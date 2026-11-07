#!/usr/bin/env bash
# The stray-commit check (glossary: Stray-commit check) as one call. Reads every non-merge commit
# of <range> in <repo>, oldest first; the first whose author is not the repo's user.email, or that
# has no Bead: trailer, is printed as "stray commit <sha> <subject>" and the script exits 1. A
# clean or empty range prints nothing and exits 0. A wrong usage, a non-repo or an unreadable
# range is one refusal line and exit 2.
# Usage: scripts/stray-commit.sh <repo> <range>
set -uo pipefail
[ "$#" = 2 ] || { echo "stray-commit.sh refused: usage: stray-commit.sh <repo> <range>"; exit 2; }
repo=$1 range=$2

email=$(git -C "$repo" config user.email 2>/dev/null) \
  || { echo "stray-commit.sh refused: $repo has no user.email"; exit 2; }
log=$(git -C "$repo" log --no-merges --reverse \
  --format='%H%x1f%ae%x1f%(trailers:key=Bead,valueonly,separator=%x2C)%x1f%s' "$range" -- 2>/dev/null) \
  || { echo "stray-commit.sh refused: cannot read $range in $repo"; exit 2; }

[ -n "$log" ] || exit 0
sep=$(printf '\037')
while IFS="$sep" read -r sha author bead subject; do
  if [ "$author" != "$email" ] || [ -z "$bead" ]; then
    echo "stray commit $sha $subject"
    exit 1
  fi
done <<<"$log"
exit 0
