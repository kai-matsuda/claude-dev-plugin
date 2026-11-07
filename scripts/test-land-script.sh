#!/usr/bin/env bash
# Tests for scripts/land.sh <owner> <branch> <task branch> <tip> [--ff-only], the Land script: run
# on a scratch git repo, reading the one line it printed, its exit status, where <branch> points
# and the owner checkout's status --porcelain. landed <sha> is exit 0, conflict exit 1 with the
# owner checkout clean, refused: <reason> exit 2 with nothing merged.
# Usage: scripts/test-land-script.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_scratch_dir, fx_check, fx_git_repo, fx_eq, fx_report_fails
script=$repo_root/scripts/land.sh

fx_scratch_dir land-script
scratch=$(cd "$scratch" && pwd -P)

r=$scratch/repo
fx_git_repo "$r" || { echo "FAIL make repo"; exit 1; }
# commit <file> <content> <subject> [<author email>] [<trailer>]: a commit on the current branch
commit() {
  local msg=$3
  [ -z "${5:-}" ] || msg=$(printf '%s\n\n%s' "$3" "$5")
  echo "$2" > "$r/$1" && git -C "$r" add "$1"
  if [ -n "${4:-}" ]; then git -C "$r" -c user.email="$4" commit -q -m "$msg"
  else git -C "$r" commit -q -m "$msg"; fi
}
sha() { git -C "$r" rev-parse "$1"; }
status() { git -C "$r" status --porcelain; }
run() { out=$("$script" "$r" "$@" 2>&1); rc=$?; }
# reset: main at base, a task branch "task" one clean commit ahead, main checked out
reset() {
  git -C "$r" checkout -q -f main && git -C "$r" reset -q --hard "$base" && git -C "$r" clean -qfd
  git -C "$r" branch -q -D task feat/t-9 2>/dev/null
  git -C "$r" checkout -q -b task && commit t.txt t "feat: task work" "" "Bead: x-2"
  tip=$(sha task)
  git -C "$r" checkout -q main
}

commit base.txt base "chore: base" "" "Bead: x-1"
base=$(sha HEAD)

# plain merge: main moved on, so the merge is a real merge commit
reset
commit m.txt m "feat: main moved" "" "Bead: x-3"
mainbefore=$(sha main)
run main task "$tip"
merged=$(sha main)
fx_check "plain merge: exits 0" fx_eq "$rc" 0
fx_check "plain merge: landed line" fx_eq "$out" "landed $merged"
fx_check "plain merge: main is a merge of base and the tip" fx_eq "$(sha main^1) $(sha main^2)" "$mainbefore $tip"
fx_check "plain merge: clean checkout" fx_eq "$(status)" ""

# --ff-only landing
reset
run main task "$tip" --ff-only
fx_check "ff-only: exits 0" fx_eq "$rc" 0
fx_check "ff-only: landed the tip" fx_eq "$out" "landed $tip"
fx_check "ff-only: main is the tip" fx_eq "$(sha main)" "$tip"
fx_check "ff-only: clean checkout" fx_eq "$(status)" ""

# re-land: the tip is already in main, nothing is merged
before=$(sha main)
run main task "$tip" --ff-only
fx_check "re-land ff-only: exits 0" fx_eq "$rc" 0
fx_check "re-land ff-only: landed line" fx_eq "$out" "landed $before"
fx_check "re-land ff-only: main unmoved" fx_eq "$(sha main)" "$before"
fx_check "re-land ff-only: clean checkout" fx_eq "$(status)" ""
reset
run main task "$tip"
again=$(sha main)
run main task "$tip"
fx_check "re-land after plain merge: exits 0" fx_eq "$rc" 0
fx_check "re-land after plain merge: landed line" fx_eq "$out" "landed $again"
fx_check "re-land after plain merge: main unmoved" fx_eq "$(sha main)" "$again"
fx_check "re-land after plain merge: clean checkout" fx_eq "$(status)" ""

# conflict: main edits the same file, the merge is aborted, the checkout is clean
reset
git -C "$r" checkout -q task && commit c.txt task-side "feat: task c" "" "Bead: x-2" && tip=$(sha task)
git -C "$r" checkout -q main && commit c.txt main-side "feat: main c" "" "Bead: x-3"
mainbefore=$(sha main)
run main task "$tip"
fx_check "conflict: exits 1" fx_eq "$rc" 1
fx_check "conflict: the line" fx_eq "$out" "conflict"
fx_check "conflict: main unmoved" fx_eq "$(sha main)" "$mainbefore"
fx_check "conflict: clean checkout" fx_eq "$(status)" ""

