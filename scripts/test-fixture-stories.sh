#!/usr/bin/env bash
# Test scripts/fixture-workspace.sh --stories against the bead state it must produce.
# Usage: scripts/test-fixture-stories.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script=$repo_root/scripts/fixture-workspace.sh
source "$repo_root/scripts/fixture-test-lib.sh"
scratch_dir test-stories || exit 1
out=$scratch/workspace

# 0. argument handling: --stories after OUT is a usage error, not a silent plain build
"$script" "$out" --stories >/dev/null 2>&1; rc=$?
check "OUT --stories is rejected with exit 2" eq "$rc" 2


# 1. without the flag: unchanged (no beads at all)
traced_build "without flag" "$out"
check "no flag: lib has no beads" eq "$(all lib | jq length)" 0
check "no flag: consumer has no beads" eq "$(all consumer | jq length)" 0
check "no flag: root has no beads" eq "$(all . | jq length)" 0

# 2. with the flag, twice: identical listings
traced_build "with flag" --stories "$out"
l1=$(snapshot lib); c1=$(snapshot consumer); r1=$(snapshot .)
traced_build "rebuild with flag" --stories "$out"
l2=$(snapshot lib); c2=$(snapshot consumer); r2=$(snapshot .)
check "rerun: lib listing identical (incl. dependencies)" eq "$l1" "$l2"
check "rerun: consumer listing identical (incl. dependencies)" eq "$c1" "$c2"
check "rerun: root listing identical (id prefix normalised)" eq "$r1" "$r2"
check "lib has exactly 4 beads" eq "$(jq length <<<"$l2")" 4
check "consumer has exactly 3 beads (story, 2 tickets)" eq "$(jq length <<<"$c2")" 3
check "root has exactly 1 bead (the epic)" eq "$(jq length <<<"$r2")" 1

# 3. shape
epic=$(one . '.issue_type=="epic"')
check "no epic in consumer" eq "$(all consumer | jq '[.[] | select(.issue_type=="epic")] | length')" 0
cstory=$(one consumer '.issue_type=="story"')
lstory=$(one lib '.issue_type=="story"')
pub=$(one lib '.labels // [] | index("ready-for-human")')
lt1=$(one lib '.title=="Add multiply to fixture-lib"')
lt2=$(one lib '.title=="Test multiply in fixture-lib"')
bump=$(one consumer '.title=="Bump fixture-lib to 0.2.0"')
print=$(one consumer '.title=="Print multiply result"')
found=$([ -n "$epic" ] && [ -n "$cstory" ] && [ -n "$lstory" ] && [ -n "$pub" ] && [ -n "$lt1" ] && [ -n "$lt2" ] && [ -n "$bump" ] && [ -n "$print" ] && echo yes)
check "exactly one epic, story per repo, publish ticket, and named tickets" eq "$found" yes

check "epic has external ref FIX-1" eq "$(field . "$epic" .external_ref)" FIX-1
check "epic is labelled ready-for-agent" eq "$(field . "$epic" '.labels | index("ready-for-agent") != null')" true
check "consumer story ref FIX-1" eq "$(field consumer "$cstory" .external_ref)" FIX-1
check "lib story ref FIX-1" eq "$(field lib "$lstory" .external_ref)" FIX-1
check "consumer story has no parent" eq "$(field consumer "$cstory" '.parent // "none"')" none
check "lib story has no parent" eq "$(field lib "$lstory" '.parent // "none"')" none
for pair in "consumer $cstory" "lib $lstory"; do
  set -- $pair
  check "$1 story carries no complexity label" eq "$(field "$1" "$2" '[.labels // [] | .[] | select(startswith("complexity:"))] | length')" 0
  pbody=$(field "$1" "$2" .description | sed -n '/^## Parent/,/^## Blocked by/p')
  check "$1 story ## Parent names home repo, epic id, FIX-1" grep -Fqx "Home $(basename "$out"), epic bead $epic, FIX-1" <<<"$pbody"
  check "$1 story body has a ## Test seams heading" grep -qx "## Test seams" <<<"$(field "$1" "$2" .description)"
