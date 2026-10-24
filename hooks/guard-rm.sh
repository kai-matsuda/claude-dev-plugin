#!/usr/bin/env bash
# PreToolUse hook on Bash (registered in hooks/hooks.json): refuses a recursive rm whose target carries a shell variable not
# guarded with :? or ends in /*, before the command runs. Exit 2 refuses and the stderr line
# reaches the model; exit 0 lets the command through. A fix-up implementer whose mktemp -d was
# denied ran rm -rf "$s"/* with $s empty, as rm -rf /*, for five minutes (chezmoi-cyc, INFRA-29).
#
# Checked: every unquoted word `rm` (also /bin/rm and \rm) in the command, in any position
# (`sudo rm`, `&& rm`, a second line, `-exec rm`, inside a $(...) or `...`), unless an earlier
# word of its simple command is `git` (git rm is not a filesystem delete), whose arguments carry
# -r, -R or --recursive. Each non-option argument that is not a redirection or its operand is
# refused when, quotes aside, it ends in /*, is a bare *, or contains $NAME, $1, $@, $* or a
# ${...} without :?. A $(...) or `...` substitution is not a variable: its body is checked as a
# command of its own, and the word around it is still a target, so "$(mktemp -d)"/* is refused.
# Not parsed: a command string handed to another shell (bash -c "rm -rf $x") or quoted text, where
# `rm` is not an unquoted word. Tests: scripts/test-guard-rm.sh. Only the Bash tool is checked;
# input the hook cannot read passes, so a missing jq never blocks every command.
set -u
input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
cmd=$(jq -r 'select(.tool_name == "Bash") | .tool_input.command // empty' <<<"$input" 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

# refuse <word>: print the reason and exit 2; a lifted substitution shows as $(...)
refuse() {
  printf 'guard-rm: refused rm -r on %s: a variable in the target must be guarded as "${x:?}" and the target may not end in /*; use a literal path or "${x:?}"/sub\n' "${1//__guard_rm_subst__/\$(...)}" >&2
  exit 2
}

# A continued line is one line.
cmd=${cmd//\\$'\n'/ }

# Lift every substitution out, innermost first: its body becomes a command of its own at the
# end, and the word it sat in keeps a placeholder so the word's tail is still checked.
subst='\$\(([^()]*)\)'
backtick='`([^`]*)`'
bodies=
while [[ $cmd =~ $subst ]] || [[ $cmd =~ $backtick ]]; do
  bodies+=$'\n'${BASH_REMATCH[1]}
  cmd=${cmd/"${BASH_REMATCH[0]}"/__guard_rm_subst__}
done
cmd+=$bodies

# One simple command per line: command separators and subshell and group delimiters become
# newlines, so each `rm` sees only its own arguments. Group braces are whole words (`{ cmd; }`),
# so the brace of a ${var} stays with its word.
segments=$(printf '%s\n' "$cmd" | awk '{
  gsub(/;|&&|\|\||\||\(|\)/, "\n")
  gsub(/(^|[[:space:]])[{}]([[:space:]]|$)/, "\n")
  print }')

recursive_opt='^-[A-Za-z]*[rR]'
redirection='^&?[0-9]*[<>]'                  # operator with its operand attached (2>"$log")
redirection_op='^&?[0-9]*[<>]{1,3}&?[0-9]*$' # bare operator: the next word is its operand
variable='\$[A-Za-z_0-9@*#]'
brace_var='\$\{([^}]*)\}'

while IFS= read -r line; do
  # shellcheck disable=SC2206  # word-split on purpose; globs stay literal under set -f
  set -f; words=($line); set +f
  n=${#words[@]}
  seen_git=
  for ((i = 0; i < n; i++)); do
    w=${words[i]}
    [ "$w" = git ] && seen_git=1
    base=${w##*/}; base=${base#\\}
    if [ "$base" = rm ] && [ -z "$seen_git" ]; then
      args=()
      [ $((i + 1)) -lt "$n" ] && args=("${words[@]:i+1}")
      recursive=
      targets=()
      opts_done=
      operand_next=
      for a in "${args[@]+"${args[@]}"}"; do
        if [ -n "$operand_next" ]; then operand_next=; continue; fi
        if [[ $a =~ $redirection_op ]]; then operand_next=1; continue; fi
        if [[ $a =~ $redirection ]]; then continue; fi
        if [ -z "$opts_done" ] && [ "$a" = -- ]; then opts_done=1; continue; fi
        if [ -z "$opts_done" ] && [[ $a == -* ]]; then
          if [ "$a" = --recursive ] || [[ $a =~ $recursive_opt ]]; then recursive=1; fi
          continue
        fi
        targets+=("$a")
      done
      if [ -n "$recursive" ]; then
        for t in "${targets[@]+"${targets[@]}"}"; do
          bare=${t//[\"\']/}
          [[ $bare == */\* || $bare == '*' ]] && refuse "$t"
          [[ $bare =~ $variable ]] && refuse "$t"
          rest=$bare
          while [[ $rest =~ $brace_var ]]; do
            [[ ${BASH_REMATCH[1]} == *:\?* ]] || refuse "$t"
            rest=${rest#*"${BASH_REMATCH[0]}"}
          done
        done
      fi
    fi
  done
done <<<"$segments"
exit 0
