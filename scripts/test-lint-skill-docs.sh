#!/usr/bin/env bash
# Regression tests for scripts/lint-skill-docs.sh against a scratch copy of the fixtures (skills,
# agent docs, CLAUDE.md, WORKFLOW.md and the plugin skill names the runbook's commands resolve
# to): the baseline passes, an explicitly passed missing path fails, and the retired-phrase scan
# (section 5) covers every file under the skills and agent docs dirs and matches whole words
# only. The lint of the plugin's own tree is the Makefile's first step, not repeated here.
# Usage: scripts/test-lint-skill-docs.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lint=$repo_root/scripts/lint-skill-docs.sh
fixtures=$repo_root/scripts/fixtures/lint-skill-docs
source "$repo_root/scripts/fixture-test-lib.sh"   # scratch_dir, check, fails, report_fails
scratch_dir test-lint-skill-docs || exit 1

# fresh copy of the fixtures, so each case edits only its own file; empties the dir rather
# than recreating it (see scratch_dir)
fresh() {
  local name
  find "$scratch" -mindepth 1 -delete
  cp -R "$fixtures/skills" "$scratch/skills"
  cp -R "$fixtures/agents" "$scratch/agents"
  cp "$fixtures/CLAUDE.md" "$fixtures/WORKFLOW.md" "$scratch/"
  # the skill names the runbook's /commands resolve to, standing in for the installed plugin
  for name in grill-with-docs to-spec spec-to-stories spec-to-tickets implement-spec close-epic implement-story close-story pr; do
    mkdir -p "$scratch/plugin/$name"
  done
}
# run the lint against the scratch copy, sealed to the fixtures; prints its output, then the
# exit code on a last line. Extra arguments replace the lint's own ($1 driver, $2 runbook).
lint_scratch() {
  local out rc
  [ $# -gt 0 ] || set -- "" "$scratch/WORKFLOW.md"
  out=$(SKILLS_DIR=$scratch/skills AGENT_DOCS=$scratch/agents USER_CLAUDE_MD=$scratch/CLAUDE.md \
    PLUGIN_SKILLS=$scratch/plugin "$lint" "$@" 2>&1)
  rc=$?
  printf '%s\n%s\n' "$out" "$rc"
}
# expect <description> <expected exit code> [message the output must contain] [lint args...]
expect() {
  local d=$1 want=$2 msg=${3:-} out rc
  shift 3 2>/dev/null || shift $#
  out=$(lint_scratch "$@")
  rc=${out##*$'\n'}
  if [ "$rc" != "$want" ]; then echo "FAIL $d (exit $rc, want $want)"; fails=$((fails+1))
  elif [ -n "$msg" ] && ! grep -qF -- "$msg" <<<"$out"; then echo "FAIL $d (no \"$msg\" in the output)"; fails=$((fails+1))
  else echo "ok   $d"; fi
}

fresh
expect "baseline copy passes" 0

fresh
expect "an explicit driver path that does not exist fails" 1 "no such file" "$scratch/nope.md" "$scratch/WORKFLOW.md"

fresh
expect "an explicit runbook path that does not exist fails" 1 "no such file" "" "$scratch/nope.md"

fresh
echo "retired wording: cut one" > "$scratch/skills/sample/notes.txt"
expect "retired phrase in a non-md file under a skill dir fails" 1 "retired phrase in $scratch/skills/sample/notes.txt"

fresh
echo "retired wording: <spec-slug>" > "$scratch/agents/notes.yaml"
expect "retired placeholder in a non-md file under the agent docs fails" 1 "retired phrase in $scratch/agents/notes.yaml"

fresh
echo "cut one" >> "$scratch/skills/sample/SKILL.md"
expect "retired phrase in a md file still fails" 1 "retired phrase in $scratch/skills/sample/SKILL.md"

fresh
echo "see story-cut.md" >> "$scratch/agents/sample.md"
expect "story-cut.md in an agent doc fails" 1 "retired phrase in $scratch/agents/sample.md"

fresh
echo "run_in_background: false" >> "$scratch/skills/sample/SKILL.md"
expect "foreground spawn instruction in a skill fails" 1 "foreground spawn instruction in $scratch/skills/sample/SKILL.md"

fresh
printf 'a shortcut one exists\nthe cut ones stay\n' >> "$scratch/skills/sample/SKILL.md"
expect "words containing the retired phrase do not false-fail" 0

report_fails