done
check "consumer story has no labels" eq "$(field consumer "$cstory" '.labels // [] | length')" 0
check "exactly 2 consumer tickets with complexity + ready-for-agent" eq "$(bdj consumer list --parent "$cstory" --json | jq '[.[] | select((.labels|index("ready-for-agent")) and (.labels|map(startswith("complexity:"))|any))]|length')" 2
check "publish ticket is a child of lib story" eq "$(field lib "$pub" .parent)" "$lstory"
check "publish ticket titled 'publish fixture-lib 0.2.0'" eq "$(field lib "$pub" .title)" "publish fixture-lib 0.2.0"
check "publish ticket labels are exactly ready-for-human + complexity:low" eq "$(field lib "$pub" '.labels | sort | join(",")')" "complexity:low,ready-for-human"
body=$(field consumer "$cstory" .description)
check "consumer story body: Blocked by line 'lib <publish id>'" grep -qx "lib $pub" <<<"$body"
check "consumer story body: ## Blocked by" grep -q '^## Blocked by' <<<"$body"

# 4. native edges
check "publish ticket blocked by both lib tickets" eq "$(blockers lib "$pub")" "$(printf '%s\n' "$lt1" "$lt2" | sort | paste -sd, -)"
check "lib ticket 2 blocked by lib ticket 1 (gap 1)" eq "$(blockers lib "$lt2")" "$lt1"
check "lib ticket 1 has no blockers" eq "$(blockers lib "$lt1")" ""
check "print ticket blocked by the bump" eq "$(blockers consumer "$print")" "$bump"
check "bump ticket has no blockers" eq "$(blockers consumer "$bump")" ""

# 5. frontier
check "consumer ready --parent lists exactly the bump" eq "$(bdj consumer ready --parent "$cstory" --json | jq -r 'map(.id)|join(",")')" "$bump"
check "lib ready --parent lists exactly one lib ticket (the unblocked one)" eq "$(bdj lib ready --parent "$lstory" --json | jq -r 'map(.id)|join(",")')" "$lt1"
# a dead runner's claim hides its ticket from bd ready; the orchestrator's unclaim brings it back (chezmoi-jvc)
bdj lib update "$lt1" --claim >/dev/null
check "a claimed lib ticket leaves ready --parent" eq "$(bdj lib ready --parent "$lstory" --json | jq length)" 0
# a needs-triage child filed under the story (a review deferral, INFRA-27) is listed by bd ready like
# any other open child; the Frontier rule admits ready-for-agent tickets only, so with lt1 still
# claimed the rule's filter yields nothing to run (chezmoi-wgi)
frontier() { # <repo> <story-id>   the Frontier rule's read: bd ready --parent, ready-for-agent tickets only
  bdj "$1" ready --parent "$2" --json | jq -r '[.[] | select(.labels // [] | index("ready-for-agent"))] | map(.id) | join(",")'
}
triage_child=$(bdj lib create --silent --parent "$lstory" --no-inherit-labels --labels needs-triage "Deferred: review note with nothing to implement")
check "bd ready --parent lists the needs-triage child" eq "$(bdj lib ready --parent "$lstory" --json | jq -r 'map(.id)|join(",")')" "$triage_child"
check "the frontier (ready-for-agent only) yields nothing to run" eq "$(frontier lib "$lstory")" ""
bdj lib unclaim "$lt1" >/dev/null
check "unclaim returns it to ready --parent, open and unassigned" eq "$(bdj lib ready --parent "$lstory" --json | jq -r 'map(select(.id == "'"$lt1"'") | .id + " " + .status + " " + (.assignee // "-"))|join(",")')" "$lt1 open -"
check "the frontier is then exactly the unclaimed ticket, the needs-triage child still off it" eq "$(frontier lib "$lstory")" "$lt1"
bdj lib close "$triage_child" --reason "test teardown" >/dev/null

# 6. gap 2: a plain git worktree of the consumer checkout builds (path dep resolves from both)
worktree_builds() {
  local wt=.worktrees/x rc
  git -C "$out/consumer" worktree add -q "$wt" || return 1
  cargo build -q --manifest-path "$out/consumer/$wt/Cargo.toml"; rc=$?
  git -C "$out/consumer" worktree remove --force "$wt"
  return $rc
}
check "consumer builds from a plain git worktree under .worktrees/x" worktree_builds

report_fails
