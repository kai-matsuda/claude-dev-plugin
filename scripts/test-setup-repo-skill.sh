#!/usr/bin/env bash
# Tests for skills/setup-repo: the skill exists with user-invoked frontmatter naming it, and
# its prose pins the check target step. Each prose pin is a function of the doc, so it runs
# twice: on the real skill (it must hold) and on a copy with the pinned line removed (it
# must fail), the drop-line regression case the spec's Testing Decisions ask for.
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
fx_check "description names the check target write" grep -q '^description: .*check' <<<"$fm"

# One numbered step of a doc: from "<n>. **" to the next numbered step.
step() { awk -v n="$2" '$0 ~ "^" n "\\. \\*\\*"{p=1; print; next} /^[0-9]+\. \*\*/{p=0} p' "$1"; }

# The check target step: the explore step reads the Makefile and what the repo can be checked
# with, the present and confirm steps name the proposed recipe, the write step always adds
# `check` (creating the Makefile, never an empty or `true` recipe), and the skill names
# `make check` as the repo's check command, which every owner repo has (ADR 0015). It names no
# lint-command alternative, no CLAUDE.md note in place of the target and no review-only gate.
pin_explore_makefile() { step "$1" 2 | grep -q 'GNUmakefile' && step "$1" 2 | grep -q '`check` target'; }
# it asks make's database, never a grep of the Makefile (dev-b3p); test-check-target.sh runs the query
pin_explore_make_db() { step "$1" 2 | grep -q 'never grep a Makefile: `make -pRrq :'; }
pin_explore_checkable() { step "$1" 2 | grep -q 'what the repo can be checked with'; }
pin_present_recipe() { step "$1" 3 | grep -q '`check` target'; }
pin_present_ask() { step "$1" 3 | grep -q 'ask the owner what the'; }
pin_confirm_recipe() { step "$1" 4 | grep -q '`check` recipe included'; }
pin_write_target() { step "$1" 5 | grep -q '`check` target:'; }
pin_write_phony() { step "$1" 5 | grep -q '\.PHONY'; }
pin_write_not_default() { step "$1" 5 | grep -q 'default goal'; }
pin_write_wraps() { step "$1" 5 | grep -q 'wrap'; }
pin_write_new_makefile() { step "$1" 5 | grep -q 'create one holding that target'; }
pin_write_every_repo() { step "$1" 5 | grep -q 'every owner repo'; }
pin_write_never_true() { step "$1" 5 | grep -q 'never an'; }
pin_make_check() { grep -q '`make check`' "$1"; }
pin_report_runs() { step "$1" 6 | grep -q 'what the .check. target runs'; }
pin_no_commit_makefile() { step "$1" 6 | grep -q 'commit the CLAUDE.md, Makefile'; }
fails_on() { ! "$@"; }
pin_no_lint_alt() { ! grep -qi 'lint command\|make lint' "$1"; }
pin_no_review_only() { ! grep -qi 'review-only' "$1"; }
pin_no_claude_note() { ! grep -qi 'note on the convention\|`make check` note\|`CLAUDE.md` note' "$1"; }

# name | pin | regex of the lines the pin rests on (the drop-line case removes them)
pins=(
  "explore step reads the Makefile check target|pin_explore_makefile|GNUmakefile"
  "explore step asks make's database for the check target|pin_explore_make_db|never grep a Makefile"
  "explore step reads what the repo can be checked with|pin_explore_checkable|can be checked with"
  "present step names the proposed check recipe|pin_present_recipe|check. target"
  "present step asks the owner when nothing gives a check|pin_present_ask|ask the owner what"
  "confirm step covers the check recipe|pin_confirm_recipe|recipe"
  "write step adds the check target|pin_write_target|check. target:"
  "write step declares the target .PHONY|pin_write_phony|PHONY"
  "write step keeps check off the default goal|pin_write_not_default|default goal"
  "write step wraps the existing test and lint targets|pin_write_wraps|wrap"
  "write step creates the Makefile when there is none|pin_write_new_makefile|create one holding"
  "write step says every owner repo has the target|pin_write_every_repo|every owner repo"
  "write step never writes an empty or true recipe|pin_write_never_true|never an"
  "skill names make check as the check command|pin_make_check|make check"
  "report step says what the target runs|pin_report_runs|target runs"
  "report step keeps the Makefile edit uncommitted|pin_no_commit_makefile|commit the CLAUDE.md, Makefile"
)
for p in "${pins[@]}"; do
  IFS='|' read -r name fn drop <<<"$p"
  fx_check "$name" "$fn" "$doc"
  # Drop only the lines of the step-and-line shape the pin reads: every line matching the regex.
  dropped=$(mktemp "${TMPDIR:-/tmp}/setup-repo-drop.XXXXXX") || { echo "FAIL mktemp"; fails=$((fails+1)); continue; }
  grep -v -e "$drop" "$doc" > "$dropped"
  fx_check "$name: fails with the line dropped" fails_on "$fn" "$dropped"
  rm -f "$dropped"
done
fx_check "skill names no lint-command alternative" pin_no_lint_alt "$doc"
fx_check "skill names no review-only gate" pin_no_review_only "$doc"
fx_check "skill writes no CLAUDE.md note in place of the target" pin_no_claude_note "$doc"
fx_check "description names no CLAUDE.md note" fails_on grep -q '^description: .*note' <<<"$fm"
fx_report_fails
