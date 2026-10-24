#!/usr/bin/env bash
# Test scripts/fixture-workspace.sh --stories against the bead state it must produce.
# Usage: scripts/test-fixture-stories.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script=$repo_root/scripts/fixture-workspace.sh
source "$repo_root/scripts/fixture-test-lib.sh"
fx_scratch_dir test-stories || exit 1
out=$scratch/workspace

# 0. argument handling: --stories after OUT is a usage error, not a silent plain build
"$script" "$out" --stories >/dev/null 2>&1; rc=$?
fx_check "OUT --stories is rejected with exit 2" fx_eq "$rc" 2


# 1. without the flag: unchanged (no beads at all)
fx_traced_build "without flag" "$out"
fx_check "no flag: lib has no beads" fx_eq "$(fx_all lib | jq length)" 0
fx_check "no flag: consumer has no beads" fx_eq "$(fx_all consumer | jq length)" 0
fx_check "no flag: root has no beads" fx_eq "$(fx_all . | jq length)" 0

# 2. with the flag, twice: identical listings
fx_traced_build "with flag" --stories "$out"
l1=$(fx_snapshot lib); c1=$(fx_snapshot consumer); r1=$(fx_snapshot .)
fx_traced_build "rebuild with flag" --stories "$out"
l2=$(fx_snapshot lib); c2=$(fx_snapshot consumer); r2=$(fx_snapshot .)
fx_check "rerun: lib listing identical (incl. dependencies)" fx_eq "$l1" "$l2"
fx_check "rerun: consumer listing identical (incl. dependencies)" fx_eq "$c1" "$c2"
fx_check "rerun: root listing identical (id prefix normalised)" fx_eq "$r1" "$r2"
fx_check "lib has exactly 4 beads" fx_eq "$(jq length <<<"$l2")" 4
fx_check "consumer has exactly 3 beads (story, 2 tickets)" fx_eq "$(jq length <<<"$c2")" 3
fx_check "root has exactly 1 bead (the epic)" fx_eq "$(jq length <<<"$r2")" 1

# 3. shape
epic=$(fx_one . '.issue_type=="epic"')
fx_check "no epic in consumer" fx_eq "$(fx_all consumer | jq '[.[] | select(.issue_type=="epic")] | length')" 0
cstory=$(fx_one consumer '.issue_type=="story"')
lstory=$(fx_one lib '.issue_type=="story"')
pub=$(fx_one lib '.labels // [] | index("ready-for-human")')
lt1=$(fx_one lib '.title=="Add multiply to fixture-lib"')
lt2=$(fx_one lib '.title=="Test multiply in fixture-lib"')
bump=$(fx_one consumer '.title=="Bump fixture-lib to 0.2.0"')
print=$(fx_one consumer '.title=="Print multiply result"')
found=$([ -n "$epic" ] && [ -n "$cstory" ] && [ -n "$lstory" ] && [ -n "$pub" ] && [ -n "$lt1" ] && [ -n "$lt2" ] && [ -n "$bump" ] && [ -n "$print" ] && echo yes)
fx_check "exactly one epic, story per repo, publish ticket, and named tickets" fx_eq "$found" yes

fx_check "epic has external ref FIX-1" fx_eq "$(fx_field . "$epic" .external_ref)" FIX-1
fx_check "epic is labelled ready-for-agent" fx_eq "$(fx_field . "$epic" '.labels | index("ready-for-agent") != null')" true
fx_check "consumer story ref FIX-1" fx_eq "$(fx_field consumer "$cstory" .external_ref)" FIX-1
fx_check "lib story ref FIX-1" fx_eq "$(fx_field lib "$lstory" .external_ref)" FIX-1
fx_check "consumer story has no parent" fx_eq "$(fx_field consumer "$cstory" '.parent // "none"')" none
fx_check "lib story has no parent" fx_eq "$(fx_field lib "$lstory" '.parent // "none"')" none
for pair in "consumer $cstory" "lib $lstory"; do
  set -- $pair
  fx_check "$1 story carries no complexity label" fx_eq "$(fx_field "$1" "$2" '[.labels // [] | .[] | select(startswith("complexity:"))] | length')" 0
  pbody=$(fx_field "$1" "$2" .description | sed -n '/^## Parent/,/^## Blocked by/p')
  fx_check "$1 story ## Parent names home repo, epic id, FIX-1" grep -Fqx "Home $(basename "$out"), epic bead $epic, FIX-1" <<<"$pbody"
  fx_check "$1 story body has a ## Test seams heading" grep -qx "## Test seams" <<<"$(fx_field "$1" "$2" .description)"
