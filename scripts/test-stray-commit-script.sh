#!/usr/bin/env bash
# Tests for scripts/stray-commit.sh <repo> <range>, the stray-commit check (glossary: Stray-commit
# check) as one call: run on a scratch git repo, reading only what it printed and its exit status.
# The first non-merge commit of the range whose author is not the repo's user.email, or that has no
# Bead: trailer, is one "stray commit <sha> <subject>" line and exit 1; a clean or empty range
# prints nothing and exits 0; merge commits are skipped; a wrong usage is one refusal line, exit 2.
# Usage: scripts/test-stray-commit-script.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_scratch_dir, fx_check, fx_git_repo, fx_eq, fx_report_fails
script=$repo_root/scripts/stray-commit.sh

fx_scratch_dir stray-commit-script
scratch=$(cd "$scratch" && pwd -P)

r=$scratch/repo
fx_git_repo "$r" || { echo "FAIL make repo"; exit 1; }
# commit <file> <subject> [<author email>] [<trailer>]: a commit on the current branch
commit() {
  local msg=$2
  [ -z "${4:-}" ] || msg=$(printf '%s\n\n%s' "$2" "$4")
  echo "$2" > "$r/$1" && git -C "$r" add "$1"
  if [ -n "${3:-}" ]; then
    git -C "$r" -c user.email="$3" commit -q -m "$msg"
  else
    git -C "$r" commit -q -m "$msg"
  fi
}
sha() { git -C "$r" rev-parse "$1"; }
run() { out=$("$script" "$r" "$1" 2>&1); rc=$?; }

commit base.txt base "" "Bead: x-1"
base=$(sha HEAD)

# a clean range
commit a.txt "feat: clean one" "" "Bead: x-2"
commit b.txt "feat: clean two" "" "Bead: x-3"
run "$base..HEAD"
fx_check "clean range: exits 0" fx_eq "$rc" 0
fx_check "clean range: prints nothing" fx_eq "$out" ""

# an empty range
run "HEAD..HEAD"
fx_check "empty range: exits 0" fx_eq "$rc" 0
fx_check "empty range: prints nothing" fx_eq "$out" ""

# a missing Bead: trailer
commit c.txt "fix: no trailer"
nobead=$(sha HEAD)
run "$base..HEAD"
fx_check "missing trailer: exits 1" fx_eq "$rc" 1
fx_check "missing trailer: the stray line" fx_eq "$out" "stray commit $nobead fix: no trailer"

# a stray author before a missing-trailer commit: the first stray in range order is reported
git -C "$r" reset -q --hard "$base"
commit a.txt "feat: clean one" "" "Bead: x-2"
commit d.txt "feat: other author" other@example.invalid "Bead: x-4"
other=$(sha HEAD)
commit e.txt "fix: no trailer"
run "$base..HEAD"
fx_check "stray author: exits 1" fx_eq "$rc" 1
fx_check "stray author: the first stray is the line" fx_eq "$out" "stray commit $other feat: other author"

# merge commits are skipped, whatever their author or trailer
git -C "$r" reset -q --hard "$base"
git -C "$r" checkout -q -b side
commit s.txt "feat: side" "" "Bead: x-5"
git -C "$r" checkout -q main
commit m.txt "feat: main" "" "Bead: x-6"
git -C "$r" -c user.email=other@example.invalid merge -q --no-ff -m "merge side" side
fx_check "merge fixture: the tip is a merge" fx_eq "$(git -C "$r" rev-list --parents -n1 HEAD | wc -w | tr -d ' ')" 3
run "$base..HEAD"
fx_check "merge skipped: exits 0" fx_eq "$rc" 0
fx_check "merge skipped: prints nothing" fx_eq "$out" ""

# usage
out=$("$script" "$r" 2>&1); rc=$?
fx_check "usage: exits 2" fx_eq "$rc" 2
fx_check "usage: one refusal line" fx_eq "$(wc -l <<<"$out" | tr -d ' ')" 1
run "nosuchref..HEAD"
fx_check "unreadable range: exits 2" fx_eq "$rc" 2

fx_report_fails
