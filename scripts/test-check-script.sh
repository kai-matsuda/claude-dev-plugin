#!/usr/bin/env bash
# Tests for scripts/check.sh <worktree path> <owner>, the one call an orchestrator checks a tree
# with (glossary: Check record): run on scratch git repos, reading only what it printed, its exit
# status and what it left under <owner>/.tmp/checks/<tree>/. A green record on the tip's tree
# prints its line and runs no make; any other tree runs make check in the worktree with TMPDIR
# inside it; a red prints the log's last forty lines and is run again next time; a worktree that
# is no git checkout or an owner with no check target is one refusal line and no record.
# Usage: scripts/test-check-script.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_scratch_dir, fx_check, fx_git_repo, fx_eq, fx_report_fails
script=$repo_root/scripts/check.sh

fx_scratch_dir check-script
scratch=$(cd "$scratch" && pwd -P)

# make_repo <name>: a scratch repo on main whose check recipe appends to <name>.runs, records
# $TMPDIR in <name>.tmpdir, prints the log filler and exits with the number in <name>.rc
make_repo() {
  local d=$scratch/$1
  fx_git_repo "$d" || { echo "FAIL make repo $1"; exit 1; }
  printf 'check:\n\t@echo run >> %s.runs; echo "$$TMPDIR" > %s.tmpdir; seq 1 60; exit $$(cat %s.rc)\n' \
    "$d" "$d" "$d" > "$d/Makefile"
  echo 0 > "$d.rc"
  git -C "$d" add Makefile && git -C "$d" commit -q -m first
  echo "$d"
}
runs() { cat "$1.runs" 2>/dev/null | wc -l | tr -d ' '; }
tree_of() { git -C "$1" rev-parse 'HEAD^{tree}'; }

# first run on a green tree
w=$(make_repo green)
out1=$("$script" "$w" "$w" 2>&1); rc1=$?
t=$(tree_of "$w"); rec=$w/.tmp/checks/$t
fx_check "green: exits 0" fx_eq "$rc1" 0
fx_check "green: prints the record line" fx_eq "$out1" "command=make check exit=0"
fx_check "green: record holds the line" fx_eq "$(cat "$rec/record" 2>/dev/null)" "command=make check exit=0"
fx_check "green: log holds the recipe's output" grep -q '^60$' "$rec/log"
fx_check "green: make ran once" fx_eq "$(runs "$w")" 1
fx_check "TMPDIR is inside the worktree during the check" fx_eq "$(cat "$w.tmpdir")" "$w/.tmp"

# second run on the same tree: no make
out2=$("$script" "$w" "$w" 2>&1); rc2=$?
fx_check "green again: exits 0" fx_eq "$rc2" 0
fx_check "green again: same line" fx_eq "$out2" "$out1"
fx_check "green again: runs no make" fx_eq "$(runs "$w")" 1

# an empty commit keeps the tree: hits the record; a changed tree misses it
git -C "$w" commit -q --allow-empty -m empty
"$script" "$w" "$w" >/dev/null 2>&1
fx_check "empty commit: hits the record" fx_eq "$(runs "$w")" 1
echo more >> "$w/Makefile.extra" && git -C "$w" add Makefile.extra && git -C "$w" commit -q -m change
"$script" "$w" "$w" >/dev/null 2>&1
fx_check "changed tree: runs make" fx_eq "$(runs "$w")" 2
fx_check "changed tree: its own record" test -f "$w/.tmp/checks/$(tree_of "$w")/record"