done
fx_check "consumer story has no labels" fx_eq "$(fx_field consumer "$cstory" '.labels // [] | length')" 0
fx_check "exactly 2 consumer tickets with complexity + ready-for-agent" fx_eq "$(fx_children consumer "$cstory" | jq '[.[] | select(.status != "closed") | select((.labels|index("ready-for-agent")) and (.labels|map(startswith("complexity:"))|any))]|length')" 2
fx_check "publish ticket is a child of lib story" fx_eq "$(fx_field lib "$pub" .parent)" "$lstory"
fx_check "publish ticket titled 'publish fixture-lib 0.2.0'" fx_eq "$(fx_field lib "$pub" .title)" "publish fixture-lib 0.2.0"
fx_check "publish ticket labels are exactly ready-for-human + complexity:low" fx_eq "$(fx_field lib "$pub" '.labels | sort | join(",")')" "complexity:low,ready-for-human"
body=$(fx_field consumer "$cstory" .description)
fx_check "consumer story body: Blocked by line 'lib <publish id>'" grep -qx "lib $pub" <<<"$body"
fx_check "consumer story body: ## Blocked by" grep -q '^## Blocked by' <<<"$body"

# 4. native edges
fx_check "publish ticket blocked by both lib tickets" fx_eq "$(fx_blockers lib "$pub")" "$(printf '%s\n' "$lt1" "$lt2" | sort | paste -sd, -)"
fx_check "lib ticket 2 blocked by lib ticket 1 (gap 1)" fx_eq "$(fx_blockers lib "$lt2")" "$lt1"
fx_check "lib ticket 1 has no blockers" fx_eq "$(fx_blockers lib "$lt1")" ""
fx_check "print ticket blocked by the bump" fx_eq "$(fx_blockers consumer "$print")" "$bump"
fx_check "bump ticket has no blockers" fx_eq "$(fx_blockers consumer "$bump")" ""

# 5. frontier
fx_check "consumer ready --parent lists exactly the bump" fx_eq "$(fx_bdj consumer ready --parent "$cstory" --json | jq -r 'map(.id)|join(",")')" "$bump"
fx_check "lib ready --parent lists exactly one lib ticket (the unblocked one)" fx_eq "$(fx_bdj lib ready --parent "$lstory" --json | jq -r 'map(.id)|join(",")')" "$lt1"
# a dead runner's claim hides its ticket from bd ready; the orchestrator's unclaim brings it back (chezmoi-jvc)
fx_bdj lib update "$lt1" --claim >/dev/null
fx_check "a claimed lib ticket leaves ready --parent" fx_eq "$(fx_bdj lib ready --parent "$lstory" --json | jq length)" 0
# a needs-triage child filed under the story (a review deferral, INFRA-27) is listed by bd ready like
# any other open child; the Frontier rule admits ready-for-agent tickets only, so with lt1 still
# claimed the rule's filter yields nothing to run (chezmoi-wgi)
frontier() { # <repo> <story-id>   the Frontier rule's read: bd ready --parent, ready-for-agent tickets only
  fx_bdj "$1" ready --parent "$2" --json | jq -r '[.[] | select(.labels // [] | index("ready-for-agent"))] | map(.id) | join(",")'
}
triage_child=$(fx_bdj lib create --silent --parent "$lstory" --no-inherit-labels --labels needs-triage "Deferred: review note with nothing to implement")
fx_check "bd ready --parent lists the needs-triage child" fx_eq "$(fx_bdj lib ready --parent "$lstory" --json | jq -r 'map(.id)|join(",")')" "$triage_child"
fx_check "the frontier (ready-for-agent only) yields nothing to run" fx_eq "$(frontier lib "$lstory")" ""
fx_bdj lib unclaim "$lt1" >/dev/null
fx_check "unclaim returns it to ready --parent, open and unassigned" fx_eq "$(fx_bdj lib ready --parent "$lstory" --json | jq -r 'map(select(.id == "'"$lt1"'") | .id + " " + .status + " " + (.assignee // "-"))|join(",")')" "$lt1 open -"
fx_check "the frontier is then exactly the unclaimed ticket, the needs-triage child still off it" fx_eq "$(frontier lib "$lstory")" "$lt1"
fx_bdj lib close "$triage_child" --reason "test teardown" >/dev/null

# 6. gap 2: a plain git worktree of the consumer checkout builds (path dep resolves from both)
worktree_builds() {
  local wt=.worktrees/x rc
  git -C "$out/consumer" worktree add -q "$wt" || return 1
  cargo build -q --manifest-path "$out/consumer/$wt/Cargo.toml"; rc=$?
  git -C "$out/consumer" worktree remove --force "$wt"
  return $rc
}
fx_check "consumer builds from a plain git worktree under .worktrees/x" worktree_builds

fx_report_fails
