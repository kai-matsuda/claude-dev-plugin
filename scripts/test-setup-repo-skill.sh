#!/usr/bin/env bash
# Tests for skills/setup-repo: the skill exists with user-invoked frontmatter naming it.
# The skill has no script, and no test reads its prose for a phrase (the spec's Testing
# Decisions), so the frontmatter is all there is to drive from outside.
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

fx_report_fails