# red: record, tail, and a rerun
r=$(make_repo red)
echo 2 > "$r.rc"
outr=$("$script" "$r" "$r" 2>&1); rcr=$?
fx_check "red: exits with the check's status" fx_eq "$rcr" 2
fx_check "red: first line is the record line" fx_eq "$(head -1 <<<"$outr")" "command=make check exit=2"
fx_check "red: record keeps the exit" fx_eq "$(cat "$r/.tmp/checks/$(tree_of "$r")/record")" "command=make check exit=2"
fx_check "red: prints the log's last forty lines" fx_eq "$(tail -n +2 <<<"$outr" | head -40 | head -1)" "$(tail -n 40 "$r/.tmp/checks/$(tree_of "$r")/log" | head -1)"
fx_check "red: prints exactly forty lines after the record line" fx_eq "$(tail -n +2 <<<"$outr" | wc -l | tr -d ' ')" 40
"$script" "$r" "$r" >/dev/null 2>&1
fx_check "red: the next run runs make again" fx_eq "$(runs "$r")" 2
echo 0 > "$r.rc"
"$script" "$r" "$r" >/dev/null 2>&1; rcg=$?
fx_check "red then fixed: green, exits 0" fx_eq "$rcg" 0
fx_check "red then fixed: record is green" fx_eq "$(cat "$r/.tmp/checks/$(tree_of "$r")/record")" "command=make check exit=0"

# worktree apart from the owner: the record lands under the owner
o=$(make_repo owner)
w2=$(make_repo apart)
"$script" "$w2" "$o" >/dev/null 2>&1
fx_check "apart: record under the owner" test -f "$o/.tmp/checks/$(tree_of "$w2")/record"
fx_check "apart: make ran in the worktree, TMPDIR in the worktree" fx_eq "$(cat "$w2.tmpdir")" "$w2/.tmp"

# refusals: one line, non-zero, no record
mkdir -p "$scratch/plain"
before=$(ls "$o/.tmp/checks")
outp=$("$script" "$scratch/plain" "$o" 2>&1); rcp=$?
fx_check "not a git checkout: non-zero exit" test "$rcp" != 0
fx_check "not a git checkout: one line" fx_eq "$(wc -l <<<"$outp" | tr -d ' ')" 1
fx_check "not a git checkout: writes nothing" test ! -e "$scratch/plain/.tmp"
fx_check "not a git checkout: no record under the owner" fx_eq "$(ls "$o/.tmp/checks")" "$before"
n=$(make_repo nocheck)
printf 'all:\n\t@true\n' > "$n/Makefile" && git -C "$n" commit -q -am nocheck
outn=$("$script" "$w2" "$n" 2>&1); rcn=$?
fx_check "no check target: non-zero exit" test "$rcn" != 0
fx_check "no check target: one line" fx_eq "$(wc -l <<<"$outn" | tr -d ' ')" 1
fx_check "no check target: writes nothing" test ! -e "$n/.tmp/checks"

# the other refusals: one line, non-zero, nothing written
outu=$("$script" "$w2" 2>&1); rcu=$?
fx_check "usage: non-zero exit" test "$rcu" != 0
fx_check "usage: one refusal line" fx_eq "$(wc -l <<<"$outu" | tr -d ' ')" 1
e=$scratch/empty
fx_git_repo "$e" || { echo "FAIL make repo empty"; exit 1; }
oute=$("$script" "$e" "$o" 2>&1); rce=$?
fx_check "no commit: non-zero exit" test "$rce" != 0
fx_check "no commit: one refusal line" fx_eq "$(wc -l <<<"$oute" | tr -d ' ')" 1
fx_check "no commit: writes nothing" test ! -e "$e/.tmp"
chmod -w "$o/.tmp/checks"
echo fresh > "$w2/fresh.txt" && git -C "$w2" add fresh.txt && git -C "$w2" commit -q -m fresh2
outc=$("$script" "$w2" "$o" 2>&1); rcc=$?
chmod +w "$o/.tmp/checks"
fx_check "cannot create record dir: non-zero exit" test "$rcc" != 0
fx_check "cannot create record dir: one refusal line" fx_eq "$(wc -l <<<"$outc" | tr -d ' ')" 1

# check.sh's make database query is the orchestration doc's
doc_awk() { grep pRrq "$1" | grep -o "awk '[^']*'"; }
fx_check "check.sh's query is the orchestration doc's" fx_eq "$(doc_awk "$script")" "$(doc_awk "$repo_root/references/orchestration.md")"

fx_report_fails
