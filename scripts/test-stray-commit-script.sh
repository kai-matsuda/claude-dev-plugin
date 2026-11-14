#!/usr/bin/env bash
# Tests for scripts/stray-commit.sh <repo> <range>, the stray-commit check (glossary: Stray-commit
# check) as one call: run on a scratch git repo, reading only what it printed and its exit status.
# The first non-merge commit of the range whose author is not the repo's user.email, or that has no
# Bead: trailer, is one "stray commit <sha> <subject>" line and exit 1; a clean or empty range
# prints nothing and exits 0; a merge commit passes unless it changes a path the merge of its parents
# does not, outside its conflicted paths (one "stray merge <sha> adds <path>" line, exit 1); a wrong usage is one refusal line, exit 2.
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

# a clean merge passes, whatever its author or trailer
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

# a merge adding content found in neither parent, outside any conflicted path: stopped, naming the merge and the path
git -C "$r" reset -q --hard "$base"
git -C "$r" checkout -q -b side2
commit s2.txt "feat: side two" "" "Bead: x-7"
git -C "$r" checkout -q main
commit m2.txt "feat: main two" "" "Bead: x-8"
git -C "$r" merge -q --no-ff --no-commit side2
echo smuggled > "$r/smuggled.txt" && git -C "$r" add smuggled.txt
git -C "$r" commit -q -m "merge side two"
smerge=$(sha HEAD)
run "$base..HEAD"
fx_check "merge adding content: exits 1" fx_eq "$rc" 1
fx_check "merge adding content: names the merge and the path" fx_eq "$out" "stray merge $smerge adds smuggled.txt"

# a conflict resolution changing only the conflicted path passes
git -C "$r" reset -q --hard "$base"
git -C "$r" checkout -q -b side3
commit x.txt "side version" "" "Bead: x-9"
git -C "$r" checkout -q main
commit x.txt "main version" "" "Bead: x-10"
git -C "$r" merge --no-ff side3 >/dev/null 2>&1
fx_check "conflict fixture: the merge conflicted" fx_eq "$(git -C "$r" ls-files -u | wc -l | tr -d ' ')" 2
echo resolved > "$r/x.txt" && git -C "$r" add x.txt
git -C "$r" commit -q -m "merge side three"
run "$base..HEAD"
fx_check "conflict resolution: exits 0" fx_eq "$rc" 0
fx_check "conflict resolution: prints nothing" fx_eq "$out" ""

# a conflict resolution that also adds a path outside the conflict is stopped
git -C "$r" reset -q --hard HEAD^
git -C "$r" merge --no-ff side3 >/dev/null 2>&1
echo resolved > "$r/x.txt" && git -C "$r" add x.txt
echo smuggled > "$r/extra.txt" && git -C "$r" add extra.txt
git -C "$r" commit -q -m "merge side three plus"
cmerge=$(sha HEAD)
run "$base..HEAD"
fx_check "conflict resolution plus extra: exits 1" fx_eq "$rc" 1
fx_check "conflict resolution plus extra: names the merge and the extra path" fx_eq "$out" "stray merge $cmerge adds extra.txt"

# usage
out=$("$script" "$r" 2>&1); rc=$?
fx_check "usage: exits 2" fx_eq "$rc" 2
fx_check "usage: one refusal line" fx_eq "$(wc -l <<<"$out" | tr -d ' ')" 1
run "nosuchref..HEAD"
fx_check "unreadable range: exits 2" fx_eq "$rc" 2
fx_check "unreadable range: one refusal line" fx_eq "$(wc -l <<<"$out" | tr -d ' ')" 1

# not a git checkout (a plain directory inside the scratch, under an enclosing checkout): refused
mkdir -p "$scratch/plain"
out=$("$script" "$scratch/plain" "HEAD..HEAD" 2>&1); rc=$?
fx_check "non-repo: exits 2" fx_eq "$rc" 2
fx_check "non-repo: one refusal line" fx_eq "$(wc -l <<<"$out" | tr -d ' ')" 1
fx_check "non-repo: the line is refused: <reason>" fx_eq "$out" "refused: $scratch/plain is not a git checkout"

# a repo with no user.email (no global or system config to fall back on): refused
n=$scratch/noemail
fx_git_repo "$n" || { echo "FAIL make repo noemail"; exit 1; }
git -C "$n" config --unset user.email
out=$(GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 "$script" "$n" "HEAD..HEAD" 2>&1); rc=$?
fx_check "no user.email: exits 2" fx_eq "$rc" 2
fx_check "no user.email: one refusal line" fx_eq "$(wc -l <<<"$out" | tr -d ' ')" 1
fx_check "no user.email: the line is refused: <reason>" fx_eq "$out" "refused: $n has no user.email"

fx_report_fails
