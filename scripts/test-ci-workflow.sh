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
check "runs on every push" grep -Eq '^[[:space:]]+push:' "$wf"
check "runs on pull requests" grep -Eq '^[[:space:]]+pull_request:' "$wf"
check "push is not limited to branches" bash -c '! sed -n "/^[[:space:]]*push:/,/^[[:space:]]*pull_request:/p" "$1" | grep -Eq "branches"' _ "$wf"
check "checks out mattpocock/skills" grep -Eq 'repository:[[:space:]]*mattpocock/skills' "$wf"
check "pins the mattpocock/skills checkout itself to a version tag" bash -c 'grep -A3 "repository:[[:space:]]*mattpocock/skills" "$1" | grep -Eq "ref:[[:space:]]*v[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*$"' _ "$wf"
check "points PLUGIN_SKILLS at the skills dir of the mattpocock checkout path" bash -c 'p=$(grep -E "^[[:space:]]+path:" "$1" | head -1 | sed "s/.*path:[[:space:]]*//"); [ -n "$p" ] && grep -Fq "PLUGIN_SKILLS: \${{ github.workspace }}/$p/skills" "$1"' _ "$wf"
check "sets VERSION_BUMP_BASE to the PR base sha" grep -Eq 'VERSION_BUMP_BASE:.*pull_request\.base\.sha' "$wf"
check "VERSION_BUMP_BASE applies only when the PR targets main" grep -Eq "VERSION_BUMP_BASE:.*github\.base_ref == 'main'" "$wf"
check "fetches full history for the version-bump diff" grep -Eq 'fetch-depth:[[:space:]]*0' "$wf"
check "installs bd pinned to a version" grep -Eq 'run:[[:space:]]*npm install -g @beads/bd@[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*$' "$wf"
check "runs the Makefile ci target" grep -Eq 'run:[[:space:]]*make ci[[:space:]]*$' "$wf"
check "the only run steps are the bd install and make ci" bash -c '[ "$(grep -Ec "^[[:space:]-]*run:" "$1")" -eq 2 ]' _ "$wf"
check "never runs the scripts directly" bash -c '! grep -Eq "run:.*scripts/" "$1"' _ "$wf"
check "limits the token to contents: read" bash -c 'sed -n "/^permissions:/,/^[a-z]/p" "$1" | grep -Eq "contents:[[:space:]]*read"' _ "$wf"
check "cancels superseded runs with a concurrency group" bash -c 'b=$(sed -n "/^concurrency:/,/^[a-z]/p" "$1"); grep -Eq "group:" <<<"$b" && grep -Eq "cancel-in-progress:[[:space:]]*true" <<<"$b"' _ "$wf"
mk=$repo_root/Makefile
ci_block=$(awk '/^ci:/{f=1;print;next} f&&!/^\t/{exit} f{print}' "$mk")
check "the Makefile lint target reuses ci" grep -Eq '^lint:[[:space:]]*ci' "$mk"
check "the ci target runs the workflow test" bash -c 'grep -Fq scripts/test-ci-workflow.sh <<<"$1"' _ "$ci_block"
check "the ci target runs no fixtures, direct or via make" bash -c '! tail -n +2 <<<"$1" | grep -Eq "fixture|MAKE"' _ "$ci_block"
# Help text that enumerates scripts goes stale when one joins or leaves a target, so no help
# line names a script its recipe runs (by stem, test- and fixture- dropped) or lists names in
# the "a, b and c tests" shape the old ci text had.
help_names_scripts() { # <makefile>
  awk '
    /^[a-z]+:.*##/ { t = $1; sub(/:.*/, "", t); h = tolower($0); sub(/.*## /, "", h)
                     if (h ~ /\.sh|, [a-z-]+ and [a-z-]+ (tests|fixtures)/) { print t ": lists scripts"; bad = 1 }
                     next }
    !/^\t/ { t = ""; next }
    t && match($0, /[^\/[:space:]]+\.sh/) { s = substr($0, RSTART, RLENGTH - 3); sub(/^test-/, "", s); sub(/^fixture-/, "", s)
                     if (length(s) >= 4 && index(h, s)) { print t ": " s; bad = 1 } }
    END { exit bad }' "$1"
}
check "no Makefile help line names a script its recipe runs" help_names_scripts "$mk"
check "the fixture lib header lists this test" grep -Fq test-ci-workflow.sh "$repo_root/scripts/fixture-test-lib.sh"

report_fails
