#!/usr/bin/env bash
# PreToolUse hook on Bash (registered in hooks/hooks.json): refuses a recursive rm whose target
# carries a shell variable, special parameter or ~ not guarded with :?, or whose last path
# segment is a *, before the command runs. Exit 2 refuses and the stderr line reaches the
# model; exit 0 lets the command through. A fix-up implementer whose mktemp -d was denied ran
# rm -rf "$s"/* with $s empty, as rm -rf /*, for five minutes (chezmoi-cyc, INFRA-29).
#
# Checked: every unquoted word `rm` (also /bin/rm and \rm) in the command, in any position
# (`sudo rm`, `&& rm`, after a background &, a second line, `-exec rm`, inside a $(...) or
# `...`), whose arguments carry -r, -R or --recursive, except git's own subcommand (`git rm`,
# `git -C path rm`, `sudo git rm`: not a filesystem delete; the command word is the first word
# after any NAME=value assignments and wrappers such as sudo, so `sudo -u git rm` and
# `git submodule foreach rm` are still checked). Each non-option argument that is not a
# redirection or its operand is refused when, quotes aside, its last path segment is only stars
# (foo/*, /*/, /**, a bare *), it starts with ~, or it contains $NAME, $1, a special parameter
# ($@, $*, $#, $!, $?, $$, $-) or a ${...} without :?. A $(...) or `...` substitution is not a
# variable: its body, nested $(...) and (...) included, is checked as a command of its own, and
# the word around it is still a target, so "$(mktemp -d)"/* is refused. Skipped: single- and
# double-quoted text, comments and heredoc bodies, where `rm` is not a command (a commit
# message or bead body that quotes a recursive delete passes, INFRA-30); a substitution inside
# double quotes or an unquoted heredoc body is live and still checked. Not parsed: a command
# string handed to another shell or to git (bash -c "rm -rf $x", git -c alias.x='!rm -rf $x')
# and a backtick nested with \` inside another backtick. Tests: scripts/test-guard-rm.sh.
# Only the Bash tool is checked; input the hook cannot read passes, so a missing jq never
# blocks every command.
set -u
export LC_ALL=C   # one byte per character, so a window below is a byte range
input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
cmd=$(jq -r 'select(.tool_name == "Bash") | .tool_input.command // empty' <<<"$input" 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

# refuse <word>: print the reason and exit 2; a lifted substitution shows as $(...)
refuse() {
  printf 'guard-rm: refused rm -r on %s: a variable, special parameter or ~ in the target must be guarded as "${x:?}" and the target may not end in /* or /*/; use a literal path or "${x:?}"/sub\n' "${1//__guard_rm_subst__/\$(...)}" >&2
  exit 2
}

recursive_opt='^-[A-Za-z]*[rR]'
redirection='^&?[0-9]*[<>]'                  # operator with its operand attached (2>"$log")
redirection_op='^&?[0-9]*[<>]{1,3}&?[0-9]*$' # bare operator: the next word is its operand
variable='\$[A-Za-z_0-9@*#!?$-]'          # $NAME, $1, $@, $*, $#, $!, $?, $$, $-
brace_var='\$\{([^}]*)\}'
assignment='^[A-Za-z_][A-Za-z_0-9]*='
wrappers=' sudo command exec env nohup time nice builtin '

# check_simple: refuse the first hazardous recursive rm among the words of one simple command,
# held in `words`.
check_simple() {
  local count=${#words[@]} k word base a t bare seg last rest recursive opts_done operand_next args targets git_sub=-1
  # The command word is the first word that is not an assignment or a wrapper such as sudo.
  # When it is git, its subcommand (the first word after git's options; -C and -c take an
  # operand) is exempt if it is rm.
  for ((k = 0; k < count; k++)); do
    word=${words[k]}
    [[ $word =~ $assignment ]] && continue
    [[ $wrappers == *" $word "* ]] && continue
    if [ "${word##*/}" = git ]; then
      for ((k++; k < count; k++)); do
        word=${words[k]}
        case $word in -C | -c) ((k++)); continue;; -*) continue;; esac
        git_sub=$k; break
      done
    fi
    break
  done
  for ((k = 0; k < count; k++)); do
    [ "$k" = "$git_sub" ] && continue
    word=${words[k]}
    base=${word##*/}; base=${base#\\}
    [ "$base" = rm ] || continue
    args=(); ((k + 1 < count)) && args=("${words[@]:k+1}")
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
    [ -n "$recursive" ] || continue
    for t in "${targets[@]+"${targets[@]}"}"; do
      bare=${t//[\"\']/}
      seg=$bare; while [[ $seg == */ ]]; do seg=${seg%/}; done   # trailing slashes aside
      last=${seg##*/}                                              # the last path segment
      [ -n "$last" ] && [ -z "${last//\*/}" ] && refuse "$t"
      [[ $bare =~ $variable || $bare == '~'* ]] && refuse "$t"
      rest=$bare
      while [[ $rest =~ $brace_var ]]; do
        [[ ${BASH_REMATCH[1]} == *:\?* ]] || refuse "$t"
        rest=${rest#*"${BASH_REMATCH[0]}"}
      done
    done
  done
}

# The scanner below walks one command string a character at a time, building each word in `w`
# and each simple command in `words`, and checks a simple command at every separator. Quotes
# keep their content in the word (a separator or `rm` inside them is text) and are stripped
# again by check_simple. Every $(...) and `...` body is lifted onto `pending`, to be scanned as
# a command of its own, and leaves a placeholder in its word. A heredoc body is skipped line by
# line up to its delimiter.
#
# The string being scanned is the global `cur`, never a function argument: under bash 3.2 a
# string argument is copied per call and every ${cur:i:1} first measures the whole string, so
# either would make the scan quadratic in the command's length. The loops instead read `c`
# through `win`, a 1 KB window refilled when the index leaves it (`refill`), which keeps the
# scan linear apart from the peeks at a special character's neighbours. Whoever changes `cur`
# sets win_end=0 so the next read refills.
window=1024
cur=; win=; win_start=0; win_end=0
refill() { win=${cur:$1:window}; win_start=$1; win_end=$(($1 + ${#win})); }  # <index>

# subst_end <index of an opening paren in cur>: sets match_end to the index of the matching
# close paren, quotes inside the body respected, or to -1 when it is unbalanced.
subst_end() {
  local j=$1 depth=0 lq= c len=${#cur}
  for ((; j < len; j++)); do
    ((j >= win_end)) && refill "$j"; c=${win:j-win_start:1}
    if [ -n "$lq" ]; then
      case $c in "$lq") lq=;; '\') [ "$lq" = '"' ] && ((j++));; esac
      continue
    fi
    case $c in
      "'" | '"') lq=$c;;
      '\') ((j++));;
      '(') ((depth++));;
      ')') ((depth--)); if ((depth == 0)); then match_end=$j; return; fi;;
    esac
  done
  match_end=-1
}
# backtick_end <index of an opening backtick in cur>: sets match_end to the index of the
# closing backtick, or to -1 when there is none.
backtick_end() {
  local j=$(($1 + 1)) len=${#cur} c
  for ((; j < len; j++)); do
    ((j >= win_end)) && refill "$j"; c=${win:j-win_start:1}
    case $c in '\') ((j++));; '`') match_end=$j; return;; esac
  done
  match_end=-1
}
# lift_at <index of a $ or backtick in cur>: when a substitution starts there, push its body
# onto pending and set match_end to its last index; otherwise set match_end to -1.
lift_at() {
  local j=$1
  if [ "${cur:j:1}" = '$' ]; then
    [ "${cur:j+1:1}" = '(' ] || { match_end=-1; return; }
    subst_end $((j + 1))
    ((match_end >= 0)) && pending+=("${cur:j+2:match_end-j-2}")
  else
    backtick_end "$j"
    ((match_end >= 0)) && pending+=("${cur:j+1:match_end-j-1}")
  fi
}
# lift_only <text>: push the body of every substitution in the text (an unquoted heredoc's
# body) onto pending; the text itself is not a command. It scans a string of its own, so it
# swaps `cur` out and back.
lift_only() {
  local outer=$cur j=0 len=${#1} c
  cur=$1; win_end=0
  while ((j < len)); do
    ((j >= win_end)) && refill "$j"; c=${win:j-win_start:1}
    case $c in
      '\') j=$((j + 2)); continue;;
      '$' | '`') lift_at "$j"; if ((match_end >= 0)); then j=$((match_end + 1)); continue; fi;;
    esac
    ((j++))
  done
  cur=$outer; win_end=0
}

# end_word: close the word being built; a whole-word { or } is a group delimiter, not a word
end_word() {
  [ -n "$have_word" ] || return 0
  if [ "$w" = '{' ] || [ "$w" = '}' ]; then w=; have_word=; end_command; return 0; fi
  words+=("$w"); w=; have_word=
}
# end_command: close the word and check the simple command collected so far
end_command() {
  end_word
  [ ${#words[@]} -gt 0 ] && check_simple
  words=()
}

# scan <command string>
scan() {
  local n=${#1} i=0 c q= hd=0 delims=() dashes=() quoted=() body= j raw delim line cmp
  cur=$1; win_end=0
  w=; have_word=; words=()
  while ((i < n)); do
    ((i >= win_end)) && refill "$i"; c=${win:i-win_start:1}
    if [ -n "$q" ]; then
      # Inside quotes: only the closing quote, an escape, and in "..." a substitution matter.
      if [ "$c" = "$q" ]; then q=
      elif [ "$q" = '"' ] && [ "$c" = '\' ]; then w+=$c; ((i++)); c=${cur:i:1}
      elif [ "$q" = '"' ] && { [ "$c" = '$' ] || [ "$c" = '`' ]; }; then
        lift_at "$i"
        if ((match_end >= 0)); then w+=__guard_rm_subst__; i=$((match_end + 1)); continue; fi
      fi
      w+=$c; ((i++)); continue
    fi
    case $c in
      "'" | '"') q=$c; w+=$c; have_word=1; ((i++));;
      '\')
        w+=$c${cur:i+1:1}; have_word=1; i=$((i + 2));;
      '$' | '`')
        lift_at "$i"
        if ((match_end >= 0)); then w+=__guard_rm_subst__; have_word=1; i=$((match_end + 1)); continue; fi
        w+=$c; have_word=1; ((i++));;
      '#')
        # A comment runs to the end of the line; a # inside a word (${x#y}, $#) is not one.
        if [ -z "$have_word" ]; then
          line=${cur:i}; line=${line%%$'\n'*}; i=$((i + ${#line}))
        else w+=$c; ((i++)); fi;;
      ' ' | $'\t') end_word; ((i++));;
      ';' | '|' | '(' | ')') end_command; ((i++));;
      '&')
        # The & of a redirection (2>&1, >&2, &>log) stays in its word; any other & separates.
        if [[ $w == *[\<\>] ]] || [ "${cur:i+1:1}" = '>' ]; then w+=$c; have_word=1
        else end_command; fi
        ((i++));;
      '<')
        if [ "${cur:i+1:1}" = '<' ] && [ "${cur:i+2:1}" != '<' ]; then
          # A heredoc operator: read its delimiter and queue it for the body that follows the line.
          j=$((i + 2)); raw=
          [ "${cur:j:1}" = '-' ] && { raw=-; ((j++)); }
          while [ "${cur:j:1}" = ' ' ] || [ "${cur:j:1}" = $'\t' ]; do ((j++)); done
          while ((j < n)); do
            c=${cur:j:1}
            case $c in ' ' | $'\t' | $'\n' | ';' | '&' | '|' | '(' | ')' | '<' | '>') break;; esac
            raw+=$c; ((j++))
          done
          delim=${raw#-}; delim=${delim//[\"\'\\]/}
          delims+=("$delim"); dashes+=("${raw%%[!-]*}")
          if [ "${raw#-}" = "$delim" ]; then quoted+=(''); else quoted+=(1); fi
          w+="<<$raw"; have_word=1; i=$j
        else w+=$c; have_word=1; ((i++)); fi;;
      $'\n')
        end_command; ((i++))
        # The lines after one with heredoc operators are their bodies, up to each delimiter;
        # an unquoted delimiter leaves the body's substitutions live, so they are lifted.
        body=
        while ((i < n)) && ((hd < ${#delims[@]})); do
          line=${cur:i}; line=${line%%$'\n'*}
          i=$((i + ${#line} + 1))
          cmp=$line
          if [ -n "${dashes[hd]}" ]; then while [[ $cmp == $'\t'* ]]; do cmp=${cmp#$'\t'}; done; fi
          if [ "$cmp" = "${delims[hd]}" ]; then
            [ -z "${quoted[hd]}" ] && lift_only "$body"
            body=; ((hd++))
          else body+=$line$'\n'; fi
        done
        # a body the command ends inside is still live
        [ -n "$body" ] && [ -z "${quoted[hd]}" ] && lift_only "$body";;
      *) w+=$c; have_word=1; ((i++));;
    esac
  done
  end_command
}

# A continued line is one line.
cmd=${cmd//\\$'\n'/ }
pending=("$cmd")
k=0
while ((k < ${#pending[@]})); do scan "${pending[k]}"; ((k++)); done
exit 0
