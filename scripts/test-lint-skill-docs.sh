#!/usr/bin/env bash
# Regression tests for scripts/lint-skill-docs.sh against a scratch copy of the fixtures (skills,
# agent docs, CLAUDE.md, GLOSSARY.md, WORKFLOW.md and the plugin skill names the runbook's
# commands resolve to): the baseline passes, an explicitly passed missing path fails, and the
# retired-phrase scan (section 5) covers every file under the skills and agent docs dirs and
# matches whole words only, and the namespace rule (section 11: only dev: and
# mattpocock-skills: pass, over every doc under docs/, the skills, the runbook, the project
# CLAUDE.md and the root glossary), the brief rule (section 13: the plugin-root variable fails
# inside a brief block and passes outside one), and the version-bump rule.
# The last section drives the version-bump rule on a throwaway git repo (VERSION_BUMP_REPO,
# VERSION_BUMP_BASE; the other cases point the repo at a non-repo path and pin the base to HEAD):
# its shipping pathspec, uncommitted edits and bumps, and the base on a detached HEAD.
# The lint of the plugin's own tree is the Makefile's first step, not repeated here.
# Usage: scripts/test-lint-skill-docs.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lint=$repo_root/scripts/lint-skill-docs.sh
fixtures=$repo_root/scripts/fixtures/lint-skill-docs
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_scratch_dir, fx_check, fails, fx_report_fails
fx_scratch_dir test-lint-skill-docs || exit 1

