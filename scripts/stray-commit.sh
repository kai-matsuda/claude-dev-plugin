#!/usr/bin/env bash
# The stray-commit check (glossary: Stray-commit check) as one call. Reads every non-merge commit
# of <range> in <repo>, oldest first; the first whose author is not the repo's user.email, or that
# has no Bead: trailer, is printed as "stray commit <sha> <subject>" and the script exits 1. Then
# each two-parent merge commit of <range> is compared with the merge of its parents (git
# merge-tree): a path the merge changed that the parents' merge did not report as conflicted is
# printed as "stray merge <sha> adds <path>" and the script exits 1. A clean or empty range prints
# nothing and exits 0. A wrong usage, a non-repo or an unreadable range is one refusal line and exit 2.
# Usage: scripts/stray-commit.sh <repo> <range>
set -uo pipefail
[ "$#" = 2 ] || { echo "refused: usage: stray-commit.sh <repo> <range>"; exit 2; }
repo=$1 range=$2

top=$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null) \
  && [ "$top" = "$(cd "$repo" && pwd -P)" ] \
  || { echo "refused: $repo is not a git checkout"; exit 2; }
email=$(git -C "$repo" config user.email 2>/dev/null) \
  || { echo "refused: $repo has no user.email"; exit 2; }
log=$(git -C "$repo" log --no-merges --reverse \
  --format='%H%x1f%ae%x1f%(trailers:key=Bead,valueonly,separator=%x2C)%x1f%s' "$range" -- 2>/dev/null) \
  || { echo "refused: cannot read $range in $repo"; exit 2; }

merges=$(git -C "$repo" log --merges --reverse --format='%H %P' "$range" -- 2>/dev/null) \
  || { echo "refused: cannot read $range in $repo"; exit 2; }

sep=$(printf '\037')
if [ -n "$log" ]; then
  while IFS="$sep" read -r sha author bead subject; do
    if [ "$author" != "$email" ] || [ -z "$bead" ]; then
      echo "stray commit $sha $subject"
      exit 1
    fi
  done <<<"$log"
fi

# A merge adds nothing of its own: its tree equals the merge of its parents, bar the paths that
# merge reported as conflicted. Any other differing path is content no commit carries. Only
# two-parent merges are compared; git merge-tree takes two parents, so an octopus merge is not read.
[ -n "$merges" ] || exit 0
while read -r sha p1 p2 extra; do
  [ -n "$p2" ] && [ -z "$extra" ] || continue
  mt=$(git -C "$repo" merge-tree --write-tree --name-only "$p1" "$p2" 2>/dev/null); rc=$?
  [ "$rc" = 0 ] || [ "$rc" = 1 ] || { echo "refused: cannot merge-tree $sha in $repo"; exit 2; }
  tree=$(sed -n 1p <<<"$mt")
  conflicted=$(sed -n '2,/^$/p' <<<"$mt")
  [ "$rc" = 1 ] || conflicted=
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    grep -qxF -- "$path" <<<"$conflicted" && continue
    echo "stray merge $sha adds $path"
    exit 1
  done < <(git -C "$repo" diff-tree -r --name-only --no-renames "$tree" "$sha")
done <<<"$merges"
exit 0
