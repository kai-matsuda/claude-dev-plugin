#!/usr/bin/env bash
# Test scripts/fixture-workspace.sh --stage-boundary against the bead state it must produce.
# Usage: scripts/test-fixture-stage-boundary.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script=$repo_root/scripts/fixture-workspace.sh
source "$repo_root/scripts/fixture-test-lib.sh"
fx_scratch_dir test-stage-boundary || exit 1
out=$scratch/workspace

# 1. build twice: identical listings
fx_traced_build "with flag" --stage-boundary "$out"
l1=$(fx_snapshot lib); c1=$(fx_snapshot consumer); r1=$(fx_snapshot .)
fx_traced_build "rebuild with flag" --stage-boundary "$out"
l2=$(fx_snapshot lib); c2=$(fx_snapshot consumer); r2=$(fx_snapshot .)
fx_check "rerun: lib listing identical" fx_eq "$l1" "$l2"
fx_check "rerun: consumer listing identical" fx_eq "$c1" "$c2"
fx_check "rerun: root listing identical (id prefix normalised)" fx_eq "$r1" "$r2"
fx_check "lib has exactly 1 bead (its story)" fx_eq "$(jq length <<<"$l2")" 1
fx_check "consumer has exactly 1 bead (its story)" fx_eq "$(jq length <<<"$c2")" 1
fx_check "root has exactly 1 bead (the epic)" fx_eq "$(jq length <<<"$r2")" 1
# the sandbox denies writes to config and hooks/ inside any .git directory (chezmoi-chk)
fx_check "no .git directory in the fixture: git dirs live under OUT/.git-dirs" fx_eq "$(find "$out" -type d -name .git | wc -l | tr -d ' ')" 0
fx_check "the root is still a git repo (its .git file resolves)" fx_eq "$(git -C "$out" rev-parse --is-inside-work-tree 2>/dev/null)" true
# bd init looks upward for a .git directory and would adopt the enclosing origin as the Dolt remote
fx_check "lib has no Dolt remote configured" fx_eq "$(grep -cE '^ *(sync\.)?remote:' "$out/lib/.beads/config.yaml")" 0
# read the YAML: bd config get reports the env-effective value, and BD_EXPORT_AUTO=true is in the shell env
fx_check "lib has auto-export off (its repair line would name the enclosing origin)" fx_eq "$(grep -A1 '^export:' "$out/lib/.beads/config.yaml" | grep -c 'auto: false')" 1

# 2. shape: one epic, one story per repo, no tickets
epic=$(fx_one . '.issue_type=="epic"')
cstory=$(fx_one consumer '.issue_type=="story"')
lstory=$(fx_one lib '.issue_type=="story"')
fx_check "exactly one epic and one story per repo" fx_eq "$([ -n "$epic" ] && [ -n "$cstory" ] && [ -n "$lstory" ] && echo yes)" yes
fx_check "no tickets in lib" fx_eq "$(fx_all lib | jq '[.[] | select(.issue_type != "story")] | length')" 0
fx_check "no tickets in consumer" fx_eq "$(fx_all consumer | jq '[.[] | select(.issue_type != "story")] | length')" 0
fx_check "no epic in consumer" fx_eq "$(fx_all consumer | jq '[.[] | select(.issue_type=="epic")] | length')" 0
fx_check "epic has external ref FIX-1" fx_eq "$(fx_field . "$epic" .external_ref)" FIX-1
fx_check "epic is labelled ready-for-agent" fx_eq "$(fx_field . "$epic" '.labels | index("ready-for-agent") != null')" true
fx_check "consumer story ref FIX-1" fx_eq "$(fx_field consumer "$cstory" .external_ref)" FIX-1
fx_check "lib story ref FIX-1" fx_eq "$(fx_field lib "$lstory" .external_ref)" FIX-1
fx_check "consumer story has no parent" fx_eq "$(fx_field consumer "$cstory" '.parent // "none"')" none
fx_check "lib story has no parent" fx_eq "$(fx_field lib "$lstory" '.parent // "none"')" none
fx_check "consumer story has no labels" fx_eq "$(fx_field consumer "$cstory" '.labels // [] | length')" 0
for pair in "consumer $cstory" "lib $lstory"; do
  set -- $pair
  fx_check "$1 story ## Parent line names the root and epic" grep -Fqx "Home $(basename "$out"), epic bead $epic, FIX-1" <<<"$(fx_field "$1" "$2" .description | sed -n '/^## Parent/,/^## Blocked by/p')"
done

# 3. blocker line as /spec-to-stories writes it
body=$(fx_field consumer "$cstory" .description)
fx_check "consumer story ends with ## Blocked by and the not-yet-created line" fx_eq \
  "$(tail -n 3 <<<"$body" | sed '/^$/d')" "$(printf '## Blocked by\nlib publish fixture-lib 0.2.0 (not created yet)')"

# 4. Spec: line in its canonical form (tracker doc, "gather the epic bead"): a path relative
# to the epic bead's repo, the root here, so a reader opens <home>/<path>
specpath=$(fx_field . "$epic" .description | sed -n 's/^Spec: //p')
fx_check "epic description has one Spec: line" fx_eq "$(grep -c . <<<"$specpath")" 1
fx_check "the Spec: path is relative, not absolute" fx_eq "${specpath#/}" "$specpath"
fx_check "the spec file exists at <home>/<path>" test -s "$out/$specpath"

fx_report_fails
