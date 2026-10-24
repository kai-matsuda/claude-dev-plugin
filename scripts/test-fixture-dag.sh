#!/usr/bin/env bash
# Test scripts/fixture-workspace.sh --dag against the bead state it must produce: the four-story
# expand-migrate-contract shape of ADR 0011 (lib-expand, consumer-migrate, lib-contract, consumer-bump).
# Usage: scripts/test-fixture-dag.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script=$repo_root/scripts/fixture-workspace.sh
source "$repo_root/scripts/fixture-test-lib.sh"
scratch_dir test-dag || exit 1
out=$scratch/workspace

# 0. argument handling: --dag after OUT is a usage error, not a silent plain build
"$script" "$out" --dag >/dev/null 2>&1; rc=$?
check "OUT --dag is rejected with exit 2" eq "$rc" 2

# 1. twice: identical listings
traced_build "with flag" --dag "$out"
l1=$(snapshot lib); c1=$(snapshot consumer); r1=$(snapshot .)
traced_build "rebuild with flag" --dag "$out"
l2=$(snapshot lib); c2=$(snapshot consumer); r2=$(snapshot .)
check "rerun: lib listing identical (incl. dependencies)" eq "$l1" "$l2"
check "rerun: consumer listing identical (incl. dependencies)" eq "$c1" "$c2"
check "rerun: root listing identical" eq "$r1" "$r2"
check "lib has exactly 7 beads (2 stories, 3 tickets, 2 publish)" eq "$(jq length <<<"$l2")" 7
check "consumer has exactly 5 beads (2 stories, 2 bumps, 1 switch ticket)" eq "$(jq length <<<"$c2")" 5
check "root has exactly 1 bead (the epic)" eq "$(jq length <<<"$r2")" 1

# 2. shape
epic=$(one . '.issue_type=="epic"')
expand=$(one lib '.title=="Story: lib expand"')
contract=$(one lib '.title=="Story: lib contract"')
migrate=$(one consumer '.title=="Story: consumer migrate"')
cbump=$(one consumer '.title=="Story: consumer bump"')
pub2=$(one lib '.title=="publish fixture-lib 0.2.0"')
pub3=$(one lib '.title=="publish fixture-lib 0.3.0"')
b2=$(one consumer '.title=="Bump fixture-lib to 0.2.0"')
b3=$(one consumer '.title=="Bump fixture-lib to 0.3.0"')
sw=$(one consumer '.title=="Switch consumer from add to multiply"')
lt1=$(one lib '.title=="Add multiply to fixture-lib"')
lt2=$(one lib '.title=="Test multiply in fixture-lib"')
lt3=$(one lib '.title=="Remove add from fixture-lib"')
found=$([ -n "$epic" ] && [ -n "$expand" ] && [ -n "$contract" ] && [ -n "$migrate" ] && [ -n "$cbump" ] \
  && [ -n "$pub2" ] && [ -n "$pub3" ] && [ -n "$b2" ] && [ -n "$b3" ] && [ -n "$sw" ] && [ -n "$lt1" ] && [ -n "$lt2" ] && [ -n "$lt3" ] && echo yes)
check "one epic, four named stories, two publish tickets, two bumps, three lib tickets" eq "$found" yes
check "exactly 2 stories in lib" eq "$(all lib | jq '[.[] | select(.issue_type=="story")] | length')" 2
check "exactly 2 stories in consumer" eq "$(all consumer | jq '[.[] | select(.issue_type=="story")] | length')" 2
check "exactly 2 publish tickets (ready-for-human) in lib" eq "$(all lib | jq '[.[] | select(.labels // [] | index("ready-for-human"))] | length')" 2

# the four stories as "<repo> <id>" pairs, read by the per-story passes below (2 and 5)
stories=("lib $expand" "lib $contract" "consumer $migrate" "consumer $cbump")
for s in "${stories[@]}"; do
  set -- $s
  check "$1 story $2 ref FIX-1, no parent, no complexity label" eq \
    "$(field "$1" "$2" '[.external_ref, (.parent // "none"), ([.labels // [] | .[] | select(startswith("complexity:"))] | length)] | join(",")')" "FIX-1,none,0"
  check "$1 story $2 ## Parent names home, epic id, FIX-1" grep -Fqx "Home $(basename "$out"), epic bead $epic, FIX-1" <<<"$(field "$1" "$2" .description)"
  check "$1 story $2 has a ## Test seams heading" grep -qx "## Test seams" <<<"$(field "$1" "$2" .description)"
