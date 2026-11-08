#!/usr/bin/env bash
# Tests for hooks/guard-cd.sh, the PreToolUse hook on Bash that refuses a command whose first
# word is cd (dev-6hgz, INFRA-41). Each case feeds the hook the tool-input JSON Claude Code
# sends and asserts the exit code: 2 refuses the command before it runs, 0 lets it through.
# Usage: scripts/test-guard-cd.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
hook=$repo_root/hooks/guard-cd.sh
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_check, fails, fx_report_fails

# hook_json <json>: run the hook on that stdin; prints the exit code
hook_json() { "$hook" <<<"$1" >/dev/null 2>&1; echo $?; }
# hook_rc <tool name> <command>: run the hook on the tool input for that command; prints the exit code
hook_rc() {
  hook_json "$(jq -cn --arg tool "$1" --arg cmd "$2" '{tool_name: $tool, tool_input: {command: $cmd}}')"
}
# expect <expected exit code> <command>: on the Bash tool
expect() {
  local rc shown; rc=$(hook_rc Bash "$2"); shown=${2//$'\n'/\\n}
  if [ "$rc" = "$1" ]; then echo "ok   exit $1: $shown"; else echo "FAIL exit $rc, want $1: $shown"; fails=$((fails+1)); fi
}

# refused: cd is the first word
expect 2 'cd /tmp'
expect 2 'cd /tmp && ls'
expect 2 'cd repo; make check'
expect 2 'cd'
expect 2 '  cd /tmp && ls'
expect 2 $'cd /tmp\nls'
expect 2 $'\ncd /tmp'
# variable assignments before cd still run cd
expect 2 'FOO=1 cd x'
expect 2 'A=1 B=2 cd x'
# a quoted cd still runs cd
expect 2 '"cd" x'
expect 2 "'cd' x"
# a subshell or brace group opens with cd
expect 2 '(cd /tmp && ls)'
expect 2 '( cd /tmp && ls)'
expect 2 '{ cd x; }'
expect 2 '((cd /tmp))'

# allowed: cd only later, in an argument or a path
expect 0 'ls && cd /tmp'
expect 0 'git -C /tmp status'
expect 0 'echo cd /tmp'
expect 0 'ls /home/cd/x'
expect 0 'cdrecord dev=1'
expect 0 'cd-hit -i x'
expect 0 'make -C /tmp check'
expect 0 'ls'
expect 0 'FOO=1 git -C /tmp status'
expect 0 'FOO=1 echo cd'
expect 0 'A=1 ls && cd /tmp'
expect 0 '"echo" cd'

# allowed: other tools and input the hook cannot read
expect 0 '(ls /tmp)'
expect 0 '{ ls; }'
fx_check "a non-Bash tool with cd passes" fx_eq "$(hook_rc Edit 'cd /tmp')" 0
fx_check "input without a command passes" fx_eq "$(hook_json '{"tool_name":"Bash","tool_input":{}}')" 0
fx_check "unreadable input passes" fx_eq "$(hook_json 'not json')" 0

# the refusal names the alternatives
msg=$("$hook" <<<"$(jq -cn '{tool_name: "Bash", tool_input: {command: "cd /tmp && ls"}}')" 2>&1 >/dev/null)
for alt in 'git -C' 'bd -C' 'make -C' 'absolute path' 'Edit'; do
  fx_check "the refusal names $alt" grep -qF "$alt" <<<"$msg"
done

# suggestion_line <command>: the hook's Suggestion line for that Bash command, empty when none
suggestion_line() {
  "$hook" <<<"$(jq -cn --arg c "$1" '{tool_name: "Bash", tool_input: {command: $c}}')" 2>&1 >/dev/null | grep -F 'Suggestion' || true
}
# expect_suggestion <command> <expected Suggestion line, empty for none>
expect_suggestion() {
  fx_check "the suggestion for '$1' is '$2'" fx_eq "$(suggestion_line "$1")" "$2"
}

# a cd <dir> && git/bd/make command is answered with the rewrite using the command's own flag
expect_suggestion 'cd /x && git status' 'Suggestion: git -C /x status'
expect_suggestion 'cd /y && make check' 'Suggestion: make -C /y check'
expect_suggestion 'cd /w && bd show dev-1' 'Suggestion: bd -C /w show dev-1'
expect_suggestion 'cd /v && git' 'Suggestion: git -C /v'
# a chained command is suggested up to its first separator only
for chain in 'cd /x && git status && cd -' 'cd /x && git status; cd -' 'cd /x && git status | head' 'cd /x && git status || true' 'cd /x && git status & cd -'; do
  expect_suggestion "$chain" 'Suggestion: git -C /x status'
done
# a separator inside quotes is part of the args, and a >& redirect stays in them
expect_suggestion 'cd /x && git commit -m "a; b"' 'Suggestion: git -C /x commit -m "a; b"'
expect_suggestion "cd /x && git log --grep='a|b' && cd -" "Suggestion: git -C /x log --grep='a|b'"
expect_suggestion 'cd /x && git status 2>&1 | head' 'Suggestion: git -C /x status 2>&1'
# an &> redirect is cut like any &, and an unterminated quote keeps the rest
expect_suggestion 'cd /x && git status &>/dev/null' 'Suggestion: git -C /x status'
expect_suggestion 'cd /x && git commit -m "a; b' 'Suggestion: git -C /x commit -m "a; b'
# a word that only starts with the command, or a command with no directory flag, gets none
for word in 'cd /x && gitk' 'cd /x && makefoo all' 'cd /x && bdx show' 'cd /z && ls'; do
  expect_suggestion "$word" ''
done

hooks_json=$repo_root/hooks/hooks.json
fx_check "hooks.json runs guard-cd on Bash before tool use, through the plugin root" jq -e '
  .hooks.PreToolUse | any(.matcher == "Bash" and any(.hooks[]; .command == "\"${CLAUDE_PLUGIN_ROOT}/hooks/guard-cd.sh\""))' "$hooks_json"
fx_check "hooks.json still runs guard-rm on Bash" jq -e '
  .hooks.PreToolUse | any(.matcher == "Bash" and any(.hooks[]; .command == "\"${CLAUDE_PLUGIN_ROOT}/hooks/guard-rm.sh\""))' "$hooks_json"
fx_check "the guard-cd script is executable" test -x "$hook"

fx_report_fails
