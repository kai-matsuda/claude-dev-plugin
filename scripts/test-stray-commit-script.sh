#!/usr/bin/env bash
# Tests for scripts/stray-commit.sh <repo> <range>, the stray-commit check (glossary: Stray-commit
# check) as one call: run on a scratch git repo, reading only what it printed and its exit status.
# The first non-merge commit of the range whose author is not the repo's user.email, or that has no
# Bead: trailer, is one "stray commit <sha> <subject>" line and exit 1; a clean or empty range
# prints nothing and exits 0; a two-parent merge commit passes unless it changes a path the merge of
# its parents does not, outside its conflicted paths and the paths derived from them, such as a file/directory conflict's side path (one "stray merge <sha> changes <path>" line,
# exit 1); an octopus merge (more than two parents), a merge whose parents git merge-tree cannot merge
# and a failed diff-tree are each one refusal line, exit 2, as is a wrong usage.
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
git -C "$r" -c user.email=other@example.invalid merge -q --no-ff -m "merge side" side >/dev/null
fx_check "merge fixture: the tip is a merge" fx_eq "$(git -C "$r" rev-list --parents -n1 HEAD | wc -w | tr -d ' ')" 3
run "$base..HEAD"
fx_check "clean merge: exits 0" fx_eq "$rc" 0
fx_check "clean merge: prints nothing" fx_eq "$out" ""

# a merge adding content found in neither parent, outside any conflicted path: stopped, naming the merge and the path
git -C "$r" reset -q --hard "$base"
git -C "$r" checkout -q -b side2
commit s2.txt "feat: side two" "" "Bead: x-7"
git -C "$r" checkout -q main
commit m2.txt "feat: main two" "" "Bead: x-8"
git -C "$r" merge -q --no-ff --no-commit side2 >/dev/null 2>&1
echo smuggled > "$r/smuggled.txt" && git -C "$r" add smuggled.txt
git -C "$r" commit -q -m "merge side two"
smerge=$(sha HEAD)
run "$base..HEAD"
fx_check "merge adding content: exits 1" fx_eq "$rc" 1
fx_check "merge adding content: names the merge and the path" fx_eq "$out" "stray merge $smerge changes smuggled.txt"

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
fx_check "conflict resolution plus extra: names the merge and the extra path" fx_eq "$out" "stray merge $cmerge changes extra.txt"

# a file/directory conflict (main has dd/f, side5 has a file dd) resolved by keeping the file: git lists only
# the side path dd~<sha>, and the resolution removes it, adds dd and removes dd/f, all derived from the conflict
git -C "$r" reset -q --hard "$base"
git -C "$r" checkout -q -b side5
commit dd "side file" "" "Bead: x-16"
git -C "$r" checkout -q main
mkdir -p "$r/dd" && commit dd/f "main file in dir" "" "Bead: x-17"
# resolve_keep_file <extra file>: after the conflicted merge, keep the file dd and commit with the extra file
resolve_keep_file() {
  git -C "$r" merge --no-ff side5 >/dev/null 2>&1
  git -C "$r" rm -q -r -f dd >/dev/null
  mv "$r"/dd~* "$r/dd" && [ -z "$1" ] || echo smuggled > "$r/$1"
  git -C "$r" add -A && git -C "$r" commit -q -m "merge side five"
}
resolve_keep_file ""
run "$base..HEAD"
fx_check "file/dir resolution: exits 0" fx_eq "$rc" 0
fx_check "file/dir resolution: prints nothing" fx_eq "$out" ""

# the same resolution plus an unrelated path is still stopped
git -C "$r" reset -q --hard HEAD^
resolve_keep_file extra5.txt
fmerge=$(sha HEAD)
run "$base..HEAD"
fx_check "file/dir resolution plus extra: exits 1" fx_eq "$rc" 1
fx_check "file/dir resolution plus extra: names the extra path" fx_eq "$out" "stray merge $fmerge changes extra5.txt"

# a conflicted path git would quote (non-ASCII) resolves cleanly
git -C "$r" reset -q --hard "$base"
git -C "$r" checkout -q -b side6
commit "é.txt" "side version" "" "Bead: x-18"
git -C "$r" checkout -q main
commit "é.txt" "main version" "" "Bead: x-19"
git -C "$r" merge --no-ff side6 >/dev/null 2>&1
echo resolved > "$r/é.txt" && git -C "$r" add -A
git -C "$r" commit -q -m "merge side six"
run "$base..HEAD"
fx_check "quoted path resolution: exits 0" fx_eq "$rc" 0
fx_check "quoted path resolution: prints nothing" fx_eq "$out" ""

# an octopus merge is refused, not passed unread
git -C "$r" reset -q --hard "$base"
for b in o1 o2 o3; do
  git -C "$r" checkout -q -b "$b" "$base"
  commit "$b.txt" "feat: $b" "" "Bead: x-11"
done
git -C "$r" checkout -q main
commit m5.txt "feat: main five" "" "Bead: x-15"
git -C "$r" merge -q --no-ff -m "octopus" o1 o2 o3 >/dev/null 2>&1
omerge=$(sha HEAD)
fx_check "octopus fixture: the tip has four parents" fx_eq "$(git -C "$r" rev-list --parents -n1 HEAD | wc -w | tr -d ' ')" 5
run "$base..HEAD"
fx_check "octopus merge: exits 2" fx_eq "$rc" 2
fx_check "octopus merge: the refusal line" fx_eq "$out" "refused: octopus merge $omerge in $r is not read"

# a merge whose parents git merge-tree cannot merge (unrelated histories) is refused
git -C "$r" reset -q --hard "$base"
git -C "$r" checkout -q --orphan unrelated
git -C "$r" rm -rq -f . >/dev/null 2>&1
commit u.txt "feat: unrelated" "" "Bead: x-12"
git -C "$r" checkout -q main
git -C "$r" merge -q --no-ff --allow-unrelated-histories -m "merge unrelated" unrelated >/dev/null 2>&1
umerge=$(sha HEAD)
fx_check "unrelated fixture: the tip is a merge" fx_eq "$(git -C "$r" rev-list --parents -n1 HEAD | wc -w | tr -d ' ')" 3
run "$base..HEAD"
fx_check "merge-tree failure: exits 2" fx_eq "$rc" 2
fx_check "merge-tree failure: the refusal line" fx_eq "$out" "refused: cannot merge-tree $umerge in $r"

# a failed diff-tree is refused, not read as no changed paths (a git on PATH that fails diff-tree)
git -C "$r" reset -q --hard "$base"
git -C "$r" checkout -q -b side4
commit s4.txt "feat: side four" "" "Bead: x-13"
git -C "$r" checkout -q main
commit m4.txt "feat: main four" "" "Bead: x-14"
git -C "$r" merge -q --no-ff -m "merge side four" side4 >/dev/null
dmerge=$(sha HEAD)
mkdir -p "$scratch/stubbin"
real_git=$(command -v git)
printf '#!/bin/sh\nfor a in "$@"; do [ "$a" = diff-tree ] && exit 128; done\nexec "%s" "$@"\n' "$real_git" > "$scratch/stubbin/git"
chmod +x "$scratch/stubbin/git"
out=$(PATH="$scratch/stubbin:$PATH" "$script" "$r" "$base..HEAD" 2>&1); rc=$?
fx_check "diff-tree failure: exits 2" fx_eq "$rc" 2
fx_check "diff-tree failure: the refusal line" fx_eq "$out" "refused: cannot diff-tree $dmerge in $r"

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
