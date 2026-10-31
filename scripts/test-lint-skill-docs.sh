#!/usr/bin/env bash
# Regression tests for scripts/lint-skill-docs.sh against a scratch copy of the plugin's own tree
# (skills/, docs/, CLAUDE.md, GLOSSARY.md), plus the sample skill and agent doc under
# scripts/fixtures/lint-skill-docs and a stand-in plugin dir holding every mattpocock-skills name
# the tree references. The clean copy passes; every section has seeded copies that fail it and
# it alone (the "== <n>. " header the lint prints over its FAIL lines tells which section
# failed), and a copy missing a section's document fails naming that document rather than
# skipping the section (dev-dov). Every pinned phrase of the lint has its drop cases derived from
# the lint's own list of its checks (LINT_PIN_LIST), so no case copies a phrase (dev-yqpz); the
# cases below that are written by hand seed a retired or absent phrase, and the namespace rule
# (section 11), the brief rule (section 13) and the path checks keep their own cases.
# The last section drives the version-bump rule on a throwaway git repo (VERSION_BUMP_REPO,
# VERSION_BUMP_BASE; the other cases point the repo at a non-repo path and pin the base to HEAD):
# its shipping pathspec, uncommitted edits and bumps, and the base on a detached HEAD.
# The lint of the plugin's own tree is the Makefile's first step, not repeated here.
# Each case's lint run goes in the background against the scratch tree, moved into the case's
# own dir (one tree per expect: fresh builds it, expect takes it), one per CPU, and the results
# print in case order. Every fresh and snapshot runs in this shell, one after another, so each
# is one process: fresh is a cp of a pristine tree built once, the snapshot is a mv, and the
# verdicts are read and tallied with builtins. Every case but the baseline lints with
# LINT_UNCHANGED listing its files still byte-identical to the pristine tree, whose queued checks
# the baseline shows pass, so a run checks only what its case seeded.
# No wait in the pool is unbounded (dev-1ef): each lint run (under perl, which macOS and the
# ubuntu runner ship) is killed, its whole process group, after LINT_CASE_TIMEOUT seconds
# (default 120) and its case fails naming the timeout; a case's slot token goes back from an
# EXIT trap, so a case that dies early, short of a SIGKILL, still frees its slot; and a wait for
# a slot, or for every slot at the end, gives up after the case timeout plus 30 seconds, failing
# the run with the cases still holding one. For checking those bounds by hand,
# LINT_TEST_SEED=hang:<n> (case n's lint never returns) or drop:<n> (case n keeps its token)
# seeds a stall; no target runs them.
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
njobs=0 shown=0 nl=$'\n'
# a rolling pool of one run per CPU: a case takes a slot token from this FIFO before it starts
# and puts it back when it ends (bash 3.2 has no wait -n to wait on any one job)
mkfifo "$jobs/slots" && exec 3<>"$jobs/slots" || exit 1
# slots_put <n>: puts n tokens in the pool
slots_put() { local i; for ((i = 0; i < $1; i++)); do printf x >&3; done; }
nslots=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)
slots_put "$nslots"
case_timeout=${LINT_CASE_TIMEOUT:-120}
# a slot frees within a case timeout of being taken, plus the case's setup and judging, which
# the 30 seconds over it leave room for; a longer wait means a case hung outside its lint run
# or a token is lost
slot_timeout=$((case_timeout + 30))
case_desc=()   # each case's description by number, for a stall to name the cases holding a slot
# bounded <seconds> <command...>: runs the command in its own process group and kills the group
# after <seconds>, exiting 124 then, or else with the command's own exit code; an INT or TERM
# to it kills the group too, since the group is out of reach of the terminal's signals
bounded() {
  perl -e 'my $t = shift; my $pid = fork; defined $pid or exit 126;
    if (!$pid) { setpgrp(0, 0); exec @ARGV or exit 127 }
    setpgrp($pid, $pid); $SIG{ALRM} = sub { kill "KILL", -$pid; exit 124 }; alarm $t;
    $SIG{$_} = sub { kill "KILL", -$pid; exit 130 } for qw(INT TERM);
    waitpid $pid, 0; exit($? & 127 ? 128 + ($? & 127) : $? >> 8)' "$@"
}

# the stand-in for the installed plugin: every name the tree's /commands resolve to, and the
# ones the cases below name; listed once, since every fresh copy holds the same tree
plugin_names=$(grep -rhoE 'mattpocock-skills:[a-z-]+' "$repo_root/skills" "$repo_root/docs" "$repo_root/CLAUDE.md" "$repo_root/GLOSSARY.md" \
  | cut -d: -f2; printf '%s\n' tdd)
