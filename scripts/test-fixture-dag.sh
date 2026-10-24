#!/usr/bin/env bash
# Test scripts/fixture-workspace.sh --dag against the bead state it must produce: the four-story
# expand-migrate-contract shape of ADR 0011 (lib-expand, consumer-migrate, lib-contract, consumer-bump).
# Usage: scripts/test-fixture-dag.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script=$repo_root/scripts/fixture-workspace.sh
source "$repo_root/scripts/fixture-test-lib.sh"
fx_scratch_dir test-dag || exit 1
out=$scratch/workspace

# 0. argument handling: --dag after OUT is a usage error, not a silent plain build
"$script" "$out" --dag >/dev/null 2>&1; rc=$?
fx_check "OUT --dag is rejected with exit 2" fx_eq "$rc" 2

# 1. twice: identical listings
fx_traced_build "with flag" --dag "$out"
l1=$(fx_snapshot lib); c1=$(fx_snapshot consumer); r1=$(fx_snapshot .)
fx_traced_build "rebuild with flag" --dag "$out"
l2=$(fx_snapshot lib); c2=$(fx_snapshot consumer); r2=$(fx_snapshot .)
fx_check "rerun: lib listing identical (incl. dependencies)" fx_eq "$l1" "$l2"
fx_check "rerun: consumer listing identical (incl. dependencies)" fx_eq "$c1" "$c2"
fx_check "rerun: root listing identical" fx_eq "$r1" "$r2"
fx_check "lib has exactly 7 beads (2 stories, 3 tickets, 2 publish)" fx_eq "$(jq length <<<"$l2")" 7
fx_check "consumer has exactly 5 beads (2 stories, 2 bumps, 1 switch ticket)" fx_eq "$(jq length <<<"$c2")" 5
fx_check "root has exactly 1 bead (the epic)" fx_eq "$(jq length <<<"$r2")" 1

# 2. shape
epic=$(fx_one . '.issue_type=="epic"')
expand=$(fx_one lib '.title=="Story: lib expand"')
contract=$(fx_one lib '.title=="Story: lib contract"')
migrate=$(fx_one consumer '.title=="Story: consumer migrate"')
cbump=$(fx_one consumer '.title=="Story: consumer bump"')
pub2=$(fx_one lib '.title=="publish fixture-lib 0.2.0"')
pub3=$(fx_one lib '.title=="publish fixture-lib 0.3.0"')
b2=$(fx_one consumer '.title=="Bump fixture-lib to 0.2.0"')
b3=$(fx_one consumer '.title=="Bump fixture-lib to 0.3.0"')
sw=$(fx_one consumer '.title=="Switch consumer from add to multiply"')
lt1=$(fx_one lib '.title=="Add multiply to fixture-lib"')
lt2=$(fx_one lib '.title=="Test multiply in fixture-lib"')
lt3=$(fx_one lib '.title=="Remove add from fixture-lib"')
found=$([ -n "$epic" ] && [ -n "$expand" ] && [ -n "$contract" ] && [ -n "$migrate" ] && [ -n "$cbump" ] \
  && [ -n "$pub2" ] && [ -n "$pub3" ] && [ -n "$b2" ] && [ -n "$b3" ] && [ -n "$sw" ] && [ -n "$lt1" ] && [ -n "$lt2" ] && [ -n "$lt3" ] && echo yes)
fx_check "one epic, four named stories, two publish tickets, two bumps, three lib tickets" fx_eq "$found" yes
fx_check "exactly 2 stories in lib" fx_eq "$(fx_all lib | jq '[.[] | select(.issue_type=="story")] | length')" 2
fx_check "exactly 2 stories in consumer" fx_eq "$(fx_all consumer | jq '[.[] | select(.issue_type=="story")] | length')" 2
fx_check "exactly 2 publish tickets (ready-for-human) in lib" fx_eq "$(fx_all lib | jq '[.[] | select(.labels // [] | index("ready-for-human"))] | length')" 2

# the four stories as "<repo> <id>" pairs, read by the per-story passes below (2 and 5)
stories=("lib $expand" "lib $contract" "consumer $migrate" "consumer $cbump")
for s in "${stories[@]}"; do
  set -- $s
  fx_check "$1 story $2 ref FIX-1, no parent, no complexity label" fx_eq \
    "$(fx_field "$1" "$2" '[.external_ref, (.parent // "none"), ([.labels // [] | .[] | select(startswith("complexity:"))] | length)] | join(",")')" "FIX-1,none,0"
  fx_check "$1 story $2 ## Parent names home, epic id, FIX-1" grep -Fqx "Home $(basename "$out"), epic bead $epic, FIX-1" <<<"$(fx_field "$1" "$2" .description)"
  fx_check "$1 story $2 has a ## Test seams heading" grep -qx "## Test seams" <<<"$(fx_field "$1" "$2" .description)"
