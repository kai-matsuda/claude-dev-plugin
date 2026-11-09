#!/usr/bin/env bash
# Tests for CODING_STANDARDS.md: it sits at the repo root, where the standards axis of
# mattpocock-skills:code-review looks for repo standards, and holds the verify-then-use rule
# with its reason and a wrong and a right example (dev-fb36, INFRA-42).
# Usage: scripts/test-coding-standards.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_check, fx_report_fails, section
f=$repo_root/CODING_STANDARDS.md
h='A verified value is the value every later step uses'

fx_check "CODING_STANDARDS.md exists at the repo root" test -s "$f"
fx_check "it has the verify-then-use heading" grep -qxF "## $h" "$f"
rule=$(section "$f" "$h")
fx_check "the rule names the name-versus-value gap" grep -q 'name it was resolved from' <<<"$rule"
fx_check "the rule gives its reason, the INFRA-42 land.sh case" bash -c 'grep -q "INFRA-42" <<<"$1" && grep -q "land.sh" <<<"$1"' _ "$rule"
fx_check "the rule has a wrong and a right example" bash -c 'grep -q "^- Wrong" <<<"$1" && grep -q "^- Right" <<<"$1"' _ "$rule"
fx_check "the example guards refs/heads and merges by value" bash -c 'grep -q "refs/heads" <<<"$1" && grep -q "^- Right.*git merge \"\$tip\"" <<<"$1"' _ "$rule"

fx_report_fails