# fresh copy of the fixtures, so each case edits only its own file; empties the dir rather
# than recreating it (see scratch_dir)
fresh() {
  local name
  find "$scratch" -mindepth 1 -delete
  cp -R "$fixtures/skills" "$scratch/skills"
  cp -R "$fixtures/agents" "$scratch/agents"
  cp "$fixtures/project-CLAUDE.md" "$scratch/CLAUDE.md"
  cp "$fixtures/project-GLOSSARY.md" "$scratch/GLOSSARY.md"
  cp "$fixtures/WORKFLOW.md" "$scratch/"
  mkdir -p "$scratch/docs/adr"
  # the skill names the runbook's /commands resolve to, standing in for the installed plugin
  for name in grill-with-docs to-spec to-tickets implement domain-modeling improve-codebase-architecture pr tdd; do
    mkdir -p "$scratch/plugin/$name"
  done
  # and the plugin's own (dev:) skills, which resolve against the skills dir
  for name in workflow spec-to-stories spec-to-tickets implement-spec close-epic implement-story close-story; do
    mkdir -p "$scratch/skills/$name"
  done
}
# run the lint against the scratch copy, sealed to the fixtures; prints its output, then the
# exit code on a last line. Extra arguments replace the lint's own ($1 driver, $2 runbook).
lint_scratch() {
  local out rc
  [ $# -gt 0 ] || set -- "" "$scratch/WORKFLOW.md"
  # diff_base is the lint's VERSION_BUMP_BASE: HEAD by default (an empty diff), a ref to diff
  # against, or the word "derive", which leaves it unset so the lint derives the merge-base
  if [ "${diff_base:-HEAD}" = derive ]; then unset VERSION_BUMP_BASE
  else export VERSION_BUMP_BASE=${diff_base:-HEAD}; fi
  out=$(SKILLS_DIR=${skills_dir:-$scratch/skills} AGENT_DOCS=${agent_docs:-$scratch/agents} DOCS_DIR=$scratch/docs \
    USER_CLAUDE_MD=${claude_md:-$scratch/CLAUDE.md} GLOSSARY_MD=${glossary_md:-$scratch/GLOSSARY.md} \
    PLUGIN_SKILLS=$scratch/plugin VERSION_BUMP_REPO=${bump_repo_dir:-$scratch/no-repo} \
    "$lint" "$@" 2>&1)
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
  fx_check "$d" result_is "$want" "$msg" "$out"
}

fresh
expect "baseline copy passes" 0

fresh
expect "an explicit driver path that does not exist fails" 1 "no such file" "$scratch/nope.md" "$scratch/WORKFLOW.md"

fresh
expect "an explicit runbook path that does not exist fails" 1 "no such file" "" "$scratch/nope.md"

for var in skills_dir agent_docs claude_md glossary_md; do
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

# namespace rule: our skills are dev:<skill>, mattpocock's are mattpocock-skills:<skill>; a bare
# /<skill> or any other namespace fails in a skill doc, an agent doc, the runbook, the project
# CLAUDE.md or the root glossary (dev-9np)
ns_msg="bare or unknown skill namespace"
for target in skills/sample/SKILL.md agents/sample.md WORKFLOW.md CLAUDE.md GLOSSARY.md; do
  fresh
  echo "run /story-to-tickets next" >> "$scratch/$target"
  expect "a bare /<skill> in $target fails with the namespace message" 1 "$ns_msg in $scratch/$target"
  fresh
  echo "run /other:story-to-tickets next" >> "$scratch/$target"
  expect "another namespace in $target fails with the namespace message" 1 "$ns_msg in $scratch/$target"
  fresh
  printf 'run dev:story-to-tickets, then mattpocock-skills:to-tickets\nor /mattpocock-skills:tdd and /dev:workflow\n' >> "$scratch/$target"
  expect "namespaced references in $target pass" 0
done
# the loop above seeds /story-to-tickets; dev-9np's acceptance criterion names /implement-spec
# in the glossary, so that token is pinned on its own
fresh
echo "the spec runs through /implement-spec" >> "$scratch/GLOSSARY.md"
expect "a bare /implement-spec in the root glossary fails with the namespace message" 1 "$ns_msg in $scratch/GLOSSARY.md: /implement-spec"
fresh
echo "the /tmp/x path and /plugin command are not skills" >> "$scratch/skills/sample/SKILL.md"
expect "paths and built-in commands pass" 0

fresh
echo "then close it with /close-story." >> "$scratch/skills/sample/SKILL.md"
expect "a sentence-final bare /<skill>. fails" 1 "$ns_msg in $scratch/skills/sample/SKILL.md: /close-story"

fresh
echo "run /dev:workflow /close-story now" >> "$scratch/skills/sample/SKILL.md"
expect "the second of two adjacent commands is checked" 1 "$ns_msg in $scratch/skills/sample/SKILL.md: /close-story"
fresh
echo "pick (/dev:workflow|/close-story)" >> "$scratch/skills/sample/SKILL.md"
expect "an alternation's second command is checked" 1 "$ns_msg in $scratch/skills/sample/SKILL.md: /close-story"

fresh
printf 'a template <issue-template>x</issue-template> and `/tmp`\nbuilt-ins /sandbox /clear /mcp /help /config.\n' >> "$scratch/skills/sample/SKILL.md"
expect "closing tags, a bare /tmp and the built-ins pass" 0

fresh
echo "run /dev:nope" >> "$scratch/skills/sample/SKILL.md"
expect "/dev:<missing> fails as naming no skill" 1 "/dev:nope names no skill"
fresh
echo "run /mattpocock-skills:nope" >> "$scratch/skills/sample/SKILL.md"
expect "/mattpocock-skills:<missing> fails as naming no skill" 1 "/mattpocock-skills:nope names no skill"

fresh
echo "run /story-to-tickets" >> "$scratch/docs/adr/0001.md"
expect "a bare /<skill> under docs/ outside docs/agents fails" 1 "$ns_msg in $scratch/docs/adr/0001.md"
fresh
echo "run dev:story-to-tickets and /dev:workflow" >> "$scratch/docs/adr/0001.md"
expect "namespaced references under docs/adr pass" 0

fresh
echo "run /story-to-tickets" > "$scratch/driver.md"
expect "a driver passed as \$1 outside the skills dir gets the namespace check" 1 "$ns_msg in $scratch/driver.md" "$scratch/driver.md" "$scratch/WORKFLOW.md"

# paths after a placeholder, a substitution or a closing backtick are not commands
fresh
printf 'see <home>/repos.yaml and $(pwd)/x.sh and `package.json`/build-tool\nalso /usr/x.sh and /compact /init /permissions /hooks /resume\n' >> "$scratch/skills/sample/SKILL.md"
expect "paths after a placeholder, substitution or closing backtick, and more built-ins, pass" 0

# a command followed by a colon is still checked
fresh
echo "Run /close-story: it closes" >> "$scratch/skills/sample/SKILL.md"
expect "a bare /<skill>: fails" 1 "$ns_msg in $scratch/skills/sample/SKILL.md: /close-story"
fresh
echo "Run /dev:nope: x" >> "$scratch/skills/sample/SKILL.md"
expect "/dev:<missing>: fails as naming no skill" 1 "/dev:nope names no skill"
fresh
echo "write /dev:<skill> and /dev:workflow." >> "$scratch/skills/sample/SKILL.md"
expect "a /dev:<placeholder> passes" 0

# a multibyte char before a slash must not abort the tokenizer and hide the rest of the file
fresh
printf 'flow a →/dev:workflow and — /dev:workflow\nthen /close-story\n' >> "$scratch/skills/sample/SKILL.md"
LC_ALL=en_US.UTF-8 expect "a multibyte char before a slash does not hide a later bare /<skill>" 1 "$ns_msg in $scratch/skills/sample/SKILL.md: /close-story"

# markup that sits directly before a slash still lets the command be checked
for pre in '**' '_' '>' '='; do
  fresh
  echo "run ${pre}/close-story now" >> "$scratch/skills/sample/SKILL.md"
  expect "a bare /<skill> after '$pre' fails" 1 "$ns_msg in $scratch/skills/sample/SKILL.md: /close-story"
done

# a namespace written alone is not a bare command
fresh
printf 'the /dev: namespace and `/dev:` and /mattpocock-skills: too\n' >> "$scratch/skills/sample/SKILL.md"
expect "a namespace alone passes" 0

# only .md files are scanned
fresh
printf 'cd /opt and /story-to-tickets\n' > "$scratch/docs/helper.sh"
expect "a non-md file under docs is not scanned" 0
fresh
printf 'cd /opt and /story-to-tickets\n' > "$scratch/skills/sample/helper.sh"
expect "a non-md file under the skills dir is not scanned" 0

# the plugin dir absent is said so; the skill dir is matched at the plugin's skills level only
fresh
rm -r "${scratch:?}/plugin"
expect "an absent plugin dir says it cannot resolve /mattpocock-skills:<x>" 1 "plugin skills dir not found"
fresh
mkdir -p "$scratch/plugin/tdd/scripts"; touch "$scratch/plugin/tdd/SKILL.md"
echo "run /mattpocock-skills:scripts" >> "$scratch/skills/sample/SKILL.md"
expect "a directory inside a skill is not a skill" 1 "/mattpocock-skills:scripts names no skill"
fresh
mkdir -p "$scratch/plugin/engineering/tdd"
echo "run /mattpocock-skills:tdd" >> "$scratch/skills/sample/SKILL.md"
expect "a skill under a category directory resolves" 0

# a /dev:<x> resolves only to a skill dir that exists: a dropped or renamed skill fails,
# whichever skill it was, and so do a bare /<skill> and a missing mattpocock-skills: one
# when no skill has shipped
fresh
mkdir -p "$scratch/noskills"
echo "run /dev:nope" >> "$scratch/agents/sample.md"
skills_dir=$scratch/noskills expect "an unknown /dev:<x> fails while no skill has shipped" 1 "/dev:nope names no skill"
fresh
mkdir -p "$scratch/noskills"
echo "run /dev:setup-repo" >> "$scratch/agents/sample.md"
skills_dir=$scratch/noskills expect "a /dev:<x> for one of the plugin's skills fails when its dir is gone" 1 "/dev:setup-repo names no skill"
fresh
mkdir -p "$scratch/skills/new-skill"; touch "$scratch/skills/new-skill/SKILL.md"
echo "run /dev:new-skill" >> "$scratch/agents/sample.md"
expect "a shipped /dev:<x> passes" 0
fresh
mkdir -p "$scratch/noskills"
echo "run /close-story" >> "$scratch/agents/sample.md"
skills_dir=$scratch/noskills expect "a bare /<skill> fails while no skill has shipped" 1 "$ns_msg in $scratch/agents/sample.md: /close-story"
fresh
mkdir -p "$scratch/noskills"
echo "run /mattpocock-skills:nope" >> "$scratch/agents/sample.md"
skills_dir=$scratch/noskills expect "/mattpocock-skills:<missing> fails while no skill has shipped" 1 "/mattpocock-skills:nope names no skill"

# the docs ship in the plugin: a path into the dotfiles deployment or the chezmoi source fails
# in any doc under docs/ and in the runbook
for path in '~/.claude/docs/agents/orchestration.md' '~/.claude/hooks/guard-rm.sh' '~/.local/share/chezmoi/GLOSSARY.md'; do
  fresh
  echo "see \`$path\`" >> "$scratch/docs/adr/0001.md"
  expect "a dotfiles deployment path ($path) under docs/ fails" 1 "dotfiles deployment path in $scratch/docs/adr/0001.md"
done
fresh
echo 'see `~/.claude/docs/agents/*.md`' >> "$scratch/WORKFLOW.md"
expect "a dotfiles deployment path in the runbook fails" 1 "dotfiles deployment path in $scratch/WORKFLOW.md"
# and in the skills, the agent docs and the project CLAUDE.md, in the $HOME/ spelling too
fresh
echo 'read `~/.claude/docs/agents/orchestration.md`' >> "$scratch/skills/sample/SKILL.md"
expect "a dotfiles deployment path in a skill fails" 1 "dotfiles deployment path in $scratch/skills/sample/SKILL.md"
fresh
echo 'read `~/.claude/docs/agents/orchestration.md`' >> "$scratch/agents/sample.md"
expect "a dotfiles deployment path in an agent doc fails" 1 "dotfiles deployment path in $scratch/agents/sample.md"
fresh
echo 'rules: `~/.claude/docs/agents/`' >> "$scratch/CLAUDE.md"
expect "a dotfiles deployment path in the project CLAUDE.md fails" 1 "dotfiles deployment path in $scratch/CLAUDE.md"
for path in '$HOME/.claude/docs/agents/orchestration.md' '${HOME}/.claude/hooks/guard-rm.sh' '$HOME/.local/share/chezmoi/GLOSSARY.md'; do
  fresh
  echo "see \`$path\`" >> "$scratch/WORKFLOW.md"
  expect "a dotfiles deployment path in the \$HOME spelling ($path) fails" 1 "dotfiles deployment path in $scratch/WORKFLOW.md"
done

# the brief rule (dev-rc9): a brief block (a markdown quote, indented or not) that names the
# plugin-root variable fails with the skill and line named; the variable in a step outside a
# brief, where the skill itself resolves it, passes
brief_msg="plugin-root variable in a brief in"
fresh
echo '> Read the rules doc, `${CLAUDE_PLUGIN_ROOT}/docs/agents/orchestration.md`, before step 1.' >> "$scratch/skills/sample/SKILL.md"
n=$(grep -n CLAUDE_PLUGIN_ROOT "$scratch/skills/sample/SKILL.md" | cut -d: -f1)
expect "the plugin-root variable in a brief block fails with the skill and line named" 1 "$brief_msg $scratch/skills/sample/SKILL.md:$n"
fresh
printf '1. Spawn the runner:\n   > You are the runner. Read $CLAUDE_PLUGIN_ROOT/docs/agents/orchestration.md first.\n' >> "$scratch/skills/sample/SKILL.md"
n=$(grep -n CLAUDE_PLUGIN_ROOT "$scratch/skills/sample/SKILL.md" | cut -d: -f1)
expect "the bare variable in an indented brief block fails with the skill and line named" 1 "$brief_msg $scratch/skills/sample/SKILL.md:$n"
fresh
printf '> You are the runner. Read the rules doc,\n${CLAUDE_PLUGIN_ROOT}/docs/agents/orchestration.md, before step 1.\n' >> "$scratch/skills/sample/SKILL.md"
n=$(grep -n CLAUDE_PLUGIN_ROOT "$scratch/skills/sample/SKILL.md" | cut -d: -f1)
expect "the variable on a wrapped brief line that drops the > still fails" 1 "$brief_msg $scratch/skills/sample/SKILL.md:$n"
fresh
printf '> Read the rules doc at the absolute path above.\n\n1. Read `${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md` before step 2.\n' >> "$scratch/skills/sample/SKILL.md"
expect "the plugin-root variable in a step outside a brief passes" 0

# a DOCS_DIR override must exist
fresh
out=$(VERSION_BUMP_REPO=$scratch/no-repo VERSION_BUMP_BASE=HEAD DOCS_DIR=/typo-no-such-dir SKILLS_DIR=$scratch/skills AGENT_DOCS=$scratch/agents USER_CLAUDE_MD=$scratch/CLAUDE.md PLUGIN_SKILLS=$scratch/plugin "$lint" "" "$scratch/WORKFLOW.md" 2>&1; echo "rc=$?")
fx_check "a DOCS_DIR that does not exist fails" grep -qF "no such directory: /typo-no-such-dir" <<<"$out"

# docs/specs: the namespace rule applies, the existence check does not
fresh
mkdir -p "$scratch/docs/specs"
echo "run /story-to-tickets" > "$scratch/docs/specs/s.md"
expect "a bare /<skill> in docs/specs fails the namespace rule" 1 "$ns_msg in $scratch/docs/specs/s.md"
fresh
mkdir -p "$scratch/docs/specs"
echo "run /dev:not-built-yet" > "$scratch/docs/specs/s.md"
expect "a /dev:<not yet built> in docs/specs passes" 0

# --- the version-bump rule, on a throwaway git repo the lint reads via VERSION_BUMP_REPO ---
# The other cases pin the diff base to HEAD (an empty diff) and point VERSION_BUMP_REPO at a
# path that is no repo, so the checkout the test runs in never decides them; these cases let the
# lint derive the merge-base itself (diff_base=derive) in a throwaway repo.
# GIT_CEILING_DIRECTORIES stops discovery at $scratch, and make_bump_repo checks init and the
# top level before any add, so a failed init cannot commit into the enclosing checkout.
git_t() { GIT_CEILING_DIRECTORIES=$scratch git -c core.hooksPath=/dev/null -c hook.commitlint.enabled=false -c user.name=t -c user.email=t@t -c commit.gpgsign=false "$@"; }
# make_bump_repo <branch>: in the current scratch, a repo on main with a manifest at 0.1.0,
# origin/main tracking that commit, <branch> checked out from it; fails, committing nothing, when the repo cannot be made
make_bump_repo() {
  bump_repo_dir=$scratch/bump
  mkdir -p "$bump_repo_dir/.claude-plugin" "$bump_repo_dir/docs" "$bump_repo_dir/scripts"
  # separate git dir: the sandbox refuses writes to any .git/config, nested repos included
  git_t init -q --template= --separate-git-dir="$scratch/bump.gd" -b main "$bump_repo_dir" || return 1
  fx_is_repo_top "$bump_repo_dir" || return 1
  echo '{"name":"dev","version":"0.1.0"}' > "$bump_repo_dir/.claude-plugin/plugin.json"
  echo one > "$bump_repo_dir/docs/a.md"; echo one > "$bump_repo_dir/scripts/a.sh"
  git_t -C "$bump_repo_dir" add -A && git_t -C "$bump_repo_dir" commit -q -m base || return 1
  git_t -C "$bump_repo_dir" update-ref refs/remotes/origin/main main
  [ "$1" = main ] || git_t -C "$bump_repo_dir" checkout -q -b "$1"
}
bump_repo() { fresh; make_bump_repo "$1" || { echo "FAIL make the throwaway repo"; exit 1; }; }
bump_commit() { git_t -C "$bump_repo_dir" add -A; git_t -C "$bump_repo_dir" commit -q -m "$1"; }

# a failed init commits nothing, here or in the enclosing checkout
fresh
enclosing_head=$(git -C "$repo_root" rev-parse HEAD)
touch "$scratch/bump.gd"   # a file where the git dir goes: init fails
fx_check "a throwaway repo whose init fails is refused" eval '! (make_bump_repo main)'
fx_check "a failed throwaway init commits nothing into the enclosing checkout" fx_eq "$(git -C "$repo_root" rev-parse HEAD)" "$enclosing_head"
mkdir -p "$scratch/plain"
fx_check "a dir inside the enclosing checkout is no throwaway repo's top level" eval '! fx_is_repo_top "$scratch/plain"'
unset bump_repo_dir

diff_base=derive   # from here the lint derives the merge-base itself unless a case names a ref

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

# the pathspec is what ships: hooks and the glossary do, the specs under docs do not
bump_repo feat
mkdir -p "$bump_repo_dir/hooks"; echo h > "$bump_repo_dir/hooks/h.sh"; bump_commit "hooks change"
expect "a hooks-only change without a version bump fails" 1 "version bump"

bump_repo feat
echo g > "$bump_repo_dir/GLOSSARY.md"; bump_commit "glossary change"
expect "a glossary-only change without a version bump fails" 1 "version bump"

bump_repo feat
mkdir -p "$bump_repo_dir/docs/specs"; echo s > "$bump_repo_dir/docs/specs/s.md"; bump_commit "spec change"
expect "a docs/specs-only change without a version bump passes" 0

# the working tree counts, so a pre-commit run sees an uncommitted edit and an uncommitted bump
bump_repo feat
mkdir -p "$bump_repo_dir/skills/x"; echo s > "$bump_repo_dir/skills/x/SKILL.md"; bump_commit "skill added"
git_t -C "$bump_repo_dir" checkout -q main; git_t -C "$bump_repo_dir" merge -q --ff-only feat
git_t -C "$bump_repo_dir" update-ref refs/remotes/origin/main main; git_t -C "$bump_repo_dir" checkout -q feat
echo two > "$bump_repo_dir/skills/x/SKILL.md"
expect "an uncommitted edit under skills/ without a version bump fails" 1 "version bump"
echo '{"name":"dev","version":"0.2.0"}' > "$bump_repo_dir/.claude-plugin/plugin.json"
expect "an uncommitted edit under skills/ with an uncommitted bump passes" 0

bump_repo feat
mkdir -p "$bump_repo_dir/skills/y"; echo s > "$bump_repo_dir/skills/y/SKILL.md"
expect "an untracked file under skills/ without a version bump fails" 1 "version bump"

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change"
diff_base=HEAD
expect "the base variable overrides the merge-base" 0
diff_base=HEAD~1
expect "a base variable naming the PR base diffs against it" 1 "version bump"
diff_base=derive

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change"
diff_base=no-such-ref
expect "an unresolvable base variable fails with its own message" 1 "does not resolve"
diff_base=derive

# the derived base is origin's default branch, never a local main
bump_repo feat
git_t -C "$bump_repo_dir" update-ref -d refs/remotes/origin/main
expect "a repo with a local main but no origin default branch fails with no diff base" 1 "no diff base"

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change"
git_t -C "$bump_repo_dir" update-ref refs/remotes/origin/trunk main
git_t -C "$bump_repo_dir" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk
git_t -C "$bump_repo_dir" update-ref -d refs/remotes/origin/main
git_t -C "$bump_repo_dir" branch -q -f main feat   # a local main that would hide the change
expect "origin/HEAD names the default branch the base derives from" 1 "version bump"

# a detached HEAD (a GitHub Actions checkout) gets the branch's verdict, with the base variable
# set and without it
for diff_base in main derive; do
  bump_repo feat
  echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change"
  git_t -C "$bump_repo_dir" checkout -q --detach
  expect "a detached HEAD with base $diff_base and no version bump fails" 1 "version bump"
  echo '{"name":"dev","version":"0.2.0"}' > "$bump_repo_dir/.claude-plugin/plugin.json"; bump_commit "bump"
  expect "a detached HEAD with base $diff_base and a version bump passes" 0
done
diff_base=derive

bump_repo main
echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change on main"
diff_base=HEAD~1   # a real, non-empty diff: only the main guard makes this pass
expect "the rule is a no-op on main" 0
diff_base=derive

# a main that moved on after the branch point: base...HEAD sees only the branch's own changes
bump_repo feat
echo two > "$bump_repo_dir/scripts/a.sh"; bump_commit "scripts change"
git_t -C "$bump_repo_dir" checkout -q main
echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change on main"
git_t -C "$bump_repo_dir" checkout -q feat
diff_base=main
expect "the base variable is diffed three-dot, so a moved-on base does not count" 0
diff_base=derive

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"
printf '{\n  "name": "dev",\n  "version": "0.1.0"\n}\n' > "$bump_repo_dir/.claude-plugin/plugin.json"; bump_commit "docs change and reformat"
expect "a reformatted manifest with the same version is not a bump" 1 "version bump"

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"
git_t -C "$bump_repo_dir" rm -q .claude-plugin/plugin.json; bump_commit "docs change, manifest removed"
expect "a manifest missing at HEAD is not a bump" 1 "version bump"

bump_repo feat
git_t -C "$bump_repo_dir" rm -q .claude-plugin/plugin.json; bump_commit "manifest removed"
echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change"
diff_base=HEAD~1
expect "a manifest missing at both ends is not a bump" 1 "version bump"
diff_base=derive

bump_repo feat
git_t -C "$bump_repo_dir" rm -q .claude-plugin/plugin.json; bump_commit "manifest removed"
git_t -C "$bump_repo_dir" tag nomanifest
mkdir -p "$bump_repo_dir/.claude-plugin"
echo two > "$bump_repo_dir/docs/a.md"
echo '{"name":"dev","version":"0.2.0"}' > "$bump_repo_dir/.claude-plugin/plugin.json"; bump_commit "docs change, manifest added"
diff_base=nomanifest
expect "a manifest unreadable at base is not a bump" 1 "version bump"
diff_base=derive

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"
echo '{"name":"dev","version":"0.2.0"}' > "$bump_repo_dir/.claude-plugin/plugin.json"; bump_commit "docs change and bump"
git_t -C "$bump_repo_dir" branch -q -D main
expect "with no local main the merge-base uses origin/main" 0
unset bump_repo_dir

fx_report_fails