done

# 3. blocker lines
blocked_by() { fx_field "$1" "$2" .description | sed -n '/^## Blocked by/,$p' | sed '1d' | grep . ; }
fx_check "lib-expand has no ## Blocked by section" fx_eq "$(fx_field lib "$expand" .description | grep -c '^## Blocked by')" 0
fx_check "consumer-migrate blocked by exactly 'lib <publish 0.2.0 id>'" fx_eq "$(blocked_by consumer "$migrate")" "lib $pub2"
fx_check "lib-contract blocked by exactly 'consumer <consumer-migrate id>'" fx_eq "$(blocked_by lib "$contract")" "consumer $migrate"
fx_check "consumer-bump blocked by exactly 'lib <publish 0.3.0 id>'" fx_eq "$(blocked_by consumer "$cbump")" "lib $pub3"

# 4. tickets, labels, parents
fx_check "publish tickets are each the only ready-for-human ticket in their story" fx_eq \
  "$(for s in "$expand" "$contract"; do fx_children lib "$s" | jq '[.[] | select(.labels // [] | index("ready-for-human"))] | length'; done | paste -sd, -)" "1,1"
fx_check "publish 0.2.0 is a child of lib-expand, 0.3.0 of lib-contract" fx_eq "$(fx_field lib "$pub2" .parent),$(fx_field lib "$pub3" .parent)" "$expand,$contract"
fx_check "publish tickets labels are exactly ready-for-human + complexity:low" fx_eq \
  "$(fx_field lib "$pub2" '.labels | sort | join(",")'),$(fx_field lib "$pub3" '.labels | sort | join(",")')" "complexity:low,ready-for-human,complexity:low,ready-for-human"
fx_check "bump 0.2.0 is a child of consumer-migrate, bump 0.3.0 of consumer-bump" fx_eq "$(fx_field consumer "$b2" .parent),$(fx_field consumer "$b3" .parent)" "$migrate,$cbump"
for t in "$b2" "$b3" "$sw"; do
  fx_check "consumer ticket $t carries complexity + ready-for-agent" fx_eq \
    "$(fx_field consumer "$t" '(.labels | index("ready-for-agent") != null) and (.labels | map(startswith("complexity:")) | any)')" true
done
fx_check "consumer-bump has exactly one child (the 0.3.0 bump)" fx_eq \
  "$(fx_children consumer "$cbump" | jq -r 'map(.id) | join(",")')" "$b3"
fx_check "consumer-migrate has exactly two children (bump 0.2.0, switch)" fx_eq \
  "$(fx_children consumer "$migrate" | jq -r 'map(.id) | sort | join(",")')" "$(printf '%s\n' "$b2" "$sw" | sort | paste -sd, -)"
fx_check "lib tickets 1,2 children of lib-expand; 3 of lib-contract" fx_eq "$(fx_field lib "$lt1" .parent),$(fx_field lib "$lt2" .parent),$(fx_field lib "$lt3" .parent)" "$expand,$expand,$contract"

# 5. native edges
fx_check "publish 0.2.0 blocked by both lib-expand implementation tickets" fx_eq "$(fx_blockers lib "$pub2")" "$(printf '%s\n' "$lt1" "$lt2" | sort | paste -sd, -)"
fx_check "publish 0.3.0 blocked by the lib-contract implementation ticket" fx_eq "$(fx_blockers lib "$pub3")" "$lt3"
fx_check "lib ticket 2 blocked by lib ticket 1" fx_eq "$(fx_blockers lib "$lt2")" "$lt1"
fx_check "switch ticket blocked by the 0.2.0 bump" fx_eq "$(fx_blockers consumer "$sw")" "$b2"
fx_check "no native edge on the first tickets and bumps" fx_eq "$(fx_blockers lib "$lt1"),$(fx_blockers lib "$lt3"),$(fx_blockers consumer "$b2"),$(fx_blockers consumer "$b3")" ",,,"
fx_check "no native edge on any story (the waits are text)" fx_eq \
  "$(for p in "${stories[@]}"; do set -- $p; fx_blockers "$1" "$2"; done | paste -sd, -)" ",,,"

fx_report_fails
