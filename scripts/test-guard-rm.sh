#!/usr/bin/env bash
# Tests for hooks/guard-rm.sh, the PreToolUse hook on Bash that refuses a recursive rm whose
# target carries a shell variable, special parameter or ~ not guarded with :?, or whose last
# path segment is a * (chezmoi-cyc, INFRA-29: a fix-up ran rm -rf "$s"/* with $s
# empty), and its parser gaps (dev-n3w, INFRA-30). Each case
# feeds the hook the tool-input JSON Claude Code sends and asserts the exit code: 2 refuses the
# command before it runs, 0 lets it through.
# Usage: scripts/test-guard-rm.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
hook=$repo_root/hooks/guard-rm.sh
source "$repo_root/scripts/fixture-test-lib.sh"   # fails, fx_report_fails


# hook_json <json>: run the hook on that stdin; prints the exit code
hook_json() { "$hook" <<<"$1" >/dev/null 2>&1; echo $?; }
# hook_rc <tool name> <command>: the same on the tool input Claude Code sends for that command
hook_rc() {
  hook_json "$(jq -cn --arg tool "$1" --arg cmd "$2" '{tool_name: $tool, tool_input: {command: $cmd}}')"
}
# expect <expected exit code> <command>: on the Bash tool
expect() {
  local rc shown; rc=$(hook_rc Bash "$2"); shown=${2//$'\n'/\\n}
  if [ "$rc" = "$1" ]; then echo "ok   exit $1: $shown"; else echo "FAIL exit $rc, want $1: $shown"; fails=$((fails+1)); fi
}

# refused: the acceptance criteria's four forms
expect 2 'rm -rf "$s"/*'
expect 2 'rm -r $dir'
expect 2 'rm -rf ${dir}/'
expect 2 'rm -rf foo/*'

# refused: the same hazards in other spellings and positions
expect 2 'rm -fr "$s"'
expect 2 'rm -Rf "$s"'
expect 2 'rm --recursive --force "$s"'
expect 2 'rm -r -f -- "$s"'
expect 2 'rm "$s" -rf'
expect 2 'rm -rf "$s/*"'
expect 2 'rm -rf ./build/$name'
expect 2 'rm -rf "${s:-}"/sub'
expect 2 'sudo rm -rf $x'
expect 2 'git status && rm -rf "$x"'
expect 2 $'s=$(mktemp -d)\nrm -rf "$s"/*'
expect 2 'find . -name tmp -exec rm -rf {} + ; rm -rf ${x}'
expect 2 '(rm -rf $x)'
expect 2 '{ rm -rf $x; }'
# a substitution is not a variable, but the word around it is still a target
expect 2 'rm -rf "$(mktemp -d)"/*'
expect 2 'rm -rf "$(pwd)/$x"'
expect 2 'rm -rf `pwd`/*'
expect 2 'echo "$(rm -rf $x)"'
expect 2 'rm -rf "$1"'
expect 2 'rm -rf "$@"'
expect 2 'rm -rf *'
expect 2 '/bin/rm -rf "$x"'
expect 2 '\rm -rf "$x"'
expect 2 $'rm -rf \\\n  "$s"'
expect 2 'rm -rf "$x" > "$log"'

# refused: the parser gaps (dev-n3w, INFRA-30)
# a target whose last segment is * or */, not only one ending in exactly /*
expect 2 'rm -rf /*/'
expect 2 'rm -rf ./*/'
expect 2 'rm -rf */'
expect 2 'rm -rf "$s"/*/'
expect 2 'rm -rf /*//'
expect 2 'rm -rf /**'
# special parameters and a leading ~ are variables too
expect 2 'rm -rf $!'
expect 2 'rm -rf "$?"'
expect 2 'rm -rf $$'
expect 2 'rm -rf "$-"'
expect 2 'rm -rf ~'
expect 2 'rm -rf ~/.cache/plugin'
expect 2 'rm -rf ~user/tmp'
# a background & separates commands, and git turns the check off only as the command word
expect 2 'sleep 1 & rm -rf $x'
expect 2 'git status & rm -rf "$x"'
expect 2 'sudo -u git rm -rf $x'
expect 2 'git submodule foreach rm -rf $x'
expect 2 'echo "a; b" && rm -rf $x'
# a substitution whose body has parentheses is still lifted
expect 2 'rm -rf "$(dirname "$(pwd)")"/*'
expect 2 'rm -rf "$((n + 1))"/*'
expect 2 'rm -rf "$(echo $(mktemp -d))"/*'
# an unquoted heredoc delimiter leaves the body's substitutions live, and the commands after
# a heredoc are still commands
expect 2 $'cat <<EOF\n$(rm -rf $x)\nEOF'
expect 2 $'cat <<EOF\n$(\n  rm -rf $x\n)\nEOF'
expect 2 $'cat <<\'EOF\'\nrm -rf $x\nEOF\nrm -rf $y'

# passes: the acceptance criteria's three forms
expect 0 'rm -rf "${s:?}"/sub'
expect 0 'rm -rf ./build'
expect 0 'rm -r /absolute/literal/path'
# the guarded spelling of ~ and of a positional parameter
expect 0 'rm -rf "${HOME:?}"/.cache/plugin'
expect 0 'rm -rf "${1:?}"/sub'

# passes: no recursive delete in the command
expect 0 'rm "$file"'
expect 0 'rm -f $file'
expect 0 'git rm -r --cached vendor'
expect 0 'git -C /Users/me/repo rm -r --cached "$x"'
expect 0 'echo done'
expect 0 'rm -rf "${s:?}" "${t:?}"/*.log'
expect 0 'rm -rf "$(git rev-parse --show-toplevel)"/.fixtures/x'
# a redirection operand is not a target
expect 0 'rm -rf ./build > "$log" 2>&1'
expect 0 'rm -rf ./build 2>"$log"'
expect 0 'xargs rm -rf <<<"$x"'
# git is the command word after assignments and wrappers; a redirection's & is not a separator
expect 0 'sudo git rm -r --cached "$x"'
expect 0 'git -c core.quotepath=off -C /repo rm -r --cached "$x"'
expect 0 'GIT_DIR=.git git rm -r --cached "$x"'
expect 0 'rm -rf ./build 2>&1 & wait'

# passes: quoted text, heredoc bodies and comments are not commands (the triage run that
# filed it was refused for quoting these forms in a bead body, dev-n3w)
expect 0 'bd create --title="guard-rm gaps" --description="rm -rf \"$s\"/* ran with \$s empty; rm -r $dir"'
expect 0 "git commit -m 'fix(hooks): refuse rm -rf \$x after a background &'"
expect 0 'echo "rm -rf $x; rm -rf *"'
expect 0 $'cat <<\'EOF\'\nrm -rf "$s"/*\nEOF'
expect 0 $'cat <<-EOF\n\trm -rf $x\n\tEOF'
expect 0 $'bd update dev-1 --description="$(cat <<EOF\nthe guard refuses rm -rf $x\nEOF\n)"'
expect 0 $'# clean up with rm -rf $x later\necho ok'

# passes: not the Bash tool, or no command to read
fx_check "another tool's input passes" fx_eq "$(hook_rc Read 'rm -rf $x')" 0
fx_check "input without a command passes" fx_eq "$(hook_json '{"tool_name":"Bash","tool_input":{}}')" 0
fx_check "input that is not JSON passes" fx_eq "$(hook_json 'rm -rf $x')" 0

# the refusal names the safe forms on stderr
msg=$(jq -cn '{tool_name: "Bash", tool_input: {command: "rm -rf \"$s\"/*"}}' | "$hook" 2>&1 >/dev/null)
fx_check "the refusal names \${x:?}" grep -qF '${x:?}' <<<"$msg"
fx_check "the refusal names a literal path" grep -qi 'literal path' <<<"$msg"
fx_check "the refusal quotes the offending word" grep -qF '"$s"/*' <<<"$msg"
msg=$(jq -cn '{tool_name: "Bash", tool_input: {command: "rm -rf \"$(mktemp -d)\"/*"}}' | "$hook" 2>&1 >/dev/null)
fx_check "the refusal shows a lifted substitution as \$(...)" grep -qF '"$(...)"/*' <<<"$msg"

# hooks/hooks.json registers the hooks in the harness's schema: event -> [{matcher, hooks: [{type, command}]}]
hooks_json=$repo_root/hooks/hooks.json
fx_check "hooks.json is valid JSON" jq -e . "$hooks_json"
fx_check "hooks.json entries have the harness schema" jq -e '
  .hooks | type == "object" and length > 0 and
  all(.[]; type == "array" and length > 0 and
    all(.[]; (.matcher | type == "string") and (.hooks | type == "array" and length > 0 and
      all(.[]; .type == "command" and (.command | type == "string" and length > 0)))))' "$hooks_json"
fx_check "hooks.json runs guard-rm on Bash before tool use, through the plugin root" jq -e '
  .hooks.PreToolUse | any(.matcher == "Bash" and any(.hooks[]; .command == "\"${CLAUDE_PLUGIN_ROOT}/hooks/guard-rm.sh\""))' "$hooks_json"
fx_check "hooks.json runs bd prime --hook-json on session start" jq -e '
  .hooks.SessionStart | any(.[]; any(.hooks[]; .command == "command -v bd >/dev/null 2>&1 && bd prime --hook-json || true"))' "$hooks_json"
fx_check "the guard-rm script is executable" test -x "$hook"

fx_report_fails
