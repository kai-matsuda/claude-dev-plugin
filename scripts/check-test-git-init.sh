#!/usr/bin/env bash
# Refuses a git init in any test script (scripts/test-*.sh) outside scripts/fixture-test-lib.sh:
# a test makes a throwaway repo with the lib's fx_git_repo, which refuses a dir that is not the
# new repo's top level, since a half-made init lets the test's add and commit climb into the
# enclosing checkout (21f770c). Comments are skipped; each hit prints <script>:<line>: <text>.
# A line-by-line heuristic: it sees git, a path ending in /git or a git_* wrapper, then init as
# a later word, so an init split over a continuation line or behind another wrapper name slips by,
# and a commit message that is just init is a false hit (reword it).
# Usage: scripts/check-test-git-init.sh [ROOT]   (ROOT defaults to the repo this script is in)
set -uo pipefail
root=${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
shopt -s nullglob
scripts=("$root"/scripts/test-*.sh)
[ "${#scripts[@]}" -gt 0 ] || exit 0
# git or a git_* wrapper as a word, then any arguments, then init as a word
awk -v root="$root/" '
  { code = $0; sub(/^[[:space:]]*#.*/, "", code); sub(/[[:space:]]#.*/, "", code) }
  code ~ /(^|[^[:alnum:]_.\/-]|\/)git(_[[:alnum:]_]+)?([[:space:]]+[^[:space:];&|]+)*[[:space:]]+init([[:space:];&|)]|$)/ {
    f = FILENAME; if (index(f, root) == 1) f = substr(f, length(root) + 1); print f ":" FNR ": " $0; bad = 1 }
  END { if (bad) { print "check-test-git-init: a test script runs git init outside scripts/fixture-test-lib.sh; make the repo with fx_git_repo" > "/dev/stderr"; exit 1 } }
' "${scripts[@]}"
