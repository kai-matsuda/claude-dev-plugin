#!/usr/bin/env bash
# Tests for skills/setup-repo: the skill exists with user-invoked frontmatter naming it.
# The skill has no script, and no test reads its prose for a phrase (the spec's Testing
# Decisions, which allow frontmatter-structure checks), so the frontmatter is all there is
# to check from outside.
# Usage: scripts/test-setup-repo-skill.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_check, fx_front, fx_report_fails
doc=$repo_root/skills/setup-repo/SKILL.md

fm=$(fx_front "$doc")
fx_check "skill file exists" test -s "$doc"
fx_check "frontmatter names the skill setup-repo" grep -qx 'name: setup-repo' <<<"$fm"
fx_check "frontmatter is user-invoked" grep -qx 'disable-model-invocation: true' <<<"$fm"
fx_check "frontmatter has a description" grep -q '^description: .' <<<"$fm"

# The check target step: the explore step reads the Makefile, the write step adds `check`
# or documents the convention, and the skill names `make check` as the repo's check
# command with the review-only fallback. It names no lint-command alternative.
body=$(cat "$doc")
fx_check "explore step reads the Makefile check target" grep -q 'Makefile.*`check` target' <<<"$body"
fx_check "write step adds the check target" grep -q '`check` target:' <<<"$body"
fx_check "skill names make check as the check command" grep -q '`make check`' <<<"$body"
fx_check "skill states the review-only fallback" grep -qi 'review-only' <<<"$body"
fx_check "skill names no lint-command alternative" bash -c '! grep -qi "lint command\|make lint" "$1"' _ "$doc"

fx_report_fails
