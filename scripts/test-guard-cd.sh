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

hooks_json=$repo_root/hooks/hooks.json
fx_check "hooks.json runs guard-cd on Bash before tool use, through the plugin root" jq -e '
  .hooks.PreToolUse | any(.matcher == "Bash" and any(.hooks[]; .command == "\"${CLAUDE_PLUGIN_ROOT}/hooks/guard-cd.sh\""))' "$hooks_json"
fx_check "hooks.json still runs guard-rm on Bash" jq -e '
  .hooks.PreToolUse | any(.matcher == "Bash" and any(.hooks[]; .command == "\"${CLAUDE_PLUGIN_ROOT}/hooks/guard-rm.sh\""))' "$hooks_json"
fx_check "the guard-cd script is executable" test -x "$hook"

fx_report_fails
