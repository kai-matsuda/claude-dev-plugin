#!/usr/bin/env bash
# Tests for hooks/guard-rm.sh, the PreToolUse hook on Bash that refuses a
# recursive rm whose target carries a shell variable not guarded with :? or ends in /*
# (chezmoi-cyc, INFRA-29: a fix-up implementer ran rm -rf "$s"/* with $s empty). Each case
# feeds the hook the tool-input JSON Claude Code sends and asserts the exit code: 2 refuses the
# command before it runs, 0 lets it through.
# Usage: scripts/test-guard-rm.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
hook=$repo_root/hooks/guard-rm.sh
source "$repo_root/scripts/fixture-test-lib.sh"   # fails, report_fails

eq() { [ "$1" = "$2" ]; }   # for check: two strings equal

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

# passes: the acceptance criteria's three forms
expect 0 'rm -rf "${s:?}"/sub'
expect 0 'rm -rf ./build'
expect 0 'rm -r /absolute/literal/path'

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

# passes: not the Bash tool, or no command to read
check "another tool's input passes" eq "$(hook_rc Read 'rm -rf $x')" 0
check "input without a command passes" eq "$(hook_json '{"tool_name":"Bash","tool_input":{}}')" 0
check "input that is not JSON passes" eq "$(hook_json 'rm -rf $x')" 0

# the refusal names the safe forms on stderr
msg=$(jq -cn '{tool_name: "Bash", tool_input: {command: "rm -rf \"$s\"/*"}}' | "$hook" 2>&1 >/dev/null)
check "the refusal names \${x:?}" grep -qF '${x:?}' <<<"$msg"
check "the refusal names a literal path" grep -qi 'literal path' <<<"$msg"
check "the refusal quotes the offending word" grep -qF '"$s"/*' <<<"$msg"
msg=$(jq -cn '{tool_name: "Bash", tool_input: {command: "rm -rf \"$(mktemp -d)\"/*"}}' | "$hook" 2>&1 >/dev/null)
check "the refusal shows a lifted substitution as \$(...)" grep -qF '"$(...)"/*' <<<"$msg"

# hooks/hooks.json registers the hooks in the harness's schema: event -> [{matcher, hooks: [{type, command}]}]
hooks_json=$repo_root/hooks/hooks.json
check "hooks.json is valid JSON" jq -e . "$hooks_json"
check "hooks.json entries have the harness schema" jq -e '
  .hooks | type == "object" and length > 0 and
  all(.[]; type == "array" and length > 0 and
    all(.[]; (.matcher | type == "string") and (.hooks | type == "array" and length > 0 and
      all(.[]; .type == "command" and (.command | type == "string" and length > 0)))))' "$hooks_json"
check "hooks.json runs guard-rm on Bash before tool use, through the plugin root" jq -e '
  .hooks.PreToolUse | any(.matcher == "Bash" and any(.hooks[]; .command == "${CLAUDE_PLUGIN_ROOT}/hooks/guard-rm.sh"))' "$hooks_json"
check "hooks.json runs bd prime --hook-json on session start" jq -e '
  .hooks.SessionStart | any(.[]; any(.hooks[]; .command == "bd prime --hook-json"))' "$hooks_json"
check "the guard-rm script is executable" test -x "$hook"

report_fails
