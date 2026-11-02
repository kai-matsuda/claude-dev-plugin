#!/usr/bin/env bash
# PreToolUse hook on Bash (registered in hooks/hooks.json beside guard-rm.sh): refuses a command
# whose first word is cd before it runs. Exit 2 refuses and the stderr line reaches the model;
# exit 0 lets the command through. The rule "never prefix a command with cd <repo> && ..."
# lives in the harness doc and every worktree brief, yet fix-up agents broke it 24 times in
# INFRA-41's run (dev-6hgz). Only the first word is checked: a cd later in the command, in an
# argument or in a path runs. Tests: scripts/test-guard-cd.sh.
# Only the Bash tool is checked; input the hook cannot read passes, so a missing jq never
# blocks every command.
set -u
input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
cmd=$(jq -r 'select(.tool_name == "Bash") | .tool_input.command // empty' <<<"$input" 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

# the first word, after leading blanks and newlines and any opening ( or { of a subshell or group
trimmed=${cmd#"${cmd%%[![:space:]]*}"}
while [[ $trimmed == [\(\{]* ]]; do
  trimmed=${trimmed#?}
  trimmed=${trimmed#"${trimmed%%[![:space:]]*}"}
done
first=${trimmed%%[[:space:];&|]*}
if [ "$first" = cd ]; then
  echo 'guard-cd: a command may not start with cd; use the command'"'"'s own directory flag (git -C <dir>, bd -C <dir>, make -C <dir>), an absolute path, or the Edit tool for a file edit' >&2
  exit 2
fi
exit 0
