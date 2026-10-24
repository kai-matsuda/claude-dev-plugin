#!/usr/bin/env bash
# Regression tests for scripts/lint-skill-docs.sh against a scratch copy of the fixture skills
# and agent docs: the plugin's own (empty) tree passes, the fixture baseline passes, and the
# retired-phrase scan (section 5) covers every file under the skills and agent docs dirs and
# matches whole words only.
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
  find "$scratch" -mindepth 1 -delete
  cp -R "$fixtures/skills" "$scratch/skills"
  cp -R "$fixtures/agents" "$scratch/agents"
}
# run the lint against the scratch copy; prints the exit code
lint_scratch() {
  SKILLS_DIR=$scratch/skills AGENT_DOCS=$scratch/agents "$lint" >/dev/null 2>&1
  echo $?
}
# expect <description> <expected exit code>
expect() {
  local rc; rc=$(lint_scratch)
  if [ "$rc" = "$2" ]; then echo "ok   $1"; else echo "FAIL $1 (exit $rc, want $2)"; fails=$((fails+1)); fi
}

check "the plugin's own tree passes" "$lint"

fresh
expect "baseline copy passes" 0

fresh
echo "retired wording: cut one" > "$scratch/skills/sample/notes.txt"
expect "retired phrase in a non-md file under a skill dir fails" 1

fresh
echo "retired wording: <spec-slug>" > "$scratch/agents/notes.yaml"
expect "retired placeholder in a non-md file under the agent docs fails" 1

fresh
echo "cut one" >> "$scratch/skills/sample/SKILL.md"
expect "retired phrase in a md file still fails" 1

fresh
echo "see story-cut.md" >> "$scratch/agents/sample.md"
expect "story-cut.md in an agent doc fails" 1

fresh
echo "run_in_background: false" >> "$scratch/skills/sample/SKILL.md"
expect "foreground spawn instruction in a skill fails" 1

fresh
printf 'a shortcut one exists\nthe cut ones stay\n' >> "$scratch/skills/sample/SKILL.md"
expect "words containing the retired phrase do not false-fail" 0

report_fails
