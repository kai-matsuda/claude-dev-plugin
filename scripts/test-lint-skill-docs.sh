#!/usr/bin/env bash
# Regression tests for scripts/lint-skill-docs.sh against a scratch copy of the plugin's own tree
# (skills/, references/, docs/, CLAUDE.md, GLOSSARY.md), plus the sample skill and reference doc under
# scripts/fixtures/lint-skill-docs and a stand-in plugin dir holding every mattpocock-skills name
# the tree references. The clean copy passes; every section has seeded copies that fail it and
# it alone (the "== <n>. " header the lint prints over its FAIL lines tells which section
# failed), and a copy missing a section's document fails naming that document rather than
# skipping the section (dev-dov). Every queued check of the lint has its cases derived from the
# lint's own list of its checks, LINT_PIN_LIST (dev-yqpz): a positive check gets a drop case, a
# lacksf check its phrase seeded, and every other absent-phrase check each plain text its pattern
# bans seeded. A hand-written case that needs a pin's phrase, anchor or plain banned text, seeded
# or only passed as a counterpart, reads it from that list (pin_phrase, pin_anchor, ban, ban_alt,
# ban_nth); the other hand-written cases seed an instance of a regex construct (a pattern the list
# gives back whole, not as text), pass a counterpart that must not fail, check one of the paths
# that keep their own cases (the namespace rule, section 11, the brief rule, section 13, the pin
# tables' row and sweep checks, and the lint's direct checks, which never reach the list), or type
# fixture text of their own that no case needs as a pin phrase.
# The last section drives the version-bump rule on a throwaway git repo (VERSION_BUMP_REPO,
# VERSION_BUMP_BASE; the other cases point the repo at a non-repo path and pin the base to HEAD):
# its shipping pathspec, uncommitted edits and bumps, and the base on a detached HEAD.
# The lint of the plugin's own tree is one of the Makefile's steps, not repeated here.
# Each case's lint run goes in the background against the scratch tree, moved into the case's
# own dir (one tree per expect: fresh builds it, expect takes it), one per CPU (LINT_TEST_SLOTS
# forces the count), and the results print in case order. Every fresh and snapshot runs in this shell, one after another, so each
# is one process: fresh is a cp of a pristine tree built once, the snapshot is a mv, and the
# verdicts are read and tallied with builtins. Every case but the baseline lints with
# LINT_UNCHANGED listing its files still byte-identical to the pristine tree, whose queued checks
# the baseline shows pass, and the repo's pin tables unless it reads its own, so a run checks only
# what its case seeded and skips the section of every doc it left alone. The cases derived from
# LINT_PIN_LIST share their runs: one seeded tree per kind and file (pin_case, seed_pins), a check
# apart from any seeding that takes its anchor (round_specs), its verdicts read off one lint output
# (judge_batch), and a case a batch cannot vouch for runs alone, so every derived case still prints
# its own verdict line. A shared tree's verdict stands for a tree of the case's own on the
# conditions set out above the batch loop. Section 18's cases share runs too, each in a small doc of
# its own (cite_case, cite_flush, judge_cites), and one its run cannot vouch for runs alone as well.
# Each part of the run prints its wall and CPU seconds and the pool's slot count on a "timing:"
# line (phase), for the CI log.
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
nslots=${LINT_TEST_SLOTS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}
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
cp -R "$repo_root/skills" "$repo_root/references" "$repo_root/docs" "$repo_root/CLAUDE.md" "$repo_root/GLOSSARY.md" "$pristine/"
mkdir -p "$pristine/.claude" && cp -R "$repo_root/.claude/rules" "$pristine/.claude/"
cp -R "$fixtures/skills/sample" "$pristine/skills/"
cp "$fixtures/references/sample.md" "$pristine/references/"
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
# unchanged_tables: the repo's pin tables, the ones the baseline read, unless the case reads its own
unchanged_tables() {
  [ -n "${pins_dir:-}" ] || printf '%s\n' "$repo_root"/scripts/*.tsv
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
  out=$(SKILLS_DIR=${skills_dir:-$scratch/skills} REFERENCES_DIR=${references_dir:-$scratch/references} DOCS_DIR=$scratch/docs RULES_DIR=$scratch/.claude/rules \
    USER_CLAUDE_MD=${claude_md:-$scratch/CLAUDE.md} HOOKS_DIR=$scratch/hooks README_MD=$scratch/README.md GLOSSARY_MD=${glossary_md:-$scratch/GLOSSARY.md} \
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
# sections it names ("6 10"), or in exactly one section when it says "one". With $must_not_print
# set (lines, one per line), the output must hold none of them.
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
  # with $must_not_print set (lines, one per line), a case must print none of them
  if [ -z "$why" ] && [ -n "${must_not_print:-}" ]; then
    while IFS= read -r got; do
      [ -z "$got" ] || [[ $4 != *"$got"* ]] || { why="printed '$got', which it must not"; break; }
    done <<<"$must_not_print"
  fi
  if [ -z "$why" ]; then echo "ok   $1"; return; fi
  echo "FAIL $1 ($why)"
  grep '^FAIL' <<<"$4" | head -5 | sed 's/^/       /'
}
# judge_batch <spec> <lint output>: one ok line per record of the spec (its fields under seed_pins)
# the lint's output vouches for; every other record goes to $BATCH_RETRY, to run alone. The output
# vouches for a record when the lint ended 1 and printed its message, which names its check's
# phrase, and for a seed when the line it seeded is also among the hits shown under that message,
# since another record's seed can fire the same check. The output's paths are the case's dir
# ($BATCH_DIR); the spec's are the scratch dir's ($BATCH_SCRATCH)
judge_batch() {
  local rc=${2##*$'\n'}
  printf '%s\n' "$2" | rc=$rc awk -F '\t' '
    NR == FNR {
      while (d != "" && (i = index($0, d))) $0 = substr($0, 1, i - 1) s substr($0, i + length(d))
      out = out $0 "\n"; next }
    {
      i = index(out, $6)
      ok = (ENVIRON["rc"] == 1 && i)
      if (ok && $1 == "seed") {
        hits = substr(out, i + length($6))
        if (match(hits, /\n(FAIL|== )/)) hits = substr(hits, 1, RSTART)
        ok = index(hits, ":" $4 "\n")
      }
      if (ok) print "ok   " $5; else print > ENVIRON["BATCH_RETRY"]
    }' d="${BATCH_DIR:-}" s="${BATCH_SCRATCH:-}" - "$1"
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
# phase <name>: waits for every case, then prints the wall and CPU seconds since the last phase,
# so a CI log shows each part's cost and how many cores it got (CPU over wall) beside the pool's
# slots: this test's wall time on a host follows its CPU seconds over that host's cores
phase_wall=0 phase_cpu=0
phase() {
  local cpu
  expect_flush all
  times > "$jobs/times"
  cpu=$(awk '{ for (i = 1; i <= 2; i++) { split($i, t, /[ms]/); c += t[1] * 60 + t[2] } } END { printf "%d", c }' "$jobs/times")
  echo "timing: $1: $((SECONDS - phase_wall))s wall, $((cpu - phase_cpu))s cpu on $nslots slots"
  phase_wall=$SECONDS phase_cpu=$cpu
}
# expect <description> <expected exit code> [messages the output must contain, one per line] [lint args...]
# Moves the scratch tree into the case's own dir and lints it there in the background, every
# $scratch path in the message, the arguments and the override variables rewritten to it.
expect() {
  local d=$1 want=$2 msg=${3:-} dir a v args
  args=()
  shift 3 2>/dev/null || shift $#
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
    for v in skills_dir references_dir claude_md glossary_md pins_dir bump_repo_dir; do
      [ -z "${!v:-}" ] || eval "$v=\${$v//\"\$scratch\"/\"\$dir\"}"
    done
    batch_scratch=$scratch
    msg=${msg//"$scratch"/"$dir"} scratch=$dir
    # with $full set the case lints every file, as the baseline must
    # the list vouches for a file only in the role the baseline linted it in, so every path the
    # case hands the lint (an argument or an override) leaves it, with everything under it,
    # unless it names the very path that role defaults to
    if [ -z "${full:-}" ]; then
      a1=${args[0]:-} a2=${args[1]:-}
      [ "$a1" != "$dir/skills/implement-spec/SKILL.md" ] || a1=
      [ "$a2" != "$dir/docs/WORKFLOW.md" ] || a2=
      printf '%s\n' "$a1" "$a2" "${skills_dir:-}" "${references_dir:-}" "${claude_md:-}" "${glossary_md:-}" > "$dir.roles"
      unchanged_files "$dir" | awk 'NR == FNR { if ($0 != "") role[$0]; next }
        { for (r in role) if ($0 == r || $0 == r "/" || index($0, r "/") == 1) next; print }' \
        "$dir.roles" - > "$dir.same"
      unchanged_tables >> "$dir.same"
      unchanged_list=$dir.same
    fi
    if [ -n "${batch:-}" ]; then
      BATCH_RETRY=$dir.retry BATCH_DIR=$dir BATCH_SCRATCH=$batch_scratch \
        "${judge_fn:-judge_batch}" "$batch" "$(lint_scratch ${args[@]+"${args[@]}"})" > "$dir.part" 2>&1
    else
      judge "$d" "$want" "$msg" "$(lint_scratch ${args[@]+"${args[@]}"})" > "$dir.part" 2>&1
    fi
    rm -rf "${dir:?}" "${dir:?}.same" "${dir:?}.roles"   # the case's tree goes here, off the parent's path
    # the .out appears whole or not at all, so expect_flush never prints half a verdict
    mv "$dir.part" "$dir.out"
  ) &
  expect_flush
}

fresh
full=1 expect "baseline copy passes" 0

# The lint's own list of its checks (LINT_PIN_LIST), written by one run on the pristine tree, one
# check per line as <type> <file> <description> <phrase> [<anchor>] (the lint's queue line). Every
# positive check (has, hasc, hase, line_has, line_hase, para_has, sec_has, opening_has) and every
# lacksf gets its cases from it below, and a case that needs a pinned phrase or anchor reads it
# with pin_phrase or pin_anchor, so a whole pin phrase is written once, in the lint or a table row (dev-yqpz).
# pin_list_run <list file>: runs the lint on the scratch tree with its list of checks written to the
# file (emptied first), printing the run's output
pin_list_run() {
  export LINT_PIN_LIST=$1
  : > "$LINT_PIN_LIST"
  lint_scratch
  local rc=$?
  unset LINT_PIN_LIST
  return $rc
}
fresh
pin_list_run "$jobs/pins.list" > /dev/null
# the same run left the pristine tree's cite names beside the list, for section 18 (LINT_UNCHANGED)
export LINT_CITE_BASE=$jobs/pins.list.cites
phase "baseline and pin list"

# pin_phrase <description>: sets pinned_phrase to the phrase of the lint's pin of that description, from its list
pin_phrase() {
  pinned_phrase=$(awk -F '\t' -v d="$1" '$3 == d { print $4; exit }' "$jobs/pins.list")
  [ -n "$pinned_phrase" ] || { echo "FAIL pin_phrase: the lint has no pin described '$1'"; fails=$((fails+1)); pinned_phrase=NO-SUCH-PIN; }
}
# pin_anchor <description>: sets pinned_anchor to the anchor of the lint's pin of that description
pin_anchor() {
  pinned_anchor=$(awk -F '\t' -v d="$1" '$3 == d { print $5; exit }' "$jobs/pins.list")
  [ -n "$pinned_anchor" ] || { echo "FAIL pin_anchor: the lint has no anchored pin described '$1'"; fails=$((fails+1)); pinned_anchor=NO-SUCH-ANCHOR; }
}

# ban <variable> <description>: sets the variable to the text an absent-phrase check of that
# description bans, read from the list, for a hand-written case that seeds it
ban() { pin_phrase "$2"; printf -v "$1" '%s' "$pinned_phrase"; }

# append_to_matching <file under scratch> <anchor regex> <text>: put the text at the end of every line
# matching the anchor, for the phrase an anchored absent-phrase check (line_lacks) reads on its line
append_to_matching() {
  an="$2" t="$3" rewrite "$1" awk '{ if ($0 ~ ENVIRON["an"]) $0 = $0 " " ENVIRON["t"]; print }'
}
# alts(<type>, <pattern>): sets A[1..n], returns n: the texts an absent-phrase check's pattern bans: the
# plain alternatives at the top level of a pattern (a \. is a dot), the whole phrase of a fixed-string check
# (line_lacks); an alternative that holds a regex construct, or sits inside a group, is left to the
# hand-written cases (uncovered_pins fails a pin with none). An awk function, since the pin list runs through it ten thousand times
alts_fn='function alts(t, pat,   n, alt, c, i, depth) {
    if (t == "X") { A[1] = pat; return 1 }
    gsub(/\\\./, ".", pat)
    for (i = 1; i <= length(pat) + 1; i++) {
      c = substr(pat, i, 1)
      if (c == "(" || c == "[") depth++; else if (c == ")" || c == "]") depth--
      if (c == "" || (c == "|" && !depth)) {
        if (alt != "" && alt !~ /[][^$()*+?{}\\]/) A[++n] = alt
        alt = ""
      } else alt = alt c
    }
    return n + 0
  }'
# absent_alternatives <type> <pattern>: alts' texts, one per line
absent_alternatives() {
  t=$1 p=$2 awk "$alts_fn"' BEGIN { n = alts(ENVIRON["t"], ENVIRON["p"]); for (i = 1; i <= n; i++) print A[i] }'
}
# ban_pick <variable> <description> <n> <word>: sets the variable to the n-th plain alternative of the
# pattern of that description (n empty: the first one holding <word>, which may be empty)
ban_pick() {
  local alt i=0 hit
  pin_phrase "$2"
  while IFS= read -r alt; do
    i=$((i+1)) hit=
    if [ -n "$3" ]; then [ "$i" -eq "$3" ] && hit=1; else case $alt in *"$4"*) hit=1 ;; esac; fi
    [ -z "$hit" ] || { printf -v "$1" '%s' "$alt"; return; }
  done < <(absent_alternatives w "$pinned_phrase")
  echo "FAIL ban_pick: '$2' bans no plain text ${3:+number $3}${4:+holding '$4'}"; fails=$((fails+1)); printf -v "$1" '%s' NO-SUCH-TEXT
}
# ban_alt <variable> <description> [<word>]: the first plain alternative of a pattern of plain words, or
# the first one holding <word>
ban_alt() { ban_pick "$1" "$2" "" "${3:-}"; }
# ban_nth <variable> <description> <n>: the n-th plain alternative of the pattern, so that rewording
# the ban leaves the case reading it
ban_nth() { ban_pick "$1" "$2" "$3"; }

fresh
expect "an explicit implement-spec path that does not exist fails" 1 "missing document: $scratch/nope.md" "$scratch/nope.md" "$scratch/docs/WORKFLOW.md"

fresh
expect "an explicit runbook path that does not exist fails" 1 "missing document: $scratch/nope.md" "" "$scratch/nope.md"

# an unchanged doc handed in another doc's role is linted in that role, never skipped as unchanged
fresh
sec=1 expect "an unchanged skill passed as the implement-spec skill fails section 1" 1 "" "$scratch/skills/workflow/SKILL.md"

for var in skills_dir references_dir claude_md glossary_md pins_dir; do
  fresh
  eval "$var=$scratch/nope"
  expect "a set override ($var) naming a missing path fails" 1 "no such"
  unset "$var"
done

fresh
echo "retired wording: cut one" > "$scratch/skills/sample/notes.txt"
expect "retired phrase in a non-md file under a skill dir fails" 1 "retired phrase in $scratch/skills/sample/notes.txt"

fresh
ban_nth ban_spec_slug "retired phrase in $scratch/skills/sample/SKILL.md" 1
ban_nth ban_story_cut_md "retired phrase in $scratch/skills/sample/SKILL.md" 2
echo "retired wording: $ban_spec_slug" > "$scratch/references/notes.yaml"
expect "retired placeholder in a non-md file under the reference docs fails" 1 "retired phrase in $scratch/references/notes.yaml"

fresh
echo "cut one" >> "$scratch/skills/sample/SKILL.md"
expect "retired phrase in a md file still fails" 1 "retired phrase in $scratch/skills/sample/SKILL.md"

fresh
echo "see $ban_story_cut_md" >> "$scratch/references/sample.md"
expect "the retired story-cut file name in a reference doc fails" 1 "retired phrase in $scratch/references/sample.md"

fresh
echo "the orchestration doc's Story plumbing" >> "$scratch/references/sample.md"
expect "the old Story plumbing section name in a reference doc fails" 1 "retired phrase in $scratch/references/sample.md"

fresh
echo "the orchestration doc's story plumbing" >> "$scratch/references/sample.md"
expect "the old section name in lowercase in a reference doc fails" 1 "retired phrase in $scratch/references/sample.md"

fresh
ban ban_run_in_background "foreground spawn instruction in $scratch/skills/sample/SKILL.md"
echo "$ban_run_in_background" >> "$scratch/skills/sample/SKILL.md"
expect "foreground spawn instruction in a skill fails" 1 "foreground spawn instruction in $scratch/skills/sample/SKILL.md"

fresh
printf 'a shortcut one exists\nthe cut ones stay\n' >> "$scratch/skills/sample/SKILL.md"
expect "words containing the retired phrase do not false-fail" 0

# namespace rule: our skills are dev:<skill>, mattpocock's are mattpocock-skills:<skill>; a bare
# /<skill> or any other namespace fails in a skill doc, a reference doc, the runbook, the project
# CLAUDE.md or the root glossary (dev-9np)
ns_msg="bare or unknown skill namespace"
for target in skills/sample/SKILL.md references/sample.md docs/WORKFLOW.md CLAUDE.md GLOSSARY.md; do
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
echo "run /dev:nope" >> "$scratch/references/sample.md"
skills_dir=$scratch/noskills expect "an unknown /dev:<x> fails while no skill has shipped" 1 "/dev:nope names no skill"
fresh
mkdir -p "$scratch/noskills"
echo "run /dev:setup-repo" >> "$scratch/references/sample.md"
skills_dir=$scratch/noskills expect "a /dev:<x> for one of the plugin's skills fails when its dir is gone" 1 "/dev:setup-repo names no skill"
fresh
echo "run /dev:no-such-skill" >> "$scratch/references/sample.md"
expect "a /dev:<x> naming no skill dir fails while other skills have shipped" 1 "/dev:no-such-skill names no skill"

# a renamed skill turns every reference to its old name red, and its new name resolves (dev-89o)
# (a throwaway skill, since renaming one a section reads fails that section too)
fresh
mkdir "$scratch/skills/old-guide"; mv "$scratch/skills/old-guide" "$scratch/skills/guide"
echo "run /dev:old-guide" >> "$scratch/references/sample.md"
expect "a /dev:<x> for a renamed skill's old name fails" 1 "/dev:old-guide names no skill"
fresh
mkdir "$scratch/skills/old-guide"; mv "$scratch/skills/old-guide" "$scratch/skills/guide"
echo "run /dev:guide" >> "$scratch/references/sample.md"
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
echo "run /dev:new-skill" >> "$scratch/references/sample.md"
expect "a shipped /dev:<x> passes" 0
fresh
mkdir -p "$scratch/noskills"
echo "run /close-story" >> "$scratch/references/sample.md"
skills_dir=$scratch/noskills expect "a bare /<skill> fails while no skill has shipped" 1 "$ns_msg in $scratch/references/sample.md: /close-story"
fresh
mkdir -p "$scratch/noskills"
echo "run /mattpocock-skills:nope" >> "$scratch/references/sample.md"
skills_dir=$scratch/noskills expect "/mattpocock-skills:<missing> fails while no skill has shipped" 1 "/mattpocock-skills:nope names no skill"

# the docs ship in the plugin: a path into the dotfiles deployment or the chezmoi source fails
# in any doc under docs/ and in the runbook
for path in '~/.claude/references/orchestration.md' '~/.claude/hooks/guard-rm.sh' '~/.local/share/chezmoi/GLOSSARY.md'; do
  fresh
  echo "see \`$path\`" >> "$scratch/docs/adr/0001.md"
  expect "a dotfiles deployment path ($path) under docs/ fails" 1 "dotfiles deployment path in $scratch/docs/adr/0001.md"
done
fresh
echo 'see `~/.claude/references/*.md`' >> "$scratch/docs/WORKFLOW.md"
expect "a dotfiles deployment path in the runbook fails" 1 "dotfiles deployment path in $scratch/docs/WORKFLOW.md"
# and in the skills, the reference docs and the project CLAUDE.md, in the $HOME/ spelling too
fresh
echo 'read `~/.claude/references/orchestration.md`' >> "$scratch/skills/sample/SKILL.md"
expect "a dotfiles deployment path in a skill fails" 1 "dotfiles deployment path in $scratch/skills/sample/SKILL.md"
fresh
echo 'read `~/.claude/references/orchestration.md`' >> "$scratch/references/sample.md"
expect "a dotfiles deployment path in a reference doc fails" 1 "dotfiles deployment path in $scratch/references/sample.md"
fresh
echo 'rules: `~/.claude/references/`' >> "$scratch/CLAUDE.md"
expect "a dotfiles deployment path in the project CLAUDE.md fails" 1 "dotfiles deployment path in $scratch/CLAUDE.md"
for path in '$HOME/.claude/references/orchestration.md' '${HOME}/.claude/hooks/guard-rm.sh' '$HOME/.local/share/chezmoi/GLOSSARY.md'; do
  fresh
  echo "see \`$path\`" >> "$scratch/docs/WORKFLOW.md"
  expect "a dotfiles deployment path in the \$HOME spelling ($path) fails" 1 "dotfiles deployment path in $scratch/docs/WORKFLOW.md"
done

# the reference docs live in references/: a path naming one under the old docs/agents/ folder fails
# in a skill and in a doc, naming the file; the two docs that stay there are no reference docs
for doc in orchestration harness issue-tracker; do
  fresh
  echo "read \`<plugin root>/docs/agents/$doc.md\`" >> "$scratch/skills/sample/SKILL.md"
  expect "a skill naming $doc under docs/agents fails" 1 "reference doc under the old folder in $scratch/skills/sample/SKILL.md"
  fresh
  echo "see docs/agents/$doc.md" >> "$scratch/docs/WORKFLOW.md"
  expect "a doc naming $doc under docs/agents fails" 1 "reference doc under the old folder in $scratch/docs/WORKFLOW.md"
done
for doc in domain triage-labels; do
  fresh
  echo "read docs/agents/$doc.md" >> "$scratch/skills/sample/SKILL.md"
  echo "see docs/agents/$doc.md" >> "$scratch/docs/WORKFLOW.md"
  expect "a path to docs/agents/$doc.md is not flagged" 0
done
# accepted ADRs and past specs keep their old paths
fresh
mkdir -p "$scratch/docs/specs"
echo "see docs/agents/orchestration.md" >> "$scratch/docs/adr/0001.md"
echo "see docs/agents/harness.md" > "$scratch/docs/specs/past.md"
expect "an ADR and a spec keeping an old path pass" 0
# the sweep's other inputs fail too, naming the file (dev-7mkq.1.3)
old_msg="reference doc under the old folder in"
for rel in GLOSSARY.md CLAUDE.md README.md references/sample.md docs/agents/domain.md hooks/sample.sh; do
  fresh
  mkdir -p "$scratch/hooks" "$scratch/$(dirname "$rel")"
  echo "see docs/agents/harness.md" >> "$scratch/$rel"
  expect "$rel naming harness under docs/agents fails" 1 "$old_msg $scratch/$rel"
done
# the pattern ends at a word boundary: a longer name passes, the bare name at line end fails
fresh
printf '%s\n' "see docs/agents/harness-notes.md and docs/agents/orchestration_x.md" >> "$scratch/docs/WORKFLOW.md"
expect "a longer name after docs/agents/harness passes" 0
fresh
printf '%s\n' "see docs/agents/harness" >> "$scratch/docs/WORKFLOW.md"
expect "the bare name at line end fails" 1 "$old_msg $scratch/docs/WORKFLOW.md"
# a near-miss folder (docs/adr-notes) is still swept; only docs/adr and docs/specs are pruned
fresh
mkdir -p "$scratch/docs/adr-notes"
echo "see docs/agents/harness.md" > "$scratch/docs/adr-notes/n.md"
expect "docs/adr-notes is still swept" 1 "$old_msg $scratch/docs/adr-notes/n.md"

# the brief rule (dev-rc9): a brief block (a markdown quote, indented or not) that names the
# plugin-root variable fails with the skill and line named; the variable in a step outside a
# brief, where the skill itself resolves it, passes
brief_msg="plugin-root variable in a brief in"
pin_phrase "the harness's plugin-root variable"; plugin_root_var=$pinned_phrase
fresh
printf '%s\n' "> Read the orchestration doc, \`\${$plugin_root_var}/references/orchestration.md\`, before step 1." >> "$scratch/skills/sample/SKILL.md"
n=$(grep -n "$plugin_root_var" "$scratch/skills/sample/SKILL.md" | cut -d: -f1)
expect "the plugin-root variable in a brief block fails with the skill and line named" 1 "$brief_msg $scratch/skills/sample/SKILL.md:$n"
fresh
printf '1. Spawn the runner:\n   > You are the runner. Read $%s/references/orchestration.md first.\n' "$plugin_root_var" >> "$scratch/skills/sample/SKILL.md"
n=$(grep -n "$plugin_root_var" "$scratch/skills/sample/SKILL.md" | cut -d: -f1)
expect "the bare variable in an indented brief block fails with the skill and line named" 1 "$brief_msg $scratch/skills/sample/SKILL.md:$n"
fresh
printf '> You are the runner. Read the orchestration doc,\n${%s}/references/orchestration.md, before step 1.\n' "$plugin_root_var" >> "$scratch/skills/sample/SKILL.md"
n=$(grep -n "$plugin_root_var" "$scratch/skills/sample/SKILL.md" | cut -d: -f1)
expect "the variable on a wrapped brief line that drops the > still fails" 1 "$brief_msg $scratch/skills/sample/SKILL.md:$n"
fresh
printf '> Read the orchestration doc at the absolute path above.\n\n1. Read `${%s}/references/issue-tracker.md` before step 2.\n' "$plugin_root_var" >> "$scratch/skills/sample/SKILL.md"
expect "the plugin-root variable in a step outside a brief passes" 0

# rewrite <file under scratch> <command...>: replaces the file with the command's output on it
rewrite() { local rel=$1; shift; "$@" "$scratch/$rel" > "$scratch/$rel.new" && mv "$scratch/$rel.new" "$scratch/$rel"; }
# drop_phrase <file under scratch> <phrase> [-i]: delete every occurrence of the literal phrase
# and keep the rest of its line, so a case whose phrase shares a line with another pinned
# phrase fires its own check alone; -i ignores case
drop_phrase() {
  [ -n "$2" ] || { echo "FAIL drop_phrase: an empty phrase for $1 would drop nothing"; exit 1; }
  p="$2" ci="$([ "${3:-}" = -i ] && echo 1)" rewrite "$1" awk '{
    p = ENVIRON["p"]; ci = ENVIRON["ci"]
    out = ""; rest = $0
    while (1) {
      i = ci ? index(tolower(rest), tolower(p)) : index(rest, p)
      if (!i) break
      out = out substr(rest, 1, i - 1); rest = substr(rest, i + length(p))
    }
    print out rest
  }'
}
# swap_phrase <file under scratch> <sed regex> <replacement>: rewrite the first match on each
# line (extended regex, `|` as the delimiter so paths pass), for a case that changes a phrase
# instead of dropping it
swap_phrase() { rewrite "$1" sed -E "s|$2|$3|"; }

# drop_matching <file under scratch> <regex> [<anchor regex>]: delete every line matching the
# regex (and the anchor, when given), for a case whose pin is a pattern, not a phrase
drop_matching() {
  re="$2" an="${3:-}" rewrite "$1" awk '{ if ($0 ~ ENVIRON["re"] && (ENVIRON["an"] == "" || $0 ~ ENVIRON["an"])) next; print }'
}
# prefix_matching <file under scratch> <regex>: put a word ahead of every line matching the regex
prefix_matching() {
  re="$2" rewrite "$1" awk '{ if ($0 ~ ENVIRON["re"]) $0 = "x " $0; print }'
}
# move_to_line_end <file under scratch> <anchor regex> <phrase>: on the lines matching the anchor,
# take the phrase out of where it stands and append it to the line's end
move_to_line_end() {
  an="$2" p="$3" rewrite "$1" awk '{ if ($0 ~ ENVIRON["an"] && (i = index($0, ENVIRON["p"]))) $0 = substr($0, 1, i - 1) substr($0, i + length(ENVIRON["p"])) " " ENVIRON["p"] "." } { print }'
}
# move_to_line_start <file under scratch> <anchor regex> <phrase>: the same to the line's start
move_to_line_start() {
  an="$2" p="$3" rewrite "$1" awk '{ if ($0 ~ ENVIRON["an"] && (i = index($0, ENVIRON["p"]))) $0 = ENVIRON["p"] ". " substr($0, 1, i - 1) substr($0, i + length(ENVIRON["p"])) } { print }'
}
# swap_two <file under scratch> <anchor regex> <phrase> <phrase>: on the lines matching the anchor,
# exchange the first occurrence of each phrase, so the one that stood first stands second
swap_two() {
  an="$2" a="$3" b="$4" rewrite "$1" awk '{
    if ($0 ~ ENVIRON["an"] && (i = index($0, ENVIRON["a"])) && (j = index($0, ENVIRON["b"])) && i != j) {
      x = ENVIRON["a"]; y = ENVIRON["b"]
      if (i > j) { t = x; x = y; y = t; t = i; i = j; j = t }   # x stands first, at i; y second, at j
      $0 = substr($0, 1, i - 1) y substr($0, i + length(x), j - i - length(x)) x substr($0, j + length(y))
    }
    print }'
}
# drop_last <file under scratch> <anchor regex> <phrase>: on the lines matching the anchor, take out
# the last occurrence of the phrase and leave the others
drop_last() {
  an="$2" p="$3" rewrite "$1" awk '{
    if ($0 ~ ENVIRON["an"]) {
      p = ENVIRON["p"]; last = 0; pos = 0; rest = $0
      while ((k = index(rest, p))) { pos += k; last = pos; rest = substr(rest, k + length(p)); pos += length(p) - 1 }
      if (last) $0 = substr($0, 1, last - 1) substr($0, last + length(p))
    }
    print }'
}
# drop_first <file under scratch> <anchor regex> <phrase>: on the lines matching the anchor, take
# out the first occurrence of the phrase and leave the others
drop_first() {
  an="$2" p="$3" rewrite "$1" awk '{
    if ($0 ~ ENVIRON["an"] && (i = index($0, ENVIRON["p"]))) $0 = substr($0, 1, i - 1) substr($0, i + length(ENVIRON["p"]))
    print }'
}
# drop_second <file under scratch> <anchor regex> <phrase>: on the lines matching the anchor, take
# out the second occurrence of the phrase and leave the others
drop_second() {
  an="$2" p="$3" rewrite "$1" awk '{
    if ($0 ~ ENVIRON["an"] && (i = index($0, ENVIRON["p"])) && (k = index(substr($0, i + 1), ENVIRON["p"]))) {
      j = i + k; $0 = substr($0, 1, j - 1) substr($0, j + length(ENVIRON["p"]))
    }
    print }'
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
# round_specs <tree> <spec...>: keeps a check apart from a seeding that takes its anchor. A spec's
# record whose seeding takes another record's anchor off a line of its file under <tree>, or that
# holds an anchor a record already in the round takes, moves to the first round that has neither,
# <spec>.<round>, the seeding read as seed_pins does it: a pattern's drop takes its whole line, a
# phrase's every occurrence, a seed nothing. The anchor is read as the lint reads it: a section's is
# its whole line, a paragraph's the line's start, and a line check's a pattern.
round_specs() {
  awk -F '\t' -v tree="$1" '
    function holds(s, j) {
      return at[j] == "S" ? s == an[j] : (at[j] == "p" ? index(s, an[j]) == 1 : s ~ an[j])
    }
    # true when the seeding of record r leaves a line that held anchor j without it
    function cuts(r, j,   l, s, out, p, ci, i) {
      if (K[r] == "seed") return 0
      ci = (T[r] == "i" || T[r] == "p")
      p = ci ? tolower(P[r]) : P[r]
      for (l = 1; l <= nl[j]; l++) {
        s = held[j, l]
        if (T[r] == "e" || T[r] == "A") { if (s ~ P[r]) return 1; continue }
        out = ""
        while ((i = index(ci ? tolower(s) : s, p))) { out = out substr(s, 1, i - 1); s = substr(s, i + length(p)) }
        if (!holds(out s, j)) return 1
      }
      return 0
    }
    # the id of the anchor of record r in its spec, its lines read from the tree the first time
    function anchor(r,   key, j, s, c, path) {
      c = (T[r] == "S" || T[r] == "p") ? T[r] : "a"
      key = SP[r] SUBSEP c SUBSEP A[r]
      if (key in id) return id[key]
      j = id[key] = ++na; an[j] = A[r]; at[j] = c
      spanch[SP[r], ++nspan[SP[r]]] = j
      path = tree "/" F[r]
      while ((getline s < path) > 0) if (holds(s, j)) held[j, ++nl[j]] = s
      close(path)
      return j
    }
    # true when record r cannot join round q of its spec
    function clash(r, q,   sp, i, j) {
      sp = SP[r]
      for (i = 1; i <= nspan[sp]; i++) { j = spanch[sp, i]; if (((j, q) in taken) && cuts(r, j)) return 1 }
      if (r in own) for (i = 1; i <= size[sp, q]; i++) if (cuts(member[sp, q, i], own[r])) return 1
      return 0
    }
    { n++; SP[n] = FILENAME; REC[n] = $0; K[n] = $1; T[n] = $2; F[n] = $3; P[n] = $4; A[n] = $7 }
    END {
      for (r = 1; r <= n; r++) if (A[r] != "") own[r] = anchor(r)
      for (r = 1; r <= n; r++) {
        for (q = 0; clash(r, q); q++) ;
        member[SP[r], q, ++size[SP[r], q]] = r
        if (r in own) taken[own[r], q] = 1
        print REC[r] > (q ? SP[r] "." q : SP[r])
      }
    }' "${@:2}"
}
# seed_pins <spec>: seeds the scratch tree with every record of a spec, one case per line, tab-separated:
# <kind> <check type> <file under scratch> <phrase> <description> <message> [<anchor>] (the anchor last,
# since read collapses empty fields). A kind's records seed one tree at once: drop drops the phrase
# (drop_pin), start puts a word ahead of its lines, seed appends the phrase on a line of its own, and
# moved takes the phrase out of the doc and puts it back outside its scope: ahead of the doc for a
# section or a paragraph (the last section of a doc runs to its end), to its end for the opening or
# an anchored line (the anchor's line no longer holds it). Every moved phrase leaves before any goes
# back, so one record's drop never takes a piece out of another's moved phrase.
seed_pins() {
  local kind ptype prel pphrase pdesc pmsg panchor
  while IFS=$'\t' read -r -u 6 kind ptype prel pphrase pdesc pmsg panchor; do
    case $kind in
      drop) drop_pin "$ptype" "$prel" "$pphrase" "$panchor" ;;
      start) prefix_matching "$prel" "$pphrase" ;;
      seed) printf '\n%s\n' "$pphrase" >> "$scratch/$prel" ;;
      moved) if [ "$ptype" = p ]; then drop_phrase "$prel" "$pphrase" -i; else drop_phrase "$prel" "$pphrase"; fi ;;
    esac
  done 6< "$1"
  while IFS=$'\t' read -r -u 6 kind ptype prel pphrase pdesc pmsg panchor; do
    [ "$kind" = moved ] || continue
    if [ "$ptype" = o ] || [ "$ptype" = a ]; then printf '\n%s\n' "$pphrase" >> "$scratch/$prel"
    else { printf '%s\n\n' "$pphrase"; cat "$scratch/$prel"; } > "$scratch/$prel.new" && mv "$scratch/$prel.new" "$scratch/$prel"; fi
  done 6< "$1"
}
# --- every section: a seeded copy fails that section alone, a missing document fails naming it ---
# section_case <section> <file under scratch> <line appended> <description>
section_case() {
  fresh
  printf '%s\n' "$3" >> "$scratch/$2"
  sec=$1 expect "section ${1// / and } fails alone: $4" 1
}
ban ban_cross_repo "stale wording"
ban ban_rerun_hint "rerun hint covering an already cut dependent"
ban ban_profile_push "profile-gated push in the orchestration doc"
ban ban_three_entries "Gitignore step counts three entries"
ban ban_tea_no_repo "Forgejo/Gitea query without --repo"
ban ban_only_lines "story cut's lines contradict step 2"
ban ban_bare_grep "the bare grep instruction"
ban_nth ban_pr_step "PR-opening steps" 1
ban ban_resync "re-sync instruction"
ban_nth ban_notes_file "owner-repo notes file" 1
section_case 1 skills/implement-spec/SKILL.md "then open a $ban_pr_step" "/implement-spec with a PR step"
section_case 2 docs/WORKFLOW.md "each $ban_cross_repo gets its own PR" "a runbook with stale wording"
section_case 3 skills/spec-to-stories/SKILL.md "then $ban_resync the stories" "/spec-to-stories with a re-sync"
section_case 4 skills/spec-to-tasks/SKILL.md "then $ban_rerun_hint" "/spec-to-tasks with the retired rerun hint"
section_case 5 skills/sample/SKILL.md 'cut one' "a retired phrase in a skill"
section_case 6 references/orchestration.md "push $ban_profile_push" "an orchestration doc gating the push on the profile"
section_case 7 skills/story-to-tasks/SKILL.md "read the notes under $ban_notes_file" "/story-to-tasks reading an owner-repo notes file"
section_case 8 skills/implement-story/SKILL.md "$ban_three_entries" "/implement-story counting three Gitignore entries"
section_case 9 skills/close-story/SKILL.md "query \`$ban_tea_no_repo{owner}/{repo}/pulls/1\`" "/close-story with a Forgejo query naming no repo"
section_case 10 references/issue-tracker.md "$ban_only_lines" "a tracker doc whose story cut writes two forms only"
section_case 11 skills/sample/SKILL.md 'run /story-to-tasks next' "a bare /<skill>"
section_case 12 skills/retro/SKILL.md "$ban_bare_grep" "/retro with the bare grep instruction"
section_case 13 skills/sample/SKILL.md "> read \${$plugin_root_var}/references/orchestration.md" "the plugin-root variable in a brief"
# the inline landing merge, banned from task-orchestrator (section 16) and every skill (section 5);
# also seeds the @merge@ derivation below
landing_merge='`git -C <owner> merge <task branch>`'
section_case "5 16" skills/task-orchestrator/SKILL.md "then merge it with $landing_merge" "/task-orchestrator merging onto the owner checkout"
ban_alt ban_draft_pr "a draft PR for a standalone task"
section_case 17 skills/implement-task/SKILL.md "then run \`$ban_draft_pr\`" "/implement-task opening a draft PR"
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
pin_phrase "merge guard cites the orchestration doc's Repo plumbing and Cut-off probe for its mechanism"
printf '%s\n' "$pinned_phrase, then merge it" >> "$scratch/skills/implement-spec/SKILL.md"
sec=1 expect "the carve-out phrase beside a real merge step fails section 1" 1 "present: merge steps"
fresh
printf '%s\n' "$(tr '[:upper:]' '[:lower:]' <<<"$pinned_phrase")" >> "$scratch/skills/implement-spec/SKILL.md"
sec=1 expect "a lowercase variant of the carve-out fails section 1" 1 "present: merge steps"
fresh
printf '%s\n' "${pinned_phrase%Merge guard}Merge-guard" >> "$scratch/skills/implement-spec/SKILL.md"
sec=1 expect "a hyphenated variant of the carve-out fails section 1" 1 "present: merge steps"
# a skill's own steps and another skill named without a step number are outside the rule
fresh
printf '%s\n' 'Read `/dev:close-story` for the merge guard, then go on to step 4.' \
  'This skill has steps 1 to 4, and /dev:sample step 2 is its own.' >> "$scratch/skills/sample/SKILL.md"
sec=5 expect "own steps and a step-free skill name pass section 5" 0
# a reference doc is swept too: a skill's step number cited there fails (dev-90up)
fresh
printf '%s\n' 'the forge query, as `/dev:close-story` step 4 does' >> "$scratch/references/sample.md"
sec=5 expect "a reference doc citing a skill's step number fails section 5 with its message" 1 "another skill's step number cited in $scratch/references/sample.md"

# a section's document gone: the section fails naming it, never skips; a reference doc that two
# sections read fails both
for case in '1 skills/implement-spec/SKILL.md' '2 skills/workflow/SKILL.md' '2 docs/WORKFLOW.md' \
  '3 skills/spec-to-stories/SKILL.md' '4 skills/spec-to-tasks/SKILL.md' '6 10 references/orchestration.md' \
  '6 references/harness.md' '6 10 references/issue-tracker.md' '6 skills/setup-repo/SKILL.md' '7 skills/story-to-tasks/SKILL.md' '8 skills/implement-story/SKILL.md' \
  '9 skills/close-story/SKILL.md' '6 skills/triage/SKILL.md' '12 skills/retro/SKILL.md' '16 skills/task-orchestrator/SKILL.md' '17 skills/implement-task/SKILL.md' '18 .claude/rules/cross-skill-cites.md' '0 CLAUDE.md' '0 GLOSSARY.md'; do
  doc=${case##* }
  fresh
  rm "$scratch/$doc"
  msg="missing document: $scratch/$doc"
  case $doc in CLAUDE.md|GLOSSARY.md) msg="no such file: $scratch/$doc" ;; esac
  sec=${case% *} expect "a missing $doc fails naming it" 1 "$msg"
done

# a renamed skill or reference doc turns the lint red naming the document its section reads, rather
# than turning that section off
fresh
mv "$scratch/skills/retro" "$scratch/skills/retrospective"
expect "a renamed skill directory fails naming its missing document" 1 "missing document: $scratch/skills/retro/SKILL.md"
fresh
mv "$scratch/references/orchestration.md" "$scratch/references/orchestrator.md"
expect "a renamed reference doc fails naming its missing document" 1 "missing document: $scratch/references/orchestration.md"
# a reference doc back in the old folder is no reference doc: the lint reads references/ alone
for doc in orchestration harness issue-tracker; do
  fresh
  mv "$scratch/references/$doc.md" "$scratch/docs/agents/$doc.md"
  expect "a reference doc under docs/agents and not references/ fails as a missing document" 1 "missing document: $scratch/references/$doc.md"
done

# --- hand-written cases of absent phrases and rules; the drop case of each pinned phrase is derived below ---
sec=one

fresh
echo "next: /dev:spec-to-tikets <KEY>-<n>" >> "$scratch/skills/workflow/SKILL.md"
expect "misspelt command in /dev:workflow fails" 1

fresh
echo 'git -C <owner> commit -m "chore: x" --trailer "Bead: <story-id>"' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story committing with --trailer fails" 1

fresh
echo 'a commit never takes `--trailer`; the message file carries the trailers' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story naming --trailer in prose passes" 0

fresh
ban ban_lands_itself "a task orchestrator landing its own task in the runbook"
echo "each task orchestrator $ban_lands_itself" >> "$scratch/docs/WORKFLOW.md"
sec=2 expect "a runbook task orchestrator landing its task fails" 1 "a task orchestrator landing its own task in the runbook"

fresh
ban ban_medium_high_only "the runbook's task review limited to medium and high"
echo "at the task $ban_medium_high_only on both axes" >> "$scratch/docs/WORKFLOW.md"
expect "runbook copy limiting the task review to medium and high fails" 1 "the runbook's task review limited to medium and high"

# every implementer and reviewer brief at the task and story rows names both rules folders, the
# personal ~/.claude/rules/ and the repo's .claude/rules/ (ADR 0018, dev-7mkq.1.6): one brief
# missing either folder fails its own pin and no sibling brief's on its line (the ;-list of
# descriptions after the folder). drop_first, drop_second and drop_last take the folder out of
# the first, second or last brief on the anchored line, where the task row's step 3 holds the
# spec reviewer's, the standards reviewer's and then a fix-up's brief
spec_d='the task spec reviewer brief leaves both rules folders to the standards reviewer'
std_d='the task standards reviewer brief names both rules folders and the breach form'
fix_d='the task fix-up brief names both rules folders'
srev_d='the story review brief names both rules folders and the breach form'
sfix_d='the story fix-up brief names both rules folders'
for folder in '`~/.claude/rules/`' '`<owner>/.claude/rules/`'; do
  for c in "first|$spec_d|task-orchestrator|$std_d;$fix_d" \
    "second|$std_d|task-orchestrator|$spec_d;$fix_d" \
    "last|$fix_d|task-orchestrator|$spec_d;$std_d" \
    "last|the task implementer brief names both rules folders|task-orchestrator|" \
    "first|$srev_d|implement-story|$sfix_d" \
    "last|$sfix_d|implement-story|$srev_d" \
    "last|the conflict implementer brief names both rules folders|implement-story|"; do
    IFS='|' read -r which desc skill siblings <<<"$c"
    pin_anchor "$desc"
    fresh
    "drop_$which" "skills/$skill/SKILL.md" "$pinned_anchor" "$folder"
    must_not_print=${siblings//;/$'\n'} expect "$skill: a brief without $folder fails '$desc'" 1 "$desc"
  done
done

# one has-a-database rule: .beads/ exists and bd where names it, stated once in the tracker doc
# and cited by every gate; a gate testing only that .beads/ exists fails the sweep (dev-e87)
fresh
printf '%s\n' 'Before any `bd` call, check `test -d <home>/.beads`.' >> "$scratch/skills/close-epic/SKILL.md"
sec=5 expect "a gate testing only that .beads exists fails" 1 "present: an existence-only beads database gate in $scratch/skills/close-epic/SKILL.md"

fresh
printf '%s\n' '   owner other than `<home>` with no `.beads/` → say so.' 'No `<home>/.beads` → say so' >> "$scratch/skills/triage/SKILL.md"
sec=5 expect "a gate worded as a missing .beads fails" 1 "present: an existence-only beads database gate in $scratch/skills/triage/SKILL.md"

fresh
printf '%s\n' 'in every manifest repo with `.beads/` (the same guard)' >> "$scratch/references/issue-tracker.md"
sec=5 expect "a sweep guarded on .beads alone fails" 1 "present: an existence-only beads database gate in $scratch/references/issue-tracker.md"

fresh
ban ban_cannot_take_c "the retired bd init -C wording in $scratch/skills/sample/SKILL.md"
echo "\`bd init\` $ban_cannot_take_c, so give the user the command." >> "$scratch/skills/sample/SKILL.md"
expect "a skill saying bd init cannot take -C fails" 1 "the retired bd init -C wording"

# the Land script and the stray-commit script own the landing's merge and the stray-commit git log
# (ADR 0017), so no skill doc types either inline (dev-skn5.1.5); the reference docs may name them
for typed in '`git -C <owner> merge --no-edit <task branch>`' '`git -C <owner> merge --ff-only <task branch>`' '`git merge <task branch>`' '`git merge <task-branch>`'; do
  fresh
  echo "Then merge it with $typed." >> "$scratch/skills/sample/SKILL.md"
  expect "a skill typing $typed fails" 1 "an inline landing merge in $scratch/skills/sample/SKILL.md"
done
fresh
echo "Check \`git -C <owner> log --no-merges --format='%H' <branch>..<task branch>\` for strays." >> "$scratch/skills/sample/SKILL.md"
expect "a skill typing the stray-commit git log fails" 1 "the inline stray-commit git log in $scratch/skills/sample/SKILL.md"
fresh
echo "The Land script runs git merge <task branch> for you, and git log <branch>..<task branch> its check." >> "$scratch/skills/sample/SKILL.md"
echo "Done when \`git -C <owner> merge-base --is-ancestor <task branch> <branch>\` exits 0; \`git -C <owner> merge --abort\` first." >> "$scratch/skills/sample/SKILL.md"
echo 'A `git merge <task branch>` that applies is a command, and `git -C <owner> log <branch>..<task branch>` its check.' >> "$scratch/references/sample.md"
expect "merge-base and merge --abort in a skill, and the typed commands in the reference docs, pass" 0

# the two-wave cap is a pattern with an optional word: its instances, as the skill might word them
for phrase in 'in at most two dependency waves' 'in at most two waves'; do
  fresh
  echo "x $phrase y" >> "$scratch/skills/spec-to-tasks/SKILL.md"
  sec=4 expect "spec-to-tasks saying '$phrase' fails" 1
done
# the ban is on the cap, not on the words: two waves named without a cap pass, and so does
# "at most two" about anything but waves
for phrase in 'a chain of two waves' 'at most two tasks'; do
  fresh
  echo "x $phrase y" >> "$scratch/skills/spec-to-tasks/SKILL.md"
  expect "spec-to-tasks saying '$phrase' passes" 0
done

# a lock wait by hand, as a skill might word it (the pattern is a regex of alternatives)
for phrase in 'waits 10 seconds and checks again' 'waits 15 seconds and retries' 'sleeps, then re-checks the lock' 'checks every 10 seconds'; do
  fresh
  echo "so it $phrase, for up to 5 minutes" >> "$scratch/skills/implement-story/SKILL.md"
  expect "implement-story whose lock wait '$phrase' by hand fails" 1
done

fresh
echo 'a locked one is removed with `git -C <owner> worktree remove <absolute path> --force`' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story forcing a locked worktree fails" 1

fresh
echo 'a locked one is removed with `git -C <owner> worktree remove -f -f <absolute path>`' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story forcing a locked worktree with -f fails" 1

fresh
echo 'Step 8 writes it: see `/dev:implement-story` step 8.' >> "$scratch/skills/implement-spec/SKILL.md"
sec=5 expect "implement-spec pointing at /dev:implement-story step 8 fails" 1 "another skill's step number cited in"

fresh
echo 'Evidence is recorded by `/dev:implement-story` step 7.' >> "$scratch/skills/implement-spec/SKILL.md"
sec=5 expect "implement-spec pointing at /dev:implement-story step 7 fails" 1 "another skill's step number cited in"

fresh
echo 'The wait is `/dev:implement-story` step 8.' >> "$scratch/references/harness.md"
sec=5 expect "harness doc pointing at /dev:implement-story step 8 fails" 1 "another skill's step number cited in"

fresh
pin_phrase "step 3 pointing at step 8's stray-commit check"
pin_anchor "step 3 pointing at step 8's stray-commit check"
swap_phrase skills/implement-story/SKILL.md "($pinned_anchor.*)$" "\\1 Run $pinned_phrase."
expect "implement-story step 3 pointing at step 8's stray-commit check fails" 1 "present: step 3 pointing at step 8's stray-commit check"

fresh
pin_phrase "the heredoc failure"
swap_phrase references/harness.md "$pinned_phrase" 'here-document'
printf '\nA %s elsewhere in the doc.\n' "$pinned_phrase" >> "$scratch/references/harness.md"
expect "harness doc whose TMPDIR rule names no heredoc fails" 1

section_case 6 references/orchestration.md 'At the epic row it is `failed: <story-id> checks failed after three fix-ups`' "a Check gate allowing a third epic-row fourth-failure line"

fresh
swap_phrase references/orchestration.md '`/.worktrees/`, `/.spec-notes/` and `/.tmp/`' '`/.tmp/`, `/.worktrees/` and `/.spec-notes/`'
expect "orchestration doc listing /.tmp/ first among the Gitignore entries passes" 0

fresh
pin_phrase "commit example: the Bead trailer line"
line=$pinned_phrase rewrite references/harness.md awk '{ print } $0 == ENVIRON["line"] { print "" }'
expect "harness doc whose commit example has a blank line among its trailers fails" 1 "no blank line between the commit example's trailers"

fresh
mv "$scratch/references/harness.md" "$scratch/references/harness-gone.md"
expect "a missing harness doc fails naming it" 1 "missing document: $scratch/references/harness.md"

# the tracker and orchestration docs speak of the story DAG and the human gate task, and
# no longer say a feature has one text blocker or that chains are out of scope (ADR 0011)
for doc in issue-tracker orchestration; do
  fresh
  printf 'Chains (A depends on B depends on C) are also\nout of scope.\n' >> "$scratch/references/$doc.md"
  expect "$doc doc putting chains out of scope across a line break fails" 1
  # the match is bounded, so "chains" and an unrelated "out of scope" paragraphs apart pass
  fresh
  printf '%s\n\n%s\n%s\n' 'Chains of stories are cut in one topological pass' \
    '- every story is created after each story it waits on, in its owner repo database' \
    '- a dependency pinned by git tag is out of scope' >> "$scratch/references/$doc.md"
  expect "$doc doc with chains and an unrelated out of scope paragraphs apart passes" 0
done

# the task cut orders one pass per story, so every bump precedes the dependent's other
# tasks; the story cut writes a story line or a publish placeholder, never a gate task id
fresh
pin_phrase "task cut ordered per story"
swap_phrase references/issue-tracker.md "$pinned_phrase" "${pinned_phrase% *}"
expect "tracker doc whose task cut pass is not per story fails" 1

# the stories are listed with the dependent after the dependency, not dependency first
fresh
echo 'The dependency first publishes its crate, then the dependent bumps.' >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories saying dependency first outside the list order passes" 0

# a skipped closure is no invented line (the pattern holds parentheses)
fresh
ban ban_invented_closure "invented closure line on a skipped story"
echo "written \`<repo> ${ban_invented_closure//\\/}\`" >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories with an invented skipped-closure line fails" 1

# a PR closed unmerged is refused as /dev:implement-story's merge guard refuses it (story review 1)
fresh
ban_nth ban_unsealed "a PR closed unmerged takes OPEN's path" 1
echo "- A PR $ban_unsealed: it takes \`OPEN\`'s path." >> "$scratch/skills/spec-to-stories/SKILL.md"
expect "spec-to-stories re-cutting a story whose PR closed unmerged fails" 1

phase "hand-written cases ahead of the derived ones"
# every kind of check the lint queues is named here: a positive one gets a drop case, a lacksf one
# its phrase seeded, an absent-phrase one (x y w W X) each plain text it bans seeded; a kind named
# nowhere fails, so a new one cannot go without a case; uncovered_pins reads absent_types too
pos_types=" i c e a A p S o "
seed_types=" f "
absent_types=" x y w W X "
moved_types=" a S p o "
npins=0 nmoved=0 nanch=0 nabsent=0 nbatches=0 nretried=0
# pin_case <kind> <round> <check type> <file under scratch> <phrase> <description> <message> [<anchor>]:
# puts a derived case in its batch, the tree it shares with the cases of its kind, file and round
pin_case() {
  local spec=$jobs/batch.$1.${4//\//_}.$2
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$3" "$4" "$5" "$6" "$7" "${8:-}" >> "$spec"
}
# the list as the loop below reads it, one line per case: <type> <file> <description> <phrase> <text>
# [<anchor>], <text> "+" for a positive check or a line the loop must refuse, else one banned text per
# line (a plain alternative of the phrase). One case per banned text and file; a sweep over many
# files (w W) is seeded in every file it names; a file dropped from a sweep leaves the list a case
# short, which sweeps_gaps below catches from the tree. Most of the list's lines ban no plain text,
# so this pass is what spares the loop them.
absent_types=$absent_types pre=$scratch/ awk -F '\t' -v OFS='\t' -v pristine="$pristine" "$alts_fn"'
  function exists(f,   line) { if (!(f in ex)) { ex[f] = ((getline line < f) >= 0); close(f) } return ex[f] }
  {
    rel = (index($2, ENVIRON["pre"]) == 1) ? substr($2, length(ENVIRON["pre"]) + 1) : ""
    if (!index(ENVIRON["absent_types"], " " $1 " ") || rel == "" || $3 == "" || $4 == "" || !exists(pristine "/" rel)) {
      print $1, $2, $3, $4, "+", $5; next }
    n = alts($1, $4)
    for (i = 1; i <= n; i++) {
      if (($1, rel, A[i]) in seen) continue
      seen[$1, rel, A[i]]
      print $1, $2, $3, $4, A[i], $5
    }
  }' "$jobs/pins.list" > "$jobs/pins.derive"
last_pin= round=0
while IFS=$'\t' read -r -u 4 ptype pfile pdesc pphrase alt panchor; do
  prel=${pfile#"$scratch"/}
  if [ "$prel" = "$pfile" ] || [ ! -f "$pristine/$prel" ] || [ -z "$pdesc" ] || [ -z "$pphrase" ]; then
    echo "FAIL pin list: '$pdesc' ($pphrase) names no file under the scratch tree: $pfile"
    fails=$((fails+1)); continue
  fi
  if [[ $absent_types == *" $ptype "* ]]; then
    nabsent=$((nabsent+1))
    desc="absent $nabsent: $prel with '$alt' seeded fails '$pdesc'"
    # line_lacks prints no hits to tell whose seed fired it, so its cases each take a tree
    if [ "$ptype" = X ]; then
      fresh
      append_to_matching "$prel" "$panchor" "$alt"
      sec= expect "$desc" 1 "present: $pdesc ("
      continue
    fi
    # a check's alternatives go in rounds, one to a tree, so each is seen to fire it
    if [ "$ptype|$pfile|$pdesc" = "$last_pin" ]; then round=$((round+1)); else round=0 last_pin="$ptype|$pfile|$pdesc"; fi
    pin_case seed "$round" "$ptype" "$prel" "$alt" "$desc" "present: $pdesc ($pphrase)"
    continue
  fi
  case $pos_types$seed_types in *" $ptype "*) ;;
    *) echo "FAIL pin list: '$pdesc' is a check of kind '$ptype', which this test has no drop case for"; fails=$((fails+1)); continue ;;
  esac
  npins=$((npins+1))
  if [[ $seed_types == *" $ptype "* ]]; then   # a lacksf: the phrase seeded into the doc fails it
    pin_case seed 0 "$ptype" "$prel" "$pphrase" "pin $npins: $prel with '$pdesc' seeded fails" "present: $pdesc ($pphrase)"
    continue
  fi
  pin_case drop 0 "$ptype" "$prel" "$pphrase" "pin $npins: $prel without '$pdesc' fails" ": $pdesc ($pphrase" "$panchor"
  # a pattern pinned to the start of a line fails once its lines start with another word
  if [ "$ptype" = e ] && [ "${pphrase:0:1}" = '^' ]; then
    nanch=$((nanch+1))
    pin_case start 0 "$ptype" "$prel" "$pphrase" "pin $npins: $prel with '$pdesc' no longer at the start of its line fails" ": $pdesc ($pphrase"
  fi
  # a pinned phrase moved out of its scope still fails
  if [[ $moved_types == *" $ptype "* ]]; then
    nmoved=$((nmoved+1))
    pin_case moved 0 "$ptype" "$prel" "$pphrase" "pin $npins: $prel with '$pdesc' moved out of its scope fails" ": $pdesc ($pphrase" "$panchor"
  fi
done 4< "$jobs/pins.derive"
# each batch is one seeded tree and one lint run, where the cases alone would cost hundreds. A
# queued check reads one file, its phrase in its anchor's scope, so a neighbour's seeding fires it
# only through that phrase or that scope, and a batch's ok line says a drop of the case's own fires
# it on these conditions. A neighbour that takes the check's anchor would fire it with the case's
# own drop lost, so round_specs keeps the two to separate trees. A neighbour can still take the
# check's phrase, or empty a line of its paragraph, which closes the paragraph early; that leaves
# the case's own drop unseen, so the ok line then rests on drop_pin reading a phrase as the check
# does, every occurrence, with no tree of its own to show it. A case the output does not vouch for
# runs alone (judge_batch)
round_specs "$pristine" "$jobs"/batch.*
for batch_spec in "$jobs"/batch.*; do
  fresh
  seed_pins "$batch_spec"
  nbatches=$((nbatches+1))
  sec= batch=$batch_spec expect "batch ${batch_spec##*/batch.}" 1