done

# 3. blocker lines
blocked_by() { field "$1" "$2" .description | sed -n '/^## Blocked by/,$p' | sed '1d' | grep . ; }
check "lib-expand has no ## Blocked by section" eq "$(field lib "$expand" .description | grep -c '^## Blocked by')" 0
check "consumer-migrate blocked by exactly 'lib <publish 0.2.0 id>'" eq "$(blocked_by consumer "$migrate")" "lib $pub2"
check "lib-contract blocked by exactly 'consumer <consumer-migrate id>'" eq "$(blocked_by lib "$contract")" "consumer $migrate"
check "consumer-bump blocked by exactly 'lib <publish 0.3.0 id>'" eq "$(blocked_by consumer "$cbump")" "lib $pub3"

# 4. tickets, labels, parents
check "publish tickets are each the only ready-for-human ticket in their story" eq \
  "$(for s in "$expand" "$contract"; do bdj lib list --all --parent "$s" --json | jq '[.[] | select(.labels // [] | index("ready-for-human"))] | length'; done | paste -sd, -)" "1,1"
check "publish 0.2.0 is a child of lib-expand, 0.3.0 of lib-contract" eq "$(field lib "$pub2" .parent),$(field lib "$pub3" .parent)" "$expand,$contract"
check "publish tickets labels are exactly ready-for-human + complexity:low" eq \
  "$(field lib "$pub2" '.labels | sort | join(",")'),$(field lib "$pub3" '.labels | sort | join(",")')" "complexity:low,ready-for-human,complexity:low,ready-for-human"
check "bump 0.2.0 is a child of consumer-migrate, bump 0.3.0 of consumer-bump" eq "$(field consumer "$b2" .parent),$(field consumer "$b3" .parent)" "$migrate,$cbump"
for t in "$b2" "$b3" "$sw"; do
  check "consumer ticket $t carries complexity + ready-for-agent" eq \
    "$(field consumer "$t" '(.labels | index("ready-for-agent") != null) and (.labels | map(startswith("complexity:")) | any)')" true
done
check "consumer-bump has exactly one child (the 0.3.0 bump)" eq \
  "$(bdj consumer list --all --parent "$cbump" --json | jq -r 'map(.id) | join(",")')" "$b3"
check "consumer-migrate has exactly two children (bump 0.2.0, switch)" eq \
  "$(bdj consumer list --all --parent "$migrate" --json | jq -r 'map(.id) | sort | join(",")')" "$(printf '%s\n' "$b2" "$sw" | sort | paste -sd, -)"
check "lib tickets 1,2 children of lib-expand; 3 of lib-contract" eq "$(field lib "$lt1" .parent),$(field lib "$lt2" .parent),$(field lib "$lt3" .parent)" "$expand,$expand,$contract"

# 5. native edges
blockers() { field "$1" "$2" '[.dependencies // [] | .[] | select(.dependency_type=="blocks") | .id] | sort | join(",")'; }
check "publish 0.2.0 blocked by both lib-expand implementation tickets" eq "$(blockers lib "$pub2")" "$(printf '%s\n' "$lt1" "$lt2" | sort | paste -sd, -)"
check "publish 0.3.0 blocked by the lib-contract implementation ticket" eq "$(blockers lib "$pub3")" "$lt3"
check "lib ticket 2 blocked by lib ticket 1" eq "$(blockers lib "$lt2")" "$lt1"
check "switch ticket blocked by the 0.2.0 bump" eq "$(blockers consumer "$sw")" "$b2"
check "no native edge on the first tickets and bumps" eq "$(blockers lib "$lt1"),$(blockers lib "$lt3"),$(blockers consumer "$b2"),$(blockers consumer "$b3")" ",,,"
check "no native edge on any story (the waits are text)" eq \
  "$(for p in "${stories[@]}"; do set -- $p; blockers "$1" "$2"; done | paste -sd, -)" ",,,"

report_fails
