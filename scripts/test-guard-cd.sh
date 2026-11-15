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

# refusal_msg <command>: the hook's whole stderr for that Bash command
refusal_msg() {
  "$hook" <<<"$(jq -cn --arg c "$1" '{tool_name: "Bash", tool_input: {command: $c}}')" 2>&1 >/dev/null
}

# the refusal names the alternatives
msg=$(refusal_msg 'cd /tmp && ls')
for alt in 'git -C' 'bd -C' 'make -C' 'absolute path' 'Edit'; do
  fx_check "the refusal names $alt" grep -qF "$alt" <<<"$msg"
done

# suggestion_line <command>: the hook's Suggestion line for that Bash command, empty when none
suggestion_line() {
  refusal_msg "$1" | grep -F 'Suggestion' || true
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
# a backslash-escaped quote inside double quotes does not end the span, so the rewrite stays balanced
expect_suggestion 'cd /x && git commit -m "a \" ; b" && cd -' 'Suggestion: git -C /x commit -m "a \" ; b"'
# an unescaped quote still ends the span, and a separator after it cuts the rewrite
expect_suggestion 'cd /x && git commit -m "a " ; b" && cd -' 'Suggestion: git -C /x commit -m "a "'
# an escaped backslash is a pair, so the quote after it ends the span
expect_suggestion 'cd /x && git commit -m "a \\" ; b" && cd -' 'Suggestion: git -C /x commit -m "a \\"'
expect_suggestion "cd /x && git log --grep='a|b' && cd -" "Suggestion: git -C /x log --grep='a|b'"
expect_suggestion 'cd /x && git status 2>&1 | head' 'Suggestion: git -C /x status 2>&1'
# an &> redirect is cut like any &, and an unterminated quote keeps the rest
expect_suggestion 'cd /x && git status &>/dev/null' 'Suggestion: git -C /x status'
expect_suggestion 'cd /x && git commit -m "a; b' 'Suggestion: git -C /x commit -m "a; b'
# Rewrites for a command with no directory flag depend on which files exist under <dir>, so they
# run against a throwaway directory $d holding a.txt, b.md, run.py, run.sh, sub/c.txt and scripts/foo.sh.
fx_scratch_dir guard-cd
d=$scratch
mkdir -p "$d/sub" "$d/scripts"
touch "$d/a.txt" "$d/b.md" "$d/run.py" "$d/run.sh" "$d/sub/c.txt" "$d/scripts/foo.sh"
# expect_no_rewrite <command>: no Suggestion line, and the refusal says so
expect_no_rewrite() {
  expect_suggestion "$1" ''
  fx_check "the refusal for '$1' says no rewrite is suggested" grep -qF 'no rewrite suggested' <<<"$(refusal_msg "$1")"
}
# a word that only starts with git/bd/make is another command: no -C flag, file args rewritten
touch "$d/all" "$d/show"
expect_suggestion "cd $d && makefoo all" "Suggestion: makefoo $d/all"
expect_suggestion "cd $d && bdx show" "Suggestion: bdx $d/show"
# no relative argument: the command would act on the current directory, so no suggestion
for word in "cd $d && gitk" "cd $d && ls" "cd $d && ls -la /etc"; do
  expect_no_rewrite "$word"
done
# a command with no directory flag has each relative file argument put under <dir>
expect_suggestion "cd $d && wc -w *.md" "Suggestion: wc -w $d/*.md"
expect_suggestion "cd $d && cat a.txt sub/c.txt" "Suggestion: cat $d/a.txt $d/sub/c.txt"
expect_suggestion "cd $d/ && wc -l b.md" "Suggestion: wc -l $d/b.md"
expect_suggestion "cd $d && cat a.txt /abs/in" "Suggestion: cat $d/a.txt /abs/in"
expect_suggestion "cd $d && cat sub && cd -" "Suggestion: cat $d/sub"
expect_suggestion "cd $d && cat ." "Suggestion: cat $d/."
# a glob stays a word: it is not expanded in the hook's own directory
expect_suggestion "cd $d && wc scripts/f*.sh" "Suggestion: wc $d/scripts/f*.sh"
# a relative dir is looked up from the hook's own directory
rel_out=$(cd "$d" && "$hook" <<<"$(jq -cn '{tool_name: "Bash", tool_input: {command: "cd sub && wc c.txt"}}')" 2>&1 >/dev/null | grep -F Suggestion || true)
fx_check "a relative dir is prefixed as written" fx_eq "$rel_out" 'Suggestion: wc sub/c.txt'
# only a file argument gets <dir>/: a word that is no file or glob under <dir> (a pattern, a
# subcommand, a number) means no rewrite, since prefixing it would change the command
for notfile in "cd $d && grep -r foo ." "cd $d && npm test" "cd $d && go test ./..." "cd $d && python3 -u run.py --n 3" "cd $d && wc missing.md" "cd $d && wc *.zzz"; do
  expect_no_rewrite "$notfile"
done
# a relative command word runs from <dir>, so it is prefixed too, or no rewrite when it is no file there
expect_suggestion "cd $d && ./run.sh a.txt" "Suggestion: $d/./run.sh $d/a.txt"
expect_suggestion "cd $d && scripts/foo.sh b.md" "Suggestion: $d/scripts/foo.sh $d/b.md"
expect_no_rewrite "cd $d && ./nope.sh a.txt"
# a ~ word is the shell's, not a file under <dir>: left as written
expect_suggestion "cd $d && cat ~/a.txt a.txt" "Suggestion: cat ~/a.txt $d/a.txt"
expect_suggestion "cd $d && cat ~~/a a.txt" "Suggestion: cat ~~/a $d/a.txt"
# a comment ends the command: its words are not file arguments
expect_no_rewrite "cd $d && wc a.txt # b.md"
# a compound body, quotes, expansions, redirects, an environment prefix or a group get no
# rewrite, and the refusal says so
for unsafe in "cd $d && for f in *.md; do wc \"\$f\"; done" "cd $d && if true; then ls a.txt; fi" "cd $d && wc \"a b.md\"" "cd $d && cat \$HOME/a" "cd $d && wc a.txt > out" "cd $d && FOO=1 wc a.txt" "cd $d && ! wc a.txt" "cd $d && { wc a.txt; }" "cd $d && cd sub"; do
  expect_no_rewrite "$unsafe"
done
# the refusal names a negation, since a ! command word is one of the cases that get no rewrite
fx_check "the refusal for a ! command names a negation" grep -qF 'a negation' <<<"$(refusal_msg "cd $d && ! wc a.txt")"
# a <dir> written with ~ is tested as written, never expanded, so it gets no rewrite
expect_no_rewrite "cd ~ && cat a.txt"

hooks_json=$repo_root/hooks/hooks.json
fx_check "hooks.json runs guard-cd on Bash before tool use, through the plugin root" jq -e '
  .hooks.PreToolUse | any(.matcher == "Bash" and any(.hooks[]; .command == "\"${CLAUDE_PLUGIN_ROOT}/hooks/guard-cd.sh\""))' "$hooks_json"
fx_check "hooks.json still runs guard-rm on Bash" jq -e '
  .hooks.PreToolUse | any(.matcher == "Bash" and any(.hooks[]; .command == "\"${CLAUDE_PLUGIN_ROOT}/hooks/guard-rm.sh\""))' "$hooks_json"
fx_check "the guard-cd script is executable" test -x "$hook"

fx_report_fails
