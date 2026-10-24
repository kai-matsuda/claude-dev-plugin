#!/usr/bin/env bash
# Test /triage in a repo session (chezmoi-gfu.1.5, INFRA-28) against the fixture workspace.
# The seam is a subagent run, which a script cannot spawn, so the test has phases:
#   scripts/test-fixture-triage.sh seed triage   build the fixture, seed a retro:foreign inbox bead in
#                                            consumer, print the brief: run /triage per the skill
#                                            file in consumer alone (no manifest in that session),
#                                            answer "accept", plain bd only
#   scripts/test-fixture-triage.sh assert triage check the bead state the run must leave behind
#   scripts/test-fixture-triage.sh           assert when a seeded fixture exists, else print a note
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cases="triage"
skill=$repo_root/skills/triage/SKILL.md

fixture() { echo "$repo_root/.fixtures/test-triage"; }
home_of() { echo consumer; }

seed() { # <case>
  [ "$1" = triage ] || return 1
  build_fixture
  bd -C "$out/consumer" create "Reviewer misses unused imports" --type chore \
    -l retro,needs-triage,retro:foreign --silent --body-file - >/dev/null <<'T' || { echo "FAIL seed inbox bead"; exit 1; }
## Moment
The review of the multiply ticket passed an unused import.

## Category
Coding standards

## Proposed fix
Add a check to a CI workflow outside this repo. layer: check. file: ../lib/.github/workflows/ci.yml. blocks commits: yes

## Session
consumer, 2026-10-20
T
  echo "seeded $out/consumer"
  echo "brief: the session repo is $out/consumer alone; follow $skill and the branch's tracker doc $repo_root/docs/agents/issue-tracker.md (this repo's skills/ loaded as the plugin: claude --plugin-dir $repo_root, the skill typed dev:triage); answer step 4 with accept; plain bd only, never bd -C"
  echo "if the subagent's cwd is elsewhere, point plain bd at consumer: BEADS_DIR=$out/consumer/.beads bd <args> (verified with this bd)"
}

assert() {
  inbox=$(one consumer '.title=="Reviewer misses unused imports" and (.labels|index("needs-triage"))')
  routed=$(one consumer '(.labels // [] | index("retro")) and ((.labels // [] | index("needs-triage")) | not)')
  check "one inbox bead and one routed bead in consumer" eq "$([ -n "$inbox" ] && [ -n "$routed" ] && echo yes)" yes
  check "routed bead is a new bead, not the inbox bead" test "$routed" != "$inbox"
  check "routed bead is ready-for-human" eq "$(field consumer "$routed" '.labels|index("ready-for-human") != null')" true
  check "routed bead carries retro" eq "$(field consumer "$routed" '.labels|index("retro") != null')" true
  check "routed bead has one complexity label" eq "$(field consumer "$routed" '[.labels[]|select(startswith("complexity:"))]|length')" 1
  check "routed bead has acceptance criteria" eq "$(field consumer "$routed" '((.acceptance_criteria // "")|length) > 0')" true
  check "routed bead is open" eq "$(field consumer "$routed" .status)" open
  check "inbox bead is closed" eq "$(field consumer "$inbox" .status)" closed
  check "inbox bead closed with 'routed: consumer <new id>'" eq "$(field consumer "$inbox" .close_reason)" "routed: consumer $routed"
  check "inbox bead was not relabelled in place" eq "$(field consumer "$inbox" '.labels|index("ready-for-human") == null')" true
  check "no other beads were created in consumer" eq "$(all consumer | jq length)" 2
  check "the workspace's beads are untouched" eq "$(all . | jq length)" 0
  check "lib's beads are untouched" eq "$(all lib | jq length)" 0
}

source "$repo_root/scripts/fixture-phases.sh"
run_phases "$@"
