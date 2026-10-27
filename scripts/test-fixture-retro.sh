#!/usr/bin/env bash
# Test /retro's filing step (step 5) in both session modes (chezmoi-gfu.1, INFRA-28) against the
# fixture workspace. The seam is a subagent run, which a script cannot spawn, so the test has
# phases, one fixture per case under .fixtures/test-retro-<case>:
#   scripts/test-fixture-retro.sh seed <case>     build the fixture, print the brief: the survivors
#                                                 of steps 1-4 are given, the run does step 5
#   scripts/test-fixture-retro.sh assert <case>   check the bead state and the saved end block
#   scripts/test-fixture-retro.sh                 assert every case whose fixture is seeded and run
# Cases:
#   root      typed at the fixture root (a workspace session): a fix in lib files in the root's
#             inbox as target:lib
#   consumer  typed in consumer alone (a repo session): a fix inside consumer files as
#             target:consumer, a fix under lib as retro:foreign with the lib path in the body
#   bare      typed in a git repo with no .beads/ inside the fixture: the run stops, files
#             nothing, and plain bd never climbs to the root's database
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
skill=$repo_root/skills/retro/SKILL.md
tracker=$repo_root/docs/agents/issue-tracker.md
cases="root consumer bare"

fixture() { echo "$repo_root/.fixtures/test-retro-$1"; }
home_of() { case "$1" in root) echo . ;; *) echo "$1" ;; esac; }
lib_fix="Reviewer misses unused imports. layer: check. file: \$FIX/lib/src/lib.rs (add #![deny(unused_imports)]). blocks commits: yes"
con_fix="Main prints without a label. layer: code. file: \$FIX/consumer/src/main.rs. blocks commits: no"

seed() { # <case>
  local home home_dir survivors
  fx_build_fixture
  home=$(home_of "$1"); home_dir=$(home_path "$1")
  if [ "$1" = bare ]; then
    fx_git_repo "$out/bare" "$out/.git-dirs/bare" || { echo "FAIL init bare"; exit 1; }
  fi
  case "$1" in
    root|bare) survivors="1. ${lib_fix//\$FIX/$out}" ;;
    consumer) survivors="1. ${con_fix//\$FIX/$out} 2. ${lib_fix//\$FIX/$out}" ;;
  esac
  echo "seeded $out"
  echo "brief: the session's repo is $home_dir$( [ "$home" != . ] && echo ' alone (a repo session: the workspace above is ignored)'); follow step 5 of $skill and the branch's tracker doc $tracker (this repo's skills/ loaded as the plugin: claude --plugin-dir $repo_root, the skill typed dev:retro); steps 1-4 are done and their survivors, all six fields known (category: coding standards; session: $(basename "$home_dir"), today), are: $survivors; plain bd only, pointed at the home with BEADS_DIR=$home_dir/.beads bd <args>, never bd -C; save the skill's final report, verbatim, to $out/report.txt"
}

labels() { fx_field "$1" "$2" '.labels // [] | sort | join(",")'; }

assert() { # <case>
  local a b
  fx_check "the run saved its end block" test -s "$out/report.txt"
  case "$1" in
    root)
      a=$(fx_one . '.title != null')
      fx_check "one inbox bead in the root" test -n "$a"
      fx_check "labelled retro, needs-triage, target:lib (from the manifest)" fx_eq "$(labels . "$a")" "needs-triage,retro,target:lib"
      fx_check "nothing in lib" fx_eq "$(fx_all lib | jq length)" 0
      fx_check "nothing in consumer" fx_eq "$(fx_all consumer | jq length)" 0 ;;
    consumer)
      a=$(fx_one consumer '(.labels // []) | index("target:consumer")')
      b=$(fx_one consumer '(.labels // []) | index("retro:foreign")')
      fx_check "two inbox beads in consumer" fx_eq "$(fx_all consumer | jq length)" 2
      fx_check "the fix inside consumer is target:consumer" fx_eq "$(labels consumer "$a")" "needs-triage,retro,target:consumer"
      fx_check "the fix under lib is retro:foreign, no target: label" fx_eq "$(labels consumer "$b")" "needs-triage,retro,retro:foreign"
      fx_check "the foreign bead's body names the lib path" grep -qF "lib/src/lib.rs" <<<"$(fx_field consumer "$b" .description)"
      fx_check "nothing in the root (no manifest read)" fx_eq "$(fx_all . | jq length)" 0
      fx_check "nothing in lib (no bd -C)" fx_eq "$(fx_all lib | jq length)" 0 ;;
    bare)
      fx_check "no database was initialised in bare" test ! -e "$out/bare/.beads"
      fx_check "plain bd did not climb to the root's database" fx_eq "$(fx_all . | jq length)" 0
      fx_check "nothing in lib or consumer" fx_eq "$(fx_all lib | jq length)$(fx_all consumer | jq length)" 00
      fx_check "the end block keeps the candidate list" grep -qF "unused imports" "$out/report.txt" ;;
  esac
}

source "$repo_root/scripts/fixture-phases.sh"
run_phases "$@"
