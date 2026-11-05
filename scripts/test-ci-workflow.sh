#!/usr/bin/env bash
# Tests for .github/workflows/ci.yml: it runs on a push to main and on pull requests, checks out
# mattpocock/skills at a pinned tag as the lint's PLUGIN_SKILLS, installs bd with CI blanked, sets the
# version-bump rule's base to the PR base, and runs the Makefile's check target, never the scripts;
# and the check target's git-init check refuses a test script that inits a repo outside the lib.
# Usage: scripts/test-ci-workflow.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
wf=$repo_root/.github/workflows/ci.yml
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_check, fx_report_fails

fx_check "the workflow exists" test -f "$wf"
fx_check "runs on a push" grep -Eq '^[[:space:]]+push:' "$wf"
fx_check "runs on pull requests" grep -Eq '^[[:space:]]+pull_request:' "$wf"
# a PR branch's push would fire both triggers, so one PR tip would get two runs: push is main's alone
# push_branches: the branches of the push trigger of the workflow on stdin, one per line, read
# from a flow list ([main]) or a block list (- main), quotes and trailing comments off
push_branches() {
  sed -n "/^[[:space:]]*push:/,/^[[:space:]]*pull_request:/p" | awk '
    function names(s,   i, n, w) {
      sub(/[[:space:]]+#.*/, "", s); gsub(/[][,"\047]/, " ", s)
      n = split(s, w, " "); for (i = 1; i <= n; i++) print w[i]
    }
    /^[[:space:]]*branches:/ { on = 1; sub(/^[^:]*:/, ""); names($0); next }
    on && /^[[:space:]]*-[[:space:]]/ { sub(/^[[:space:]]*-/, ""); names($0); next }
    { on = 0 }'
}
pushes_main_alone() { [ "$(push_branches <<<"$1")" = main ]; } # <workflow text>
fx_check "a push runs CI on main and on no other branch" pushes_main_alone "$(<"$wf")"
# the same branches in either YAML form read alike, so a reformat of the workflow is no failure
fx_check "branches as a block list read as main alone" pushes_main_alone $'on:\n  push:\n    branches:\n      - main\n  pull_request:\n'
pushes_other_branches() { ! pushes_main_alone "$1"; }
fx_check "a second branch in a block list is more than main" pushes_other_branches $'on:\n  push:\n    branches:\n      - main\n      - dev\n  pull_request:\n'
fx_check "a second branch in a flow list is more than main" pushes_other_branches $'on:\n  push:\n    branches: [main, dev]\n  pull_request:\n'
fx_check "pull requests are not limited to a branch or path" bash -c '! sed -n "/^[[:space:]]*pull_request:/,/^[a-z]/p" "$1" | grep -Eq "branches|paths"' _ "$wf"
fx_check "checks out mattpocock/skills" grep -Eq 'repository:[[:space:]]*mattpocock/skills' "$wf"
fx_check "pins the mattpocock/skills checkout itself to a version tag" bash -c 'grep -A3 "repository:[[:space:]]*mattpocock/skills" "$1" | grep -Eq "ref:[[:space:]]*v[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*$"' _ "$wf"
fx_check "points PLUGIN_SKILLS at the skills dir of the mattpocock checkout path" bash -c 'p=$(grep -E "^[[:space:]]+path:" "$1" | head -1 | sed "s/.*path:[[:space:]]*//"); [ -n "$p" ] && grep -Fq "PLUGIN_SKILLS: \${{ github.workspace }}/$p/skills" "$1"' _ "$wf"
fx_check "sets VERSION_BUMP_BASE to the PR base sha" grep -Eq 'VERSION_BUMP_BASE:.*pull_request\.base\.sha' "$wf"
fx_check "VERSION_BUMP_BASE applies only when the PR targets main" grep -Eq "VERSION_BUMP_BASE:.*github\.base_ref == 'main'" "$wf"
fx_check "fetches full history for the version-bump diff" grep -Eq 'fetch-depth:[[:space:]]*0' "$wf"
fx_check "installs bd pinned to a version" grep -Eq 'run:[[:space:]]*npm install -g @beads/bd@[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*$' "$wf"
fx_check "the bd install blanks CI so its postinstall downloads the binary" bash -c 'grep -A3 "run:[[:space:]]*npm install -g @beads/bd@" "$1" | grep -Eq "CI:[[:space:]]*\"\"[[:space:]]*$"' _ "$wf"
fx_check "runs the Makefile check target" grep -Eq 'run:[[:space:]]*make check[[:space:]]*$' "$wf"
fx_check "the only run steps are the bd install and make check" bash -c '[ "$(grep -Ec "^[[:space:]-]*run:" "$1")" -eq 2 ]' _ "$wf"
fx_check "never runs the scripts directly" bash -c '! grep -Eq "run:.*scripts/" "$1"' _ "$wf"
fx_check "limits the token to contents: read" bash -c 'sed -n "/^permissions:/,/^[a-z]/p" "$1" | grep -Eq "contents:[[:space:]]*read"' _ "$wf"
fx_check "cancels superseded runs with a concurrency group" bash -c 'b=$(sed -n "/^concurrency:/,/^[a-z]/p" "$1"); grep -Eq "group:" <<<"$b" && grep -Eq "cancel-in-progress:[[:space:]]*true" <<<"$b"' _ "$wf"
mk=$repo_root/Makefile
fx_check "the Makefile lint target aliases check" grep -Eq '^lint:[[:space:]]*check([[:space:]]|$)' "$mk"
fx_check "the lint help line says it aliases check" grep -Eq '^lint:.*##.*alias.*check' "$mk"
# make -n prints each target's recipe with its steps spelled out, so the checks below read what
# the target runs, not how the Makefile spells it
fx_scratch_dir test-ci-workflow || exit 1
plan() { make -n --no-print-directory -C "$repo_root" "$1" 2>&1; }
check_plan=$(plan check) fixtures_plan=$(plan fixtures)
# the one extension of the check command is a ci target in a repo whose forge needs steps it cannot
# run locally; this repo's forge needs none, so check is the whole gate and make has no ci target
no_ci_target() { ! make -C "$repo_root" -pRrq : 2>/dev/null | grep -Eq '^ci::?([^=:]|$)'; }
fx_check "the Makefile has no ci target, asked of make" no_ci_target
fx_check "make -n ci fails" bash -c '! make -n --no-print-directory -C "$1" ci >/dev/null 2>&1' _ "$repo_root"
fx_check "the Makefile names no ci_steps list, the check's steps are check_steps" bash -c '! grep -Eq "ci_steps" "$1"' _ "$mk"
fx_check "the check target runs the workflow test" grep -Fq scripts/test-ci-workflow.sh <<<"$check_plan"
fx_check "the fixtures target runs a fixture test" grep -Fq scripts/test-fixture-dag.sh <<<"$fixtures_plan"
fx_check "the check target runs every step of the fixtures" bash -c '
  for s in $(grep -oE "[a-z/-]+\.sh" <<<"$1" | sort -u); do grep -Fq "$s" <<<"$2" || { echo "check lacks $s" >&2; exit 1; }; done' _ "$fixtures_plan" "$check_plan"
# one pool: a step run apart from it (one of the Makefile's check_steps, say) would hold its seconds ahead of or behind it
fx_check "the check target runs its steps in one side-by-side run, no sub-make" bash -c '
  [ "$(grep -c "wait \$p" <<<"$1")" = 1 ] && ! grep -Eq "make (ci|fixtures)|MAKE" <<<"$1"' _ "$check_plan"
# Help text that enumerates scripts goes stale when one joins or leaves a target, so no help
# line names a script its target runs (by stem, test- and fixture- dropped) or lists names in
# the "a, b and c tests" shape the old ci text had. The steps come from make -n, as the recipes
# spell them only as lists.
help_names_scripts() { # <makefile>
  local t h s bad=0
  while IFS=$'\t' read -r t h; do
    h=$(tr 'A-Z' 'a-z' <<<"$h")
    if grep -Eq '\.sh|, [a-z-]+ and [a-z-]+ (tests|fixtures)' <<<"$h"; then echo "$t: lists scripts"; bad=1; fi
    for s in $(make -n --no-print-directory -f "$1" "$t" 2>&1 | grep -oE '[^/[:space:]]+\.sh' | sort -u); do
      s=${s%.sh}; s=${s#test-}; s=${s#fixture-}
      if [ "${#s}" -ge 4 ] && [[ $h == *"$s"* ]]; then echo "$t: $s"; bad=1; fi
    done
  done < <(awk '/^[a-z]+:.*##/ { t = $1; sub(/:.*/, "", t); h = $0; sub(/.*## /, "", h); print t "\t" h }' "$1")
  return $bad
}
fx_check "no Makefile help line names a script its target runs" help_names_scripts "$mk"
# the check must bite: a script's stem seeded into a target's help line is caught, for the
# fixtures target and check, whose recipes name no script themselves
help_seeded() { # <target> <stem>: the Makefile with the stem appended to the target's help line
  sed -E "s/^($1:.*## .*)\$/\1 $2/" "$mk" > "$scratch/seeded.mk"
  grep -Eq "^$1:.*## .*$2\$" "$scratch/seeded.mk" || return 2   # the seed missed the help line
  help_names_scripts "$scratch/seeded.mk"
}
# a seed that misses its target's help line returns 2, so it reads as a failure, not as caught (1)
fx_check "a seed that misses its help line is a failure, not a catch" eval 'help_seeded no-such-target guard-rm >/dev/null 2>&1; [ $? = 2 ]'
fx_check "a script stem seeded into the fixtures help line is caught" eval 'help_seeded fixtures stage-boundary >/dev/null 2>&1; [ $? = 1 ]'
fx_check "a script stem seeded into the check help line is caught" eval 'help_seeded check guard-rm >/dev/null 2>&1; [ $? = 1 ]'
fx_check "the check target runs the test git-init check" bash -c 'grep -Fq scripts/check-test-git-init.sh <<<"$1"' _ "$check_plan"
# a step's line in a CI log says where the time went, and its CPU seconds say whether it waited or
# worked: under its elapsed seconds, the shell's user and sys, then the step's (the times builtin)
printf 'include %s\nside_step:\n\t$(call side_by_side,true)\nside_red:\n\t$(call side_by_side,true false)\n' "$mk" > "$scratch/probe.mk"
cpu_follows() { # <output of a step named true>
  awk '/^true: [0-9]+s$/ { on = 1; next } on && /^[0-9]+m[0-9.]+s [0-9]+m[0-9.]+s$/ { n++ } END { exit n != 2 }' <<<"$1"
}
fx_check "a side-by-side step prints its CPU seconds under its elapsed seconds" cpu_follows "$(make -s -C "$scratch" -f probe.mk side_step 2>&1)"
fx_check "a red side-by-side step fails its target" eval '! make -s -C "$scratch" -f probe.mk side_red >/dev/null 2>&1'

# the git-init check: a test script that inits a repo itself, directly or through a git_* wrapper,
# fails it and is named; the lib's fx_git_repo, a bd init and a commented git init pass
init_check=$repo_root/scripts/check-test-git-init.sh
init_fixtures=$repo_root/scripts/fixtures/check-test-git-init
fx_check "the plugin's own test scripts pass the git-init check" "$init_check"
bad_out=$("$init_check" "$init_fixtures/bad" 2>&1); bad_rc=$?
fx_check "a test script that inits its own repo fails the git-init check" fx_eq "$bad_rc" 1
fx_check "the failure names the script that inits with -C <dir>" grep -Fq "scripts/test-hand-rolled.sh:3:" <<<"$bad_out"
fx_check "the failure names the script that inits through a git_* wrapper" grep -Fq "scripts/test-wrapped.sh:3:" <<<"$bad_out"
fx_check "fx_git_repo, bd init and an init in a comment pass the git-init check" "$init_check" "$init_fixtures/good"
fx_check "the fixture lib header lists this test" grep -Fq test-ci-workflow.sh "$repo_root/scripts/fixture-test-lib.sh"

# the install above puts npm's node wrapper on the PATH, the binary beside it: laid out here as
# npm lays it out, the lib's fixtures reach the binary, and any other bd is left as it is
npm_bin=$scratch/npm/lib/node_modules/@beads/bd/bin
mkdir -p "$npm_bin" "$scratch/npm/bin" "$scratch/plain"
printf '#!/bin/sh\n' | tee "$npm_bin/bd.js" "$scratch/plain/bd" > /dev/null
chmod +x "$npm_bin/bd.js" "$scratch/plain/bd"
ln -s ../lib/node_modules/@beads/bd/bin/bd.js "$scratch/npm/bin/bd"
bd_after() { # <dir first on the PATH>: the bd a fixture reaches from there
  ( PATH=$1:$PATH; fx_skip_bd_wrapper; command -v bd )
}
fx_check "a wrapper with no binary beside it stays" fx_eq "$(bd_after "$scratch/npm/bin")" "$scratch/npm/bin/bd"
printf '#!/bin/sh\n' > "$npm_bin/bd"
chmod +x "$npm_bin/bd"
# the skip puts the wrapper's resolved dir on the PATH, so the expected path is physical too: a
# checkout reached through a symlink has a $scratch that differs from it
fx_check "npm's node wrapper is skipped for the binary beside it" fx_eq "$(bd_after "$scratch/npm/bin")" "$(cd "$npm_bin" && pwd -P)/bd"
fx_check "a bd that is no npm wrapper stays" fx_eq "$(bd_after "$scratch/plain")" "$scratch/plain/bd"

fx_report_fails