# the pristine tree, built once: every fresh copy is one cp of it
pristine=$jobs/pristine
mkdir "$pristine"
cp -R "$repo_root/skills" "$repo_root/docs" "$repo_root/CLAUDE.md" "$repo_root/GLOSSARY.md" "$pristine/"
cp -R "$fixtures/skills/sample" "$pristine/skills/"
cp "$fixtures/agents/sample.md" "$pristine/docs/agents/"
(cd "$pristine" && sort -u <<<"$plugin_names" | sed 's|^|plugin/|' | xargs mkdir -p)
# tree_listing <tree>: every entry under <tree>, a dir as "D <path>", a file as its cksum line
# ("<crc> <size> <path>"), anything else as "O <path>"
tree_listing() {
  find "$1" \( -type d -exec printf 'D %s\n' {} + \) -o \( -type f -exec cksum {} + \) -o -exec printf 'O %s\n' {} +
}
# the pristine tree's listing: a case lints with LINT_UNCHANGED naming what still matches it,
# so the lint skips those files' checks, which the baseline case (run in full) shows pass, and
# a case pays only for what it seeded
tree_listing "$pristine" > "$jobs/pristine.list"
# unchanged_files <tree>: the files under <tree> whose size and checksum match the pristine
# copy's, then as "<path>/" the dirs whose layout does: the same paths under it, each of the
# same kind (a file's content aside)
unchanged_files() {
  tree_listing "$1" | awk -v pre="$pristine/" -v dir="$1/" '
    # sets K, the entry kind ("D", "O", or "F <crc> <size>"), and P, its path
    function parse(line) {
      K = substr(line, 1, 2)
      if (K == "D " || K == "O ") { K = substr(K, 1, 1); P = substr(line, 3); return }
      split(line, w, " "); K = "F " w[1] " " w[2]; P = line; sub(/^[^ ]+ [^ ]+ /, "", P)
    }
    # marks every dir above <r> as laid out anew
    function off(r) { while (sub(/\/[^\/]*$/, "", r)) moved[r] = 1 }
    NR == FNR { parse($0); r = substr(P, length(pre) + 1); if (r != "") ref[r] = K; next }
    { parse($0); r = substr(P, length(dir) + 1); if (r != "") got[r] = K }
    END {
      for (r in ref) if (substr(got[r], 1, 1) != substr(ref[r], 1, 1)) off(r)
      for (r in got) {
        if (substr(got[r], 1, 1) != substr(ref[r], 1, 1)) { off(r); moved[r] = 1 }
        else if (got[r] == ref[r] && got[r] ~ /^F/) print dir r
      }
      for (r in got) if (got[r] == "D" && !(r in moved)) print dir r "/"
    }' "$jobs/pristine.list" -
}
# the scratch dir's top-level entries in $entries, dotfiles included and .jobs left out, with
# no process: the sweep below and expect's move both start from it, so a dotfile a case writes
# at the top level moves with the tree and never leaks into a later case
scratch_entries() {
  local e
  entries=()
  for e in "$scratch"/* "$scratch"/.[!.]* "$scratch"/..?*; do
    { [ -e "$e" ] || [ -L "$e" ]; } && [ "$e" != "$jobs" ] || continue
    entries+=("$e")
  done
}
# fresh copy of the tree, so each case edits only its own file; empties the dir (but .jobs)
# rather than recreating it (see fx_scratch_dir). After an expect the dir is already empty
# (expect moved the tree away), so the sweep runs only when a case left something behind
handed=0   # 1 once expect has taken the current tree; fresh resets it
fresh() {
  scratch_entries
  [ "${#entries[@]}" -eq 0 ] || find "$scratch" -mindepth 1 -maxdepth 1 ! -name .jobs -exec rm -rf {} +
  cp -R "$pristine/." "$scratch/"
  handed=0
}
# run the lint against the scratch copy, sealed to it; prints its output, then the exit code on
# a last line. Extra arguments replace the lint's own ($1 implement-spec skill, $2 runbook).
lint_scratch() {
  local out rc cmd
  [ $# -gt 0 ] || set -- "" "$scratch/docs/WORKFLOW.md"
  # diff_base is the lint's VERSION_BUMP_BASE: HEAD by default (an empty diff), a ref to diff
  # against, or the word "derive", which leaves it unset so the lint derives the merge-base
  if [ "${diff_base:-HEAD}" = derive ]; then unset VERSION_BUMP_BASE
  else export VERSION_BUMP_BASE=${diff_base:-HEAD}; fi
  # a seeded hang swaps in a lint that never returns
  cmd=("$lint")
  [ "${LINT_TEST_SEED:-}" != "hang:$njobs" ] || cmd=(/bin/sh -c 'sleep 86400' sh)
  out=$(SKILLS_DIR=${skills_dir:-$scratch/skills} AGENT_DOCS=${agent_docs:-$scratch/docs/agents} DOCS_DIR=$scratch/docs \
    USER_CLAUDE_MD=${claude_md:-$scratch/CLAUDE.md} GLOSSARY_MD=${glossary_md:-$scratch/GLOSSARY.md} \
    LINT_PINS_DIR=${pins_dir:-$repo_root/scripts} PLUGIN_SKILLS=$scratch/plugin VERSION_BUMP_REPO=${bump_repo_dir:-$scratch/no-repo} \
    LINT_UNCHANGED=${unchanged_list:-} bounded "$case_timeout" "${cmd[@]}" "$@" 2>&1)
  rc=$?
  [ "$rc" != 124 ] || out+="${out:+$nl}FAIL the lint run timed out after ${case_timeout}s"
  printf '%s\n%s\n' "$out" "$rc"
}
# the lines of messages $2 that output $1 lacks, "; "-joined, in $missing, with no process
missing_lines() { # <output> <messages, one per line>
  local m
  missing=
  while IFS= read -r m; do [ -z "$m" ] || [[ $1 == *"$m"* ]] || missing+="${missing:+; }$m"; done <<<"$2"
}
# true when the lint output $3 (last line: exit code) ends in exit code $1 and contains every
# line of $2
result_is() { # <exit code> <messages, one per line> <output>
  [ "${3##*$'\n'}" = "$1" ] || return 1
  missing_lines "$3" "$2"
  [ -z "$missing" ]
}
# the sections with a FAIL line in lint output $1 (stdin), space-separated, ascending
failed_sections() {
  awk '/^== [0-9]+\. /{s=$2; sub(/\.$/, "", s)} /^FAIL/{print s}' | sort -un | tr '\n' ' ' | sed 's/ $//'
}
# judge <description> <exit code> <message> <lint output>: one ok or FAIL line, the lint's own
# FAIL lines indented under a FAIL. With $sec set, a failing case must fail in exactly the
# sections it names ("6 10"), or in exactly one section when it says "one".
judge() {
  local why= got missing
  if ! result_is "$2" "$3" "$4"; then
    missing_lines "$4" "$3"
    why="exit ${4##*$'\n'}, want $2${missing:+, missing: $missing}"
  fi
  if [ -z "$why" ] && [ "$2" = 1 ] && [ -n "${sec:-}" ]; then
    got=$(failed_sections <<<"$4")
    if [ "$sec" = one ]; then [ "$(wc -w <<<"$got")" -eq 1 ]; else [ "$got" = "$sec" ]; fi \
      || why="failed sections: ${got:-none}, want ${sec}"
  fi
  if [ -z "$why" ]; then echo "ok   $1"; return; fi
  echo "FAIL $1 ($why)"
  grep '^FAIL' <<<"$4" | head -5 | sed 's/^/       /'
}
# a wait for a slot outlasted $slot_timeout: print what has finished, then a FAIL naming each case
# still holding a slot (one with no .freed marker), and end the run red
pool_stall() { # <what was waiting>
  local i held=
  expect_flush
  for ((i = 1; i <= njobs; i++)); do [ -e "$jobs/$i.freed" ] || held+="$nl       case $i: ${case_desc[i]}"; done
  echo "FAIL $1: no slot came free in ${slot_timeout}s; holding a slot:${held:- no case, so a token was lost}"
  kill $(jobs -p) 2>/dev/null   # each case's lint group, a grandchild, ends at its own bound
  exit 1
}
# print the finished cases' lines in order, as far as they have finished, counting their FAILs;
# with "all", wait for every case first: take back every slot within one $slot_timeout, then
# put them back
expect_flush() {
  local i deadline=$((SECONDS + slot_timeout))
  if [ "${1:-}" = all ]; then
    for ((i = 0; i < nslots; i++)); do
      read -t "$(( deadline > SECONDS ? deadline - SECONDS : 1 ))" -r -n 1 -u 3 _ || pool_stall "the wait for every case"
    done
    slots_put "$nslots"
    wait
  fi
  while [ "$shown" -lt "$njobs" ]; do
    if [ ! -f "$jobs/$((shown+1)).out" ]; then
      [ "${1:-}" = all ] || return 0
      # a case whose run died before judging it printed no verdict: that is a failure too
      echo "FAIL case $((shown+1)) printed no verdict" > "$jobs/$((shown+1)).out"
    fi
    shown=$((shown+1))
    # builtins only: this loop runs in the parent after every case
    verdict=
    IFS= read -r -d '' verdict < "$jobs/$shown.out" || true
    printf '%s' "$verdict"
    case "$nl$verdict" in *"$nl"FAIL*) fails=$((fails+1));; esac
  done
}
# expect <description> <expected exit code> [messages the output must contain, one per line] [lint args...]
# Moves the scratch tree into the case's own dir and lints it there in the background, every
# $scratch path in the message, the arguments and the override variables rewritten to it. A case
# with a throwaway repo (bump_repo_dir) runs in the foreground on the scratch copy itself.
expect() {
  local d=$1 want=$2 msg=${3:-} dir a v args
  args=()
  shift 3 2>/dev/null || shift $#
  if [ -n "${bump_repo_dir:-}" ]; then
    expect_flush all
    njobs=$((njobs+1)) case_desc[njobs]=$d
    : > "$jobs/$njobs.freed"   # it runs here and takes no slot
    judge "$d" "$want" "$msg" "$(lint_scratch "$@")" > "$jobs/$njobs.out"
    expect_flush all
    return
  fi
  njobs=$((njobs+1)) dir=$jobs/$njobs case_desc[njobs]=$d
  # fresh builds a tree for one expect: a second one on it would lint an empty dir
  if [ "$handed" = 1 ]; then
    echo "FAIL $d (no fresh since the previous expect)" > "$dir.out"
    : > "$dir.freed"
    expect_flush
    return
  fi
  handed=1
  mkdir "$dir"
  scratch_entries
  mv ${entries[@]+"${entries[@]}"} "$dir/"   # the tree moves, nothing is copied
  for a in "$@"; do a=${a//"$scratch"/"$dir"}; args+=("$a"); done
  read -t "$slot_timeout" -r -n 1 -u 3 _ || pool_stall "case $njobs ($d)"   # wait for a free slot
  (
    # the token goes back however the case ends (a seeded drop keeps it), then the .freed marker
    # says so; a case that died before its verdict gets one
    trap '[ -e "$dir.out" ] || echo "FAIL $d (its run died before judging it)" > "$dir.out"
      [ "${LINT_TEST_SEED:-}" = "drop:$njobs" ] || { printf x >&3; : > "$dir.freed"; }' EXIT
    for v in skills_dir agent_docs claude_md glossary_md pins_dir; do
      [ -z "${!v:-}" ] || eval "$v=\${$v//\"\$scratch\"/\"\$dir\"}"
    done
    msg=${msg//"$scratch"/"$dir"} scratch=$dir
    # with $full set the case lints every file, as the baseline must
    # the list vouches for a file only in the role the baseline linted it in, so every path the
    # case hands the lint (an argument or an override) leaves it, with everything under it,
    # unless it names the very path that role defaults to
    if [ -z "${full:-}" ]; then
      a1=${args[0]:-} a2=${args[1]:-}
      [ "$a1" != "$dir/skills/implement-spec/SKILL.md" ] || a1=
      [ "$a2" != "$dir/docs/WORKFLOW.md" ] || a2=
      printf '%s\n' "$a1" "$a2" "${skills_dir:-}" "${agent_docs:-}" "${claude_md:-}" "${glossary_md:-}" > "$dir.roles"
      unchanged_files "$dir" | awk 'NR == FNR { if ($0 != "") role[$0]; next }
        { for (r in role) if ($0 == r || $0 == r "/" || index($0, r "/") == 1) next; print }' \
        "$dir.roles" - > "$dir.same"
      unchanged_list=$dir.same
    fi
    judge "$d" "$want" "$msg" "$(lint_scratch ${args[@]+"${args[@]}"})" > "$dir.part" 2>&1
    rm -rf "${dir:?}" "${dir:?}.same" "${dir:?}.roles"   # the case's tree goes here, off the parent's path
    # the .out appears whole or not at all, so expect_flush never prints half a verdict
    mv "$dir.part" "$dir.out"
  ) &
  expect_flush
}

fresh
full=1 expect "baseline copy passes" 0

fresh
expect "an explicit implement-spec path that does not exist fails" 1 "missing document: $scratch/nope.md" "$scratch/nope.md" "$scratch/docs/WORKFLOW.md"

fresh
expect "an explicit runbook path that does not exist fails" 1 "missing document: $scratch/nope.md" "" "$scratch/nope.md"

# an unchanged doc handed in another doc's role is linted in that role, never skipped as unchanged
fresh
sec=1 expect "an unchanged skill passed as the implement-spec skill fails section 1" 1 "" "$scratch/skills/workflow/SKILL.md"

for var in skills_dir agent_docs claude_md glossary_md pins_dir; do
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
echo "the rules doc's Story plumbing" >> "$scratch/docs/agents/sample.md"
expect "the old Story plumbing section name in an agent doc fails" 1 "retired phrase in $scratch/docs/agents/sample.md"

fresh
echo "the rules doc's story plumbing" >> "$scratch/docs/agents/sample.md"
expect "the old section name in lowercase in an agent doc fails" 1 "retired phrase in $scratch/docs/agents/sample.md"

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
  echo "run /story-to-tasks next" >> "$scratch/$target"
  expect "a bare /<skill> in $target fails with the namespace message" 1 "$ns_msg in $scratch/$target"
  fresh
  echo "run /other:story-to-tasks next" >> "$scratch/$target"
  expect "another namespace in $target fails with the namespace message" 1 "$ns_msg in $scratch/$target"
  fresh
  printf 'run dev:story-to-tasks, then mattpocock-skills:code-review\nor /mattpocock-skills:tdd and /dev:workflow\n' >> "$scratch/$target"
  expect "namespaced references in $target pass" 0
done
# the loop above seeds /story-to-tasks; the acceptance criterion (dev-9np) names /implement-spec
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
echo "run /story-to-tasks" >> "$scratch/docs/adr/0001.md"
expect "a bare /<skill> under docs/ outside docs/agents fails" 1 "$ns_msg in $scratch/docs/adr/0001.md"
fresh
echo "run dev:story-to-tasks and /dev:workflow" >> "$scratch/docs/adr/0001.md"
expect "namespaced references under docs/adr pass" 0

fresh
echo "run /story-to-tasks" > "$scratch/driver.md"
expect "an implement-spec skill passed as \$1 outside the skills dir gets the namespace check" 1 "$ns_msg in $scratch/driver.md" "$scratch/driver.md" "$scratch/docs/WORKFLOW.md"

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
printf 'cd /opt and /story-to-tasks\n' > "$scratch/docs/helper.sh"
expect "a non-md file under docs is not scanned" 0
fresh
printf 'cd /opt and /story-to-tasks\n' > "$scratch/skills/sample/helper.sh"
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
# a skills or plugin dir laid out anew drops out of LINT_UNCHANGED, so the namespace rule rereads
# the docs it lists, which name the skill byte for byte as before
fresh
mv "$scratch/skills/close-story" "$scratch/skills/close-story-old"
expect "a renamed shipped skill fails the unchanged docs naming it" 1 "/dev:close-story names no skill"
fresh
rmdir "$scratch/plugin/grill-with-docs"
expect "a dropped plugin skill fails the unchanged docs naming it" 1 "/mattpocock-skills:grill-with-docs names no skill"

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
  [ -n "$2" ] || { echo "FAIL drop_phrase: an empty phrase for $1 would drop nothing"; exit 1; }
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
section_case 2 docs/WORKFLOW.md 'each cross-repo task gets its own PR' "a runbook with stale wording"
section_case 3 skills/spec-to-stories/SKILL.md 'then re-sync the stories' "/spec-to-stories with a re-sync"
section_case 4 skills/spec-to-tasks/SKILL.md 'then rerun this skill for the dependent' "/spec-to-tasks with the retired rerun hint"
section_case 5 skills/sample/SKILL.md 'cut one' "a retired phrase in a skill"
section_case 6 docs/agents/orchestration.md 'push when the active profile permits' "an orchestration doc gating the push on the profile"
section_case 7 skills/story-to-tasks/SKILL.md 'read the notes under .spec-notes' "/story-to-tasks reading an owner-repo notes file"
section_case 8 skills/implement-story/SKILL.md "the rule's three entries" "/implement-story counting three Gitignore entries"
section_case 9 skills/close-story/SKILL.md 'query `tea api repos/x/y/pulls/1`' "/close-story with a Forgejo query naming no repo"
section_case 10 docs/agents/issue-tracker.md 'the only lines the story cut writes' "a tracker doc whose story cut writes two forms only"
section_case 11 skills/sample/SKILL.md 'run /story-to-tasks next' "a bare /<skill>"
section_case 12 skills/retro/SKILL.md 'grep the whole slug directory' "/retro with the bare grep instruction"
section_case 13 skills/sample/SKILL.md '> read ${CLAUDE_PLUGIN_ROOT}/docs/agents/orchestration.md' "the plugin-root variable in a brief"
section_case 16 skills/task-orchestrator/SKILL.md 'then merge it with `git -C <owner> merge <task branch>`' "/task-orchestrator merging onto the owner checkout"
section_case 17 skills/implement-task/SKILL.md 'then run `gh pr create --draft`' "/implement-task opening a draft PR"
section_case 5 skills/sample/SKILL.md 'run it with the sandbox disabled, as `/dev:close-story` step 4 does' "a skill citing another skill's step number"
section_case 5 skills/sample/SKILL.md 'run it as `/dev:close-story`
step 4 does' "a citation wrapped across a line break"
# a skill citing its own step when its name is a prefix of another skill's (setup, setup-repo)
fresh
printf '%s\n' 'Run `/dev:setup-repo` step 2 again.' >> "$scratch/skills/setup-repo/SKILL.md"
sec=5 expect "setup-repo citing its own step passes section 5" 0
section_case 5 skills/setup-repo/SKILL.md 'as `/dev:setup` step 2 does' "setup-repo citing /dev:setup's step"
step_msg="another skill's step number cited in $scratch/skills/sample/SKILL.md"
fresh
printf '%s\n' 'run it as `/dev:close-story` Step 4 does' >> "$scratch/skills/sample/SKILL.md"
sec=5 expect "a capitalised Step fails section 5 with its message" 1 "$step_msg"
fresh
printf '%s\n' 'run it as `/dev:close-story` step' '4 does' >> "$scratch/skills/sample/SKILL.md"
sec=5 expect "a step number on the next line fails section 5 with its message" 1 "$step_msg"
fresh
printf '%s\n' 'run it as `/dev:close-story` step' '4. Do it' >> "$scratch/skills/sample/SKILL.md"
sec=5 expect "a step wrapped onto a list-item line passes section 5 (documented limit)" 0
# section 1: the Merge guard carve-out is exactly the phrase, case and spelling included
fresh
printf '%s\n' "the rules doc's Repo plumbing and Cut-off probe, its Merge guard, then merge it" >> "$scratch/skills/implement-spec/SKILL.md"
sec=1 expect "the carve-out phrase beside a real merge step fails section 1" 1 "present: merge steps"
fresh
printf '%s\n' "the rules doc's plumbing and cut-off probe merge guard" >> "$scratch/skills/implement-spec/SKILL.md"
sec=1 expect "a lowercase variant of the carve-out fails section 1" 1 "present: merge steps"
fresh
printf '%s\n' "the rules doc's Repo plumbing and Cut-off probe merge-guard" >> "$scratch/skills/implement-spec/SKILL.md"
sec=1 expect "a hyphenated variant of the carve-out fails section 1" 1 "present: merge steps"
# a skill's own steps and another skill named without a step number are outside the rule
fresh
printf '%s\n' 'Read `/dev:close-story` for the merge guard, then go on to step 4.' \
  'This skill has steps 1 to 4, and /dev:sample step 2 is its own.' >> "$scratch/skills/sample/SKILL.md"
sec=5 expect "own steps and a step-free skill name pass section 5" 0
# a rules doc is swept too: a skill's step number cited there fails (dev-90up)
fresh
printf '%s\n' 'the forge query, as `/dev:close-story` step 4 does' >> "$scratch/docs/agents/sample.md"
sec=5 expect "a rules doc citing a skill's step number fails section 5 with its message" 1 "another skill's step number cited in $scratch/docs/agents/sample.md"

# a section's document gone: the section fails naming it, never skips; a rules doc that two
# sections read fails both
for case in '1 skills/implement-spec/SKILL.md' '2 skills/workflow/SKILL.md' '2 docs/WORKFLOW.md' \
  '3 skills/spec-to-stories/SKILL.md' '4 skills/spec-to-tasks/SKILL.md' '6 10 docs/agents/orchestration.md' \
  '6 docs/agents/harness.md' '6 10 docs/agents/issue-tracker.md' '6 skills/setup-repo/SKILL.md' '7 skills/story-to-tasks/SKILL.md' '8 skills/implement-story/SKILL.md' \
  '9 skills/close-story/SKILL.md' '6 skills/triage/SKILL.md' '12 skills/retro/SKILL.md' '16 skills/task-orchestrator/SKILL.md' '17 skills/implement-task/SKILL.md' '18 docs/agents/coding-standards.md' '0 CLAUDE.md' '0 GLOSSARY.md'; do
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

# --- hand-written cases of absent phrases and rules; the drop case of each pinned phrase is derived below ---
sec=one

fresh
echo "next: /dev:spec-to-tikets <KEY>-<n>" >> "$scratch/skills/workflow/SKILL.md"
expect "misspelt command in /dev:workflow fails" 1

fresh
echo "push when the active profile permits" >> "$scratch/docs/agents/orchestration.md"
expect "profile-gated push in the orchestration doc fails" 1

fresh
echo "otherwise ask the user to run that exact command and wait for it" >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story asking the user to push fails" 1

fresh
echo 'git -C <owner> commit -m "chore: x" --trailer "Bead: <story-id>"' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story committing with --trailer fails" 1

fresh
echo 'a commit never takes `--trailer`; the message file carries the trailers' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story naming --trailer in prose passes" 0

fresh
echo 'then `git -C <owner> commit -m "chore: ignore spec notes"`' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories committing in an owner repo fails" 1

fresh
echo 'With no argument, list the open epic beads in `<home>` and ask which is this feature'"'"'s' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories recovering the epic from the open epic list fails" 1

fresh
echo 'With none, take the one on the next: line /dev:spec-to-stories ended on in the conversation' >> "$scratch/skills/spec-to-tasks/SKILL.md"
expect "spec-to-tasks recovering the epic from the conversation fails" 1

fresh
echo 'each task orchestrator lands the task itself' >> "$scratch/docs/WORKFLOW.md"
sec=2 expect "a runbook task orchestrator landing its task fails" 1 "a task orchestrator landing its own task in the runbook"

fresh
echo 'at the task (`medium` and `high` only) on both axes' >> "$scratch/docs/WORKFLOW.md"
expect "runbook copy limiting the task review to medium and high fails" 1 "the runbook's task review limited to medium and high"

fresh
echo 'Then the task gate (switch `/model` to the tier'"'"'s review model) runs.' >> "$scratch/docs/WORKFLOW.md"
expect "runbook copy with the seeded phrase task gate fails" 1 "retired task gate name in the runbook"

fresh
echo '`medium` and `high` tasks pass the check gate before merge.' >> "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc limiting the check gate to medium and high fails" 1 "medium and high tasks passing the check gate"

fresh
echo 'read `<owner>/.spec-notes/<epic-id>/story-cut.md` first' >> "$scratch/skills/spec-to-tasks/SKILL.md"
sec="4 5" expect "story-cut.md in a skill fails" 1

fresh
echo 'the notes are in `story-cut.md`' >> "$scratch/docs/agents/orchestration.md"
expect "story-cut.md in an agent doc fails" 1

fresh
echo 'and `story-cut.md` notes' >> "$scratch/docs/WORKFLOW.md"
expect "story-cut.md in the runbook copy fails" 1

fresh
echo 'The story cut commits `/.spec-notes/` ahead of this' >> "$scratch/docs/agents/orchestration.md"
expect "orchestration doc handing the gitignore line to the story cut fails" 1

fresh
echo 'with the `/.spec-notes/` line the story cut appended but could not commit' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story taking a gitignore hand-off from the story cut fails" 1

# one has-a-database rule: .beads/ exists and bd where names it, stated once in the tracker doc
# and cited by every gate; a gate testing only that .beads/ exists fails the sweep (dev-e87)
fresh
printf '%s\n' 'Before any `bd` call, check `test -d <home>/.beads`.' >> "$scratch/skills/close-epic/SKILL.md"
sec=5 expect "a gate testing only that .beads exists fails" 1 "present: an existence-only beads database gate in $scratch/skills/close-epic/SKILL.md"

fresh
printf '%s\n' '   owner other than `<home>` with no `.beads/` → say so.' 'No `<home>/.beads` → say so' >> "$scratch/skills/triage/SKILL.md"
sec=5 expect "a gate worded as a missing .beads fails" 1 "present: an existence-only beads database gate in $scratch/skills/triage/SKILL.md"

fresh
printf '%s\n' 'in every manifest repo with `.beads/` (the same guard)' >> "$scratch/docs/agents/issue-tracker.md"
sec=5 expect "a sweep guarded on .beads alone fails" 1 "present: an existence-only beads database gate in $scratch/docs/agents/issue-tracker.md"

fresh
echo '     from the repo'"'"'s top level, never through `-C` or `BEADS_DIR`' >> "$scratch/skills/setup-repo/SKILL.md"
expect "setup-repo restating the init rule fails" 1 "present: setup-repo restating the init rule"

fresh
echo '`bd init` cannot take `-C`, so give the user the command.' >> "$scratch/skills/sample/SKILL.md"
expect "a skill saying bd init cannot take -C fails" 1 "the retired bd init -C wording"

for phrase in 'in at most two dependency waves' 'in at most two waves' 'two dependency waves suffice' \
  'two waves suffice' '(two suffice)' \
  'chains are out of scope' 'then rerun this skill for the dependent' \
  '(/dev:spec-to-stories would refuse too, since stories exist)'; do
  fresh
  echo "x $phrase y" >> "$scratch/skills/spec-to-tasks/SKILL.md"
  # two of them are section 5's retired story-DAG wording, which section 4 does not repeat
  case $phrase in "two waves suffice"|"chains are out of scope") s=5 ;; *) s=4 ;; esac
  sec=$s expect "spec-to-tasks saying '$phrase' fails" 1
done
# the ban is on the cap, not on the words: two waves named without a cap pass, and so does
# "at most two" about anything but waves
for phrase in 'a chain of two waves' 'at most two tasks'; do
  fresh
  echo "x $phrase y" >> "$scratch/skills/spec-to-tasks/SKILL.md"
  expect "spec-to-tasks saying '$phrase' passes" 0
done

fresh
echo 'switch -c feat/<key>-<n> main' >> "$scratch/skills/implement-story/SKILL.md"
sec=5 expect "implement-story with the keyed branch form fails" 1

fresh
echo 'each sibling appears as `<repo> <url>`' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story with the url-only sibling line fails" 1

# a literal <owner>/.git/ path does not exist where .git is a file (dev-cjf)
fresh
echo 'read `<owner>/.git/HEAD` for the branch' >> "$scratch/skills/implement-story/SKILL.md"
sec=8 expect "implement-story naming a literal <owner>/.git/HEAD fails" 1

fresh
echo 'the sandbox denies deletes under `<owner>/.git/worktrees/`' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story naming a literal <owner>/.git/worktrees/ fails" 1

fresh
echo 'an `until` loop over `<owner>/.git/HEAD`' >> "$scratch/docs/agents/harness.md"
sec=6 expect "harness doc naming a literal <owner>/.git/HEAD fails" 1

# the story row lands serially with no lock, so the task orchestrator's lock wait and its
# index.lock probe are swept from every doc a reader meets, each seeded back alone failing
# section 5 (dev-b8d.1.4)
for case in 'skills/implement-story/SKILL.md|Take the owner checkout under the lock, one landing at a time.' \
  'skills/task-orchestrator/SKILL.md|Wait on `index.lock` before you report.' \
  'docs/agents/harness.md|The task orchestrator'"'"'s lock wait is a shell wait too.' \
  'docs/agents/orchestration.md|The task orchestrator merges under the lock.' \
  'docs/SEQUENCES.md|O waits on index.lock.'; do
  fresh
  printf '\n%s\n' "${case#*|}" >> "$scratch/${case%%|*}"
  sec=5 expect "${case%%|*} regaining the lock wait ('${case#*|}') fails" 1 "the retired lock wait in $scratch/${case%%|*}"
done

for phrase in 'waits 10 seconds and checks again' 'waits 15 seconds and retries' 'sleeps, then re-checks the lock' 'checks every 10 seconds'; do
  fresh
  echo "so it $phrase, for up to 5 minutes" >> "$scratch/skills/implement-story/SKILL.md"
  expect "implement-story whose lock wait '$phrase' by hand fails" 1
done

fresh
echo 'If either fails with `Operation not permitted`, retry that one command with the sandbox disabled.' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story retrying the worktree removal sandbox-disabled only after the denial fails" 1

fresh
echo '9. **Clean up** every worktree the run made.' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story sweeping only this run's worktrees fails" 1

fresh
echo 'a locked one is removed with `git -C <owner> worktree remove <absolute path> --force`' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story forcing a locked worktree fails" 1

fresh
echo 'a locked one is removed with `git -C <owner> worktree remove -f -f <absolute path>`' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story forcing a locked worktree with -f fails" 1

fresh
echo 'A nested owner that holds none is swept like any merged entry.' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story sweeping a childless nested owner fails" 1

fresh
echo 'then `git -C <owner> clean -f` removes the stray files' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story cleaning the stray files fails" 1 "present: step 9 deleting a stray file"

# a second copy of what moved, seeded back into a skill, fails
for case in '^(8\. .*)$|\1 Then wait: `gh pr checks <n> --repo <forge-slug> --watch`.|present: a second copy of the forge-check wait in step 8' \
  '^(8\. .*)$|\1 Read `git -C <owner> log --no-merges --format=%H`.|present: a second copy of the stray-commit check in step 8'; do
  anchor=${case%%|*} rest=${case#*|}
  fresh
  swap_phrase skills/implement-story/SKILL.md "$anchor" "${rest%%|*}"
  expect "implement-story regaining '${rest%%|*}' fails" 1 "${rest#*|}"
done
fresh
swap_phrase skills/task-orchestrator/SKILL.md '^(3\. .*)$' '\1 Run `make check > <owner>/.tmp/checks/<tree>/log 2>\&1`.'
sec=16 expect "task-orchestrator regaining a copy of the check-record call fails" 1 "present: a second copy of the check-record call in the skill"

# the paragraph is the Delivery authority and the section is the Delivery section: a paragraph
# named like the section is two rules under one name (dev-b8d.1.3 review 1)
fresh
echo '**Delivery.** The paragraph under the section'"'"'s name.' >> "$scratch/docs/agents/orchestration.md"
expect "the rules doc with a paragraph named like the Delivery section fails" 1 "present: a paragraph named like the Delivery section"

fresh
echo 'Step 8 writes it: see `/dev:implement-story` step 8.' >> "$scratch/skills/implement-spec/SKILL.md"
sec=5 expect "implement-spec pointing at /dev:implement-story step 8 fails" 1 "another skill's step number cited in"

fresh
echo 'Evidence is recorded by `/dev:implement-story` step 7.' >> "$scratch/skills/implement-spec/SKILL.md"
sec=5 expect "implement-spec pointing at /dev:implement-story step 7 fails" 1 "another skill's step number cited in"

fresh
echo 'The wait is `/dev:implement-story` step 8.' >> "$scratch/docs/agents/harness.md"
sec=5 expect "harness doc pointing at /dev:implement-story step 8 fails" 1 "another skill's step number cited in"

fresh
swap_phrase skills/implement-story/SKILL.md "^(   With a forge, open a .*)$" "\\1 Run step 8's **stray-commit check**."
expect "implement-story step 3 pointing at step 8's stray-commit check fails" 1 "present: step 3 pointing at step 8's stray-commit check"

# the Idle rule's retired second shell wait, seeded back in the harness doc (dev-b8d.1.4)
fresh
printf '\nThere are two shell waits.\n' >> "$scratch/docs/agents/harness.md"
sec=6 expect "harness doc naming two shell waits fails" 1 "present: the Idle rule's second shell wait"

fresh
echo 'The `human:` and `resume:` lines appear only when they have content.' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story printing the resume: line only with content fails" 1 "present: the resume: line printed only with content"

fresh
swap_phrase docs/agents/harness.md 'heredoc' 'here-document'
printf '\nA heredoc elsewhere in the doc.\n' >> "$scratch/docs/agents/harness.md"
expect "harness doc whose TMPDIR rule names no heredoc fails" 1

section_case 6 docs/agents/orchestration.md 'At the epic row it is `failed: <story-id> checks failed after three fix-ups`' "a Check gate allowing a third epic-row fourth-failure line"

fresh
swap_phrase docs/agents/orchestration.md '`/.worktrees/`, `/.spec-notes/` and `/.tmp/`' '`/.tmp/`, `/.worktrees/` and `/.spec-notes/`'
expect "orchestration doc listing /.tmp/ first among the Gitignore entries passes" 0

fresh
printf 'on the harness route the implementer fills in the path `pwd` prints\n' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story with the retired fill-in-the-pwd-path wording fails" 1 \
  "present: the retired fill-in-the-pwd-path wording"

fresh
echo "its commit holds one of the rule's three entries" >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story whose Gitignore step counts three entries fails" 1

# there is no foreground spawn: an Agent call returns at once, a nested orchestrator ends its
# turn and is resumed by the child's completion notification, and every subagent below the
# the epic orchestrator runs Bash in the foreground only; no skill says run_in_background: false (chezmoi-p4q)
for skill in implement-spec implement-story spec-to-tasks retro; do
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

fresh
awk '{ print } /^Bead: <task-id>$/ { print "" }' "$scratch/docs/agents/harness.md" > "$scratch/docs/agents/harness.md.new" && mv "$scratch/docs/agents/harness.md.new" "$scratch/docs/agents/harness.md"
expect "harness doc whose commit example has a blank line among its trailers fails" 1 "no blank line between the commit example's trailers"

fresh
mv "$scratch/docs/agents/harness.md" "$scratch/docs/agents/harness-gone.md"
expect "a missing harness doc fails naming it" 1 "missing document: $scratch/docs/agents/harness.md"

fresh
echo 'spawn each child with `run_in_background: false`' >> "$scratch/docs/agents/harness.md"
expect "run_in_background: false seeded in the harness doc fails" 1

fresh
echo 'a nested orchestrator (one that is itself a subagent) spawns in the foreground' >> "$scratch/docs/agents/harness.md"
expect "harness doc regaining the nested foreground spawn fails" 1

fresh
echo '- it is not labelled `ready-for-human`, which is all the orchestrator checks' >> "$scratch/docs/agents/orchestration.md"
expect "orchestration doc keying the frontier on ready-for-human alone fails" 1

fresh
echo 'minus `ready-for-human` tasks only' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story filtering the frontier on ready-for-human alone fails" 1

fresh
echo 'Any child not `closed` → `<id> refused: open tasks <child> <status>, ...`' >> "$scratch/skills/close-story/SKILL.md"
expect "close-story refusing without the label fails" 1

# the tracker and orchestration docs speak of the story DAG and the human gate task, and
# no longer say a feature has one text blocker or that chains are out of scope (ADR 0011)
for doc in issue-tracker orchestration; do
  fresh
  echo "That one line is the feature's only text blocker." >> "$scratch/docs/agents/$doc.md"
  sec=5 expect "$doc doc saying 'only text blocker' fails" 1
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

fresh
echo "it appears in bd ready as soon as its repo's implementation tasks close." >> "$scratch/docs/agents/orchestration.md"
expect "orchestration doc releasing a publish task on its repo's tasks fails" 1

fresh
echo '   <repo> <gate task id>' >> "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc whose story body shows an unfillable gate task line fails" 1

fresh
echo 'Only the home story has a parent: a parent cannot span databases.' >> "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc giving only one home story a parent fails" 1

fresh
echo '   task opens its own wave, created last' >> "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc splitting a middle story across waves fails" 1

# the task cut orders one pass per story, so every bump precedes the dependent's other
# tasks; the story cut writes a story line or a publish placeholder, never a gate task id
fresh
sed 's/one topological pass over the stories/one topological pass/' "$scratch/docs/agents/issue-tracker.md" > "$scratch/docs/agents/issue-tracker.md.new" && mv "$scratch/docs/agents/issue-tracker.md.new" "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc whose task cut pass is not per story fails" 1

fresh
echo '   In the task cut, one topological pass over the edges: per edge,' >> "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc ordering the task cut per edge fails" 1

fresh
echo 'two forms are the only lines the story cut writes.' >> "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc whose story cut writes only two forms fails" 1

fresh
echo 'every open task of the story is blocked natively on every bump' >> "$scratch/docs/agents/issue-tracker.md"
expect "tracker doc whose re-cut blocks a bump on itself fails" 1

fresh
echo 'For each pair of stories, decide which is the dependent' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories detecting dependencies per pair fails" 1

# the stories are listed with the dependent after the dependency, not dependency first
fresh
echo 'Present the stories as a numbered list, dependency first.' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories ordering the stories dependency first fails" 1

fresh
echo 'The dependency first publishes its crate, then the dependent bumps.' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories saying dependency first outside the list order passes" 0

# the epic bead notes no skipped story, a skipped closure is no invented line, and the frontmatter
# keeps its story form
fresh
echo 'Record each skipped story on the epic bead, as that doc'"'"'s step 2 says.' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories noting every skipped story on the epic bead fails" 1

fresh
echo 'description: "resolve a spec to one story per repo it changes"' >> "$scratch/skills/spec-to-stories/SKILL.md"
sec=5 expect "spec-to-stories with one story per repo in its frontmatter fails" 1

fresh
echo 'written `<repo> <story title> (not created: no beads database)`' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories with an invented skipped-closure line fails" 1

fresh
echo 'Also refuse when it already has stories → `<epic-id> refused: stories exist`' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories refusing on existing stories fails" 1

fresh
echo '`tea api repos/{owner}/{repo}/pulls/<n>` on a Forgejo/Gitea host' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories with a tea forge query lacking --repo fails" 1

# a PR closed unmerged is refused as /dev:implement-story's merge guard refuses it (story review 1)
fresh
echo "- A PR closed unmerged is not sealed: it takes \`OPEN\`'s path." >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories re-cutting a story whose PR closed unmerged fails" 1

fresh
echo "the nearest ancestor of <owner> holding repos.yaml" >> "$scratch/skills/spec-to-tasks/SKILL.md"
expect "walk-up phrase in /dev:spec-to-tasks fails" 1

fresh
echo "the workspace root included" >> "$scratch/skills/story-to-tasks/SKILL.md"
expect "walk-up phrase in /dev:story-to-tasks fails" 1

fresh
echo 'Story <story-id> in <owner repo>; home repo <home repo>, epic bead' >> "$scratch/skills/story-to-tasks/SKILL.md"
expect "retired home repo <home repo> Parent form in /dev:story-to-tasks fails" 1

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

# Every positive check of the lint (has, hasc, hase, line_has, line_hase, para_has, sec_has,
# opening_has) and every lacksf, pinned inline in lint-skill-docs.sh or read from a pin table, has one drop case
# here, derived from the lint's own list of its checks (LINT_PIN_LIST), so a phrase is written in
# one place and no case copies it (dev-yqpz). The pristine tree's lint run writes the list, one
# check per line as <type> <file> <description> <phrase> [<anchor>] (the lint's queue line).
# drop_matching <file under scratch> <regex> [<anchor regex>]: delete every line matching the
# regex (and the anchor, when given), for a case whose pin is a pattern, not a phrase
drop_matching() {
  re="$2" an="${3:-}" awk '{ if ($0 ~ ENVIRON["re"] && (ENVIRON["an"] == "" || $0 ~ ENVIRON["an"])) next; print }' \
    "$scratch/$1" > "$scratch/$1.new" && mv "$scratch/$1.new" "$scratch/$1"
}
# prefix_matching <file under scratch> <regex>: put a word ahead of every line matching the regex
prefix_matching() {
  re="$2" awk '{ if ($0 ~ ENVIRON["re"]) $0 = "x " $0; print }' "$scratch/$1" > "$scratch/$1.new" && mv "$scratch/$1.new" "$scratch/$1"
}
# pin_phrase <description>: sets pp to the phrase of the lint's pin of that description, from its list
pin_phrase() {
  pp=$(awk -F '\t' -v d="$1" '$3 == d { print $4; exit }' "$jobs/pins.list")
  [ -n "$pp" ] || { echo "FAIL pin_phrase: the lint has no pin described '$1'"; fails=$((fails+1)); pp=NO-SUCH-PIN; }
}
# move_to_line_end <file under scratch> <anchor regex> <phrase>: on the lines matching the anchor,
# take the phrase out of where it stands and append it to the line's end
move_to_line_end() {
  an="$2" p="$3" awk '{ if ($0 ~ ENVIRON["an"] && (i = index($0, ENVIRON["p"]))) $0 = substr($0, 1, i - 1) substr($0, i + length(ENVIRON["p"])) " " ENVIRON["p"] "." } { print }' \
    "$scratch/$1" > "$scratch/$1.new" && mv "$scratch/$1.new" "$scratch/$1"
}
# drop_pin <type> <file under scratch> <phrase> <anchor>: seeds the doc without the pinned phrase
drop_pin() {
  case $1 in
    i|p) drop_phrase "$2" "$3" -i ;;
    e) drop_matching "$2" "$3" ;;
    A) drop_matching "$2" "$3" "$4" ;;
    *) drop_phrase "$2" "$3" ;;
  esac
}
fresh
export LINT_PIN_LIST=$jobs/pins.list
: > "$LINT_PIN_LIST"
lint_scratch > /dev/null
unset LINT_PIN_LIST
# every kind of check the lint queues is named here: a positive one gets a drop case, a lacksf one
# its phrase seeded, an absent-phrase one (x y w W X) none; a kind named nowhere fails, so a new one
# cannot go without a case
pos_types=" i c e a A p S o "
seed_types=" f "
absent_types=" x y w W X "
moved_types=" a S p o "
npins=0 nmoved=0 nanch=0
while IFS=$'\t' read -r -u 4 ptype pfile pdesc pphrase panchor; do
  case $absent_types in *" $ptype "*) continue ;; esac
  case $pos_types$seed_types in *" $ptype "*) ;;
    *) echo "FAIL pin list: '$pdesc' is a check of kind '$ptype', which this test has no drop case for"; fails=$((fails+1)); continue ;;
  esac
  prel=${pfile#"$scratch"/}
  if [ "$prel" = "$pfile" ] || [ ! -f "$pristine/$prel" ] || [ -z "$pdesc" ] || [ -z "$pphrase" ]; then
    echo "FAIL pin list: '$pdesc' ($pphrase) names no file under the scratch tree: $pfile"
    fails=$((fails+1)); continue
  fi
  npins=$((npins+1))
  if [[ $seed_types == *" $ptype "* ]]; then   # a lacksf: the phrase seeded into the doc fails it
    fresh
    printf '\n%s\n' "$pphrase" >> "$scratch/$prel"
    expect "pin $npins: $prel with '$pdesc' seeded fails" 1 "present: $pdesc ("
    continue
  fi
  fresh
  drop_pin "$ptype" "$prel" "$pphrase" "$panchor"
  expect "pin $npins: $prel without '$pdesc' fails" 1 ": $pdesc ("
  # a pinned phrase moved out of its scope, still fails: ahead of the doc for a section or a
  # paragraph (the last section of a doc runs to its end), to its end for the opening or an
  # anchored line (the anchor's line no longer holds it)
  # a pattern pinned to the start of a line fails once its lines start with another word
  if [ "$ptype" = e ] && [ "${pphrase:0:1}" = '^' ]; then
    nanch=$((nanch+1))
    fresh
    prefix_matching "$prel" "$pphrase"
    expect "pin $npins: $prel with '$pdesc' no longer at the start of its line fails" 1 ": $pdesc ("
  fi
  if [[ $moved_types == *" $ptype "* ]]; then
    nmoved=$((nmoved+1))
    fresh
    drop_phrase "$prel" "$pphrase" $([ "$ptype" = p ] && echo -i)
    if [ "$ptype" = o ] || [ "$ptype" = a ]; then printf '\n%s\n' "$pphrase" >> "$scratch/$prel"
    else { printf '%s\n\n' "$pphrase"; cat "$scratch/$prel"; } > "$scratch/$prel.new" && mv "$scratch/$prel.new" "$scratch/$prel"; fi
    expect "pin $npins: $prel with '$pdesc' moved out of its scope fails" 1 ": $pdesc ("
  fi
done 4< "$jobs/pins.list"
expect_flush all
# the derivation must have found the pins it derives from: the list holds a pin for every row of
# each pin table, so a table whose pins_from call is lost gets no drop case and fails here
guard=1
for table in implement-spec-pins repo-plumbing-pins; do
  read -r found want < <(awk -F '\t' 'NR == FNR { if ($0 !~ /^#/ && NF >= 3) want[$2]; next }
    $3 in want { got[$3] } END { for (k in want) w++; for (k in got) g++; print g + 0, w + 0 }' "$repo_root/scripts/$table.tsv" "$jobs/pins.list")
  if [ "$want" -eq 0 ] || [ "$found" -ne "$want" ]; then
    echo "FAIL pin list holds $found of the $want rows of $table.tsv"; fails=$((fails+1)); guard=0
  fi
done
if [ "$npins" -gt 0 ] && [ "$nmoved" -gt 0 ] && [ "$nanch" -gt 0 ] && [ "$guard" = 1 ]; then
  echo "ok   $npins pin cases derived from the lint's list ($nmoved also moved out of their scope, $nanch also off the start of their line)"
else
  echo "FAIL no pin case was derived from the lint's list ($npins pins, $nmoved moved, $nanch anchored)"; fails=$((fails+1))
fi

# the derived anchored case needs the lint's pattern to open with ^: the one review tool paragraph
# pin, which names no heading, must stay anchored on its line (losing the ^ makes it match mid-line)
pin_phrase "the one review tool paragraph"
fx_check "the one review tool paragraph pin is anchored on its line" test "${pp:0:1}" = '^'

# a pin table row short of a field, or with an unknown check, fails the lint rather than being
# skipped or read as an empty phrase (which every doc holds)
for table in implement-spec-pins repo-plumbing-pins; do
  for case in 'a row of words and no tab|a row needs a check, a description and a phrase' \
    $'has\tno phrase\t|a row needs a check, a description and a phrase' \
    $'hasx\tunknown check\ta phrase|unknown check hasx' \
    $'sec\theading-less sec\ta phrase|sec needs a heading'; do
    row=${case%%|*}
    # a sec row is the repo plumbing table's own kind; the other table has no heading for it
    ! { [ "$table" = repo-plumbing-pins ] && [[ $row == sec* ]]; } || continue
    fresh
    mkdir "$scratch/pins" && cp "$repo_root/scripts/implement-spec-pins.tsv" "$repo_root/scripts/repo-plumbing-pins.tsv" "$scratch/pins/"
    printf '%s\n' "$row" >> "$scratch/pins/$table.tsv"
    pins_dir=$scratch/pins
    expect "$table.tsv with the row '${row//$'\t'/<tab>}' fails" 1 "$table.tsv: ${case#*|}"
    unset pins_dir
  done
done

# section 1 lints the implement-spec file it is handed, so the cases below edit a scratch copy of it
# and hand that copy to expect (chezmoi-9v4.1.6): the human-stop line passing "no merge steps"
# while a merge procedure still fails, and the cases of its lacks checks
spec=$scratch/spec.md
fresh_spec() { fresh; cp "$scratch/skills/implement-spec/SKILL.md" "$spec"; }

fresh_spec
expect "implement-spec with the human-stop merge line passes" 0 "" "$spec" "$scratch/docs/WORKFLOW.md"

# a pin table gone from the pins directory turns its pins off unless the lint fails naming it
for table in implement-spec-pins repo-plumbing-pins; do
  fresh
  mkdir "$scratch/pins" && cp "$repo_root/scripts/implement-spec-pins.tsv" "$repo_root/scripts/repo-plumbing-pins.tsv" "$scratch/pins/"
  rm "$scratch/pins/$table.tsv"
  pins_dir=$scratch/pins
  expect "a pins directory without $table.tsv fails" 1 "missing pin table: $scratch/pins/$table.tsv"
  unset pins_dir
done

fresh_spec
echo "tea pr list --repo <owner> --state open lists it" >> "$spec"
expect "implement-spec listing open PRs with tea pr list fails" 1 "the paginated tea pr list" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "Then open a PR for the story." >> "$spec"
expect "implement-spec opening a PR in prose fails" 1 "PR-opening steps" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "Run tea pulls create for the story." >> "$spec"
expect "implement-spec opening a PR with tea pulls create fails" 1 "PR-opening steps" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "three blocking verdicts are fixed up" >> "$spec"
expect "implement-spec counting only blocking verdicts fails" 1 "a budget of blocking verdicts only" "$spec" "$scratch/docs/WORKFLOW.md"

# the epic row's fourth failure reads only the Check gate's two lines (dev-aeo)
fresh_spec
echo 'report `failed: <story-id> epic gate not clean after three fix-ups`' >> "$spec"
expect "implement-spec with a fourth-failure line the Check gate does not allow fails" 1 "an epic-row fourth-failure line the Check gate does not allow" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo 'report `failed: <story-id> epic review failed after 3 fix-ups`' >> "$spec"
expect "implement-spec with a reworded fix-up count fails" 1 "an epic-row fourth-failure line the Check gate does not allow" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "one with three fix-ups is failed and not reviewed again" >> "$spec"
expect "implement-spec skipping a spent budget fails" 1 "a spent budget skipping the review" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "it enters the set when its orchestrator did not report \`failed:\` this run" >> "$spec"
expect "implement-spec keying the review set on a failed: report fails" 1 "review set keyed on a failed: report this run" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "nothing below touches a task" >> "$spec"
expect "implement-spec claiming it touches no task fails" 1 "nothing touches a task" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "You are the driver, the feature-level session." >> "$spec"
sec=5 expect "implement-spec naming the old epic role fails" 1 "the retired driver role in $spec" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "Run gh pr create --draft for the story." >> "$spec"
expect "implement-spec opening a PR fails" 1 "PR-opening steps" "$spec" "$scratch/docs/WORKFLOW.md"

# the glossary's avoided term "human task" (a ready-for-human task is fine): the gate
# task is a human gate task (story review 1)
fresh_spec
echo "A resumed run starts the stories the closed human task released." >> "$spec"
expect "implement-spec saying 'human task' fails" 1 "" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "every open ready-for-human task is listed" >> "$spec"
expect "implement-spec saying 'ready-for-human task' passes" 0 "" "$spec" "$scratch/docs/WORKFLOW.md"

fresh
echo '(each story whose text blocker names a human task)' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story saying 'human task' fails" 1

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
# among the task cut's refusals (chezmoi-9v4.1.9)
fresh
sed -e 's|add mode|extension|g' -e 's|Add mode|Extension|g' "$scratch/docs/WORKFLOW.md" > "$scratch/docs/WORKFLOW.md.new" && mv "$scratch/docs/WORKFLOW.md.new" "$scratch/docs/WORKFLOW.md"
expect "runbook copy without add mode fails" 1

fresh
echo 'Among its refusals: a dependency chain (A depends on B depends on C).' >> "$scratch/docs/WORKFLOW.md"
expect "runbook copy with the chain refusal fails" 1

fresh
echo 'The task cut refuses a dependency chain of three stories.' >> "$scratch/docs/WORKFLOW.md"
expect "runbook copy with the chain refusal in a sentence fails" 1

fresh
echo 'The closure chain goes through a dependency chain of stories, merged in order.' >> "$scratch/docs/WORKFLOW.md"
expect "runbook copy mentioning a dependency chain of closures passes" 0

# the retired story-DAG phrases are absent from every covered file: the skills, the agent docs,
# the user-level CLAUDE.md and the runbook (one case per phrase, each planted in one file kind)
fresh
echo 'Resolve a spec to one story per repo it changes.' >> "$scratch/skills/story-to-tasks/SKILL.md"
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

# the check and review loop's retired two-gate wording is absent from every file kind the sweep
# covers (one seeded case per phrase, each in its own kind); docs/specs keeps the words
fresh
echo 'Then the Evidence run checks the tip.' >> "$scratch/skills/sample/SKILL.md"
expect "skill saying 'Evidence run' fails" 1 "retired two-gate wording in $scratch/skills/sample/SKILL.md"

fresh
echo 'The marker stays put, so a later run reviews the fix.' >> "$scratch/docs/agents/triage-labels.md"
expect "agent doc saying 'a later run reviews the fix' fails" 1 "retired two-gate wording in $scratch/docs/agents/triage-labels.md"

fresh
echo 'Stop at a third round of either kind.' >> "$scratch/GLOSSARY.md"
expect "glossary saying 'a third round of either kind' fails" 1 "retired two-gate wording in $scratch/GLOSSARY.md"

fresh
echo 'A second red fails the story, no review.' >> "$scratch/docs/SEQUENCES.md"
expect "sequence diagrams saying 'a second red' fails" 1 "retired two-gate wording in $scratch/docs/SEQUENCES.md"

fresh
echo 'The retired Evidence run stays in the spec.' >> "$scratch/docs/specs/check-and-review-loop.md"
expect "a spec keeping 'Evidence run' passes" 0

# the gate with no check command (ADR 0015) is absent from every file kind the sweep covers, the
# glossary included (one seeded case per phrase, each in its own kind); docs/specs keeps the words
for case in 'skills/sample/SKILL.md|With no check target the gate is review-only.' \
  'docs/agents/triage-labels.md|A low task in a repo with no check command is reviewed.' \
  'GLOSSARY.md|A task without a check command lands on its review.' \
  'docs/SEQUENCES.md|checks green, the task row at low with a check command' \
  'docs/WORKFLOW.md|A repo with no\ncheck command is reviewed.'; do
  fresh
  printf "${case#*|}\n" >> "$scratch/${case%%|*}"
  expect "${case%%|*} naming a gate with no check command fails" 1 "retired review-only gate wording in $scratch/${case%%|*}"
done
fresh
echo 'A repo with no check command gets a review-only gate.' >> "$scratch/docs/specs/one-loop-three-rows.md"
expect "a spec keeping the review-only gate passes" 0

# stated once: a skill spelling the refusal out again fails
for sk in implement-spec implement-story close-epic; do
  fresh
  echo '`<epic-id> refused: <child-id> is not a story`' >> "$scratch/skills/$sk/SKILL.md"
  expect "$sk restating the malformed-epic refusal fails" 1 "restating the malformed-epic refusal"
done

fresh
swap_phrase docs/agents/issue-tracker.md 'create "<title>" --type task -l complexity:' 'create "<title>" --type chore -l complexity:'
sec=6 expect "a routed bead of type chore fails" 1 "a routed bead of type chore"

fresh
echo 'Body in the `to-tickets` issue template.' >> "$scratch/skills/triage/SKILL.md"
sec="5 6" expect "triage citing the to-tickets template fails" 1 "/triage citing the retired to-tickets template"

for case in 'a flat epic of tasks|flat epic' 'the legacy flat shape|flat shape' 'The flat-epic refusal.|flat-epic' \
  'the small-bug path does it|small-bug path' 'the small bug path|small bug path' \
  'run /mattpocock-skills:implement <id>|mattpocock-skills:implement' \
  'run /mattpocock-skills:to-tickets now|mattpocock-skills:to-tickets' \
  'the upstream engineering to-tickets skill|to-tickets' \
  'the implement-chore skill|implement-chore' 'the chore orchestrator|chore orchestrator' \
  'on branch chore/<id>|chore/'; do
  for file in skills/sample/SKILL.md docs/agents/issue-tracker.md docs/WORKFLOW.md skills/implement-story/SKILL.md; do
    fresh
    echo "${case%%|*}" >> "$scratch/$file"
    sec=5 expect "$file saying '${case%%|*}' fails section 5" 1 "a retired route (flat epic or shape, small-bug path, upstream skill or chore name) in $scratch/$file"
  done
done
fresh
printf 'The commit subject is chore: ignore agent scratch space.\nA chore type and a chore commit pass.\nSee /mattpocock-skills:tdd.\n' >> "$scratch/skills/sample/SKILL.md"
expect "the bare word chore and the other upstream skills pass" 0
fresh
echo 'ADR 0006 keeps the flat epic and /mattpocock-skills:to-tickets history.' >> "$scratch/docs/adr/0001.md"
echo 'The spec names a flat epic, chore/<id> and the small-bug path.' >> "$scratch/docs/specs/one-loop-three-rows.md"
expect "an ADR and a spec keeping the retired route words pass" 0

# the retired vocabulary (dev-9k5.1.10, dev-9k5.1.11): every retired word or phrase seeded
# together into each file section 5 sweeps (skills, agent docs, the project CLAUDE.md, the
# runbook, the sequence diagrams) fails by section 5 alone, the output naming each phrase's
# check, one lint run per file; the glossary and docs/adr/ are not swept
retired_vocab='The driver spawns the stories.|the retired driver role
Each ticket runner implements.|the retired ticket runner role
A merger folds it in.|the retired merger role
Spawn a fresh fix-up implementer.|the retired fix-up implementer role
Run the built-in `code-review` on it.|the built-in code-review named
Two review tools, two stages: per task.|the two review tools paragraph
Exit on the review marker.|the retired review marker
Run the lint command, then the tip.|the retired lint command
Name the test seams as checks.|the retired test seams as checks'
for file in skills/sample/SKILL.md skills/workflow/SKILL.md skills/close-epic/SKILL.md skills/spec-to-stories/SKILL.md \
  skills/spec-to-tasks/SKILL.md docs/agents/issue-tracker.md docs/agents/triage-labels.md CLAUDE.md docs/WORKFLOW.md docs/SEQUENCES.md; do
  fresh
  msgs=
  while IFS= read -r case; do
    echo "${case%%|*}" >> "$scratch/$file"
    msgs+="${case##*|} in $scratch/$file$nl"
  done <<<"$retired_vocab"
  sec=5 expect "$file seeded with every retired word fails section 5" 1 "$msgs"
done

fresh
echo 'The driver and the review marker are retired.' >> "$scratch/GLOSSARY.md"
expect "glossary naming the retired words passes the lint" 0

# section 5 reads each file as one line: a retired phrase wrapped across a line break, indented
# or inside a quote block, fails there alone; the same words a blank line apart pass (dev-86j)
for case in 'Each ticket\nrunner implements.|the retired ticket runner role' \
  '> Run the lint\n>    command, then the tip.|the retired lint command' \
  'Then the Evidence\n  run checks the tip.|retired two-gate wording' \
  'A feature is one story\nper repo.|retired story-DAG wording' \
  'The Evidence  \nrun goes.|retired two-gate wording'; do
  fresh
  printf "${case%%|*}\n" >> "$scratch/docs/WORKFLOW.md"
  sec=5 expect "runbook with '${case%%|*}' wrapped fails section 5" 1 "${case##*|} in $scratch/docs/WORKFLOW.md"
done
fresh
printf 'One task\n\nrunner notes follow.\n' >> "$scratch/docs/WORKFLOW.md"
expect "a phrase's words a paragraph apart pass section 5" 0
for block in '## One task\nrunner notes follow.' '| a task |\nrunner notes follow.' 'One task\n- runner notes follow.'; do
  fresh
  printf "\n$block\n" >> "$scratch/docs/WORKFLOW.md"
  expect "a phrase's words across a block boundary ('$block') pass section 5" 0
done
# section 10's wider chains wording leaves section 5's phrase to section 5
for doc in issue-tracker orchestration; do
  fresh
  echo 'Chains are out of scope.' >> "$scratch/docs/agents/$doc.md"
  sec=5 expect "$doc doc saying 'chains are out of scope' fails section 5 alone" 1 "retired story-DAG wording"
done

# the implement-spec skill passed as $1 outside the skills dir is swept like the default
fresh_spec
echo 'Then the Evidence run checks the tip.' >> "$spec"
sec=5 expect "implement-spec passed as \$1 with a retired phrase fails section 5" 1 "retired two-gate wording in $spec" "$spec" "$scratch/docs/WORKFLOW.md"

# a rule that moved to harness.md, cited at the rules doc in either form, fails section 5 alone,
# wrapped included; a rule the rules doc still holds, and the harness doc's citation, pass (dev-zra)
for case in "skills/implement-story/SKILL.md|as the rules doc's Scratch space says (Literal paths)" \
  "skills/sample/SKILL.md|the rules doc's Cut-off agents" \
  "docs/agents/issue-tracker.md|see orchestration.md's TMPDIR rule" \
  "docs/agents/triage-labels.md|(\`orchestration.md\`, Commits)" \
  "skills/sample/SKILL.md|re-add it as the rules doc's fallback says" \
  "skills/sample/SKILL.md|as the rules doc's Scratch space (Literal paths) says" \
  "skills/sample/SKILL.md|hand-rolled, as the rules doc's worktree fallback says" \
  "skills/spec-to-tasks/SKILL.md|as the \"Waiting\" rule of \`orchestration.md\` says" \
  "docs/agents/triage-labels.md|the idle rule in the rules doc" \
  "docs/agents/triage-labels.md|see \`orchestration.md\`'s TMPDIR rule" \
  "docs/WORKFLOW.md|the rules doc's\nWorktrees"; do
  fresh
  printf '%b\n' "${case#*|}" >> "$scratch/${case%%|*}"
  sec=5 expect "${case%%|*} citing '${case#*|}' fails section 5" 1 "a moved harness rule cited at the rules doc in $scratch/${case%%|*}"
done
fresh
printf "%s\n" "the rules doc's Scratch space (Gitignore)" "the harness doc's Scratch space says (Literal paths)" \
  "(\`orchestration.md\`, Trust rules, rule 2)" "the rules doc's Frontier (waiting tasks stay open)" >> "$scratch/skills/sample/SKILL.md"
expect "the rules doc's own rule and the harness doc's citation pass section 5" 0

# a semicolon ends a mermaid statement, so one inside a ```mermaid block fails; the same ';' in prose passes
fresh
printf '\n```mermaid\nsequenceDiagram\n    A->>B: one; two\n```\n' >> "$scratch/docs/SEQUENCES.md"
expect "a mermaid block with a semicolon fails" 1 "a semicolon in a mermaid block in $scratch/docs/SEQUENCES.md"

fresh
echo 'Prose may keep a semicolon; one, two.' >> "$scratch/docs/SEQUENCES.md"
expect "a semicolon outside a mermaid block passes" 0

# a rules doc cites another skill's rule in one form (dev-q47w): a heading cited bare after a
# possessive fails in any rules doc but the coding standards, which show it as the wrong form
fresh
printf '%s\n' "As \`/dev:task-orchestrator\`'s Two entries says." >> "$scratch/docs/agents/orchestration.md"
sec=18 expect "a bare heading cite of a skill in a rules doc fails section 18" 1 "present: an unquoted heading cite of a skill in $scratch/docs/agents/orchestration.md"

fresh
printf '%s\n' "As \`/dev:task-orchestrator\`'s" "Two entries says." >> "$scratch/docs/agents/orchestration.md"
sec=18 expect "a bare heading cite split across a line break fails section 18" 1 "present: an unquoted heading cite of a skill in $scratch/docs/agents/orchestration.md"

fresh
printf '%s\n' "As \`/dev:task-orchestrator\`'s" "own brief says." >> "$scratch/docs/agents/orchestration.md"
expect "a possessive followed by a lowercase word on the next line passes section 18" 0

fresh
printf '%s\n' "As \`/dev:task-orchestrator\`'s \"Two entries\" says, and \`/dev:implement-story\`'s **Story gate**." >> "$scratch/docs/agents/orchestration.md"
expect "a quoted heading cite and a bold step cite pass section 18" 0

fresh
printf '%s\n' "The wrong form: \`/dev:task-orchestrator\`'s Two entries." >> "$scratch/docs/agents/coding-standards.md"
expect "a bare heading cite in the coding standards passes section 18" 0

orch=docs/agents/orchestration.md
# the task row's budget regaining the conflict resolutions the landing took to the story row
fresh
awk 'index($0, "| **Task** |") == 1 { sub(/\| three fix-ups \|/, "| three fix-ups; three conflict resolutions per landing |") } { print }' \
  "$scratch/$orch" > "$scratch/$orch.new" && mv "$scratch/$orch.new" "$scratch/$orch"
sec=6 expect "orchestration doc's Task row regaining the conflict resolutions fails" 1 "present: task row: a conflict resolution budget"
# a red check record counted as checked, seeded back in the rules doc (dev-6qi)
fresh
printf '\nA tree with a check record counts as checked.\n' >> "$scratch/$orch"
sec=6 expect "orchestration doc counting any check record as checked fails" 1 "present: a red check record counted as checked"
# a fix-up that commits nothing re-reading the red record, seeded back in the rules doc (dev-vnf)
fresh
printf '\nSo a fix-up that commits nothing re-reads the red record.\n' >> "$scratch/$orch"
sec=6 expect "orchestration doc letting a fix-up that commits nothing re-read the red record fails" 1 "present: a fix-up that commits nothing re-reading the red record"
# the Check gate's retired sentence naming the epic row as the budget's exception, seeded back
fresh
printf '\n%s\n%s\n' 'The epic row is the exception: it spans runs while its PRs wait on their checks, so it counts each' \
  "story's budget from the story's \`epic fix-up\` notes (The epic row, above)." >> "$scratch/$orch"
sec=6 expect "orchestration doc naming the epic row as the budget's exception fails" 1 "present: the epic row named as the budget's exception"
# the accepted status is the frontmatter line itself: an amended status, or the words in the body, do not pass
fresh
swap_phrase docs/adr/0014-one-loop-at-three-rows.md '^status: accepted$' 'status: accepted, amended'
printf '\nThe decision is status: accepted, as the prose says.\n' >> "$scratch/docs/adr/0014-one-loop-at-three-rows.md"
sec=6 expect "ADR 0014 with 'status: accepted, amended' in the frontmatter fails" 1 "ADR 0014 is accepted"
fresh
rm "$scratch/docs/adr/0014-one-loop-at-three-rows.md"
sec=6 expect "a missing ADR 0014 fails" 1 "missing document: $scratch/docs/adr/0014-one-loop-at-three-rows.md"
# the retired two-level loop and the built-in review, seeded back; section 5 alone sweeps the
# review marker and the built-in review
for case in 'lint first, then the test seams|present: the retired two-level check order' \
  'at the story level the review marker is the exit|present: the retired review marker' \
  'reviewers run the built-in `code-review`|present: the built-in code-review named'; do
  fresh
  echo "${case%%|*}" >> "$scratch/$orch"
  s=6; case ${case%%|*} in *"review marker"*|*built-in*) s=5;; esac
  sec=$s expect "orchestration doc with '${case%%|*}' fails" 1 "${case#*|}"
done

# the Idle rule's retired story's-checks clause, seeded back (story dev-9k5.1 review)
fresh
echo "These are the story's checks." >> "$scratch/docs/agents/harness.md"
expect "harness doc regaining the story's-checks clause fails" 1 "present: the Idle rule's retired story's-checks clause"

# the row regaining the landing's conflict resolutions fails (dev-b8d.1.4)
fresh
swap_phrase skills/task-orchestrator/SKILL.md '^(You are the .*)within three fix-ups' '\1within three fix-ups and three conflict resolutions per landing'
sec=16 expect "task-orchestrator whose row regains conflict resolutions fails" 1 "present: the row's conflict resolutions"


fresh
echo "grep -q '^check:' <owner>/Makefile tells which" >> "$scratch/skills/implement-story/SKILL.md"
expect "a step 3 that greps the Makefile for the check target fails" 1 "present: the retired grep for the check target"

# a task orchestrator that resolves the check command per task again fails, so parallel tasks
# share one gate (dev-yyu)
fresh
swap_phrase skills/task-orchestrator/SKILL.md '^(You are the \*\*task orchestrator\*\*.*)never resolve it yourself' '\1find it with `make -C <owner> -pRrq :`'
sec=16 expect "a task orchestrator that looks up the check target per task fails" 1 "present: the per-task check target lookup"

fresh
swap_phrase skills/task-orchestrator/SKILL.md '^(You are the \*\*task orchestrator\*\*.*)never resolve it yourself' '\1use `make check` when `<owner>`'"'"'s Makefile has a `check` target'
sec=16 expect "a task orchestrator that applies the Makefile convention per task fails" 1 "present: the per-task check command by Makefile convention"

fresh
swap_phrase skills/task-orchestrator/SKILL.md '^You are the \*\*task orchestrator\*\*' 'You are the ticket runner'
sec="5 16" expect "a row opening on the old ticket role fails" 1 "missing: the row opens on the task orchestrator"

for case in 'Resolve the owner repo'"'"'s **lint command** once, here beside the forge.|present: the retired lint-command resolution' \
  '`make lint` when `<owner>`'"'"'s Makefile has a `lint` target|present: the retired lint-command resolution' \
  'The brief'"'"'s header carries it as `<lint>`.|present: the retired lint placeholder' \
  '> 4. Spawn a **merger** at the tier'"'"'s implementation model.|present: the retired merger role'; do
  fresh
  echo "${case%%|*}" >> "$scratch/skills/implement-story/SKILL.md"
  s=one; case ${case%%|*} in *merger*) s=5;; esac   # section 5 alone sweeps the retired role
  sec=$s expect "implement-story regaining '${case%%|*}' fails" 1 "${case#*|}"
done

# the clean-worktree guard regaining --untracked-files=no fails (untracked files the check sees
# but the tree lacks would pass a dirty worktree)
fresh
swap_phrase skills/task-orchestrator/SKILL.md '^(3\. .*)`git -C <worktree path> status --porcelain`(.*)$' '\1`git -C <worktree path> status --porcelain --untracked-files=no`\2'
sec=16 expect "the clean-worktree guard regaining --untracked-files=no fails" 1 "present: the clean-worktree guard that hides untracked files"

for case in ' Each check logs to <worktree path>/.tmp/checks-<round>-<k>.log.|present: the per-round check log' \
  ' Spawn a reviewer briefed to call the built-in `code-review`.|present: the built-in code-review named'; do
  fresh
  swap_phrase skills/task-orchestrator/SKILL.md '^(3\. .*)$' "\\1${case%%|*}"
  s=16; case ${case%%|*} in *built-in*) s=5;; esac   # section 5 alone sweeps the built-in review
  sec=$s expect "task-orchestrator step 3 regaining '${case%%|*}' fails" 1 "${case#*|}"
done

fresh
swap_phrase skills/implement-story/SKILL.md '^## Landing$' '## Merging'
sec=8 expect "implement-story without its Landing section fails" 1 "missing: the Landing section"
# the reviewed-tip guard seeded back after a conflict resolution fails (dev-b8d.1.4 review 1)
fresh
swap_phrase skills/implement-story/SKILL.md '^(3\. A conflict goes to an implementer.*)Green: ' "\\1Green: repeat 1's guards and 2's stray-commit check. "
sec=8 expect "implement-story repeating the reviewed-tip guard after a resolution fails" 1 "present: the reviewed-tip guard repeated after a conflict resolution"
fresh
printf '%s\n' 'whose hand-rolled `task/<task-slug>` carries commits' >> "$scratch/skills/implement-story/SKILL.md"
sec=8 expect "implement-story's brief limiting the gate entry to the hand-rolled route fails" 1 "present: the gate entry limited to the hand-rolled route"
fresh
printf '%s\n' 'git log --oneline <branch>..task/<task-slug>' >> "$scratch/skills/implement-story/SKILL.md"
sec=8 expect "implement-story carrying the cut-off probe's old branch test fails" 1 "present: a second copy of the cut-off probe's old hand-rolled branch test"
for case in '   - `<id> closed`: nothing more for that task.|present: a closed report from the task orchestrator' \
  'A task orchestrator is a subagent, not a skill. Send this, filled in:|present: the pasted task orchestrator brief'; do
  fresh
  printf '%s\n' "${case%%|*}" >> "$scratch/skills/implement-story/SKILL.md"
  sec=8 expect "implement-story regaining '${case%%|*}' fails" 1 "${case#*|}"
done

fresh
swap_phrase skills/task-orchestrator/SKILL.md '^4\. \*\*Report the reviewed branch\.\*\*' '4. **Land the task.**'
sec=16 expect "task-orchestrator whose step 4 lands the task fails" 1 "missing: step 4 reports the reviewed branch"
for case in 'Then merge, `git -C <owner> merge <task branch>`.|present: a write command on the owner checkout' \
  'Then `git -C <owner> switch <branch>`.|present: a write command on the owner checkout' \
  'Then close it, `bd -C <owner> close <task-id>`.|present: the task closed by the task orchestrator' \
  'Or report `<task-id> closed`.|present: a closed report line'; do
  fresh
  printf '%s\n' "${case%%|*}" >> "$scratch/skills/task-orchestrator/SKILL.md"
  sec=16 expect "task-orchestrator regaining '${case%%|*}' fails" 1 "${case#*|}"
done

for case in 'Then `gh pr create --draft --repo <forge-slug>`.|present: a draft PR for a standalone task' \
  'Or `tea pr create --title "WIP: <task title>"`.|present: a draft PR for a standalone task' \
  '   story:   <story-id> <title>|present: a story line in the report' \
  '   human:   <bead-id> <title>|present: a human: or waiting: line in the report'; do
  fresh
  printf '%s\n' "${case%%|*}" >> "$scratch/skills/implement-task/SKILL.md"
  sec=17 expect "implement-task regaining '${case%%|*}' fails" 1 "${case#*|}"
done
# the skill exists, so /dev:task-orchestrator's refusal and the glossary naming it pass the
# namespace rule; without its dir they fail there
fresh
rm -r "$scratch/skills/implement-task"
sec="11 17" expect "a missing implement-task skill dir fails the namespace rule" 1 "/dev:implement-task names no skill"

fresh
printf '%s\n' '| **Standalone task** | story orchestrator | one task orchestrator |' >> "$scratch/docs/agents/orchestration.md"
sec=6 expect "orchestration with a fourth table row fails" 1 "present: a fourth row in the table"

# step 7's heading swapped away fails the story-gate pin (dev-9k5.1.9 review 1)
fresh
swap_phrase skills/implement-story/SKILL.md '^7\. \*\*Story gate\.\*\*' '7. **Story review.**'
expect "implement-story step 7 not headed the story gate fails" 1 "missing: step 7 is the story gate"

# a red record read as checked, seeded back on step 3's, step 7's or step 9's line, fails (dev-6qi)
fresh
swap_phrase skills/task-orchestrator/SKILL.md '^(3\. .*)$' '\1 So a tree with a record is checked: read its exit and run nothing.'
sec=16 expect "task-orchestrator regaining the red record read as checked fails" 1 "present: the gate skipping the run on a red record"
for case in '^(7\. .*)$|\1 So a tree with a record is checked: read its exit and run nothing.|present: the story gate skipping the run on a red record' \
  '^(9\. .*)$|\1 A rerun on that tip reads the record as checked red.|present: a rerun reading a red record as checked'; do
  anchor=${case%%|*} rest=${case#*|}
  fresh
  swap_phrase skills/implement-story/SKILL.md "$anchor" "${rest%%|*}"
  expect "implement-story regaining '${rest%%|*}' fails" 1 "${rest#*|}"
done

# the checks named after the review on step 7's line: the order pin fails; the phrase comes from
# the lint's own pin for it
fresh
pin_phrase "the story gate runs the checks first in each pass"
move_to_line_end skills/implement-story/SKILL.md '^7\. ' "$pp"
expect "story gate step 7 with the checks after the two-axis review fails" 1 "missing: the story gate (step 7) runs the checks before the reviewed-tip compare"

# the retired story-gate wording seeded back on its own line fails: a landing agent, a budgeted minors
# fix-up, the Running the checks paragraph, the review marker, a deliver step marking the PR ready
for case in '^(7\. .*)$|\1 Then spawn a merger.|present: the retired merger role' \
  "^(7\\. .*)\$|\\1 Every fix-up spends it, a minors-only review's included.|present: the story gate's minors fix-up spending budget" \
  '^(8\. .*)$|\1 Mark the PR ready (`gh pr ready <n> --repo <forge-slug>`).|present: the deliver step marking the PR ready' \
  '^(8\. .*)$|\1 Mark it ready (`tea pr edit <n> --repo <owner> --ready`).|present: the deliver step marking the PR ready with tea' \
  '^(7\. .*)$|\1 Run `make -C <owner> check > <owner>/.tmp/checks/<tree>/log 2>\&1`.|present: a second copy of the check-record call'; do
  anchor=${case%%|*} rest=${case#*|}
  fresh
  swap_phrase skills/implement-story/SKILL.md "$anchor" "${rest%%|*}"
  s=one; case ${rest%%|*} in *merger*) s=5;; esac   # section 5 alone sweeps the retired role
  sec=$s expect "implement-story regaining '${rest%%|*}' fails" 1 "${rest#*|}"
done
for case in '   **Running the checks.** The checks are the lint command, then the test seams.|present: the retired Running the checks paragraph' \
  'The exit is the review marker.|present: the retired review marker'; do
  fresh
  echo "${case%%|*}" >> "$scratch/skills/implement-story/SKILL.md"
  # the Running the checks seed also names the lint command, which section 5 sweeps
  s=one; case ${case%%|*} in *"the lint command"*) s="5 8";; *"review marker"*) s=5;; esac
  sec=$s expect "implement-story regaining '${case%%|*}' fails" 1 "${case#*|}"
done

# the retired two-gate phrases seeded back fail, by section 5's sweep alone
for line in 'Then the Evidence run checks the tip.' \
  'The marker stays put, so a later run reviews the fix.' \
  'A second red skips step 8.' \
  'A third round of either kind is `failed`.'; do
  fresh
  echo "$line" >> "$scratch/skills/implement-story/SKILL.md"
  sec=5 expect "implement-story regaining '$line' fails" 1 "retired two-gate wording in $scratch/skills/implement-story/SKILL.md"
done

# the retired phrase seeded back fails
fresh
echo 'Then run the seams and keep the command and its output.' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story with 'the command and its output' seeded fails" 1 "the command and its output"

fresh
swap_phrase skills/task-orchestrator/SKILL.md '^3\. \*\*Check gate\*\*, every tier' '3. The checks'
sec=16 expect "task-orchestrator step 3 not opening with the loop fails" 1 "missing: task orchestrator step 3 opens with the check gate, every tier"

# position: a reviewer spawned ahead of the checks' green (the green's own spawn kept too)
fresh
swap_phrase skills/task-orchestrator/SKILL.md '^(3\. \*\*Check gate\*\*, every tier, )' '\1for `medium` and `high` spawn two **reviewers** alongside it, '
sec=16 expect "task-orchestrator step 3 spawning the reviewers before the checks' green fails" 1 "present: task orchestrator step 3 spawns a reviewer ahead of the checks' green"

fresh
swap_phrase skills/task-orchestrator/SKILL.md '^(3\. .*)$' "\\1 Brief the reviewer with the skill's two sub-agents spawned at the tier's review model too."
sec=16 expect "task-orchestrator step 3 regaining the reviewer's sub-agents fails" 1 "present: the reviewer told to spawn the skill's sub-agents"

fresh
echo 'Run the check gate again, and on green spawn a reviewer again.' >> "$scratch/skills/task-orchestrator/SKILL.md"
sec=16 expect "task-orchestrator regaining the run-the-gate-again wording fails" 1 "present: the retired run-the-gate-again wording"

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
echo "run /story-to-tasks" > "$scratch/docs/specs/s.md"
expect "a bare /<skill> in docs/specs fails the namespace rule" 1 "$ns_msg in $scratch/docs/specs/s.md"
fresh
mkdir -p "$scratch/docs/specs"
echo "run /dev:not-built-yet" > "$scratch/docs/specs/s.md"
expect "a /dev:<not yet built> in docs/specs passes" 0

# docs/adr: a record keeps the skill names of its day, so the existence check does not apply
fresh
mkdir -p "$scratch/docs/adr"
echo "run /dev:retired-skill" > "$scratch/docs/adr/0099-x.md"
expect "a retired /dev:<skill> in docs/adr passes" 0
fresh
mkdir -p "$scratch/docs/adr"
echo "run /retired-skill" > "$scratch/docs/adr/0099-x.md"
expect "a bare /<skill> in docs/adr fails the namespace rule" 1 "$ns_msg in $scratch/docs/adr/0099-x.md"

# every skill GLOSSARY.md names must exist; a glossary naming a missing skill (/dev:not-built-yet) fails
fresh
echo 'The `/dev:task-orchestrator` and `/dev:implement-task` run it.' >> "$scratch/GLOSSARY.md"
expect "the glossary naming the task row's skills passes" 0
fresh
echo 'The `/dev:not-built-yet` runs it.' >> "$scratch/GLOSSARY.md"
expect "the glossary naming another missing skill fails" 1 "/dev:not-built-yet names no skill"

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

# LINT_UNCHANGED, which every case but the baseline lints with: a seeded failure in a file it
# lists is skipped, while the same seed unlisted fails, as the retired-phrase cases show
expect_flush all
fresh
echo "cut one" >> "$scratch/skills/sample/SKILL.md"
printf '%s\n' "$scratch/skills/sample/SKILL.md" > "$jobs/unchanged"
fx_check "a seeded file LINT_UNCHANGED lists is not checked" \
  eval 'result_is 0 "" "$(unchanged_list=$jobs/unchanged lint_scratch)"'
# an empty list skips nothing, the sweeps over many files included
fresh
printf '```mermaid\nA->>B: one; two\n```\n' >> "$scratch/docs/agents/sample.md"
: > "$jobs/unchanged"
fx_check "an empty LINT_UNCHANGED skips no sweep" \
  eval 'result_is 1 "semicolon in a mermaid block" "$(unchanged_list=$jobs/unchanged lint_scratch)"'

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
