#!/usr/bin/env bash
# Tests for skills/glossary-lint/glossary-lint.sh: on a throwaway repo holding the fixture
# glossary, whose _Avoid_ notes wrap across lines (a parenthetical, and a list), every term on
# either line is flagged and a clean doc passes; terms with regex metacharacters match
# literally; the root glossary covers subdirectories; .beads/ is never scanned; every installed
# awk gives the same output; a tree with nothing to scan exits 0 without reading stdin; the
# plugin's own tree passes; and a banned synonym seeded into a copy of that tree is caught.
# Usage: scripts/test-glossary-lint.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lint=$repo_root/skills/glossary-lint/glossary-lint.sh
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_scratch_dir, fx_is_repo_top, fx_check, fx_report_fails
fx_scratch_dir test-glossary-lint || exit 1

# run_lint <dir>: the lint's output, then its exit code on a last line
run_lint() { local out rc; out=$(cd "$1" && sh "$lint" 2>&1); rc=$?; printf '%s\n%s\n' "$out" "$rc"; }
exit_is() { [ "${2##*$'\n'}" = "$1" ]; }   # <code> <run_lint output>

# throwaway_repo <dir> <what>: an empty git repo at $scratch/<dir>, or the run ends on FAIL make <what>.
# Separate git dir: the sandbox refuses writes to any .git/config; GIT_CEILING_DIRECTORIES and
# fx_is_repo_top keep a failed init from adding into the enclosing checkout
throwaway_repo() {
  mkdir -p "$scratch/$1" \
    && GIT_CEILING_DIRECTORIES=$scratch git init -q --template= --separate-git-dir="$scratch/$1.gd" "$scratch/$1" \
    && fx_is_repo_top "$scratch/$1" || { echo "FAIL make $2"; exit 1; }
}

repo=$scratch/repo
throwaway_repo repo "the throwaway repo"
cp "$repo_root/scripts/fixtures/glossary-lint/GLOSSARY.md" "$repo/"
printf 'The gate ticket waits.\nThe axb name.\n' > "$repo/clean.md"
printf 'This is a manual step.\nIt waits on a human ticket.\nIn the home base repo.\nSee a.b here.\nWritten in c++.\n' > "$repo/dirty.md"
mkdir -p "$repo/sub" "$repo/.beads" "$repo/sub/.beads"
printf 'A nested manual step.\n' > "$repo/sub/nested.md"
printf 'A manual step the tool wrote.\n' > "$repo/.beads/README.md"
printf 'A manual step the tool wrote.\n' > "$repo/sub/.beads/README.md"
git -C "$repo" add -A

out=$(run_lint "$repo")
fx_check "a glossary with wrapped _Avoid_ notes parses (exit 1 on the hits, not 2)" exit_is 1 "$out"
fx_check "a term after a wrapped parenthetical is flagged" grep -qF 'dirty.md:1: "manual step"' <<<"$out"
fx_check "a term before the wrapped parenthetical is flagged" grep -qF 'dirty.md:2: "human ticket"' <<<"$out"
fx_check "a term on a wrapped list's next line is flagged" grep -qF 'dirty.md:3: "home base"' <<<"$out"
fx_check "the parenthetical's own words are not terms" eval '! grep -qF "story waits on" <<<"$out"'
fx_check "a clean doc is not flagged (a.b does not match axb)" eval '! grep -qF clean.md <<<"$out"'
fx_check "an avoid term with a dot is flagged literally" grep -qF 'dirty.md:4: "a.b"' <<<"$out"
fx_check "an avoid term with + is flagged literally" grep -qF 'dirty.md:5: "c++"' <<<"$out"
fx_check "the root glossary covers a file in a subdirectory" grep -qF 'sub/nested.md:1: "manual step"' <<<"$out"
fx_check "files under .beads/ are not scanned" eval '! grep -qF .beads/ <<<"$out"'
fx_check "the hits are exactly the seeded ones" grep -qF 'glossary-lint: 6 violation(s)' <<<"$out"

# every awk on this machine gives the default awk's output, through a PATH shim so the lint's
# own "awk" resolves to it; root-glossary scoping and dynamic regexes differ between BSD awk,
# gawk, mawk and busybox
for awk_name in /usr/bin/awk gawk mawk original-awk nawk busybox; do
  bin=$(command -v "$awk_name") || continue
  shim=$scratch/awk-${awk_name##*/}
  mkdir -p "$shim"
  if [ "$awk_name" = busybox ]; then printf '#!/bin/sh\nexec %s awk "$@"\n' "$bin" > "$shim/awk"; chmod +x "$shim/awk"
  else ln -sf "$bin" "$shim/awk"; fi
  alt=$(PATH=$shim:$PATH run_lint "$repo")
  [ "$out" = "$alt" ] || {
    echo "glossary-lint under $awk_name differs:"; echo "$out" > "$shim.want"; echo "$alt" > "$shim.got"
    diff "$shim.want" "$shim.got"
  }
  fx_check "the lint under $awk_name gives the default awk's output" fx_eq "$out" "$alt"
done

# a repo whose only hit is under .beads/ has no file to scan, so it exits 0 at once, never
# reading stdin: stdin is a pipe held open for 4s, so a lint that reads it takes that long
empty=$scratch/empty
throwaway_repo empty "the empty repo"
cp "$repo_root/scripts/fixtures/glossary-lint/GLOSSARY.md" "$empty/"
mkdir -p "$empty/.beads" && printf 'A manual step the tool wrote.\n' > "$empty/.beads/README.md"
git -C "$empty" add -A
exec 3< <(exec sleep 4 2>/dev/null); sleeper=$!
start=$SECONDS
out=$(cd "$empty" && sh "$lint" <&3 2>&1; echo "rc=$?")
exec 3<&-; kill "$sleeper" 2>/dev/null
fx_check "a tree with its only hit under .beads/ is clean (exit 0)" grep -qx 'rc=0' <<<"$out"
fx_check "an empty file list does not read stdin (exits at once)" test $((SECONDS - start)) -lt 2

# the plugin's own tree is clean: its glossary's _Avoid_ lists hold the synonyms its prose
# must not use, and .glossary-allow the senses it permits; a dirty tree's hits are printed
# before the check, since fx_check swallows them
out=$(run_lint "$repo_root")
exit_is 0 "$out" || { echo "glossary-lint on the tree:"; head -20 <<<"$out"; }
fx_check "the plugin's own tree passes (the lint exits 0)" exit_is 0 "$out"
fx_check "the plugin's own GLOSSARY.md raises no awk error" eval '! grep -q "^awk:" <<<"$out"'

# and the clean run is the glossary catching nothing, not catching nothing at all: a doc
# seeded with a banned synonym fails, in a copy of the tracked tree so the tree itself is
# untouched
copy=$scratch/plugin
throwaway_repo plugin "the plugin copy"
git -C "$repo_root" ls-files -z | tar -C "$repo_root" --null -T - -cf - | tar -C "$copy" -xf - \
  || { echo "FAIL copy the tracked tree"; exit 1; }
printf 'The sub-orchestrator delivers the PR.\n' > "$copy/seeded.md"
git -C "$copy" add -A
out=$(run_lint "$copy")
fx_check "a banned synonym seeded into the plugin's docs fails the lint" exit_is 1 "$out"
fx_check "the seeded synonym is the hit" grep -qF 'seeded.md:1: "sub-orchestrator" is on the glossary avoid list; use story orchestrator' <<<"$out"
fx_check "the seeded synonym is the only hit" grep -qF 'glossary-lint: 1 violation(s)' <<<"$out"

fx_report_fails
