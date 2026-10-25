#!/usr/bin/env bash
# Regression tests for scripts/lint-skill-docs.sh against a scratch copy of the plugin's own tree
# (skills/, docs/, CLAUDE.md, GLOSSARY.md), plus the sample skill and agent doc under
# scripts/fixtures/lint-skill-docs and a stand-in plugin dir holding every mattpocock-skills name
# the tree references. The clean copy passes; every section has seeded copies that fail it and
# it alone (the "== <n>. " header the lint prints over its FAIL lines tells which section
# failed), and a copy missing a section's document fails naming that document rather than
# skipping the section (dev-dov). The per-phrase cases are the dotfiles source's, ported to the
# plugin layout and the dev: namespace; the namespace rule (section 11), the brief rule
# (section 13) and the path checks keep their own cases.
# The last section drives the version-bump rule on a throwaway git repo (VERSION_BUMP_REPO,
# VERSION_BUMP_BASE; the other cases point the repo at a non-repo path and pin the base to HEAD):
# its shipping pathspec, uncommitted edits and bumps, and the base on a detached HEAD.
# The lint of the plugin's own tree is the Makefile's first step, not repeated here.
# Each case's lint run goes in the background against its own snapshot of the scratch copy,
# one per CPU, and the results print in case order.
# Usage: scripts/test-lint-skill-docs.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lint=$repo_root/scripts/lint-skill-docs.sh
fixtures=$repo_root/scripts/fixtures/lint-skill-docs
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_scratch_dir, fx_git_repo, fx_check, fails, fx_report_fails
fx_scratch_dir test-lint-skill-docs || exit 1
# the case snapshots live in $scratch/.jobs, which fresh leaves alone and the lib's trap removes
jobs=$scratch/.jobs
mkdir -p "$jobs"
njobs=0 shown=0
# a rolling pool of one run per CPU: a case takes a slot token from this FIFO before it starts
# and puts it back when it ends (bash 3.2 has no wait -n to wait on any one job)
mkfifo "$jobs/slots" && exec 3<>"$jobs/slots" || exit 1
for _ in $(seq "$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"); do printf x >&3; done

# fresh copy of the tree, so each case edits only its own file; empties the dir (but .jobs)
# rather than recreating it (see fx_scratch_dir)
# the stand-in for the installed plugin: every name the tree's /commands resolve to, and the
# ones the cases below name; listed once, since every fresh copy holds the same tree
plugin_names=$(grep -rhoE 'mattpocock-skills:[a-z-]+' "$repo_root/skills" "$repo_root/docs" "$repo_root/CLAUDE.md" "$repo_root/GLOSSARY.md" \
  | cut -d: -f2; printf '%s\n' tdd to-tickets)
