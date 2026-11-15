#!/usr/bin/env bash
# PreToolUse hook on Bash (registered in hooks/hooks.json beside guard-rm.sh): refuses a command
# whose first word is cd before it runs. Exit 2 refuses and the stderr line reaches the model;
# exit 0 lets the command through. The rule "never prefix a command with cd <repo> && ..."
# lives in the harness doc and every worktree brief, yet fix-up agents broke it 24 times in
# INFRA-41's run (dev-6hgz). Only the first word is checked: a cd later in the command, in an
# argument or in a path runs. For cd <dir> && git|bd|make <args> the refusal adds a
# `Suggestion:` line with the rewrite using the command's own flag (git -C <dir> <args>). For
# any other command the `Suggestion:` line prefixes a relative word of the args (and a command
# word holding a /, as ./run.sh) with <dir>/ only when <dir>/<word> exists when the hook runs
# or the word is a glob matching under <dir> (a relative <dir> is read from the hook's own
# directory); flags, absolute paths and ~ words stay as written. A <dir> written with ~ is
# tested as written, never expanded, so its words are not found and get no rewrite. No
# `Suggestion:` line is printed, and the refusal says "no rewrite suggested", for a compound body
# (for, if, ...), an environment prefix, a negation (!), a group, a cd, quotes, expansions, redirects or a # comment in the args,
# a word that is no file or glob under <dir> (a pattern, a number), or no file argument at all.
# The args are cut at the first ;, |, & (so also &&, || and an &> redirect) outside quotes, so
# only the first command is rewritten; a >& redirect (2>&1) stays in them. Quotes are
# honoured; inside "..." a backslash escapes the next character (\" does not end the span), while
# outside quotes backslash escapes are not, an unterminated quote keeps the rest, and a newline
# does not end the args. Tests: scripts/test-guard-cd.sh.
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
  # cd <dir> && <cmd> <args>: name the rewrite, with the command's own flag for git|bd|make
  re='^cd[[:space:]]+([^[:space:];&|]+)[[:space:]]*&&[[:space:]]*([^[:space:];&|]+)([[:space:]].*)?$'
  if [[ $trimmed =~ $re ]]; then
    dir=${BASH_REMATCH[1]} name=${BASH_REMATCH[2]}
    # args end at the first ; & | outside quotes (a >& redirect stays in them)
    rest=${BASH_REMATCH[3]} args= q= prev=
    while [ -n "$rest" ]; do
      ch=${rest:0:1}
      rest=${rest:1}
      if [ -n "$q" ]; then
        # in "..." a backslash escapes the next character, so \" does not end the span
        if [ "$q" = '"' ] && [ "$ch" = '\' ] && [ -n "$rest" ]; then
          args+="$ch${rest:0:1}" prev=${rest:0:1}
          rest=${rest:1}
          continue
        fi
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
    case $name in
      git|bd|make)
        sug="$name -C $dir"
        [ -z "$args" ] || sug+=" $args"
        echo "Suggestion: $sug" >&2 ;;
      *)
        # shell keywords start a compound body and NAME=value words an environment prefix: the
        # cut args are then not the command's own, and a quote, expansion, redirect or group
        # in them cannot be split on blanks, so none of these is rewritten
        keyword='^(for|while|until|if|case|select|function|time|cd)$|[=(){}!]'
        special="[\"'\\\$\`<>(){}#"$'\n]'
        if [[ $name =~ $keyword || $args =~ $special ]]; then
          echo "guard-cd: no rewrite suggested, the command is compound, has an environment prefix, a negation (!), a group or a cd,or its args use quotes, expansions, redirects or a comment; use an absolute path for each file argument" >&2
        else
          sug= found= unresolved=
          set -f # a glob argument stays a word here instead of expanding in the hook's directory
          # the command word is a file under <dir> only when it holds a / (./run.sh, scripts/x.sh)
          words=$args
          [[ $name != */* ]] || words="$name $args"
          [[ $name == */* ]] || sug=$name
          for arg in $words; do
            case $arg in
              -*|/*|\~*) sug+=" $arg" ;;
              *)
                # a word becomes <dir>/<word> only when that file exists or the glob matches under <dir>
                if [ -e "${dir%/}/$arg" ] || compgen -G "${dir%/}/$arg" >/dev/null; then
                  sug+=" ${dir%/}/$arg" found=1
                else
                  unresolved=1
                fi ;;
            esac
          done
          sug=${sug# }
          if [ -n "$unresolved" ]; then
            echo "guard-cd: no rewrite suggested, a word is neither a flag, an absolute path nor a file or glob under $dir; use an absolute path for each file argument" >&2
          elif [ -z "$found" ]; then
            # no file argument means the command acts on the current directory, which is not <dir>
            echo "guard-cd: no rewrite suggested, no word is a file or glob under $dir; use an absolute path for each file argument" >&2
          else
            echo "Suggestion: $sug" >&2
          fi
        fi ;;
    esac
  fi
  exit 2
fi
exit 0
