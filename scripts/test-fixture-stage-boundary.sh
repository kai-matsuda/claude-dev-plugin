#!/usr/bin/env bash
# Test scripts/fixture-workspace.sh --stage-boundary against the bead state it must produce.
# Usage: scripts/test-fixture-stage-boundary.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script=$repo_root/scripts/fixture-workspace.sh
source "$repo_root/scripts/fixture-test-lib.sh"
scratch_dir test-stage-boundary || exit 1
out=$scratch/workspace

# 1. build twice: identical listings
traced_build "with flag" --stage-boundary "$out"
l1=$(snapshot lib); c1=$(snapshot consumer); r1=$(snapshot .)
traced_build "rebuild with flag" --stage-boundary "$out"
l2=$(snapshot lib); c2=$(snapshot consumer); r2=$(snapshot .)
check "rerun: lib listing identical" eq "$l1" "$l2"
check "rerun: consumer listing identical" eq "$c1" "$c2"
check "rerun: root listing identical (id prefix normalised)" eq "$r1" "$r2"
check "lib has exactly 1 bead (its story)" eq "$(jq length <<<"$l2")" 1
check "consumer has exactly 1 bead (its story)" eq "$(jq length <<<"$c2")" 1
check "root has exactly 1 bead (the epic)" eq "$(jq length <<<"$r2")" 1
# the sandbox denies writes to config and hooks/ inside any .git directory (chezmoi-chk)
check "no .git directory in the fixture: git dirs live under OUT/.git-dirs" eq "$(find "$out" -type d -name .git | wc -l | tr -d ' ')" 0
check "the root is still a git repo (its .git file resolves)" eq "$(git -C "$out" rev-parse --is-inside-work-tree 2>/dev/null)" true
# bd init looks upward for a .git directory and would adopt the enclosing origin as the Dolt remote
check "lib has no Dolt remote configured" eq "$(grep -cE '^ *(sync\.)?remote:' "$out/lib/.beads/config.yaml")" 0
# read the YAML: bd config get reports the env-effective value, and BD_EXPORT_AUTO=true is in the shell env
check "lib has auto-export off (its repair line would name the enclosing origin)" eq "$(grep -A1 '^export:' "$out/lib/.beads/config.yaml" | grep -c 'auto: false')" 1

# 2. shape: one epic, one story per repo, no tickets
epic=$(one . '.issue_type=="epic"')
cstory=$(one consumer '.issue_type=="story"')
lstory=$(one lib '.issue_type=="story"')
check "exactly one epic and one story per repo" eq "$([ -n "$epic" ] && [ -n "$cstory" ] && [ -n "$lstory" ] && echo yes)" yes
check "no tickets in lib" eq "$(all lib | jq '[.[] | select(.issue_type != "story")] | length')" 0
check "no tickets in consumer" eq "$(all consumer | jq '[.[] | select(.issue_type != "story")] | length')" 0
check "no epic in consumer" eq "$(all consumer | jq '[.[] | select(.issue_type=="epic")] | length')" 0
check "epic has external ref FIX-1" eq "$(field . "$epic" .external_ref)" FIX-1
check "epic is labelled ready-for-agent" eq "$(field . "$epic" '.labels | index("ready-for-agent") != null')" true
check "consumer story ref FIX-1" eq "$(field consumer "$cstory" .external_ref)" FIX-1
check "lib story ref FIX-1" eq "$(field lib "$lstory" .external_ref)" FIX-1
check "consumer story has no parent" eq "$(field consumer "$cstory" '.parent // "none"')" none
check "lib story has no parent" eq "$(field lib "$lstory" '.parent // "none"')" none
check "consumer story has no labels" eq "$(field consumer "$cstory" '.labels // [] | length')" 0
for pair in "consumer $cstory" "lib $lstory"; do
  set -- $pair
  check "$1 story ## Parent line names the root and epic" grep -Fqx "Home $(basename "$out"), epic bead $epic, FIX-1" <<<"$(field "$1" "$2" .description | sed -n '/^## Parent/,/^## Blocked by/p')"
done

# 3. blocker line as /spec-to-stories writes it
body=$(field consumer "$cstory" .description)
check "consumer story ends with ## Blocked by and the not-yet-created line" eq \
  "$(tail -n 3 <<<"$body" | sed '/^$/d')" "$(printf '## Blocked by\nlib publish fixture-lib 0.2.0 (not created yet)')"

# 4. Spec: line in its canonical form (tracker doc, "gather the epic bead"): a path relative
# to the epic bead's repo, the root here, so a reader opens <home>/<path>
specpath=$(field . "$epic" .description | sed -n 's/^Spec: //p')
check "epic description has one Spec: line" eq "$(grep -c . <<<"$specpath")" 1
check "the Spec: path is relative, not absolute" eq "${specpath#/}" "$specpath"
check "the spec file exists at <home>/<path>" test -s "$out/$specpath"

report_fails
