#!/usr/bin/env bash
# Tests for .github/workflows/ci.yml: it runs on every push and on pull requests, checks out
# mattpocock/skills at a pinned tag as the lint's PLUGIN_SKILLS, installs bd, sets the
# version-bump rule's base to the PR base, and runs the Makefile's ci target, never the scripts.
# Usage: scripts/test-ci-workflow.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
wf=$repo_root/.github/workflows/ci.yml
source "$repo_root/scripts/fixture-test-lib.sh"   # check, report_fails

check "the workflow exists" test -f "$wf"
check "runs on every push" grep -Eq '^  push:' "$wf"
check "runs on pull requests" grep -Eq '^  pull_request:' "$wf"
check "push is not limited to branches" bash -c '! sed -n "/^  push:/,/^  [a-z_]*:/p" "$1" | grep -Eq "branches"' _ "$wf"
check "checks out mattpocock/skills" grep -Eq 'repository: mattpocock/skills' "$wf"
check "pins mattpocock/skills to a version tag" grep -Eq 'ref: v[0-9]+\.[0-9]+\.[0-9]+$' "$wf"
check "points PLUGIN_SKILLS at the checkout" grep -Eq 'PLUGIN_SKILLS: .*skills' "$wf"
check "sets VERSION_BUMP_BASE to the PR base" grep -Eq 'VERSION_BUMP_BASE: .*pull_request\.base\.sha' "$wf"
check "fetches full history for the version-bump diff" grep -Eq 'fetch-depth: 0' "$wf"
check "installs bd" grep -Eq 'run: .*(beads|bd)' "$wf"
check "runs the Makefile ci target" grep -Eq 'run: make ci$' "$wf"
check "never runs the scripts directly" bash -c '! grep -Eq "run: .*scripts/" "$1"' _ "$wf"
check "the Makefile lint target reuses ci" grep -Eq '^lint: ci' "$repo_root/Makefile"
check "the ci target does not run the fixtures" bash -c '! sed -n "/^ci:/,/^fixtures:/p" "$1" | grep -Eq "scripts/.*fixture"' _ "$repo_root/Makefile"

report_fails
