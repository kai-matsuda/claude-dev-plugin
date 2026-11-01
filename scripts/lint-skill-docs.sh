#!/usr/bin/env bash
# Reference lint for skill-facing docs (INFRA-26): named commands exist, stale phrases are absent.
# Not the test seam for any skill; that is a subagent following the skill against the fixture.
# One section per doc (INFRA-27 added 3-6):
#   1. the /implement-spec epic orchestrator text (chezmoi-0jp.24): no task-level procedure, names the
#      refusals, the spawn with its pointer at the waiting rule (chezmoi-p4q) and the end states,
#      the story-closure human stop and the add-mode stall hint pinned (chezmoi-9v4.1.6); the
#      epic row (dev-9k5.1.8): the role named, the harness doc cited, the epic review (one PR at
#      a time, the default-branch diff, the Jira Epic's spec, no standards axis, the epic's max
#      tier), draft until clean with the mark-ready commands, the add-mode fix-up (one task per
#      blocking finding, three per story, the fourth failed in one of the Check gate's two lines
#      and no other, dev-aeo) and the review: end-state line, with
#      no epic-row role and no PR opened here; its home database gate cites the tracker doc's
#      "Has a database" rule (dev-e87);
#   2. the human runbook docs/WORKFLOW.md (chezmoi-0jp.25) and the /workflow skill:
#      names only commands that exist, no stale cross-repo wording, the cut skills' argument
#      written in the runbook and filled in on /workflow's next lines (chezmoi-nz0);
#      the /close-epic doc block (dev-9k5.1.10);
#   3. /spec-to-stories: user-typed, the required argument with its usage line and no
#      no-argument epic recovery (chezmoi-nz0), the refusals, preflight, the orientation written
#      to the story bead's design field behind its header line, no file and no git write in any
#      owner repo (chezmoi-cdf, ADR 0010), no Jira comment; the story DAG detected per edge,
#      a split proposed only for a deprecate-then-remove and the user's split for any reason,
#      the cycle refusal before any bead exists, the topological order with one Blocked by
#      line per edge in both forms, and every edge and publish in the orientation and the end
#      report (ADR 0011); the frontmatter's one story per PR, the deprecate-then-remove
#      split's full shape, a story with an edge on a skipped story skipped too and reported
#      only (the epic bead note is for a no-database skip), the cycle refusal ahead of step
#      7's epic bead, the deploy as the
#      earlier story's last step, a quiz cycle rejected without ending the skill, and the
#      tracker doc's out-of-scope cases (git tag or ssh URL, several crates in one story);
#      add mode on a feature whose stories exist (the refusal only when every story is
#      closed, never the unconditional "stories exist"), its story states, its additions
#      answering failed twice: notes, one sandbox-disabled forge query per finished story it
#      touches with the MERGED, OPEN and no-forge paths, and its additions-only publish
#      with the dependent's body rewritten and Jira untouched (chezmoi-9v4.1.7), and its home
#      database checked with bd where after the user's bd init, refused when none was made
#      (dev-zyx);
#   4. /spec-to-tasks: user-typed, the same argument rule as 3, the refusals,
#      cutters pointed at the waiting rule and without a model override, explicit dependent
#      lines, the closed and publish-failed lines, a Jira comment over every story, no
#      story-cut procedure; the cycle refusal, topological waves with every upstream
#      breakdown in a dependent's brief, the inline re-cut of an already cut dependent keyed on
#      its missing bump, a finished dependent excluded at step 1, a skipped repo's publish line
#      as an edge with no dependency, the held-back cascade narrowed to a dependency without
#      its publish task, and no two-wave cap (ADR 0011);
#   (3, 4 and 1 point at the shared preflight and epic gather that section 6 checks; 3, 4 and 7
#   cite the "epic bead writes" convention that section 6 checks)
#   5. one sweep over one file list: every file under the agent docs and the skills dir, the
#      project CLAUDE.md, the runbook, docs/SEQUENCES.md and the implement-spec skill passed as
#      $1, each read as one line so a phrase wrapped across a line break is caught (dev-86j):
#      no retired "cut one", "cut two" or <spec-slug>, as whole words, and no story-cut.md (the
#      notes moved to the story bead's design field, chezmoi-cdf); none of the retired walk-up
#      phrases ("nearest ancestor", "walking up", "walk up", "one level up", "the home repo
#      included", "the workspace root included", "no repos.yaml above", "workspace inbox",
#      "workspace's inbox", the "home repo <home repo>" Parent form); no "run_in_background:
#      false", since no foreground spawn exists (chezmoi-p4q); none of the retired story-DAG
#      wording ("one story per repo", feat/<key>-<n>, "chains are out of scope", "only text
#      blocker", "two waves suffice"; ADR 0011); none of the check and review loop's retired
#      two-gate wording ("Evidence run", "a later run reviews the fix", "a third round of
#      either kind", "a second red", dev-1xf.1.4), which the root GLOSSARY.md lacks too; and
#      none of the retired vocabulary (dev-9k5.1.11): the epic, task and landing roles, the
#      built-in review by name, the two-review-tools paragraph, the review marker, the lint
#      command and the test seams as checks (the glossary lists them under _Avoid_, docs/adr/
#      keeps them through .glossary-allow); and no rule that moved to harness.md cited at the
#      rules doc (dev-zra), nor a beads database gate on the .beads/ directory alone
#      (dev-e87). docs/specs keeps every list. No other section repeats a phrase this
#      sweep covers, so a seeded one fails here alone;
#   6. the shared rules: orchestration.md's working-directory preflight, and harness.md's
#      waiting rule (an Agent call returns at once, the orchestrator ends its turn and the
#      completion notification resumes it, never a Bash poll loop; pgrep is dead in the
#      sandbox) with its idle rule (Bash in the foreground only below the epic orchestrator, chezmoi-p4q), the
#      model (dev-9k5.1.3): the loop sentence, the table's header and each of its three rows, the
#      two scoping rules (only a green check record skips a run, dev-6qi), the six trust rules as a
#      closed list, the check command, the check record, the one gate exit, the epic row's two
#      fourth-failure lines and no third (dev-aeo), a fix-up that commits
#      nothing rerunning the checks and spending budget (dev-vnf), a landing's cap of three
#      conflict resolutions, the seam-test blocking case and the one review tool, with the two-level
#      loop's lint-first order retired (section 5 sweeps the review marker and the built-in
#      code-review); ADR 0014 (its
#      frontmatter status line accepted, Supersedes ADR 0001, its considered options and
#      decisions) and ADR 0001 (its status superseded by ADR 0014, its pointer at 0014), and
#      the Review scope's pointer to ADR 0014; the
#      Orchestrator role's beads-only principle for the epic-level stages (ADR 0010), the
#      Frontier's unclaim rule (chezmoi-jvc) and its ready-for-agent-only admission with the
#      finished story that tolerates an untriaged child (chezmoi-wgi), the Review verdict rule
#      with its verdict lines, its blocking-or-minor tags and its blocking-rounds-only count
#      (chezmoi-49k), issue-tracker.md's
#      one test of the session mode in its opening (ADR 0008), its epic bead gather with its
#      refusals, its spec fetch with the Spec: fallback, its "epic bead writes" convention,
#      and its close rule counting a story's children as the finished story does (chezmoi-afn),
#      and its "First time in a repo" running bd init from the repo's top level alone, never
#      reinitialising on an abort, checked with bd where whose failure names the init commit,
#      which /setup-repo cites without restating and the story publish follows, a failed
#      init there a no (dev-zyx), and its "Has a database" rule (.beads/ exists and bd where
#      names it), which every other gating skill cites (dev-e87);
#   7. /story-to-tasks: the spec fetch pointer, the story cutter and publish triggers, the
#      design field read, the one test and "home <home name>" in the template's Parent line,
#      the pair read per edge (one bump per publish blocker, Dependency:/Dependent: lines),
#      the two refusals (two publish tasks; a finished story pointing at add mode) and the
#      re-cut's added bump, re-edge and citation of the per-edge rules (ADR 0011);
#   8. /implement-story: the deliver step pushes and opens the PR on the typed command's
#      authority (orchestration.md's delivery rule, checked in 6; ADR 0009), a refused push
#      is a failed: line, so no step waits on the user, the Gitignore step commits a dirty
#      .gitignore made of the rule's entries alone while an edit of the user's in it is a
#      failed: line (chezmoi-hkn), its exploration subagent reads the story's design field
#      and owns .spec-notes/<epic-id>/ (chezmoi-cdf), and a task whose task orchestrator failed is
#      unclaimed before the next frontier read, with the resume pointer noted on a second
#      failure and step 9's resume: line naming when a human runs the unclaim (chezmoi-jvc),
#      the Frontier's unclaim rule being checked in 6, its frontier read keeps ready-for-agent
#      tasks only, its review step captures deferred findings in the inbox through the
#      retro capture, its finished story tolerates an untriaged child (chezmoi-wgi), and its
#      frontier spawn ends the turn after spawning and carries the idle rule (chezmoi-p4q), and
#      it lands each reviewed task branch itself, serially with no lock, the stray-commit check
#      then the merge, a conflict to an implementer in the task's worktree, the resolved tree
#      checked, then a fast-forward, three resolutions per landing, a red on a resolved tree
#      a failed landing whose retry enters at the gate, a landing closing the task, and sends
#      the short brief to /dev:task-orchestrator at opus (dev-b8d.1.4), and its integration branch is
#      feat/<story-id> keyed or not, a delivered story with an open agent task passes one
#      merge guard (MERGED, CLOSED unmerged, OPEN, ask), a story-closure wait says to merge
#      and run /close-story, and the sibling line is <repo> <story-id> <url> (chezmoi-9v4.1.5,
#      ADR 0011), and its clean-up step removes worktrees with the sandbox disabled up front,
#      sweeps every worktree-agent-* and .worktrees/ worktree whose branch is merged into the
#      integration branch, earlier runs' included, and reports a locked or unmerged one in the
#      report's worktrees: line instead of forcing it (chezmoi-73d), only inside the owner
#      checkout's resolved top level and not inside a linked worktree nested there (dev-114,
#      dev-f61), nor that nested checkout itself while it holds a listed worktree (dev-wcv),
#      nor any .worktrees/ entry but a hand-rolled task worktree (dev-dzu),
#      then names every untracked, non-ignored file on the report's stray: line
#      without deleting it (dev-9ft), its deliver
#      step waits for the PR's forge checks and makes a red one a failed: line, a missing forge
#      or check a checks: skipped line (dev-xc2), and its story fix-up and conflict-resolution
#      briefs start with the TMPDIR line, whose rule section 6 checks in orchestration.md
#      (chezmoi-3eg), and its story review step 7 points at the rules doc's Review verdict,
#      whose rule section 6 checks (chezmoi-49k), and its step 3 applies the rules doc's
#      Repo plumbing and Cut-off probe (check target resolved once, forge decision, Gitignore commit and merge
#      guard, which section 6 pins, dev-yykg), a red record checked again and a
#      fix-up that commits nothing checked again at step 7, the story gate exiting on a
#      reviewed tip (dev-vnf), with the lint-command resolution retired (dev-9k5.1.7),
#      and its story gate (step 7) is the rules doc's Check gate loop at the story row: it exits
#      when the checks are green on the tip the review called clean, reads the checks from the
#      check records, keeps the reviewed tip in the story's review: note, reviews the story's body
#      (spec) and what entered since the task reviews (standards), sends a red or a blocking
#      verdict to a fresh fix-up, three per story, the fourth failed, and spends nothing on the
#      minors fix-up; its deliver step (8) leaves the PR a draft, its Evidence the delivered tip's
#      check record, and step 9 removes the records; "Running the checks" and "the command and
#      its output" are gone (section 5's sweep covers the review marker, the merger, the keyed
#      branch, the Evidence run and the second-red stall) (dev-cq0.1.5, dev-1xf.1.3, dev-9k5.1.9); section 6 checks the
#      rules doc's Check gate;
#   9. /close-story: its Forgejo/Gitea query carries --repo <path> as the intro and
#      /implement-story's merge guard do (dev-hac); its task check skips a child carrying
#      needs-triage or wontfix, as the finished story does, and its refusal names each open
#      child's status and label (chezmoi-afn);
#  10. the tracker and orchestration docs: both name the story DAG and the human gate task,
#      and neither puts chains out of scope in any wording (section 5 sweeps "only text
#      blocker" and "chains are out of scope"); the orchestration
#      doc ends a story-closure wait as a human stop and readies a publish task on its
#      story's tasks; the tracker doc's story body shows no unfillable gate task line
#      and orders a middle story of a chain in one topological pass, creates every
#      repo-session story under the epic bead, and makes a deploy split wait on the
#      earlier story's closure (ADR 0011).
#  11. the namespace rule: in every .md file under the skills dir, docs/ (the agent docs, ADRs, specs),
#      the runbook, the project CLAUDE.md, the root GLOSSARY.md and the implement-spec skill passed as $1, a
#      /<command> is dev:<skill> or mattpocock-skills:<skill> naming a skill that exists, or a
#      built-in or a path; a bare /<skill> or another namespace fails. The /command extraction
#      (cmd_tokens) and the existence check (cmds) moved here from section 2, which no longer
#      calls them. A bare name in the root docs passed before they joined the scan (dev-9np).
#  12. /retro: step 2 names the transcript shape (one JSON object per line with its own type
#      and timestamp, tool_use and tool_result objects in message.content) and two recipes, a
#      jq per-agent call timeline and a grep tally across agents, each run with
#      `timeout: 600000` on a directory-wide scan; the bare "grep the whole slug directory" is
#      gone (dev-qfz, INFRA-30).
#  13. the brief rule: in every .md file under the skills dir, a brief block (a markdown quote,
#      from a line starting with `>`, indented or not, to the next blank line: the blocks the
#      orchestration skills send to task orchestrators, cutters, implementers and reviewers) never
#      names the plugin-root variable CLAUDE_PLUGIN_ROOT, which Bash never has and the harness
#      fills in only in the skill text it loads (the rules doc's Plugin root rule); the skill's
#      path and the line are named. Outside a brief, where the skill itself resolves the
#      variable, it passes (dev-rc9, INFRA-30);
#  15. the mermaid rule: no ";" on a line of a ```mermaid block in any doc the sweeps read, since
#      mermaid ends the statement there and the diagram fails to render (dev-1xf.1.4).
#  16. /task-orchestrator (dev-b8d.1.4): typed bare it refuses in one line naming the two skills
#      that spawn it; its brief carries only what the story run knows; two entries (claim, gate)
#      selected by the brief; one report line (reviewed: <task branch> <worktree path> <tip SHA>,
#      needs split:, failed:); no write to the owner checkout and no close; and the pins that
#      moved with the old task orchestrator brief: the task row's parameters, the run's check
#      command from the brief, the harness doc in one line, the turn ended after a spawn, the
#      TMPDIR and plain-command lines, a check record per tree SHA, the two-axis review with its
#      verdict line, the fix-up budget and the minors rule. Section 5 sweeps the lock wait.
#  17. /implement-task (dev-b8d.1.6): the non-task, story-task and not-ready refusals, the story
#      row's plumbing (the make probe and its refusal, the forge decided once, the gitignore rule,
#      task/<id> with a branch: note), one task orchestrator with the short brief, the landing by
#      a fast-forward, the rules doc's Delivery with the PR opened ready and never a draft,
#      delivered: before pr: and the close at delivery, no forge's pushed branch and skipped-checks
#      line, the merge guard and the gate re-entry on a rerun, and the report minus the story lines
#      ending on resume:. Section 6 pins the rules doc's one paragraph on it (the table keeps three
#      rows) and the no-seam-test case skipping a standalone task without ## Test seams.
#  18. the cross-skill cite rule (dev-q47w): the coding standards state it under its heading, and
#      no other rules doc or SKILL.md cites another skill's heading bare after a possessive, even
#      split across a line break. Nor does a step name of a skill in quotes, a heading in bold,
#      either one bare before "of"/"in" /dev:x or bare after "'s step"/"'s section" (dev-mnz6),
#      a step or heading in backticks (alone, or with the bold or quotes inside or around the
#      pair), or the right marking beside a skill not in backticks (dev-hcn9). The names are read
#      from that skill's SKILL.md (numbered or ## to #### headings; bold steps, hyphens,
#      punctuation and indents included, regex characters escaped), in the closed list of shapes
#      the section's comment states and nothing beside it; a changed SKILL.md has every rules
#      doc and SKILL.md re-read.
# Usage: scripts/lint-skill-docs.sh [implement-spec SKILL.md [WORKFLOW.md]]
# A section whose doc is missing fails naming it ("missing document: <path>") rather than being
# skipped, so a renamed skill or rules doc cannot turn its checks off (dev-dov); each section
# opens with a "== <n>. " header, under which its FAIL lines print (the regression test reads
# them to tell which section failed). The plugin layout is skills/, docs/agents/,
# docs/WORKFLOW.md, CLAUDE.md and GLOSSARY.md under the repo root.
# SKILLS_DIR and AGENT_DOCS override the skills and agent docs directories (scratch copies).
# DOCS_DIR overrides the docs directory the namespace rule scans (default: docs under the repo root).
# USER_CLAUDE_MD overrides the project CLAUDE.md (default: CLAUDE.md under the repo root).
# GLOSSARY_MD overrides the root glossary (default: GLOSSARY.md under the repo root).
# LINT_PINS_DIR overrides the directory of the pin tables (default: scripts under the repo root); a
# missing directory or table fails, as a missing doc does.
# LINT_PIN_LIST names a file every queued check is appended to first, for the regression test
# to derive its drop cases from.
# PLUGIN_SKILLS overrides the plugin skills directory (default: newest installed mattpocock-skills).
# The last section is the version-bump rule (INFRA-30): a change to what the plugin ships
# needs a changed version in .claude-plugin/plugin.json. VERSION_BUMP_REPO overrides the repo it
# reads (default: the repo root); VERSION_BUMP_BASE overrides the diff base (default: the
# merge-base with origin/HEAD, else origin/main).
# LINT_UNCHANGED names a file listing paths, one per line, unchanged from a tree every check
# passed on (the regression test's pristine copy): a file byte-identical to its copy there, or as
# "<dir>/" a dir laid out as there (the same paths under it, each of the same kind). A check on
# such a file is skipped wherever its verdict depends on nothing the list leaves out: that file
# and its fixed pattern for most, plus the skills and plugin dirs' layout for the namespace
# rule, and the skills' cite names for section 18: every SKILL.md listed, or the names as
# LINT_CITE_BASE holds them, a file a LINT_PIN_LIST run wrote beside its list (<list>.cites). A
# listed pin table counts too: with every table listed, a listed doc skips its section whole. The
# list vouches for a file only in the role it had there, so a caller leaves out every path it
# passes as an argument or override. Unset, every check runs.
set -u
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail=0
bad() { echo "FAIL: $*"; fail=1; }
# has (grep -iF), hasc (-F), hase (-E), lacks (-iE), lacksf (-iF) and lackse (-E) check <pattern>
# against $f line by line, as those greps would; lacksw (-iE, lackswc -E) against $f read as one line, each
# line's leading blanks and quote markers dropped and a space joining it to the next, so a
# phrase wrapped across a line break matches too; line_has (-F), line_hase (-E) and line_lacks (-F) check it
# on the lines matching <anchor> (-E), as a grep -E <anchor> | grep -q pipeline would; para_has
# (-iF) on the first paragraph opening with <heading> (that line to the next empty one), and
# opening_has (-F) on the lines before the first "## ". Each only queues its check: a section's
# checks run in one awk pass when the next section opens (section) and at the end (checks_run),
# so their FAIL lines print under their own section's header, at a cost of one process per
# section rather than one or two per check (the regression test runs the lint hundreds of
# times, and its pool is CPU-bound).
queue=
unchanged=$'\n'
[ -z "${LINT_UNCHANGED:-}" ] || unchanged+="$(<"$LINT_UNCHANGED")"$'\n'
# unchanged_file: true when $f is a file LINT_UNCHANGED lists; a sweep skips such a file whole.
# The last answer is kept: a section asks about one $f for check after check, and the match
# against the whole list costs as much as the rest of the run
unchanged_f=/ unchanged_rc=1
unchanged_file() {
  if [ "$f" != "$unchanged_f" ]; then
    unchanged_f=$f unchanged_rc=1
    case $unchanged in *$'\n'"$f"$'\n'*) unchanged_rc=0 ;; esac
  fi
  return $unchanged_rc
}
# drop_unchanged: stdin's paths, one per line, less the ones LINT_UNCHANGED lists, in one pass,
# for a sweep over many files (where unchanged_file would match the list once per file); a
# LINT_PIN_LIST run keeps them all, since the pin list takes every check
drop_unchanged() {
  # -s: an empty list would leave NR == FNR true on stdin too, and the sweep would print nothing
  if [ -s "${LINT_UNCHANGED:-}" ] && [ -z "${LINT_PIN_LIST:-}" ]; then
    awk 'NR == FNR { u[$0]; next } !($0 in u)' "$LINT_UNCHANGED" -
  else cat; fi
}
# enqueue <check line>: queues it unless $f is a file LINT_UNCHANGED lists
# LINT_PIN_LIST names a file every queued check is appended to first, one per line as
# <type> <file> <description> <phrase> [<anchor>] (the queue's own line), for the regression test
# to derive its drop cases from; the list holds every queued check, though enqueue still skips
# queueing the checks of an unchanged file
enqueue() {
  [ -z "${LINT_PIN_LIST:-}" ] || printf '%s\n' "$1" >> "$LINT_PIN_LIST"
  unchanged_file || queue+="$1"$'\n'
}
has() { enqueue "i	$f	$1	$2"; }
hasc() { enqueue "c	$f	$1	$2"; }
hase() { enqueue "e	$f	$1	$2"; }
lacks() { [ -f "$f" ] || return 0; enqueue "x	$f	$1	$2"; }
lacksf() { [ -f "$f" ] || return 0; enqueue "f	$f	$1	$2"; }
lackse() { [ -f "$f" ] || return 0; enqueue "y	$f	$1	$2"; }
lacksw() { [ -f "$f" ] || return 0; enqueue "w	$f	$1	$2"; }
lackswc() { [ -f "$f" ] || return 0; enqueue "W	$f	$1	$2"; }   # lacksw, case-sensitive (-E)
line_has() { enqueue "a	$f	$2	$3	$1"; }   # <anchor> <description> <phrase>
line_hase() { enqueue "A	$f	$2	$3	$1"; }   # <anchor> <description> <pattern>
line_lacks() { [ -f "$f" ] || return 0; enqueue "X	$f	$2	$3	$1"; }   # <anchor> <description> <phrase>
para_has() { enqueue "p	$f	$2	$3	$1"; }   # <heading> <description> <phrase>
sec_has() { enqueue "S	$f	$2	$3	$1"; }   # <heading line> <description> <phrase>: searched between that heading and the next ##
opening_has() { enqueue "o	$f	$1	$2"; }
# pins_from <table> [<heading>]: queues the checks of a pin table, one row per line as
# <check>	<description>	<phrase>[	<sweep>], tab-separated: has (-iF), hasc (-F) or sec (-F inside the
# <heading> section of $f, sec_has); the sweep field, a part of the phrase, is read by row_sweep, and a row
# whose sweep is not inside its phrase fails. The one schema of
# every pin table, so a whole phrase is written once, in its table row, and the regression test derives
# its drop case from LINT_PIN_LIST. A line opening with # and an empty line are skipped; a row short of
# a field, or with another check, fails
pins_from() {
  local check d phrase sweep
  [ -f "$1" ] || { bad "missing pin table: $1"; return 0; }
  while IFS=$'\t' read -r check d phrase sweep; do
    case $check in '#'*|'') continue ;; esac
    if [ -z "$d" ] || [ -z "$phrase" ]; then bad "${1##*/}: a row needs a check, a description and a phrase: $check"; continue; fi
    # a sweep is a part of its row's phrase, so rewording the phrase moves it; one left behind
    # would guard the old wording while every check passed
    case $phrase in *"$sweep"*) ;; *) bad "${1##*/}: the sweep of '$d' is not inside its phrase" ;; esac
    case $check in
      has|hasc) "$check" "$d" "$phrase" ;;
      sec) if [ -n "${2:-}" ]; then sec_has "$2" "$d" "$phrase"; else bad "${1##*/}: sec needs a heading: $d"; fi ;;
      *) bad "${1##*/}: unknown check $check" ;;
    esac
  done < "$1"
}
# table_field <table> <row description> <field>: sets table_value to that field (3 the phrase, 4 the
# sweep) of the pin table's row of that description, as the table writes it, empty with no such row or
# table. A run asks dozens of times, so a table is read once, as \036<description>\037<phrase>\t<sweep>
# rows, and asked with builtins
table_field() {
  local text=table_text_${1//-/_} row LC_ALL=C
  [ -n "${!text+set}" ] || printf -v "$text" '%s' \
    "$(awk -F '\t' '$1 !~ /^#/ { print "\036" $2 "\037" $3 "\t" $4 }' "$pins_dir/$1.tsv" 2>/dev/null)"
  table_value=
  case ${!text} in *$'\036'"$2"$'\037'*) ;; *) return 0 ;; esac
  row=${!text}; row=${row#*$'\036'"$2"$'\037'}; row=${row%%$'\n'*}
  if [ "$3" = 3 ]; then table_value=${row%%$'\t'*}; else table_value=${row#*$'\t'}; fi
}
# row_phrase <table> <row description>: sets row_text to that row's phrase, as the table writes it, for
# a check in another doc that must follow the row when it is reworded (dev-yqpz); a missing row
# fails the lint and leaves row_text empty
row_phrase() {
  table_field "$1" "$2" 3
  row_text=$table_value
  # a missing table is reported once, by pins_from, in the section that reads it
  [ -n "$row_text" ] || [ ! -f "$pins_dir/$1.tsv" ] || { bad "no row '$2' in $1.tsv"; return 1; }
  [ -n "$row_text" ]
}
# row_sweep <table> <row description>: sets row_text to what a skill must not restate of that row: its
# sweep field, else its phrase less the backtick a code span opens or closes it with
row_sweep() {
  row_phrase "$1" "$2" || return 1
  table_field "$1" "$2" 4
  if [ -n "$table_value" ]; then row_text=$table_value; else row_text=${row_text#\`} row_text=${row_text%\`}; fi
}
# hasc_row, lacksf_row <description> <table> <row description>: hasc or lacksf of that row
hasc_row() { row_phrase "$2" "$3" && hasc "$1" "$row_text"; }
lacksf_row() { row_sweep "$2" "$3" && lacksf "$1" "$row_text"; }
# what a skill that cites the rules doc's Repo plumbing and Cut-off probe must not restate
plumbing_copies() {
  lacksf_row "a second copy of the check target probe" repo-plumbing-pins "the check target is read from make's database"
  lacksf_row "a second copy of the check target refusal" repo-plumbing-pins "a repo with no check target fails the run with the setup line, before any task orchestrator starts"
  lacksf_row "a second copy of the forge decision" repo-plumbing-pins "the forge is decided once"
  lacksf_row "a second copy of the Gitignore commit recipe" repo-plumbing-pins "the Gitignore commit is keyed on a dirty file"
  lacksf_row "a second copy of the Gitignore commit's message file" repo-plumbing-pins "the Gitignore commit goes through a message file"
  lacksf_row "a second copy of the merge guard's forge query" repo-plumbing-pins "the merge guard's GitHub query"
  lacksf_row "a second copy of the merge guard's Forgejo query" repo-plumbing-pins "the merge guard's Forgejo query names the repo"
  lacksf_row "a second copy of the merge guard's ancestry check" repo-plumbing-pins "the merge guard compares by ancestry"
}
# the roles and review tools the three-row restatement retired (INFRA-33), swept in section 5
retired_row_names() {
  lacksw "the retired driver role in $f" '(^|[^a-z])[Dd]rivers?([^a-z]|$)'
  lacksw "the retired ticket runner role in $f" '[Tt]icket runners?'
  lacksw "the retired merger role in $f" '(^|[^a-z])[Mm]ergers?([^a-z]|$)'
  lacksw "the retired fix-up implementer role in $f" '[Ff]ix-up implementers?'
  lacksw "the built-in code-review named in $f" 'built-in `code-review`'
  lacksw "the two review tools paragraph in $f" 'Two review tools'
}
# the epic row's fourth failure reads only the Check gate's two lines, red or blocking (dev-aeo):
# both are blanked, so any other `failed: <story-id> ...` naming a fix-up left in $f is a FAIL
epic_fourth_failure_lines() {
  local scan other='failed: <story-id> [^`]*fix-up' red blocking
  unchanged_file && return 0
  # the two lines the Check gate allows are the pin table's rows, so a reword of one follows it;
  # they are blanked as literal text by index, not as a pattern (a phrase may hold a / or a pattern
  # character), and not by bash's ${//}, which is quadratic in bash 3.2
  row_phrase implement-spec-pins "red-check budget failure line" || return 0
  red=$row_text
  row_phrase implement-spec-pins "blocking-verdict budget failure line" || return 0
  blocking=$row_text
  scan=$(red=$red blocking=$blocking awk '{
    for (k = 1; k <= 2; k++) {
      p = ENVIRON[k == 1 ? "red" : "blocking"]
      while ((i = index($0, p))) $0 = substr($0, 1, i - 1) substr($0, i + length(p))
    }
    print }' "$f")
  if grep -q "$other" <<<"$scan"; then
    bad "present: an epic-row fourth-failure line the Check gate does not allow"
    grep -n "$other" <<<"$scan" | head -3
  fi
}
# run the queued checks: a missing pattern or a present lacks one is a FAIL line; a lacks, lacksf,
# lackse or lacksw one is followed by its first three matching lines, numbered as grep -n numbers them,
# an anchored one names its anchor, a paragraph or opening one the scope it searched
checks_run() {
  local out
  [ -n "$queue" ] || return 0
  out=$(printf '%s' "$queue" | LC_ALL=C awk -F '\t' '
    BEGIN { meta = "^$.[]()*+?{}\\" }
    { k[NR] = $1; f[NR] = $2; d[NR] = $3; p[NR] = $4; lp[NR] = tolower($4); a[NR] = $5
      if (!($2 in nat)) files[++nf] = $2
      at[$2, ++nat[$2]] = NR
      # a lacks (-iE) pattern of plain words, or of alternatives of them, is matched with index
      # rather than as a regex: cheap in every awk, where the regex is slow in gawk
      if ($1 == "x") {
        s = lp[NR]; gsub(/\\\./, "", s)
        for (c = 1; c <= length(meta); c++) if (index(s, substr(meta, c, 1))) break
        if (c > length(meta)) {
          nw[NR] = split(lp[NR], w, "|")
          for (q = 1; q <= nw[NR]; q++) { gsub(/\\\./, ".", w[q]); W[NR, q] = w[q] }
        }
      }
      # the checks sharing a kind, pattern and anchor run back to back (below)
      g = $1 SUBSEP $4 SUBSEP $5
      if (!(g in gn)) gs[++ng] = g
      G[g, ++gn[g]] = NR }
    END {
      for (j = 1; j <= nf; j++) {
        fn = files[j]; n = 0
        while ((getline line < fn) > 0) { n++; L[fn, n] = line; LO[fn, n] = tolower(line) }
        close(fn); N[fn] = n
      }
      # each check scans its file start to end, stopping at its first hit (its third for a
      # lacks), and the checks run grouped by pattern, so a dynamic regex is compiled once per
      # pattern rather than once per line or per file (gawk caches only the last one at each
      # match)
      for (gi = 1; gi <= ng; gi++) for (gm = 1; gm <= gn[gs[gi]]; gm++) {
        i = G[gs[gi], gm]; t = k[i]; fn = f[i]; n = N[fn]
        # a wrapped (lacksw) check matches the file read as one line, every line trimmed of its
        # blanks and quote markers and joined to the last at JO[fn, ln] by one space, or by
        # two where a block starts (a blank line, a heading, list item, table row or fence, and
        # the line after a heading, table row or fence), which no phrase spans; a hit names the
        # line it starts on, and the next search starts on the line after it
        if (t == "w" || t == "W") {
          if (!((fn, t) in J)) {
            s = ""; pblk = 0
            for (ln = 1; ln <= n; ln++) {
              x = (t == "W" ? L[fn, ln] : LO[fn, ln]); sub(/^[ \t>]+/, "", x); sub(/[ \t]+$/, "", x)
              blk = (x == "" || x ~ /^(#|\||```|[-*+] |[0-9]+\. )/)
              JO[fn, ln] = length(s) + 1
              s = s (ln == 1 ? "" : (blk || pblk ? "  " : " ")) x
              pblk = (x ~ /^(#|\||```)/)
            }
            J[fn, t] = s
          }
          ln = 1; pos = 1
          while (match(substr(J[fn, t], pos), (t == "W" ? p[i] : lp[i]))) {
            at0 = pos + RSTART - 1
            while (ln < n && JO[fn, ln + 1] <= at0) ln++
            shown[i] = shown[i] ln ":" L[fn, ln] "\n"
            if (++hit[i] == 3 || ln == n) break
            ln++; pos = JO[fn, ln]
          }
          continue
        }
        if (nw[i]) {
          for (ln = 1; ln <= n; ln++) {
            for (q = 1; q <= nw[i]; q++) if (index(LO[fn, ln], W[i, q])) break
            if (q <= nw[i]) { shown[i] = shown[i] ln ":" L[fn, ln] "\n"; if (++hit[i] == 3) break }
          }
          continue
        }
        on = 0
        for (ln = 1; ln <= n; ln++) {
          line = L[fn, ln]
          if (t == "i") { if (index(LO[fn, ln], lp[i])) { hit[i] = 1; break } }
          else if (t == "x") { if (LO[fn, ln] ~ lp[i]) { shown[i] = shown[i] ln ":" line "\n"; if (++hit[i] == 3) break } }
          else if (t == "c") { if (index(line, p[i])) { hit[i] = 1; break } }
          else if (t == "e") { if (line ~ p[i]) { hit[i] = 1; break } }
          else if (t == "f") { if (index(LO[fn, ln], lp[i])) { shown[i] = shown[i] ln ":" line "\n"; if (++hit[i] == 3) break } }
          else if (t == "y") { if (line ~ p[i]) { shown[i] = shown[i] ln ":" line "\n"; if (++hit[i] == 3) break } }
          else if (t == "a" || t == "X") { if (index(line, p[i]) && line ~ a[i]) { hit[i] = 1; break } }
          else if (t == "A") { if (line ~ a[i] && line ~ p[i]) { hit[i] = 1; break } }
          else if (t == "p") {
            # the paragraph opens on its heading line and closes for good at the next empty line
            if (index(line, a[i]) == 1) on = 1
            if (on) { if (line == "") break; if (index(LO[fn, ln], lp[i])) { hit[i] = 1; break } }
          }
          else if (t == "S") {
            # the section opens on its heading line and closes at the next ## heading
            if (line == a[i]) on = 1
            else if (on && index(line, "## ") == 1) break
            if (on && index(line, p[i])) { hit[i] = 1; break }
          }
          else if (t == "o") { if (index(line, "## ") == 1) break; if (index(line, p[i])) { hit[i] = 1; break } }
        }
      }
      for (i = 1; i <= NR; i++) {
        t = k[i]
        if (t == "x" || t == "f" || t == "y" || t == "w" || t == "W") { if (hit[i]) printf "FAIL: present: %s (%s)\n%s", d[i], p[i], shown[i] }
        else if (t == "X") { if (hit[i]) printf "FAIL: present: %s (%s on a line matching %s)\n", d[i], p[i], a[i] }
        else if (hit[i]) continue
        else if (t == "a" || t == "A") printf "FAIL: missing: %s (%s on a line matching %s)\n", d[i], p[i], a[i]
        else if (t == "p") printf "FAIL: missing in the %s paragraph: %s (%s)\n", a[i], d[i], p[i]
        else if (t == "S") printf "FAIL: missing in the %s section: %s (%s)\n", a[i], d[i], p[i]
        else if (t == "o") printf "FAIL: missing in the opening: %s (%s)\n", d[i], p[i]
        else printf "FAIL: missing%s: %s (%s)\n", (t == "c" ? " (case-sensitive)" : ""), d[i], p[i]
      }
    }') || bad "the check pass failed (awk exit $?)"
  queue=
  [ -z "$out" ] || { printf '%s\n' "$out"; fail=1; }
}
# section <header>: runs the previous section's checks, then opens this one
section() { checks_run; echo "== $1"; }
# doc <n> <title> <file>: opens section n on <file> (sets f), true when it exists and its section has
# something to check; a missing one is a failure naming it, never a skipped section. With <file>
# and every pin table in LINT_UNCHANGED the section's whole body is skipped: its checks would each
# skip <file> anyway, the tables are all a body reads besides, and the regression test runs the
# lint hundreds of times, those calls being most of a run with one changed doc. With LINT_UNCHANGED
# unset, or a table left out of it, every body runs and its rows are asked for
doc() { f=$3; section "$1. $2: $f"; [ -f "$f" ] || { bad "missing document: $f"; return 1; }; [ -z "$tables_unchanged" ] || ! unchanged_file; }

skills=${SKILLS_DIR:-$root/skills}
agents=${AGENT_DOCS:-$root/docs/agents}
docs=${DOCS_DIR:-$root/docs}
docs=${docs%/}
user_claude_md=${USER_CLAUDE_MD:-$root/CLAUDE.md}
glossary_md=${GLOSSARY_MD:-$root/GLOSSARY.md}
runbook=${2:-$root/docs/WORKFLOW.md}
pins_dir=${LINT_PINS_DIR:-$root/scripts}
# set when LINT_UNCHANGED lists every pin table the lint reads, which lets doc skip a listed doc's
# section; a table gone counts as not listed, so pins_from reports it, and a LINT_PIN_LIST run
# leaves it unset, since the pin list takes every check
tables_unchanged=
if [ -n "${LINT_UNCHANGED:-}" ] && [ -z "${LINT_PIN_LIST:-}" ]; then
  tables_unchanged=1
  for t in implement-spec-pins repo-plumbing-pins; do
    [ -f "$pins_dir/$t.tsv" ] || tables_unchanged=
    case $unchanged in *$'\n'"$pins_dir/$t.tsv"$'\n'*) ;; *) tables_unchanged= ;; esac
  done
fi
# ---- the phrases more than one check pins, each written once and built into every check that pins it (dev-yqpz) ----
# A whole pin phrase is written once: in this block, in a pin table row (read with row_phrase) or in its
# one check, never typed again as its own literal on another lint line or table row; every check that
# pins it is built from that one place, so rewording it is one edit and the regression test's cases
# follow. A different, longer pin that embeds or shares a run of the phrase is no repeat, and needs
# no shared variable or split row: rewording the shared run may need an edit in each pin holding it.
# the harness doc's rule names: its headings pin them, and section 5 sweeps a citation of them at the rules doc
rule_waiting='Waiting'
rule_idle='Idle rule'
rule_commits='Commits'
rule_cut_off='Cut-off agents'
rule_literal_paths='Literal paths'
rule_tmpdir='TMPDIR'
# paragraph and section headings several checks scope to
head_check_command='**Check command.**'
head_check_gate='**Check gate.**'
head_check_record='**Check record.**'
head_check_scope='**Check scope.**'
head_commits="**$rule_commits.**"
head_considered_options='## Considered options'
head_cut_off_agents="**$rule_cut_off.**"
head_delivery_authority='**Delivery authority.**'
head_epic_row='**The epic row.**'
head_has_database='**Has a database.**'
head_idle_rule="**$rule_idle.**"
head_literal_paths="**$rule_literal_paths.**"
head_tmpdir="**$rule_tmpdir.**"
head_waiting="**$rule_waiting.**"
head_landing_a_task='**Landing a task.**'
head_plugin_root='**Plugin root.**'
head_review_scope='**Review scope.**'
head_review_verdict='**Review verdict.**'
head_start_work_on_a_task='## When a skill says "start work on a task" (`/dev:implement-story`, `/dev:implement-task`)'
# line anchors several checks share
anchor_adr_status_accepted='^status: accepted$'
anchor_first_failure_report='^   - `<id> failed: <reason>`'
anchor_git_follows_bullet='^- `git` follows'
anchor_runbook_row_4a='^[|] 4a [|] `/dev:implement-spec`'
anchor_story_step_4_frontier='^4\. \*\*Work the frontier\.\*\*'
anchor_task_step_2_implementer='^2\. Spawn the \*\*implementer\*\*'
# phrases pinned in more than one doc or on more than one line
pin_120_second_default='120-second default'
pin_avoided_term_human_task='(^|[^-])human task'
pin_call_task_orchestrator_skill='Call the Skill tool with `dev:task-orchestrator`'
pin_cite_epic_bead_writes='"epic bead writes" convention'
pin_cite_gather_epic_bead='"gather the epic bead"'
pin_cite_has_a_database_rule='"Has a database" rule'
pin_cite_malformed_epic_refusal='malformed-epic refusal of the tracker doc'
pin_cite_one_test='the one test'
pin_cite_preflight='"Working-directory preflight"'
pin_conflict_resolutions='conflict resolutions'
pin_forge_decision='its Forge decision'
pin_frontmatter_disable_model_invocation='disable-model-invocation: true'
pin_gh_checks_watch='gh pr checks <n> --repo <forge-slug> --watch'
pin_gitignore_commit='its Gitignore commit'
pin_literal_owner_git_path='<owner>/\.git/'
pin_mktemp_template='mktemp -d <worktree>/.tmp/<name>.XXXXXX'
pin_needs_triage_wontfix='`needs-triage` or `wontfix`'
pin_no_story_bead_or_gate='no story bead and no story gate'
pin_red_log_line='`red log: <log>`'
pin_red_or_blocking_to_fresh_fix_up='A red or a blocking verdict goes to a fresh implementer by pointer brief and the loop starts over'
pin_retired_foreground_spawn='spawns in the foreground|foreground spawn returns|has no notification to wait for'
pin_retired_zero_findings_bar='not clean after three rounds|no findings at all|clean means zero findings'
pin_spawn_at_opus='at `model: opus`'
pin_notes_dir_name='.spec-notes'
pin_spec_notes_path=${pin_notes_dir_name//./\\.}
pin_story_row_frontier_of_one='the story row with a frontier of one'
pin_tea_api_without_repo='tea api repos/'
pin_timeout_600000='timeout: 600000'
pin_task_orchestrator_bold='**task orchestrator**'
pin_trailer_bead='Bead: <task-id>'
pin_trailer_refs='Refs: <KEY>-<n>'
pin_trailer_co_authored_by='Co-Authored-By: <model> <noreply@anthropic.com>'
pin_trailer_claude_session='Claude-Session: <session-url>'
pin_every_tree_checked_once='every tree is checked once'
pin_pr_stays_a_draft='The PR stays a draft'
cite_harness_idle_rule="harness doc's Idle rule"
pin_spawned_by='by /dev:implement-story or /dev:implement-task'
pin_run_close_story='run `/dev:close-story <story-id>`'
cmd_implement_story='/dev:implement-story <story-id>'
pin_child_not_a_story='<child-id> is not a story'
pin_code_review_name='mattpocock-skills:code-review'
# phrases built from another pin, so each is still written once
pin_code_review_tool="\`$pin_code_review_name\`"
pin_conflict_resolutions_per_landing="three $pin_conflict_resolutions per landing"
anchor_task_orchestrator_header="^You are the ${pin_task_orchestrator_bold//\*/\\*}"
pin_refused_not_a_story="refused: $pin_child_not_a_story"
pin_carries_needs_triage="carries $pin_needs_triage_wontfix"
pin_malformed_epic_refusal_line="<epic-id> $pin_refused_not_a_story"
# the plain phrases, each typed here once
pin_not_ready_for_human_alone='other than `ready-for-human` ones|non-`ready-for-human`'
pin_refused_pr_closed_unmerged='refused: PR <url> is closed unmerged'
pin_refused_pr_already_merged='refused: PR <url> already merged'
pin_failed_red_after_conflict='failed: red after conflict resolution'
pin_add_dir_remedy='/add-dir <'
pin_add_mode='add mode'
pin_resync='re-sync'
pin_story_dag='story DAG'
pin_design_field_read='.[0].design'
pin_profile_gated_push='when the active profile permits'
pin_plugin_root_variable='CLAUDE_PLUGIN_ROOT'
pin_verdict_clean='verdict: clean'
pin_verdict_blocking='verdict: blocking (<n>)'
pin_blocking_or_minor='**blocking** or **minor**'
pin_cell_check_command='| the check command'
pin_story_row_lands='The story row lands'
pin_retry_at_gate_on_resolved_branch='entering at the gate on the resolved branch'
pin_landing_closes_task='A landing closes the task'
pin_checks_skipped_no_forge='checks: skipped: no forge'
head_repo_plumbing='## Repo plumbing and Cut-off probe'
pin_inbox_as_deferrals='the inbox as deferrals'
pin_spawn_two_reviewers='spawn two **reviewers**'
pin_chains_out_of_scope='chains are out of scope'
pin_implement_task_id='`/dev:implement-task <id>`'
pin_implement_task_task_id='`/dev:implement-task <task-id>`'
pin_never_through_c='never through `-C`'
pin_ff_only_merge='git -C <owner> merge --ff-only <task branch>'
pin_bd_close='bd -C <owner> close'
pin_rev_parse_head='`git -C <worktree path> rev-parse HEAD`'
pin_not_a_task_worktree='not a task worktree'
pin_its_check_target='its Check target'
pin_with_fresh_budget='with a fresh budget'
pin_one_topological_pass='one topological pass'
pin_pr_command_re='/mattpocock-skills:pr([^a-z-]|$)'
cite_delivery_authority="the rules doc's Delivery authority"
# the phrases every worktree brief carries and the order checks over them, each written once
# (dev-yqpz); the _re forms read a backtick as any character, to sit in a pattern
tmpdir_line='TMPDIR line'
plain_command='plain-command line, one plain `git` or `bd` command per Bash call, every path spelled out'
plain_re=${plain_command//\`/.}
pwd_step='first Bash call is `pwd` alone'
pwd_re=${pwd_step//\`/.}
spelled='spelled literally in every later `export`'
spelled_re=${spelled//\`/.}
tmpdir_then_plain="$tmpdir_line.*$plain_re"   # a brief's TMPDIR line, then its plain-command line
tmpdir_pwd_spelled="$pwd_re.*$spelled_re"   # the bare pwd step, then the path spelled literally
# the story gate's two phrases whose order the step 7 awk check reads (below) beside their pins
gate_first='Each pass runs the checks first'
gate_same='the same SHA exits the gate'
head_standalone_task='**The standalone task.**'
head_task_orchestrator_brief='## Task orchestrator brief'
head_branch_from_remote_ref='**Branches from a remote ref.**'
anchor_step_3_draft_pr='^   With a forge, open a \*\*draft PR\*\*'
gate_entry='`gate entry: <task branch> <worktree path> <tip SHA>`'
rec_green='a tree with a green record (`exit=0`) is checked: run nothing'
rec_red='a red record is no check, so the tree is checked again'
rec_any='a tree with a record is checked: read its exit and run nothing'
rec_fixup='After a red, a fix-up that commits nothing leaves the tree red-recorded, so the next pass checks it again'
rec_call='check > <owner>/.tmp/checks/<tree>/log'
tmpdir_export='mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp'
merge_then_close="merge its PR, then $pin_run_close_story"
dep_line='one `Dependency:` line per publish blocker'
plumbing_cite="the rules doc's Repo plumbing and Cut-off probe"
merge_guard_cite="$plumbing_cite, its Merge guard"
apply_probe="Apply $plumbing_cite"
probe_cite="the rules doc's Cut-off probe"
verdict_cite="the rules doc's Review verdict"
# the dirs and the docs no section owns must exist, a default as much as an override; the
# driver ($1) and the runbook ($2) are their sections' documents
section "0. paths"
for given in "$skills" "$agents" "$docs" "$pins_dir"; do
  [ -d "$given" ] || bad "no such directory: $given"
done
for given in "$user_claude_md" "$glossary_md"; do
  [ -f "$given" ] || bad "no such file: $given"
done
# phrases the pin tables hold, read from their rows (a missing row fails the lint)
# (each is set empty first, so a pin table or row that is gone fails its own check and not the shell)
cmd_spec_to_stories_key= cmd_spec_to_stories_epic= epic_row_budget=
row_phrase implement-spec-pins "add-mode stall hint" && cmd_spec_to_stories_key=$row_text
row_phrase implement-spec-pins "add-mode stall hint without an external ref" && cmd_spec_to_stories_epic=$row_text

# ---- 1. /implement-spec epic orchestrator ----
if doc 1 "/implement-spec epic orchestrator" "${1:-$skills/implement-spec/SKILL.md}"; then
hasc "the report's failed: forms name a merge conflict" 'for a conflicted PR; or step 6'"'"'s epic review line'
lacks "worktree steps" 'worktree'
# its home database gate is the tracker doc's rule, which section 6 checks (dev-e87)
hasc "/implement-spec cites the tracker doc's \"Has a database\" rule" "$pin_cite_has_a_database_rule"
# no merge steps; the one allowed use is the human stop naming "the PR to merge" for the user
# (chezmoi-9v4.1.6) and the rules doc's "Repo plumbing and Cut-off probe, its Merge guard",
# which implement-story and implement-task cite the same way), so both are blanked before the
# scan. The first blanking ignores case (any "The PR to merge"); the second is exact on purpose,
# so a variant spelling of the citation, or the phrase beside a real merge step, still fails
if ! unchanged_file; then
  merge_scan=$(sed -e 's/the PR to merge//gI' -e "s/${merge_guard_cite#"the rules doc's "}//g" "$f")
  if grep -qi 'merge' <<<"$merge_scan"; then
    bad "present: merge steps (merge)"; grep -ni 'merge' <<<"$merge_scan" | head -3
  fi
fi
# the phrases pinned one by one, in a table the regression test derives its pin cases from too
pins_from "$pins_dir/implement-spec-pins.tsv"
epic_fourth_failure_lines
# the glossary avoids "human task" for the human gate task ("ready-for-human task" is fine)
lacks "glossary's avoided term human task" "$pin_avoided_term_human_task"
# the epic row reviews and marks ready, but opening a PR stays the story orchestrator's
lacks "PR-opening steps" 'draft PR|pr create|pulls create|open(s|ing)? (a|the) PR'
lacks "a budget of blocking verdicts only" 'three blocking verdicts'
lacks "a spent budget skipping the review" 'is failed and not reviewed again'
lacks "nothing touches a task" 'nothing below touches a task'
# the review set reads the delivered: note, not a failed: report this run (dev-47z)
lacks "review set keyed on a failed: report this run" 'did not report `failed:` this run'
lacks "the paginated tea pr list" 'tea pr list'
has "frontmatter" "$pin_frontmatter_disable_model_invocation"
has "malformed epic refusal" "$pin_cite_malformed_epic_refusal"
lacks "implement-spec restating the malformed-epic refusal" "$pin_malformed_epic_refusal_line"
has "add-dir refusal" "$pin_add_dir_remedy"
hasc "Human stop" '**Human stop.**'
hasc "Stall" '**Stall.**'
hasc "Done" '**Done.**'
has "Finished story" 'finished story'
hasc "finished story tolerates untriaged children" "$pin_needs_triage_wontfix"
lacks "finished story keyed on ready-for-human alone" "$pin_not_ready_for_human_alone"
has "story orchestrator" 'story orchestrator'
has "implement-story" 'implement-story'
has "opus" 'opus'
has "resume command" '/dev:implement-spec <KEY>-<n>'
has "Jira step pointer" '"the spec is done"'
has "Jira already-made read" 'getJiraIssue'
has "no-startable path" 'No startable story'
has "stopped state" 'stopped at <bead-id>'
has "orchestration pointer" 'orchestration.md'
# the epic review reads delivery from the rules doc's Delivery section, never from a step number
# of /dev:implement-story (dev-b8d.1.3 review 1)
row_phrase implement-spec-pins "the delivered: note's shape" && hasc "the epic review cites the Delivery section for the delivered: note" "the rules doc's Delivery section writes \`$row_text\`"
hasc "draft until clean cites the Delivery section's forge-check wait" "the rules doc's Delivery section's forge-check wait"
# (no skill cites another skill's step number: section 5 sweeps every skill, dev-0ohl)
has "preflight pointer" "$pin_cite_preflight"

fi

# ---- 2. WORKFLOW.md runbook and /workflow ----
# /workflow prints each next command with the argument filled in, so a fresh session types it as-is
if doc 2 "/workflow" "$skills/workflow/SKILL.md"; then
hasc "workflow prints the story cut's argument" 'next: `/dev:spec-to-stories <arg>`'
hasc "workflow prints the task cut's argument" 'next: `/dev:spec-to-tasks <arg>`'
hasc "workflow prints a standalone task's next line" 'next: /dev:implement-task <task-id>'
hasc "workflow prints the malformed-epic line" "$pin_child_not_a_story"
hasc "workflow cites the malformed-epic refusal" "$pin_cite_malformed_epic_refusal"
fi
if doc 2 "/close-epic" "$skills/close-epic/SKILL.md"; then
hasc "close-epic refuses a non-story child as a malformed epic" "$pin_cite_malformed_epic_refusal"
lacks "close-epic restating the malformed-epic refusal" "$pin_malformed_epic_refusal_line"
fi
if doc 2 "runbook" "$runbook"; then
# the cut skills take the feature as their one argument; the runbook has a paragraph on it and
# writes it in the 3a and 3b rows below (chezmoi-nz0)
hasc "argument paragraph" '**The argument.**'
# row 4b is the standalone task: /dev:implement-task, and the small-bug route is one bd create
# then that skill, with no epic bead (INFRA-37); the retired words are section 5's sweep
line_has '^[|] 4b [|]' "4b names implement-task" "$pin_implement_task_task_id"
hasc "the small-bug route is one bd create then implement-task" "one \`bd create\`, then $pin_implement_task_task_id"
line_has "$anchor_runbook_row_4a" "4a names the task orchestrators" "$pin_task_orchestrator_bold"
# the story row lands (ADR 0016): 4a's task orchestrator reports a reviewed branch that its
# story orchestrator lands, and 4b's session lands its one task's (dev-b8d.1 story review 1)
line_has "$anchor_runbook_row_4a" "4a: the story orchestrator lands each task" 'the story orchestrator lands each reviewed branch'
line_has '^[|] 4b [|]' "4b: the session lands the task" 'the session lands its reviewed branch'
lacks "a task orchestrator landing its own task in the runbook" 'lands the task itself'
# 4a's check gate reviews medium and high tasks, a low task's gate being its checks (ADR 0015)
line_has "$anchor_runbook_row_4a" "4a reviews medium and high tasks" '(the checks, then, for `medium` and `high`, a review one tier up'
hase "the one review tool paragraph" '^One review tool, three rows'
# the task review is medium and high only, every owner repo having a check command (ADR 0015)
hasc "the runbook reviews medium and high tasks" "task's review model, for \`medium\` and \`high\`; at the story"
lacks "the runbook's task review limited to medium and high" '(`medium` and `high` only)'
line_has '^[|] 4a [|] opus [|]' "session model 4a: the epic orchestrator session" 'The epic orchestrator session'

lacks "retired task gate name in the runbook" 'task gate'

# stale wording
for pat in 'cross-repo task' 'per-task `pr:`' 'single orchestrator' 'one orchestrator drives'; do
  lacksf "stale wording" "$pat"
done
# session mode (ADR 0008): runbook-only retired wording is absent (section 5 sweeps the walk-up list), the mode is named
for pat in 'workspace **inbox**' 'resume from the home repo' "the home repo's story is a child"; do
  lacksf "retired wording" "$pat"
done
hasc "workspace session named" 'workspace session'
hasc "cross-repo typed at the workspace root" 'typed at the workspace root'
hasc "resume from the workspace root" 'resume from the workspace root'
hasc "inbox is the home's beads" "the home's beads"

line_lacks '^\| 4a \|' "sonnet at 4a in session-model table" sonnet

# required content
hasc "one-line flow" '/mattpocock-skills:grill-with-docs → /mattpocock-skills:to-spec → /dev:spec-to-stories → /dev:spec-to-tasks → /dev:implement-spec → /dev:close-epic'
hase "4a session model is opus" '^\| 4a \| opus'
hase "3a row" "^\\| 3a \\| \`$cmd_spec_to_stories_key\`"
hase "3b row" '^\| 3b \| `/dev:spec-to-tasks <KEY>-<n>`'
hase "1-3b session model is fable" '^\| 1–3b \| fable'
hasc "exploration notes path" "\`<repo>/$pin_notes_dir_name/<epic-id>/\`"
for need in "$cmd_implement_story" '/dev:close-story' 'story bead' 'GLOSSARY.md'; do
  hasc "runbook content" "$need"
done
# the story DAG's runbook text (ADR 0011): add mode, and the human stop's merge-then-close line
# as the skills print it; the task cut's chain refusal is retired
hasc "add mode in the runbook" "$pin_add_mode"
hasc "human-stop merge line in the runbook" "$merge_then_close"
hasc_row "printed human-stop line in the runbook" implement-spec-pins "story-closure human stop line"
lacks "chain refusal in the runbook" 'refus[a-z]*[^|]{0,60}dependency chain|dependency chain \(A depends'
hase "/mattpocock-skills:pr named (Variants)" "$pin_pr_command_re"

# /pr stays off the main line: the fenced flow block and stage 5
unchanged_file || awk -v re="$pin_pr_command_re" '/^```/{fence=!fence; next} fence && $0 ~ re {n=1} END{exit n}' "$f" || bad "/mattpocock-skills:pr in the fenced flow"
lackse "/mattpocock-skills:pr in stage 5" '^\| 5 .*'"$pin_pr_command_re"

# the stage table stays one table (rows 1..8 contiguous)
unchanged_file || awk '/^\| 1 \|/{on=1} on && !/^\|/{bad=1} /^\| 8 \|/{on=0} END{exit bad}' "$f" || bad "stage table broken by a non-row line"

fi

# ---- 3. /spec-to-stories ----
if doc 3 "/spec-to-stories" "$skills/spec-to-stories/SKILL.md"; then
has "frontmatter" "$pin_frontmatter_disable_model_invocation"
has "preflight pointer" "$pin_cite_preflight"
has "epic gather pointer" "$pin_cite_gather_epic_bead"
# the argument is required; recovering the epic from the conversation or the open epic list
# is retired (chezmoi-nz0)
hasc "usage line" "usage: $cmd_spec_to_stories_key|<epic-id>"
lacks "no-argument epic recovery" 'bd list --type epic --json|open epic beads|reported in the conversation'
# the orientation goes to the story bead's design field; the story cut writes nothing in an owner
# repo but beads (chezmoi-cdf, ADR 0010)
hasc "design field write" 'update <story-id> --design-file -'
hasc "orientation header line" 'Orientation from the story cut; the story body is the only contract.'
hasc "beads-only writes in owner repos" 'writes no file and runs no git write in any owner repo'
lacks "step 8 gitignore line or commit" 'chore: ignore spec notes|Gitignore step commits it|'"$pin_spec_notes_path"'|>> <owner>/\.gitignore|git -C <owner> (add|commit)'
has "no Jira comment" 'No Jira comment'
has "the design field names the other repo of a pair" "the other repo's name"
# the user's bd init in <home> is checked before any bd call lands there, and refused when it
# made no <home>/.beads (dev-zyx)
hasc "the home database check after the user's init" '`bd -C <home> where` prints `<home>/.beads`'
hasc "an aborted init in the home is refused" '`refused: bd init in <home> aborted: <error>`'
hasc "an init in the home that where does not name is refused" '`refused: bd -C <home> where names <path>, not <home>/.beads`'
has "repo-session line" 'repo session in <home>: one story, in the home repo'
has "repo-session refusal" 'refused: the spec changes <what> outside <home>; start this at the workspace root'
has "one test pointer" "$pin_cite_one_test"
has "workspace-session key warnings" 'in a workspace session'
lacks "re-sync instruction" "$pin_resync"
lacks "Jira comment step" 'addCommentToJiraIssue'
has "epic bead writes pointer" "$pin_cite_epic_bead_writes"
# the stories form a DAG detected per edge, not a pair; the cut proposes a split of a repo's
# story only for a deprecate-then-remove, the user may split for any reason (ADR 0011)
has "story DAG" "$pin_story_dag"
lacks "pair-wise dependency detection" 'for each pair of stories'
hasc "split proposed only for a deprecate-then-remove" 'only when the spec describes a deprecate-then-remove'
hasc "user split for any reason" 'split a repo'"'"'s story for any reason'
# a cut whose edges close a cycle is refused with the stories named, before any bead exists
hasc "cycle refusal" 'refused: the stories form a cycle (<repo> <story title> -> <repo> <story title> -> ...)'
hasc "cycle refused before any bead exists" 'stop before any bead exists'
hasc "cycle refused before step 7's epic bead" "that this run would create, step 7's epic bead included"
# the stories are listed, published and reported in topological order, each with one
# `## Blocked by` line per edge in both forms; the quiz and end report show every publish
lacks "pair-era dependency-first order" 'numbered list, dependency first'
hasc "topological order" 'topological order'
hasc "one blocker line per edge" 'one `## Blocked by` line per edge'
hasc "story-closure line form" 'a story-closure edge as `<repo> <story-id>`'
hasc "publish placeholder line form" 'a publish edge as `<dep repo> publish <crate> <version> (not created yet)`'
hasc "end report names each publish" 'publishes: <crate> <version> (from <current version>)'
hasc "end report names a story-closure edge" 'blocked by: <repo> <story-id>'
hasc "orientation names every edge" 'every edge of the story'
# the frontmatter says one story per PR (ADR 0011)
has "frontmatter: one story per PR" 'one story per PR, usually one per repo it changes'
# the deprecate-then-remove split's full shape, so it cannot trip its own cycle refusal: the
# removing half waits on each migrating story's closure, each migrating repo gets a second
# story bumping to the removal, and an importer's edge names the half it needs
hasc "removing half waits on the migrating stories" "the removing half waits on each migrating story's closure"
hasc "second migrating story bumps to the removal" "a second story that bumps to the removal's version"
hasc "importer names the half it needs" 'names the half it needs'
# a story waiting on a skipped story's closure is skipped too, with no invented line form
hasc "closure on a skipped story is skipped" "<repo> skipped: waits on <skipped repo>'s story"
lacks "invented closure line on a skipped story" '<story title> \(not created: no beads database\)'
# the skip cascades over closure and publish edges alike; only a story skipped for no beads
# database gets step 2's epic bead note, which is false for one skipped for waiting on it
hasc "skip cascades over both edge kinds" 'nor any story with an edge on it in turn, closure or publish'
hasc "epic bead note for a no-database skip" 'Record each story skipped for no beads database on the epic bead'
hasc "a waits-on skip is reported only" 'a story skipped for waiting on one is reported only'
lacks "epic bead note for every skipped story" 'Record each skipped story on the epic bead'
# a deploy split: the earlier story's paragraph names the deploy as its last step
hasc "deploy is the earlier story's last step" 'names the deploy as its last step'
# a cycle the user introduces at the quiz is rejected there; the skill keeps iterating
hasc "quiz cycle rejected, quiz continues" 'reject that change and keep iterating'
# the out-of-scope cases match the tracker doc's dependency section
hasc "ssh URL out of scope" 'pinned by git tag or ssh URL'
hasc "several crates in one story out of scope" 'several crates in one story'
# a feature whose stories exist enters add mode; the refusal stays only when every story is
# closed (ADR 0011)
has "add mode" "$pin_add_mode"
lacks "unconditional stories-exist refusal" 'refused: stories exist'
hasc "refusal only when every story is closed" 'refused: every story is closed'
hasc "add mode shows each story's state" 'finished, open with failed tasks, waiting'
hasc "add mode reads the failed twice: notes" 'names the `failed twice:` reason it answers'
hasc "add mode quizzes the additions only" 'quizzes the additions only'
# one forge query per finished story an addition touches, sandbox-disabled as /close-story's
hasc_row "forge query, GitHub" repo-plumbing-pins "the merge guard's GitHub query"
hasc_row "forge query, Forgejo/Gitea" repo-plumbing-pins "the merge guard's Forgejo query names the repo"
lacks "Forgejo/Gitea forge query without --repo" "$pin_tea_api_without_repo"
hasc_row "forge query runs sandbox-disabled" repo-plumbing-pins "the merge guard runs the forge query sandbox-disabled"
hasc "MERGED forces a new story on the old one's closure" 'a new story blocked on its closure and on the new publish'
hasc "MERGED reminds the close" "$pin_run_close_story"
hasc "OPEN defaults to a re-cut" '`OPEN` defaults to a re-cut'
hasc "no forge or a branch-form pr: asks the user" 'a branch-form `pr:` value asks the user'
# OPEN's re-cut marks the finished dependent so the task cut may re-cut it past its pr: note;
# a PR closed unmerged is refused, as /implement-story's merge guard refuses it (story review 1)
hasc "OPEN marks the finished dependent for a re-cut" '`recut: <dep repo> publish <crate> <version>`'
hasc "a PR closed unmerged is refused" "$pin_refused_pr_closed_unmerged"
lacks "a PR closed unmerged takes OPEN's path" 'closed unmerged is not sealed|closed unmerged[^.]*takes `OPEN`'
# step 7 in add mode writes the additions and the rewritten dependent bodies, beads only
hasc "add mode publishes the additions only" 'publishes the additions only'
row_phrase implement-spec-pins "fix-up description on stdin" && hasc "open dependent's body rewritten" "update <story-id> $row_text"
hasc "add mode leaves Jira untouched" 'the Jira description is untouched'

fi

# ---- 4. /spec-to-tasks ----
if doc 4 "/spec-to-tasks" "$skills/spec-to-tasks/SKILL.md"; then
has "frontmatter" "$pin_frontmatter_disable_model_invocation"
has "no-stories refusal" 'refused: no stories'
has "every-story-cut refusal" 'refused: every story already cut'
has "every-story-cut remedy" 're-cut one with /dev:story-to-tasks <story-id>'
has "preflight pointer" "$pin_cite_preflight"
has "epic gather pointer" "$pin_cite_gather_epic_bead"
# the same argument rule as /spec-to-stories (chezmoi-nz0)
hasc "usage line" 'usage: /dev:spec-to-tasks <KEY>-<n>|<epic-id>'
lacks "no-argument epic recovery" 'ended on in the conversation|ask the user for it'
has "already cut line" '<repo> <story-id> already cut'
hasc "waiting rule pointer" 'the "Waiting" rule of `harness.md`'
has "no model override" 'no `model:` override'
has "waiting line" 'waiting on <dep repo> cut'
has "closed story line" '<repo> <story-id> closed'
has "skipped dependent gets explicit crate and version" 'Dependent: <repo>, skipped: no beads database, crate <crate>, version <version>.'
lacks "crate and version deferred to the notes" 'as the design field has them'
has "skipped dependent's crate and version read from the design field" 'design field'
lacks "owner-repo notes file" "$pin_spec_notes_path"
has "already-cut block carries What to build" '`## What to build` paragraph'
has "all-closed refusal" 'refused: every story closed'
has "closed-uncut dependency line" 'dependency story closed uncut'
has "failed publish line" '<repo> <story-id> publish failed: <reason>'
has "dependent of a failed publish line" 'waiting on <dep repo> publish'
has "dependency cut without a publish task waits" 'has no `publish <crate> <version>` child'
has "closed-uncut remedy reopens the dependency" 'bd -C <repo> reopen <id>'
has "Jira comment covers every story" 'every story of the feature that has tasks'
lacks "Jira comment limited to this run" 'tasks this run published'
lacks "re-sync instruction" "$pin_resync"
has "one test pointer" "$pin_cite_one_test"
has "epic bead writes pointer" "$pin_cite_epic_bead_writes"
lacks "story-cut procedure" 'Resolve the spec to its repos|Draft the stories|Quiz the user on the stories|Write the story-cut notes'
# the task cut cuts the story DAG (ADR 0011, chezmoi-9v4.1.8): a cycle is refused naming its
# stories; cutters run in topological waves, one per DAG level, each dependent's brief carrying
# every upstream breakdown, a story-closure edge ordering no wave; an already cut dependent of a
# new publish task is re-cut inline in the same run, so the rerun hint drops that case
has "cycle refusal names the stories" 'refused: dependency cycle ('
has "topological waves" 'topological waves'
has "one wave per DAG level" 'one wave per level of the story DAG'
has "dependent brief carries every upstream breakdown" "$dep_line"
has "story-closure edge orders no wave" 'a story-closure edge orders no wave'
has "the task cut re-cuts an already cut dependent" 're-cuts that dependent itself'
has "the re-cut adds a second bump" 'second bump'
# a skipped repo's publish line has no dependency story; the inline re-cut is keyed on the
# missing bump; a finished dependent is excluded at step 1, and a failed re-cut of a dependency
# that has its publish task holds no dependent back (chezmoi-9v4.1.8 review 1)
has "skipped publish line is an edge with no dependency" 'an edge with no dependency in the run'
has "re-cut keyed on the missing bump" 'has no bump child titled with that crate'
has "finished dependent excluded at step 1" 'cut failed: finished story (pr: note present)'
has "failed re-cut with a publish task holds nothing" 'already has its publish task holds nothing'
hasc "re-cut dependent also waits on a dependency without its publish" 'A dependent of the run (in the set to cut or to re-cut) with such an edge'
# a re-cut dependent that is also a dependency joins the trigger until no story joins, and no
# dependent waits on a publish the run creates; the cut-failure cascade covers only the run's
# dependencies, after the closed-uncut rule, so no story gets two report lines (review 2)
has "re-cut dependent without its publish joins the trigger" 'a dependent to re-cut without its publish task'
has "trigger applied to a fixed point" 'applied until no story joins'
has "no wait on a publish the run creates" 'and is not re-cut in this run'
has "cascade narrowed to the run's dependencies" 'a dependency of the run whose cutter failed or that was itself held back'
hasc "closed-uncut rule stands on its own" 'Nor is a dependent spawned whose dependency story is `closed` with no children'
has "re-cut line is a progress line" 'a step-1 progress line'
# a finished dependent add mode marked with a recut: note is re-cut for that edge; the
# all-closed refusal gives the live reason, not the retired stories-exist one (story review 1)
has "finished dependent re-cut on its recut: note" 'a `recut:` line for that edge'
lacks "retired stories-exist reason" 'since stories exist'
lacks "two-wave cap or chain refusal" 'two dependency waves suffice|two suffice|at most two( dependency)? waves'
lacks "rerun hint covering an already cut dependent" 'rerun this skill for the dependent'

fi

# ---- 5. agent docs and skills: retired phrases ----
section "5. retired phrases"
# the files a reader meets, listed once for every sweep below: every file under the agent docs
# and the skills, the project CLAUDE.md, the runbook, the sequence diagrams and the
# implement-spec skill passed as $1, wherever it lives (less those LINT_UNCHANGED lists). Each
# sweep reads a file as one line (lacksw), so a phrase wrapped across a line break is caught,
# and no other section repeats one: a seeded retired phrase fails here alone.
# docs/specs keeps every list, since a spec states the change it makes
swept=$({ find "$agents" "$skills" -type f 2>/dev/null
  printf '%s\n' "$user_claude_md" "$runbook" "$docs/SEQUENCES.md" "${1:-}"; } | grep . | sort -u | drop_unchanged)
# whole words only ("shortcut one", "cut ones" pass); "re-cut one" is the spec's wording, not the retired name
retired='(^|[^-A-Za-z0-9_])cut (one|two)([^-A-Za-z0-9_]|$)|<spec-slug>|story-cut\.md|[Ss]tory [Pp]lumbing'
# Session mode (ADR 0008): the walk-up wording.
walkup='nearest ancestor|walking up|walk up|one level up|the home repo included|the workspace root included|no repos\.yaml above|workspace inbox|workspace'\''s inbox|home repo <home repo>'
# The story-DAG wording (ADR 0011): one story per repo (now one per PR), the keyed branch
# feat/<key>-<n> (now feat/<story-id>), chains out of scope and the one text blocker (now a
# DAG), and the two-wave cap (now topological waves).
retired_dag="one story per repo|feat/<key>-<n>|$pin_chains_out_of_scope|only text blocker|two waves suffice"
# the check and review loop's retired two-gate wording (dev-1xf.1.4): the Evidence run, the later
# run that reviews a fix, the third-round wording and the second-red stall
retired_loop='evidence run|a later run reviews the fix|a third round of either kind|a second red'
# the gate with no check command (ADR 0015): every owner repo has a check target, so no doc names
# a review-only gate or a repo, task or gate without a check command
retired_gate='review-only|no check command|with(out)? a check command'
# a rule that moved to harness.md (dev-9k5.1.2) cited at the rules doc, doc first as "the rules
# doc's Worktrees", "the rules doc's worktree fallback", "the rules doc's Scratch space says
# (Literal paths)" or "(`orchestration.md`, Commits)", or rule first as 'the "Waiting" rule of
# `orchestration.md`'; the worktree fallback moved too, so the rules doc holds no fallback (dev-zra)
moved_names="($rule_waiting|$rule_idle|$rule_commits|$rule_cut_off|worktrees|hand-rolled|fallback|$rule_literal_paths|$rule_tmpdir|diff two files|python's cache line|recursive deletes|shell commands)"
# a database gate that tests only that .beads/ exists (dev-e87): as the shell test, as a missing
# <x>/.beads, or as a repo "with `.beads/`"; the gates cite the tracker doc's "Has a database" rule
beads_gate='test -d [^ ]*/\.beads|`<[a-z ]+>/\.beads` (is )?missing|no `<[a-z ]+>/\.beads`|with (no )?`\.beads/`'
moved_rule='(rules doc|orchestration\.md)`?(, |'\''s (([a-z-]+ ){1,3}says \(|scratch space \(|[a-z-]+ )?)'"$moved_names"'([^a-z]|$)|'"$moved_names"'"?( rule)? (of|in) (the )?`?(rules doc|orchestration\.md)'
# the task row as a skill (INFRA-37): one route per unit. No doc names a flat epic, the small-bug
# path, the two upstream skills it replaces or the rejected chore names (never the bare word
# chore, which the gitignore commit subject and the Conventional Commits type use)
retired_route='flat[ -](epics?|shape)|small[ -]bug path|mattpocock-skills:implement([^-a-z]|$)|(^|[^-a-z])to-tickets([^-a-z]|$)|implement-chore|chore orchestrator|chore/'
# no skill cites another skill's step number: steps renumber, so a citation like "/dev:close-story
# step 4" goes stale without a failing test; it names the rule by its section or the rules doc
# instead (dev-0ohl). A skill's own steps are its own to cite, so a file under the skills dir is
# swept for every skill but its own; a doc under docs/agents is no skill's, so it is swept for
# every skill (dev-90up). The name ends at a boundary (setup is not setup-repo), and the sweep
# reads "dev:<skill> step N" in that order only: a "step N of /dev:<skill>" citation is not
# caught. The match ignores case ("Step 4" fails). A "step" ending one line with "N. " opening a list item on the next is not
# caught either: the join puts two spaces at a block start, which the pattern's one space misses.
skill_names='|'
for given in "$skills"/*/; do
  given=${given%/}
  [ -d "$given" ] && skill_names+="${given##*/}|"
done
while IFS= read -r f; do
  case $f in
    "$skills"/*/*)
      own=${f#"$skills"/}; own=${own%%/*}
      others=${skill_names//|$own|/|}; others=${others#|}; others=${others%|}
      [ -z "$others" ] || lacksw "another skill's step number cited in $f (name the rule by its section or the rules doc)" "dev:($others)([^a-z -][^ ]*)? steps? [0-9]" ;;
    "$agents"/*)
      # a rules doc is no skill, so it cites every skill by rule name, never by step (dev-90up)
      all=${skill_names#|}; all=${all%|}
      [ -z "$all" ] || lacksw "another skill's step number cited in $f (name the rule by its section or bold name)" "dev:($all)([^a-z -][^ ]*)? steps? [0-9]" ;;
  esac
  lacksw "retired phrase in $f" "$retired"
  # no foreground spawn instruction: an Agent call returns at once whatever run_in_background
  # says, so skills and agent docs point at the waiting rule instead (chezmoi-p4q)
  lacksw "foreground spawn instruction in $f" 'run_in_background: false'
  lacksw "retired walk-up wording in $f" "$walkup"
  lacksw "retired story-DAG wording in $f" "$retired_dag"
  lacksw "retired two-gate wording in $f" "$retired_loop"
  lacksw "retired review-only gate wording in $f" "$retired_gate"
  # the retired vocabulary (dev-9k5.1.11): the epic, task and landing roles, the built-in
  # review by name, the review marker, the lint command and the test seams as checks
  retired_row_names
  lacksw "the retired review marker in $f" 'review markers?'
  lacksw "the retired lint command in $f" 'the lint command'
  lacksw "the retired test seams as checks in $f" 'test seams? as (the )?checks?'
  lacksw "a moved harness rule cited at the rules doc in $f" "$moved_rule"
  # bd init does take -C but lands on an ancestor's database through it, so the docs cite the
  # tracker doc's "First time in a repo" for why it runs from the repo instead (dev-zyx)
  lacksw "the retired bd init -C wording in $f" 'cannot take `-C`'
  # a .beads/ that bd where does not resolve to is no database, so a gate on the directory alone
  # lets a rerun file into the database bd climbs to (dev-e87)
  lacksw "an existence-only beads database gate in $f" "$beads_gate"
  # the story row lands each reviewed task branch serially, one per report, so the task
  # orchestrator's wait on the owner checkout's lock and its index.lock probe are gone
  # (dev-b8d.1.4)
  lacksw "the retired lock wait in $f" 'lock wait|index\.lock|under the lock'
  # one route per unit (INFRA-37): a standalone task goes to /dev:implement-task, an epic bead
  # with a non-story child is refused as malformed, and the upstream skills are not named
  lacksw "a retired route (flat epic or shape, small-bug path, upstream skill or chore name) in $f" "$retired_route"
done <<<"$swept"
# the root glossary lists the retired vocabulary under _Avoid_ (and docs/adr/ keeps its
# historical sense through .glossary-allow), so only the two-gate wording is swept there
f=$glossary_md
lacksw "retired two-gate wording in $f" "$retired_loop"
lacksw "retired review-only gate wording in $f" "$retired_gate"

# the docs ship in the plugin: no path into the old dotfiles deployment (~/.claude/docs,
# ~/.claude/hooks) or the chezmoi source remains in any doc under docs/, the skills, the agent
# docs, the project CLAUDE.md or the runbook, spelled ~/, $HOME/ or ${HOME}/ (INFRA-30)
deployed='(~|\$HOME|\$\{HOME\})/(\.claude/docs|\.claude/hooks|\.local/share/chezmoi)'
while IFS= read -r f; do
  lacks "dotfiles deployment path in $f" "$deployed"
done < <({ find "$docs" -type f -name '*.md' 2>/dev/null; find "$agents" "$skills" -type f 2>/dev/null
  echo "$user_claude_md"; echo "$runbook"; } | grep . | sort -u | drop_unchanged)

# ---- 6. shared rules the skills point at ----
if doc 6 "orchestration rules" "$agents/orchestration.md"; then
lacks "a foreground spawn" "$pin_retired_foreground_spawn"
hasc "preflight section" '## Working-directory preflight'
has "preflight remedy" "$pin_add_dir_remedy"
# the typed implement command is the authority to push and open the PR, so the push is a step
# of the run, with a failed: line when it is refused (ADR 0009, chezmoi-g61)
hasc "delivery authority rule" "$head_delivery_authority"
# /dev:implement-task is typed to deliver a PR too (dev-b8d.1.6 review 2)
para_has "$head_delivery_authority" "/dev:implement-task is typed to deliver a PR" 'and `/dev:implement-task` are typed to deliver a PR'
# the paragraph and the ## Delivery section are named apart, so a citation names one of them
lacksf "a paragraph named like the Delivery section" '**Delivery.**'
lacks "profile-gated push in the rules doc" "$pin_profile_gated_push"
# the epic-level stages reach an owner repo only through its beads database; files, .gitignore
# and commits there are the story orchestrator's (chezmoi-cdf, ADR 0010)
hasc "beads-only principle for the epic-level stages" 'only through its beads database'
lacks "the story cut commits the /.spec-notes/ line" 'The story cut commits'
# a task whose runner ended without closing it keeps its claim and bd ready omits it, so the
# story orchestrator unclaims it; a human does so only when the orchestrator could not (chezmoi-jvc)
hasc "frontier unclaim rule" '**Unclaim.**'
# the frontier admits only ready-for-agent tasks, not merely those without ready-for-human,
# so a needs-triage child filed under a story never gets a runner (chezmoi-wgi)
hasc "frontier admits ready-for-agent only" 'it is labelled `ready-for-agent`'
lacks "frontier keyed on ready-for-human alone" 'it is not labelled `ready-for-human`'
hasc "finished story tolerates untriaged children" "$pin_needs_triage_wontfix"
para_has '**Gitignore.**' "/.tmp/ among the Gitignore rule's entries" '`/.tmp/`'
# the rules docs ship in the plugin, so a brief reaches them through the plugin root: resolved
# once per session from the harness's variable and spelled as an absolute path in every brief,
# the TMPDIR rule's pattern (INFRA-30)
hasc "Plugin root rule" "$head_plugin_root"
para_has "$head_plugin_root" "the harness's plugin-root variable" "$pin_plugin_root_variable"
para_has "$head_plugin_root" "resolved once per session" 'once per session'
para_has "$head_plugin_root" "the rules-doc path spelled literally in every brief" '<plugin root>/docs/agents/'
para_has "$head_plugin_root" "spelled out in every brief" 'every brief'
# a reviewer tags every finding blocking or minor and ends on a verdict line; a round with no
# blocking findings is clean; every fix-up, red or blocking, spends the check gate loop's budget. The
# rule is stated once here; the runner brief and the story review point at it (chezmoi-49k)
hasc "Review verdict rule" "$head_review_verdict"
para_has "$head_review_verdict" "the clean verdict line" "$pin_verdict_clean"
para_has "$head_review_verdict" "the blocking verdict line" "$pin_verdict_blocking"
para_has "$head_review_verdict" "the blocking-or-minor tags" "$pin_blocking_or_minor"
para_has "$head_review_verdict" "a round with no blocking findings is clean" 'no blocking findings is **clean**'
para_has "$head_review_verdict" "every fix-up, red or blocking, spends the loop's budget" "Every fix-up, red or blocking, spends the loop's budget"
# no minor is dropped (dev-a9a): a blocking round's fix-up fixes its in-scope minors and names
# what it left, and every minor still unfixed when the unit lands or fails goes to the inbox
para_has "$head_review_verdict" "a blocking round's in-scope minors go to its fix-up" "those in the unit's scope go to its fix-up"
para_has "$head_review_verdict" "a fix-up's report names each minor it fixed and left unfixed" "report names each minor it fixed and each"
para_has "$head_review_verdict" "the epic row sends every round's minors to the inbox" "every round's minors go to the inbox at once"
para_has "$head_review_verdict" "every minor unfixed when the unit lands or fails goes to the inbox" 'every minor still unfixed when the unit lands or fails goes to the inbox'
para_has "$head_review_verdict" "a fanned-out reviewer reports once, after every sub-agent has" 'waits, by ending its turn, until every one of them has reported'
para_has "$head_review_verdict" "a fanned-out reviewer sends one whole-review report, and no orchestrator acts on a partial verdict" 'whose verdict covers the whole review; no orchestrator acts on a partial verdict'
# the model (dev-9k5.1.3): one loop run at three rows, stated once as its sentence and a table
# whose rows give each level its parameters; each row pinned on its own line, so a cell kept
# elsewhere in the doc cannot stand in
hasc "the loop sentence" 'claim a unit, have a subagent build it, check it, review it, send a failure to a fresh fix-up or land it at the row above, and report one line'
line_has '^[|] Row [|]' "the table's header names every parameter" '| Orchestrator | Builds | Checks | Review spec axis | Review standards axis | Reviewer and model | Fix-up | Lands by | Exits when | Budget |'
row='^[|] [*][*]Task[*][*] [|]'
line_has "$row" "task row: the task orchestrator" '| task orchestrator |'
line_has "$row" "task row: one implementer in a worktree" '| one implementer in a worktree |'
line_has "$row" "task row: the task's body as spec" "| the task's body |"
line_has "$row" "task row: the task diff as standards" '| the task diff |'
line_has "$row" "task row: both axes at the review model, none at low" "| both axes, at the task's review model; none at \`low\` |"
# the task row reports its reviewed branch and the story row merges it, the resolution cap
# moving with the landing to the story row (dev-b8d.1.4)
line_has "$row" "task row: lands by reporting its reviewed branch for the story orchestrator to merge" '| reports its reviewed branch, which the story orchestrator merges |'
line_has "$row" "task row: a fix-up by pointer brief, same worktree" '| an implementer by pointer brief, same worktree |'
line_has "$row" "task row: three fix-ups" '| three fix-ups |'
line_lacks "$row" "task row: a conflict resolution budget" "$pin_conflict_resolutions"
row='^[|] [*][*]Story[*][*] [|]'
line_has "$row" "story row: the story orchestrator" '| story orchestrator |'
line_has "$row" "story row: task orchestrators over the frontier" '| task orchestrators in parallel over the frontier |'
line_has "$row" "story row: the story's body as spec" "| the story's body |"
line_has "$row" "story row: what entered since as standards" "what entered since the last standards review: $pin_conflict_resolutions, cross-task coherence and the story gate's fix-up commits"
line_has "$row" "story row: both axes at the review model of the story's max tier" "| both axes, at the review model of the story's max tier |"
line_has "$row" "story row: a fix-up by pointer brief in a fix-up worktree" '| an implementer by pointer brief in a fix-up worktree |'
line_has "$row" "story row: lands by merging each reviewed task branch, then a push, the PR a draft" '| merges each reviewed task branch after the stray-commit check; push, the PR staying a draft |'
line_has "$row" "story row: three fix-ups and three conflict resolutions per landing" "| three fix-ups; $pin_conflict_resolutions_per_landing |"
row='^[|] [*][*]Epic[*][*] [|]'
line_has "$row" "epic row: the epic orchestrator" '| epic orchestrator |'
line_has "$row" "epic row: story orchestrators over the frontier" '| story orchestrators in parallel over the frontier |'
line_has "$row" "epic row: the check command as the forge runs it" "$pin_cell_check_command as the forge runs it |"
row_phrase implement-spec-pins "epic review spec axis" && line_has "$row" "epic row: the Jira Epic's spec" "| $row_text |"
line_has "$row" "epic row: no standards axis" '| none, the axis is skipped |'
row_phrase implement-spec-pins "epic review model" && line_has "$row" "epic row: the spec axis only at the review model of the epic's max tier" "| the spec axis only, at $row_text |"
line_has "$row" "epic row: findings filed as tasks, the story re-run in add mode" '| findings filed as `ready-for-agent` tasks under the story, that story re-run in add mode |'
line_has "$row" "epic row: the PR marked ready, the human merges" 'the PR marked ready, the human merges'
row_phrase implement-spec-pins "fix-up budget" && line_has "$row" "epic row: three per story" "| $row_text |" && epic_row_budget=$row_text
for r in Task Story Epic; do
  line_has "^[|] [*][*]$r[*][*] [|]" "$r row: the check command" "$pin_cell_check_command"
  line_has "^[|] [*][*]$r[*][*] [|]" "$r row: the one exit" '| the checks green on the tip the review called clean |'
done
# the two scoping rules: what a review reads at a row, and which trees a row checks
hasc "review scoping rule" "$head_review_scope"
para_has "$head_review_scope" "the spec axis takes the row's own unit" "The spec axis takes the row's own unit"
para_has "$head_review_scope" "the standards axis reads what entered since" 'The standards axis reviews what entered since the last standards review'
para_has "$head_review_scope" "the review scope's why is ADR 0014" 'ADR 0014 in the plugin repo'
para_has "$head_review_scope" "the story row's standards axis takes the gate's fix-up commits" "the story gate's own fix-up commits"
hasc "check scoping rule" "$head_check_scope"
para_has "$head_check_scope" "every tree is checked once" "$pin_every_tree_checked_once"
# only a green record lets a later agent skip the run; a red one is checked again, so a flaky or
# environmental red never sticks to its tree (dev-6qi)
para_has "$head_check_scope" "a tree with a green check record counts as checked" 'a tree with a green check record (`exit=0`) counts as checked'
para_has "$head_check_scope" "a red check record is checked again" 'A red record skips nothing'
lacks "a red check record counted as checked" 'a tree with a check record counts as checked'
para_has "$head_check_gate" "a pass skips the check only on a green record" 'unless its tree has a green record'
para_has "$head_check_record" "a red record's tree is checked again" 'one with a red record checks it again'
# a fix-up that commits nothing leaves its tree red-recorded, so the checks rerun on it rather
# than a flaky red's record spending the whole budget, and the fix-up still counts (dev-vnf)
para_has "$head_check_gate" "a fix-up that commits nothing reruns the checks" 'so the checks rerun on the unchanged tree'
para_has "$head_check_gate" "a fix-up that commits nothing still spends the budget" 'A fix-up that commits nothing still spends the budget'
para_has "$head_check_scope" "a fix-up that commits nothing has its tree checked again" 'after a red, a fix-up that commits nothing leaves it red-recorded'
para_has "$head_check_gate" "a fix-up that commits nothing after a blocking verdict is reviewed again" 'After a blocking verdict the unchanged tree keeps its green record'
lacks "a fix-up that commits nothing re-reading the red record" 'a fix-up that commits nothing re-reads the red record'
# a landing's conflict resolutions are capped per landing, apart from the fix-up budget, the
# fourth conflict failing the task (dev-6qi)
para_has "$head_landing_a_task" "a landing takes at most three conflict resolutions" "A landing takes at most three $pin_conflict_resolutions"
para_has "$head_landing_a_task" "the resolution cap is apart from the fix-up budget" 'apart from the fix-up budget'
para_has "$head_landing_a_task" "the fourth conflict fails the task" 'the fourth conflict ends the task `failed`'
# the landing is the story row's: the task orchestrator reports a reviewed branch and never
# touches the owner checkout, the story orchestrator merges it serially with no lock, checks a
# resolved tree, and a red there fails the landing with the retry entering at the gate (dev-b8d.1.4)
para_has "$head_landing_a_task" "the story row lands" "$pin_story_row_lands"
para_has "$head_landing_a_task" "the task orchestrator never touches the owner checkout" 'never touches the owner checkout'
para_has "$head_landing_a_task" "landings are serial with no lock" 'Landings are serial, one per report, so no lock is'
para_has "$head_landing_a_task" "the resolved tree is checked with the Check record call" 'checks the resolved tree'
para_has "$head_landing_a_task" "a red on a resolved tree fails the landing" "\`$pin_failed_red_after_conflict\`"
para_has "$head_landing_a_task" "the retry enters at the gate on the resolved branch" "$pin_retry_at_gate_on_resolved_branch"
para_has "$head_landing_a_task" "a landing closes the task" "$pin_landing_closes_task"
para_has "$head_landing_a_task" "the story gate's fix-ups land by the same procedure" "fix-up branches land by the same procedure"
para_has "$head_check_scope" "a changed tree is checked again" 'changes the tree, so it is checked again'
# the six trust rules, a closed list
hasc "trust rule 1: reviewer one tier up" '1. The reviewer runs one tier of model above the implementer'
hasc "trust rule 2: a fresh fix-up, never a message back" "2. A fix-up is a fresh implementer in the unit's worktree, never a message back"
hasc "trust rule 3: an implementer's own check runs never count" "3. An implementer's own check runs never count"
hasc "trust rule 4: the stray-commit check before every merge and push" '4. The stray-commit check runs before every merge and every push'
hasc "trust rule 5: only ready-for-agent tasks are claimed" '5. Only `ready-for-agent` tasks are claimed'
hasc "trust rule 6: the typed command authorises delivery" '6. The typed command authorises delivery'
hasc "the trust rules are a closed list" 'The list is closed: a rule that wants to join needs an ADR'
# one check command, make check, every owner repo having the target and a story run failing in
# a repo without it (ADR 0015); the check record keyed by tree SHA, written only by an
# orchestrator, the delivered tip's record the PR's Evidence
hasc "Check command rule" "$head_check_command"
para_has "$head_check_command" "make check is the one check command" 'One command per owner repo, `make check`'
row_phrase repo-plumbing-pins "the check command is make check" && row_text=${row_text#*since } && para_has "$head_check_command" "every owner repo has a check target" "${row_text%% target*}"
para_has "$head_check_command" "a story run with no check target fails" 'with `failed: no check target`'
hasc "Check record rule" "$head_check_record"
para_has "$head_check_record" "keyed by the tree SHA" 'keyed by the tree SHA'
para_has "$head_check_record" "only an orchestrator writes a record" 'Only an orchestrator writes a check record'
para_has "$head_check_record" "the delivered tip's record is the Evidence" "the record of the delivered tip's tree"
# the call that writes a record is stated once here, the brief and the story gate cite it
hasc "Check record states the compound call" 'mkdir -p <worktree path>/.tmp; mkdir -p <owner>/.tmp/checks/<tree>; export TMPDIR=<worktree path>/.tmp; make -C <worktree path> '"$rec_call"' 2>&1; echo "command=make check exit=$?" > <owner>/.tmp/checks/<tree>/record; cat <owner>/.tmp/checks/<tree>/record'
# the Delivery section, parametrised by the unit: the stray-commit check, the push, the PR body
# with the check record as Evidence, the forge-check wait with its six-call bound, the notes order
hase "Delivery section" '^## Delivery$'
sec_has "## Delivery" "Delivery is parametrised by the unit" 'parametrised by the unit it delivers: a **story**'
sec_has "## Delivery" "Delivery names the standalone task" 'or a **standalone task** (delivered by its own skill)'
sec_has "## Delivery" "Delivery's stray-commit check precedes the push" '1. **Stray-commit check**, before any push'
sec_has "## Delivery" "Delivery's stray-commit failed: line" 'failed: stray commit <sha> <subject>'
sec_has "## Delivery" "Delivery's push command" 'git -C <owner> push -u origin <branch>'
sec_has "## Delivery" "Delivery's refused push is a failed: line" 'failed: push <command>: <error>'
sec_has "## Delivery" "Delivery's push runs with the sandbox disabled, and only an error outside it is a refused push" 'The push runs with the sandbox disabled, as forge commands do; only an error outside the sandbox is a refused push'
sec_has "## Delivery" "Delivery's PR body is written by mattpocock-skills:pr" 'the Skill tool with `mattpocock-skills:pr` to write the body'
sec_has "## Delivery" "Delivery's PR body is written with a forge" '3. **PR body.** With a forge, call the Skill tool'
row_phrase implement-spec-pins "tea fallback evidence" && sec_has "## Delivery" "Delivery's Evidence is the delivered tip's check record" "its Evidence $row_text"
sec_has "## Delivery" "Delivery waits for the forge checks" '4. **Forge-check wait**, before the delivery is recorded'
sec_has "## Delivery" "Delivery watches the gh checks" "$pin_gh_checks_watch"
sec_has "## Delivery" "Delivery waits on the tea commit status" 'tea api --repo <owner> repos/{owner}/{repo}/commits/<tip SHA>/status | jq -e'
sec_has "## Delivery" "Delivery's gh wait waits for the pushed tip as the PR head" '--json headRefOid -q .headRefOid)" = <tip SHA> ]'
sec_has "## Delivery" "Delivery treats a failing forge read as an error, not a skip" 'is a forge error, never a skip'
sec_has "## Delivery" "Delivery reads the merge state on every forge PR, ahead of the workflows read" 'Read whether the PR can merge on every forge PR, ahead of the workflows read'
sec_has "## Delivery" "Delivery reads the gh merge state and head together" 'gh pr view <n> --repo <forge-slug> --json mergeable,headRefOid'
sec_has "## Delivery" "Delivery reads a gh conflict as CONFLICTING" 'a `mergeable` of `CONFLICTING`'
sec_has "## Delivery" "Delivery reads a tea conflict from git, not the forge's mergeable" 'git -C <owner> merge-tree --write-tree origin/<default branch> <branch>'
sec_has "## Delivery" "Delivery says why tea's mergeable is not read" "by Gitea's source tea's \`mergeable\` is also false for a WIP PR and while the forge is still checking"
sec_has "## Delivery" "Delivery notes a conflict so the unit is not finished" 'bd -C <owner> note <unit-id> "checks red: <tip SHA> merge conflict"'
sec_has "## Delivery" "Delivery treats an unreadable merge state as a forge error" 'A merge read that fails or returns no state is a forge error'
sec_has "## Delivery" "Delivery reads the merge state again before taking none reported" 'so read the merge state once more first, one read'
sec_has "## Delivery" "Delivery ends a conflicted PR on a failed: line" 'A PR git cannot merge ends the delivery on `failed: merge conflict <PR URL>`'
sec_has "## Delivery" "Delivery's conflicted PR records no delivery" 'with no `delivered:` or `pr:` note, so the unit stays open'
sec_has "## Delivery" "Delivery reads an unknown merge state again" 'A `gh` merge state of `UNKNOWN` is not yet known: it is read again, never read as a conflict'
sec_has "## Delivery" "Delivery tells a conflict from a repo with no checks" 'is a forge with no checks, for a repo whose workflows never run on PRs'
sec_has "## Delivery" "Delivery reads a head other than the tip like UNKNOWN" 'a head other than `<tip SHA>` (the push not yet seen) read like `UNKNOWN`'
sec_has "## Delivery" "Delivery fetches the default branch with the sandbox disabled on tea" 'git -C <owner> fetch origin <default branch>` (with the sandbox disabled, as the push is)'
sec_has "## Delivery" "Delivery verifies the default branch ref before merge-tree" 'git -C <owner> rev-parse --verify origin/<default branch>'
sec_has "## Delivery" "Delivery's conflict fix is the human's" 'resolve the conflict on the branch, and a rerun pushes it again and reads the merge state again'
sec_has "## Delivery" "Delivery's conflict does not spend the wait's timeout" 'the wait is not entered and its `timeout` is not spent'
sec_has "## Delivery" "Delivery bounds the forge-check wait" 'at most six calls in all'
sec_has "## Delivery" "Delivery says no workflows skips the checks" '`checks: skipped: no workflows`'
sec_has "## Delivery" "Delivery says no checks reported skips the checks" '`checks: skipped: none reported`'
sec_has "## Delivery" "Delivery says no forge skips the checks" "\`$pin_checks_skipped_no_forge\`"
sec_has "## Delivery" "Delivery's red forge check is a failed: line" 'one `failed: forge check <name> <run URL>` line per red check'
sec_has "## Delivery" "Delivery's red forge check leaves the unit unfinished" 'note <unit-id> "checks red: <tip SHA>"'
sec_has "## Delivery" "Delivery's red forge check records no delivery" 'no `delivered:` or `pr:` note is written;'
row_phrase implement-spec-pins "the delivered: note's shape" && sec_has "## Delivery" "Delivery records the delivered: note" "note <unit-id> \"$row_text\""
sec_has "## Delivery" "Delivery records delivered: ahead of pr:" 'The `delivered:` note goes ahead of the `pr:` note'
# the repo plumbing and Cut-off probe section, parametrised by the unit like Delivery: the check target probe, the
# forge decision, the Gitignore commit recipe and the merge guard, stated once; both skills cite it
# and the skill lints below pin only their own lines (dev-yykg)
hase "Repo plumbing and Cut-off probe section" "^$head_repo_plumbing\$"
# the phrases pinned one by one, in a table the regression test derives its drop cases from too
pins_from "$pins_dir/repo-plumbing-pins.tsv" "$head_repo_plumbing"
# the one gate semantics at every row (INFRA-33): the exit, the fix-up and its budget, the
# minors fix-up and the conflict resolution that rerun the checks and spend nothing, the
# reviewed tip as a sentence; the two-level loop with lint before the seams and the review
# marker exit is retired
hasc "Check gate rule" "$head_check_gate"
para_has "$head_check_gate" "one gate at every row" 'At every row the gate exits when the checks are green on the tip the review called clean'
para_has "$head_check_gate" "a red or blocking verdict goes to a fresh implementer" "$pin_red_or_blocking_to_fresh_fix_up"
para_has "$head_check_gate" "three fix-ups per unit" 'three such fix-ups per unit'
para_has "$head_check_gate" "the epic row budgets per story" "at the epic row, $epic_row_budget"
row_phrase implement-spec-pins "fix-up budget's fourth" && para_has "$head_check_gate" "a fourth failure is failed" "$row_text"
# the epic row's fourth-failure lines, the same two step 6 of /dev:implement-spec reports (dev-aeo)
row_phrase implement-spec-pins "red-check budget failure line" && para_has "$head_check_gate" "the epic row's red fourth-failure line" "\`$row_text\` after a red check"
row_phrase implement-spec-pins "blocking-verdict budget failure line" && para_has "$head_check_gate" "the epic row's blocking fourth-failure line" "\`$row_text\` after a blocking verdict"
epic_fourth_failure_lines
para_has "$head_check_gate" "a minors fix-up and a conflict resolution rerun the checks" 'A minors fix-up and a conflict resolution move the tip, so the checks rerun'
para_has "$head_check_gate" "and spend nothing" 'no budget is spent'
para_has "$head_check_gate" "the reviewed tip noted on the story" 'records the reviewed tip in its notes'
para_has "$head_check_gate" "the gate exits on the moved tip" 'the gate exits on the moved tip once its checks are green'
para_has "$head_check_gate" "the reviewed-tip note names the moved tip" 'the reviewed-tip note on the story bead'
para_has "$head_check_gate" "the task row writes no reviewed-tip note" 'the task row writes no such note'
# a low task's gate is its checks, every owner repo having a check command (ADR 0015)
para_has "$head_check_gate" "a low task is gated by the checks alone" 'A `low` task'"'"'s gate is the checks alone, with no review'
# the fix-up budget is bounded per invocation at every row (dev-gi1): a fresh orchestrator at any
# row starts its unit's budget at three whatever notes earlier invocations left, the epic
# orchestrator counts a story's spent budget from the notes after this invocation's epic review 1,
# an agent resumed with its context keeps its own count, and the epic row is no exception
para_has "$head_check_gate" "a fresh orchestrator starts its unit's budget at three" "starts its unit's budget at three whatever notes earlier invocations left"
para_has "$head_check_gate" "the fresh budget holds at any row" 'A fresh orchestrator at any row'
para_has "$head_check_gate" "a resumed agent keeps its own count" 'an agent resumed with its context keeps its own count'
para_has "$head_check_gate" "neither the task row nor the story row records spent fix-ups" 'neither the task row nor the story row records spent fix-ups'
para_has "$head_check_gate" "the epic orchestrator counts from the notes after this invocation's epic review 1" "counts a story's spent budget from the story's \`epic fix-up\` notes after this invocation's \`epic review 1\` note"
para_has "$head_check_gate" "the bound is per invocation, citing dev-l4j" 'bound a person wants is per invocation (dev-l4j)'
lacks "the epic row named as the budget's exception" 'The epic row is the exception'
para_has "$head_epic_row" "the epic row's checks are the forge's status on the PR tip" "the forge reports them green on the PR's tip"
# the epic row settles its own red check and minors (dev-bwh): a red check is filed like a
# blocking finding, a task under the story, and spends the budget; a clean verdict's minors
# take no last fix-up, which the epic orchestrator cannot run, and go to the inbox
para_has "$head_epic_row" "a red check at the epic row is filed like a blocking verdict" 'On a blocking verdict or a red check'
para_has "$head_epic_row" "the red check's task carries its check, command and log" 'carries its check, its command and its log pointer'
para_has "$head_epic_row" "a red check spends the epic row's budget" 'three such fix-ups per story per invocation, red or blocking alike'
para_has "$head_epic_row" "a pending check leaves the PR a draft" "$pin_pr_stays_a_draft and a later invocation reads it again"
para_has "$head_epic_row" "the epic row's minors take no last fix-up" 'minors take no last fix-up at this row'
para_has "$head_epic_row" "every epic review's minors go to the inbox, blocking or clean" "verdict, an epic review's minors take no last fix-up"
para_has "$head_epic_row" "the epic row's minors go to the inbox" "$pin_inbox_as_deferrals"
para_has "$head_epic_row" "the epic row's minors go to the inbox at once" "$pin_inbox_as_deferrals at once"
para_has "$head_review_verdict" "the Review verdict sends the epic row's minors to the inbox" 'always to the inbox (The epic row, above)'
lacks "the retired two-level check order" 'lint first, then the test seams'
# the seam-test blocking case, and the one review tool
para_has "$head_review_verdict" "no test at a story seam is blocking" 'no test at a story seam exercises the criteria'
# a standalone task's body may carry ## Test seams; without one the case does not apply (dev-b8d.1.6)
para_has "$head_review_verdict" "the no-seam-test case skips a standalone task without test seams" 'a standalone task whose body has no `## Test seams` names no seam, and the case does not apply to it'
hasc "the one review tool" "$pin_code_review_tool at every row"
# /dev:implement-task in one paragraph under the table, the table keeping three rows (dev-b8d.1.6)
para_has "$head_standalone_task" "the paragraph names /dev:implement-task" "$pin_implement_task_id"
para_has "$head_standalone_task" "the paragraph: the story row with a frontier of one" "$pin_story_row_frontier_of_one"
para_has "$head_standalone_task" "the paragraph: no story gate" "$pin_no_story_bead_or_gate"
para_has "$head_standalone_task" "the paragraph: the PR opened ready" 'a PR opened ready'
para_has "$head_standalone_task" "the paragraph: the close at delivery" 'closes the task at delivery'
para_has "$head_standalone_task" "the paragraph: the table keeps three rows" 'the table keeps its three rows'
# a rerun's merge guard applies to an open task only, as implement-task's step 1 says (INFRA-37)
para_has "$head_standalone_task" "the paragraph: the merge guard on a rerun is for an open task only, a closed task is reported from its notes" 'a rerun applies the merge guard on the `pr:` note only to an open task; a closed task with one is finished and reported from its notes'
lackse "a fourth row in the table" '^[|] [*][*](Standalone|Standalone task|Implement-task)[*][*] [|]'
fi
if doc 6 "harness rules" "$agents/harness.md"; then
# the mechanics live in the harness doc (dev-9k5.1.2): the rules above moved out of the
# orchestration doc with it, and the doc points back at the preflight that stays there
# a runner waits on its subagent's report, never on a Bash poll loop; pgrep is dead in the sandbox (chezmoi-flq)
hasc "waiting rule" "$head_waiting"
hasc "pgrep unusable in the sandbox" '`pgrep` cannot list processes in the sandbox'
# the lock wait's paths come from git rev-parse --git-path, since .git may be a file (dev-cjf)
lacks "a literal <owner>/.git/ path" "$pin_literal_owner_git_path"
# an Agent call returns at once in this harness, so an orchestrator ends its turn after spawning
# and the child's report arrives as the Agent tool's completion notification; run_in_background
# is a JSON boolean the probe found ignored or absent for a nested agent; every subagent below
# the epic orchestrator runs Bash in the foreground only, since a child that ends a turn with background
# work running counts as idle and its real report escapes to the top-level session (chezmoi-p4q)
hasc "an Agent call returns at once" 'An Agent call returns at once'
hasc "the completion notification carries the report" "the Agent tool's completion notification"
hasc "a nested orchestrator ends its turn after spawning" 'ends its turn'
hasc "run_in_background is a JSON boolean" '`run_in_background` is a JSON boolean'
hasc "idle rule" "$head_idle_rule"
hasc "Bash in the foreground only below the epic orchestrator" 'in the foreground only'
# the Bash tool backgrounds a call that outlives its 120 s default, which is the idle state the
# rule forbids, so lint and test runs pass timeout: 600000 (dev-7k0, INFRA-30)
hasc "the 120-second default backgrounds a longer call" "$pin_120_second_default"
hasc "lint and test runs carry the ten-minute timeout" "$pin_timeout_600000"
lacks "a foreground spawn" "$pin_retired_foreground_spawn"
# every worktree brief starts by exporting a gitignored repo-relative TMPDIR, since the macOS
# default is unwritable in the sandbox (mktemp -d, heredocs); the export is repeated per Bash
# call and mktemp -d takes a template, since macOS mktemp ignores TMPDIR (chezmoi-3eg)
hasc "TMPDIR rule" "$head_tmpdir"
# the rule's own paragraph (from its heading to the next blank line) carries the line, the two
# failures and the gitignore fact, so a word used elsewhere in the doc cannot stand in
para_has "$head_tmpdir" "TMPDIR line" "$tmpdir_export"
para_has "$head_tmpdir" "the heredoc failure" 'heredoc'
para_has "$head_tmpdir" "the directory is gitignored" '`.tmp/` is gitignored'
para_has "$head_tmpdir" "export repeated per Bash call" 'export TMPDIR=<worktree>/.tmp; <command>'
para_has "$head_tmpdir" "mktemp -d takes a template under .tmp" "$pin_mktemp_template"
# the export prefixes the calls that run mktemp, a heredoc or a script; a git call takes none and
# runs alone, each its own Bash call (dev-xvq5, INFRA-37)
para_has "$head_tmpdir" "the calls the export prefixes" 'every call that runs `mktemp`, a heredoc or a script'
para_has "$head_tmpdir" "git runs alone" 'git runs alone,'
para_has "$head_tmpdir" "a git call takes no export in front" 'each git call its own Bash call with no `export` in front'
# file edits in a worktree go through the Edit tool, not sed -f or a python heredoc (dev-xvq5)
para_has "$head_literal_paths" "file edits go through the Edit tool" 'the Edit tool, in place of `sed -f` or a python heredoc'
para_has "$head_idle_rule" "the Idle rule names the check command" 'every run of the check command'
# the story orchestrator's forge-check wait is the one long shell wait the rule allows (dev-xc2),
# the task orchestrator's lock wait gone with the lock (dev-b8d.1.4), which section 5 sweeps
para_has "$head_idle_rule" "the Idle rule names the forge-check wait as its one long shell wait" "The one long shell wait is the story orchestrator's"
para_has "$head_idle_rule" "the Idle rule cites the Delivery section for the forge-check wait" "forge-check wait (the rules doc's Delivery section)"
# (no step number cited for the wait: section 5's sweep covers docs/agents, dev-90up)
lacks "the Idle rule's second shell wait" 'two shell waits|The other is the story orchestrator'
lacks "the Idle rule's retired story's-checks clause" "these are the story's checks"
# the cut-off rule with its stop sweep, and the commits rule with its clean-tree check
hasc "cut-off rule" "$head_cut_off_agents"
para_has "$head_cut_off_agents" "the stop sweep" 'First the **stop sweep**'
hasc "commits rule" "$head_commits"
para_has "$head_commits" "the clean-tree check" '`git status --porcelain --untracked-files=no` prints nothing'
# a message with a trailer paragraph goes through a file the Write tool wrote, since the worktree
# guard refuses a $'...' -m as too complex to verify (dev-dzc, INFRA-35)
para_has "$head_commits" "the message file written with the Write tool" '`<worktree>/.tmp/commit-msg` with the Write tool'
para_has "$head_commits" "the commit -F form" '`git -C <worktree> commit -F <worktree>/.tmp/commit-msg`'
# Write refuses a file the session has not Read, so a commit-msg an earlier agent or a cut-off
# run left in the worktree is Read first (dev-cqf)
para_has "$head_commits" "a leftover message file Read before the Write" 'a leftover `<worktree>/.tmp/commit-msg` is Read first'
# the literal example message: its four trailer lines are pinned, and none may have a blank line
# before it, since they are one last paragraph (dev-i7u0)
hasc "commit example: the Bead trailer line" "$pin_trailer_bead"
hasc "commit example: the Refs trailer line" "$pin_trailer_refs"
hasc "commit example: the Co-Authored-By trailer line" "$pin_trailer_co_authored_by"
hasc "commit example: the Claude-Session trailer line" "$pin_trailer_claude_session"
lacksw "no blank line between the commit example's trailers" "  (${pin_trailer_refs%%:*}|${pin_trailer_co_authored_by%%:*}|${pin_trailer_claude_session%%:*}):"
# the shell-commands discipline and the pointer back at the preflight kept in the rules doc
hasc "the -C discipline" 'This section binds every session and subagent'
hasc "the preflight stays in the rules doc" 'The working-directory preflight stays in `orchestration.md`'
# a branch from a remote ref is created with --no-track, since the sandbox denies the
# .git/config write upstream tracking needs (dev-rlr)
hasc "branches from a remote ref rule" "$head_branch_from_remote_ref"
para_has "$head_branch_from_remote_ref" "the --no-track switch" '`git switch --no-track -c <branch> origin/<x>`'
para_has "$head_branch_from_remote_ref" "the sandbox denies the tracking write" 'denies the write to `.git/config`'
fi
if doc 6 "tracker rules" "$agents/issue-tracker.md"; then
# the "Has a database" rule: .beads/ exists and bd where names it (dev-e87)
para_has "$head_has_database" "the rule checks bd where" '`bd -C <repo> where` then prints `<repo>/.beads`'
para_has "$head_has_database" "a .beads where does not name is no database" 'counts as no database'
para_has "$head_has_database" "every gate cites the rule" 'applies this rule and cites it'
# every task passes the check gate; only the review is medium and high (ADR 0014, ADR 0015)
lacks "medium and high tasks passing the check gate" '`medium` and `high` tasks pass the check gate'
hasc "every task passes the check gate" 'every task passes the check gate'
hasc "the tracker doc reviews medium and high tasks" 'only `medium` and `high` tasks add the review'
# the task gate's review is two reviewers, one per axis, as /dev:task-orchestrator spawns them
sec_has "$head_start_work_on_a_task" "the task gate's review is two-axis" 'two reviewers, one per axis'
# the task's close is the story row's at landing, never the task row's (ADR 0016, dev-b8d.1
# story review 2)
sec_has "$head_start_work_on_a_task" "the story orchestrator closes the task at landing" 'the story orchestrator closes the task at landing'
# a routed triage item is a standalone task, the one type /dev:implement-task takes; the
# inbox bead stays a chore, a retro item and no task (dev-b8d.1 story review 1)
sec_has '## When a skill says "route a triaged item" (`/dev:triage`)' "the routed bead is a task" 'create "<title>" --type task -l complexity:<tier>,retro'
lacks "a routed bead of type chore" '--type chore -l complexity:'
# the one test of the session mode (ADR 0008), stated once, in the opening before any section
for need in '`<home>` is the session'"'"'s repo' '`<home>/repos.yaml`' '**workspace session**' '**repo session**' 'the only owner'; do
  opening_has "the tracker doc's one test" "$need"
done
hasc "epic gather section" "When a skill says $pin_cite_gather_epic_bead"
has "other-repo refusal" 'refused: epic bead lives in <repo>'
has "closed refusal" 'refused: epic bead is closed'
has "malformed epic refusal" "$pin_refused_not_a_story"
has "malformed-epic refusal named" '**malformed-epic refusal**'
has "re-cut creates a missing publish task" 'has no publish task'
lacks "Jira comment gated on every task" "When all of a run's tasks are published"
hasc "spec fetch section" 'When a skill says "fetch the spec"'
has "Spec: file fallback" 'The file a `Spec: <path>` line'
# the line's one canonical form, stated in the gather section and read by the fallback (chezmoi-dz4)
has "Spec: line canonical form" '`<path>` relative to the epic bead'"'"'s repo'
# who may write on the epic bead, stated once and cited by the three cut skills (chezmoi-f0f)
hasc "epic bead writes convention" '- Epic bead writes:'
# the close check counts a story's children the way the finished-story definition does: an
# untriaged child an earlier run left under the story holds back neither its PR nor its close
# (chezmoi-afn)
hasc "close rule tolerates untriaged children" "closed or $pin_carries_needs_triage"
# bd init runs from the repo's top level alone: from anywhere else, and through -C, BEADS_DIR,
# --db or --init-if-missing, it lands on an ancestor's database (gastownhall/beads#7985); an
# abort naming one never reinits, and every init is checked with bd where (dev-zyx)
hasc "init runs from the repo's top level" 'with the repo'"'"'s top level as the session'"'"'s current directory'
hasc "init never runs through -C, BEADS_DIR, --db or --init-if-missing" "$pin_never_through_c, \`BEADS_DIR\`, \`--db\` or \`--init-if-missing\`"
hasc "an init abort never reinits" 'never retry with `--reinit-local`, `--force` or `--destroy-token`'
hasc "init is checked with bd where" '`bd -C <repo> where` must print `<repo>/.beads`'
hasc "a failed init check names the init commit" 'the report names the init commit'"'"'s hash'
hasc "the story publish checks the user's init" '`bd -C <owner> where` prints `<owner>/.beads`'
hasc "a failed init in the story publish is a no" 'or `where` names another database), treat it as a no'
# the skip note keeps its exact text for its readers; only the report says why init failed
hasc "the report gives a failed init's reason" '`(bd init failed: <reason>, commit <hash>)`'

fi
# /setup-repo runs bd init itself by the tracker doc's rule, cited and not restated (dev-zyx)
if doc 6 "/setup-repo" "$skills/setup-repo/SKILL.md"; then
hasc "setup-repo runs init by the tracker doc's rule" 'which says where it runs from and when setup stops'
lacks "setup-repo restating the init rule" "$pin_never_through_c"
# the stop reports the init commit as init made it, before the pruning amends it
hasc "setup-repo stops before the pruning" 'A stop there comes before the pruning'
fi
# one has-a-database rule, stated once in the tracker doc and cited by every gate: .beads/ exists
# and bd where names it (dev-e87); section 5 sweeps a gate on the directory alone, and section 1
# checks /implement-spec, whose skill may be passed as $1. A gating skill with a section of its
# own fails there when missing, not here
section "6. database gates"
for g in spec-to-stories spec-to-tasks story-to-tasks close-epic retro; do
  f=$skills/$g/SKILL.md
  [ -f "$f" ] || continue
  hasc "/$g cites the tracker doc's \"Has a database\" rule" "$pin_cite_has_a_database_rule"
done
# /triage has no section of its own, so its document is this one's
if doc 6 "/triage" "$skills/triage/SKILL.md"; then
hasc "/triage cites the tracker doc's \"Has a database\" rule" "$pin_cite_has_a_database_rule"
hasc "/triage hands a standalone task to implement-task" "$pin_implement_task_id in the owner repo"
# the bead it routes is a task, and its body follows the issue template /dev:story-to-tasks
# holds, not the retired to-tickets one (dev-b8d.1 story review 1)
hasc "/triage creates a standalone task" 'a standalone task (`--type task`'
hasc "/triage writes the body in story-to-tasks' issue template" 'the issue template in `/dev:story-to-tasks`'
lacks "/triage citing the retired to-tickets template" 'to-tickets` issue template'
fi
# ADR 0014 records the one loop and supersedes ADR 0001, which keeps its text and points at it
if doc 6 "ADR 0014" "$docs/adr/0014-one-loop-at-three-rows.md"; then
line_hase "$anchor_adr_status_accepted" "ADR 0014 is accepted" "$anchor_adr_status_accepted"
hasc "ADR 0014 supersedes ADR 0001" 'Supersedes ADR 0001'
hasc "ADR 0014 has considered options" "$head_considered_options"
hasc "ADR 0014 option: the two-tool review" '**The two-tool review ADR 0001 chose**'
hasc "ADR 0014 option: a per-row check list" '**A per-row check list**'
hasc "ADR 0014 option: a merger kept as a role" '**A merger kept as a role**'
hasc "ADR 0014 decides the ticket orchestrator lands its ticket" 'The ticket orchestrator lands its ticket'
hasc "ADR 0014 decides every tree is checked once" "$pin_every_tree_checked_once"
# a red record checked again and the landing's resolution cap amend the ADR (dev-6qi)
hasc "ADR 0014 amended by dev-6qi" '> Amended by dev-6qi'
# ADR 0014 is superseded in part by ADR 0016, its status line intact; ADR 0016 records that the
# story row lands its tasks, why, the options considered, the rename and the budget's move
hasc "ADR 0014 superseded in part by ADR 0016" '> Superseded in part by ADR 0016'
fi
if doc 6 "ADR 0016" "$docs/adr/0016-the-story-row-lands-its-tasks.md"; then
line_hase "$anchor_adr_status_accepted" "ADR 0016 is accepted" "$anchor_adr_status_accepted"
hasc "ADR 0016 supersedes ADR 0014 in part" 'Supersedes in part ADR 0014'
hasc "ADR 0016 decides the story row lands its tasks" "**$pin_story_row_lands its tasks.**"
hasc "ADR 0016 has considered options" "$head_considered_options"
hasc "ADR 0016 option: the story row sends a red tree to a fix-up" '**The story row sending a red resolved tree to a fix-up itself**'
hasc "ADR 0016 option: a typed skill that is also the spawned one" '**A typed skill that is also the spawned one**'
hasc "ADR 0016 option: a chore skill" '**A chore skill**'
hasc "ADR 0016 moves the resolution budget to the story row" "$pin_conflict_resolutions_per_landing"
hasc "ADR 0016 rejects the red-tree fix-up for the task-row gate it would run" 'run a task-row gate'
hasc "ADR 0016 rejects the typed-and-spawned skill for its two modes" 'two modes in one skill'
hasc "ADR 0016 rejects the chore skill for the branch it would deliver" 'would deliver `fix:` commits'
fi
if doc 6 "ADR 0001" "$docs/adr/0001-two-stage-review.md"; then
hasc "ADR 0001 is superseded by 0014" 'status: superseded by ADR 0014'
hasc "ADR 0001 points at ADR 0014" 'docs/adr/0014-one-loop-at-three-rows.md'
fi

# ---- 7. /story-to-tasks ----
if doc 7 "/story-to-tasks" "$skills/story-to-tasks/SKILL.md"; then
has "spec fetch pointer" 'Fetch the spec as the tracker doc'"'"'s "fetch the spec" says'
has "story cutter trigger" '**Called, draft role ("story cutter"'
has "publish trigger" 'opens `Publish this block`'
hasc "design field read" "$pin_design_field_read"
lacks "owner-repo notes file" "$pin_spec_notes_path"
has "one test pointer" "$pin_cite_one_test"
has "home name in the Parent line template" 'home <home name>'
has "epic bead writes pointer" "$pin_cite_epic_bead_writes"
# the pair is read per edge of the story DAG (ADR 0011): a dependent for each publish
# blocker, one bump per publish blocker, a dependency when it holds a publish task
has "pair read per edge" 'Dependency pair, per edge'
has "one bump per publish blocker" 'one bump per publish blocker'
has "brief carries a Dependency line per publish blocker" "$dep_line"
has "brief carries a Dependent line per dependent" 'one `Dependent:` line per dependent'
# the two refusals: two publish tasks in one story, and a finished story pointing at add mode
has "two publish tasks refusal" 'refused: block carries two publish tasks; one PR publishes one version'
has "finished-story refusal names add mode" "add mode ($cmd_spec_to_stories_key, or the epic bead id when the story has no key)"
has "finished story marked by add mode is re-cut" 'unless its notes carry a `recut:` line'
# a re-cut that gained a publish blocker adds a second bump and re-edges open tasks
has "re-cut adds a bump per new publish blocker" 'gained a publish blocker'
has "re-cut re-edges kept tasks onto the new bump" 'kept ones with `bd dep add <task id> <bump id>`'
has "re-cut matches a bump to its blocker by crate" 'a bump covers the blocker whose crate its title names'
has "publish task line shapes" 'a line names a publish task when it reads'
has "re-cut cites the tracker doc's per-edge rules" 'the tracker doc'"'"'s per-edge re-cut rules'
# a story changing what a plugin ships bumps its version first, so no task runs red on the
# version-bump rule before the bump lands (dev-b9t)
has "plugin version bump is the first task" 'the plugin version bump as its first task'
has "every other task blocked on the plugin bump" 'every other task of the story blocked natively on that bump'
has "a re-cut keeps the plugin bump first" 'A re-cut keeps the plugin version bump first'

fi

# ---- 8. /implement-story: the deliver step pushes and opens the PR on the typed command's authority ----
if doc 8 "/implement-story" "$skills/implement-story/SKILL.md"; then
# an epic bead with a non-story child is malformed, and the refusal points nowhere (INFRA-37)
hasc "malformed epic refusal" "$pin_cite_malformed_epic_refusal"
lacks "implement-story restating the malformed-epic refusal" "$pin_malformed_epic_refusal_line"
hasc "delivery rule pointer" "$cite_delivery_authority"
hasc "step 8 delivers as the Delivery section says with the story as its unit" "8. **Deliver**, as the rules doc's Delivery section says, with the story as its unit"
# a commit from outside the run (21f770c: a test whose throwaway init failed committed into the
# enclosing checkout) is refused before the push and before a merger's merge (dev-y1p)
hasc "the story orchestrator's landing runs the stray-commit check" 'the **stray-commit check** on what the merge brings in'
# the delivery records its tip and check record, which /dev:implement-spec's review set reads (dev-47z)
hasc "finished story backfills a missing delivered: note" 'a finished story with no `delivered:` line'
lacks "profile-gated push" "$pin_profile_gated_push|ask the user to run that exact command|give the user that exact command"
lacks "a gitignore hand-off from the story cut" 'the story cut appended|story cut could not commit'
# the Gitignore commit recipe is the rules doc's Repo plumbing and Cut-off probe (section 6 pins it, dev-yykg); the
# step cites it and repeats none of it, its trailers included (dev-ieiv)
hasc "step 3 cites the rules doc's Repo plumbing and Cut-off probe" "$plumbing_cite"
lacksf_row "a second copy of the Gitignore commit's user-edit failure" repo-plumbing-pins "a user edit in .gitignore is a failed: line, not absorbed"
# the commit carries trailers, so it goes through a message file, never --trailer (dev-7gu)
lacks "a --trailer commit" 'commit [^`]*--trailer'
hasc "exploration subagent reads the design field" "$pin_design_field_read"
hasc "exploration subagent owns the notes directory" "\`<owner>/$pin_notes_dir_name/<epic-id>/\`"
# a failed task orchestrator's task is unclaimed at once, a second failure leaves the resume pointer on
# it, and the resume section says when a human runs the unclaim instead (chezmoi-jvc)
hasc "a failed task orchestrator's task is unclaimed" 'first `bd -C <owner> unclaim <id>`'
hasc "second failure notes the resume pointer" 'failed twice: <reason>; resume:'
hasc "hand unclaim condition in the resume section" 'by hand only when'
# the frontier keeps only ready-for-agent tasks, a deferred review finding is captured in the
# inbox through the retro capture and never as a story child, and a story counts as finished
# with an untriaged child under it (chezmoi-wgi); the Frontier rule itself is checked in 6
hasc "frontier keeps ready-for-agent tasks only" 'keeping only the tasks labelled `ready-for-agent`'
lacks "frontier minus ready-for-human alone" "minus \`ready-for-human\` tasks|$pin_not_ready_for_human_alone"
hasc "deferred findings go through the retro capture" '"capture a retro item"'
hasc "finished story tolerates untriaged children" "$pin_needs_triage_wontfix"
# step 9's worktrees live where git says, not under <owner>/.git/, which is a file in a linked
# worktree, a submodule or the stories fixture (dev-cjf)
hasc "step 9 finds the worktrees directory through git" '`git -C <owner> rev-parse --path-format=absolute --git-common-dir`'
lacks "a literal <owner>/.git/ path" "$pin_literal_owner_git_path"
lacks "a lock wait sleeping and re-checking the lock by hand" 'waits [0-9]+ seconds|checks again|re-?checks the lock|checks every [0-9]+ seconds'
# the story orchestrator ends its turn after spawning and is resumed by the completion
# notification (chezmoi-p4q); the rule itself is checked in 6
hasc "frontier spawn ends the turn" 'then end your turn: each task orchestrator'
hasc "the skill names the harness doc's Idle rule" "the $cite_harness_idle_rule"
# the story row lands each reviewed task branch itself (dev-b8d.1.4): in the turn the reviewed:
# report resumes it, serially and with no lock; the stray-commit check, then the merge; a conflict
# to an implementer in the task's worktree, the resolved tree checked with the rules doc's call,
# then a fast-forward; three resolutions per landing, the fourth failed with the merge aborted; a
# red on a resolved tree a failed landing whose one retry enters at the gate; a landing closes
# the task; the story gate's fix-ups land by the same procedure (section 5 sweeps the lock wait)
hase "the Landing section" '^## Landing$'
line_has '^   - `<id> reviewed: <task branch> <worktree path> <tip SHA>`' "a reviewed: report is landed in the turn it resumes" 'land it now, in the turn this report resumes you'
sec_has "## Landing" "landings are serial" 'Landings are **serial**: one runs at a time, one per report'
sec_has "## Landing" "a landing waits on no lock" 'So there is no lock to wait on'
sec_has "## Landing" "the landing confirms the reviewed tip" 'confirm `git -C <owner> rev-parse <task branch>` prints `<tip SHA>`'
sec_has "## Landing" "the landing merges the task branch" '`git -C <owner> merge <task branch>`'
sec_has "## Landing" "a conflicted merge is aborted, never resolved by the orchestrator" '`git -C <owner> merge --abort`'
sec_has "## Landing" "a conflict goes to an implementer in the task's worktree" "A conflict goes to an implementer in the task's worktree"
sec_has "## Landing" "the conflict implementer merges the integration tip into the task branch" "it is briefed to merge \`<branch>\`'s tip into the task branch"
sec_has "## Landing" "the resolved tree is checked with the rules doc's call" "run the rules doc's Check record call with the task's worktree as its \`<worktree path>\`"
sec_has "## Landing" "no reviewer runs on the resolution" 'No reviewer runs: the story row'"'"'s standards axis sees the resolution'
sec_has "## Landing" "the landing then fast-forwards" "\`$pin_ff_only_merge\`"
sec_has "## Landing" "a red on a resolved tree fails the landing" "\`<task-id> $pin_failed_red_after_conflict\`"
sec_has "## Landing" "the retry enters at the gate on the resolved branch" "its one retry is a fresh task orchestrator $pin_retry_at_gate_on_resolved_branch"
sec_has "## Landing" "the story orchestrator never gates a task" 'so you never gate a task yourself'
sec_has "## Landing" "a landing takes at most three conflict resolutions" "A landing takes at most **three $pin_conflict_resolutions**"
sec_has "## Landing" "the fourth conflict fails the task" '`<task-id> failed: conflict <task branch> after three resolutions`'
sec_has "## Landing" "a landing closes the task" "$pin_landing_closes_task: \`$pin_bd_close <task-id>\`"
# a resolution always moves the task branch past the reviewed tip, so the fast-forward guards the
# resolved tip, the tree just checked, never the reviewed one; a story fix-up reports no tip SHA,
# so its tip is read from its worktree (dev-b8d.1.4 review 1)
sec_has "## Landing" "the fast-forward guards the resolved tip" "confirm \`git -C <owner> rev-parse <task branch>\` prints the resolved tip, $pin_rev_parse_head"
sec_has "## Landing" "a story fix-up's tip is read from its worktree" "its \`<tip SHA>\` is $pin_rev_parse_head"
lacksf "the reviewed-tip guard repeated after a conflict resolution" "repeat 1's guards"
K='^3\. A conflict goes to an implementer'
line_has "$K" "the conflict implementer's brief starts with the TMPDIR line" "$tmpdir_line"
line_has "$K" "the conflict implementer's brief carries the plain-command line" "$plain_command"
line_hase "$K" "the conflict implementer's brief puts the TMPDIR line ahead of the plain-command line" "$tmpdir_then_plain"
line_has "$K" "the conflict implementer's check and test timeout" "$pin_timeout_600000"
line_has "$anchor_first_failure_report" "a first failure after a red on a resolved tree retries at the gate" 'that one enters at the gate on the resolved branch'
# any other first failure probes for the commits its attempt left, as implement-task's retry does (dev-a3c0)
line_has "$anchor_first_failure_report" "a first failure's retry runs the Cut-off probe" "step 4's Cut-off probe deciding its entry"
lacks "a closed report from the task orchestrator" '`<id> closed`'
# the short brief (dev-b8d.1.4): the task orchestrator runs /dev:task-orchestrator, spawned at
# opus, and the brief carries only what the run alone knows, a gate entry adding the branch,
# worktree, tip and the red record's log
line_has "$anchor_story_step_4_frontier" "the frontier spawn is at opus" "$pin_spawn_at_opus"
# a cut-off task the rules doc's Cut-off probe hits, on either worktree route, is respawned
# at the gate on the branch, worktree and tip the probe found (dev-b8d.1.4 review 1, dev-ndfi)
line_has "$anchor_story_step_4_frontier" "step 4 probes a cut-off task through the rules doc's Cut-off probe" "$probe_cite"
lacksf "a second copy of the cut-off probe's old hand-rolled branch test" 'log --oneline <branch>..task/<task-slug>'
lacksf_row "a second copy of the cut-off probe's trailer query" repo-plumbing-pins "the cut-off probe matches the Bead trailer on the commits its branch adds"
sec_has "$head_task_orchestrator_brief" "the gate entry covers a probe hit on either route" "a cut-off task orchestrator's replacement for which step 4's Cut-off probe hits"
lacksf "the gate entry limited to the hand-rolled route" 'whose hand-rolled `task/<task-slug>` carries commits'
sec_has "$head_task_orchestrator_brief" "the brief calls the task-orchestrator skill" "$pin_call_task_orchestrator_skill"
sec_has "$head_task_orchestrator_brief" "the brief carries only what the run alone knows" 'It carries only what this run alone knows'
sec_has "$head_task_orchestrator_brief" "the brief carries the plugin root literally" 'plugin root `<plugin root>`, spelled out as the absolute path'
sec_has "$head_task_orchestrator_brief" "the brief carries a retry's reason" '`retry: <first failure'"'"'s reason>`'
sec_has "$head_task_orchestrator_brief" "the brief's gate entry" "$gate_entry"
sec_has "$head_task_orchestrator_brief" "the gate entry's red log" "$pin_red_log_line"
lacks "the pasted task orchestrator brief" 'A task orchestrator is a subagent, not a skill'
line_has '^7\. ' "story fix-up brief names the check and test limit" 'the ten-minute limit on check and test runs'
# every story-level fix-up after the first reuses the first's worktree and branch, the harness
# doc's fix-up route, where the skill had left it unstated whether up to three shared one slug,
# and reaches it with git -C on either route (dev-6da)
line_has '^7\. ' "a later story fix-up reuses the first's worktree and branch" "reuses the first's worktree and branch rather than taking a fresh one, on either route"
line_has "$anchor_git_follows_bullet" "an implementer in a worktree another reported runs git -C" 'into a worktree another reported (a later story-level fix-up, a conflict resolution) runs `git -C <worktree path> …` on either route'
line_has "$anchor_git_follows_bullet" "only the story orchestrator writes to the owner checkout" 'and you alone write there: a task orchestrator never touches it'
line_has '^7\. ' "a later story fix-up is spawned without isolation into that worktree" 'without `isolation`, into the worktree and branch the first fix-up reported'
# one story is one PR on `feat/<story-id>` (keyed or not); a finished story with an open agent
# task is guarded by one forge query; a story-closure wait says to merge and close; the
# sibling line carries the story id (chezmoi-9v4.1.5, ADR 0011)
hasc "integration branch is feat/<story-id> for keyed and keyless stories" 'named `feat/<story-id>`, keyed or not'
hasc "merge guard names the delivered story with an open agent task" 'a delivered story with an open `ready-for-agent` task'
hasc "merge guard covers a pr: line, a URL or the branch form" 'whose notes carry a `pr:` line'
hasc "merge guard's MERGED refusal says add mode" 'in add mode (or /dev:spec-to-stories'
hasc "merge guard's MERGED refusal closes the stray task" '; then close <task-id> (moved to the new story)'
hasc "step 3 defers to the forge decision of the merge guard" '(already decided in step 1 when the merge guard ran)'
# the guard's mechanism (the forge decision, the queries, the three outcomes, the local decision of a
# branch form) is the rules doc's Repo plumbing and Cut-off probe, pinned in section 6 (dev-yykg); the step cites it
# and keeps its trigger, its refusal lines and what it does when the state is unknown
hasc "merge guard cites the rules doc's Repo plumbing and Cut-off probe for its mechanism" "$merge_guard_cite"
hasc "merge guard: OPEN continues on the re-delivery path" 'the re-delivery path of steps 3 and 8'
row_phrase repo-plumbing-pins "the merge guard refuses a MERGED PR" && hasc "merge guard's MERGED refusal line" "$row_text with \`<story-id> $pin_refused_pr_already_merged;"
row_phrase repo-plumbing-pins "the merge guard refuses a PR closed unmerged" && hasc "merge guard's closed-unmerged refusal line" "$row_text with \`<story-id> $pin_refused_pr_closed_unmerged\`"
hasc "merge guard's add-mode hint covers an epic with no external ref" "(or $cmd_spec_to_stories_epic when the epic has no external ref)"
hasc "merge guard asks when the forge cannot tell" 'the forge cannot tell (no forge, or a branch-form `pr:` note)'
hasc "merge guard asks whether the PR or branch has merged" 'whether the PR, or for the branch form the branch, has merged into the default branch'
hasc "merge guard leaves the stray task until add mode carries its work over" 'until add mode has carried its work into a new story, so close it there then'
hasc "story-closure wait says to merge the PR and run /dev:close-story" 'merge its PR and run /dev:close-story <blocker-id>`'
hasc "a keyless story's branch is still feat/<story-id>" 'its branch is `feat/<story-id>`, as every story'"'"'s is (step 3)'
hasc "merge guard fires on a child that is not closed" 'while a child that is not closed (open, in_progress or blocked) is labelled `ready-for-agent`'
hasc "merge guard ends a spawned run with a failed: line" 'failed: <story-id> merge state unknown (<pr: value>): say whether it merged, then re-run'
hasc "merge guard finds the default branch as step 3 says" '`<default branch>` is found as step 3 says'
hasc "sibling line format carries the story id" '`<repo> <story-id> <url>`'
lacks "the sibling line as <repo> <url>" '`<repo> <url>`'
lacks "glossary's avoided term human task" "$pin_avoided_term_human_task"
# step 9 removes worktrees with the sandbox disabled up front (the sandbox denies deletes under
# .git/worktrees/ and no setting lifts that), never as a retry after the denial; it sweeps every
# worktree-agent-* and .worktrees/ worktree whose branch is merged into the integration branch,
# earlier runs' included, and reports a locked or unmerged one in the worktrees: line instead of
# forcing it (chezmoi-73d)
hasc "worktree removal runs sandbox-disabled up front" 'worktree prune` run with the sandbox disabled'
lacks "worktree removal retried sandbox-disabled only after the denial" 'retry that one command with the sandbox disabled'
hasc "the sweep covers harness and hand-rolled worktrees" 'whose branch is `worktree-agent-*` or whose path is under `<owner>/.worktrees/`'
hasc "the sweep is keyed on the branch being merged into the integration branch" 'merged into `<branch>`'
# the sweep keeps to entries whose resolved path lies inside the owner checkout's resolved top
# level: a linked-worktree owner's list shows every checkout's worktrees, and git prints both
# paths with symlinks followed (dev-114)
line_has '^9\. ' "step 9 sweeps only worktrees inside the owner checkout" 'lies inside `<top>`'
row_phrase repo-plumbing-pins "the cut-off probe compares an entry against the owner's top level" && row_text=${row_text#*what } && line_has '^9\. ' "step 9 resolves the owner's top level" "${row_text% prints}"
# an entry inside another listed worktree that itself lies inside <top> belongs to a linked
# worktree nested in the owner, and that worktree's own sweep is the one to remove it (dev-f61)
line_has '^9\. ' "step 9 skips worktrees of a checkout nested in the owner" 'inside another listed worktree'
# and spares that nested checkout itself: a .worktrees/ entry holding a listed worktree is
# another run's owner, whose remove would delete its children's unmerged work (dev-wcv)
line_has '^9\. ' "step 9 spares a nested owner that holds worktrees" 'holds another listed worktree'
hasc "report template names a nested owner in use" 'in use: holds <child path>'
# a nested owner that holds no listed worktree yet (before its run's first spawn) is still
# another run's checkout: under .worktrees/ only a hand-rolled task worktree, task/<slug>
# at .worktrees/<slug>, is swept, and any other entry is reported, not removed (dev-dzu)
line_has '^9\. ' "step 9 sweeps only a hand-rolled task worktree under .worktrees/" 'only a hand-rolled task worktree is swept'
line_has '^9\. ' "step 9 names a task worktree by its branch and path" '`refs/heads/task/<slug>` at `<top>/.worktrees/<slug>`'
line_has '^9\. ' "step 9 matches a task worktree's branch and path on one slug" 'the same `<slug>` in both'
line_has '^9\. ' "step 9 leaves a ticket/ worktree in place as not a task worktree" "reported as \`$pin_not_a_task_worktree\`, a \`ticket/<slug>\` worktree (the prefix before the rename) included"
hasc "report template names a .worktrees/ entry that is not a task worktree" "$pin_not_a_task_worktree"
lacks "a nested owner with no children swept by path alone" 'swept like any merged entry'
lacks "the sweep limited to this run's worktrees" 'every worktree the run made'
hasc "a locked or unmerged worktree is reported, not removed" 'reported with its path'
lacks "a locked or unmerged worktree forced" 'worktree remove[^`]* -(-force|f)'
hasc "report template shows the worktrees: line" 'worktrees: <absolute path>'
hasc "the worktrees: and stray: lines appear only with content" '`waiting:`, `worktrees:` and `stray:` lines appear only when they have content'
# step 9 names every untracked, non-ignored file left in the owner checkout on the report's
# stray: line and deletes none, so a file an agent wrote outside the scratch paths gets seen
# (dev-9ft, the .tmp-lint.sh left at the INFRA-33 run's repo root)
line_has '^9\. ' "step 9 lists the stray files" '`git -C <owner> status --porcelain --untracked-files=all`'
line_has '^9\. ' "step 9 lists them for a finished story too" "step 1's finished story included"
line_has '^9\. ' "step 9 deletes no stray file" 'none is deleted'
line_has '^9\. ' "the stray: line is absent with no stray file" 'there is no `stray:` line'
hasc "report template shows the stray: line" 'stray:   <path>'
lacks "step 9 deleting a stray file" 'git -C <owner> clean'
lacks "the resume: line printed only with content" '`resume:` lines appear only'
# the implementer, fix-up and conflict-resolving briefs start with the
# TMPDIR line, stated once in the Owner repo section with its two riders and named in the task
# orchestrator brief's steps 2, 3 and 4 (the landing) and the story review's fix-up (step 7); the
# Gitignore step counts the rule's four
# entries, /.tmp/ included (chezmoi-3eg)
hasc "TMPDIR line stated in the skill" "$tmpdir_export"
hasc "export repeated per Bash call" 'repeated at the head of every Bash call'
hasc "mktemp -d takes a template under .tmp" "$pin_mktemp_template"
line_has '^7\. ' "the story review's fix-up brief starts with the TMPDIR line" "$tmpdir_line"
# next to its TMPDIR line, every worktree brief carries the plain-command line inline: briefs that
# only cited the harness doc's Literal paths drew 14 guard refusals in INFRA-33's run (dev-ask);
# step 3 names it for both of its fix-up briefs
hasc "plain-command line stated in the skill" "$plain_command"
O="starts with the \\*\\*$tmpdir_line\\*\\*"
line_has "$O" "the Owner repo bullet states the plain-command line" "$plain_command"
line_hase "$O" "the Owner repo bullet puts the TMPDIR line ahead of the plain-command line" "$tmpdir_then_plain"
line_has '^7\. ' "the story review's fix-up brief carries the plain-command line" "$plain_command"
line_hase '^7\. ' "the story review's fix-up brief puts the TMPDIR line ahead of the plain-command line" "$tmpdir_then_plain"
# on the harness route the TMPDIR line is two steps: a bare pwd as the first Bash call, then the
# path it printed spelled literally in every later export, since agents left to fill in the path
# wrote $PWD and the guard refused it in INFRA-35's run (dev-r1p)
line_has "$O" "the Owner repo bullet states the bare pwd step" "$pwd_step"
line_has "$O" "the Owner repo bullet spells the path literally in later exports" "$spelled"
line_hase "$O" "the Owner repo bullet puts the bare pwd step ahead of the path spelled literally" "$tmpdir_pwd_spelled"
lacks "the retired fill-in-the-pwd-path wording" 'fills in the path `pwd` prints'
lacks "Gitignore step counts three entries" "the rule's three entries"
line_has '^7\. ' "the story review (step 7) points at the rules doc's Review verdict" "$verdict_cite"
lacks "the zero-findings bar" "$pin_retired_zero_findings_bar"
# the check target probe, its refusal and the once-per-run resolution are the rules doc's Story
# plumbing, pinned in section 6 (dev-yykg, dev-de4, dev-b3p, ADR 0015); scripts/test-check-target.sh
# runs the pinned query on scratch repos; step 3 cites it, and the
# run's check command still goes in every brief and gates step 7
C="^   $apply_probe"
line_has "$C" "step 3 applies the rules doc's Repo plumbing and Cut-off probe" "$apply_probe"
line_has "$C" "step 3 resolves the check command through the repo plumbing and Cut-off probe" "$pin_its_check_target, whose \`<check command>\`"
line_has "$C" "the run's check command goes in every brief" 'every task orchestrator brief carries and step 7 gates on'
line_has "$C" "the Gitignore commit is the rule's, in the repo plumbing and Cut-off probe" "$pin_gitignore_commit"
line_has "$C" "the forge decision is the repo plumbing and Cut-off probe's" "$pin_forge_decision"
plumbing_copies
lacks "the retired grep for the check target" "grep -q .\\^check:"
lacks "the retired lint-command resolution" 'resolve the owner repo.s \*\*lint command\*\*|`make lint` when `<owner>`.s makefile has a `lint` target'
lacksf "the retired lint placeholder" '`<lint>`'
# the story gate (step 7) is the rules doc's Check gate loop on the integration branch tip, the
# story row of its table (dev-9k5.1.9): it exits when the checks are green on the tip the review
# called clean; each pass reads the checks from the check records first (a recorded tree runs
# nothing, an unrecorded one is checked once in the clean owner checkout and recorded), then
# compares the reviewed tip the story keeps in its review: note; the review's spec axis is the
# story's body and its standards axis what entered since the task reviews; a red or a blocking
# verdict goes to a fresh fix-up and the loop starts over, three per story, the fourth failed; the
# minors fix-up reruns the checks and spends nothing; the story orchestrator lands its fix-up
# itself, no separate landing agent (section 5 sweeps the merger); "Running the checks" is gone. Step 8 leaves the PR a
# draft, its Evidence the delivered tip's check record; step 9 removes the records
G7='^7\. '
hase "step 7 is the story gate" '^7\. \*\*Story gate\.\*\*'
line_has "$G7" "the story gate names its row of the rules doc's table" "the story row of the rules doc's table"
line_has "$G7" "the story gate exits on green checks at the tip the review called clean" 'it exits when the checks are green on the tip the review called clean'
line_has "$G7" "the story gate runs the checks first in each pass" "$gate_first"
line_has "$G7" "the story gate reads the tree only of a clean owner checkout" 'confirm the owner checkout is clean, `git -C <owner> status --porcelain` prints nothing'
# the guard (dev-9k5.1.9 review 1): the owner checkout on <branch>, untracked files counted and
# why, the failed line naming the files, its exit classified as step 6 says
line_has "$G7" "the story gate confirms the owner checkout is on the integration branch" '`git -C <owner> branch --show-current` prints `<branch>`'
line_has "$G7" "the story gate's off-branch failed line" '`failed: <story-id> not on <branch>`'
line_has "$G7" "the story gate's clean-checkout guard says why untracked files count" 'untracked files count, since the check runs on the working tree while the record keys on the committed tree'
line_has "$G7" "the dirty-checkout failed line names the files" '`failed: <story-id> owner checkout dirty: <files>`, `<files>` the paths that status call printed, classified as step 6 says'
line_has "$G7" "the story gate keys the check on the tip's tree" '`git -C <owner> rev-parse <branch>^{tree}`'
line_has "$G7" "the story gate reads a green tree's check record and runs nothing" "$rec_green"
line_has "$G7" "the story gate checks a red-recorded tree again" "$rec_red"
line_lacks "$G7" "the story gate skipping the run on a red record" "$rec_any"
line_has "$G7" "the story gate checks a red's fix-up that commits nothing again" "$rec_fixup"
line_has "$G7" "the story gate exits on a green tip its review: note still names" 'a green on a tip the `review:` note still names exits'
# the check-record call is defined once, in the rules doc's Check record, and step 7
# names it with <owner> for the worktree path (dev-9k5.1.9 review 1)
line_has "$G7" "the story gate writes the check record with the rules doc's call" "the rules doc's Check record call with \`<owner>\` as its \`<worktree path>\`"
line_lacks "$G7" "a second copy of the check-record call" "$rec_call"
line_has "$G7" "the story keeps the reviewed tip in its notes" "The story keeps the reviewed tip in its notes: its \`review:\` note names the tip the gate exits on after a clean review, so a rerun reviews only a tip that has moved past it"
# the story review round is numbered on from the notes, not from 1 per run, and its note names
# the tip it read (dev-9k5.1.9 review 1)
hasc "step 1 reads the story review notes" '`review:` and `story review <round>` (step 7)'
line_has "$G7" "the story review round continues across runs" "\`<round>\` one more than the last \`story review\` note's round step 1 read (1 when there is none)"
line_has "$G7" "the story review note names the reviewed tip" '`bd -C <owner> note <story-id> "story review <round> <tip SHA>: <findings>; <verdict line>"`'
line_has "$G7" "a green tip the review called clean exits the gate" "$gate_same"
line_has "$G7" "the story review's spec axis is the story's body" "the spec axis is the story's body"
line_has "$G7" "the story review's standards axis is what entered since the task reviews" "the standards axis is what entered since the task reviews: the $pin_conflict_resolutions and the coherence across tasks"
# the standards axis gets its inputs: the base SHA, each merge's resolution and the fix-up
# commits since the last story review (dev-9k5.1.9 review 1)
line_has "$G7" "the story review names the base SHA" '`<base>`, `git -C <owner> merge-base <default branch> <branch>`'
line_has "$G7" "the standards axis gets each merge's resolution" '`git -C <owner> show --remerge-diff <merge>`'
line_has "$G7" "the standards axis gets the fix-up commits since the last story review" "\`git -C <owner> log --no-merges --grep='^Bead: <story-id>\$' <since>..<branch>\`"
line_has "$G7" "a red or a blocking verdict goes to a fresh fix-up and starts the loop over" "$pin_red_or_blocking_to_fresh_fix_up"
line_has "$G7" "the minors fix-up reruns the checks and spends no budget" 'the minors fix-up reruns the checks and spends no budget'
line_has "$G7" "the story fix-up fixes the note's in-scope minors" "the blocking findings and the minors in the story's scope"
line_has "$G7" "what a story fix-up leaves unfixed goes to the inbox" 'you capture each one left in the inbox'
line_has "$G7" "a failed story gate captures its unfixed minors" "Before any \`failed:\` line this step sends to step 9, a guard's or the fourth failure's, capture in the inbox every minor of this run's \`story review\` notes that no fix-up's report names as fixed"
line_has "$G7" "the story gate's budget is three fix-ups, red or blocking" 'The budget is three fix-ups per story, red or blocking alike'
line_has "$G7" "the story gate's fourth failure skips delivery" 'the fourth failure skips step 8 and goes to step 9'
line_has "$G7" "the story gate's stall line" '`failed: <check> <command>`'
line_has "$G7" "the story gate's stall line for a review" "(a review's as \`failed: review $pin_code_review_name\`)"
line_has "$G7" "the story gate lands its fix-up itself by the Landing procedure" "you land its branch by the same procedure as a task's, the Landing section below"
line_lacks "$G7" "the story gate's minors fix-up spending budget" "a minors-only review's included"
lacksf "the retired Running the checks paragraph" '**Running the checks.**'
# on the first step 7 line, the checks come before the reviewed-tip compare and the review
unchanged_file || awk -v g="$gate_first" -v m="$gate_same" -v r="$pin_code_review_name" \
  '/^7\. / { i = index($0, g); k = index($0, m); j = index($0, r); ok = (i && k && j && i < k && k < j); seen = 1; exit } END { exit !(seen && ok) }' "$f" \
  || bad "missing: the story gate (step 7) runs the checks before the reviewed-tip compare and the two-axis review"
line_has '^8\. ' "the deliver step leaves the PR a draft" "$pin_pr_stays_a_draft"
# step 3 runs the Delivery section's stray-commit check and cites the Delivery authority, never step 8
line_has "$anchor_step_3_draft_pr" "step 3 runs the Delivery section's stray-commit check" "first run the rules doc's Delivery section's **stray-commit check**"
line_has "$anchor_step_3_draft_pr" "step 3 pushes on the Delivery authority" "($cite_delivery_authority)"
line_lacks "$anchor_step_3_draft_pr" "step 3 pointing at step 8's stray-commit check" "step 8's **stray-commit check**"
line_has '^8\. ' "step 8 opens the draft itself" 'open the draft after the push if step 3 could not'
line_has '^8\. ' "step 8 appends the sibling line" 'append the sibling line (rebuilt as in step 3)'
line_has '^8\. ' "step 8 runs the sibling refresh" "only then run step 3's sibling refresh"
line_lacks '^8\. ' "a second copy of the forge-check wait in step 8" "$pin_gh_checks_watch"
line_lacks '^8\. ' "a second copy of the stray-commit check in step 8" '--no-merges --format='
row_sweep implement-spec-pins "mark ready with gh" && line_lacks '^8\. ' "the deliver step marking the PR ready" "$row_text"
row_sweep implement-spec-pins "mark ready with tea" && line_lacks '^8\. ' "the deliver step marking the PR ready with tea" "$row_text"
# step 1 does not count a story with a later checks red: note as finished, so a re-delivery's
# red check is not hidden by the earlier delivery's pr: note (dev-xc2 review 1)
line_has '^   The tasks are ' "a checks red: note unfinishes the story" 'with no `checks red:` line after it'
hasc "report template shows the checks: line" 'checks:  skipped: <no forge | no workflows | none reported>'
hasc "report template's failed: line names a red forge check" 'or forge check <name> <run URL>'
hasc "report template's failed: line names a merge conflict" 'or merge conflict <PR URL>'
hasc "step 8 leaves a conflicted story not finished" 'A red forge check or a PR git cannot merge leaves the story not finished'
line_has '^9\. ' "step 9 removes the check records" '`rm -rf <owner>/.tmp/checks`'
# a run that ends failed on a red keeps the red tree's log in place for the human, the
# failed: line's words unchanged, while every other run still removes the records (dev-15s)
line_has '^9\. ' "step 9 keeps the red check's log on a failed: check run" 'skips the removal and keeps the red check'"'"'s log in place'
line_lacks '^9\. ' "a rerun reading a red record as checked" 'reads the record as checked red'
line_has '^9\. ' "step 9 still removes the records on every other run" 'Every other run, a green delivery or one failed for any other reason, removes the records'
hasc "report template's failed: line names the check" 'or <check> <command>'
# the report marks the PR a draft and always carries the resume line (dev-9k5.1.9 review 1)
hasc "report template marks the PR a draft" 'PR:      <url> (draft)'
hasc "the resume: line always appears" 'the `resume:` line always appears'
lacks "the retired Evidence phrase" 'the command and its output'

fi

# ---- 16. /task-orchestrator: the task row as a skill, spawned only, to a reviewed branch ----
# what was /implement-story's task orchestrator brief (dev-b8d.1.4): typed bare it refuses in one
# line naming the two skills that spawn it; two entries selected by the brief; one report line,
# reviewed: with the branch, worktree and tip, needs split: or failed:; no write to the owner
# checkout and no close, the story orchestrator landing the branch and closing the task. The
# brief's pins below moved here with it, anchored on the skill's own step lines
if doc 16 "/task-orchestrator" "$skills/task-orchestrator/SKILL.md"; then
hasc "the spawned-only refusal names the two skills that spawn it" "\`/dev:task-orchestrator is spawned only, $pin_spawned_by; run one of those instead.\`"
hasc "typed bare it refuses with exactly one line" 'Typed bare, or called without that brief, refuse with exactly one line'
opening_has "the frontmatter says spawned only" "Spawned only, $pin_spawned_by"
hasc "the brief carries only what the story run alone knows" 'The brief carries only what the story run alone knows'
hasc "the rest is derived from the task bead" 'Everything else you derive from the task bead'
hasc "the gate entry's brief line" "$gate_entry"
hasc "the gate entry's red log line" "$pin_red_log_line"
# two entries, no modes: claim for a fresh task, the gate when the branch carries commits
hasc "the claim entry" 'the **claim entry**, for a fresh task'
hasc "the gate entry" 'the **gate entry**, when the branch already carries commits'
hasc "the entry is selected by the brief" 'selected by the brief and never by you'
hasc "the gate entry runs no step 2 on a fresh budget" "$pin_with_fresh_budget and no step 2"
# the one report line: reviewed:, needs split: or failed:
hasc "the reviewed: report line" '`<task-id> reviewed: <task branch> <worktree path> <tip SHA>`'
hasc "the needs split: report line" '`<task-id> needs split: <proposed cut>`'
hasc "the failed: report line" '`<task-id> failed: <reason>`'
hasc "exactly one report line" 'Report exactly one line'
lacks "a closed report line" '<task-id> closed'
# never the owner checkout, never the close
hasc "no write to the owner checkout" 'You never write to the owner checkout'
hasc "the story orchestrator lands and closes" 'The story orchestrator lands your branch there and closes the task; you never close it'
lacks "a write command on the owner checkout" 'git -C <owner> (merge|commit|switch|reset|checkout|push)'
lacks "the task closed by the task orchestrator" "$pin_bd_close"
# spawning ends the turn, Bash in the foreground only (chezmoi-p4q)
hasc "task orchestrator's spawn ends the turn" 'then end your turn: its report'
hasc "the skill names the harness doc's Idle rule" "The $cite_harness_idle_rule binds you too"
# the implementer and fix-up briefs give check and test runs an explicit ten-minute timeout
# (dev-7k0, INFRA-30)
for step in 2 3; do
  line_has "^$step\. " "the task orchestrator's step $step: check and test timeout" "$pin_timeout_600000"
done
# a fresh task orchestrator starts at round 1 whatever earlier attempts noted, the Check gate's
# fresh budget; a replaced implementer's no reset holds within one task orchestrator (dev-drw)
CUT='^A subagent that returns an API error'
line_has "$CUT" "a fresh task orchestrator starts at round 1" 'so you start at round 1'
line_has "$CUT" "the fresh start ignores earlier attempts' notes" 'whatever `checks <n>:` or `review <n>:` notes earlier attempts left'
line_has "$CUT" "the fresh start points at the rules doc's Check gate" "your task starts over from \`<branch>\`'s tip (the rules doc's Check gate)"
line_has "$CUT" "a replaced implementer's no reset holds within one task orchestrator" 'no reset within this task orchestrator'
# the per-task reviewer reads the standards the story review reads (dev-co6)
for need in '`CODING_STANDARDS.md` or `CONTRIBUTING.md`' '<plugin root>/docs/agents/coding-standards.md` spelled as the path this session resolved'; do
  line_has '^3\. ' "the task reviewer brief's standards source" "$need"
done
# the implementer and fix-up briefs start with the TMPDIR line, then the plain-command line
# (chezmoi-3eg, dev-ask); on the harness route the TMPDIR line is two steps (dev-r1p)
hasc "task orchestrator brief points at the harness doc's TMPDIR rule" "the harness doc's TMPDIR rule"
for step in 2 3; do
  line_has "^$step\\. " "task orchestrator step $step's brief starts with the TMPDIR line" "$tmpdir_line"
done
line_has '^2\. ' "task orchestrator step 2's brief carries the plain-command line" "$plain_command"
line_has '^3\. ' "task orchestrator step 3's brief carries the plain-command line" "$plain_command"
line_has "$anchor_task_orchestrator_header" "the task orchestrator header carries the plain-command line" "$plain_command"
line_has '^2\. ' "task orchestrator step 2's brief names the bare pwd step" "$pwd_step"
line_has '^2\. ' "task orchestrator step 2's brief spells the path literally in later exports" "$spelled"
# the order of each brief, the TMPDIR line then the plain-command line; step 3 holds two briefs
line_hase '^2\. ' "task orchestrator step 2's brief puts the TMPDIR line ahead of the plain-command line" "$tmpdir_then_plain"
line_hase '^3\. ' "task orchestrator step 3's two briefs each put the TMPDIR line ahead of the plain-command line" "$tmpdir_then_plain.*$tmpdir_then_plain"
line_hase "$anchor_task_orchestrator_header" "the task orchestrator header puts the TMPDIR line ahead of the plain-command line" "$tmpdir_then_plain"
line_hase '^2\. ' "task orchestrator step 2's brief puts the TMPDIR line, the bare pwd step and the spelled path in order" "$tmpdir_line.*$tmpdir_pwd_spelled"
# the reviewer brief carries the two tags and the verdict line, and step 3 points at the rules
# doc's Review verdict (chezmoi-49k)
for phrase in "$pin_verdict_clean" "$pin_verdict_blocking" "$pin_blocking_or_minor" 'within the budget above'; do
  line_has '^3\. ' "task orchestrator step 3's reviewer brief" "$phrase"
done
line_has '^3\. ' "task orchestrator step 3 points at the rules doc's Review verdict" "$verdict_cite"
lacks "the zero-findings bar" "$pin_retired_zero_findings_bar"
# the skill states its row of the rules doc's table, the run's check command from its brief, and
# cites the harness doc in one line (dev-9k5.1.7); its row reports a reviewed branch (dev-b8d.1.4)
H="$anchor_task_orchestrator_header"
hase "the row opens on the task orchestrator" "$H"
for pin in "your row is the task row of the rules doc's table|the skill names its row of the rules doc's table" \
  'you build with one implementer in a worktree|the row builds with one implementer in a worktree' \
  'check with the check command|the row checks with the check command' \
  "review the task's body as the spec axis and the task diff as the standards axis, one tier up, none at \`low\`, fix up|the row reviews the task body and diff one tier up, none at low" \
  'fix up by pointer brief in the same worktree|the row fixes up by pointer brief in the same worktree' \
  'report the reviewed branch for the story orchestrator to land|the row reports its reviewed branch for the story orchestrator to land' \
  'exit when the checks are green on the tip the review called clean|the row exits on green checks at the tip the review called clean' \
  'within three fix-ups|the row budgets three fix-ups'; do
  line_has "$H" "${pin#*|}" "${pin%%|*}"
done
line_lacks "$H" "the row's conflict resolutions" "$pin_conflict_resolutions"
line_has "$H" "the skill cites the harness doc in one line" 'The harness mechanics are in `<plugin root>/docs/agents/harness.md`'
line_has "$H" "every brief it sends cites the harness doc" 'every brief you send cites it in one line'
# the story orchestrator resolves the check command once per run and the brief carries it; the
# skill never resolves it itself (dev-yyu)
line_has "$H" "the row's check command is the brief's" 'check command `<check command>`'
line_has "$H" "the skill never resolves the check command itself" 'never resolve it yourself'
row_sweep repo-plumbing-pins "the check target is read from make's database" && line_lacks "$H" "the per-task check target lookup" "$row_text"
line_lacks "$H" "the per-task check command by Makefile convention" "Makefile has a \`check\` target"
# the check and review loop (step 3): checks ahead of the reviewers, each check one record call,
# a red noted, a red and a blocking verdict both to a fresh fix-up on one budget of three, a low
# task exiting on green (dev-cq0.1.4, dev-1xf.1.2)
G3='^3\. \*\*Check gate\*\*, every tier'
hase "task orchestrator step 3 opens with the check gate, every tier" "$G3"
line_has "$G3" "the loop step cites the rules doc's loop" "as the rules doc's Check gate says"
line_has "$G3" "a red starts the loop over from the checks" 'A red spawns a fresh implementer on the fix-up and the loop starts over from the checks'
line_has "$G3" "a blocking verdict starts the loop over from the checks, never straight to the reviewers" 'a blocking verdict spawns a fresh implementer on the fix-up and the loop starts over from the checks, never straight to the reviewers'
line_has "$G3" "a clean verdict exits the loop" '**Clean** exits the loop'
line_has "$G3" "the check gate runs before step 3's reviewer" "go to step 4; for \`medium\` and \`high\`, $pin_spawn_two_reviewers"
unchanged_file || ! grep -E "$G3" "$f" | sed 's/Green: .*//' | grep -qF -- "$pin_spawn_two_reviewers" || bad "present: task orchestrator step 3 spawns a reviewer ahead of the checks' green"
# one reviewer per axis, combined into one verdict line (dev-bzd)
line_has "$G3" "the task review spawns one reviewer per axis" "$pin_spawn_two_reviewers, one per axis"
line_has "$G3" "the two reviewers combine their reports into one verdict line" 'Combine the two reports into one verdict line'
line_lacks "$G3" "the reviewer told to spawn the skill's sub-agents" "the skill's two sub-agents spawned"
line_has "$G3" "a low task exits the loop on green checks" 'Green: a `low` task exits the loop, go to step 4'
line_has "$anchor_task_step_2_implementer" "task orchestrator step 2's implementer runs no gate and spawns no one" 'The implementer runs no gate and spawns no one'
# the check record keyed by the tree SHA, written only by the task orchestrator; only a green
# record skips the run (dev-9k5.1.7, dev-6qi, dev-vnf)
line_has "$G3" "the gate keys the check on the tree SHA" '`git -C <worktree path> rev-parse HEAD^{tree}`'
line_has "$G3" "the gate reads the tree only of a clean worktree" 'First confirm the worktree is clean, `git -C <worktree path> status --porcelain` prints nothing; a dirty worktree goes to a fresh implementer as a red does'
line_lacks "$G3" "the clean-worktree guard that hides untracked files" '`git -C <worktree path> status --porcelain --untracked-files=no`'
line_has "$G3" "a tree with a green check record is not checked again" "$rec_green"
line_has "$G3" "a tree with a red check record is checked again" "$rec_red"
line_lacks "$G3" "the gate skipping the run on a red record" "$rec_any"
line_has "$G3" "the task gate checks a red's fix-up that commits nothing again" "$rec_fixup"
line_has "$G3" "the gate cites the rules doc's check-record call" "the call the rules doc's Check record states"
line_lacks "$G3" "a second copy of the check-record call in the skill" "$rec_call"
line_has "$G3" "the gate names the rules doc's Check record as the writer's rule" "Only you write a record, never an implementer (the rules doc's Check record)"
line_has "$G3" "the gate reviews with mattpocock-skills:code-review" "$pin_code_review_tool"
line_has "$G3" "the reviewer brief names the harness-route diff" '`git -C <worktree path> diff <branch>...HEAD`'
line_lacks "$G3" "the per-round check log" 'checks-<round>-<k>.log'
line_has "$G3" "a red gate reads a forty-line tail of the log, never the whole output" 'tail -n 40 <log>'
line_has "$G3" "a red gate's note form (checks <round>: red <command>)" '`bd -C <owner> note <task-id> "checks <round>: red <command>"`'
line_has "$G3" "a green gate writes no note" 'a green writes no note'
line_has "$G3" "the gate's fix-up brief points at the log path" 'the log path, and no pasted output'
line_has "$G3" "red and blocking fix-ups share one budget of three, the fourth failure is failed" 'The budget is three fix-ups of either cause; the fourth red or blocking verdict is `failed`'
line_has "$G3" "the minors fix-up after a clean verdict spends no budget and advances no round" 'The minors fix-up spends no budget and advances no round'
line_has "$G3" "the blocking fix-up fixes the note's in-scope minors" "fixes the note's blocking findings and its minors in the task's scope"
line_has "$G3" "a minor unfixed when the task is reported reviewed or failed goes to the inbox" 'Every minor still unfixed when you report the task reviewed or failed goes to the inbox'
line_has "$G3" "a blocking round's out-of-scope minors go to the inbox" "the note's minors you judge out of the task's scope go to the inbox at once"
lacks "the retired run-the-gate-again wording" 'run the check gate again, and on green spawn a reviewer again'
# step 4 reports the reviewed branch and lands nothing: the landing is the story row's
R4='^4\. \*\*Report the reviewed branch\.\*\*'
hase "step 4 reports the reviewed branch" "$R4"
line_has "$R4" "step 4 lands nothing and closes nothing" 'You land nothing and close nothing'
line_has "$R4" "step 4 reads the reviewed tip" "$pin_rev_parse_head"
# a standalone task without ## Test seams names no seam, so the no-seam-test blocking case does
# not apply to it, and its implementer's tests go where tdd agrees them (dev-b8d.1.6)
line_has "$G3" "the no-seam-test case skips a standalone task without test seams" 'a standalone task whose body has no `## Test seams` names no seam, so this case does not apply'
line_has "$anchor_task_step_2_implementer" "a standalone task's implementer tests where tdd agrees them" "where \`tdd\` agrees them when it has none"
# the spec reviewer reads a standalone task's own ## Test seams, as the implementer's brief does
# (dev-b8d.1.6 review 2)
line_has "$G3" "the spec reviewer reads a standalone task's own test seams" "and the story's test seams, or a standalone task's own body's \`## Test seams\`, where those criteria must be exercised"
fi

# ---- 17. /implement-task: a standalone task delivered as a PR opened ready ----
# the story row with a frontier of one (dev-b8d.1.6): typed, it refuses a bead of another type, a
# story's task (naming /dev:implement-story <story-id>) and one not ready-for-agent; it reuses the
# story orchestrator's plumbing (the make probe and its refusal, the forge decision, the gitignore
# rule, task/<id> off the default branch with a branch: note), spawns one task orchestrator with
# the short brief, lands its reviewed branch by a fast-forward, and delivers by the rules doc's
# Delivery section: the PR opened ready, delivered: before pr:, then the close; with no forge the
# pushed branch and checks: skipped: no forge. A rerun applies the merge guard on the pr: note and
# re-enters at the gate on a failed run's commits with a fresh budget; the report ends on resume:.
if doc 17 "/implement-task" "$skills/implement-task/SKILL.md"; then
opening_has "the frontmatter names a standalone task" 'Implement one standalone task bead'
hasc "report template's failed: line names a merge conflict" 'or merge conflict <PR URL>'
# the three refusals, each one line that creates nothing
hasc "the non-task refusal" '`<id> is of type <type>, not a task; /dev:implement-task takes a standalone task bead id.`'
hasc "the story-task refusal names /dev:implement-story" "\`<id> refused: its parent <story-id> is a story; run $cmd_implement_story\`"
hasc "the not-ready refusal" '`<id> refused: not ready-for-agent'
# the story row with a frontier of one, no story bead and no story gate
hasc "the story row with a frontier of one" "$pin_story_row_frontier_of_one"
hasc "no story gate" "$pin_no_story_bead_or_gate"
# the plumbing: the same make probe and refusal, the forge decision, the gitignore rule, the branch
# the make probe, its refusal, the forge decision, the Gitignore commit and the merge guard's
# mechanism are the rules doc's Repo plumbing and Cut-off probe (section 6 pins them, dev-yykg); the skill cites
# it and repeats none of it
hasc "the repo plumbing and Cut-off probe cited for the check target" "$plumbing_cite"
hasc "the repo plumbing and Cut-off probe's Check target" "$pin_its_check_target"
hasc "the repo plumbing and Cut-off probe's Gitignore commit" "$pin_gitignore_commit"
hasc "the repo plumbing and Cut-off probe's Forge decision" "$pin_forge_decision"
plumbing_copies
hasc "the branch feat/<id> off the default branch" 'git -C <owner> switch -c feat/<task-id> <default branch>'
hasc "the branch: note" 'bd -C <owner> note <task-id> "branch: feat/<task-id>"'
# one task orchestrator, the short brief
hasc "one task orchestrator through the skill" "$pin_call_task_orchestrator_skill"
hasc "the task orchestrator at opus" "$pin_spawn_at_opus"
hasc "the brief's gate entry" "$gate_entry"
# the landing is a fast-forward after the stray-commit check, and a review: note marks it
hasc "the landing is a fast-forward" "$pin_ff_only_merge"
hasc "the landed tip is noted" 'bd -C <owner> note <task-id> "review: <tip SHA>"'
# delivery: the rules doc's Delivery section, the PR opened ready, the notes in order, the close
hasc "delivery by the rules doc's Delivery section" "as the rules doc's Delivery section says, with the standalone task as its unit"
hasc "the PR opened ready, not draft" 'opened **ready**, not draft'
lacks "a draft PR for a standalone task" 'gh pr create --draft|"WIP: '
hasc "delivered: precedes pr:" 'the `delivered:` and `pr:` notes in that order'
hasc "the task closes at delivery" "$pin_bd_close <task-id> --reason \"delivered: <pr: value>\""
hasc "no forge: the pushed branch is the deliverable" 'the pushed branch is the deliverable'
hasc "no forge: the skipped-checks line" "$pin_checks_skipped_no_forge"
# a rerun: the merge guard on the pr: note, and a gate re-entry on a failed run's commits
hasc "the merge guard" '**Merge guard.**'
hasc "the merge guard's merged refusal" "\`<task-id> $pin_refused_pr_already_merged"
hasc "the merge guard's closed-unmerged refusal" "\`<task-id> $pin_refused_pr_closed_unmerged\`"
hasc "the merge guard cites the rules doc's Repo plumbing and Cut-off probe for its mechanism" "$merge_guard_cite"
hasc "the merge guard's open PR delivers again" 'and deliver again (steps 2 to 5 once more, on it)'
hasc "the branch form's refusals name the pr: value" 'the `pr:` value stands in for `<url>` in the refusals'
# a finished task touches nothing: no worktree removed, no check record deleted (review 2)
hasc "a finished task runs only the stray scan" "run only step 6's stray scan"
hasc "a failed run re-enters at the gate" 'its next spawn is a gate entry'
hasc "the probe for a failed run's commits is the rules doc's Cut-off probe" "$probe_cite"
lacksf_row "a second copy of the cut-off probe's trailer query" repo-plumbing-pins "the cut-off probe matches the Bead trailer on the commits its branch adds"
hasc "the gate entry starts a fresh budget" "$pin_with_fresh_budget"
# the report: the story block minus the story lines, ending on resume:
hasc "the report's task line" 'task:    <task-id> <title>'
hasc "the report's resume line" 'resume:  /dev:implement-task <task-id>'
lacks "a story line in the report" '^ *story: '
lacks "a human: or waiting: line in the report" '^ *(human|waiting): '
fi

# ---- 9. /close-story: the task check counts children as the finished-story definition does ----
if doc 9 "/close-story" "$skills/close-story/SKILL.md"; then
# a child carrying needs-triage or wontfix is a note with nothing to implement, not a task
# to wait for; any other open child is named with its status and label, so the remedy is
# readable from the refusal line (chezmoi-afn)
hasc "task check skips untriaged children" "$pin_carries_needs_triage"
hasc "refusal names status and label" 'open tasks <child> <status> <label>'
lacks "refusal without the label" 'open tasks <child> <status>, \.\.\.'
# the Forgejo/Gitea query names the story's repo, as the intro promises for every forge
# command and as /implement-story's merge guard does; without --repo, a workspace session
# reads whichever repo the shell sits in (dev-hac)
hasc "Forgejo/Gitea query names the repo" 'tea api --repo <path> repos/{owner}/{repo}/pulls/<n>'
lacks "Forgejo/Gitea query without --repo" "$pin_tea_api_without_repo"

fi

# ---- 10. the story DAG in the tracker and orchestration docs (ADR 0011) ----
# a feature's stories form a DAG of text blockers, each naming a human gate task or a story;
# the one-text-blocker and no-chains rules are retired. Section 5 sweeps "only text blocker"
# and "chains are out of scope"; the wider chains wording is scoped to these two docs.
for d in "$agents/issue-tracker.md" "$agents/orchestration.md"; do
  doc 10 "story DAG" "$d" || continue
  has "story DAG" "$pin_story_dag"
  has "human gate task" 'human gate task'
  # read as one line, so a phrase wrapped across a line break is still caught; the match stops
  # at a period, so it spans a paragraph break only where a paragraph ends without one. Section
  # 5's "chains are out of scope" is blanked first, so a seed of it fails there alone
  unchanged_file || ! tr -s '[:space:]' ' ' < "$f" | tr '[:upper:]' '[:lower:]' | sed "s/$pin_chains_out_of_scope//g" \
    | grep -qE -- 'chains[^.]{0,120}out of scope' || bad "present: retired story-DAG wording in $f (chains[^.]{0,120}out of scope)"
done
# a story held only by a story-closure blocker ends the run as a human stop naming the merge
# and the /close-story; a publish task waits on its story's tasks, not its repo's
f=$agents/orchestration.md
if [ -f "$f" ]; then
section "10. story DAG: $f"
hasc "story-closure human stop" "$merge_then_close"
has "publish task ready on its story's tasks" "as soon as its story's implementation tasks close"
lacks "publish task ready on its repo's tasks" "its repo's implementation tasks close"
fi
# the story body shows only blocker lines a step fills; a middle story of a chain is ordered
f=$agents/issue-tracker.md
if [ -f "$f" ]; then
section "10. story DAG: $f"
lacks "gate task line no step fills" '<repo> <gate task id>'
# the story cut writes a story line or a publish placeholder (step 2's skipped form too), so
# "the only lines" of step 4 would contradict step 2
has "story cut writes no gate task id" 'never a line naming a gate task id'
lacks "story cut's lines contradict step 2" 'the only lines the story cut writes'
has "middle story of a chain" 'in the middle of a chain'
# a repo session may hold several home stories, each the epic bead's child, or the stories
# gather (bd children <epic-id>) misses one; the task cut is one topological pass, since a
# dependency wave is one batch of cutters per DAG level and never splits a story
has "every repo-session story under the epic" '# repo session: every story'
lacks "one home story with a parent" 'Only the home story has a parent'
has "task cut in one topological pass" "$pin_one_topological_pass"
# the pass is per story, not per edge: a dependent with two publish blockers gets every bump
# before its other tasks (steps 4 and 5)
has "task cut ordered per story" "$pin_one_topological_pass over the stories"
lacks "task cut ordered per edge" "$pin_one_topological_pass over the edges"
lacks "middle story split across waves" 'opens its own wave'
has "deploy split waits on the earlier story's closure" 'that `/dev:close-story` requires closed'
# a re-cut blocks every open task but the bumps on every bump, so no bump blocks on itself
# or on another bump and step 5 holds
has "re-cut exempts the bumps" 'every open task of the story that is not a bump'
lacks "re-cut blocks a bump on itself" 'every open task of the story is blocked'

fi

# ---- 11. namespace rule: only dev: and mattpocock-skills: ----
# our skills are dev:<skill>, mattpocock's are mattpocock-skills:<skill>. A bare /<skill> or a
# /<other>:<skill> in a skill doc, any doc under docs/, the runbook, the project CLAUDE.md or
# the root glossary fails, and so does a namespaced one naming no skill; a path (/tmp/x) and a
# built-in command do not count as skills. The implement-spec skill passed as $1 is scanned too, wherever it
# lives. In docs/specs/ only the existence check is skipped: a spec names the skills its
# stories have yet to build.
plugin=${PLUGIN_SKILLS:-$(ls -d "$HOME"/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/*/skills 2>/dev/null | sort -V | tail -1)}
# the plugin's skill names, listed once per run: a skill dir sits at the plugin's skills level,
# directly or under one category dir (engineering/tdd), and is not a subdirectory of another
# skill (tdd/scripts); listed when the first mattpocock-skills: token is checked
plugin_skills= plugin_listed=
list_plugin_skills() {
  plugin_listed=1
  [ -d "$plugin" ] || return 0
  # one listing: the SKILL.md files that make a dir a skill ("S"), then the candidate dirs ("D")
  plugin_skills=$({ find "$plugin" -maxdepth 2 -name SKILL.md | sed 's/^/S /'
    find "$plugin" -mindepth 1 -maxdepth 2 -type d | sed 's/^/D /'; } 2>/dev/null | awk '
    { path = substr($0, 3) }
    /^S / { sub(/\/SKILL\.md$/, "", path); skill[path] = 1; next }
    { parent = path; sub(/\/[^\/]*$/, "", parent); if (!(parent in skill)) { sub(/.*\//, "", path); print path } }' | sort -u)
}
builtin=" model add-dir code-review plugin sandbox clear mcp help config tmp compact init permissions hooks resume agents bug context cost doctor exit login logout memory pr-comments review status statusline terminal-setup vim ide install-github-app release-notes rewind export usage theme output-style loop schedule security-review simplify run fewer-permission-prompts keybindings-help update-config claude-api "

# the /command tokens of files $@, one "<file><tab><token>" line per distinct pair, in one awk
# run rather than one per file. A slash starts a command only at the start of a
# line or after whitespace, an opening delimiter or an opening backtick (so not a/b, ~/x, a URL,
# a closing tag, <home>/x, $(pwd)/x or a closing `x`/y). The name is [a-z-]+ with an optional
# :skill; what follows it tells a command from a path (/tmp/x, /x.sh) or a placeholder
# (/dev:<x>): a command ends at a space, the end of line or punctuation, and a ":" or "." that
# ends a sentence still counts, so adjacent commands and "/skill." or "/skill: x" are checked.
cmd_tokens() { # <file>...
  local out
  # LC_ALL=C: a multibyte char (arrow, em dash) next to a slash must not abort awk; an extractor
  # failure is the caller's to report, never swallowed by the sort
  out=$(LC_ALL=C awk -v q="'" '{
    if (!index($0, "/")) next
    line = $0; inc = 0; i = 0
    # visit the slashes and backticks in order rather than every character: the regression
    # test runs this over every doc over a thousand times
    while (1) {
      s = index(substr(line, i + 1), "/"); b = index(substr(line, i + 1), "`")
      if (!s && !b) break
      if (!s || (b && b < s)) { i += b; inc = !inc; continue }
      i += s
      p = (i > 1) ? substr(line, i - 1, 1) : ""
      ok = (p == "" || p ~ /[ \t(\[{|,;"*_=]/ || p == q || (p == "`" && inc))
      # a ">" opens a command only when it is not the end of a <placeholder>: <home>/x is a path
      if (p == ">" && substr(line, 1, i - 1) !~ /<[^ \t<>]*>$/) ok = 1
      if (!ok) continue
      rest = substr(line, i + 1)
      if (!match(rest, /^[a-z][a-z-]*(:[a-z-]+)?/)) continue
      tok = substr(rest, 1, RLENGTH); c = substr(rest, RLENGTH + 1, 1); d = substr(rest, RLENGTH + 2, 1)
      if (c ~ /[\/_A-Z0-9<]/) continue
      if (c == ":" && (tok == "dev" || tok == "mattpocock-skills")) continue   # a namespace alone
      if (c == "." && d ~ /[A-Za-z0-9_]/) continue
      if (c == ":" && d != "" && d !~ /[ \t,;.)`]/) continue
      sub(/-+$/, "", tok)
      print FILENAME "\t" tok
    }
  }' "$@") || return 1
  [ -z "$out" ] || printf '%s\n' "$out" | sort -u
}
# every namespaced /command token in $@ maps to a skill directory: dev: ones under the
# skills dir, mattpocock-skills: ones under the plugin skills dir. Bare and unknown-namespace
# tokens are the loop's below, which calls this for every doc it scans.
# A dev: name passes only when its skill dir exists, so a dropped, renamed or typo'd skill fails.
cmds() { # <token>...
  local tok name
  for tok in "$@"; do
    name=${tok##*:}
    case "$tok" in
      dev:*) [ -d "$skills/$name" ] || bad "/$tok names no skill" ;;
      mattpocock-skills:*)
        if [ ! -d "$plugin" ]; then
          bad "/$tok cannot be resolved: plugin skills dir not found (${plugin:-unset}; install mattpocock-skills or set PLUGIN_SKILLS)"
        else
          [ -n "$plugin_listed" ] || list_plugin_skills
          case $'\n'"$plugin_skills"$'\n' in
            *$'\n'"$name"$'\n'*) ;;
            *) bad "/$tok names no skill" ;;
          esac
        fi ;;
    esac
  done
}
section "11. namespace rule"
# a token's verdict reads its file and the layout of the skills and plugin dirs; with
# LINT_UNCHANGED listing both dirs, a file it lists is skipped, as the queued checks skip it
scanned=() trees_unchanged=1
for given in "$skills" "$plugin"; do
  case $unchanged in *$'\n'"$given/"$'\n'*) ;; *) trees_unchanged= ;; esac
done
while IFS= read -r f; do
  [ -f "$f" ] && scanned+=("$f")
done < <({ find "$docs" "$agents" "$skills" -type f -name '*.md' 2>/dev/null
  echo "$runbook"; echo "$user_claude_md"; echo "$glossary_md"; echo "${1:-}"; } | grep . | sort -u \
  | if [ -n "$trees_unchanged" ]; then drop_unchanged; else cat; fi)
pairs=
[ "${#scanned[@]}" -eq 0 ] || pairs=$(cmd_tokens "${scanned[@]}") || bad "token extractor failed on ${scanned[*]}"
while IFS=$'\t' read -r f tok; do
  [ -n "$tok" ] || continue
  # specs and ADRs keep the words of their day, so no existence check runs on them
  case "$f" in "$docs/specs/"*|"$docs/adr/"*) ;; *) cmds "$tok" ;; esac
  case "$tok" in dev:*|mattpocock-skills:*) continue;; esac
  case "$builtin" in *" $tok "*) continue;; esac
  bad "bare or unknown skill namespace in $f: /$tok (use dev:<skill> or mattpocock-skills:<skill>)"
done <<<"$pairs"

# ---- 12. /retro: step 2 names the transcript shape and the two mining recipes ----
# the pins are fragments, so a recipe can be reworded without a lint edit
if doc 12 "/retro" "$skills/retro/SKILL.md"; then
hasc "one JSON object per line" 'one JSON object per line'
hasc "the timestamp field named" '`.timestamp`'
hasc "the tool call object" '`.type == "tool_use"`'
hasc "the tool result object" '`tool_result`'
hasc "calls live in message.content" '`.message.content[]`'
hasc "the schema-text trap" 'tool schemas'
hasc "the jq timeline recipe selects the call objects" 'select(.type=="tool_use")'
hasc "the jq timeline recipe stamps each call" '.timestamp as $t'
hasc "the grep tally recipe" 'sort | uniq -c'
hasc "the directory-wide timeout" "$pin_timeout_600000"
hasc "the 120-second default named" "$pin_120_second_default"
lacks "the bare grep instruction" 'grep the whole slug directory'
fi

# ---- 13. the brief rule: no plugin-root variable inside a brief block ----
# a brief spells the plugin root literally (the rules doc's Plugin root rule): Bash never has
# CLAUDE_PLUGIN_ROOT, in the main session or a subagent; the harness fills it in only in the
# skill text it loads, which a brief's subagent never sees, so a brief naming the variable sends
# it to a doc it cannot open. A brief block is a markdown quote: it opens on a line starting with
# `>`, indented or not (implement-spec's sits inside a list item), and runs to the next blank
# line, so a wrapped line that drops the `>` is still inside it. The variable outside one is the
# skill's own to resolve and passes.
section "13. brief rule"
# one awk over every skill doc, the quote state reset at each file's first line
brief_files=()
while IFS= read -r -d '' f; do
  unchanged_file || brief_files+=("$f")
done < <(find "$skills" -type f -name '*.md' -print0 2>/dev/null | sort -z)
[ "${#brief_files[@]}" -eq 0 ] || while IFS=$'\t' read -r f n line; do
  bad "plugin-root variable in a brief in $f:$n (spell the plugin root literally; the rules doc's Plugin root rule): $line"
done < <(awk -v name="$pin_plugin_root_variable" '
  FNR == 1 {inq=0} /^[[:space:]]*>/ {inq=1} /^[[:space:]]*$/ {inq=0}
  inq && index($0, name) {print FILENAME "\t" FNR "\t" $0}' "${brief_files[@]}")

# version-bump rule: a change to what the plugin ships (skills, docs, hooks and the glossary,
# less the specs under docs, which never reach an installed machine) needs a version change in
# the plugin manifest. The base is VERSION_BUMP_BASE (a CI job sets it to the PR base) or else
# the default branch's remote tracking ref, origin/HEAD or origin/main, so a detached HEAD
# derives it as a branch does; no local branch name picks the base. The diff runs from the
# merge-base of that base and HEAD to the working tree, untracked non-ignored files included, so
# a pre-commit run sees an uncommitted edit and an uncommitted bump alike; VERSION_BUMP_REPO
# overrides the repo (the regression test's throwaway repo). The manifest's parsed version value
# is compared at the merge-base and in the working tree: unreadable at either, or a reformat with
# the same value, is no bump. A no-op with a local main checked out (by name, the one place a
# branch name counts), and in a tree that is not a git repo.
bump_repo=${VERSION_BUMP_REPO:-$root}
shipping=(skills docs hooks GLOSSARY.md ':(exclude)docs/specs')
if git -C "$bump_repo" rev-parse --git-dir >/dev/null 2>&1 \
  && [ "$(git -C "$bump_repo" rev-parse --abbrev-ref HEAD 2>/dev/null)" != main ]; then
  section "14. version bump"
  base=${VERSION_BUMP_BASE:-$(git -C "$bump_repo" merge-base origin/HEAD HEAD 2>/dev/null \
    || git -C "$bump_repo" merge-base origin/main HEAD 2>/dev/null)}
  if [ -z "$base" ]; then
    bad "version bump: no diff base (neither origin/HEAD nor origin/main to merge-base with; set VERSION_BUMP_BASE)"
  elif ! git -C "$bump_repo" rev-parse --verify --quiet "$base^{commit}" >/dev/null; then
    bad "version bump: diff base '$base' does not resolve to a commit (a shallow checkout may not have fetched it)"
  elif ! fork=$(git -C "$bump_repo" merge-base "$base" HEAD 2>/dev/null); then
    bad "version bump: diff base '$base' shares no history with HEAD (a shallow checkout may have cut it)"
  elif [ -n "$(git -C "$bump_repo" diff --name-only "$fork" -- "${shipping[@]}"
               git -C "$bump_repo" ls-files --others --exclude-standard -- "${shipping[@]}")" ]; then
    manifest=.claude-plugin/plugin.json
    version_of() { # stdin: a manifest; prints its "version" value, empty if none
      sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1
    }
    old=$(git -C "$bump_repo" show "$fork:$manifest" 2>/dev/null | version_of)
    new=$(cat "$bump_repo/$manifest" 2>/dev/null | version_of)
    { [ -n "$old" ] && [ -n "$new" ] && [ "$old" != "$new" ]; } \
      || bad "version bump: a shipping path changed since ${fork:0:9} but $manifest has no version change"
  fi
fi

# ---- 15. mermaid blocks: no semicolon ----
# mermaid ends a sequenceDiagram statement at a ";", so a line of a ```mermaid block with one does
# not render (dev-1xf.1.4). The block opens on a fence line starting ```mermaid, indented or not,
# and closes on the next fence line; every .md under the docs dir, the skills and the agent docs,
# plus the project CLAUDE.md, the runbook and the root glossary, is read.
section "15. mermaid blocks: no semicolon"
mermaid_files=()
while IFS= read -r f; do
  [ -f "$f" ] && mermaid_files+=("$f")
done < <({ find "$agents" "$skills" "$docs" -type f -name '*.md' 2>/dev/null; echo "$user_claude_md"; echo "$runbook"; echo "$glossary_md"; } | sort -u | drop_unchanged)
# one awk pass over every file, a FAIL line per file with its first three hits under it
if [ "${#mermaid_files[@]}" -gt 0 ]; then
  hits=$(awk 'FNR == 1 { inm = 0; c = 0 }
    /^[[:space:]]*```mermaid/ { inm = 1; next } inm && /^[[:space:]]*```/ { inm = 0 }
    inm && index($0, ";") {
      if (++c == 1) printf "FAIL: present: a semicolon in a mermaid block in %s (mermaid ends the statement there)\n", FILENAME
      if (c <= 3) print FNR": "$0
    }' "${mermaid_files[@]}")
  [ -z "$hits" ] || { printf '%s\n' "$hits"; fail=1; }
fi

# ---- 18. cross-skill cites ----
# dev-q47w: the coding standards state how a rules doc or SKILL.md cites another skill's rule: a
# bold step name in bold, a heading in quotes, the skill named in backticks, never bare and never
# a name in backticks (dev-hcn9). A skill named in backticks and followed by a possessive and a
# bare capitalised heading ("`/dev:x`'s Two entries") is a heading cite in neither form, so it
# fails in every rules doc and SKILL.md but the coding standards, which show the wrong forms as
# examples, and a SKILL.md citing its own skill. The other wrong forms fail the same way
# (dev-mnz6): a step name in quotes, a heading in bold, either one bare before "of"/"in"
# `/dev:x`, and a bare name after the possessive and an optional "step"/"section" (the quoted and
# bold checks take either word too). The quoted and bold checks also fail a skill-first cite (the
# skill, an optional comma, colon, semicolon or dash, any of the, step and section, then the
# marked name: `/dev:x` "Step name", `/dev:x`: **Heading**), and a bare name straight after the
# skill fails the same way (dev-wh65). The skill is matched backticked or bare in all of these,
# with a stray backtick at one end or around the possessive too, so a bare skill beside a known
# name fails, and so does the right marking (a step in bold, a heading in quotes) beside a skill
# not in a whole pair of backticks (dev-hcn9). A name inside a pair of backticks fails in all
# three orders, with the skill backticked or bare, alone or with the bold or quotes inside the
# pair (**`Name`**) or around it (`**Name**`), with or without punctuation; a backtick that is
# part of the name (**`git` rule**) is no pair around it. Every check but the bare skill-first
# one matches the name in any case; that one matches its own case only.
# Limits, a closed list (the coding standards state the same one): the lint reads a skill beside a
# step or heading name its SKILL.md has, in three places only: after the skill's possessive and an
# optional step/section; straight after the skill, with an optional comma, colon or semicolon or a
# spaced hyphen or em dash, and any of the/step/section; and before of/in the skill, at most two
# words of letters between. The skill is backticked, bare, or has a backtick at one end only or
# around its possessive. The marks are straight double quotes, ** and backticks, around the name
# alone, with an optional period, comma, colon or semicolon after the name inside the marks, right
# after them or between two of them (a stray mark is read too, but only inside the backtick
# check). A name is the skill's own words (every regex character escaped, any characters but a
# bold marker). Names match in any case, except a bare name straight after a skill, which matches
# in its own case only ("/dev:x story gate" passes). It fails: a bare skill beside a name in the
# right mark; a name in the wrong mark (a step in quotes, a heading in bold) or a bare heading (in
# the of/in order a backtick right after the bare name, and a period, comma, colon or semicolon
# after that, leave it bare); a name inside a pair of backticks, alone or with bold or quotes
# inside or around the pair; and, as plain prose, a bare skill beside a name in any case ("the
# steps of `/dev:implement-spec`", "/dev:triage, Report the items", "/dev:task-orchestrator's
# report is one line"). A name that is both a step and a heading takes either mark and fails only
# bare, in backticks, or in either mark beside a bare skill. A capital word after a backticked possessive
# fails too ("`/dev:x`'s Jira key"), a known name or not. Every other typography is outside what
# the lint reads: curly quotes and apostrophes, en dashes and an unspaced em dash, a separator
# with no space, single quotes, italics, double backticks, a name in both bold and quotes, a skill
# set in bold or quotes, any other punctuation outside the marks, a one-sided mark (a bold or
# quote mark opening a name and never closed, or closing one never opened), a stray backtick
# beside a right mark, a backtick before the name only (straight after a skill or its possessive;
# elsewhere it leaves the name bare and fails), a space inside the backticks, a bold lead-in with
# no period that opens no numbered item (read as a label, not a step), a skill cite with an
# argument, a hyphenated gap word, a link word other than of/in, a name directly before the skill
# with no link word, and any words beside a skill other than the three places. A skill in
# parentheses is read like any other. A bare skill is read only beside a known name: a bare skill
# with a capitalised word that is no step or heading ("/dev:x's Jira key"), a quoted or bold word
# that is no name, or no cite at all passes. A second cite in a list passes for every one but the
# first. The heading extractor reads ## to #### lines inside code fences and tags too, so
# story-to-tasks's template (in an <issue-template> tag) gives Parent, What to build and
# Acceptance criteria. A possessive cite of a skill with no directory ("`/dev:nope`'s Name")
# passes here, as only the existing skills are matched; section 11 fails it.
standards=$agents/coding-standards.md
# each file is read as one line (lacksw and lackswc, as section 5 does, dev-86j), so a cite
# split across a line break fails too
doc 18 "cross-skill cites" "$standards" && has "the cross-skill cite rule heading" "## Another skill's rule is cited in one form"
# the sweep reads every skill and doc, so the standards doc being listed in LINT_UNCHANGED leaves
# it to run
if [ -f "$standards" ]; then
  # the cite targets of every skill, read in one pass: "<skill> <kind> <name>" with the kind step
  # or heading (both when the skill marks the name both ways), the name's regex characters
  # escaped. A step is a bold name opening a numbered item (**Name** or **Name.**) or opening a
  # line, indented or not, after an optional list marker "- ", with its period inside
  # (**Name.**); a bold label with no period that opens no numbered item (a list item
  # "- **Owner**", a table-like "**Alone**") is a label, no step, and a bold term inside a
  # sentence is none, so neither is read. A heading is a ## to #### line, its number dropped. A
  # name opens on a letter or a backtick.
  cite_names=$(awk '
    function esc(s) { gsub(/[][\\.^$*+?(){}|]/, "\\\\&", s); return s }
    function add(kind, name) {
      if (name !~ /^[A-Za-z`]/ || index(name, "\t")) return
      name = esc(name)
      # the kind is read per name in any case (the marked checks match in any case), so a step and
      # a heading differing only in case are one name of kind both
      lk = skill SUBSEP tolower(name)
      if (!(lk in kind_of)) kind_of[lk] = kind
      else if (kind_of[lk] != kind) kind_of[lk] = "both"
      k[skill, name] = 1
    }
    FNR == 1 { skill = FILENAME; sub(/\/SKILL\.md$/, "", skill); sub(/.*\//, "", skill) }
    /^(##|###|####) / { h = $0; sub(/^#+ /, "", h); sub(/^[0-9]+\. /, "", h); sub(/[ \t]+$/, "", h); add("heading", h); next }
    {
      s = $0; sub(/^[ \t]+/, "", s)
      numbered = (s ~ /^[0-9]+\. \*\*/)
      if (numbered) sub(/^[0-9]+\. /, "", s)
      else sub(/^- /, "", s)
      if (substr(s, 1, 2) != "**") next
      s = substr(s, 3); e = index(s, "**")
      if (e == 0) next
      name = substr(s, 1, e - 1)
      if (name ~ /\.$/) { sub(/\.$/, "", name); add("step", name) }
      else if (numbered) add("step", name)
    }
    END { for (x in k) { split(x, p, SUBSEP); print p[1] "\t" kind_of[p[1] SUBSEP tolower(p[2])] "\t" p[2] } }' "$skills"/*/SKILL.md | LC_ALL=C sort)
  # the checks depend on the skills' names, so a changed SKILL.md that moves one has every rules
  # doc and SKILL.md read again, whatever LINT_UNCHANGED vouches for; one that leaves them as
  # LINT_CITE_BASE holds them moves no verdict on a listed file
  cite_key=$skill_names$'\n'$cite_names
  [ -z "${LINT_PIN_LIST:-}" ] || printf '%s\n' "$cite_key" > "$LINT_PIN_LIST.cites"
  saved_f=$f saved_unchanged=$unchanged
  if [ ! -s "${LINT_CITE_BASE:-}" ] || [ "$cite_key" != "$(<"$LINT_CITE_BASE")" ]; then
    for f in "$skills"/*/SKILL.md; do unchanged_file || { unchanged=$'\n'; break; }; done
  fi
  f=$saved_f unchanged_f=/
  # cite_toks <form>: sets the skill's regexes for the three word orders, from $skill: poss (the
  # skill and its possessive), skill_alone (the skill alone), skfirst (skill_alone with what may
  # stand between it and a name that follows it with no possessive: a comma, colon or semicolon,
  # a dash, and the words the, step and section) and gap (up to two words, then of/in and the
  # skill). The form "any" is the skill backticked or bare, with a stray backtick at either end
  # or around its possessive too, and ends on an edge that no letter or hyphen continues, so
  # /dev:setup is no match in /dev:setup-repo. The form "bare" is the skill not set in a whole
  # pair of backticks (bare, or a backtick at one end only, or one that swallows the
  # possessive): the right marking beside it is wrong (dev-hcn9)
  cite_toks() {
    local pre='(^|[^`/A-Za-z:-])' sk="/dev:$skill"
    if [ "$1" = bare ]; then
      poss="($pre$sk\`?'s\`?|\`$sk's\`?)"
      skill_alone="($pre$sk\`?|\`$sk)"
      gap="( [a-z]+){0,2} (of|in) ($sk(\`|[^A-Za-z-]|\$)|\`$sk([^\`A-Za-z-]|\$))"
    else
      poss="\`?$sk\`?'s\`?"
      skill_alone="\`?$sk\`?"
      gap="( [a-z]+){0,2} (of|in) \`?$sk(\`|[^A-Za-z-]|\$)"
    fi
    skfirst="$skill_alone[,:;]?( (—|-))?( (the|step|section))*"
  }
  # three_orders <x>: the pattern for x in the three word orders, from the p, skfirst and gap that
  # cite_toks set, so the orders of one cite cannot drift between checks
  three_orders() { printf '%s' "$poss( (step|section))? $1|$skfirst $1|$1$gap"; }
  # cite_marked <wants> <what> <mark> <skill form>: queues a check that a name of one of the kinds
  # <wants> (a |-list; never one of kind both unless listed) is not cited in the mark ('"' or
  # '\*\*'), in any case, in any of three word orders: after the possessive and an optional step
  # or section, straight after the skill (skill-first), or ahead of the gap. The skill form is
  # "any" (a wrong marking) or "bare" (the right marking beside a skill not in backticks); reads
  # skill, kind, name and the file in f (dev-hcn9)
  cite_marked() {
    case "|$1|" in *"|$kind|"*) ;; *) return 0 ;; esac   # kind both is checked only where <wants> lists it (dev-mnz6)
    local poss skill_alone gap skfirst
    cite_toks "$4"
    lacksw "$2 of /dev:$skill in $f" "$(three_orders "$3$name[.,;:]?$3[.,;:]?")"
  }
  # every skill's SKILL.md is read too (dev-xyrl), the skills' own docs binding like a rules doc
  for f in "$agents"/*.md "$skills"/*/SKILL.md; do
    [ "$f" = "$standards" ] && continue   # it shows the wrong forms as examples
    # a listed file queues nothing here, and the loop below is most of a run's cost (the pin list
    # still takes its checks)
    [ -n "${LINT_PIN_LIST:-}" ] || ! unchanged_file || continue
    # the file's own skill, when it is a SKILL.md, is no cross-skill cite
    own=
    case $f in "$skills"/*/SKILL.md) own=${f%/SKILL.md}; own=${own##*/} ;; esac
    # one pattern over the other skills (skill_names, section 17's list), the file's own left out
    others=${skill_names//|$own|/|}; others=${others#|}; others=${others%|}
    [ -z "$others" ] || lackswc "an unquoted heading cite of a skill in $f" "\`/dev:($others)\`'s [A-Z]"
    # every pattern below holds /dev:<skill> (backticked or bare; the test is on the bare text) and
    # the name's first word, tokens no line break splits, so a file lacking either can match none
    # of them: most files name few skills, and the regexes are the run's cost, in gawk above all.
    # Both tests are fixed-string, the word's in lower case against the file lowered (the checks
    # match in any case), so they know no skill name's alphabet; a first word with a regex escape
    # in it goes unfiltered. The pin list takes every check
    names_here=$cite_names
    [ -n "${LINT_PIN_LIST:-}" ] || names_here=$(awk -F '\t' -v own="$own" '
      NR == FNR { text = text tolower($0) "\n"; next }
      $3 != "" && $1 != own && index(text, "/dev:" $1) {
        w = tolower($3); sub(/ .*/, "", w)
        if (index(w, "\\") || index(text, w)) print
      }' "$f" - <<<"$cite_names")
    while IFS=$'\t' read -r skill kind name; do
      [ -n "$name" ] || continue
      # a skill's own steps and headings are no cross-skill cite
      [ "$skill" = "$own" ] && continue
      # the skill is matched backticked or bare, so a bare skill beside a name fails too (dev-hcn9)
      cite_toks any
      # a backtick after the name (and a punctuation mark after it) leaves the name bare too
      lacksw "a bare cite of /dev:$skill in $f" "(^|[^*\"A-Za-z])$name(\`[.,;:]?)?$gap"
      lacksw "a bare cite after a possessive and step or section of /dev:$skill in $f" "$poss( (step|section))? $name([^A-Za-z]|$)"
      # case-sensitive: a lower-case word straight after a skill reads as prose ("`/dev:x` re-cut adds")
      lackswc "a bare skill-first cite of /dev:$skill in $f" "$skfirst $name([^A-Za-z]|$)"
      # a name is never set in backticks, step or heading, in any of the three orders: the name
      # inside a pair of backticks, with a bold or quote mark inside or outside the pair too
      # (dev-hcn9). A backtick that is part of the name (**`git` rule**) is not a pair around it
      in_ticks="[*\"]*\`[*\"]*$name[*\".,;:]*\`[*\".,;:]*"
      lacksw "a name cited in backticks of /dev:$skill in $f" "$(three_orders "$in_ticks")"
      cite_marked step "a step name cited in quotes" '"' any
      cite_marked heading "a heading cited in bold" '\*\*' any
      # a skill is named in backticks: the right marking beside a bare skill fails (dev-hcn9)
      cite_marked "step|both" "a skill not in backticks beside a cited name" '\*\*' bare
      cite_marked "heading|both" "a skill not in backticks beside a cited name" '"' bare
    done <<< "$names_here"
  done
  unchanged=$saved_unchanged unchanged_f=/
fi

checks_run
[ "$fail" = 0 ] && echo "PASS"
exit "$fail"
