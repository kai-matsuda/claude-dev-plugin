#!/usr/bin/env bash
# Seed/assert phase driver shared by the fixture tests whose seam is a live subagent run
# (test-fixture-retro.sh, test-fixture-story-cut.sh, test-fixture-story-cutter.sh,
# test-fixture-triage.sh). The caller sets $repo_root and $cases and defines fixture <case>
# (the case's fixture path), home_of <case> (its session repo, relative to the fixture root,
# `.` for the root), seed <case> and assert <case>, then ends with: run_phases "$@".
# A seed that finishes leaves the marker <fixture>.seeded beside its fixture (beside, so no
# checkout inside sees it), and every brief has the skill run save its end block to
# <fixture>/report.txt, which the seed clears. The no-argument run, the one make check calls,
# asserts a fixture only when both are there: one left by an interrupted seed, or seeded but
# never run by its briefed skill, is skipped with a note instead of failing the run, so a stale
# .fixtures/ in the owner checkout cannot turn make check red (dev-24m). assert <case> asserts
# whatever is there.

# Absolute path of the case's session repo; reads $out.
home_path() { # <case>
  local home; home=$(home_of "$1")
  if [ "$home" = . ]; then echo "$out"; else echo "$out/$home"; fi
}

phases_usage() { echo "usage: $0 [seed <case>|assert <case>]   cases: $cases" >&2; exit 2; }

run_phases() { # [seed <case>|assert <case>]
  local phase=${1:-all} name=${2:-} c ran=0
  case "$phase" in
    seed|assert)
      case " $cases " in *" $name "*) ;; *) phases_usage ;; esac
      out=$(fixture "$name"); source "$repo_root/scripts/fixture-test-lib.sh"
      if [ "$phase" = seed ]; then
        rm -f "$out.seeded" "$out/report.txt"
        seed "$name" || exit 1
        touch "$out.seeded"; exit 0
      fi
      assert "$name" ;;
    all)
      out=$(fixture none); source "$repo_root/scripts/fixture-test-lib.sh"
      for c in $cases; do
        out=$(fixture "$c"); [ -d "$out/.beads" ] || continue
        if [ ! -e "$out.seeded" ]; then echo "== $c: skipped, its seed did not finish (no $out.seeded); run seed $c again"; continue; fi
        if [ ! -s "$out/report.txt" ]; then echo "== $c: skipped, its briefed skill run did not finish (no $out/report.txt); run it, then assert $c"; continue; fi
        echo "== $c"; assert "$c"; ran=1
      done
      [ "$ran" = 1 ] || echo "no fixture seeded and run: run seed <case>, the briefed skill run, then assert <case>" ;;
    *) phases_usage ;;
  esac
  fx_report_fails
}
