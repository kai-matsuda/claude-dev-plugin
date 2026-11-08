#!/usr/bin/env bash
# PreToolUse hook on Bash (registered in hooks/hooks.json beside guard-rm.sh): refuses a command
# whose first word is cd before it runs. Exit 2 refuses and the stderr line reaches the model;
# exit 0 lets the command through. The rule "never prefix a command with cd <repo> && ..."
# lives in the harness doc and every worktree brief, yet fix-up agents broke it 24 times in
# INFRA-41's run (dev-6hgz). Only the first word is checked: a cd later in the command, in an
# argument or in a path runs. For cd <dir> && git|bd|make <args> the refusal adds a
# "Suggestion:" line with the rewrite using the command's own flag (git -C <dir> <args>). The
# args stop at the first &&, ||, ; or | outside quotes, so only the first command is rewritten;
# a >& redirect (2>&1) stays in them. Tests: scripts/test-guard-cd.sh.
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
# skip leading NAME=value words: FOO=1 cd x still runs cd
while [[ $first =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do
  trimmed=${trimmed#"$first"}
  trimmed=${trimmed#"${trimmed%%[![:space:]]*}"}
  first=${trimmed%%[[:space:];&|]*}
done
# strip one pair of quotes around the word: "cd" x and 'cd' x still run cd
word=$first
case $word in
  \"*\") word=${word#\"}; word=${word%\"} ;;
  \'*\') word=${word#\'}; word=${word%\'} ;;
esac
if [ "$word" = cd ]; then
  echo 'guard-cd: a command may not start with cd; use the command'"'"'s own directory flag (git -C <dir>, bd -C <dir>, make -C <dir>), an absolute path, or the Edit tool for a file edit' >&2
  # cd <dir> && git|bd|make <args>: name the rewrite with the command's own flag
  re='^cd[[:space:]]+([^[:space:];&|]+)[[:space:]]*&&[[:space:]]*(git|bd|make)([[:space:]].*)?$'
  if [[ $trimmed =~ $re ]]; then
    # args end at the first ; & | outside quotes (a >& redirect stays in them)
    rest=${BASH_REMATCH[3]} args= q= prev=
    while [ -n "$rest" ]; do
      ch=${rest:0:1}
      rest=${rest:1}
      if [ -n "$q" ]; then
        [ "$ch" != "$q" ] || q=
      else
        case $ch in
          \"|\') q=$ch ;;
          \;|\|) break ;;
          \&) [ "$prev" = '>' ] || break ;;
        esac
      fi
      args+=$ch prev=$ch
    done
    args=${args#"${args%%[![:space:]]*}"}
    args=${args%"${args##*[![:space:]]}"}
    sug="${BASH_REMATCH[2]} -C ${BASH_REMATCH[1]}"
    [ -z "$args" ] || sug+=" $args"
    echo "Suggestion: $sug" >&2
  fi
  exit 2
fi
exit 0