done
expect_flush all
# a case its batch could not vouch for (judge_batch) runs alone and decides for itself
cat "$jobs"/*.retry > "$jobs/retries" 2>/dev/null
while IFS= read -r -u 4 record; do
  nretried=$((nretried+1))
  printf '%s\n' "$record" > "$jobs/retried"
  IFS=$'\t' read -r _ _ _ _ pdesc pmsg _ <<<"$record"
  fresh
  seed_pins "$jobs/retried"
  sec= expect "$pdesc" 1 "$pmsg"
done 4< "$jobs/retries"
phase "derived cases"
# judge_batch alone, on a made-up spec and lint output: what it cannot vouch for goes to the retry
# file and never to an ok line
judge_batch_gives() { # <expected ok lines, |-joined> <expected retried descriptions, |-joined> <lint rc>
  local oks retried
  rm -f "$jobs/judged.retry"
  oks=$(BATCH_RETRY=$jobs/judged.retry judge_batch "$jobs/judged.spec" "$(cat "$jobs/judged.lint")$nl$3" | sed 's/^ok   //' | paste -sd '|' -)
  retried=$(cut -f5 "$jobs/judged.retry" 2>/dev/null | paste -sd '|' -)
  [ "$oks" = "$1" ] && [ "$retried" = "$2" ]
}
printf '%s\t%s\t%s\t%s\t%s\t%s\t\n' \
  drop c a.md phrase-one 'dropped pin' ': one (phrase-one' \
  drop c a.md phrase-two 'silent pin' ': two (phrase-two' \
  seed f a.md seed-one 'seed shown' 'present: three (p3)' \
  seed f a.md seed-two 'seed masked' 'present: four (p4)' > "$jobs/judged.spec"
printf '%s\n' '== 6. a' 'FAIL: missing: one (phrase-one)' 'FAIL: present: three (p3)' '12:seed-one' \
  'FAIL: present: four (p4)' '14:seed-one' '== 7. b' > "$jobs/judged.lint"
fx_check "a batch vouches for a fired check and a seed shown under its own check, and retries the rest" \
  judge_batch_gives 'dropped pin|seed shown' 'silent pin|seed masked' 1
fx_check "a batch whose lint did not end 1 vouches for nothing" \
  judge_batch_gives '' 'dropped pin|silent pin|seed shown|seed masked' 124

# round_specs alone, on a made-up tree and spec: a check whose anchor a neighbour's seeding takes
# away would fire with its own drop lost, so the two never share a tree
mkdir "$jobs/rounds"
printf '%s\n' '3. **Gate**, every tier: a pin' '## Landing' 'a pin of the section' '**Check.** a para pin' > "$jobs/rounds/a.md"
round_specs_gives() { # <descriptions left in the tree, |-joined> <moved to its next round, |-joined> <records...>
  local left moved want_left=$1 want_moved=$2
  shift 2
  rm -f "$jobs/judged.spec.0"*
  printf '%s\n' "$@" > "$jobs/judged.spec.0"
  round_specs "$jobs/rounds" "$jobs/judged.spec.0"
  left=$(cut -f5 "$jobs/judged.spec.0" | paste -sd '|' -)
  moved=$(cut -f5 "$jobs/judged.spec.0.1" 2>/dev/null | paste -sd '|' -)
  [ "$left" = "$want_left" ] && [ "$moved" = "$want_moved" ]
}
# rec <kind> <check type> <phrase> <description> [<anchor>]: a spec record on a.md
rec() { printf '%s\t%s\ta.md\t%s\t%s\t: %s\t%s' "$1" "$2" "$3" "$4" "$4" "${5:-}"; }
fx_check "a phrase equal to a neighbour's anchor takes the next round" round_specs_gives 'anchored|plain' 'cutter' \
  "$(rec drop S 'a pin of the section' anchored '## Landing')" "$(rec drop c '## Landing' cutter)" "$(rec drop c 'plain' plain)"
fx_check "a phrase containing a neighbour's anchor takes the next round" round_specs_gives 'anchored' 'cutter' \
  "$(rec drop p 'para pin' anchored '**Check.**')" "$(rec drop c '**Check.** a para' cutter)"
fx_check "a phrase holding a piece of a neighbour's anchor takes the next round" round_specs_gives 'anchored' 'cutter' \
  "$(rec drop a 'every tier' anchored '^3\. \*\*Gate\*\*')" "$(rec drop c '**Gate**' cutter)"
fx_check "a check's anchor keeps out a phrase already in the tree" round_specs_gives 'cutter' 'anchored' \
  "$(rec drop c '**Gate**' cutter)" "$(rec drop a 'every tier' anchored '^3\. \*\*Gate\*\*')"
fx_check "a phrase dropped case-blind is read case-blind" round_specs_gives 'anchored' 'cutter' \
  "$(rec drop p 'para pin' anchored '**Check.**')" "$(rec drop i '**CHECK.**' cutter)"
fx_check "a pattern's drop takes its whole line" round_specs_gives 'anchored' 'cutter' \
  "$(rec drop a 'every tier' anchored '^3\. ')" "$(rec drop e 'Gate' cutter)"
fx_check "a phrase off the anchor's line stays in the tree" round_specs_gives 'anchored|plain' '' \
  "$(rec drop a 'every tier' anchored '^3\. ')" "$(rec drop c 'a para pin' plain)"
fx_check "a seed cuts nothing" round_specs_gives 'anchored|seeded' '' \
  "$(rec drop a 'every tier' anchored '^3\. ')" "$(rec seed f '3. **Gate**' seeded)"

# the pin tables under scripts/, one list for every loop over them
pin_tables="implement-spec-pins repo-plumbing-pins"
# the derivation must have found the pins it derives from: the list holds a pin for every row of
# each pin table, so a table whose pins_from call is lost gets no drop case and fails here
guard=1
for table in $pin_tables; do
  read -r found want < <(awk -F '\t' 'NR == FNR { if ($0 !~ /^#/ && NF >= 3) want[$2]; next }
    $3 in want { got[$3] } END { for (k in want) w++; for (k in got) g++; print g + 0, w + 0 }' "$repo_root/scripts/$table.tsv" "$jobs/pins.list")
  if [ "$want" -eq 0 ] || [ "$found" -ne "$want" ]; then
    echo "FAIL pin list holds $found of the $want rows of $table.tsv"; fails=$((fails+1)); guard=0
  fi
done
# the two pins the lint names in shared variables (dev-0xhd) must be queued too, so each gets a drop
# case: a phrase in field 4 of the list, whatever its check
for pin in 'every owner repo has a `check`' '`git -C <owner> rev-parse --show-toplevel`'; do
  awk -F '\t' -v p="$pin" '$4 == p { n++ } END { exit n ? 0 : 1 }' "$jobs/pins.list" || { echo "FAIL pin list lacks the named pin '$pin'"; fails=$((fails+1)); guard=0; }
done
if [ "$npins" -gt 0 ] && [ "$nmoved" -gt 0 ] && [ "$nanch" -gt 0 ] && [ "$nabsent" -gt 0 ] && [ "$guard" = 1 ]; then
  echo "ok   $npins pin cases derived from the lint's list ($nmoved also moved out of their scope, $nanch also off the start of their line), $nabsent more seeding a banned text, in $nbatches lint runs and $nretried alone"
else
  echo "FAIL no pin case was derived from the lint's list ($npins pins, $nmoved moved, $nanch anchored, $nabsent banned texts)"; fails=$((fails+1))
fi

# the batches are what keep this test's minutes down: a derived case that takes to running alone
# passes as before, so its cost is caught here
# measured on this tree: 2671 cases in 360 runs, 7.4 a run and none alone (a run per ten cases, the
# old bound, no longer holds since every sweep ban is seeded in every file it names); the bound is
# six, and a case run alone is the cost to catch first, so those get a bound of their own
fx_check "the derived cases share their lint runs (under one run per six cases)" \
  test "$(( (nbatches + nretried) * 6 ))" -lt "$((npins + nmoved + nanch + nabsent))"
fx_check "no derived case takes to running alone (under one in a hundred)" \
  test "$(( nretried * 100 ))" -lt "$((npins + nmoved + nanch + nabsent))"

# the sweeps' files, expected by this test and not read back from the lint: a pin list that
# lacks a file from a sweep would derive no case for it, so the list is checked against the files
# the sweeps are documented to read (section 5: every file under the reference docs, docs/agents and the skills,
# CLAUDE.md, the runbook and the sequence diagrams, GLOSSARY.md also for the two-gate pins). A
# w/W description that names one of the three top-level files is a sweep, and sweeps_gaps prints
# one line for each file of the expected set it lacks, or that it reads beyond it. It sees only the
# sweeps the list shows in one of those three top-level files: a sweep seeded in none of them (the
# step-number sweeps) is checked by loop_gaps below
# sweeps_gaps <pin list>
sweeps_gaps() {
  { (cd "$pristine" && find references docs/agents skills -type f; printf '%s\n' CLAUDE.md docs/WORKFLOW.md docs/SEQUENCES.md) | sed 's/^/E\t/'
    awk -F '\t' -v pre="$scratch/" '$1 == "w" || $1 == "W" {
      f = substr($2, length(pre) + 1); d = $3; s = " in " $2
      if (substr(d, length(d) - length(s) + 1) == s) d = substr(d, 1, length(d) - length(s))
      print "G\t" f "\t" d }' "$1"; } | awk -F '\t' '
    $1 == "E" { want[$2]; next }
    { got[$3, $2]; desc[$3]
      if ($2 ~ /^(CLAUDE\.md|docs\/WORKFLOW\.md|docs\/SEQUENCES\.md)$/) sweep[$3] }
    END { for (d in sweep) {
      for (f in want) if (!((d, f) in got)) print "FAIL sweep \"" d "\" does not name " f
      for (k in got) { split(k, p, SUBSEP); if (p[1] == d && !(p[2] in want) && p[2] != "GLOSSARY.md") print "FAIL sweep \"" d "\" names " p[2] } } }'
}
sweeps=$(sweeps_gaps "$jobs/pins.list")
fx_check "every sweep names every file under the reference docs, docs/agents and the skills, CLAUDE.md, the runbook and the sequence diagrams" test -z "$sweeps"
# pin_list_report <gaps function> <pins file> [<suffix>]: prints what the gaps function reports for
# the pin list the lint writes to <pins file> on a fresh tree (its argument is <pins file><suffix>)
pin_list_report() {
  fresh
  pin_list_run "$2" > /dev/null
  "$1" "$2${3:-}"
}
# with_dropped_lint <name> <file> <sed address> <sed substitution> <command...>: runs the command in
# this shell with $lint a copy of the lint whose sed edit (the address and substitution that drop
# <file> from the loop <name> in the lint) has been applied, and puts $lint back, with what the
# command prints in $dropped (the command runs in a subshell, so what it sets, as fresh and
# lint_scratch do, does not reach this shell); the case "the copy drops <file> from <name>" fails
# when the edit leaves the copy as the lint (the lint's own list cannot vouch for the files it was
# built from, so each drop is a lint copy)
with_dropped_lint() {
  local name=$1 file=$2 addr=$3 sub=$4 saved=$lint copy
  shift 4
  mkdir -p "$jobs/lintcopy"
  copy=$jobs/lintcopy/lint-${name// /-}.sh
  sed "$addr $sub" "$lint" > "$copy"
  chmod +x "$copy"
  fx_check "the copy drops $file from $name" bash -c '! cmp -s "$1" "$2"' _ "$lint" "$copy"
  lint=$copy
  dropped=$("$@")
  lint=$saved
}
# a copy of the lint with one file dropped from the section-5 sweep: its list lacks that file, so
# the check above must report it
with_dropped_lint "one sweep" skills/retro/SKILL.md '/SEQUENCES.md" "${1:-}"/' \
  's#| sort -u | drop_unchanged)$#| grep -v "/retro/SKILL.md" | sort -u | drop_unchanged)#' \
  pin_list_report sweeps_gaps "$jobs/pins.dropped"
fx_check "a file dropped from a sweep in a copy of the lint is reported" \
  bash -c '[ -n "$1" ] && ! grep -v "does not name skills/retro/SKILL\.md\$" <<<"$1" | grep -q .' _ "$dropped"

# the other loops over several files (dev-5wpr): each loop's files are expected here from the tree,
# not read back from the lint, and a seed in each file is linted once, so a file the lint's loop
# misses leaves its seed unreported. The loops: the section-5 step-number sweep, the dotfiles-
# deployment lacks loop, the section-11 namespace rule, the section-13 brief rule, the section-15
# mermaid list, the section-18 cite loop and the section-18 cache-invalidation loop (further down,
# since it needs no seed in a file). The section-18 cite-target pass and the skill-name list
# (skill_names, built in section 5) read every SKILL.md but no seed, so they are checked further
# down by the cite key they leave. The section-10 two-file loop is hand-picked and needs no guard
# here: a file dropped from it loses the section-10 pins its cases already seed. loop_facts holds
# each loop's facts in one table.
# drop_file is the file the loop cases below (the six loops and the cache-invalidation loop) drop in
# a copy of the lint, and @DROPPED@ in a sed substitution is its path from the skills dir. The
# cite-target and skill-name cases drop skills/retro/SKILL.md instead, a second skill so the two
# kinds of drop are not both of close-story
drop_file=skills/close-story/SKILL.md
# loop_facts <step|dotfiles|ns|brief|mermaid|cite>: sets, for that loop, loop_files (the files it is
# documented to read, from the pristine tree), loop_seed (the seed appended to each, @OTHER_SKILL@ a
# skill other than the file's own and @HEADING@ a heading of it), loop_message (the lint's message
# for the seed in file @FILE@) and loop_sed_addr and loop_sed_sub (the sed edit that drops
# $drop_file from the loop in a copy)
loop_facts() {
  loop_sed_sub='s#| sort -u | drop_unchanged)$#| grep -v "/@DROPPED@" | sort -u | drop_unchanged)#'
  case $1 in
    step)
      loop_files=$(cd "$pristine" && find references docs/agents skills -type f | sort -u)
      loop_seed='See /dev:@OTHER_SKILL@ step 3.'
      loop_message="another skill's step number cited in $scratch/@FILE@"
      loop_sed_addr='/SEQUENCES.md" "${1:-}"/' ;;
    dotfiles)
      loop_files=$(cd "$pristine" && { find docs -type f -name '*.md'; find references docs/agents skills -type f; echo CLAUDE.md; } | sort -u)
      loop_seed='Install to ~/.claude/docs.'
      loop_message="dotfiles deployment path in $scratch/@FILE@"
      loop_sed_addr='/done < <(sweep_files | grep/' ;;
    ns)
      loop_files=$(cd "$pristine" && { find docs skills -type f -name '*.md'; echo CLAUDE.md; echo GLOSSARY.md; } | sort -u)
      loop_seed='Run /story-to-tasks.'
      loop_message="bare or unknown skill namespace in $scratch/@FILE@"
      loop_sed_addr='/echo "$runbook"; echo "$user_claude_md"/'
      loop_sed_sub='s#| grep \. | sort -u \\$#| grep . | grep -v "/@DROPPED@" | sort -u \\#' ;;
    brief)
      loop_files=$(cd "$pristine" && find skills -type f -name '*.md' | sort -u)
      loop_seed='> read ${CLAUDE_PLUGIN_ROOT}/references/orchestration.md'
      loop_message="plugin-root variable in a brief in $scratch/@FILE@:"
      loop_sed_addr='/unchanged_file || brief_files+=/'
      loop_sed_sub='s#unchanged_file || brief_files+=("$f")#unchanged_file || [ "${f%/@DROPPED@}" != "$f" ] || brief_files+=("$f")#' ;;
    mermaid)
      loop_files=$(cd "$pristine" && { find docs skills -type f -name '*.md'; echo CLAUDE.md; echo GLOSSARY.md; } | sort -u)
      loop_seed=$'```mermaid\nsequenceDiagram\nA->>B: one; two\n```'
      loop_message="a semicolon in a mermaid block in $scratch/@FILE@"
      loop_sed_addr='/echo "$glossary_md"; } | sort/' ;;
    cite)
      loop_files=$(cd "$pristine" && { find references docs/agents -maxdepth 1 -type f -name '*.md'; find skills -mindepth 2 -maxdepth 2 -name SKILL.md; } | sort -u)
      loop_seed='As the @HEADING@ step of `/dev:@OTHER_SKILL@` says.'
      loop_message="a bare cite of /dev:@OTHER_SKILL@ in $scratch/@FILE@"
      loop_sed_addr='\#for f in "$refs"/\*.md#'
      loop_sed_sub='s#"$skills"/\*/SKILL.md; do$#"$skills"/*/SKILL.md; do [ "${f%/@DROPPED@}" = "$f" ] || continue#' ;;
  esac
  loop_sed_sub=${loop_sed_sub//@DROPPED@/${drop_file#skills/}}
}
# loop_other <file>: prints a skill that is not the file's own and a heading of it, tab-separated
loop_other() {
  case $1 in
    skills/close-story/*) printf '%s\t%s\n' implement-story Landing ;;
    *) printf '%s\t%s\n' close-story 'The forge shows MERGED' ;;
  esac
}
# loop_gaps <loop>: one line for each file of that loop's expected set that the lint run in $lint
# does not report its seed in, from a tree that seeds each file of the set
loop_gaps() {
  local f text msg out other heading expect=()
  loop_facts "$1"
  fresh
  while IFS= read -r f; do
    IFS=$'\t' read -r other heading <<<"$(loop_other "$f")"
    text=${loop_seed//@OTHER_SKILL@/$other}
    printf '\n%s\n' "${text//@HEADING@/$heading}" >> "$scratch/$f"
    msg=${loop_message//@FILE@/$f}
    expect+=("$f"$'\t'"${msg//@OTHER_SKILL@/$other}")
  done <<<"$loop_files"
  out=$(lint_scratch)
  for f in "${expect[@]}"; do
    [[ $out == *"${f#*$'\t'}"* ]] || echo "FAIL the $1 loop does not read ${f%%$'\t'*}"
  done
}
for loop in step dotfiles ns brief mermaid cite; do
  gaps=$(loop_gaps "$loop")
  fx_check "every file the $loop loop is documented to read is read" test -z "$gaps"
  loop_facts "$loop"
  with_dropped_lint "the $loop loop" "$drop_file" "$loop_sed_addr" "$loop_sed_sub" loop_gaps "$loop"
  fx_check "a file dropped from the $loop loop in a copy of the lint is reported" \
    test "$dropped" = "FAIL the $loop loop does not read $drop_file"
done

# the section-6 database-gate loop (dev-lfh0): the lint checks each gate skill's cite of the tracker
# doc's "Has a database" rule in a loop over a hand-picked list, so a skill dropped from that list
# passes unseen. The expected set is stated here, not read back from the lint. Every skill in it
# is seeded with the cite removed, in one tree, so one lint run reports each one that is unchecked.
db_gate_skills="spec-to-stories spec-to-tasks story-to-tasks close-epic retro"
# db_gaps: one line for each skill of db_gate_skills whose missing-cite message the lint does not print
db_gaps() {
  local g out
  fresh
  for g in $db_gate_skills; do
    drop_phrase "skills/$g/SKILL.md" '"Has a database" rule'
  done
  out=$(lint_scratch)
  for g in $db_gate_skills; do
    grep -qF "/$g cites the tracker doc's \"Has a database\" rule" <<<"$out" \
      || echo "FAIL the section-6 loop does not read $g"
  done
}
db_gaps_out=$(db_gaps)
fx_check "every skill of the section-6 database-gate list is checked" test -z "$db_gaps_out"
with_dropped_lint "the section-6 database gates" skills/retro/SKILL.md \
  '/^for g in spec-to-stories /' 's/ retro; do$/; do/' db_gaps
fx_check "a skill dropped from the section-6 database-gate loop in a copy of the lint is reported" \
  test "$dropped" = "FAIL the section-6 loop does not read retro"

# the section-18 skill names (dev-5wpr): the lint reads every skill for its cite-target pass and for
# the skill-name list, and a skill dropped from either only shows when a seed happens to name it. The
# cite key it leaves beside the pin list is checked against the tree instead.
# names_gaps <cite key>: one line for each skill dir of the pristine tree that the key lacks from its
# skill-name line, or whose headings it lacks from its cite targets
names_gaps() {
  local d s
  for d in "$pristine"/skills/*/; do
    s=${d%/}; s=${s##*/}
    sed -n 1p "$1" | grep -q "|$s|" || echo "FAIL the cite key lacks $s from its skill names"
    ! grep -qE '^(##|###|####) ' "$d/SKILL.md" || sed 1d "$1" | grep -q "^$s	" || echo "FAIL the cite key lacks the headings of $s"
  done
}
names=$(names_gaps "$jobs/pins.list.cites")
fx_check "the cite key holds every skill's name and headings" test -z "$names"
with_dropped_lint "the cite-target pass" skills/retro/SKILL.md '/END { for (x in k)/' \
  's#'"'"' "$skills"/\*/SKILL.md |#'"'"' $(printf "%s\\n" "$skills"/*/SKILL.md | grep -v /retro/) |#' \
  pin_list_report names_gaps "$jobs/pins.names" .cites
fx_check "a skill dropped from the cite-target pass in a copy of the lint is reported" \
  test "$dropped" = "FAIL the cite key lacks the headings of retro"
with_dropped_lint "the skill-name list" skills/retro/SKILL.md \
  '/^  given=\${given%\/}$/' 's@$@; [ "${given##*/}" != retro ] || continue@' \
  pin_list_report names_gaps "$jobs/pins.names" .cites
fx_check "a skill dropped from the skill-name list in a copy of the lint is reported" \
  test "$dropped" = "FAIL the cite key lacks retro from its skill names"

# the section-18 cache-invalidation loop (dev-5wpr): a changed SKILL.md that moves the cite key has
# every listed file read again, and the loop that finds it walks the skills; one dropped from it
# leaves that skill's heading edit unseen, a stale cite in a listed doc unreported
# list_unchanged <path...>: $jobs/unchanged lists what the scratch tree holds unchanged and the
# paths given, so a run here costs what a case's does and names only the files the check is about
list_unchanged() {
  unchanged_files "$scratch" > "$jobs/unchanged"
  [ $# -eq 0 ] || printf '%s\n' "$@" >> "$jobs/unchanged"
}
# cache_gaps: one line for each skill of the pristine tree that the cite-key loop of the lint in
# $lint does not visit. One run on a tree whose every file is unchanged lets that loop walk all the
# skills (a changed one would end it; LINT_CITE_BASE is emptied so the loop runs), and a DEBUG trap
# sourced through BASH_ENV logs $f each time the loop's line calls unchanged_file; a skill the
# loop drops never reaches that call
cache_gaps() {
  local d skill loop_line
  loop_line=$(grep -n 'unchanged_file || { unchanged=' "$lint" | cut -d: -f1)
  if ! [[ $loop_line =~ ^[0-9]+$ ]]; then
    echo "FAIL the cache loop line is not found in $lint"
    return
  fi
  printf '%s\n' 'set -T' \
    'trap '"'"'[[ $BASH_COMMAND == unchanged_file && $LINENO == $CACHE_LOOP_LINE ]] && echo "$f" >> "$CACHE_VISITED" || :'"'"' DEBUG' \
    > "$jobs/cache.env"
  : > "$jobs/cache.visited"
  fresh
  list_unchanged
  unchanged_tables >> "$jobs/unchanged"
  LINT_CITE_BASE= BASH_ENV=$jobs/cache.env CACHE_VISITED=$jobs/cache.visited \
    CACHE_LOOP_LINE=$loop_line \
    unchanged_list=$jobs/unchanged lint_scratch > /dev/null
  for d in "$pristine"/skills/*/; do
    skill=${d%/}; skill=${skill##*/}
    grep -qxF "$scratch/skills/$skill/SKILL.md" "$jobs/cache.visited" \
      || echo "FAIL the cache loop does not read skills/$skill/SKILL.md"
  done
}
cache=$(cache_gaps)
fx_check "the cite loop visits every skill's SKILL.md" test -z "$cache"
cache_sed_sub='s#"$skills"/\*/SKILL.md; do unchanged_file#"$skills"/*/SKILL.md; do [ "${f%/@DROPPED@}" = "$f" ] || continue; unchanged_file#'
cache_sed_sub=${cache_sed_sub//@DROPPED@/${drop_file#skills/}}
with_dropped_lint "the cache-invalidation loop" "$drop_file" '/unchanged_file || { unchanged=/' \
  "$cache_sed_sub" cache_gaps
fx_check "a skill dropped from the cache-invalidation loop in a copy of the lint is reported" \
  test "$dropped" = "FAIL the cache loop does not read $drop_file"
# a copy whose loop line the locator cannot find gives one FAIL line, not one for each skill
with_dropped_lint "the cache loop locator" "$drop_file" '/unchanged_file || { unchanged=/' \
  's#unchanged_file || { unchanged=#unchanged_file ||  { unchanged=#' cache_gaps
fx_check "a cache loop line the locator cannot find in a copy of the lint is one report" \
  bash -c '[[ $1 == "FAIL the cache loop line is not found in "* && $1 != *$'"'"'\n'"'"'* ]]' _ "$dropped"

# the derived anchored case needs the lint's pattern to open with ^: the one review tool paragraph
# pin, which names no heading, must stay anchored on its line (losing the ^ makes it match mid-line)
pin_phrase "the one review tool paragraph"
fx_check "the one review tool paragraph pin is anchored on its line" test "${pinned_phrase:0:1}" = '^'

# edit_rows <rename|reword> <table>: writes the pins copy of the table with each row whose description
# (field 2) is in $rows renamed, or with its phrase (field 3) reworded to hold none of its sweep (the
# row's line number ends the new phrase, so no two rows read alike)
edit_rows() {
  ROWS=$rows awk -F '\t' -v OFS='\t' -v mode="$1" 'BEGIN { n = split(ENVIRON["ROWS"], r, "\n"); for (i = 1; i <= n; i++) hit[r[i]] }
    $1 !~ /^#/ && ($2 in hit) { if (mode == "rename") $2 = $2 " (renamed)"; else $3 = "a phrase reworded to hold none of its sweep, row " NR }
    { print }' "$repo_root/scripts/$2.tsv" > "$scratch/pins/$2.tsv"
}
# pins_copy: a fresh tree and a copy of the pin tables in it to edit, which the lint reads as its
# pins directory (pins_dir, which the caller unsets once its case has run)
pins_copy() {
  fresh
  mkdir "$scratch/pins" || return 1
  local t
  for t in $pin_tables; do cp "$repo_root/scripts/$t.tsv" "$scratch/pins/"; done
  pins_dir=$scratch/pins
}
# a pin table row short of a field, or with an unknown check, fails the lint rather than being
# skipped or read as an empty phrase (which every doc holds)
for table in $pin_tables; do
  for case in 'a row of words and no tab|a row needs a check, a description and a phrase' \
    $'has\tno phrase\t|a row needs a check, a description and a phrase' \
    $'hasx\tunknown check\ta phrase|unknown check hasx' \
    $'sec\theading-less sec\ta phrase|sec needs a heading'; do
    row=${case%%|*}
    # a sec row is the repo plumbing table's own kind; the other table has no heading for it
    ! { [ "$table" = repo-plumbing-pins ] && [[ $row == sec* ]]; } || continue
    pins_copy
    printf '%s\n' "$row" >> "$scratch/pins/$table.tsv"
    expect "$table.tsv with the row '${row//$'\t'/<tab>}' fails" 1 "$table.tsv: ${case#*|}"
    unset pins_dir
  done
done

# a pin table gone from the pins directory turns its pins off unless the lint fails naming it
for table in $pin_tables; do
  pins_copy
  rm "$scratch/pins/$table.tsv"
  expect "a pins directory without $table.tsv fails" 1 "missing pin table: $scratch/pins/$table.tsv"
  unset pins_dir
done

# a pins directory gone altogether fails too, as a missing doc does
fresh
pins_dir=$scratch/no-such-pins
sec="0 1 6" expect "a missing pins directory fails" 1 "no such directory: $scratch/no-such-pins"
unset pins_dir
# and so does a docs dir without docs/agents, this repo's mattpocock-skills configuration
# (the domain and triage-labels docs live there)
fresh
rm -rf "$scratch/docs/agents"
sec="0" expect "a docs dir without docs/agents fails" 1 "no such directory: $scratch/docs/agents"

# pin_row_case <rename|reword> <table>: the one case of a pin table's rows that the lint reads by
# their description (rename: a row the lint's own calls name, renamed so the lint must name it) or
# that carry a sweep field (reword: a row whose phrase is reworded to hold none of its sweep, which
# the lint must still name). Every such row is changed in one copy and the lint run once, since each
# change draws its own message: one run must name every row (dev-yqpz, dev-4wal)
pin_row_case() {
  local mode=$1 table=$2 rows row count=0 msgs= guard_msg desc
  if [ "$mode" = rename ]; then
    rows=$(grep -oE "$table \"[^\"]+\"" "$lint" | sed -e 's/^[^ ]* "//' -e 's/"$//' | sort -u)
    guard_msg="the lint reads no row of $table.tsv by its description"
  else
    rows=$(awk -F '\t' '$1 !~ /^#/ && NF >= 4 && $4 != "" { print $2 }' "$repo_root/scripts/$table.tsv")
    guard_msg="$table.tsv holds no row with a sweep field"
  fi
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    count=$((count+1))
    if [ "$mode" = rename ]; then msgs+="${msgs:+$nl}no row '$row' in $table.tsv"
    else msgs+="${msgs:+$nl}$table.tsv: the sweep of '$row' is not inside its phrase"; fi
  done <<<"$rows"
  [ "$count" -gt 0 ] || { echo "FAIL $guard_msg"; fails=$((fails+1)); }
  if [ "$mode" = rename ]; then desc="$table.tsv with each row the lint reads by its description renamed fails naming all $count"
  else desc="$table.tsv with the phrase of each row with a sweep reworded and its sweep left fails naming all $count"; fi
  pins_copy
  edit_rows "$mode" "$table"
  sec= expect "$desc" 1 "$msgs"
  unset pins_dir
}
# the renames first, then the rewords, each over every pin table
for mode in rename reword; do
  for table in $pin_tables; do pin_row_case "$mode" "$table"; done
done

# a doc that keeps the no-check-target setup line but loses the clause after it fails: the clause is
# what follows the line's last comma
fresh
no_target="a repo with no check target fails the run with the setup line, before any task orchestrator starts"
pin_phrase "$no_target"
drop_phrase references/orchestration.md "${pinned_phrase##*, }"
expect "orchestration doc whose no check target line lacks its closing clause fails" 1 ": $no_target ("

# section 1 lints the implement-spec file it is handed, so the cases below edit a scratch copy of it
# and hand that copy to expect (chezmoi-9v4.1.6): the human-stop line passing "no merge steps"
# while a merge procedure still fails, and the cases of its lacks checks
spec=$scratch/spec.md
fresh_spec() { fresh; cp "$scratch/skills/implement-spec/SKILL.md" "$spec"; }

fresh_spec
expect "implement-spec with the human-stop merge line passes" 0 "" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "Then open a PR for the story." >> "$spec"
expect "implement-spec opening a PR in prose fails" 1 "PR-opening steps" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
ban ban_blocking_only "a budget of blocking verdicts only"
echo "$ban_blocking_only are fixed up" >> "$spec"
expect "implement-spec counting only blocking verdicts fails" 1 "a budget of blocking verdicts only" "$spec" "$scratch/docs/WORKFLOW.md"

# the epic row's fourth failure reads only the Check gate's two lines (dev-aeo)
fresh_spec
echo 'report `failed: <story-id> epic gate not clean after three fix-ups`' >> "$spec"
expect "implement-spec with a fourth-failure line the Check gate does not allow fails" 1 "an epic-row fourth-failure line the Check gate does not allow" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo 'report `failed: <story-id> epic review failed after 3 fix-ups`' >> "$spec"
expect "implement-spec with a reworded fix-up count fails" 1 "an epic-row fourth-failure line the Check gate does not allow" "$spec" "$scratch/docs/WORKFLOW.md"

# the Check gate's allowed lines are blanked as literal text: a row reworded to hold a / (the lint
# once passed it to sed as a pattern, which failed and left the scan empty) still lets a line the
# Check gate does not allow fail
pins_copy
pin_phrase "red-check budget failure line"
slashed="$pinned_phrase/x"
for doc in pins/implement-spec-pins.tsv skills/implement-spec/SKILL.md references/orchestration.md; do
  swap_phrase "$doc" "$pinned_phrase" "$slashed"
done
printf '\n%s\n' 'report `failed: <story-id> epic gate not clean after three fix-ups`' >> "$scratch/skills/implement-spec/SKILL.md"
expect "a reworded fourth-failure row holding a / still fails a line the Check gate does not allow" 1 "an epic-row fourth-failure line the Check gate does not allow"
unset pins_dir

fresh_spec
ban ban_not_reviewed_again "a spent budget skipping the review"
echo "one with three fix-ups $ban_not_reviewed_again" >> "$spec"
expect "implement-spec skipping a spent budget fails" 1 "a spent budget skipping the review" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
ban ban_failed_report "review set keyed on a failed: report this run"
echo "it enters the set when its orchestrator $ban_failed_report" >> "$spec"
expect "implement-spec keying the review set on a failed: report fails" 1 "review set keyed on a failed: report this run" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
ban ban_touches_no_task "nothing touches a task"
echo "$ban_touches_no_task" >> "$spec"
expect "implement-spec claiming it touches no task fails" 1 "nothing touches a task" "$spec" "$scratch/docs/WORKFLOW.md"

fresh_spec
echo "You are the driver, the feature-level session." >> "$spec"
sec=5 expect "implement-spec naming the old epic role fails" 1 "the retired driver role in $spec" "$spec" "$scratch/docs/WORKFLOW.md"

# the glossary's avoided term "human task" (a ready-for-human task is fine): the gate
# task is a human gate task (story review 1)
fresh_spec
echo "A resumed run starts the stories the closed human task released." >> "$spec"
expect "implement-spec saying 'human task' fails" 1 "present: glossary's avoided term human task" "$spec" "$scratch/docs/WORKFLOW.md"

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

# the runbook no longer lists a chain among the task cut's refusals (chezmoi-9v4.1.9)
fresh
echo 'Among its refusals: a dependency chain (A depends on B depends on C).' >> "$scratch/docs/WORKFLOW.md"
expect "runbook copy with the chain refusal fails" 1 "present: chain refusal in the runbook"

fresh
echo 'The task cut refuses a dependency chain of three stories.' >> "$scratch/docs/WORKFLOW.md"
expect "runbook copy with the chain refusal in a sentence fails" 1 "present: chain refusal in the runbook"

# the pins of regex only that no derived case seeds: the commit recipe's --trailer, a forced worktree
# removal, the delivery re-reading the green record, /pr in stage 5 (a case names its pin's description)
fresh
echo 'Commit it with `git commit --trailer "Bead: x"`.' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story with a --trailer commit fails" 1 "present: a --trailer commit"

fresh
echo 'Then run git worktree remove --force <path> on the entry.' >> "$scratch/skills/implement-story/SKILL.md"
expect "implement-story forcing a worktree removal fails" 1 "present: a locked or unmerged worktree forced"

fresh
echo 'Deliver with no green record there `exit=0` in `<owner>/.tmp/checks/<tree>/record`.' >>"$scratch/skills/implement-task/SKILL.md"
expect "implement-task reading the green record itself fails" 1 "present: the delivery reading the green record itself"

fresh
echo '| 5 | review | /mattpocock-skills:pr opens the PR |' >> "$scratch/docs/WORKFLOW.md"
expect "the runbook naming /mattpocock-skills:pr in stage 5 fails" 1 "present: /mattpocock-skills:pr in stage 5"

fresh
echo 'The closure chain goes through a dependency chain of stories, merged in order.' >> "$scratch/docs/WORKFLOW.md"
expect "runbook copy mentioning a dependency chain of closures passes" 0

# the check and review loop's retired two-gate wording is swept from every file kind (the banned texts are
# seeded from the lint's list); docs/specs keeps the words
fresh
ban_nth ban_evidence_run "retired two-gate wording in $scratch/docs/WORKFLOW.md" 1
echo "The retired $ban_evidence_run stays in the spec." >> "$scratch/docs/specs/check-and-review-loop.md"
expect "a spec keeping '$ban_evidence_run' passes" 0

# a forge command is run plainly first and rerun with the sandbox disabled only on its config error or a sandbox denial (dev-aosb): the
# retired "run it with the sandbox disabled" wording is swept from every file kind; docs/specs keeps the words
fresh
ban_nth ban_forge_sandbox "retired forge sandbox-disable wording in $scratch/docs/WORKFLOW.md" 1
ban_nth ban_forge_sandbox_2 "retired forge sandbox-disable wording in $scratch/docs/WORKFLOW.md" 2
echo "The retired $ban_forge_sandbox stays in the spec." >> "$scratch/docs/specs/check-and-review-loop.md"
expect "a spec keeping '$ban_forge_sandbox' passes" 0

# the gate with no check command (ADR 0015) is swept from every file kind, the glossary included; docs/specs keeps the words
fresh
ban_nth ban_no_check "retired review-only gate wording in $scratch/GLOSSARY.md" 2
ban_nth ban_review_only "retired review-only gate wording in $scratch/GLOSSARY.md" 1
echo "A repo with $ban_no_check gets a $ban_review_only gate." >> "$scratch/docs/specs/one-loop-three-rows.md"
expect "a spec keeping the retired gate wording passes" 0

# the retired gate wording has a regex alternative the derived cases skip, so each spelling
# is seeded in the glossary and in a file under docs/
for spelling in 'without a check command' 'with a check command'; do
  for file in GLOSSARY.md docs/SEQUENCES.md; do
    fresh
    echo "A repo $spelling is gated by review alone." >> "$scratch/$file"
    expect "$file saying a repo $spelling fails" 1 "retired review-only gate wording in $scratch/$file"
  done
done

# the spec-to-stories ban on a step 8 commit has a regex alternative the
# derived cases skip: each git write, on a line holding no other banned text
for verb in add commit; do
  fresh
  echo "Run git -C <owner> $verb the notes." >> "$scratch/skills/spec-to-stories/SKILL.md"
  expect "spec-to-stories running git -C <owner> $verb fails" 1 "present: step 8 gitignore line or commit"
done

# stated once: a skill spelling the refusal out again fails
pin_phrase "implement-spec restating the malformed-epic refusal"; restated=$pinned_phrase
for sk in implement-spec implement-story close-epic; do
  fresh
  echo "\`$restated\`" >> "$scratch/skills/$sk/SKILL.md"
  expect "$sk restating the malformed-epic refusal fails" 1 "restating the malformed-epic refusal"
done

fresh
pin_phrase "a routed bead of type chore"
printf '\n%s\n' "$pinned_phrase" >> "$scratch/references/issue-tracker.md"
sec=6 expect "a routed bead of type chore fails" 1 "a routed bead of type chore"

# the capture runs its inbox search before bd create (dev-0o8z): a copy with the search block
# moved after the create block fails naming the pin
fresh
rewrite references/issue-tracker.md awk '
  /^bd search "<title words>" --status open -l needs-triage$/ { held = $0; next }
  held != "" && /^  \[--external-ref / { print; print held; held = ""; next }
  { print }'
sec=6 expect "a capture that creates before it searches fails" 1 "out of order: the capture searches the inbox before it creates the bead"

# a capture with no inbox search at all fails as missing, naming the pin
fresh
rewrite references/issue-tracker.md sed 's/^bd search "<title words>".*$/bd list/'
sec=6 expect "a capture with no inbox search fails" 1 "missing in the"

fresh
ban ban_to_tickets "/triage citing the retired to-tickets template"
echo "Body in the \`$ban_to_tickets." >> "$scratch/skills/triage/SKILL.md"
sec="5 6" expect "triage citing the to-tickets template fails" 1 "/triage citing the retired to-tickets template"

route_desc="a retired route (flat epic or shape, small-bug path, upstream skill or chore name) in"
ban_nth ban_implement_chore "$route_desc $scratch/skills/sample/SKILL.md" 1
ban_nth ban_chore_orchestrator "$route_desc $scratch/skills/sample/SKILL.md" 2
ban_nth ban_chore_branch "$route_desc $scratch/skills/sample/SKILL.md" 3
for text in 'a flat epic of tasks' 'the legacy flat shape' 'The flat-epic refusal.' \
  'the small-bug path does it' 'the small bug path' \
  'run /mattpocock-skills:implement <id>' \
  'run /mattpocock-skills:to-tickets now' \
  'the upstream engineering to-tickets skill' \
  "the $ban_implement_chore skill" "the $ban_chore_orchestrator" "on branch ${ban_chore_branch}<id>"; do
  for file in skills/sample/SKILL.md references/issue-tracker.md docs/WORKFLOW.md skills/implement-story/SKILL.md; do
    fresh
    echo "$text" >> "$scratch/$file"
    sec=5 expect "$file saying '$text' fails section 5" 1 "$route_desc $scratch/$file"
  done
done
fresh
printf 'The commit subject is chore: ignore agent scratch space.\nA chore type and a chore commit pass.\nSee /mattpocock-skills:tdd.\n' >> "$scratch/skills/sample/SKILL.md"
expect "the bare word chore and the other upstream skills pass" 0
fresh
echo 'ADR 0006 keeps the flat epic and /mattpocock-skills:to-tickets history.' >> "$scratch/docs/adr/0001.md"
echo "The spec names a flat epic, ${ban_chore_branch}<id> and the small-bug path." >> "$scratch/docs/specs/one-loop-three-rows.md"
expect "an ADR and a spec keeping the retired route words pass" 0

# the retired vocabulary (dev-9k5.1.10, dev-9k5.1.11): every retired word or phrase seeded
# together into each file section 5 sweeps (skills, reference docs, the project CLAUDE.md, the
# runbook, the sequence diagrams) fails by section 5 alone, the output naming each phrase's
# check, one lint run per file; the glossary and docs/adr/ are not swept
ban ban_builtin_review_claude "the built-in code-review named in $scratch/CLAUDE.md"
ban ban_two_review_tools "the two review tools paragraph in $scratch/CLAUDE.md"
ban ban_lint_command "the retired lint command in $scratch/CLAUDE.md"
retired_vocab="The driver spawns the stories.|the retired driver role
Each ticket runner implements.|the retired ticket runner role
A merger folds it in.|the retired merger role
Spawn a fresh fix-up implementer.|the retired fix-up implementer role
Run the $ban_builtin_review_claude on it.|the built-in code-review named
$ban_two_review_tools, two stages: per task.|the two review tools paragraph
Exit on the review marker.|the retired review marker
Run $ban_lint_command, then the tip.|the retired lint command
Name the test seams as checks.|the retired test seams as checks"
for file in skills/sample/SKILL.md skills/workflow/SKILL.md skills/close-epic/SKILL.md skills/spec-to-stories/SKILL.md \
  skills/spec-to-tasks/SKILL.md references/issue-tracker.md docs/agents/triage-labels.md CLAUDE.md docs/WORKFLOW.md docs/SEQUENCES.md; do
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
ban_nth ban_story_per_repo "retired story-DAG wording in $scratch/docs/WORKFLOW.md" 1
# the words of a banned text either side of its last space, to wrap it across a line break
evidence_a=${ban_evidence_run% *} evidence_b=${ban_evidence_run##* }
lint_cmd_a=${ban_lint_command% *} lint_cmd_b=${ban_lint_command##* }
story_repo_a=${ban_story_per_repo% *} story_repo_b=${ban_story_per_repo##* }
for case in 'Each ticket\nrunner implements.|the retired ticket runner role' \
  "> Run $lint_cmd_a\n>    $lint_cmd_b, then the tip.|the retired lint command" \
  "Then the $evidence_a\n  $evidence_b checks the tip.|retired two-gate wording" \
  "A feature is $story_repo_a\n${story_repo_b}.|retired story-DAG wording" \
  "The $evidence_a  \n$evidence_b goes.|retired two-gate wording"; do
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
  ban_alt ban_chains "retired story-DAG wording in $scratch/references/$doc.md" chains
  echo "$ban_chains." >> "$scratch/references/$doc.md"
  sec=5 expect "$doc doc saying the section 10 chains wording fails section 5 alone" 1 "retired story-DAG wording"
done

# the sweep reads a banned text in any case: its capitalised spelling, upper-cased from the list's
# text, fails section 5 too
fresh
capitalised=$(printf '%s' "$ban_evidence_run" | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }')
echo "$capitalised checks the tip." >> "$scratch/docs/WORKFLOW.md"
sec=5 expect "runbook with '$capitalised' capitalised fails section 5" 1 "retired two-gate wording in $scratch/docs/WORKFLOW.md"

# the implement-spec skill passed as $1 outside the skills dir is swept like the default
fresh_spec
echo "Then the $ban_evidence_run checks the tip." >> "$spec"
sec=5 expect "implement-spec passed as \$1 with a retired phrase fails section 5" 1 "retired two-gate wording in $spec" "$spec" "$scratch/docs/WORKFLOW.md"

# a rule that moved to harness.md, cited at the orchestration doc in either form, fails section 5 alone,
# wrapped included; a rule the orchestration doc still holds, and the harness doc's citation, pass (dev-zra)
for case in "skills/implement-story/SKILL.md|as the orchestration doc's Scratch space says (Literal paths)" \
  "skills/sample/SKILL.md|the orchestration doc's Cut-off agents" \
  "references/issue-tracker.md|see orchestration.md's TMPDIR rule" \
  "docs/agents/triage-labels.md|(\`orchestration.md\`, Commits)" \
  "skills/sample/SKILL.md|re-add it as the orchestration doc's fallback says" \
  "skills/sample/SKILL.md|as the orchestration doc's Scratch space (Literal paths) says" \
  "skills/sample/SKILL.md|hand-rolled, as the orchestration doc's worktree fallback says" \
  "skills/spec-to-tasks/SKILL.md|as the \"Waiting\" rule of \`orchestration.md\` says" \
  "docs/agents/triage-labels.md|the idle rule in the orchestration doc" \
  "docs/agents/triage-labels.md|see \`orchestration.md\`'s TMPDIR rule" \
  "docs/WORKFLOW.md|the orchestration doc's\nWorktrees"; do
  fresh
  printf '%b\n' "${case#*|}" >> "$scratch/${case%%|*}"
  sec=5 expect "${case%%|*} citing '${case#*|}' fails section 5" 1 "a moved harness rule cited at the orchestration doc in $scratch/${case%%|*}"
done
fresh
printf "%s\n" "the orchestration doc's Scratch space (Gitignore)" "the harness doc's Scratch space says (Literal paths)" \
  "(\`orchestration.md\`, Trust rules, rule 2)" "the orchestration doc's Frontier (waiting tasks stay open)" >> "$scratch/skills/sample/SKILL.md"
expect "the orchestration doc's own rule and the harness doc's citation pass section 5" 0

# a semicolon ends a mermaid statement, so one inside a ```mermaid block fails; the same ';' in prose passes
fresh
printf '\n```mermaid\nsequenceDiagram\n    A->>B: one; two\n```\n' >> "$scratch/docs/SEQUENCES.md"
expect "a mermaid block with a semicolon fails" 1 "a semicolon in a mermaid block in $scratch/docs/SEQUENCES.md"

fresh
echo 'Prose may keep a semicolon; one, two.' >> "$scratch/docs/SEQUENCES.md"
expect "a semicolon outside a mermaid block passes" 0

# another skill's rule is cited in one form (dev-q47w): a heading cited bare after a
# possessive fails in any reference doc or SKILL.md but the cite rule file and the coding standards doc, which show the wrong
# form
fresh
printf '%s\n' "As \`/dev:task-orchestrator\`'s Two entries says." >> "$scratch/references/orchestration.md"
sec=18 expect "a bare heading cite of a skill in a reference doc fails section 18" 1 "present: an unquoted heading cite of a skill in $scratch/references/orchestration.md"

fresh
printf '%s\n' "As \`/dev:task-orchestrator\`'s" "Two entries says." >> "$scratch/references/orchestration.md"
sec=18 expect "a bare heading cite split across a line break fails section 18" 1 "present: an unquoted heading cite of a skill in $scratch/references/orchestration.md"

fresh
printf '%s\n' "As \`/dev:task-orchestrator\`'s" "own brief says." >> "$scratch/references/orchestration.md"
expect "a possessive followed by a lowercase word on the next line passes section 18" 0

fresh
printf '%s\n' "As \`/dev:task-orchestrator\`'s \"Two entries\" says, and \`/dev:implement-story\`'s **Story gate**." >> "$scratch/references/orchestration.md"
expect "a quoted heading cite and a bold step cite pass section 18" 0

# a section 18 FAIL line names the skill name that matched, not the skill's whole list of names,
# and shows hits a name, so wrong cites of four names of one skill show four FAIL lines (dev-j9i5)
fresh
printf '%s\n' "As the Landing section of \`/dev:implement-story\` says." "As the Clean up sweep of \`/dev:implement-story\` says." \
  "As the Story gate step of \`/dev:implement-story\` says." "As the Re-evaluate the frontier step of \`/dev:implement-story\` says." >> "$scratch/references/orchestration.md"
sec=18 expect "wrong cites of four names of one skill each get a FAIL line naming the name" 1 "present: a bare cite of /dev:implement-story in $scratch/references/orchestration.md (Landing)
present: a bare cite of /dev:implement-story in $scratch/references/orchestration.md (Clean up)
present: a bare cite of /dev:implement-story in $scratch/references/orchestration.md (Story gate)
present: a bare cite of /dev:implement-story in $scratch/references/orchestration.md (Re-evaluate the frontier)
As the Landing section of \`/dev:implement-story\` says.
As the Clean up sweep of \`/dev:implement-story\` says.
As the Story gate step of \`/dev:implement-story\` says.
As the Re-evaluate the frontier step of \`/dev:implement-story\` says."

# one name with four wrong cites shows its first three hits and not the fourth
fresh
printf '%s\n' "First Landing section of \`/dev:implement-story\` says." "Second Landing section of \`/dev:implement-story\` says." \
  "Third Landing section of \`/dev:implement-story\` says." "Fourth Landing section of \`/dev:implement-story\` says." >> "$scratch/references/orchestration.md"
must_not_print="Fourth Landing section of" sec=18 expect "a name with four wrong cites shows three hits and not the fourth" 1 "(Landing)
First Landing section of
Second Landing section of
Third Landing section of"

# an unquoted heading cite of one skill, its FAIL line names that skill and not the alternation of
# every skill's name (dev-pwbz, the retro of dev-j9i5)
fresh
printf '%s\n' "As \`/dev:task-orchestrator\`'s Two entries says." >> "$scratch/references/orchestration.md"
must_not_print='/dev:(' sec=18 expect "an unquoted heading cite of one skill names that skill in its FAIL line, not the alternation" 1 "present: an unquoted heading cite of a skill in $scratch/references/orchestration.md (/dev:task-orchestrator)"

# the other wrong forms the rule names (dev-mnz6): a step name in quotes, a heading in bold and a
# bare cite in the "of /dev:x" word order, each failing in a reference doc but the cite rule file and the coding standards doc
orch=references/orchestration.md
# Section 18's cases seed a line of prose, and a lint run over a reference doc pays for that doc's every
# check, so they share their runs (dev-xier): cite_case keeps each case's text for a doc of its own,
# references/cite-<n>.md, in one tree per $prep, and cite_flush lints each tree once. A case's own
# doc says what the same text appended to <file> would: a check reads /dev:<skill> and a name
# together, so a text holding them passes the file's filter on its own, and a text without them
# fires nothing in <file> either. The cases above, on the orchestration doc itself, stand as the witnesses.
cite_n=0 ncbatches=0 ncretried=0
# cite_case <want: 1 fails, 0 passes> <file under scratch> <description> <message> <line>...: the
# lines are the text; $no_nl drops the last newline
cite_case() {
  local want=$1 file=$2 d=$3 msg=$4 tree=${prep:-plain} text
  shift 4
  printf -v text '%s\n' "$@"
  [ -z "${no_nl:-}" ] || text=${text%$nl}
  cite_n=$((cite_n+1))
  [ -d "$jobs/cites/$tree" ] || mkdir -p "$jobs/cites/$tree"
  printf '%s' "$text" > "$jobs/cites/$tree/cite-$cite_n.md"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$want" "$cite_n" "$tree" "$file" "$d" "$msg" >> "$jobs/cites/$tree.spec"
}
# judge_cites <spec> <lint output>: an ok line per record the output vouches for, every other record
# to $BATCH_RETRY, to run alone. A failing case is vouched for by a FAIL naming its doc with its
# message (<file> in the message read as its doc), a passing one by no FAIL naming its doc. Nothing
# is vouched for when the lint timed out, or when a FAIL fell outside section 18 or outside the
# batch's docs, as a tree of the case's own would have shown. The output's paths are the case's dir
# ($BATCH_DIR); the spec's are the scratch dir's ($BATCH_SCRATCH)
judge_cites() {
  local rc=${2##*$'\n'}
  printf '%s\n' "$2" | rc=$rc awk -F '\t' -v dir="$BATCH_DIR" -v base="$BATCH_SCRATCH" '
    NR == FNR {
      if (/^== /) { sect = $0; sub(/^== /, "", sect); sub(/\..*/, "", sect) }
      else if (/^FAIL/) {
        F[++nf] = $0
        if (sect != "18" || !index($0, dir "/references/cite-")) foreign = 1
      }
      next }
    {
      doc = dir "/references/cite-" $2 ".md"
      msg = $6; p = base "/" $4
      if ((i = index(msg, p))) msg = substr(msg, 1, i - 1) doc substr(msg, i + length(p))
      hit = 0
      for (i = 1; i <= nf; i++) if (index(F[i], doc) && index(F[i], msg)) hit = 1
      ok = !foreign && (ENVIRON["rc"] == 0 || ENVIRON["rc"] == 1) && ($1 == 1 ? hit : !hit)
      if (ok) print "ok   " $5; else print > ENVIRON["BATCH_RETRY"]
    }' - "$1"
}
# cite_flush: lints each tree of kept cases, then runs alone, as the case was written, each one its
# tree did not vouch for
cite_flush() {
  local spec tree want n file desc msg
  expect_flush all
  rm -f "$jobs"/*.retry
  for spec in "$jobs"/cites/*.spec; do
    tree=${spec##*/} tree=${tree%.spec}
    fresh
    [ "$tree" = plain ] || "$tree"
    cp "${spec%.spec}"/* "$scratch/references/"
    ncbatches=$((ncbatches+1))
    sec= batch=$spec judge_fn=judge_cites expect "cite batch $tree" 1
  done
  expect_flush all
  cat "$jobs"/*.retry > "$jobs/retries" 2>/dev/null
  while IFS=$'\t' read -r -u 4 want n tree file desc msg; do
    ncretried=$((ncretried+1))
    fresh
    [ "$tree" = plain ] || "$tree"
    cat "$jobs/cites/$tree/cite-$n.md" >> "$scratch/$file"
    sec=18 expect "$desc" "$want" "$msg"
  done 4< "$jobs/retries"
}
cite_case 1 $orch "a step name cited in quotes fails section 18" "present: a step name cited in quotes of /dev:implement-story in $scratch/$orch" "As \`/dev:implement-story\`'s \"Story gate\" says."

cite_case 1 $orch "a step name in quotes in the word order fails section 18" "present: a step name cited in quotes of /dev:implement-story in $scratch/$orch" "As the \"Clean up\" sweep of \`/dev:implement-story\` says."

cite_case 1 $orch "a heading cited in bold fails section 18" "present: a heading cited in bold of /dev:task-orchestrator in $scratch/$orch" "As \`/dev:task-orchestrator\`'s **Two entries** says."

cite_case 1 $orch "a heading in bold in the word order fails section 18" "present: a heading cited in bold of /dev:implement-story in $scratch/$orch" "As the **Landing** section of \`/dev:implement-story\` says."

cite_case 1 $orch "a bare heading in the word order fails section 18" "present: a bare cite of /dev:implement-story in $scratch/$orch" "As the Landing section of \`/dev:implement-story\` says."

cite_case 1 $orch "a bare step name in the word order fails section 18" "present: a bare cite of /dev:implement-story in $scratch/$orch" "As the Clean up sweep of \`/dev:implement-story\` says."

cite_case 0 $orch "the right form in the word order passes section 18" "" "As the **Clean up** sweep of \`/dev:implement-story\` and the \"Two entries\" section of \`/dev:task-orchestrator\` say."

# the forms past the first cut (dev-mnz6 review 1): numbered and ### headings, step names that are
# hyphenated, indented or opening no numbered item, punctuation inside the marking and more word orders
cite_case 1 $orch "a numbered ## heading cited in bold fails section 18" "present: a heading cited in bold of /dev:close-story in $scratch/$orch" "As \`/dev:close-story\`'s **The forge shows MERGED** says."

cite_case 1 $orch "a numbered ## heading cited bare in the word order fails section 18" "present: a bare cite of /dev:close-story in $scratch/$orch" "As the The forge shows MERGED step of \`/dev:close-story\` says."

cite_case 1 $orch "a numbered ### heading cited in bold fails section 18" "present: a heading cited in bold of /dev:story-to-tasks in $scratch/$orch" "As \`/dev:story-to-tasks\`'s **Gather context** says."

cite_case 1 $orch "a hyphenated numbered step cited in quotes fails section 18" "present: a step name cited in quotes of /dev:implement-story in $scratch/$orch" "As \`/dev:implement-story\`'s \"Re-evaluate the frontier\" says."

cite_case 1 $orch "a hyphenated indented step cited in quotes fails section 18" "present: a step name cited in quotes of /dev:implement-spec in $scratch/$orch" "As \`/dev:implement-spec\`'s \"Fix-up\" says."

cite_case 1 $orch "an indented step cited in quotes in the word order fails section 18" "present: a step name cited in quotes of /dev:implement-story in $scratch/$orch" "As the \"Merge guard\" of \`/dev:implement-story\` says."

cite_case 1 $orch "an indented step of implement-task cited in quotes fails section 18" "present: a step name cited in quotes of /dev:implement-task in $scratch/$orch" "As \`/dev:implement-task\`'s \"Close at delivery\" says."

cite_case 1 $orch "an indented step cited bare in the word order fails section 18" "present: a bare cite of /dev:implement-spec in $scratch/$orch" "As the Cut off sweep of \`/dev:implement-spec\` says."

cite_case 1 $orch "punctuation inside the quotes still fails section 18" "present: a step name cited in quotes of /dev:implement-story in $scratch/$orch" "As \`/dev:implement-story\`'s \"Story gate,\" says."

cite_case 1 $orch "punctuation inside the bold still fails section 18" "present: a heading cited in bold of /dev:task-orchestrator in $scratch/$orch" "As \`/dev:task-orchestrator\`'s **Two entries.** says."

cite_case 1 $orch "a step name in quotes before 'in' fails section 18" "present: a step name cited in quotes of /dev:implement-story in $scratch/$orch" "As the \"Clean up\" step in \`/dev:implement-story\` says."

cite_case 1 $orch "a step name in quotes after 'step' fails section 18" "present: a step name cited in quotes of /dev:implement-story in $scratch/$orch" "As \`/dev:implement-story\`'s step \"Clean up\" says."

cite_case 1 $orch "two words before 'of' still fail section 18" "present: a step name cited in quotes of /dev:implement-story in $scratch/$orch" "As the \"Clean up\" final sweep of \`/dev:implement-story\` says."

cite_case 0 $orch "the right forms of numbered headings and indented steps pass section 18" "" "As \`/dev:close-story\`'s \"The forge shows MERGED\", the **Merge guard** step in \`/dev:implement-story\` and \`/dev:story-to-tasks\`'s \"Gather context\" say."

# names with punctuation (dev-mnz6 review 2): parentheses, a backtick, a comma, in headings and in
# period-marked steps, each reaching the check queue with its regex characters escaped
cite_case 1 $orch "a heading with parentheses cited in bold fails section 18" "present: a heading cited in bold of /dev:story-to-tasks in $scratch/$orch" "As \`/dev:story-to-tasks\`'s **Explore the codebase (optional)** says."

cite_case 1 $orch "a heading with parentheses cited bare fails section 18" "present: a bare cite of /dev:story-to-tasks in $scratch/$orch" "As the Explore the codebase (optional) step of \`/dev:story-to-tasks\` says."

cite_case 1 $orch "a heading with a backtick cited in bold fails section 18" "present: a heading cited in bold of /dev:close-story in $scratch/$orch" "As \`/dev:close-story\`'s **The \`pr:\` note exists** says."

cite_case 1 $orch "a heading with a comma cited in bold fails section 18" "present: a heading cited in bold of /dev:spec-to-tasks in $scratch/$orch" "As \`/dev:spec-to-tasks\`'s **Comment on the Jira epic, and end** says."

cite_case 1 $orch "a period-marked step with a comma cited in quotes fails section 18" "present: a step name cited in quotes of /dev:story-to-tasks in $scratch/$orch" "As \`/dev:story-to-tasks\`'s \"Dependency pair, per edge\" says."

cite_case 1 $orch "a period-marked step with a backtick cited in quotes fails section 18" "present: a step name cited in quotes of /dev:task-orchestrator in $scratch/$orch" "As \`/dev:task-orchestrator\`'s \"\`git\` rule\" says."

cite_case 0 $orch "the right forms of names with punctuation pass section 18" "" "As \`/dev:close-story\`'s \"The \`pr:\` note exists\", \`/dev:story-to-tasks\`'s \"Explore the codebase (optional)\" and the **Dependency pair, per edge** step of \`/dev:story-to-tasks\` say."

# a regex character in a name is no operator: a parenthesised name's text without its parentheses is no cite
cite_case 0 $orch "a name's parentheses are matched as characters in section 18" "" "As \`/dev:story-to-tasks\`'s **Explore the codebase optional** says."

# the line-break case of each new form, the 's section alternative, step/section bare and a name that is both
cite_case 1 $orch "a step name in quotes split across a line break fails section 18" "present: a step name cited in quotes of /dev:implement-story in $scratch/$orch" "As \`/dev:implement-story\`'s" "\"Story gate\" says."

cite_case 1 $orch "a heading in bold split across a line break fails section 18" "present: a heading cited in bold of /dev:task-orchestrator in $scratch/$orch" "As \`/dev:task-orchestrator\`'s" "**Two entries** says."

cite_case 1 $orch "a bare cite in the word order split across a line break fails section 18" "present: a bare cite of /dev:implement-story in $scratch/$orch" "As the Landing section of" "\`/dev:implement-story\` says."

cite_case 1 $orch "a heading in bold after 'section' fails section 18" "present: a heading cited in bold of /dev:task-orchestrator in $scratch/$orch" "As \`/dev:task-orchestrator\`'s section **Two entries** says."

cite_case 1 $orch "a bare heading after 'section' fails section 18" "present: a bare cite after a possessive and step or section of /dev:task-orchestrator in $scratch/$orch" "As \`/dev:task-orchestrator\`'s section Two entries says."

cite_case 1 $orch "a bare step name after 'step' fails section 18" "present: a bare cite after a possessive and step or section of /dev:implement-story in $scratch/$orch" "As \`/dev:implement-story\`'s step Clean up says."

# a name that is both a step and a heading in one skill has no wrong marking: quotes and bold pass,
# only the bare forms fail (dev-mnz6 review 3)
fresh
printf '%s\n' "## Zed gate" "" "**Zed gate.** A step." >> "$scratch/skills/implement-story/SKILL.md"
printf '%s\n' "As \`/dev:implement-story\`'s \"Zed gate\" and its **Zed gate** say." >> "$scratch/$orch"
expect "a name both a step and a heading cited in quotes passes section 18" 0

fresh
printf '%s\n' "## Zed gate" "" "**Zed gate.** A step." >> "$scratch/skills/implement-story/SKILL.md"
printf '%s\n' "As \`/dev:implement-story\`'s **Zed gate** says." >> "$scratch/$orch"
expect "a name both a step and a heading cited in bold passes section 18" 0

fresh
printf '%s\n' "## Zed gate" "" "**Zed gate.** A step." >> "$scratch/skills/implement-story/SKILL.md"
printf '%s\n' "As the Zed gate step of \`/dev:implement-story\` says." >> "$scratch/$orch"
sec=18 expect "a name both a step and a heading cited bare fails section 18" 1 "present: a bare cite of /dev:implement-story in $scratch/$orch"

# a skill is always named in backticks, and a name is never set in them (dev-hcn9)
bare_msg="present: a skill not in backticks beside a cited name of"
bt_msg="present: a name cited in backticks of"
q_msg="present: a step name cited in quotes of"
pos_msg="present: a bare cite after a possessive and step or section of"
cite_msg="present: a bare cite of"
bold_msg="present: a heading cited in bold of"
first_msg="present: a bare skill-first cite of"
SK=/dev:implement-story
# zed_step: a step and a heading both named Zed gate in /dev:implement-story, so a name of kind both
zed_step() { printf '%s\n' "## Zed gate" "" "**Zed gate.** A step." >> "$scratch/skills/implement-story/SKILL.md"; }
# cite_pairs <file> <what> (<message> <form>)...: each form, appended to the file in a fresh tree
# (after $prep, a function to run in it, when set), fails section 18 with the message beside it;
# for seeds that fail on different checks
cite_pairs() {
  local file=$1 what=$2
  shift 2
  [ $(($# % 2)) -eq 0 ] || { echo "cite_pairs: odd argument count for '$what'" >&2; exit 2; }
  while [ $# -ge 2 ]; do cite_seeds 1 "$file" "$1" "$what" "$2"; shift 2; done
}
# cite_seeds <want: 1 fails, 0 passes> <file> <message> <what> <form>...: each form, appended to
# the file in a fresh tree ($prep first, when set), fails section 18 with the message (want 1) or
# passes it (want 0, the message ""); the helper for a list of seeds that share one verdict and
# one message
cite_seeds() {
  local want=$1 file=$2 msg=$3 what=$4 form verdict=passes
  shift 4
  [ "$want" = 1 ] || [ -z "$msg" ] || { echo "cite_seeds: a passing seed takes no message" >&2; exit 2; }
  [ "$want" = 1 ] && verdict=fails
  for form in "$@"; do cite_case "$want" "$file" "$what ($form) $verdict section 18" "$msg" "$form"; done
}
# a name of kind both in backticks fails, the skill bare or not (the backtick check has no kind
# filter; the marks beside a bare skill are seeded further down)
prep=zed_step cite_seeds 1 $orch "$bt_msg" "a name of kind both in backticks" \
  "As /dev:implement-story's \`Zed gate\` says." \
  "As \`/dev:implement-story\`'s \`Zed gate\` says."

# the cite rule file needs its heading (dev-7mkq.1.5): without it section 18 fails naming it
fresh
sed -i.bak "s/^# Another skill's rule is cited in one form/# Another rule/" "$scratch/.claude/rules/cross-skill-cites.md" && rm "$scratch/.claude/rules/cross-skill-cites.md.bak"
sec=18 expect "the cite rule file without its heading fails section 18" 1 "missing: the cross-skill cite rule heading"

# the cite rule binds a skill doc too (dev-xyrl): a wrong cite of another skill's rule in a
# SKILL.md fails section 18 in the bare and quoted forms, and the right forms pass
fresh
printf '%s\n' "As \`/dev:task-orchestrator\`'s Two entries says." >> "$scratch/skills/implement-task/SKILL.md"
sec=18 expect "a bare heading cite in a SKILL.md fails section 18" 1 "present: an unquoted heading cite of a skill in $scratch/skills/implement-task/SKILL.md"

fresh
printf '%s\n' "As \`/dev:implement-story\`'s \"Story gate\" says." >> "$scratch/skills/implement-task/SKILL.md"
sec=18 expect "a step name cited in quotes in a SKILL.md fails section 18" 1 "present: a step name cited in quotes of /dev:implement-story in $scratch/skills/implement-task/SKILL.md"

fresh
printf '%s\n' "As \`/dev:task-orchestrator\`'s \"Two entries\" says, and \`/dev:implement-story\`'s **Story gate**." >> "$scratch/skills/implement-task/SKILL.md"
expect "right-form cites in a SKILL.md pass section 18" 0

# a skill's own steps and headings are no cross-skill cite (dev-xyrl review 1): a SKILL.md citing
# its own rule in the wrong form, bare included, passes section 18
fresh
printf '%s\n' "As \`/dev:implement-story\`'s \"Story gate\" says." >> "$scratch/skills/implement-story/SKILL.md"
expect "a skill's own step cited in quotes in its SKILL.md passes section 18" 0

fresh
printf '%s\n' "As \`/dev:implement-story\`'s **Landing** section says." >> "$scratch/skills/implement-story/SKILL.md"
expect "a skill's own heading cited in bold in its SKILL.md passes section 18" 0

fresh
printf '%s\n' "As \`/dev:implement-story\`'s Landing says." >> "$scratch/skills/implement-story/SKILL.md"
expect "a skill's own heading cited bare in its SKILL.md passes section 18" 0

# the lint skips a file that never names a skill, and that reading limits no skill's name: one
# with a digit in it is cited like any other
fresh
mkdir "$scratch/skills/zed2"
printf '%s\n' "---" "name: zed2" "description: A skill whose name holds a digit." "---" "" "# Zed2" "" "## Zed gate" >> "$scratch/skills/zed2/SKILL.md"
printf '%s\n' "As the Zed gate of \`/dev:zed2\` says." >> "$scratch/$orch"
sec=18 expect "a bare cite of a skill with a digit in its name fails section 18" 1 "present: a bare cite of /dev:zed2 in $scratch/$orch"

# a #### heading is a cite target
fresh
printf '%s\n' "#### Deep gate" >> "$scratch/skills/implement-story/SKILL.md"
printf '%s\n' "As \`/dev:implement-story\`'s **Deep gate** says." >> "$scratch/$orch"
sec=18 expect "a #### heading cited in bold fails section 18" 1 "present: a heading cited in bold of /dev:implement-story in $scratch/$orch"

# crossed step/section words are read in both checks
cite_case 1 $orch "a step name in quotes after 'section' fails section 18" "present: a step name cited in quotes of /dev:implement-story in $scratch/$orch" "As \`/dev:implement-story\`'s section \"Story gate\" says."

# the stated limits pass: a gap of three words, 'of the skill'
cite_case 0 $orch "a gap longer than two words passes section 18" "" "As the Story gate one more thing step of \`/dev:implement-story\` says."

cite_case 0 $orch "a bare cite of 'the /dev:x skill' passes section 18" "" "As the Story gate of the \`/dev:implement-story\` skill says."

# a bare skill beside a name: the right mark fails as a bare skill, any other form fails on its own check
cite_pairs $orch "a bare skill beside a name" \
  "$q_msg" "As $SK's \"Story gate\" says." \
  "$bare_msg" "As the **Clean up** sweep of $SK says." \
  "$q_msg" "As $SK \"Story gate\" says." \
  "$q_msg" "As $SK, \"Story gate\" says." \
  "$bare_msg" "As $SK **Story gate** says." \
  "$bare_msg" "As $SK: **Story gate** says." \
  "$bare_msg" "As $SK's **Story gate** says." \
  "$q_msg" "As $SK's \"Story gate.\" says." \
  "$cite_msg" "As the Story gate step of $SK says." \
  "$pos_msg" "As $SK's story gate says." \
  "$q_msg" "As the \"Story gate\" step of $SK says." \
  "$bare_msg" "As the **Story gate** step in $SK says."
cite_case 1 $orch "a skill cited without backticks after a possessive fails section 18" "$bare_msg /dev:task-orchestrator in $scratch/$orch" "As /dev:task-orchestrator's \"Two entries\" says."
cite_case 1 $orch "a heading in quotes beside a bare skill fails section 18" "$bare_msg /dev:task-orchestrator in $scratch/$orch" "As /dev:task-orchestrator \"Two entries\" and /dev:task-orchestrator's \"Two entries\" say."

# prose with a bare skill that cites no known name passes: the lint reads known names only
cite_seeds 0 $orch "" "a bare skill citing no known name" "Run $SK and see its plumbing." "The word \"foo\" in $SK is prose." "The story reads $SK's Jira key from the bead." "The **foo** of $SK is prose." "As $SK's own step says."

# a skill's own bare name in its SKILL.md is no cross-skill cite
fresh
printf '%s\n' "As $SK's **Story gate** says." >> "$scratch/skills/implement-story/SKILL.md"
expect "a skill's own steps cited beside its bare skill pass section 18" 0

# a name in backticks, in all three orders, with punctuation inside the marks too
cite_seeds 1 $orch "$bt_msg /dev:implement-story in $scratch/$orch" "a step name in backticks" \
  "As \`/dev:implement-story\`'s \`Story gate\` says." \
  "As \`/dev:implement-story\` \`Story gate\` says." \
  "As /dev:implement-story \`Story gate\` says." \
  "As \`/dev:implement-story\`'s \`Story gate.\` says." \
  "As the \`Story gate,\` step of \`/dev:implement-story\` says." \
  "As \`/dev:implement-story\`: \`Story gate\` says." \
  "As \`/dev:implement-story\`'s \`story gate\` says."
cite_case 1 $orch "a heading cited in backticks fails section 18" "$bt_msg /dev:task-orchestrator in $scratch/$orch" "As \`/dev:task-orchestrator\`'s \`Two entries\` says."
cite_case 1 $orch "a heading in backticks in the word order fails section 18" "$bt_msg /dev:task-orchestrator in $scratch/$orch" "As the \`Two entries\` heading of \`/dev:task-orchestrator\` says."
cite_case 1 $orch "a heading in backticks skill-first fails section 18" "$bt_msg /dev:task-orchestrator in $scratch/$orch" "As \`/dev:task-orchestrator\` \`Two entries\` says."

# backticks around a name that is also in bold or quotes, or around the mark itself, fail in all
# three orders with the skill backticked or bare
cite_seeds 1 $orch "$bt_msg" "a marked name in backticks" \
  "As \`/dev:implement-story\`'s **\`Story gate\`** says." \
  "As the **\`Story gate\`** step of \`/dev:implement-story\` says." \
  "As \`/dev:implement-story\` **\`Story gate\`** says." \
  "As \`/dev:task-orchestrator\`'s \"\`Two entries\`\" says." \
  "As \`/dev:task-orchestrator\` \"\`Two entries\`\" says." \
  "As \`/dev:implement-story\`'s \`**Story gate**\` says." \
  "As the \`**Story gate**\` step of \`/dev:implement-story\` says." \
  "As \`/dev:implement-story\` \`**Story gate**\` says." \
  "As \`/dev:close-story\`'s \"\`The forge shows MERGED\`\" says." \
  "As \`/dev:close-story\`'s \`\"The forge shows MERGED\"\` says." \
  "As \`/dev:implement-story\`'s **\`Story gate.\`** says."
cite_seeds 1 $orch "$bt_msg" "a marked name in backticks beside a bare skill" \
  "As $SK's **\`Story gate\`** says." \
  "As the **\`Story gate\`** step of $SK says." \
  "As $SK **\`Story gate\`** says." \
  "As $SK's \`**Story gate**\` says."

# punctuation between the closing backtick and an outer mark, and between an inner mark and the
# closing backtick, fails in all three orders, the skill backticked or bare
cite_seeds 1 references/seed.md "$bt_msg" "a name in backticks with punctuation among the marks" \
  "As the \`Story gate\`**.** step of \`/dev:implement-story\` says." \
  "As the \"\`Two entries\`,\" heading of \`/dev:task-orchestrator\` says." \
  "As the \`Story gate\`**.** step of $SK says." \
  "As the \`**Story gate**.\` step of \`$SK\` says." \
  "As the \"\`Two entries\`\", heading of \`/dev:task-orchestrator\` says." \
  "As the \`\"Two entries\",\` heading of /dev:task-orchestrator says." \
  "As \`$SK\`'s \`**Story gate**.\` says." \
  "As \`/dev:task-orchestrator\`'s \`\"Two entries\";\` says." \
  "As \`$SK\` \`**Story gate**.\` says." \
  "As \`/dev:task-orchestrator\` \`\"Two entries\",\` says." \
  "As $SK's \`**Story gate**.\` says." \
  "As \`/dev:task-orchestrator\`'s \`Two entries\`**,** says." \
  "As \`$SK\`'s \`Story gate\`.** says."

# the bare of/in gap takes none, one or two words between the name and "of"/"in" (a bare skill):
# the first and second word, and the zero-word end, are each pinned
cite_seeds 1 $orch "$bare_msg" "a bare of/in gap of zero, one or two words" \
  "As the **Story gate** of $SK says." \
  "As the \"Two entries\" of /dev:task-orchestrator says." \
  "As the **Story gate** final step of $SK says." \
  "As the \"Two entries\" named heading of /dev:task-orchestrator says." \
  "As the **Story gate** step text of $SK says." \
  "As the \"Two entries\" heading text of /dev:task-orchestrator says."

# each of the four marks (. , ; :) is read among the marks of a name in backticks: a colon inside
# the backticks, a semicolon or colon outside them, and a semicolon after the closing backtick of
# a bare name
cite_seeds 1 $orch "$bt_msg" "a colon or semicolon among the marks of a name in backticks" \
  "As the \`Story gate:\` step of \`$SK\` says." \
  "As \`$SK\`'s \`Story gate:\` says." \
  "As \`$SK\`'s **\`Story gate:\`** says." \
  "As \`$SK\` \`Story gate:\` says." \
  "As the **\`Story gate\`;** step of \`$SK\` says." \
  "As the **\`Story gate\`:** step of \`$SK\` says." \
  "As the \`Story gate\`**;** step of \`$SK\` says." \
  "As the \`Story gate\`**:** step of \`$SK\` says."
cite_seeds 1 $orch "$cite_msg" "a semicolon after the closing backtick of a bare name" \
  "As the Story gate\`; step of \`$SK\` says." \
  "As the Story gate\`; step of $SK says."

# a bare skill beside a known name fails when only the prefilter could pass it: a doc that names the
# skill bare, never in backticks
cite_seeds 1 references/sample.md "$bare_msg" "a doc naming a skill only bare" \
  "As $SK's \"Story gate\" and /dev:task-orchestrator's \"Two entries\" say."

# a name of kind both beside a bare skill fails in each right mark
prep=zed_step cite_seeds 1 $orch "$bare_msg" "a name of kind both beside a bare skill" \
  "As $SK's **Zed gate** says." \
  "As $SK's \"Zed gate\" says." \
  "As the **Zed gate** step of $SK says." \
  "As the \"Zed gate\" step of $SK says."

# a capital word after a backticked possessive is a heading cite, known name or not
cite_seeds 1 $orch "present: an unquoted heading cite of a skill in $scratch/$orch" "a capital after a backticked possessive" \
  "As \`$SK\`'s Jira key says."
# the same for a skill with no directory (a backticked possessive, a bare heading), and a skill's own
# bare cite still passes (dev-ouzn)
fresh
printf '%s\n' "As \`/dev:gone\`'s Two entries says." >> "$scratch/$orch"
sec="11 18" expect "a backticked possessive and bare heading of a skill with no directory fails sections 11 and 18" 1 "present: an unquoted heading cite of a skill in $scratch/$orch"
fresh
printf '%s\n' "As \`/dev:implement-task\`'s Two entries says." >> "$scratch/skills/implement-task/SKILL.md"
# guards the new no-directory loop against re-adding the file's own skill to the pattern
expect "a skill's own bare cite in its SKILL.md passes section 18" 0

# the shapes the rule leaves open pass: a backtick on one side of a name alone, and the one
# unspaced em dash; bold with backticks inside or around is read, bold with quotes is not; a
# one-sided bold or quote mark, and a stray backtick beside a right mark, are not read either
cite_seeds 0 $orch "" "an open shape" "As $SK's \`Story gate says." "As ${SK}—**Story gate** says." "As \`$SK\`'s **\"Story gate\"** says." "As the **Story gate step of \`$SK\` says." "As \`/dev:task-orchestrator\`'s \"Two entries says." "As the Two entries\" heading of \`/dev:task-orchestrator\` says." "As the \`**Story gate** step of \`$SK\` says." "As \`$SK\`'s **Story gate**\` says." "As \`/dev:task-orchestrator\`'s \`\"Two entries\" says."

# a mark that closes a name never opened is read after the possessive and skill-first, where the
# name reads bare; in the of/in order it passes (the open shape above)
cite_seeds 1 $orch "$pos_msg" \
  "a mark closing a name never opened after the possessive" "As $SK's Story gate** says."
cite_seeds 1 $orch "$first_msg" "a mark closing a name never opened skill-first" \
  "As $SK Story gate** says."

# a parenthesis around the whole cite is read; one between the skill and the name, or before the
# skill in the of/in order, is outside what the lint reads
cite_seeds 1 $orch "$bare_msg" "a skill in parentheses around the whole cite" \
  "As ($SK's **Story gate**) says."
cite_seeds 0 $orch "" "a parenthesis inside a cite" "As the **Story gate** step of ($SK) says." "As the Story gate step of ($SK) says." "As the \"Story gate\" step of ($SK) says." "As the \"Two entries\" heading of (/dev:task-orchestrator) says." "As ($SK) **Story gate** says." "As ($SK) \"Story gate\" says." "As ($SK) Story gate says." "As ($SK)'s **Story gate** says." "As ($SK)'s \"Story gate\" says."

# a backtick straight before a name that follows the skill or its possessive (after an optional
# step or section) is outside what the lint reads; the same backtick after the name is read
cite_seeds 0 $orch "" "a backtick before a name" "As $SK's step \`Story gate says." "As $SK's section \`Story gate says." "As /dev:task-orchestrator's section \`Two entries says." "As $SK the \`Story gate says."
cite_seeds 1 $orch "$pos_msg" "a backtick after a name" \
  "As $SK's step Story gate\` says." \
  "As /dev:task-orchestrator's section Two entries\` says."
# the skill-first order reads a backtick after a bare name too, with a space after it
cite_seeds 1 $orch "$first_msg" "a backtick after a bare name, skill-first" \
  "As $SK Story gate\` says."

# a stray backtick after a bare name in the of/in order is read only with a space after it, or
# after one period, comma, colon or semicolon that follows it
cite_case 0 $orch "a backtick after a bare name with no space after it passes section 18" "" "As the Story gate\`.step of $SK says."
# that closing backtick is unread only in the of/in order: after the possessive or the skill it
# still sits beside a space and the name is unread
cite_seeds 0 $orch "" "a backticked name with a space inside the backticks after a skill" \
  "As \`$SK\`'s \` Story gate\` says." \
  "As $SK \` Story gate\` says."

# a space before a name in backticks is read in the of/in order, where the closing backtick after the
# name leaves it bare; after the possessive and skill-first it is unread (the cases above)
cite_seeds 1 $orch "$cite_msg" "a space before a name in backticks in the of/in order" \
  "As the \` Story gate\` step of $SK says."

# a lower-case phrase that spells a name before in/of the skill is read too
cite_seeds 1 $orch "$cite_msg" "a name spelled in lower case in prose" \
  "Run bd story gate in $SK first."

# a backtick around the possessive: the skill form of the any-form branch
cite_pairs $orch "a backtick around a possessive" \
  "$pos_msg" "As \`/dev:task-orchestrator's\` Two entries says." \
  "$q_msg" "As \`$SK's\` \"Story gate\" says." \
  "$pos_msg" "As \`$SK's\` Story gate says."

# a backtick straight after a bare name in the of/in order leaves it bare, with a gap of 0 to 2
# words and the skill in any form
cite_seeds 1 $orch "$cite_msg" "a backtick after a bare name" \
  "As the Story gate\` step of $SK says." \
  "As the Story gate\` step of \`$SK\` says." \
  "As the Two entries\` heading of /dev:task-orchestrator says." \
  "As the Story gate\` of $SK says." \
  "As the Story gate\` in \`$SK says." \
  "As the Story gate\`. step of $SK says."

# punctuation right after the marks (a period, comma, colon or semicolon) is read in the of/in order
cite_pairs $orch "punctuation after the marks" \
  "$bt_msg" "As the **\`Story gate\`**. step of \`/dev:implement-story\` says." \
  "$bt_msg" "As the \`Story gate\`, step of \`/dev:implement-story\` says." \
  "$bare_msg" "As the **Story gate**. step of /dev:implement-story says." \
  "$bare_msg" "As the \"Two entries\"; heading of /dev:task-orchestrator says." \
  "$q_msg" "As the \"Story gate\", step of \`$SK\` says." \
  "$q_msg" "As the \"Story gate\": step of \`$SK\` says." \
  "$bold_msg" "As the **Two entries**: heading of \`/dev:task-orchestrator\` says." \
  "$cite_msg" "As the Story gate\`, step of \`$SK\` says." \
  "$cite_msg" "As the Story gate\`: step of \`$SK\` says."

# a backtick that is part of a name stays in the name: **`git` rule.** is cited in bold
cite_seeds 0 $orch "" "a name holding backticks cited in bold" "As \`/dev:task-orchestrator\`'s **\`git\` rule** says." "As the **\`git\` rule** of \`/dev:task-orchestrator\` says." "As \`/dev:task-orchestrator\` **\`git\` rule** says."

# a skill with a stray backtick (one end, or swallowing the possessive) is not in backticks
cite_seeds 1 $orch "$bare_msg $SK in $scratch/$orch" "a skill with a stray backtick" \
  "As \`$SK's\` **Story gate** says." \
  "As $SK\`'s **Story gate** says." \
  "As \`$SK's **Story gate** says." \
  "As \`$SK **Story gate** says." \
  "As $SK\` **Story gate** says." \
  "As the **Clean up** sweep of $SK\` says."

# a backtick before the skill in the of/in order, beside a right mark, leaves the skill read as
# backticked whatever follows it: a skill with arguments or a suffix, words, punctuation or none
cite_seeds 0 $orch "" "a backtick before the skill in the of/in order" \
  "As the **Story gate** step of \`$SK dev-abc\` says." \
  "As the **Story gate** step of \`$SK INFRA-12\` says." \
  "As the \"Two entries\" heading of \`/dev:task-orchestrator dev-abc\` says." \
  "As the **Story gate** step of \`$SK 12\` says." \
  "As the **Story gate** step of \`$SK <dependent story-id>\` says." \
  "As the \"Two entries\" heading of \`/dev:task-orchestrator <id> again\` says." \
  "As the **Story gate** step of \`$SK <id> foo\` says." \
  "As the **Story gate** step of \`$SK \"x\"\` says." \
  "As the **Story gate** step of \`$SK:x\` says." \
  "As the **Story gate** step of \`$SK.1\` says." \
  "As the **Story gate** step of \`${SK}_x\` says." \
  "As the **Story gate** step of \`$SK, x\` says." \
  "As the **Story gate** step of \`$SK?\` says." \
  "As the **Story gate** step of \`$SK story <id>\` says." \
  "As the **Story gate** step of \`$SK <id> story\` says." \
  "As the **Story gate** step of \`$SK <a b>\` says." \
  "As the **Story gate** step of \`$SK [id]\` says." \
  "As the **Story gate** step of \`$SK =x\` says." \
  "As the **Clean up** sweep of \`$SK says." \
  "As the **Clean up** sweep of \`$SK, says." \
  "As the **Clean up** sweep of \`$SK. Then more." \
  "As the \"Two entries\" heading of \`/dev:task-orchestrator; says." \
  "As the **Story gate** step of \`$SK. says." \
  "As the **Story gate** step of \`$SK <id> says." \
  "As the \"Two entries\" heading of \`/dev:task-orchestrator <id> says."

# a stray closing backtick after a bare possessive is not in backticks either, in both name marks
cite_seeds 1 $orch "$bare_msg" "a bare possessive with a stray closing backtick" \
  "As $SK's\` **Story gate** says." \
  "As /dev:task-orchestrator's\` \"Two entries\" says."

# a skill and its argument inside one backtick pair is a backticked skill: the right marking
# beside it passes, in the of/in order too
cite_seeds 0 $orch "" "a backticked skill with an argument" \
  "As the **Story gate** step of \`$SK <id>\` says." \
  "As the \"Two entries\" heading of \`/dev:task-orchestrator <id>\` says." \
  "As the **Story gate** step of \`$SK/x\` says." \
  "As the **Story gate** step of \`$SK <id> <x>\` says." \
  "As the \"Two entries\" heading of \`/dev:task-orchestrator <id> <x>\` says." \
  "As the **Story gate** step in \`$SK --flag <id>\` says." \
  "As the **Story gate** step of \`$SK.md\` says." \
  "As the **Story gate** step of \`$SK <id> --flag\` says." \
  "As the \"Two entries\" heading of \`/dev:task-orchestrator <id> <other>\` says."

# a bare, quoted, bold or backticked name before 'of' a backticked skill with an argument or a
# suffix is read in the of/in order and fails, whatever follows the skill inside the pair
cite_pairs $orch "a wrong-marked name before a backticked skill with an argument" \
  "$cite_msg" "Run the Story gate step of \`$SK <id>\` first." \
  "$q_msg" "As the \"Story gate\" step of \`$SK <id>\` says." \
  "$bold_msg" "As the **Two entries** heading of \`/dev:task-orchestrator <id>\` says." \
  "$cite_msg" "As the Two entries heading of \`/dev:task-orchestrator <id>\` says." \
  "$bt_msg" "As the \`Story gate\` step of \`$SK <id>\` says." \
  "$cite_msg" "Run the Story gate step of \`$SK/x\` first." \
  "$q_msg" "As the \"Story gate\" step of \`$SK/x\` says."

# bare skill beside a bare or quoted name in the of/in order, and a bare skill with a bare capital
cite_case 1 $orch "a heading in quotes before 'of' a bare skill fails section 18" "$bare_msg /dev:task-orchestrator in $scratch/$orch" "As the \"Two entries\" heading of /dev:task-orchestrator says."
cite_case 1 $orch "a bare capital heading after a bare possessive fails section 18" "present: a bare cite after a possessive and step or section of /dev:task-orchestrator in $scratch/$orch" "As /dev:task-orchestrator's Two entries says."

# bare-skill prose that spells a known name fails: the reword is the fix
cite_pairs $orch "bare-skill prose spelling a known name" \
  "$cite_msg" "Read the steps of $SK first." \
  "$cite_msg" "The landing in $SK is serial." \
  "$cite_msg" "The report of /dev:task-orchestrator goes up." \
  "$pos_msg" "/dev:task-orchestrator's report is one line." \
  "$first_msg" "Use /dev:triage, Report the items."

# the file edges of the bare skill's regexes: a cite ending the file with no final newline (the
# of/in order's end-of-line alternative), and one opening the file (the skill's start-of-line
# alternative), each alone in a new doc
# each text, written with no final newline to a new reference doc, fails section 18 with the message beside it
no_nl=1 cite_pairs references/seed.md "a bare skill ending a doc with no final newline" \
  "$bare_msg" "As the **Clean up** sweep of $SK" \
  "$bare_msg" "As the **Story gate** step of $SK" \
  "$cite_msg" "As the Story gate step of $SK" \
  "$q_msg" "As the \"Story gate\" step of $SK"
cite_seeds 1 references/seed.md "$bare_msg" "a bare skill opening a doc" \
  "$SK's **Story gate** says." \
  "$SK **Story gate** says."
# the right marking beside a bare skill fails only for a name of the bare skill: the cited name is
# another skill's, though /dev:setup-repo begins with /dev:setup
setup_names() { printf '%s\n' "## Foo bar" "" "**Foo bar.** A step." >> "$scratch/skills/setup/SKILL.md"; }
prep=setup_names cite_seeds 0 $orch "" "a bare /dev:setup-repo beside a name of /dev:setup" \
  "As the \"Foo bar\" heading of /dev:setup-repo says." \
  "As the **Foo bar** step of /dev:setup-repo says."
# a bare skill straight after a letter (either case; the check ignores case), a slash, a colon or a
# hyphen is no bare skill (a path or a prefix), so the right marking beside it passes: one seed
# per member of the class
cite_seeds 0 $orch "" "a skill name inside a path or a prefix" \
  "See foo$SK's **Story gate** says." \
  "See a$SK **Story gate** says." \
  "See z$SK **Story gate** says." \
  "See x:$SK **Story gate** says." \
  "See x-$SK **Story gate** says." \
  "See /$SK **Story gate** says." \
  "See Z$SK **Story gate** says."
# in the possessive and skill-first orders the wrong mark or a bare name beside a prefixed skill
# still fails: those checks read the skill anywhere
cite_pairs $orch "a wrong mark or bare name beside a prefixed skill" \
  "$q_msg" "See foo$SK's \"Story gate\" says." \
  "$pos_msg" "See foo$SK's Story gate says." \
  "$q_msg" "See foo$SK \"Story gate\" says." \
  "$first_msg" "See foo$SK Story gate says." \
  "$bold_msg" "See foo/dev:task-orchestrator's **Two entries** says."
# in the of/in order a skill with any character but a space or a backtick straight before it (a
# letter, slash, colon or hyphen among them) is not read at all, so even a wrong mark or a bare
# name passes
cite_seeds 0 $orch "" "a prefixed skill in the of/in order" \
  "As the \"Story gate\" step of foo$SK says." \
  "As the Story gate step of foo$SK says." \
  "As the **Two entries** heading of foo/dev:task-orchestrator says." \
  "As the \`Story gate\` step of foo$SK says." \
  "As the \"Story gate\" step of x-$SK says." \
  "As the \"Story gate\" step of /$SK says."
# a gap word with a hyphen is not a word of letters, so the of/in order does not read it
cite_seeds 0 $orch "" "a hyphenated gap word in the of/in order" \
  "As the **Story gate** well-known step of $SK says." \
  "As the \"Story gate\" well-known step of \`$SK\` says."
# a suffix other than a letter or hyphen leaves a bare skill bare in the of/in order
cite_seeds 1 $orch "$bare_msg" "a bare skill with a suffix" \
  "As the **Story gate** step of $SK.md says." \
  "As the **Story gate** step of $SK/x says." \
  "As the **Story gate** step of ${SK}_x says."
# any other character before it leaves the skill bare, so the same marking fails
cite_seeds 1 $orch "$bare_msg" "a bare skill after a character outside that class" \
  "See 1$SK's **Story gate** says." \
  "See ($SK's **Story gate**) says."

# a skill whose name is the start of another's (/dev:setup, /dev:setup-repo) is not read inside it
fresh
printf '%s\n' "## Foo bar" >> "$scratch/skills/setup/SKILL.md"
printf '%s\n' "As the Foo bar step of \`/dev:setup-repo\` says, and the Foo bar step of /dev:setup-repo." >> "$scratch/$orch"
expect "a name of /dev:setup cited before 'of' /dev:setup-repo passes section 18" 0
fresh
printf '%s\n' "## Foo bar" >> "$scratch/skills/setup/SKILL.md"
printf '%s\n' "As the Foo bar step of \`/dev:setup\` says." >> "$scratch/$orch"
sec=18 expect "a name of /dev:setup cited before 'of' /dev:setup still fails section 18" 1 "present: a bare cite of /dev:setup in $scratch/$orch"

# a backticked word that is no known name passes
cite_case 0 $orch "a backticked word that is no known name passes section 18" "" "Run \`git status\` in \`/dev:implement-story\`, then see \`/dev:implement-story\`'s \`notes\`."

# the [A-Z] branch for a skill with a bare capital after a backticked possessive, and the quote
# form after a bare possessive in a SKILL.md of another skill
fresh
printf '%s\n' "As \`/dev:task-orchestrator\`'s Two entries says." >> "$scratch/skills/implement-task/SKILL.md"
sec=18 expect "a capital heading after a backticked possessive in a SKILL.md fails section 18" 1 "present: an unquoted heading cite of a skill in $scratch/skills/implement-task/SKILL.md"
fresh
printf '%s\n' "As /dev:task-orchestrator's \"Two entries\" says." >> "$scratch/skills/implement-task/SKILL.md"
sec=18 expect "a bare skill in a SKILL.md fails section 18" 1 "$bare_msg /dev:task-orchestrator in $scratch/skills/implement-task/SKILL.md"

# skill-first and case-changed wrong cites (dev-wh65): the skill directly before a step name in
# quotes or a heading in bold (a marked name whose case changed is seeded in a doc of its own below)
cite_case 1 $orch "a skill-first step name in quotes fails section 18" "present: a step name cited in quotes of /dev:implement-story in $scratch/$orch" "As \`/dev:implement-story\` \"Story gate\" says."

cite_case 1 $orch "a skill-first heading in bold fails section 18" "present: a heading cited in bold of /dev:task-orchestrator in $scratch/$orch" "As \`/dev:task-orchestrator\`, **Two entries** says."

cite_case 0 $orch "the right marking skill-first passes section 18" "" "As \`/dev:implement-story\` **Story gate** and \`/dev:task-orchestrator\` \"Two entries\" say."

# review 1 of dev-wh65: a case-changed cite fails in a doc lacking the name's first word in its
# original case (the prefilter reads the file case-insensitively)
cite_case 1 references/seed.md "a case-changed step name in quotes fails in a doc without the original-case word" "present: a step name cited in quotes of /dev:implement-story in $scratch/references/seed.md" "As \`/dev:implement-story\`'s \"story gate\" says."

cite_case 1 references/seed.md "a case-changed heading in bold fails in a doc without the original-case word" "present: a heading cited in bold of /dev:task-orchestrator in $scratch/references/seed.md" "As the **two entries** section of \`/dev:task-orchestrator\` says."

# a bare name in another case, in every order
cite_case 1 references/seed.md "a lower-case bare name after the possessive fails section 18" "present: a bare cite after a possessive and step or section of /dev:implement-story in $scratch/references/seed.md" "As \`/dev:implement-story\`'s story gate says."

cite_case 1 references/seed.md "a lower-case bare name before 'of' fails section 18" "present: a bare cite of /dev:implement-story in $scratch/references/seed.md" "As the check gate of \`/dev:implement-story\` says, and the story gate of \`/dev:implement-story\`."

cite_case 1 references/seed.md "a bare skill-first step name fails section 18" "present: a bare skill-first cite of /dev:implement-story in $scratch/references/seed.md" "As \`/dev:implement-story\` Story gate says."

cite_case 1 references/seed.md "a bare skill-first heading after a comma fails section 18" "present: a bare skill-first cite of /dev:task-orchestrator in $scratch/references/seed.md" "As \`/dev:task-orchestrator\`, Two entries says."

# a lower-case word straight after a skill reads as prose (the real "`/dev:story-to-tasks` re-cut adds"),
# so a bare skill-first cite is caught in the name's own case only
cite_case 0 references/seed.md "a lower-case bare skill-first heading passes section 18" "" "As \`/dev:task-orchestrator\` two entries says."

# a skill-first marked cite with another separator or a link word
cite_seeds 1 references/seed.md "present: a step name cited in quotes of /dev:implement-story in $scratch/references/seed.md" "a skill-first step in quotes" \
  "As \`/dev:implement-story\`: \"Story gate\" says." \
  "As \`/dev:implement-story\` step \"Story gate\" says." \
  "As \`/dev:implement-story\` the \"Story gate\" step says." \
  "As \`/dev:implement-story\`; \"Story gate\" says." \
  "As \`/dev:implement-story\` - \"Story gate\" says." \
  "As \`/dev:implement-story\` \"story gate\" says."
cite_seeds 1 references/seed.md "present: a heading cited in bold of /dev:task-orchestrator in $scratch/references/seed.md" "a skill-first heading in bold" \
  "As \`/dev:task-orchestrator\` section **Two entries** says." \
  "As \`/dev:task-orchestrator\` — **Two entries** says." \
  "As \`/dev:task-orchestrator\`: **Two entries** says." \
  "As \`/dev:task-orchestrator\`; **Two entries** says." \
  "As \`/dev:task-orchestrator\` - **Two entries** says." \
  "As \`/dev:task-orchestrator\` **two entries** says."

# a bare skill-first name after a colon, "the", "step", a semicolon or a hyphen
cite_seeds 1 references/seed.md "present: a bare skill-first cite of /dev:implement-story in $scratch/references/seed.md" "a bare skill-first step name" \
  "As \`/dev:implement-story\`: Story gate says." \
  "As \`/dev:implement-story\` the Story gate says." \
  "As \`/dev:implement-story\` step Story gate says." \
  "As \`/dev:implement-story\`; Story gate says." \
  "As \`/dev:implement-story\` - Story gate says."

# a step and a heading differing only in case are one name of kind both: the right markings pass
fresh
printf '%s\n' "## Story Gate" >> "$scratch/skills/implement-story/SKILL.md"
printf '%s\n' "As \`/dev:implement-story\`'s **Story gate** and \`/dev:implement-story\`'s \"Story Gate\" say." > "$scratch/references/seed.md"
expect "a step and a heading differing in case take either marking in section 18" 0

# a skill gaining a name makes an unchanged reference doc's text a wrong cite (the doc's line 'sweep of
# /dev:implement-story' reads bare once the skill has a heading 'sweep')
fresh
printf '%s\n' "## sweep" >> "$scratch/skills/implement-story/SKILL.md"
sec=18 expect "a skill gaining a heading re-reads an unchanged reference doc in section 18" 1 "present: a bare cite of /dev:implement-story in $scratch/$orch"

# a bold label opening a list item (- **Owner** in /dev:triage) names no step, so it is no cite target
cite_case 0 $orch "a list label or a bare bold label is no step name in section 18" "" "The Owner of \`/dev:triage\` and the Alone of \`/dev:story-to-tasks\` are words."

# a bold lead-in with no period is a label, not a step name (dev-bjkt): the rule says so, so a
# lead-in that carries a rule is marked with a period inside the bold (**The set to cut.**) and
# a cite of it in quotes is the wrong form
cite_case 1 $orch "a rule-carrying lead-in cited in quotes fails section 18" "present: a step name cited in quotes of /dev:spec-to-tasks in $scratch/$orch" "As \`/dev:spec-to-tasks\`'s \"The set to cut\" says."

fresh
printf '%s\n' "**Zed label** is a label with no period." >> "$scratch/skills/implement-story/SKILL.md"
printf '%s\n' "As \`/dev:implement-story\`'s \"Zed label\" says." >> "$scratch/$orch"
expect "a bold lead-in with no period cited in quotes passes section 18" 0

# a step name opens a line, after an optional list marker; a bold term inside a sentence is none
# (dev-bjkt), so the lint and the rule agree on a list item and a mid-line shape
fresh
printf '%s\n' "- **Zed item.** A rule." >> "$scratch/skills/implement-story/SKILL.md"
printf '%s\n' "As \`/dev:implement-story\`'s \"Zed item\" says." >> "$scratch/$orch"
sec=18 expect "a list item step name cited in quotes fails section 18" 1 "present: a step name cited in quotes of /dev:implement-story in $scratch/$orch"

fresh
printf '%s\n' "- **Zed item.** A rule." >> "$scratch/skills/implement-story/SKILL.md"
printf '%s\n' "As \`/dev:implement-story\`'s **Zed item** says." >> "$scratch/$orch"
expect "a list item step name cited in bold passes section 18" 0

fresh
printf '%s\n' "  - **Zed item.** A rule." >> "$scratch/skills/implement-story/SKILL.md"
printf '%s\n' "As \`/dev:implement-story\`'s \"Zed item\" says." >> "$scratch/$orch"
sec=18 expect "an indented list item step name cited in quotes fails section 18" 1 "present: a step name cited in quotes of /dev:implement-story in $scratch/$orch"

fresh
printf '%s\n' "Some words, **Zed middle.** A rule." >> "$scratch/skills/implement-story/SKILL.md"
printf '%s\n' "As \`/dev:implement-story\`'s \"Zed middle\" says." >> "$scratch/$orch"
expect "a mid-line bold term is no step name in section 18" 0

fresh
printf '%s\n' "The wrong form: \`/dev:task-orchestrator\`'s Two entries." >> "$scratch/.claude/rules/cross-skill-cites.md"
expect "a bare heading cite in the cross-skill cite rule file passes section 18" 0

fresh
printf '%s\n' "The wrong forms: \`/dev:close-story\`'s **The forge shows MERGED**, \`/dev:implement-story\`'s \"Merge guard\" and the Landing section of \`/dev:implement-story\`." >> "$scratch/.claude/rules/cross-skill-cites.md"
expect "the other wrong forms in the cross-skill cite rule file pass section 18" 0

# every section 18 case kept above runs here
cite_flush
fx_check "the cite cases share their lint runs (under one run per ten cases)" \
  test "$(( (ncbatches + ncretried) * 10 ))" -lt "$cite_n"
# judge_cites alone, on a made-up spec and lint output: what it cannot vouch for goes to the retry
# file and never to an ok line
judge_cites_gives() { # <expected ok lines, |-joined> <expected retried descriptions, |-joined> <lint rc>
  local oks retried
  rm -f "$jobs/judged.retry"
  oks=$(BATCH_RETRY=$jobs/judged.retry BATCH_DIR=/d BATCH_SCRATCH=/s judge_cites "$jobs/judged.cites" "$(cat "$jobs/judged.lint")$nl$3" | sed 's/^ok   //' | paste -sd '|' -)
  retried=$(cut -f5 "$jobs/judged.retry" 2>/dev/null | paste -sd '|' -)
  [ "$oks" = "$1" ] && [ "$retried" = "$2" ]
}
printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
  1 1 plain a.md 'fires' 'present: x in /s/a.md' \
  1 2 plain a.md 'silent' 'present: x in /s/a.md' \
  1 3 plain a.md 'fires another check' 'present: x in /s/a.md' \
  0 4 plain a.md 'passes' '' \
  0 11 plain a.md 'named' '' > "$jobs/judged.cites"
printf '%s\n' '== 5. retired phrases' '== 18. cross-skill cites: /d/.claude/rules/cross-skill-cites.md' \
  'FAIL: present: x in /d/references/cite-1.md (p)' '1:text' \
  'FAIL: present: y in /d/references/cite-3.md (p)' 'FAIL: present: y in /d/references/cite-11.md (p)' > "$jobs/judged.lint"
fx_check "a cite batch vouches for a doc's own message and a quiet doc, and retries the rest" \
  judge_cites_gives 'fires|passes' 'silent|fires another check|named' 1
fx_check "a cite batch whose lint timed out vouches for nothing" \
  judge_cites_gives '' 'fires|silent|fires another check|passes|named' 124
printf '%s\n' 'FAIL: present: z in /d/references/orchestration.md (p)' >> "$jobs/judged.lint"
fx_check "a cite batch with a FAIL off its docs vouches for nothing" \
  judge_cites_gives '' 'fires|silent|fires another check|passes|named' 1
printf '%s\n' '== 5. retired phrases' 'FAIL: present: z in /d/references/cite-1.md (p)' '== 18. x' > "$jobs/judged.lint"
fx_check "a cite batch with a FAIL outside section 18 vouches for nothing" \
  judge_cites_gives '' 'fires|silent|fires another check|passes|named' 1

# the task row's budget regaining the conflict resolutions the landing took to the story row
fresh
pin_phrase "story row: three fix-ups and three conflict resolutions per landing"
story_budget=$pinned_phrase
pin_phrase "task row: three fix-ups"
pin_anchor "task row: three fix-ups"
an=$pinned_anchor tb=$pinned_phrase sb=$story_budget rewrite "$orch" awk '$0 ~ ENVIRON["an"] && (i = index($0, ENVIRON["tb"])) {
  $0 = substr($0, 1, i - 1) ENVIRON["sb"] substr($0, i + length(ENVIRON["tb"])) } { print }'
sec=6 expect "orchestration doc's Task row regaining the conflict resolutions fails" 1 "present: task row: a conflict resolution budget"
# a red check record counted as checked, seeded back in the orchestration doc (dev-6qi)
fresh
ban ban_any_record "a red check record counted as checked"
printf '\nA %s.\n' "$ban_any_record" >> "$scratch/$orch"
sec=6 expect "orchestration doc counting any check record as checked fails" 1 "present: a red check record counted as checked"
# a fix-up that commits nothing re-reading the red record, seeded back in the orchestration doc (dev-vnf)
fresh
ban ban_rereads_red "a fix-up that commits nothing re-reading the red record"
printf '\nSo %s.\n' "$ban_rereads_red" >> "$scratch/$orch"
sec=6 expect "orchestration doc letting a fix-up that commits nothing re-read the red record fails" 1 "present: a fix-up that commits nothing re-reading the red record"
# the Check gate's retired sentence naming the epic row as the budget's exception, seeded back
fresh
ban ban_epic_exception "the epic row named as the budget's exception"
printf '\n%s\n%s\n' "$ban_epic_exception: it spans runs while its PRs wait on their checks, so it counts each" \
  "story's budget from the story's \`epic fix-up\` notes (The epic row, above)." >> "$scratch/$orch"
sec=6 expect "orchestration doc naming the epic row as the budget's exception fails" 1 "present: the epic row named as the budget's exception"
# the accepted status is the frontmatter line itself: an amended status, or the words in the body, do not pass
fresh
pin_phrase "ADR 0014 is accepted"
status_line=${pinned_phrase#^} status_line=${status_line%\$}
swap_phrase docs/adr/0014-one-loop-at-three-rows.md "$pinned_phrase" "$status_line, amended"
printf '\nThe decision is %s, as the prose says.\n' "$status_line" >> "$scratch/docs/adr/0014-one-loop-at-three-rows.md"
sec=6 expect "ADR 0014 with 'status: accepted, amended' in the frontmatter fails" 1 "ADR 0014 is accepted"
fresh
rm "$scratch/docs/adr/0014-one-loop-at-three-rows.md"
sec=6 expect "a missing ADR 0014 fails" 1 "missing document: $scratch/docs/adr/0014-one-loop-at-three-rows.md"
# the retired two-level loop and the built-in review, seeded back; section 5 alone sweeps the
# review marker and the built-in review
ban ban_two_level "the retired two-level check order"
ban ban_builtin_review "the built-in code-review named in $scratch/$orch"
for case in "$ban_two_level|present: the retired two-level check order" \
  'at the story level the review marker is the exit|present: the retired review marker' \
  "reviewers run the $ban_builtin_review|present: the built-in code-review named"; do
  fresh
  echo "${case%%|*}" >> "$scratch/$orch"
  s=6; case ${case%%|*} in *"review marker"*|*built-in*) s=5;; esac
  sec=$s expect "orchestration doc with '${case%%|*}' fails" 1 "${case#*|}"
done

# the row regaining the landing's conflict resolutions fails (dev-b8d.1.4)
fresh
pin_phrase "the row's conflict resolutions"; resolutions=$pinned_phrase
pin_phrase "the row budgets three fix-ups"
pin_anchor "the row budgets three fix-ups"
swap_phrase skills/task-orchestrator/SKILL.md "($pinned_anchor.*)$pinned_phrase" "\\1$pinned_phrase and three $resolutions per landing"
sec=16 expect "task-orchestrator whose row regains conflict resolutions fails" 1 "present: the row's conflict resolutions"

fresh
echo "grep -q '^check:' <owner>/Makefile tells which" >> "$scratch/skills/implement-story/SKILL.md"
expect "a step 3 that greps the Makefile for the check target fails" 1 "present: the retired grep for the check target"

# a task orchestrator that resolves the check command per task again fails, so parallel tasks
# share one gate (dev-yyu)
fresh
pin_phrase "the row opens on the task orchestrator"
row_open=$pinned_phrase
pin_phrase "the skill never resolves the check command itself"
never_resolve=$pinned_phrase
pin_phrase "the per-task check target lookup"
swap_phrase skills/task-orchestrator/SKILL.md "($row_open.*)$never_resolve" "\\1find it with \`$pinned_phrase :\`"
sec=16 expect "a task orchestrator that looks up the check target per task fails" 1 "present: the per-task check target lookup"

fresh
swap_phrase skills/task-orchestrator/SKILL.md "$row_open" 'You are the ticket runner'
sec="5 16" expect "a row opening on the old ticket role fails" 1 "missing: the row opens on the task orchestrator"

for case in 'Resolve the owner repo'"'"'s **lint command** once, here beside the forge.|present: the retired lint-command resolution' \
  '`make lint` when `<owner>`'"'"'s Makefile has a `lint` target|present: the retired lint-command resolution' \
  '> 4. Spawn a **merger** at the tier'"'"'s implementation model.|present: the retired merger role'; do
  fresh
  echo "${case%%|*}" >> "$scratch/skills/implement-story/SKILL.md"
  s=one; case ${case%%|*} in *merger*) s=5;; esac   # section 5 alone sweeps the retired role
  sec=$s expect "implement-story regaining '${case%%|*}' fails" 1 "${case#*|}"
done

# the clean-worktree guard regaining --untracked-files=no fails (untracked files the check sees
# but the tree lacks would pass a dirty worktree)
fresh
pin_phrase "the clean-worktree guard that hides untracked files"
pin_anchor "the clean-worktree guard that hides untracked files"
swap_phrase skills/task-orchestrator/SKILL.md "($pinned_anchor.*)$" "\\1 $pinned_phrase"
sec=16 expect "the clean-worktree guard regaining --untracked-files=no fails" 1 "present: the clean-worktree guard that hides untracked files"

# the implementer brief drops one of the three forms beside its plain-command line (dev-c5dh, INFRA-45)
for pin in 'the implementer brief says file edits go through the Edit tool' \
  'the implementer brief says a commit message with trailers goes through a message file' \
  'the implementer brief says a glob passed as a flag is quoted'; do
  fresh
  pin_phrase "$pin"
  drop_phrase skills/task-orchestrator/SKILL.md "$pinned_phrase"
  sec=16 expect "task-orchestrator dropping '$pin' fails" 1 "missing: $pin"
done

for case in 'Then merge, @merge@.|present: a write command on the owner checkout' \
  'Then `git -C <owner> switch <branch>`.|present: a write command on the owner checkout'; do
  seed=${case%%|*}
  seed=${seed/@merge@/$landing_merge}
  fresh
  printf '%s\n' "$seed" >> "$scratch/skills/task-orchestrator/SKILL.md"
  s=16; case $seed in *"$landing_merge"*) s="5 16";; esac   # a typed landing merge is also section 5's sweep
  sec=$s expect "task-orchestrator regaining '$seed' fails" 1 "${case#*|}"
done

for case in '   story:   <story-id> <title>|present: a story line in the report' \
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
printf '%s\n' '| **Standalone task** | story orchestrator | one task orchestrator |' >> "$scratch/references/orchestration.md"
sec=6 expect "orchestration with a fourth table row fails" 1 "present: a fourth row in the table"

# the checks named after the review on step 7's line: the order pin fails; the phrase comes from
# the lint's own pin for it
fresh
pin_phrase "the story gate runs the checks first in each pass"
pin_anchor "the story gate runs the checks first in each pass"
move_to_line_end skills/implement-story/SKILL.md "$pinned_anchor" "$pinned_phrase"
expect "story gate step 7 with the checks after the two-axis review fails" 1 "missing: the story gate (step 7) runs the checks before the reviewed-tip compare"

# a worktree brief opens with the TMPDIR line, then the plain-command line, and the bare pwd step
# comes before the path spelled literally: each pair swapped on its brief's line fails the order
# pin. The phrases and the anchor come from the lint's own pins
order_case() { # <file> <presence pin of the first phrase> <presence pin of the second> <order pin>
  fresh
  pin_phrase "$2"; first=$pinned_phrase
  pin_anchor "$2"; an=$pinned_anchor
  pin_phrase "$3"; second=$pinned_phrase
  swap_two "$1" "$an" "$first" "$second"
  expect "$4 swapped on its line fails" 1 "missing: $4"
}
story=skills/implement-story/SKILL.md task_orch=skills/task-orchestrator/SKILL.md
order_case $story "the conflict implementer's brief starts with the TMPDIR line" "the conflict implementer's brief carries the plain-command line" \
  "the conflict implementer's brief puts the TMPDIR line ahead of the plain-command line"
order_case $story "the story review's fix-up brief starts with the TMPDIR line" "the story review's fix-up brief carries the plain-command line" \
  "the story review's fix-up brief puts the TMPDIR line ahead of the plain-command line"
order_case $story "the Owner repo bullet states the bare pwd step" "the Owner repo bullet spells the path literally in later exports" \
  "the Owner repo bullet puts the bare pwd step ahead of the path spelled literally"
# the Owner repo bullet names its TMPDIR line inside its anchor, so a swap would break the anchor:
# the plain-command line moves to the front of the line instead
fresh
pin_phrase "the Owner repo bullet states the plain-command line"
pin_anchor "the Owner repo bullet states the plain-command line"
move_to_line_start $story "$pinned_anchor" "$pinned_phrase"
expect "the Owner repo bullet with its plain-command line ahead of the TMPDIR line fails" 1 "missing: the Owner repo bullet puts the TMPDIR line ahead of the plain-command line"
order_case $task_orch "task orchestrator step 2's brief starts with the TMPDIR line" "task orchestrator step 2's brief carries the plain-command line" \
  "task orchestrator step 2's brief puts the TMPDIR line ahead of the plain-command line"
order_case $task_orch "task orchestrator step 2's brief names the bare pwd step" "task orchestrator step 2's brief spells the path literally in later exports" \
  "task orchestrator step 2's brief puts the TMPDIR line, the bare pwd step and the spelled path in order"
order_case $task_orch "task orchestrator step 3's brief starts with the TMPDIR line" "task orchestrator step 3's brief carries the plain-command line" \
  "task orchestrator step 3's three briefs each put the TMPDIR line ahead of the plain-command line"
# the header's brief holds the plain-command line after its TMPDIRs: swapped with the first, it stands ahead
fresh
pin_phrase "task orchestrator step 2's brief starts with the TMPDIR line"; first=$pinned_phrase
pin_phrase "the task orchestrator header carries the plain-command line"; second=$pinned_phrase
pin_anchor "the task orchestrator header carries the plain-command line"
swap_two $task_orch "$pinned_anchor" "$first" "$second"
expect "the task orchestrator header with its TMPDIR line behind the plain-command line fails" 1 "missing: the task orchestrator header puts the TMPDIR line ahead of the plain-command line"
# step 3 holds three briefs: the last one cut short, or opening without its TMPDIR line, fails
fresh
pin_phrase "task orchestrator step 3's brief carries the plain-command line"
pin_anchor "task orchestrator step 3's brief carries the plain-command line"
drop_last $task_orch "$pinned_anchor" "$pinned_phrase"
expect "task orchestrator step 3 with its last brief lacking the plain-command line fails" 1 "missing: task orchestrator step 3's three briefs each put the TMPDIR line ahead of the plain-command line"
fresh
pin_phrase "task orchestrator step 3's brief starts with the TMPDIR line"
pin_anchor "task orchestrator step 3's brief starts with the TMPDIR line"
drop_last $task_orch "$pinned_anchor" "$pinned_phrase"
expect "task orchestrator step 3 with its last brief lacking the TMPDIR line fails" 1 "missing: task orchestrator step 3's three briefs each put the TMPDIR line ahead of the plain-command line"

# the retired landing agent seeded back on step 7's line fails section 5 alone (the retired role is a pattern)
fresh
pin_anchor "the story gate runs the checks first in each pass"
swap_phrase skills/implement-story/SKILL.md "($pinned_anchor.*)$" '\1 Then spawn a merger.'
sec=5 expect "implement-story regaining a merger fails" 1 "present: the retired merger role"
# the review marker as the story gate's exit
fresh
echo 'The exit is the review marker.' >> "$scratch/skills/implement-story/SKILL.md"
sec=5 expect "implement-story regaining the review marker as the exit fails" 1 "present: the retired review marker"

# position: a reviewer spawned ahead of the checks' green (the green's own spawn kept too)
fresh
pin_phrase "the task review spawns one reviewer per axis"; spawn_two=${pinned_phrase%%,*}
pin_phrase "task orchestrator step 3 opens with the check gate, every tier"
swap_phrase skills/task-orchestrator/SKILL.md "^(${pinned_phrase#^}, )" "\\1for \`medium\` and \`high\` $spawn_two alongside it, "
sec=16 expect "task-orchestrator step 3 spawning the reviewers before the checks' green fails" 1 "present: task orchestrator step 3 spawns a reviewer ahead of the checks' green"

unset sec

# a DOCS_DIR override must exist
expect_flush all
fresh
out=$(VERSION_BUMP_REPO=$scratch/no-repo VERSION_BUMP_BASE=HEAD DOCS_DIR=/typo-no-such-dir SKILLS_DIR=$scratch/skills REFERENCES_DIR=$scratch/references USER_CLAUDE_MD=$scratch/CLAUDE.md PLUGIN_SKILLS=$scratch/plugin "$lint" "" "$scratch/docs/WORKFLOW.md" 2>&1; echo "rc=$?")
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

phase "hand-written cases after the derived ones"
# --- the version-bump rule, on a throwaway git repo the lint reads via VERSION_BUMP_REPO ---
# The other cases pin the diff base to HEAD (an empty diff) and point VERSION_BUMP_REPO at a
# path that is no repo, so the checkout the test runs in never decides them; these cases let the
# lint derive the merge-base itself (diff_base=derive) in a throwaway repo.
# make_bump_repo <branch>: in the current scratch, a repo on main with a manifest at 0.1.0,
# origin/main tracking that commit, <branch> checked out from it; fails, committing nothing, when the repo cannot be made.
# The first repo is built and kept in $jobs/bump.seed and each later one is a copy of it: a build is
# a dozen git calls in this shell, one after another, and every case starts from the same repo
make_bump_repo() {
  bump_repo_dir=$scratch/bump
  if [ -d "$jobs/bump.seed" ]; then
    cp -R "$jobs/bump.seed/." "$scratch/" || return 1
  else
    mkdir -p "$bump_repo_dir/.claude-plugin" "$bump_repo_dir/docs" "$bump_repo_dir/scripts"
    # fx_git_repo refuses a dir that is not the new repo's top level, so a failed init cannot
    # commit into the enclosing checkout
    fx_git_repo "$bump_repo_dir" "$scratch/bump.gd" || return 1
    # a relative link to the git dir, so the repo still opens once expect moves the tree
    echo 'gitdir: ../bump.gd' > "$bump_repo_dir/.git"
    echo '{"name":"dev","version":"0.1.0"}' > "$bump_repo_dir/.claude-plugin/plugin.json"
    echo one > "$bump_repo_dir/docs/a.md"; echo one > "$bump_repo_dir/scripts/a.sh"
    git -C "$bump_repo_dir" add -A && git -C "$bump_repo_dir" commit -q -m base || return 1
    git -C "$bump_repo_dir" update-ref refs/remotes/origin/main main
    mkdir "$jobs/bump.seed" && cp -R "$bump_repo_dir" "$scratch/bump.gd" "$jobs/bump.seed/" || return 1
  fi
  [ "$1" = main ] || git -C "$bump_repo_dir" checkout -q -b "$1"
}
bump_repo() { fresh; make_bump_repo "$1" || { echo "FAIL make the throwaway repo"; exit 1; }; }
bump_commit() { git -C "$bump_repo_dir" add -A; git -C "$bump_repo_dir" commit -q -m "$1"; }
# expect_keep <expect's arguments>: expect on the tree as it stands, with a copy of it left in the
# scratch dir, for a case the next one builds on (expect takes the tree it is given)
expect_keep() {
  local kept=$jobs/kept
  scratch_entries
  mkdir "$kept" && cp -R "${entries[@]}" "$kept/" || { echo "FAIL keep the tree for the next case"; exit 1; }
  expect "$@"
  # dotglob: the tree holds .claude (the rule file section 18 reads), which a bare * leaves behind
  (shopt -s dotglob nullglob; mv "$kept"/* "$scratch/") && rmdir "$kept"
  handed=0
}

# LINT_UNCHANGED, which every case but the baseline lints with: a seeded failure in a file it
# lists is skipped, while the same seed unlisted fails, as the retired-phrase cases show
# (list_unchanged, which the cases use, is defined above the cache-invalidation cases)
expect_flush all
fresh
echo "cut one" >> "$scratch/skills/sample/SKILL.md"
list_unchanged "$scratch/skills/sample/SKILL.md"
unchanged_tables >> "$jobs/unchanged"
fx_check "a seeded file LINT_UNCHANGED lists is not checked" \
  eval 'result_is 0 "" "$(unchanged_list=$jobs/unchanged lint_scratch)"'
# a listed doc's section runs nothing while every pin table is listed too, so a row only that
# section asks for goes unasked (the list is taken at its word), and the same table with the doc
# unlisted, or a table unlisted, fails naming the row: a run pays only for the docs its case
# changed, not one function call per check of every section
fresh
mkdir "$scratch/pins"
cp "$repo_root"/scripts/*.tsv "$scratch/pins/"
grep -v '^has	epic review spec axis	' "$repo_root/scripts/implement-spec-pins.tsv" > "$scratch/pins/implement-spec-pins.tsv"
list_unchanged "$scratch"/pins/*.tsv
fx_check "a doc LINT_UNCHANGED lists, with every pin table, has its section skipped whole" \
  eval 'result_is 0 "" "$(pins_dir=$scratch/pins unchanged_list=$jobs/unchanged lint_scratch)"'
grep -vxF "$scratch/references/orchestration.md" "$jobs/unchanged" > "$jobs/unchanged.less"
fx_check "the same doc unlisted runs its section" \
  eval 'result_is 1 "no row '\''epic review spec axis'\'' in implement-spec-pins.tsv" "$(pins_dir=$scratch/pins unchanged_list=$jobs/unchanged.less lint_scratch)"'
list_unchanged
fx_check "the same doc listed without the pin tables runs its section" \
  eval 'result_is 1 "no row '\''epic review spec axis'\'' in implement-spec-pins.tsv" "$(pins_dir=$scratch/pins unchanged_list=$jobs/unchanged lint_scratch)"'
# a table the lint reads, gone with the doc and the rest listed, is still a table not listed: its
# section runs and fails naming it, whether or not the list names the gone path
for table in $pin_tables; do
  fresh
  mkdir "$scratch/pins"
  cp "$repo_root"/scripts/*.tsv "$scratch/pins/"
  rm "$scratch/pins/$table.tsv"
  list_unchanged "$scratch"/pins/*.tsv
  fx_check "with $table.tsv gone and the docs and the other table listed, the lint fails naming it" \
    eval 'result_is 1 "missing pin table: $scratch/pins/$table.tsv" "$(pins_dir=$scratch/pins unchanged_list=$jobs/unchanged lint_scratch)"'
  printf '%s\n' "$scratch/pins/$table.tsv" >> "$jobs/unchanged"
  fx_check "with $table.tsv gone and listed all the same, the lint fails naming it" \
    eval 'result_is 1 "missing pin table: $scratch/pins/$table.tsv" "$(pins_dir=$scratch/pins unchanged_list=$jobs/unchanged lint_scratch)"'
done
# a pin list run holds every check, so a full LINT_UNCHANGED leaves it as long as the baseline's:
# a doc skipped there would drop that doc's derived cases
fresh
list_unchanged
unchanged_tables >> "$jobs/unchanged"
unchanged_list=$jobs/unchanged pin_list_run "$jobs/pins.listed" > /dev/null
fx_check "a pin list run with every file and table listed writes the whole list" cmp -s "$jobs/pins.list" "$jobs/pins.listed"
# a pin list run lists its checks and runs none of them: the listing is what the test reads, and
# section 18's thousands of checks, unfiltered there, would be most of the test's serial time
fresh
echo "cut one" >> "$scratch/skills/sample/SKILL.md"
pin_run=$(pin_list_run "$jobs/pins.seeded")
fx_check "a pin list run on a seeded tree runs none of its queued checks" bash -c '! grep -q "retired phrase in" <<<"$1"' _ "$pin_run"
# an empty list skips nothing, the sweeps over many files included
fresh
printf '```mermaid\nA->>B: one; two\n```\n' >> "$scratch/references/sample.md"
: > "$jobs/unchanged"
fx_check "an empty LINT_UNCHANGED skips no sweep" \
  eval 'result_is 1 "semicolon in a mermaid block" "$(unchanged_list=$jobs/unchanged lint_scratch)"'
# section 18 trusts the list past a changed SKILL.md only while the skills' cite names are the ones
# LINT_CITE_BASE holds: a skill's edit that moves no name leaves a listed doc skipped, and with no
# base the same edit re-reads it (the skill gaining a heading, above, is the base that no longer
# matches)
fresh
printf '%s\n' "See \`/dev:close-story\`'s Some rule." >> "$scratch/references/orchestration.md"
echo "a line that names no step or heading" >> "$scratch/skills/sample/SKILL.md"
list_unchanged "$scratch/references/orchestration.md"
unchanged_tables >> "$jobs/unchanged"
fx_check "a changed SKILL.md that moves no cite name leaves a listed doc unread in section 18" \
  eval 'result_is 0 "" "$(unchanged_list=$jobs/unchanged lint_scratch)"'
fx_check "with no cite base a changed SKILL.md re-reads a listed doc in section 18" \
  eval 'result_is 1 "an unquoted heading cite of a skill in $scratch/references/orchestration.md" "$(LINT_CITE_BASE= unchanged_list=$jobs/unchanged lint_scratch)"'

# a failed init commits nothing, here or in the enclosing checkout
expect_flush all
fresh
enclosing_head=$(git -C "$repo_root" rev-parse HEAD)
touch "$scratch/bump.gd"   # a file where the git dir goes: init fails
fx_check "fx_git_repo refuses a dir whose git dir path is an existing file" eval '! fx_git_repo "$scratch/bump" "$scratch/bump.gd"'
# jobs points at no bump.seed, in the subshell alone: a seed would be copied in and no init would run
fx_check "a throwaway repo whose init fails is refused" eval '! (jobs=$scratch/no-seed; make_bump_repo main)'
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
mkdir -p "$bump_repo_dir/references"; echo r > "$bump_repo_dir/references/r.md"; bump_commit "reference change"
expect "a references change without a version bump fails" 1 "version bump"

bump_repo feat
mkdir -p "$bump_repo_dir/references"; echo r > "$bump_repo_dir/references/r.md"
echo '{"name":"dev","version":"0.2.0"}' > "$bump_repo_dir/.claude-plugin/plugin.json"; bump_commit "reference change and bump"
expect "a references change with a version bump passes" 0

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
expect_keep "an uncommitted edit under skills/ without a version bump fails" 1 "version bump"
echo '{"name":"dev","version":"0.2.0"}' > "$bump_repo_dir/.claude-plugin/plugin.json"
expect "an uncommitted edit under skills/ with an uncommitted bump passes" 0

bump_repo feat
mkdir -p "$bump_repo_dir/skills/y"; echo s > "$bump_repo_dir/skills/y/SKILL.md"
expect "an untracked file under skills/ without a version bump fails" 1 "version bump"

bump_repo feat
echo two > "$bump_repo_dir/docs/a.md"; bump_commit "docs change"
diff_base=HEAD
expect_keep "the base variable overrides the merge-base" 0
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
  expect_keep "a detached HEAD with base $diff_base and no version bump fails" 1 "version bump"
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

phase "version-bump cases"

fx_check "a phase prints its wall seconds, its CPU seconds and the slots" \
  grep -Eq '^timing: a phase: [0-9]+s wall, [0-9]+s cpu on [0-9]+ slots$' <<<"$(phase_cpu=0; phase "a phase")"

phase "pin coverage guard"

# uncovered_pins <pin list> <test source>: the description of every absent-phrase pin that derives no
# case (alts finds no plain text in its pattern) and that no hand-written case names, one per line.
# Reads the global absent_types (the kinds of check that are absent-phrase pins). A case names a pin
# when its description (pin_phrase, or the message it expects) appears as a substring of any line of
# the test source that is no comment: looser than a case that is about the pin, but a new pin with no
# mention at all fails. The description is read without its " in <file>" tail and without a skill
# name (" /dev:x"), so one case of a check that runs once per file or skill covers them all
uncovered_pins() {
  absent_types=$absent_types awk -F '\t' "$alts_fn"'
    NR == FNR { if ($0 !~ /^[ \t]*#/) src = src $0 "\n"; next }
    index(ENVIRON["absent_types"], " " $1 " ") && $3 != "" && $4 != "" {
      d = $3; sub(/ in \/.*$/, "", d); gsub(/ \/dev:[a-z0-9-]+/, "", d)
      if (alts($1, $4) > 0) derived[d]; else bare[d] }
    END { for (d in bare) if (!(d in derived) && !index(src, d)) print d }' "$2" "$1" | sort
}
# uncovered_report <pin list> <test source>: one FAIL line per uncovered pin, nothing when all are covered
uncovered_report() {
  while IFS= read -r pdesc; do
    [ -n "$pdesc" ] && echo "FAIL absent-phrase pin '$pdesc' derives no case and no hand-written case names it"
  done <<<"$(uncovered_pins "$1" "$2")"
}
uncovered=$(uncovered_report "$jobs/pins.list" "$repo_root/scripts/test-lint-skill-docs.sh")
if [ -z "$uncovered" ]; then
  echo "ok   every absent-phrase pin derives a case or is named by a hand-written one"
else
  echo "$uncovered"; fails=$((fails + $(wc -l <<<"$uncovered")))
fi
# the guard alone, on a made-up list and source
printf '%s\t%s\t%s\t%s\n' \
  w a.md 'regex only, unnamed' 'foo[0-9]+|ba[rz]' \
  w a.md 'regex only, named in /x/a.md' 'x[0-9]' \
  w a.md 'plain and regex' 'plain|y[0-9]' \
  c a.md 'positive check' 'z[0-9]' > "$jobs/guard.list"
printf '%s\n' 'expect 1 "regex only, named in $scratch"' '# regex only, unnamed' > "$jobs/guard.src"
fx_check "a regex-only pin that no case names is reported, a comment naming it does not count" \
  test "$(uncovered_pins "$jobs/guard.list" "$jobs/guard.src")" = 'regex only, unnamed'
printf '%s\n' 'expect 1 "regex only, named"' 'pin_phrase "regex only, unnamed"' > "$jobs/guard.src"
fx_check "a pin a hand-written case names is not reported" \
  test -z "$(uncovered_pins "$jobs/guard.list" "$jobs/guard.src")"
printf '%s\t%s\t%s\t%s\n' w a.md 'regex only /dev:foo in /x/a.md' 'x[0-9]' > "$jobs/guard.list"
printf '%s\n' 'expect 1 "regex only"' > "$jobs/guard.src"
fx_check "a pin's skill name and file tail are not needed to name it" \
  test -z "$(uncovered_pins "$jobs/guard.list" "$jobs/guard.src")"
printf '%s\n' 'expect 1 "other"' > "$jobs/guard.src"
fx_check "an uncovered pin makes a FAIL line that names it" \
  test "$(uncovered_report "$jobs/guard.list" "$jobs/guard.src")" = "FAIL absent-phrase pin 'regex only' derives no case and no hand-written case names it"

fx_report_fails
