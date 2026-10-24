#!/usr/bin/env bash
# Test /triage in a repo session (chezmoi-gfu.1.5, INFRA-28) against the fixture workspace.
# The seam is a subagent run, which a script cannot spawn, so the test has phases:
#   scripts/test-fixture-triage.sh seed      build the fixture, seed a retro:foreign inbox bead in
#                                            consumer, print the brief: run /triage per the skill
#                                            file in consumer alone (no manifest in that session),
#                                            answer "accept", plain bd only
#   scripts/test-fixture-triage.sh assert    check the bead state the run must leave behind
#   scripts/test-fixture-triage.sh skill     static check of the skill text for what the bead state
#                                            cannot show (no bd -C in a repo session, "the inbox";
#                                            retired phrases are scripts/lint-skill-docs.sh's)
#   scripts/test-fixture-triage.sh           skill, then assert when a seeded fixture exists
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
out=$repo_root/.fixtures/test-triage
skill=$repo_root/skills/triage/SKILL.md
phase=${1:-all}
source "$repo_root/scripts/fixture-test-lib.sh"

seed() {
  "$repo_root/scripts/fixture-workspace.sh" "$out" >/dev/null || { echo "FAIL build fixture"; exit 1; }
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

skill_text() {
  local f=$skill
  check "description says 'the inbox'" grep -qE '^description: .*the inbox' "$f"
  check "step 1 stops when <home>/.beads is missing" grep -qF '<home>/.beads' "$f"
  check "step 1 reads the inbox with plain bd list" grep -qE '`bd list -l needs-triage' "$f"
  check "step 1 has no manifest in a repo session" grep -qiE 'no manifest in a repo session' "$f"
  check "step 2 runs bd find-duplicates plainly" grep -qF '`bd find-duplicates`' "$f"
  check "step 2 keeps only pairs where both beads carry needs-triage" bash -c 'tr "\n" " " < "$1" | tr -s " " | grep -qF "both beads carry \`needs-triage\`"' _ "$f"
  check "step 2 runs bd duplicate plainly" grep -qF '`bd duplicate ' "$f"
  check "owner search is plain bd search in a repo session" grep -qF '`bd search ' "$f"
  check "owner search is bd -C <target repo> search in a workspace session" grep -qF 'bd -C <target repo> search' "$f"
  check "an open inbox bead never counts as already tracked" grep -qiE 'inbox bead.*never counts|never counts.*inbox bead' "$f"
  check "retro:foreign means a person carries it" grep -qF 'retro:foreign' "$f"
  check "step 5 routes retro:foreign as ready-for-human" grep -qE 'retro:foreign.*ready-for-human|ready-for-human.*retro:foreign' "$f"
  check "never a relabel in place" grep -qiF 'relabel in place' "$f"
  check "step 6 runs in a workspace session only" grep -qiE 'workspace session only|only in a workspace session' "$f"
  check "no 'bd -C <workspace>' remains" bash -c '! grep -qF "bd -C <workspace>" "$1"' _ "$f"
}

case "$phase" in
  seed) seed; exit 0 ;;
  assert) assert ;;
  skill) skill_text ;;
  all) skill_text; if [ -d "$out/consumer/.beads" ]; then assert; fi ;;
  *) echo "usage: $0 [seed|assert|skill]" >&2; exit 2 ;;
esac
report_fails
