#!/usr/bin/env bash
# Seed/assert phase driver shared by the fixture tests whose seam is a live subagent run
# (test-fixture-retro.sh, test-fixture-story-cut.sh, test-fixture-story-cutter.sh). The caller
# sets $repo_root and $cases and defines fixture <case> (the case's fixture path), home_of
# <case> (its session repo, relative to the fixture root, `.` for the root), seed <case> and
# assert <case>, then ends with: run_phases "$@".

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
      if [ "$phase" = seed ]; then seed "$name"; exit 0; fi
      assert "$name" ;;
    all)
      out=$(fixture none); source "$repo_root/scripts/fixture-test-lib.sh"
      for c in $cases; do
        out=$(fixture "$c"); [ -d "$out/.beads" ] || continue
        echo "== $c"; assert "$c"; ran=1
      done
      [ "$ran" = 1 ] || echo "no seeded fixture: run seed <case>, the briefed skill run, then assert <case>" ;;
    *) phases_usage ;;
  esac
  report_fails
}