# diverged: main moved on, --ff-only refuses
reset
commit m.txt m "feat: main moved" "" "Bead: x-3"
mainbefore=$(sha main)
run main task "$tip" --ff-only
fx_check "diverged: exits 2" fx_eq "$rc" 2
fx_check "diverged: the line" fx_eq "$out" "refused: diverged"
fx_check "diverged: main unmoved" fx_eq "$(sha main)" "$mainbefore"
fx_check "diverged: clean checkout" fx_eq "$(status)" ""

# not on the branch
reset
git -C "$r" checkout -q task
run main task "$tip"
fx_check "not on branch: exits 2" fx_eq "$rc" 2
fx_check "not on branch: the line" fx_eq "$out" "refused: not on main"
fx_check "not on branch: main unmoved" fx_eq "$(sha main)" "$base"
fx_check "not on branch: clean checkout" fx_eq "$(status)" ""

# dirty tracked file
reset
echo dirty >> "$r/base.txt"
run main task "$tip"
fx_check "dirty tracked: exits 2" fx_eq "$rc" 2
fx_check "dirty tracked: the line" fx_eq "$out" "refused: owner checkout dirty: base.txt"
fx_check "dirty tracked: main unmoved" fx_eq "$(sha main)" "$base"
fx_check "dirty tracked: status shows the edit" fx_eq "$(status)" " M base.txt"

# dirty untracked file
reset
echo u > "$r/untracked.txt"
run main task "$tip"
fx_check "dirty untracked: exits 2" fx_eq "$rc" 2
fx_check "dirty untracked: the line" fx_eq "$out" "refused: owner checkout dirty: untracked.txt"
fx_check "dirty untracked: main unmoved" fx_eq "$(sha main)" "$base"
fx_check "dirty untracked: status shows the file" fx_eq "$(status)" "?? untracked.txt"

# task branch moved past the expected tip
reset
git -C "$r" branch -q -m task feat/t-9
git -C "$r" checkout -q feat/t-9 && commit t2.txt t2 "feat: more" "" "Bead: x-2"
git -C "$r" checkout -q main
run main feat/t-9 "$tip"
fx_check "moved past tip: exits 2" fx_eq "$rc" 2
fx_check "moved past tip: the line" fx_eq "$out" "refused: feat/t-9 moved past $tip"
fx_check "moved past tip: main unmoved" fx_eq "$(sha main)" "$base"
fx_check "moved past tip: clean checkout" fx_eq "$(status)" ""

# stray author
reset
git -C "$r" checkout -q task && commit s.txt s "feat: other author" other@example.invalid "Bead: x-4"
stray=$(sha task); tip=$stray
git -C "$r" checkout -q main
run main task "$tip"
fx_check "stray author: exits 2" fx_eq "$rc" 2
fx_check "stray author: the line" fx_eq "$out" "refused: stray commit $stray feat: other author"
fx_check "stray author: main unmoved" fx_eq "$(sha main)" "$base"
fx_check "stray author: clean checkout" fx_eq "$(status)" ""

# missing Bead: trailer
reset
git -C "$r" checkout -q task && commit n.txt n "fix: no trailer"
nb=$(sha task); tip=$nb
git -C "$r" checkout -q main
run main task "$tip"
fx_check "missing trailer: exits 2" fx_eq "$rc" 2
fx_check "missing trailer: the line" fx_eq "$out" "refused: stray commit $nb fix: no trailer"
fx_check "missing trailer: main unmoved" fx_eq "$(sha main)" "$base"
fx_check "missing trailer: clean checkout" fx_eq "$(status)" ""

# renamed tracked file: the dirty list names the new path only
reset
git -C "$r" mv base.txt moved.txt
run main task "$tip"
fx_check "dirty rename: the line" fx_eq "$out" "refused: owner checkout dirty: moved.txt"
fx_check "dirty rename: exits 2" fx_eq "$rc" 2
git -C "$r" reset -q --hard "$base"

# a non-repo owner
nogit=$scratch/not-a-repo; mkdir -p "$nogit"
out=$("$script" "$nogit" main task "$tip" 2>&1); rc=$?
fx_check "non-repo owner: exits 2" fx_eq "$rc" 2
fx_check "non-repo owner: the line" fx_eq "$out" "refused: $nogit is not a git checkout"

# usage: too few, too many and a wrong flag are each one refusal line, exit 2
for args in "main task" "main task $tip --ff-only extra" "main task $tip --force"; do
  out=$("$script" "$r" $args 2>&1); rc=$?
  fx_check "usage ($args): exits 2" fx_eq "$rc" 2
  fx_check "usage ($args): one refusal line" fx_eq "$(wc -l <<<"$out" | tr -d ' ')|${out%%:*}" "1|refused"
done

fx_report_fails
