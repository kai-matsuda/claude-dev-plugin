#!/usr/bin/env bash
# The stray-commit check (glossary: Stray-commit check) as one call. Reads every non-merge commit
# of <range> in <repo>, oldest first; the first whose author is not the repo's user.email, or that
# has no Bead: trailer, is printed as "stray commit <sha> <subject>" and the script exits 1. Then
# each merge commit of <range> is compared with the merge of its parents (git merge-tree): a path
# the merge changed that the parents' merge did not report as conflicted, nor derive from a
# conflicted path (a file/directory conflict's side path <path>~<name>, <path> itself and what
# lies under <path>/), is printed as
# "stray merge <sha> changes <path>" and the script exits 1. Merges are not checked for author or
# Bead: trailer. A clean or empty range prints nothing and exits 0. A wrong usage, a non-repo, no
# user.email, an unreadable range, an octopus merge (more than two parents, which git merge-tree
# cannot compare), a merge whose parents git merge-tree cannot merge, or a failed git diff-tree is
# one refusal line and exit 2.
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
  && merges=$(git -C "$repo" log --merges --reverse --format='%H %P' "$range" -- 2>/dev/null) \
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

# A merge made with git's default ort strategy and default options adds nothing of its own: its
# tree equals the merge of its parents, bar the paths that merge reported as conflicted. Any other
# differing path is content no commit carries (dev-bxtw). A merge made otherwise (-X, -s recursive,
# a different merge.renames or rename limit) can differ from merge-tree on auto-merged paths, and
# those show as "stray merge". Only two-parent merges are compared (git merge-tree takes two
# parents), so an octopus merge is refused.
[ -n "$merges" ] || exit 0
work=$(mktemp -d "${TMPDIR:-/tmp}/stray-commit.XXXXXX") || { echo "refused: cannot make a scratch directory"; exit 2; }
trap 'rm -rf "$work"' EXIT
# A path is conflicted when merge-tree listed it or git derived it from a listed one. For a
# file/directory conflict git lists only the displaced side <path>~<name>, so <path> (a name that
# may itself contain ~, which then also passes as <path>), what lies under <path>/ and any other
# <path>~<name> count as conflicted too: resolving it removes or replaces them.
is_conflicted() {
  local c base
  for c in ${conflicted[@]+"${conflicted[@]}"}; do
    [ "$1" = "$c" ] && return 0
    base=${c%~*}
    [ "$base" != "$c" ] || continue
    [ "$1" = "$base" ] && return 0
    case $1 in "$base"/* | "$base"~*) return 0 ;; esac
  done
  return 1
}
while read -r sha p1 p2 extra; do
  [ -z "$extra" ] || { echo "refused: octopus merge $sha in $repo is not read"; exit 2; }
  git -C "$repo" merge-tree --write-tree --name-only -z "$p1" "$p2" >"$work/mt" 2>/dev/null; rc=$?
  [ "$rc" = 0 ] || [ "$rc" = 1 ] || { echo "refused: cannot merge-tree $sha in $repo"; exit 2; }
  tree= conflicted=()
  n=0
  while IFS= read -r -d '' field; do
    [ "$n" != 0 ] || { tree=$field; n=1; [ "$rc" = 1 ] || break; continue; }
    [ -n "$field" ] || break
    conflicted+=("$field")
  done <"$work/mt"
  git -C "$repo" diff-tree -r -z --name-only --no-renames "$tree" "$sha" >"$work/changed" 2>/dev/null \
    || { echo "refused: cannot diff-tree $sha in $repo"; exit 2; }
  while IFS= read -r -d '' path; do
    is_conflicted "$path" && continue
    echo "stray merge $sha changes $path"
    exit 1
  done <"$work/changed"
done <<<"$merges"
exit 0
