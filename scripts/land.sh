#!/usr/bin/env bash
# The landing (glossary: Landing) as one call, touching git only. Confirms the owner checkout is on
# <branch> and clean (untracked files counted) and that <task branch> is at <tip>, runs the
# stray-commit script on <branch>..<task branch>, then makes one merge attempt (fast-forward only
# under --ff-only). One line, one exit status:
#   landed <sha>                      exit 0; <sha> is <branch>'s tip. A tip already in <branch> merges
#                                     nothing and reports the same line.
#   conflict                          exit 1, after the script's own merge --abort left the checkout clean
#   refused: <reason>                 exit 2, nothing merged; reasons: not on <branch>,
#                                     owner checkout dirty: <files>, <task branch> moved past <tip>,
#                                     stray commit <sha> <subject>, diverged (only under --ff-only),
#                                     or a wrong usage, an owner that is not a git checkout, a merge
#                                     that failed and left the checkout dirty, or a stray-commit
#                                     script refusal (its reason, relayed)
# A task branch that does not exist is a "moved past" refusal: it is not at <tip>.
# Usage: scripts/land.sh <owner> <branch> <task branch> <tip> [--ff-only]
set -uo pipefail
refuse() { echo "refused: $*"; exit 2; }
if ! { [ "$#" = 4 ] || { [ "$#" = 5 ] && [ "$5" = "--ff-only" ]; }; }; then
  refuse "usage: land.sh <owner> <branch> <task branch> <tip> [--ff-only]"
fi
owner=$1 branch=$2 task=$3 tip=$4 ff=${5:-}
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

top=$(git -C "$owner" rev-parse --show-toplevel 2>/dev/null) \
  && [ "$top" = "$(cd "$owner" && pwd -P)" ] || refuse "$owner is not a git checkout"
[ "$(git -C "$owner" symbolic-ref --short -q HEAD)" = "$branch" ] || refuse "not on $branch"
dirty=$(git -C "$owner" status --porcelain --untracked-files=all) || refuse "cannot read status of $owner"
if [ -n "$dirty" ]; then
  files=$(sed 's/^...//; s/.* -> //' <<<"$dirty" | paste -sd' ' -)
  refuse "owner checkout dirty: $files"
fi
[ "$(git -C "$owner" rev-parse -q --verify "refs/heads/$task" 2>/dev/null)" = "$tip" ] \
  || refuse "$task moved past $tip"

if ! stray=$("$here/stray-commit.sh" "$owner" "$branch..$task"); then
  stray=${stray#stray-commit.sh refused: }
  case $stray in "stray commit "*) refuse "$stray" ;; *) refuse "${stray:-stray-commit.sh failed}" ;; esac
fi

if git -C "$owner" merge-base --is-ancestor "$tip" "$branch"; then
  echo "landed $(git -C "$owner" rev-parse "$branch")"
  exit 0
fi

if [ -n "$ff" ]; then
  git -C "$owner" merge -q --ff-only "$task" >/dev/null 2>&1 || refuse "diverged"
elif ! git -C "$owner" merge -q --no-edit "$task" >/dev/null 2>&1; then
  git -C "$owner" merge --abort >/dev/null 2>&1
  [ -z "$(git -C "$owner" status --porcelain --untracked-files=all 2>/dev/null)" ] \
    || refuse "merge failed and left $owner dirty"
  echo "conflict"
  exit 1
fi
echo "landed $(git -C "$owner" rev-parse "$branch")"
