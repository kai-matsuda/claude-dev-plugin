#!/usr/bin/env bash
# Tests for skills/glossary-lint/glossary-lint.sh: on a throwaway repo holding the fixture
# glossary, whose _Avoid_ notes wrap across lines (a parenthetical, and a list), every term on
# either line is flagged and a clean doc passes; and the plugin's own GLOSSARY.md parses.
# Usage: scripts/test-glossary-lint.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lint=$repo_root/skills/glossary-lint/glossary-lint.sh
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_scratch_dir, fx_is_repo_top, fx_check, fx_report_fails
fx_scratch_dir test-glossary-lint || exit 1

# run_lint <dir>: the lint's output, then its exit code on a last line
run_lint() { local out rc; out=$(cd "$1" && sh "$lint" 2>&1); rc=$?; printf '%s\n%s\n' "$out" "$rc"; }
exit_is() { [ "${2##*$'\n'}" = "$1" ]; }   # <code> <run_lint output>

repo=$scratch/repo
mkdir -p "$repo"
# separate git dir: the sandbox refuses writes to any .git/config; GIT_CEILING_DIRECTORIES and
# is_repo_top keep a failed init from adding into the enclosing checkout
GIT_CEILING_DIRECTORIES=$scratch git init -q --template= --separate-git-dir="$scratch/repo.gd" "$repo" \
  && fx_is_repo_top "$repo" || { echo "FAIL make the throwaway repo"; exit 1; }
cp "$repo_root/scripts/fixtures/glossary-lint/GLOSSARY.md" "$repo/"
printf 'The gate ticket waits.\n' > "$repo/clean.md"
printf 'This is a manual step.\nIt waits on a human ticket.\nIn the home base repo.\n' > "$repo/dirty.md"
git -C "$repo" add -A

out=$(run_lint "$repo")
fx_check "a glossary with wrapped _Avoid_ notes parses (exit 1 on the hits, not 2)" exit_is 1 "$out"
fx_check "a term after a wrapped parenthetical is flagged" grep -qF 'dirty.md:1: "manual step"' <<<"$out"
fx_check "a term before the wrapped parenthetical is flagged" grep -qF 'dirty.md:2: "human ticket"' <<<"$out"
fx_check "a term on a wrapped list's next line is flagged" grep -qF 'dirty.md:3: "home base"' <<<"$out"
fx_check "the parenthetical's own words are not terms" eval '! grep -qF "story waits on" <<<"$out"'
fx_check "a clean doc is not flagged" eval '! grep -qF clean.md <<<"$out"'

# the plugin's prose still uses words its glossary avoids, so the hits are not asserted; the
# glossary must parse: exit 0 or 1, never awk's 2
out=$(run_lint "$repo_root")
fx_check "the plugin's own GLOSSARY.md parses (the lint exits 0 or 1, not 2)" eval 'exit_is 0 "$out" || exit_is 1 "$out"'
fx_check "the plugin's own GLOSSARY.md raises no awk error" eval '! grep -q "^awk:" <<<"$out"'

fx_report_fails
