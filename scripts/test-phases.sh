#!/usr/bin/env bash
# Tests for scripts/fixture-phases.sh, the seed/assert driver of the phased fixture tests, through
# a stub caller whose fixtures live in a scratch dir and need no bd (dev-24m, INFRA-31). The
# no-argument run, the one make check calls, asserts a fixture only once its briefed skill run
# has finished (the run saved $out/report.txt), and skips with a note one that was seeded but
# never run, or whose seed was interrupted (no .seeded marker), so the owner checkout's stale
# .fixtures/ cannot turn make check red. An explicit assert <case> still asserts.
# Usage: scripts/test-phases.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # fails, fx_check, fx_scratch_dir, fx_report_fails
fx_scratch_dir test-phases || { echo "FAIL make scratch dir"; exit 1; }

# The stub caller: seed makes the fixture's .beads/ (STUB_INTERRUPT stops it there, as a killed
# seed would), assert checks the end block and that the run left no $out/broken
stub=$scratch/stub.sh
cat > "$stub" <<T
#!/usr/bin/env bash
set -uo pipefail
repo_root=$repo_root
cases="ran stale"
fixture() { echo "$scratch/fx/\$1"; }
home_of() { echo .; }
seed() { mkdir -p "\$out/.beads"; [ -z "\${STUB_INTERRUPT:-}" ] || exit 1; }
assert() {
  fx_check "the run saved its end block" test -s "\$out/report.txt"
  fx_check "the run left nothing broken" test ! -e "\$out/broken"
}
source "\$repo_root/scripts/fixture-phases.sh"
run_phases "\$@"
T
chmod +x "$stub"
fx() { echo "$scratch/fx/$1"; }

# expect <description> <expected exit code> <expected output line regex...>: on the no-argument run
expect() {
  local d=$1 want=$2 got rc re; shift 2
  got=$("$stub" 2>&1); rc=$?
  if [ "$rc" != "$want" ]; then echo "FAIL $d: exit $rc, want $want"; echo "$got" | sed 's/^/     /'; fails=$((fails+1)); return; fi
  for re in "$@"; do
    grep -qE "$re" <<<"$got" || { echo "FAIL $d: no line matching '$re'"; echo "$got" | sed 's/^/     /'; fails=$((fails+1)); return; }
  done
  echo "ok   $d"
}

# a stale fixture: seeded, its briefed skill run never happened
"$stub" seed stale >/dev/null
expect "a seeded fixture whose skill run never happened is skipped with a note" 0 \
  '^== stale: skipped, .*no .*report\.txt'
fx_check "the skip does not assert the stale fixture" bash -c "! '$stub' | grep -q '^== stale\$'"

# beside it, a fixture whose skill run finished is asserted
"$stub" seed ran >/dev/null; echo "end block" > "$(fx ran)/report.txt"
expect "a fixture whose skill run finished is asserted beside the stale one" 0 \
  '^== ran$' '^ok   the run saved its end block$' '^== stale: skipped' '^all passed$'
touch "$(fx ran)/broken"
expect "a finished fixture that fails its assert still turns the run red" 1 '^== ran$' '^FAIL the run left nothing broken$'
rm -f "$(fx ran)/broken"

# an interrupted seed (no .seeded marker) is skipped as before, even with a report beside it
STUB_INTERRUPT=1 "$stub" seed stale >/dev/null
echo "end block" > "$(fx stale)/report.txt"
fx_check "the interrupted seed left no .seeded marker" test ! -e "$(fx stale).seeded"
expect "a fixture left by an interrupted seed is skipped with a note" 0 '^== stale: skipped, its seed did not finish'

# an explicit assert still asserts a fixture whose skill run never happened
"$stub" seed stale >/dev/null
fx_check "assert <case> on a stale fixture fails" bash -c "! '$stub' assert stale"

fx_report_fails
