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
  cp "$fixtures/project-CLAUDE.md" "$scratch/CLAUDE.md"
  cp "$fixtures/WORKFLOW.md" "$scratch/"
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
  out=$(SKILLS_DIR=${skills_dir:-$scratch/skills} AGENT_DOCS=${agent_docs:-$scratch/agents} \
    USER_CLAUDE_MD=${claude_md:-$scratch/CLAUDE.md} \
    PLUGIN_SKILLS=$scratch/plugin VERSION_BUMP_REPO=${bump_repo_dir:-$repo_root} \
    VERSION_BUMP_BASE=${bump_base-HEAD} "$lint" "$@" 2>&1)
  rc=$?
  printf '%s\n%s\n' "$out" "$rc"
}
# true when the lint output $3 (last line: exit code) ends in exit code $1 and contains $2
result_is() { # <exit code> <message> <output>
  [ "${3##*$'\n'}" = "$1" ] && { [ -z "$2" ] || grep -qF -- "$2" <<<"$3"; }
}
# expect <description> <expected exit code> [message the output must contain] [lint args...]
expect() {
  local d=$1 want=$2 msg=${3:-} out
  shift 3 2>/dev/null || shift $#
  out=$(lint_scratch "$@")
  check "$d" result_is "$want" "$msg" "$out"
}

fresh
expect "baseline copy passes" 0

fresh
expect "an explicit driver path that does not exist fails" 1 "no such file" "$scratch/nope.md" "$scratch/WORKFLOW.md"

fresh
expect "an explicit runbook path that does not exist fails" 1 "no such file" "" "$scratch/nope.md"

for var in skills_dir agent_docs claude_md; do
  fresh
  eval "$var=$scratch/nope"
  expect "a set override ($var) naming a missing path fails" 1 "no such"
  unset "$var"
done

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

# --- the version-bump rule, on a throwaway git repo the lint reads via VERSION_BUMP_REPO ---
# The other cases pin the diff base to HEAD (an empty diff), so the checkout the test runs in
# never decides them; these cases unset the base and let the lint derive the merge-base itself.
git_t() { git -c core.hooksPath=/dev/null -c hook.commitlint.enabled=false -c user.name=t -c user.email=t@t -c commit.gpgsign=false "$@"; }
# bump_repo <branch>: a repo on main with a manifest at 0.1.0, <branch> checked out from it
bump_repo() {
  fresh
  bump_repo_dir=$scratch/bump
  mkdir -p "$bump_repo_dir/.claude-plugin" "$bump_repo_dir/docs" "$bump_repo_dir/scripts"
  git_t -C "$bump_repo_dir" init -q --template= -b main
  echo '{"name":"dev","version":"0.1.0"}' > "$bump_repo_dir/.claude-plugin/plugin.json"
  echo one > "$bump_repo_dir/docs/a.md"; echo one > "$bump_repo_dir/scripts/a.sh"
  git_t -C "$bump_repo_dir" add -A; git_t -C "$bump_repo_dir" commit -q -m base
  [ "$1" = main ] || git_t -C "$bump_repo_dir" checkout -q -b "$1"
}
bump_commit() { git_t -C "$bump_repo_dir" add -A; git_t -C "$bump_repo_dir" commit -q -m "$1"; }
bump_base=   # empty: the lint derives the merge-base itself

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change"
expect "a docs change without a version bump fails" 1 "version bump"

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"
echo '{"name":"dev","version":"0.2.0"}' > "$bump_repo_dir/.claude-plugin/plugin.json"; bump_commit "docs change and bump"
expect "a docs change with a version bump passes" 0

bump_repo feat
mkdir -p "$bump_repo_dir/skills/x"; echo s > "$bump_repo_dir/skills/x/SKILL.md"; bump_commit "skill change"
expect "a skills change without a version bump fails" 1 "version bump"

bump_repo feat
echo two > "$bump_repo_dir/scripts/a.sh"; bump_commit "scripts change"
expect "a scripts-only change passes" 0

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change"
bump_base=HEAD
expect "the base variable overrides the merge-base" 0
bump_base=HEAD~1
expect "a base variable naming the PR base diffs against it" 1 "version bump"
bump_base=

bump_repo main
echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change on main"
expect "the rule is a no-op on main" 0
unset bump_repo_dir

report_fails