fresh() {
  find "$scratch" -mindepth 1 -maxdepth 1 ! -name .jobs -exec rm -rf {} +
  cp -R "$repo_root/skills" "$repo_root/docs" "$repo_root/CLAUDE.md" "$repo_root/GLOSSARY.md" "$scratch/"
  cp -R "$fixtures/skills/sample" "$scratch/skills/"
  cp "$fixtures/agents/sample.md" "$scratch/docs/agents/"
  (cd "$scratch" && sort -u <<<"$plugin_names" | sed 's|^|plugin/|' | xargs mkdir -p)
}
# run the lint against the scratch copy, sealed to it; prints its output, then the exit code on
# a last line. Extra arguments replace the lint's own ($1 driver, $2 runbook).
lint_scratch() {
  local out rc
  [ $# -gt 0 ] || set -- "" "$scratch/docs/WORKFLOW.md"
  # diff_base is the lint's VERSION_BUMP_BASE: HEAD by default (an empty diff), a ref to diff
  # against, or the word "derive", which leaves it unset so the lint derives the merge-base
  if [ "${diff_base:-HEAD}" = derive ]; then unset VERSION_BUMP_BASE
  else export VERSION_BUMP_BASE=${diff_base:-HEAD}; fi
  out=$(SKILLS_DIR=${skills_dir:-$scratch/skills} AGENT_DOCS=${agent_docs:-$scratch/docs/agents} DOCS_DIR=$scratch/docs \
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
# the sections with a FAIL line in lint output $1 (stdin), space-separated, ascending
failed_sections() {
  awk '/^== [0-9]+\. /{s=$2; sub(/\.$/, "", s)} /^FAIL/{print s}' | sort -un | tr '\n' ' ' | sed 's/ $//'
}
# judge <description> <exit code> <message> <lint output>: one ok or FAIL line, the lint's own
# FAIL lines indented under a FAIL. With $sec set, a failing case must fail in exactly the
# sections it names ("6 10"), or in exactly one section when it says "one".
judge() {
  local why= got
  result_is "$2" "$3" "$4" || why="exit ${4##*$'\n'}, want $2${3:+, with: $3}"
  if [ -z "$why" ] && [ "$2" = 1 ] && [ -n "${sec:-}" ]; then
    got=$(failed_sections <<<"$4")
    if [ "$sec" = one ]; then [ "$(wc -w <<<"$got")" -eq 1 ]; else [ "$got" = "$sec" ]; fi \
      || why="failed sections: ${got:-none}, want ${sec}"
  fi
  if [ -z "$why" ]; then echo "ok   $1"; return; fi
  echo "FAIL $1 ($why)"
  grep '^FAIL' <<<"$4" | head -5 | sed 's/^/       /'
}
# print the finished cases' lines in order, as far as they have finished, counting their FAILs;
# with "all", wait for every case first
expect_flush() {
  [ "${1:-}" != all ] || wait
  while [ "$shown" -lt "$njobs" ]; do
    if [ ! -f "$jobs/$((shown+1)).out" ]; then
      [ "${1:-}" = all ] || return 0
      # a case whose run died before judging it printed no verdict: that is a failure too
      echo "FAIL case $((shown+1)) printed no verdict" > "$jobs/$((shown+1)).out"
    fi
    shown=$((shown+1))
    rm -rf "${jobs:?}/${shown:?}"
    cat "$jobs/$shown.out"
    ! grep -q '^FAIL' "$jobs/$shown.out" || fails=$((fails+1))
  done
}
# expect <description> <expected exit code> [message the output must contain] [lint args...]
# Snapshots the scratch copy and lints the snapshot in the background, every $scratch path in the
# message, the arguments and the override variables rewritten to it. A case with a throwaway
# repo (bump_repo_dir) runs in the foreground on the scratch copy itself.
expect() {
  local d=$1 want=$2 msg=${3:-} dir a v args
  args=()
  shift 3 2>/dev/null || shift $#
  if [ -n "${bump_repo_dir:-}" ]; then
    expect_flush all
    njobs=$((njobs+1))
    judge "$d" "$want" "$msg" "$(lint_scratch "$@")" > "$jobs/$njobs.out"
    expect_flush all
    return
  fi
  njobs=$((njobs+1)) dir=$jobs/$njobs
  mkdir "$dir"
  cp -R "$scratch"/* "$dir/"   # the glob skips .jobs
  for a in "$@"; do a=${a//"$scratch"/"$dir"}; args+=("$a"); done
  read -r -n 1 -u 3 _   # wait for a free slot
  (
    for v in skills_dir agent_docs claude_md glossary_md; do
      [ -z "${!v:-}" ] || eval "$v=\${$v//\"\$scratch\"/\"\$dir\"}"
    done
    msg=${msg//"$scratch"/"$dir"} scratch=$dir
    judge "$d" "$want" "$msg" "$(lint_scratch ${args[@]+"${args[@]}"})" > "$dir.part" 2>&1
    # the .out appears whole or not at all, so expect_flush never prints half a verdict
    mv "$dir.part" "$dir.out"
    printf x >&3
  ) &
  expect_flush
}

fresh
expect "baseline copy passes" 0

fresh
expect "an explicit driver path that does not exist fails" 1 "missing document: $scratch/nope.md" "$scratch/nope.md" "$scratch/docs/WORKFLOW.md"

fresh
expect "an explicit runbook path that does not exist fails" 1 "missing document: $scratch/nope.md" "" "$scratch/nope.md"

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
echo "retired wording: <spec-slug>" > "$scratch/docs/agents/notes.yaml"
expect "retired placeholder in a non-md file under the agent docs fails" 1 "retired phrase in $scratch/docs/agents/notes.yaml"

fresh
echo "cut one" >> "$scratch/skills/sample/SKILL.md"
expect "retired phrase in a md file still fails" 1 "retired phrase in $scratch/skills/sample/SKILL.md"

fresh
echo "see story-cut.md" >> "$scratch/docs/agents/sample.md"
expect "story-cut.md in an agent doc fails" 1 "retired phrase in $scratch/docs/agents/sample.md"

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
for target in skills/sample/SKILL.md docs/agents/sample.md docs/WORKFLOW.md CLAUDE.md GLOSSARY.md; do
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
expect "a driver passed as \$1 outside the skills dir gets the namespace check" 1 "$ns_msg in $scratch/driver.md" "$scratch/driver.md" "$scratch/docs/WORKFLOW.md"

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
echo "run /dev:nope" >> "$scratch/docs/agents/sample.md"
skills_dir=$scratch/noskills expect "an unknown /dev:<x> fails while no skill has shipped" 1 "/dev:nope names no skill"
fresh
mkdir -p "$scratch/noskills"
echo "run /dev:setup-repo" >> "$scratch/docs/agents/sample.md"
skills_dir=$scratch/noskills expect "a /dev:<x> for one of the plugin's skills fails when its dir is gone" 1 "/dev:setup-repo names no skill"
fresh
echo "run /dev:no-such-skill" >> "$scratch/docs/agents/sample.md"
expect "a /dev:<x> naming no skill dir fails while other skills have shipped" 1 "/dev:no-such-skill names no skill"

# a renamed skill turns every reference to its old name red, and its new name resolves (dev-89o)
# (a throwaway skill, since renaming one a section reads fails that section too)
fresh
mkdir "$scratch/skills/old-guide"; mv "$scratch/skills/old-guide" "$scratch/skills/guide"
echo "run /dev:old-guide" >> "$scratch/docs/agents/sample.md"
expect "a /dev:<x> for a renamed skill's old name fails" 1 "/dev:old-guide names no skill"
fresh
mkdir "$scratch/skills/old-guide"; mv "$scratch/skills/old-guide" "$scratch/skills/guide"
echo "run /dev:guide" >> "$scratch/docs/agents/sample.md"
expect "a /dev:<x> for a renamed skill's new name passes" 0

fresh
mkdir -p "$scratch/skills/new-skill"; touch "$scratch/skills/new-skill/SKILL.md"
echo "run /dev:new-skill" >> "$scratch/docs/agents/sample.md"
expect "a shipped /dev:<x> passes" 0
fresh
mkdir -p "$scratch/noskills"
echo "run /close-story" >> "$scratch/docs/agents/sample.md"
skills_dir=$scratch/noskills expect "a bare /<skill> fails while no skill has shipped" 1 "$ns_msg in $scratch/docs/agents/sample.md: /close-story"
fresh
mkdir -p "$scratch/noskills"
echo "run /mattpocock-skills:nope" >> "$scratch/docs/agents/sample.md"
skills_dir=$scratch/noskills expect "/mattpocock-skills:<missing> fails while no skill has shipped" 1 "/mattpocock-skills:nope names no skill"

# the docs ship in the plugin: a path into the dotfiles deployment or the chezmoi source fails
# in any doc under docs/ and in the runbook
for path in '~/.claude/docs/agents/orchestration.md' '~/.claude/hooks/guard-rm.sh' '~/.local/share/chezmoi/GLOSSARY.md'; do
  fresh
  echo "see \`$path\`" >> "$scratch/docs/adr/0001.md"
  expect "a dotfiles deployment path ($path) under docs/ fails" 1 "dotfiles deployment path in $scratch/docs/adr/0001.md"
done
fresh
echo 'see `~/.claude/docs/agents/*.md`' >> "$scratch/docs/WORKFLOW.md"
expect "a dotfiles deployment path in the runbook fails" 1 "dotfiles deployment path in $scratch/docs/WORKFLOW.md"
# and in the skills, the agent docs and the project CLAUDE.md, in the $HOME/ spelling too
fresh
echo 'read `~/.claude/docs/agents/orchestration.md`' >> "$scratch/skills/sample/SKILL.md"
expect "a dotfiles deployment path in a skill fails" 1 "dotfiles deployment path in $scratch/skills/sample/SKILL.md"
fresh
echo 'read `~/.claude/docs/agents/orchestration.md`' >> "$scratch/docs/agents/sample.md"
expect "a dotfiles deployment path in an agent doc fails" 1 "dotfiles deployment path in $scratch/docs/agents/sample.md"
fresh
echo 'rules: `~/.claude/docs/agents/`' >> "$scratch/CLAUDE.md"
expect "a dotfiles deployment path in the project CLAUDE.md fails" 1 "dotfiles deployment path in $scratch/CLAUDE.md"
for path in '$HOME/.claude/docs/agents/orchestration.md' '${HOME}/.claude/hooks/guard-rm.sh' '$HOME/.local/share/chezmoi/GLOSSARY.md'; do
  fresh
  echo "see \`$path\`" >> "$scratch/docs/WORKFLOW.md"
  expect "a dotfiles deployment path in the \$HOME spelling ($path) fails" 1 "dotfiles deployment path in $scratch/docs/WORKFLOW.md"
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

# drop_line <file under scratch> <pattern> [-i]: delete every line matching pattern; -i
# ignores case
drop_line() { grep -vF ${3:+"$3"} -- "$2" "$scratch/$1" > "$scratch/$1.new" && mv "$scratch/$1.new" "$scratch/$1"; }
# drop_phrase <file under scratch> <phrase> [-i]: delete every occurrence of the literal phrase
# and keep the rest of its line, so a case whose phrase shares a line with another pinned
# phrase fires its own check alone; -i ignores case
drop_phrase() {
  p="$2" ci="$([ "${3:-}" = -i ] && echo 1)" awk '{
    p = ENVIRON["p"]; ci = ENVIRON["ci"]
    out = ""; rest = $0
    while (1) {
      i = ci ? index(tolower(rest), tolower(p)) : index(rest, p)
      if (!i) break
      out = out substr(rest, 1, i - 1); rest = substr(rest, i + length(p))
    }
    print out rest
  }' "$scratch/$1" > "$scratch/$1.new" && mv "$scratch/$1.new" "$scratch/$1"
}
# swap_phrase <file under scratch> <sed regex> <replacement>: rewrite the first match on each
# line (extended regex, `|` as the delimiter so paths pass), for a case that changes a phrase
# instead of dropping it
swap_phrase() { sed -E "s|$2|$3|" "$scratch/$1" > "$scratch/$1.new" && mv "$scratch/$1.new" "$scratch/$1"; }

# --- every section: a seeded copy fails that section alone, a missing document fails naming it ---
# section_case <section> <file under scratch> <line appended> <description>
section_case() {
  fresh
  printf '%s\n' "$3" >> "$scratch/$2"
  sec=$1 expect "section $1 fails alone: $4" 1
}
section_case 1 skills/implement-spec/SKILL.md 'then open a draft PR' "/implement-spec with a PR step"
section_case 2 docs/WORKFLOW.md 'each cross-repo ticket gets its own PR' "a runbook with stale wording"
section_case 3 skills/spec-to-stories/SKILL.md 'then re-sync the stories' "/spec-to-stories with a re-sync"
section_case 4 skills/spec-to-tickets/SKILL.md 'then rerun this skill for the dependent' "/spec-to-tickets with the retired rerun hint"
section_case 5 skills/sample/SKILL.md 'cut one' "a retired phrase in a skill"
section_case 6 docs/agents/orchestration.md 'push when the active profile permits' "an orchestration doc gating the push on the profile"
section_case 7 skills/story-to-tickets/SKILL.md 'read the notes under .spec-notes' "/story-to-tickets reading an owner-repo notes file"
section_case 8 skills/implement-story/SKILL.md "the rule's three entries" "/implement-story counting three Gitignore entries"
section_case 9 skills/close-story/SKILL.md 'query `tea api repos/x/y/pulls/1`' "/close-story with a Forgejo query naming no repo"
section_case 10 docs/agents/issue-tracker.md 'the only lines the story cut writes' "a tracker doc whose story cut writes two forms only"
section_case 11 skills/sample/SKILL.md 'run /story-to-tickets next' "a bare /<skill>"
section_case 12 skills/retro/SKILL.md 'grep the whole slug directory' "/retro with the bare grep instruction"
section_case 13 skills/sample/SKILL.md '> read ${CLAUDE_PLUGIN_ROOT}/docs/agents/orchestration.md' "the plugin-root variable in a brief"
# the version-bump rule (14) has its own cases at the end, each on a throwaway repo
fresh
drop_phrase skills/retro/SKILL.md 'one JSON object per line'
sec=12 expect "section 12 fails alone: /retro without the transcript shape" 1

# a section's document gone: the section fails naming it, never skips; a rules doc that two
# sections read fails both
for case in '1 skills/implement-spec/SKILL.md' '2 skills/workflow/SKILL.md' '2 docs/WORKFLOW.md' \
  '3 skills/spec-to-stories/SKILL.md' '4 skills/spec-to-tickets/SKILL.md' '6 10 docs/agents/orchestration.md' \
  '6 10 docs/agents/issue-tracker.md' '7 skills/story-to-tickets/SKILL.md' '8 skills/implement-story/SKILL.md' \
  '9 skills/close-story/SKILL.md' '12 skills/retro/SKILL.md' '0 CLAUDE.md' '0 GLOSSARY.md'; do
  doc=${case##* }
  fresh
  rm "$scratch/$doc"
  msg="missing document: $scratch/$doc"
  case $doc in CLAUDE.md|GLOSSARY.md) msg="no such file: $scratch/$doc" ;; esac
  sec=${case% *} expect "a missing $doc fails naming it" 1 "$msg"
done

# a renamed skill or rules doc turns the lint red naming the document its section reads, rather
# than turning that section off
fresh
mv "$scratch/skills/retro" "$scratch/skills/retrospective"
expect "a renamed skill directory fails naming its missing document" 1 "missing document: $scratch/skills/retro/SKILL.md"
fresh
mv "$scratch/docs/agents/orchestration.md" "$scratch/docs/agents/orchestrator.md"
expect "a renamed rules doc fails naming its missing document" 1 "missing document: $scratch/docs/agents/orchestration.md"

# --- the dotfiles source's per-phrase cases, each failing one section ---
sec=one

fresh
echo "next: /dev:spec-to-tikets <KEY>-<n>" >> "$scratch/skills/workflow/SKILL.md"
expect "misspelt command in /dev:workflow fails" 1


fresh
drop_line skills/story-to-tickets/SKILL.md 'Fetch the spec as the tracker doc'
expect "story-to-tickets without its spec fetch fails" 1

fresh
drop_line docs/agents/orchestration.md '**Waiting.**'
expect "orchestration doc without the waiting rule fails" 1

fresh
drop_line docs/agents/orchestration.md '`pgrep` cannot list processes in the sandbox'
expect "orchestration doc without the pgrep warning fails" 1

fresh
drop_line docs/agents/orchestration.md '**Delivery.**'
expect "orchestration doc without the delivery rule fails" 1

fresh
echo "push when the active profile permits" >> "$scratch/docs/agents/orchestration.md"
expect "profile-gated push in the orchestration doc fails" 1

fresh
drop_line skills/implement-story/SKILL.md 'the rules doc'"'"'s Delivery'
expect "implement-story without its delivery pointer fails" 1

fresh
echo "otherwise ask the user to run that exact command and wait for it" >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story asking the user to push fails" 1

fresh
drop_line skills/implement-story/SKILL.md 'git -C <owner> push -u origin <branch>'
expect "implement-story without the push command fails" 1

fresh
drop_line skills/implement-story/SKILL.md 'failed: push'
expect "implement-story without the refused-push failed: line fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'First the **stray-commit check**, before any push'
expect "implement-story whose deliver step pushes without the stray-commit check fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'runs the **stray-commit check** on what the merge brings in'
expect "implement-story whose merger merges without the stray-commit check fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'failed: stray commit <sha> <subject>'
expect "implement-story without the stray-commit failed: line fails" 1

fresh
drop_line skills/implement-story/SKILL.md 'git -C <owner> status --porcelain -- .gitignore'
expect "implement-story whose Gitignore step commits only what it appended fails" 1

fresh
drop_line skills/implement-story/SKILL.md 'failed: <owner>/.gitignore has uncommitted edits'
expect "implement-story whose Gitignore step absorbs a user edit fails" 1

fresh
drop_line skills/spec-to-stories/SKILL.md 'update <story-id> --design-file -'
expect "spec-to-stories without the design field write fails" 1

fresh
drop_line skills/spec-to-stories/SKILL.md 'Orientation from the story cut; the story body is the only contract.'
expect "spec-to-stories without the orientation header line fails" 1

fresh
echo 'then `git -C <owner> commit -m "chore: ignore spec notes"`' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories committing in an owner repo fails" 1

# the cut skills require their argument; no-argument recovery is retired (chezmoi-nz0)
fresh
drop_line skills/spec-to-stories/SKILL.md 'usage: /dev:spec-to-stories <KEY>-<n>|<epic-id>'
expect "spec-to-stories without its usage line fails" 1

fresh
echo 'With no argument, list the open epic beads in `<home>` and ask which is this feature'"'"'s' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories recovering the epic from the open epic list fails" 1

fresh
drop_line skills/spec-to-tickets/SKILL.md 'usage: /dev:spec-to-tickets <KEY>-<n>|<epic-id>'
expect "spec-to-tickets without its usage line fails" 1

fresh
echo 'With none, take the one on the next: line /dev:spec-to-stories ended on in the conversation' >> "$scratch/skills/spec-to-tickets/SKILL.md"
expect "spec-to-tickets recovering the epic from the conversation fails" 1

fresh
drop_line skills/workflow/SKILL.md 'next: `/dev:spec-to-tickets <arg>`'
expect "workflow printing the ticket cut without its argument fails" 1

fresh
drop_line docs/WORKFLOW.md '| 3a | `/dev:spec-to-stories <KEY>-<n>`'
expect "runbook copy without the story cut's argument in its row fails" 1

fresh
drop_line docs/WORKFLOW.md '**The argument.**'
expect "runbook copy without the argument paragraph fails" 1

# the flat path's checks-first wording and its ticket review name (dev-cq0.1.3): each phrase
# dropped alone, the rest of its row kept, so each case fires its own pin
fresh
drop_phrase docs/WORKFLOW.md "then the checks (the owner repo's lint, then the agreed test seams), then the built-in \`code-review\`"
expect "runbook copy without the checks-first flat path fails" 1 "flat path runs the checks before the built-in code-review"

fresh
drop_phrase docs/WORKFLOW.md 'the ticket review (switch'
expect "runbook copy without the ticket review name fails" 1 "flat path's review is the ticket review"

fresh
echo 'Then the ticket gate (switch `/model` to the tier'"'"'s review model) runs.' >> "$scratch/docs/WORKFLOW.md"
expect "runbook copy with the seeded phrase ticket gate fails" 1 "retired ticket gate name in the runbook"

fresh
echo 'read `<owner>/.spec-notes/<epic-id>/story-cut.md` first' >> "$scratch/skills/spec-to-tickets/SKILL.md"
sec="4 5" expect "story-cut.md in a skill fails" 1

fresh
echo 'the notes are in `story-cut.md`' >> "$scratch/docs/agents/orchestration.md"
expect "story-cut.md in an agent doc fails" 1

fresh
echo 'and `story-cut.md` notes' >> "$scratch/docs/WORKFLOW.md"
expect "story-cut.md in the runbook copy fails" 1

fresh
drop_line docs/agents/orchestration.md 'only through its beads database'
expect "orchestration doc without the beads-only principle fails" 1

fresh
echo 'The story cut commits `/.spec-notes/` ahead of this' >> "$scratch/docs/agents/orchestration.md"
expect "orchestration doc handing the gitignore line to the story cut fails" 1

fresh
echo 'with the `/.spec-notes/` line the story cut appended but could not commit' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story taking a gitignore hand-off from the story cut fails" 1

fresh
drop_line docs/agents/issue-tracker.md 'The file a `Spec: <path>` line'
expect "tracker doc without the Spec: fallback fails" 1

fresh
drop_line docs/agents/issue-tracker.md '`<path>` relative to the epic bead'"'"'s repo'
expect "tracker doc without the Spec: line's canonical form fails" 1

fresh
drop_line docs/agents/issue-tracker.md '- Epic bead writes:'
expect "tracker doc without the epic bead writes convention fails" 1

for skill in spec-to-stories spec-to-tickets story-to-tickets; do
  fresh
  drop_line "skills/$skill/SKILL.md" '"epic bead writes" convention'
  expect "$skill without its epic bead writes pointer fails" 1
done

fresh
drop_line skills/story-to-tickets/SKILL.md '**Called, draft role ("story cutter"'
expect "story-to-tickets without the story cutter trigger fails" 1

fresh
drop_line skills/story-to-tickets/SKILL.md '.[0].design'
expect "story-to-tickets without the design field read fails" 1

# the ticket cut cuts a DAG (chezmoi-9v4.1.8): a cycle is refused naming its stories, the
# cutters run in topological waves each carrying every upstream breakdown, and an already cut
# dependent of a new publish ticket is re-cut in the same run; the two-wave cap is retired.
# Review 2: a re-cut dependent that is also a dependency joins the trigger until no story joins,
# so no dependent waits on a publish the run creates; the cut-failure cascade covers only the
# run's dependencies, after the closed-uncut rule, so each story gets one report line
for phrase in 'refused: dependency cycle (' 'topological waves' 'one wave per level of the story DAG' \
  'one `Dependency:` line per publish blocker' 'a story-closure edge orders no wave' \
  're-cuts that dependent itself' 'second bump' \
  'an edge with no dependency in the run' 'has no bump child titled with that crate' \
  'cut failed: finished story (pr: note present)' \
  'holds nothing' \
  'A dependent of the run (in the set to cut or to re-cut) with such an edge' \
  'a dependent to re-cut without its publish ticket' 'applied until no story joins' \
  'and is not re-cut in this run' \
  'a dependency of the run whose cutter failed or that was itself held back' \
  'Nor is a dependent spawned whose dependency story is `closed` with no children' \
  'a step-1 progress line' 'a `recut:` line for that edge'; do
  fresh
  drop_phrase skills/spec-to-tickets/SKILL.md "$phrase"
  expect "spec-to-tickets without '$phrase' fails" 1
done

for phrase in 'in at most two dependency waves' 'in at most two waves' 'two dependency waves suffice' \
  'two waves suffice' '(two suffice)' \
  'chains are out of scope' 'then rerun this skill for the dependent' \
  '(/dev:spec-to-stories would refuse too, since stories exist)'; do
  fresh
  echo "x $phrase y" >> "$scratch/skills/spec-to-tickets/SKILL.md"
  # two of them are also section 5's retired story-DAG wording
  case $phrase in "two waves suffice"|"chains are out of scope") s="4 5" ;; *) s=4 ;; esac
  sec=$s expect "spec-to-tickets saying '$phrase' fails" 1
done
# the ban is on the cap, not on the words: two waves named without a cap pass, and so does
# "at most two" about anything but waves
for phrase in 'a chain of two waves' 'at most two tickets'; do
  fresh
  echo "x $phrase y" >> "$scratch/skills/spec-to-tickets/SKILL.md"
  expect "spec-to-tickets saying '$phrase' passes" 0
done

fresh
drop_phrase skills/story-to-tickets/SKILL.md 'Dependency pair, per edge'
expect "story-to-tickets without the per-edge pair wording fails" 1

fresh
drop_phrase skills/story-to-tickets/SKILL.md 'one bump per publish blocker'
expect "story-to-tickets without one bump per publish blocker fails" 1

fresh
drop_phrase skills/story-to-tickets/SKILL.md 'one `Dependency:` line per publish blocker'
expect "story-to-tickets brief without a Dependency line per publish blocker fails" 1

fresh
drop_phrase skills/story-to-tickets/SKILL.md 'one `Dependent:` line per dependent'
expect "story-to-tickets brief without a Dependent line per dependent fails" 1

fresh
drop_phrase skills/story-to-tickets/SKILL.md 'refused: block carries two publish tickets; one PR publishes one version'
expect "story-to-tickets without the two-publish-tickets refusal fails" 1

fresh
drop_phrase skills/story-to-tickets/SKILL.md 'or the epic bead id when the story has no key)'
expect "story-to-tickets finished-story refusal without add mode fails" 1

# add mode's OPEN path marks a finished dependent with a recut: note, which lets the re-cut
# past the finished-story refusal (story review 1)
fresh
drop_phrase skills/story-to-tickets/SKILL.md 'unless its notes carry a `recut:` line'
expect "story-to-tickets refusing a finished story add mode marked for a re-cut fails" 1

fresh
drop_phrase skills/story-to-tickets/SKILL.md 'gained a publish blocker'
expect "story-to-tickets re-cut without the second bump fails" 1

fresh
drop_phrase skills/story-to-tickets/SKILL.md "the tracker doc's per-edge re-cut rules"
expect "story-to-tickets re-cut without the per-edge rules citation fails" 1

fresh
drop_phrase skills/story-to-tickets/SKILL.md 'kept ones with `bd dep add <ticket id> <bump id>`'
expect "story-to-tickets re-cut without the re-edge of kept tickets fails" 1

fresh
drop_phrase skills/story-to-tickets/SKILL.md 'a bump covers the blocker whose crate its title names'
expect "story-to-tickets re-cut without the bump-to-blocker match fails" 1

fresh
drop_phrase skills/story-to-tickets/SKILL.md 'a line names a publish ticket when it reads'
expect "story-to-tickets without the publish ticket line shapes fails" 1

fresh
drop_line skills/implement-story/SKILL.md '.[0].design'
expect "implement-story whose exploration subagent skips the design field fails" 1

fresh
drop_line skills/implement-story/SKILL.md 'first `bd -C <owner> unclaim <id>`'
expect "implement-story leaving a failed runner's ticket claimed fails" 1

fresh
drop_line skills/implement-story/SKILL.md 'failed twice: <reason>; resume:'
expect "implement-story without the resume pointer on a second failure fails" 1

fresh
drop_line docs/agents/orchestration.md 'The one shell wait'
expect "orchestration doc without the merger's one shell wait fails" 1

fresh
drop_line skills/implement-story/SKILL.md 'named `feat/<story-id>`, keyed or not'
expect "implement-story without the feat/<story-id> branch name fails" 1

fresh
echo 'switch -c feat/<key>-<n> main' >> "$scratch/skills/implement-story/SKILL.md"
sec="5 8" expect "implement-story with the keyed branch form fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'a delivered story with an open `ready-for-agent` ticket'
expect "implement-story without the delivered-story merge guard fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'the forge decided as step 3 says'
expect "implement-story whose guard skips the forge decision fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'tea api --repo <owner> repos/{owner}/{repo}/pulls/<n>'
expect "implement-story whose guard query names no repo fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'CLOSED unmerged: refuse'
expect "implement-story whose guard lets a closed unmerged PR through fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md ' when the epic has no external ref'
expect "implement-story whose add-mode hint needs an external ref fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'with the sandbox disabled, as `/dev:close-story` step 4 does'
expect "implement-story whose merge guard runs sandboxed fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'MERGED: refuse'
expect "implement-story whose guard does not refuse a MERGED PR fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md "OPEN: continue on the \`branch:\` note's branch"
expect "implement-story whose guard does not continue on an OPEN PR fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md '(no forge, or a branch-form `pr:` note)'
expect "implement-story whose guard does not ask when the forge cannot tell fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'merge its PR and run /dev:close-story <blocker-id>`'
expect "implement-story whose story-blocker wait skips /dev:close-story fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'its branch is `feat/<story-id>`, as every story'"'"'s is (step 3)'
expect "implement-story without the keyless story's feat/<story-id> branch fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'that is not closed (open, in_progress or blocked)'
expect "implement-story whose guard misses an in_progress or blocked ticket fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md '`git -C <owner> merge-base --is-ancestor <tip SHA> origin/<default branch>`'
expect "implement-story whose guard asks before deciding the branch form locally fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'failed: <story-id> merge state unknown (<pr: value>): say whether it merged, then re-run'
expect "implement-story whose guard waits on a user in a spawned run fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'the branch form or no forge is decided locally first, then asked (below)'
expect "implement-story whose guard summary says the branch form asks the user fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md '(exit 0: as MERGED; exit 1: as OPEN; a failed fetch of an existing origin or any other exit: it cannot decide (ask))'
expect "implement-story whose ancestry check maps every other exit to OPEN fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md '(skipped with no `origin`)'
expect "implement-story whose local check fetches even with no origin fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'find `<default branch>` as step 3 says; with no `origin`, compare against the local `<default branch>`'
expect "implement-story whose local check ignores a missing origin fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md '`<repo> <story-id> <url>`'
expect "implement-story without the story-id sibling line fails" 1

fresh
echo 'each sibling appears as `<repo> <url>`' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story with the url-only sibling line fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'whose notes carry a `pr:` line'
expect "implement-story whose guard covers only a URL pr: line fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'in add mode '
expect "implement-story whose MERGED refusal does not say add mode fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md '; then close <ticket-id> (moved to the new story)'
expect "implement-story whose MERGED refusal leaves the stray ticket open fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md '(already decided in step 1 when the merge guard ran)'
expect "implement-story whose step 3 decides the forge again fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'whether the PR, or for the branch form the branch, has merged into the default branch'
expect "implement-story whose branch-form ask names a PR that does not exist fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'until add mode has carried its work into a new story, so close it there then'
expect "implement-story whose stray ticket waits on add mode moving it fails" 1

fresh
drop_line skills/implement-story/SKILL.md 'until ! [ -e <owner>/.git/index.lock ]'
expect "implement-story whose merger does not wait on the lock with an until-loop fails" 1

fresh
drop_line skills/implement-story/SKILL.md 'timeout: 300000'
expect "implement-story whose merger's lock wait has no timeout bound fails" 1

for phrase in 'waits 10 seconds and checks again' 'waits 15 seconds and retries' 'sleeps, then re-checks the lock' 'checks every 10 seconds'; do
  fresh
  echo "so it $phrase, for up to 5 minutes" >> "$scratch/skills/implement-story/SKILL.md"
  expect "implement-story whose merger '$phrase' by hand fails" 1
done

fresh
drop_line skills/implement-story/SKILL.md 'by hand only when'
expect "implement-story whose resume section skips the hand unclaim condition fails" 1

# step 9 removes worktrees with the sandbox disabled up front, sweeps earlier runs' worktrees
# whose branch is merged, and reports a locked or unmerged one instead of forcing it (chezmoi-73d)
fresh
drop_phrase skills/implement-story/SKILL.md 'worktree prune` run with the sandbox disabled'
expect "implement-story whose worktree removal runs sandboxed fails" 1

fresh
echo 'If either fails with `Operation not permitted`, retry that one command with the sandbox disabled.' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story retrying the worktree removal sandbox-disabled only after the denial fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'whose branch is `worktree-agent-*` or whose path is under `<owner>/.worktrees/`'
expect "implement-story whose sweep names neither worktree kind fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'merged into `<branch>`'
expect "implement-story whose sweep is not keyed on the merged branch fails" 1

fresh
echo '9. **Clean up** every worktree the run made.' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story sweeping only this run's worktrees fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md 'reported with its path'
expect "implement-story that does not report a locked or unmerged worktree fails" 1

fresh
echo 'a locked one is removed with `git -C <owner> worktree remove <absolute path> --force`' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story forcing a locked worktree fails" 1

fresh
echo 'a locked one is removed with `git -C <owner> worktree remove -f -f <absolute path>`' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story forcing a locked worktree with -f fails" 1

fresh
drop_line skills/implement-story/SKILL.md 'worktrees: <absolute path>'
expect "implement-story whose report template has no worktrees: line fails" 1

fresh
drop_phrase skills/implement-story/SKILL.md '`worktrees:` and `resume:` lines appear only when they have content'
expect "implement-story printing the worktrees: line unconditionally fails" 1

# every worktree brief starts with the TMPDIR line: the rule in the orchestration doc with its
# per-call export and its mktemp template, the line in each of the three briefs (chezmoi-3eg)
fresh
drop_line docs/agents/orchestration.md '**TMPDIR.**'
expect "orchestration doc without the TMPDIR rule fails" 1

# the checks read the rule's own paragraph: a word kept elsewhere in the doc does not pass them
for phrase in 'mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp' 'export TMPDIR=<worktree>/.tmp; <command>' \
  'mktemp -d <worktree>/.tmp/<name>.XXXXXX' '`.tmp/` is gitignored'; do
  fresh
  drop_phrase docs/agents/orchestration.md "$phrase"
  expect "orchestration doc without '$phrase' fails" 1
done

fresh
swap_phrase docs/agents/orchestration.md 'heredoc' 'here-document'
printf '\nA heredoc elsewhere in the doc.\n' >> "$scratch/docs/agents/orchestration.md"
expect "orchestration doc whose TMPDIR rule names no heredoc fails" 1

fresh
drop_phrase docs/agents/orchestration.md ' and `/.tmp/`'
expect "orchestration doc whose Gitignore rule lacks /.tmp/ fails" 1

fresh
swap_phrase docs/agents/orchestration.md '`/.worktrees/`, `/.spec-notes/` and `/.tmp/`' '`/.tmp/`, `/.worktrees/` and `/.spec-notes/`'
expect "orchestration doc listing /.tmp/ first among the Gitignore entries passes" 0

fresh
drop_phrase skills/implement-story/SKILL.md 'TMPDIR line'
expect "implement-story whose briefs lose the TMPDIR line fails" 1

# each brief is checked on its own: the line dropped from one step alone still fails
for step in 2 3 4; do
  fresh
  swap_phrase skills/implement-story/SKILL.md "^(> $step\. .*)TMPDIR line" '\1TMPDIR'
  expect "implement-story whose ticket runner step $step brief loses the TMPDIR line fails" 1
done

fresh
swap_phrase skills/implement-story/SKILL.md '^(7\. .*)TMPDIR line' '\1TMPDIR'
expect "implement-story whose story review fix-up brief loses the TMPDIR line fails" 1

for phrase in 'mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp' 'repeated at the head of every Bash call' \
  'mktemp -d <worktree>/.tmp/<name>.XXXXXX' "the rules doc's TMPDIR rule"; do
  fresh
  drop_phrase skills/implement-story/SKILL.md "$phrase"
  expect "implement-story without '$phrase' fails" 1
done

fresh
swap_phrase skills/implement-story/SKILL.md "the rule's four entries" "the rule's three entries"
expect "implement-story whose Gitignore step counts three entries fails" 1

# there is no foreground spawn: an Agent call returns at once, a nested orchestrator ends its
# turn and is resumed by the child's completion notification, and every subagent below the
# driver runs Bash in the foreground only; no skill says run_in_background: false (chezmoi-p4q)
for skill in implement-spec implement-story spec-to-tickets retro; do
  fresh
  echo 'Agent calls with `run_in_background: false`, so the batch runs in the foreground' >> "$scratch/skills/$skill/SKILL.md"
  expect "run_in_background: false seeded in /$skill fails" 1
done

fresh
echo 'spawn each child with `run_in_background: false`' >> "$scratch/docs/agents/orchestration.md"
expect "run_in_background: false seeded in an agent doc fails" 1

fresh
echo 'a nested orchestrator (one that is itself a subagent) spawns in the foreground' >> "$scratch/docs/agents/orchestration.md"
expect "orchestration doc regaining the nested foreground spawn fails" 1

fresh
echo 'a foreground spawn returns with the report' >> "$scratch/docs/agents/orchestration.md"
expect "orchestration doc saying a foreground spawn returns with the report fails" 1

for phrase in 'An Agent call returns at once' "the Agent tool's completion notification" 'ends its turn' 'in the foreground only' '`run_in_background` is a JSON boolean' '**Idle rule.**'; do
  fresh
  drop_line docs/agents/orchestration.md "$phrase"
  expect "orchestration doc without '$phrase' fails" 1
done

fresh
drop_line skills/implement-story/SKILL.md 'then end your turn: each runner'
expect "implement-story whose frontier spawn does not end the turn fails" 1

fresh
drop_line skills/implement-story/SKILL.md 'then end your turn: its report'
expect "ticket runner brief whose spawn does not end the turn fails" 1

fresh
drop_line skills/implement-story/SKILL.md "the rules doc's Idle rule"
expect "ticket runner brief without the idle rule fails" 1

fresh
drop_line skills/spec-to-tickets/SKILL.md 'the "Waiting" rule of `orchestration.md`'
expect "spec-to-tickets without its waiting rule pointer fails" 1

fresh
drop_line docs/agents/orchestration.md '**Unclaim.**'
expect "orchestration doc without the frontier unclaim rule fails" 1

# the frontier admits ready-for-agent tickets only, deferred review findings go to the inbox
# through the retro capture, and an untriaged child leaves a story finished (chezmoi-wgi)
fresh
drop_line docs/agents/orchestration.md 'it is labelled `ready-for-agent`'
expect "orchestration doc whose frontier is not keyed on ready-for-agent fails" 1

fresh
echo '- it is not labelled `ready-for-human`, which is all the orchestrator checks' >> "$scratch/docs/agents/orchestration.md"
expect "orchestration doc keying the frontier on ready-for-human alone fails" 1

fresh
drop_line docs/agents/orchestration.md '`needs-triage` or `wontfix`'
expect "orchestration doc whose finished story waits on an untriaged child fails" 1

fresh
drop_line skills/implement-story/SKILL.md 'keeping only the tickets labelled `ready-for-agent`'
expect "implement-story reading the frontier without the ready-for-agent filter fails" 1

fresh
echo 'minus `ready-for-human` tickets only' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story filtering the frontier on ready-for-human alone fails" 1

fresh
drop_line skills/implement-story/SKILL.md '"capture a retro item"'
expect "implement-story whose review step does not capture deferrals in the inbox fails" 1

fresh
drop_line skills/implement-story/SKILL.md '`needs-triage` or `wontfix`'
expect "implement-story whose finished story waits on an untriaged child fails" 1

# /dev:close-story counts a story's children as the finished-story definition does, and its refusal
# names the child's label (chezmoi-afn)
fresh
drop_line docs/agents/issue-tracker.md 'closed or carries `needs-triage` or `wontfix`'
expect "tracker doc whose close rule waits on an untriaged child fails" 1

fresh
drop_line skills/close-story/SKILL.md 'carries `needs-triage` or `wontfix`'
expect "close-story waiting on an untriaged child fails" 1

fresh
drop_line skills/close-story/SKILL.md 'open tickets <child> <status> <label>'
expect "close-story whose refusal drops the label fails" 1

fresh
echo 'Any child not `closed` → `<id> refused: open tickets <child> <status>, ...`' >> "$scratch/skills/close-story/SKILL.md"
expect "close-story refusing without the label fails" 1

# the tracker and orchestration docs speak of the story DAG and the human gate ticket, and
# no longer say a feature has one text blocker or that chains are out of scope (ADR 0011)
for doc in issue-tracker orchestration; do
  for phrase in 'story DAG' 'human gate ticket'; do
    fresh
    drop_line "docs/agents/$doc.md" "$phrase" -i
    expect "$doc doc without '$phrase' fails" 1
  done
  fresh
  echo "That one line is the feature's only text blocker." >> "$scratch/docs/agents/$doc.md"
  sec="5 10" expect "$doc doc saying 'only text blocker' fails" 1
  fresh
  printf 'Chains (A depends on B depends on C) are also\nout of scope.\n' >> "$scratch/docs/agents/$doc.md"
  expect "$doc doc putting chains out of scope across a line break fails" 1
  # the match is bounded, so "chains" and an unrelated "out of scope" paragraphs apart pass
  fresh
  printf '%s\n\n%s\n%s\n' 'Chains of stories are cut in one topological pass' \
    '- every story is created after each story it waits on, in its owner repo database' \
    '- a dependency pinned by git tag is out of scope' >> "$scratch/docs/agents/$doc.md"
  expect "$doc doc with chains and an unrelated out of scope paragraphs apart passes" 0
done

# a story held only by a story-closure blocker ends the run as a human stop that names the
# merge and the /dev:close-story; a publish ticket is ready once its story's tickets close; the
# story body shows no gate-ticket line no step fills; a middle story of a chain is ordered
fresh
drop_line docs/agents/orchestration.md 'merge its PR, then run `/dev:close-story <story-id>`'
expect "orchestration doc whose end state omits the story-closure human stop fails" 1

fresh
echo "it appears in bd ready as soon as its repo's implementation tickets close." >> "$scratch/docs/agents/orchestration.md"
expect "orchestration doc releasing a publish ticket on its repo's tickets fails" 1

fresh
echo '   <repo> <gate ticket id>' >> "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc whose story body shows an unfillable gate ticket line fails" 1

fresh
drop_line docs/agents/issue-tracker.md 'in the middle of a chain'
expect "tracker doc without the middle-story order fails" 1

# a repo session may hold several home stories, each the epic bead's child; the ticket cut
# runs one topological pass, not waves; a split on a deploy waits on the earlier story
fresh
drop_line docs/agents/issue-tracker.md '# repo session: every story'
expect "tracker doc creating only one repo-session story under the epic fails" 1

fresh
echo 'Only the home story has a parent: a parent cannot span databases.' >> "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc giving only one home story a parent fails" 1

fresh
drop_line docs/agents/issue-tracker.md 'one topological pass'
expect "tracker doc whose ticket cut order is not one topological pass fails" 1

fresh
echo '   ticket opens its own wave, created last' >> "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc splitting a middle story across waves fails" 1

fresh
drop_line docs/agents/issue-tracker.md 'that `/dev:close-story` requires closed'
expect "tracker doc whose deploy split names no closure wait fails" 1

# the ticket cut orders one pass per story, so every bump precedes the dependent's other
# tickets; the story cut writes a story line or a publish placeholder, never a gate ticket id
fresh
sed 's/one topological pass over the stories/one topological pass/' "$scratch/docs/agents/issue-tracker.md" > "$scratch/docs/agents/issue-tracker.md.new" && mv "$scratch/docs/agents/issue-tracker.md.new" "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc whose ticket cut pass is not per story fails" 1

fresh
echo '   In the ticket cut, one topological pass over the edges: per edge,' >> "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc ordering the ticket cut per edge fails" 1

fresh
drop_line docs/agents/issue-tracker.md 'never a line naming a gate ticket id'
expect "tracker doc without the story cut's no-gate-id rule fails" 1

fresh
echo 'two forms are the only lines the story cut writes.' >> "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc whose story cut writes only two forms fails" 1

# a re-cut blocks every open ticket but the bumps on every bump, so no bump blocks on itself
# or on another bump (step 5)
fresh
drop_line docs/agents/issue-tracker.md 'every open ticket of the story that is not a bump'
expect "tracker doc whose re-cut does not exempt the bumps fails" 1

fresh
echo 'every open ticket of the story is blocked natively on every bump' >> "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc whose re-cut blocks a bump on itself fails" 1

# /dev:spec-to-stories cuts a story DAG per edge, proposes a split only for a deprecate-then-remove
# and lets the user split for any reason (ADR 0011)
fresh
drop_phrase skills/spec-to-stories/SKILL.md 'story DAG' -i
expect "spec-to-stories without the story DAG fails" 1

fresh
echo 'For each pair of stories, decide which is the dependent' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories detecting dependencies per pair fails" 1

fresh
drop_phrase skills/spec-to-stories/SKILL.md 'only when the spec describes a deprecate-then-remove'
expect "spec-to-stories without the deprecate-then-remove split rule fails" 1

fresh
drop_phrase skills/spec-to-stories/SKILL.md "split a repo's story for any reason"
expect "spec-to-stories without the user's split fails" 1

fresh
drop_phrase skills/spec-to-stories/SKILL.md 'refused: the stories form a cycle'
expect "spec-to-stories without the cycle refusal fails" 1

fresh
drop_phrase skills/spec-to-stories/SKILL.md 'stop before any bead exists'
expect "spec-to-stories refusing a cycle after creating beads fails" 1

# the stories go out in the story DAG's topological order with one blocker line per edge, in
# both forms; the quiz, the orientation and the end report show every edge and publish
fresh
echo 'Present the stories as a numbered list, dependency first.' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories ordering the stories dependency first fails" 1

fresh
echo 'The dependency first publishes its crate, then the dependent bumps.' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories saying dependency first outside the list order passes" 0

# a story skipped for waiting on a skipped story gets no epic bead note; the skip cascades
# over closure and publish edges alike; the cycle refusal precedes step 7's epic bead too
fresh
echo 'Record each skipped story on the epic bead, as that doc'"'"'s step 2 says.' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories noting every skipped story on the epic bead fails" 1

for phrase in 'topological order' 'one `## Blocked by` line per edge' 'a story-closure edge as `<repo> <story-id>`' \
  'a publish edge as `<dep repo> publish <crate> <version> (not created yet)`' \
  'publishes: <crate> <version> (from <current version>)' 'blocked by: <repo> <story-id>' \
  'every edge of the story' \
  "the removing half waits on each migrating story's closure" \
  "a second story that bumps to the removal's version" 'names the half it needs' \
  "<repo> skipped: waits on <skipped repo>'s story" 'names the deploy as its last step' \
  'reject that change and keep iterating' 'pinned by git tag or ssh URL' \
  'several crates in one story' \
  'Record each story skipped for no beads database on the epic bead' \
  'a story skipped for waiting on one is reported only' \
  'nor any story with an edge on it in turn, closure or publish' \
  "that this run would create, step 7's epic bead included"; do
  fresh
  drop_phrase skills/spec-to-stories/SKILL.md "$phrase"
  expect "spec-to-stories without '$phrase' fails" 1
done

# the frontmatter says one story per PR; a story waiting on a skipped story's closure gets no
# invented line form (issue-tracker.md knows three)
fresh
drop_phrase skills/spec-to-stories/SKILL.md 'one story per PR, usually one per repo it changes'
expect "spec-to-stories without one story per PR in its frontmatter fails" 1

fresh
echo 'description: "resolve a spec to one story per repo it changes"' >> "$scratch/skills/spec-to-stories/SKILL.md"
sec="3 5" expect "spec-to-stories with one story per repo in its frontmatter fails" 1

fresh
echo 'written `<repo> <story title> (not created: no beads database)`' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories with an invented skipped-closure line fails" 1

# a feature whose stories exist enters add mode, with one forge query per finished story an
# addition touches; the unconditional refusal is gone (ADR 0011)
fresh
drop_phrase skills/spec-to-stories/SKILL.md 'add mode' -i
expect "spec-to-stories without add mode fails" 1

fresh
echo 'Also refuse when it already has stories → `<epic-id> refused: stories exist`' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories refusing on existing stories fails" 1

for phrase in 'refused: every story is closed' 'finished, open with failed tickets, waiting' \
  'names the `failed twice:` reason it answers' 'quizzes the additions only' \
  'gh pr view <url> --json state' 'tea api --repo <owner> repos/{owner}/{repo}/pulls/<n>' \
  'with the sandbox disabled, as `/dev:close-story` step 4 does' \
  'a new story blocked on its closure and on the new publish' 'run `/dev:close-story <story-id>`' \
  '`OPEN` defaults to a re-cut' 'a branch-form `pr:` value asks the user' \
  'publishes the additions only' 'update <story-id> --body-file -' \
  'the Jira description is untouched' '`recut: <dep repo> publish <crate> <version>`' \
  'refused: PR <url> is closed unmerged'; do
  fresh
  drop_phrase skills/spec-to-stories/SKILL.md "$phrase"
  expect "spec-to-stories add mode without '$phrase' fails" 1
done

fresh
echo '`tea api repos/{owner}/{repo}/pulls/<n>` on a Forgejo/Gitea host' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories with a tea forge query lacking --repo fails" 1

# a PR closed unmerged is refused as /dev:implement-story's merge guard refuses it (story review 1)
fresh
echo "- A PR closed unmerged is not sealed: it takes \`OPEN\`'s path." >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories re-cutting a story whose PR closed unmerged fails" 1

fresh
drop_line skills/story-to-tickets/SKILL.md 'The story and the feature, in the tracker doc'
expect "story-to-tickets without the home name in its Parent template fails" 1

fresh
echo "the nearest ancestor of <owner> holding repos.yaml" >> "$scratch/skills/spec-to-tickets/SKILL.md"
expect "walk-up phrase in /dev:spec-to-tickets fails" 1

fresh
echo "the workspace root included" >> "$scratch/skills/story-to-tickets/SKILL.md"
expect "walk-up phrase in /dev:story-to-tickets fails" 1

fresh
echo 'Story <story-id> in <owner repo>; home repo <home repo>, epic bead' >> "$scratch/skills/story-to-tickets/SKILL.md"
expect "retired home repo <home repo> Parent form in /dev:story-to-tickets fails" 1

fresh
echo "the workspace root included" >> "$scratch/skills/retro/SKILL.md"
expect "walk-up phrase in a skill no section names fails" 1

fresh
echo "the nearest ancestor of <owner> holding repos.yaml" >> "$scratch/skills/implement-spec/SKILL.md"
expect "nearest ancestor in a skill fails" 1

fresh
echo "the nearest ancestor of <owner> holding repos.yaml" >> "$scratch/docs/WORKFLOW.md"
expect "nearest ancestor in the runbook copy fails" 1

for phrase in "walking up" "walk up" "one level up" "the home repo included" "the workspace root included" "no repos.yaml above" "workspace inbox" "workspace's inbox"; do
  fresh
  echo "x $phrase y" >> "$scratch/docs/agents/orchestration.md"
  expect "$phrase in an agent doc fails" 1
  fresh
  echo "x $phrase y" >> "$scratch/CLAUDE.md"
  expect "$phrase in the user-level CLAUDE.md fails" 1
  fresh
  echo "x $phrase y" >> "$scratch/docs/WORKFLOW.md"
  expect "$phrase in the runbook copy fails" 1
done

# section 1 lints the driver file it is handed, so these cases edit a scratch copy of it and
# hand that copy to expect (chezmoi-9v4.1.6): the pinned story-closure lines, and "no merge
# steps" narrowed to let the human-stop line through while a merge procedure still fails
spec=$scratch/spec.md
fresh_spec() { fresh; cp "$scratch/skills/implement-spec/SKILL.md" "$spec"; }

fresh_spec
expect "implement-spec with the human-stop merge line passes" 0 "" "$spec" "$scratch/docs/WORKFLOW.md"

# each pin case blanks only its own phrase in the scratch copy (drop_phrase), so it cannot pass
# on the strength of an older check that shares the line
pin_case() { # <description> <phrase>
  fresh_spec
  drop_phrase spec.md "$2"
  expect "implement-spec without $1 fails" 1 "" "$spec" "$scratch/docs/WORKFLOW.md"
}
pin_case "the story-closure blocker rule" 'open until that story is closed'
pin_case "the merge-then-close human-stop line" 'the PR to merge and the /dev:close-story <story-id> to run'
pin_case "the PR url slot in the human: line" '<owner repo> <story-id> <pr url>'
pin_case "the story-closure trigger of the Human stop" 'held only by blockers naming finished stories not yet closed'
pin_case "the chain rule for stories behind a waiting story" 'itself waits only on story closures'
pin_case "the failed twice: note the hint reads" 'carries a `failed twice:` note'
pin_case "the add-mode stall hint" '/dev:spec-to-stories <KEY>-<n>'
pin_case "the add-mode hint for an epic with no external ref" '/dev:spec-to-stories <epic-id>'
pin_case "the final report's finished-story waiting: wording" 'a finished story not yet closed'
pin_case "the report template's story-closure human: line" 'human:   <owner repo> <story-id> <pr url>'

# the glossary's avoided term "human ticket" (a ready-for-human ticket is fine): the gate
# ticket is a human gate ticket (story review 1)
fresh_spec
echo "A resumed run starts the stories the closed human ticket released." >> "$spec"
expect "implement-spec saying 'human ticket' fails" 1 "" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "every open ready-for-human ticket is listed" >> "$spec"
expect "implement-spec saying 'ready-for-human ticket' passes" 0 "" "$spec" "$scratch/docs/WORKFLOW.md"

fresh
echo '(each story whose text blocker names a human ticket)' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story saying 'human ticket' fails" 1

fresh_spec
echo "The PR To Merge is named in the human line." >> "$spec"
expect "implement-spec with the allowed phrase in another case passes" 0 "" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "Then merge the branch into main with git merge." >> "$spec"
expect "implement-spec with a merge procedure fails" 1 "" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "Run gh pr merge <url> once the checks pass." >> "$spec"
expect "implement-spec with a PR merge command fails" 1 "" "$spec" "$scratch/docs/WORKFLOW.md"

# the runbook describes add mode and the human-stop merge line, and no longer lists a chain
# among the ticket cut's refusals (chezmoi-9v4.1.9)
fresh
sed -e 's|add mode|extension|g' -e 's|Add mode|Extension|g' "$scratch/docs/WORKFLOW.md" > "$scratch/docs/WORKFLOW.md.new" && mv "$scratch/docs/WORKFLOW.md.new" "$scratch/docs/WORKFLOW.md"
expect "runbook copy without add mode fails" 1

fresh
drop_phrase docs/WORKFLOW.md 'merge its PR, then run `/dev:close-story <story-id>`'
expect "runbook copy without the human-stop merge line fails" 1

fresh
drop_phrase docs/WORKFLOW.md 'the PR to merge and the /dev:close-story <story-id> to run'
expect "runbook copy without the printed human-stop line fails" 1

fresh
echo 'Among its refusals: a dependency chain (A depends on B depends on C).' >> "$scratch/docs/WORKFLOW.md"
expect "runbook copy with the chain refusal fails" 1

fresh
echo 'The ticket cut refuses a dependency chain of three stories.' >> "$scratch/docs/WORKFLOW.md"
expect "runbook copy with the chain refusal in a sentence fails" 1

fresh
echo 'The closure chain goes through a dependency chain of stories, merged in order.' >> "$scratch/docs/WORKFLOW.md"
expect "runbook copy mentioning a dependency chain of closures passes" 0

# the retired story-DAG phrases are absent from every covered file: the skills, the agent docs,
# the user-level CLAUDE.md and the runbook (one case per phrase, each planted in one file kind)
fresh
echo 'Resolve a spec to one story per repo it changes.' >> "$scratch/skills/story-to-tickets/SKILL.md"
expect "skill saying 'one story per repo' fails" 1

fresh
echo 'The keyed branch is feat/<key>-<n>.' >> "$scratch/CLAUDE.md"
expect "user CLAUDE.md saying 'feat/<key>-<n>' fails" 1

fresh
echo 'Chains are out of scope for this feature.' >> "$scratch/docs/agents/triage-labels.md"
expect "agent doc saying 'chains are out of scope' fails" 1

fresh
echo 'That one line is the feature'"'"'s only text blocker.' >> "$scratch/docs/WORKFLOW.md"
expect "runbook saying 'only text blocker' fails" 1

fresh
echo 'Two waves suffice for any feature.' >> "$scratch/skills/close-story/SKILL.md"
expect "skill saying 'two waves suffice' fails" 1

# a reviewer tags every finding blocking or minor and ends on a verdict line; a round with no
# blocking findings is clean and only blocking rounds count toward the three-round limit
# (chezmoi-49k): the rule lives in the orchestration doc, the runner brief and the story
# review point at it
fresh
drop_line docs/agents/orchestration.md '**Review verdict.**'
expect "orchestration doc without the Review verdict rule fails" 1

# the checks read the rule's own paragraph, so a phrase kept elsewhere in the doc does not pass
for phrase in 'verdict: clean' 'verdict: blocking (<n>)' '**blocking** or **minor**' 'Only blocking rounds count'; do
  fresh
  drop_phrase docs/agents/orchestration.md "$phrase"
  expect "orchestration doc without '$phrase' fails" 1
done

fresh
drop_phrase docs/agents/orchestration.md 'no blocking findings is **clean**'
expect "orchestration doc without the clean-round definition fails" 1

# the check gate rule: its paragraph, each of its phrases, and the Idle rule's mention of the checks
fresh
drop_line docs/agents/orchestration.md '**Check gate.**'
expect "orchestration doc without the Check gate rule fails" 1
for phrase in 'No reviewer sees a branch tip' 'ticket level and the story level' 'lint first, then the test seams' \
  'the first red stops' 'fix-up implementer, never to a reviewer'; do
  fresh
  drop_phrase docs/agents/orchestration.md "$phrase"
  expect "orchestration doc's Check gate rule without '$phrase' fails" 1
done
fresh
drop_phrase docs/agents/orchestration.md "which are the story's checks"
expect "orchestration doc's Idle rule without the checks fails" 1

# the lint command's resolution in /implement-story step 3 and the runner brief's header: each
# pin is proven by dropping its phrase (dev-cq0.1.2)
for phrase in 'Resolve the owner repo'"'"'s **lint command** once' \
  '`make lint` when `<owner>`'"'"'s Makefile has a `lint` target' \
  'else the command `<owner>`'"'"'s `CLAUDE.md` names, else none' \
  'lint command `<lint>` or none'; do
  fresh
  drop_phrase skills/implement-story/SKILL.md "$phrase"
  expect "implement-story without '$phrase' fails" 1
done

for phrase in 'spells it out in every implementer, fix-up implementer and merger brief it sends' 'make -C <dir> lint' \
  'the lint command `<lint>` (or none)' "the brief's lint command" \
  'a command `CLAUDE.md` names runs in that same checkout or worktree' 'leaving out any the lint command already runs'; do
  fresh
  drop_phrase skills/implement-story/SKILL.md "$phrase"
  expect "implement-story without '$phrase' fails" 1
done

# a phrase kept elsewhere in the file does not satisfy an anchored pin: dropped on its own line only
fresh
swap_phrase skills/implement-story/SKILL.md '^(> You are the ticket runner.*)the lint command `<lint>` \(or none\)' '\1the lint'
expect "runner brief header without the lint command in its every-brief list fails" 1

fresh
swap_phrase skills/implement-story/SKILL.md "^(> 2\. .*)the brief's lint command" '\1the brief'"'"'s lint command, `make ci`, `make lint`'
expect "runner step 2 offering a list of lint commands fails" 1

# the story review runs the check gate before the two-axis review, stalls on a second
# pre-review red, and cites each check's command, exit and tail as the PR's Evidence; each pin
# is proven by dropping its phrase, the order by moving the gate after the review (dev-cq0.1.5)
for phrase in 'skip the gate and the review and go to the Evidence run' \
  'the **check gate** on the integration branch tip' \
  'a second red skips the review' \
  "each check's command, its exit and the last twenty lines of its log" \
  "each check's command, exit and twenty-line tail" \
  'or <check> <command>'; do
  fresh
  drop_phrase skills/implement-story/SKILL.md "$phrase"
  expect "implement-story without '$phrase' fails" 1
done

# the stall line is read on step 7's line: dropped there while the report template keeps it
fresh
swap_phrase skills/implement-story/SKILL.md '^(7\. .*)`failed: <check> <command>`' '\1a failed line'
expect "story review step 7 without its failed: <check> <command> stall line fails" 1

# the gate named after the review on step 7's line: the order pin fails
fresh
swap_phrase skills/implement-story/SKILL.md '^(7\. .*)$' '\1 Then the **check gate** on the integration branch tip again.'
swap_phrase skills/implement-story/SKILL.md '^(7\. .*)the \*\*check gate\*\* on the integration branch tip runs first' '\1the review runs first'
expect "story review step 7 with the gate after the two-axis review fails" 1

# the retired phrase seeded back fails
fresh
echo 'Then run the seams and keep the command and its output.' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story with 'the command and its output' seeded fails" 1 "the command and its output"

# the brief's phrases are read on the runner's step 3 line alone: dropped there while step 7
# keeps them, the lint still fails (each phrase sits once on that line, so the swap hits it)
for phrase in 'verdict: clean' 'verdict: blocking \(<n>\)' '\*\*blocking\*\* or \*\*minor\*\*' 'at most three blocking rounds'; do
  fresh
  swap_phrase skills/implement-story/SKILL.md "^(> 3\. .*)$phrase" '\1'
  expect "ticket runner step 3 without '$phrase' fails" 1
done

# each pointer is checked on its own line: step 3 of the runner brief and step 7 of the skill
fresh
swap_phrase skills/implement-story/SKILL.md "^(> 3\. .*)the rules doc's Review verdict" '\1the rules doc'
expect "ticket runner step 3 without its pointer at the Review verdict rule fails" 1

fresh
swap_phrase skills/implement-story/SKILL.md "^(7\. .*)the rules doc's Review verdict" '\1the rules doc'
expect "story review step 7 without its pointer at the Review verdict rule fails" 1

fresh
echo 'Anything you cannot finish (reviewer still not clean after three rounds) is `failed`.' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story regaining the zero-findings three-round bar fails" 1

fresh
echo 'a clean round is one with no findings at all' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story saying a clean round has no findings fails" 1
unset sec

# a DOCS_DIR override must exist
expect_flush all
fresh
out=$(VERSION_BUMP_REPO=$scratch/no-repo VERSION_BUMP_BASE=HEAD DOCS_DIR=/typo-no-such-dir SKILLS_DIR=$scratch/skills AGENT_DOCS=$scratch/docs/agents USER_CLAUDE_MD=$scratch/CLAUDE.md PLUGIN_SKILLS=$scratch/plugin "$lint" "" "$scratch/docs/WORKFLOW.md" 2>&1; echo "rc=$?")
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
# make_bump_repo <branch>: in the current scratch, a repo on main with a manifest at 0.1.0,
# origin/main tracking that commit, <branch> checked out from it; fails, committing nothing, when the repo cannot be made
make_bump_repo() {
  bump_repo_dir=$scratch/bump
  mkdir -p "$bump_repo_dir/.claude-plugin" "$bump_repo_dir/docs" "$bump_repo_dir/scripts"
  # fx_git_repo refuses a dir that is not the new repo's top level, so a failed init cannot
  # commit into the enclosing checkout
  fx_git_repo "$bump_repo_dir" "$scratch/bump.gd" || return 1
  echo '{"name":"dev","version":"0.1.0"}' > "$bump_repo_dir/.claude-plugin/plugin.json"
  echo one > "$bump_repo_dir/docs/a.md"; echo one > "$bump_repo_dir/scripts/a.sh"
  git -C "$bump_repo_dir" add -A && git -C "$bump_repo_dir" commit -q -m base || return 1
  git -C "$bump_repo_dir" update-ref refs/remotes/origin/main main
  [ "$1" = main ] || git -C "$bump_repo_dir" checkout -q -b "$1"
}
bump_repo() { fresh; make_bump_repo "$1" || { echo "FAIL make the throwaway repo"; exit 1; }; }
bump_commit() { git -C "$bump_repo_dir" add -A; git -C "$bump_repo_dir" commit -q -m "$1"; }

# a failed init commits nothing, here or in the enclosing checkout
expect_flush all
fresh
enclosing_head=$(git -C "$repo_root" rev-parse HEAD)
touch "$scratch/bump.gd"   # a file where the git dir goes: init fails
fx_check "fx_git_repo refuses a dir whose git dir path is an existing file" eval '! fx_git_repo "$scratch/bump" "$scratch/bump.gd"'
fx_check "a throwaway repo whose init fails is refused" eval '! (make_bump_repo main)'
fx_check "a failed throwaway init commits nothing into the enclosing checkout" fx_eq "$(git -C "$repo_root" rev-parse HEAD)" "$enclosing_head"
mkdir -p "$scratch/plain"
fx_check "a dir inside the enclosing checkout is no throwaway repo's top level" eval '! fx_is_repo_top "$scratch/plain"'
unset bump_repo_dir

sec=14   # from here every failing case fails the version-bump rule alone
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
git -C "$bump_repo_dir" checkout -q main; git -C "$bump_repo_dir" merge -q --ff-only feat
git -C "$bump_repo_dir" update-ref refs/remotes/origin/main main; git -C "$bump_repo_dir" checkout -q feat
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
git -C "$bump_repo_dir" update-ref -d refs/remotes/origin/main
expect "a repo with a local main but no origin default branch fails with no diff base" 1 "no diff base"

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change"
git -C "$bump_repo_dir" update-ref refs/remotes/origin/trunk main
git -C "$bump_repo_dir" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk
git -C "$bump_repo_dir" update-ref -d refs/remotes/origin/main
git -C "$bump_repo_dir" branch -q -f main feat   # a local main that would hide the change
expect "origin/HEAD names the default branch the base derives from" 1 "version bump"

# a detached HEAD (a GitHub Actions checkout) gets the branch's verdict, with the base variable
# set and without it
for diff_base in main derive; do
  bump_repo feat
  echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change"
  git -C "$bump_repo_dir" checkout -q --detach
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
git -C "$bump_repo_dir" checkout -q main
echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change on main"
git -C "$bump_repo_dir" checkout -q feat
diff_base=main
expect "the base variable is diffed three-dot, so a moved-on base does not count" 0
diff_base=derive

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"
printf '{\n  "name": "dev",\n  "version": "0.1.0"\n}\n' > "$bump_repo_dir/.claude-plugin/plugin.json"; bump_commit "docs change and reformat"
expect "a reformatted manifest with the same version is not a bump" 1 "version bump"

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"
git -C "$bump_repo_dir" rm -q .claude-plugin/plugin.json; bump_commit "docs change, manifest removed"
expect "a manifest missing at HEAD is not a bump" 1 "version bump"

bump_repo feat
git -C "$bump_repo_dir" rm -q .claude-plugin/plugin.json; bump_commit "manifest removed"
echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change"
diff_base=HEAD~1
expect "a manifest missing at both ends is not a bump" 1 "version bump"
diff_base=derive

bump_repo feat
git -C "$bump_repo_dir" rm -q .claude-plugin/plugin.json; bump_commit "manifest removed"
git -C "$bump_repo_dir" tag nomanifest
mkdir -p "$bump_repo_dir/.claude-plugin"
echo two > "$bump_repo_dir/docs/a.md"
echo '{"name":"dev","version":"0.2.0"}' > "$bump_repo_dir/.claude-plugin/plugin.json"; bump_commit "docs change, manifest added"
diff_base=nomanifest
expect "a manifest unreadable at base is not a bump" 1 "version bump"
diff_base=derive

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"
echo '{"name":"dev","version":"0.2.0"}' > "$bump_repo_dir/.claude-plugin/plugin.json"; bump_commit "docs change and bump"
git -C "$bump_repo_dir" branch -q -D main
expect "with no local main the merge-base uses origin/main" 0
unset bump_repo_dir sec

expect_flush all
fx_report_fails
