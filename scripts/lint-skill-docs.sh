#!/usr/bin/env bash
# Reference lint for skill-facing docs (INFRA-26): named commands exist, stale phrases are absent.
# Not the test seam for any skill; that is a subagent following the skill against the fixture.
# One section per doc (INFRA-27 added 3-6):
#   1. the /implement-spec epic orchestrator text (chezmoi-0jp.24): no ticket-level procedure, names the
#      refusals, the spawn with its pointer at the waiting rule (chezmoi-p4q) and the end states,
#      the story-closure human stop and the add-mode stall hint pinned (chezmoi-9v4.1.6); the
#      epic row (dev-9k5.1.8): the role named, the harness doc cited, the epic review (one PR at
#      a time, the default-branch diff, the Jira Epic's spec, no standards axis, the epic's max
#      tier), draft until clean with the mark-ready commands, the add-mode fix-up (one ticket per
#      blocking finding, three per story, the fourth failed) and the review: end-state line, with
#      no epic-row role and no PR opened here;
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
#      with the dependent's body rewritten and Jira untouched (chezmoi-9v4.1.7);
#   4. /spec-to-tickets: user-typed, the same argument rule as 3, the refusals,
#      cutters pointed at the waiting rule and without a model override, explicit dependent
#      lines, the closed and publish-failed lines, a Jira comment over every story, no
#      story-cut procedure; the cycle refusal, topological waves with every upstream
#      breakdown in a dependent's brief, the inline re-cut of an already cut dependent keyed on
#      its missing bump, a finished dependent excluded at step 1, a skipped repo's publish line
#      as an edge with no dependency, the held-back cascade narrowed to a dependency without
#      its publish ticket, and no two-wave cap (ADR 0011);
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
#      either kind", "a second red"; dev-1xf.1.4), which the root GLOSSARY.md lacks too; and
#      none of the retired vocabulary (dev-9k5.1.11): the epic, ticket and landing roles, the
#      built-in review by name, the two-review-tools paragraph, the review marker, the lint
#      command and the test seams as checks (the glossary lists them under _Avoid_, docs/adr/
#      keeps them through .glossary-allow); and no rule that moved to harness.md cited at the
#      rules doc (dev-zra). docs/specs keeps every list. No other section repeats a phrase this
#      sweep covers, so a seeded one fails here alone;
#   6. the shared rules: orchestration.md's working-directory preflight, and harness.md's
#      waiting rule (an Agent call returns at once, the orchestrator ends its turn and the
#      completion notification resumes it, never a Bash poll loop; pgrep is dead in the
#      sandbox) with its idle rule (Bash in the foreground only below the epic orchestrator, chezmoi-p4q), the
#      model (dev-9k5.1.3): the loop sentence, the table's header and each of its three rows, the
#      two scoping rules, the six trust rules as a closed list, the check command, the check record
#      and the one gate exit, the seam-test blocking case and the one review tool, with the two-level
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
#      and its close rule counting a story's children as the finished story does (chezmoi-afn);
#   7. /story-to-tickets: the spec fetch pointer, the story cutter and publish triggers, the
#      design field read, the one test and "home <home name>" in the template's Parent line,
#      the pair read per edge (one bump per publish blocker, Dependency:/Dependent: lines),
#      the two refusals (two publish tickets; a finished story pointing at add mode) and the
#      re-cut's added bump, re-edge and citation of the per-edge rules (ADR 0011);
#   8. /implement-story: the deliver step pushes and opens the PR on the typed command's
#      authority (orchestration.md's delivery rule, checked in 6; ADR 0009), a refused push
#      is a failed: line, so no step waits on the user, the Gitignore step commits a dirty
#      .gitignore made of the rule's entries alone while an edit of the user's in it is a
#      failed: line (chezmoi-hkn), its exploration subagent reads the story's design field
#      and owns .spec-notes/<epic-id>/ (chezmoi-cdf), and a ticket whose ticket orchestrator failed is
#      unclaimed before the next frontier read, with the resume pointer noted on a second
#      failure and step 9's resume: line naming when a human runs the unclaim (chezmoi-jvc;
#      the Frontier's unclaim rule is checked in 6), its frontier read keeps ready-for-agent
#      tickets only, its review step captures deferred findings in the inbox through the
#      retro capture, its finished story tolerates an untriaged child (chezmoi-wgi), and its
#      ticket orchestrator waits on the owner lock in one bounded until-loop, never a check-and-sleep loop
#      by hand (chezmoi-sn1), and its frontier spawn and the ticket orchestrator brief end the turn
#      after spawning and carry the idle rule (chezmoi-p4q), and its integration branch is
#      feat/<story-id> keyed or not, a delivered story with an open agent ticket passes one
#      merge guard (MERGED, CLOSED unmerged, OPEN, ask), a story-closure wait says to merge
#      and run /close-story, and the sibling line is <repo> <story-id> <url> (chezmoi-9v4.1.5,
#      ADR 0011), and its clean-up step removes worktrees with the sandbox disabled up front,
#      sweeps every worktree-agent-* and .worktrees/ worktree whose branch is merged into the
#      integration branch, earlier runs' included, and reports a locked or unmerged one in the
#      report's worktrees: line instead of forcing it (chezmoi-73d), and its implementer,
#      fix-up and conflict-resolution briefs start with the TMPDIR line, whose rule section 6
#      checks in orchestration.md (chezmoi-3eg), and its reviewer brief tags every finding
#      blocking or minor and ends on the verdict line, its ticket orchestrator step 3 and story review step 7
#      pointing at the rules doc's Review verdict, whose rule section 6 checks (chezmoi-49k),
#      and its ticket orchestrator brief states the ticket row's parameters, the check command
#      by Makefile convention (none: review-only) and the harness doc in one line, writes a check
#      record per tree SHA, reviews with mattpocock-skills:code-review and lands its own ticket
#      (lock wait, stray-commit check, merge; a conflict to an implementer in the ticket's
#      worktree, then a fast-forward, the resolved tree checked and not reviewed again), with the
#      lint-command resolution and the separate landing brief retired (dev-9k5.1.7),
#      and its story gate (step 7) is the rules doc's Check gate loop at the story row: it exits
#      when the checks are green on the tip the review called clean, reads the checks from the
#      check records, keeps the reviewed tip in the story's review: note, reviews the story's body
#      (spec) and what entered since the ticket reviews (standards), sends a red or a blocking
#      verdict to a fresh fix-up, three per story, the fourth failed, and spends nothing on the
#      minors fix-up; its deliver step (8) leaves the PR a draft, its Evidence the delivered tip's
#      check record, and step 9 removes the records; "Running the checks" and "the command and
#      its output" are gone (section 5's sweep covers the review marker, the merger, the keyed
#      branch, the Evidence run and the second-red stall) (dev-cq0.1.5, dev-1xf.1.3, dev-9k5.1.9); section 6 checks the
#      rules doc's Check gate;
#   9. /close-story: its Forgejo/Gitea query carries --repo <path> as the intro and
#      /implement-story's merge guard do (dev-hac); its ticket check skips a child carrying
#      needs-triage or wontfix, as the finished story does, and its refusal names each open
#      child's status and label (chezmoi-afn);
#  10. the tracker and orchestration docs: both name the story DAG and the human gate ticket,
#      and neither puts chains out of scope in any wording (section 5 sweeps "only text
#      blocker" and "chains are out of scope"); the orchestration
#      doc ends a story-closure wait as a human stop and readies a publish ticket on its
#      story's tickets; the tracker doc's story body shows no unfillable gate ticket line
#      and orders a middle story of a chain in one topological pass, creates every
#      repo-session story under the epic bead, and makes a deploy split wait on the
#      earlier story's closure (ADR 0011).
#  11. the namespace rule: in every .md file under the skills dir, docs/ (the agent docs, ADRs, specs),
#      the runbook, the project CLAUDE.md, the root GLOSSARY.md and the implement-spec skill passed as $1, a
#      /<command> is dev:<skill> or mattpocock-skills:<skill> naming a skill that exists, or a
#      built-in or a path; a bare /<skill> or another namespace fails. The /command extraction
#      (cmd_tokens) and the existence check (cmds) moved here from section 2, which no longer
#      calls them. The root docs joined the scan in dev-9np: a bare name there passed before.
#  12. /retro: step 2 names the transcript shape (one JSON object per line with its own type
#      and timestamp, tool_use and tool_result objects in message.content) and two recipes, a
#      jq per-agent call timeline and a grep tally across agents, each run with
#      `timeout: 600000` on a directory-wide scan; the bare "grep the whole slug directory" is
#      gone (dev-qfz, INFRA-30).
#  13. the brief rule: in every .md file under the skills dir, a brief block (a markdown quote,
#      from a line starting with `>`, indented or not, to the next blank line: the blocks the
#      orchestration skills send to ticket orchestrators, cutters, implementers and reviewers) never
#      names the plugin-root variable CLAUDE_PLUGIN_ROOT, which Bash never has and the harness
#      fills in only in the skill text it loads (the rules doc's Plugin root rule); the skill's
#      path and the line are named. Outside a brief, where the skill itself resolves the
#      variable, it passes (dev-rc9, INFRA-30);
#  15. the mermaid rule: no ";" on a line of a ```mermaid block in any doc the sweeps read, since
#      mermaid ends the statement there and the diagram fails to render (dev-1xf.1.4).
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
# rule. The list vouches for a file only in the role it had there, so a caller leaves out every
# path it passes as an argument or override. Unset, every check runs.
set -u
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail=0
bad() { echo "FAIL: $*"; fail=1; }
# has (grep -iF), hasc (-F), hase (-E), lacks (-iE), lacksf (-iF) and lackse (-E) check <pattern>
# against $f line by line, as those greps would; lacksw (-iE) against $f read as one line, each
# line's leading blanks and quote markers dropped and a space joining it to the next, so a
# phrase wrapped across a line break matches too; line_has (-F), line_hase (-E) and line_lacks (-F) check it
# on the lines matching <anchor> (-E), as a grep -E <anchor> | grep -q pipeline would; para_has
# (-iF) on the first paragraph opening with <heading> (that line to the next empty one), and
# opening_has (-F) on the lines before the first "## ". Each only queues its check: a section's
# checks run in one awk pass when the next section opens (section) and at the end (checks_run),
# so their FAIL lines print under their own section's header, at a cost of one process per
# section rather than one or two per check (the regression test runs the lint a few hundred
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
# for a sweep over many files (where unchanged_file would match the list once per file)
drop_unchanged() {
  # -s: an empty list would leave NR == FNR true on stdin too, and the sweep would print nothing
  if [ -s "${LINT_UNCHANGED:-}" ]; then awk 'NR == FNR { u[$0]; next } !($0 in u)' "$LINT_UNCHANGED" -; else cat; fi
}
# enqueue <check line>: queues it unless $f is a file LINT_UNCHANGED lists
enqueue() { unchanged_file || queue+="$1"$'\n'; }
has() { enqueue "i	$f	$1	$2"; }
hasc() { enqueue "c	$f	$1	$2"; }
hase() { enqueue "e	$f	$1	$2"; }
lacks() { [ -f "$f" ] || return 0; enqueue "x	$f	$1	$2"; }
lacksf() { [ -f "$f" ] || return 0; enqueue "f	$f	$1	$2"; }
lackse() { [ -f "$f" ] || return 0; enqueue "y	$f	$1	$2"; }
lacksw() { [ -f "$f" ] || return 0; enqueue "w	$f	$1	$2"; }
line_has() { enqueue "a	$f	$2	$3	$1"; }   # <anchor> <description> <phrase>
line_hase() { enqueue "A	$f	$2	$3	$1"; }   # <anchor> <description> <pattern>
line_lacks() { [ -f "$f" ] || return 0; enqueue "X	$f	$2	$3	$1"; }   # <anchor> <description> <phrase>
para_has() { enqueue "p	$f	$2	$3	$1"; }   # <heading> <description> <phrase>
opening_has() { enqueue "o	$f	$1	$2"; }
# the roles and review tools the three-row restatement retired (INFRA-33), swept in section 5
retired_row_names() {
  lacksw "the retired driver role in $f" '(^|[^a-z])[Dd]rivers?([^a-z]|$)'
  lacksw "the retired ticket runner role in $f" '[Tt]icket runners?'
  lacksw "the retired merger role in $f" '(^|[^a-z])[Mm]ergers?([^a-z]|$)'
  lacksw "the retired fix-up implementer role in $f" '[Ff]ix-up implementers?'
  lacksw "the built-in code-review named in $f" 'built-in `code-review`'
  lacksw "the two review tools paragraph in $f" 'Two review tools'
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
        if (t == "w") {
          if (!(fn in J)) {
            s = ""; pblk = 0
            for (ln = 1; ln <= n; ln++) {
              x = LO[fn, ln]; sub(/^[ \t>]+/, "", x); sub(/[ \t]+$/, "", x)
              blk = (x == "" || x ~ /^(#|\||```|[-*+] |[0-9]+\. )/)
              JO[fn, ln] = length(s) + 1
              s = s (ln == 1 ? "" : (blk || pblk ? "  " : " ")) x
              pblk = (x ~ /^(#|\||```)/)
            }
            J[fn] = s
          }
          ln = 1; pos = 1
          while (match(substr(J[fn], pos), lp[i])) {
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
          else if (t == "o") { if (index(line, "## ") == 1) break; if (index(line, p[i])) { hit[i] = 1; break } }
        }
      }
      for (i = 1; i <= NR; i++) {
        t = k[i]
        if (t == "x" || t == "f" || t == "y" || t == "w") { if (hit[i]) printf "FAIL: present: %s (%s)\n%s", d[i], p[i], shown[i] }
        else if (t == "X") { if (hit[i]) printf "FAIL: present: %s (%s on a line matching %s)\n", d[i], p[i], a[i] }
        else if (hit[i]) continue
        else if (t == "a" || t == "A") printf "FAIL: missing: %s (%s on a line matching %s)\n", d[i], p[i], a[i]
        else if (t == "p") printf "FAIL: missing in the %s paragraph: %s (%s)\n", a[i], d[i], p[i]
        else if (t == "o") printf "FAIL: missing in the opening: %s (%s)\n", d[i], p[i]
        else printf "FAIL: missing%s: %s (%s)\n", (t == "c" ? " (case-sensitive)" : ""), d[i], p[i]
      }
    }') || bad "the check pass failed (awk exit $?)"
  queue=
  [ -z "$out" ] || { printf '%s\n' "$out"; fail=1; }
}
# section <header>: runs the previous section's checks, then opens this one
section() { checks_run; echo "== $1"; }
# doc <n> <title> <file>: opens section n on <file> (sets f), true when it exists; a missing one
# is a failure naming it, never a skipped section
doc() { f=$3; section "$1. $2: $f"; [ -f "$f" ] || { bad "missing document: $f"; return 1; }; }

skills=${SKILLS_DIR:-$root/skills}
agents=${AGENT_DOCS:-$root/docs/agents}
docs=${DOCS_DIR:-$root/docs}
docs=${docs%/}
user_claude_md=${USER_CLAUDE_MD:-$root/CLAUDE.md}
glossary_md=${GLOSSARY_MD:-$root/GLOSSARY.md}
runbook=${2:-$root/docs/WORKFLOW.md}
# the dirs and the docs no section owns must exist, a default as much as an override; the
# driver ($1) and the runbook ($2) are their sections' documents
section "0. paths"
for given in "$skills" "$agents" "$docs"; do
  [ -d "$given" ] || bad "no such directory: $given"
done
for given in "$user_claude_md" "$glossary_md"; do
  [ -f "$given" ] || bad "no such file: $given"
done

# ---- 1. /implement-spec epic orchestrator ----
if doc 1 "/implement-spec epic orchestrator" "${1:-$skills/implement-spec/SKILL.md}"; then
lacks "worktree steps" 'worktree'
# no merge steps; the one allowed use is the human stop naming "the PR to merge" for the user
# (chezmoi-9v4.1.6), so that phrase is blanked before the scan
if ! unchanged_file; then
  merge_scan=$(sed 's/the PR to merge//gI' "$f")
  if grep -qi 'merge' <<<"$merge_scan"; then
    bad "present: merge steps (merge)"; grep -ni 'merge' <<<"$merge_scan" | head -3
  fi
fi
# the phrases pinned one by one, shared with the regression test's pin cases (dev-47z)
while IFS=$'\t' read -r check d phrase; do
  case $check in has|hasc) "$check" "$d" "$phrase" ;; '#'*|'') ;; *) bad "implement-spec-pins.tsv: unknown check $check" ;; esac
done < "$root/scripts/implement-spec-pins.tsv"
# the glossary avoids "human ticket" for the human gate ticket ("ready-for-human ticket" is fine)
lacks "glossary's avoided term human ticket" '(^|[^-])human ticket'
# the epic row reviews and marks ready, but opening a PR stays the story orchestrator's
lacks "PR-opening steps" 'draft PR|pr create|pulls create|open(s|ing)? (a|the) PR'
lacks "a budget of blocking verdicts only" 'three blocking verdicts'
lacks "a spent budget skipping the review" 'is failed and not reviewed again'
lacks "nothing touches a ticket" 'nothing below touches a ticket'
# dev-47z: the review set reads the delivered: note, not a failed: report this run
lacks "review set keyed on a failed: report this run" 'did not report `failed:` this run'
lacks "the paginated tea pr list" 'tea pr list'
has "frontmatter" 'disable-model-invocation: true'
has "legacy line" 'refused: flat epic (tickets directly under the epic bead); the story skills do not handle it — the small-bug path does: /mattpocock-skills:implement <ticket-id> per ticket, then bd close <epic-id>'
has "add-dir refusal" '/add-dir <'
hasc "Human stop" '**Human stop**'
hasc "Stall" '**Stall**'
hasc "Done" '**Done**'
has "Finished story" 'finished story'
hasc "finished story tolerates untriaged children" '`needs-triage` or `wontfix`'
lacks "finished story keyed on ready-for-human alone" 'other than `ready-for-human` ones|non-`ready-for-human`'
has "story orchestrator" 'story orchestrator'
has "implement-story" 'implement-story'
has "opus" 'opus'
has "resume command" '/dev:implement-spec <KEY>-<n>'
has "Jira step pointer" '"the spec is done"'
has "Jira already-made read" 'getJiraIssue'
has "no-startable path" 'No startable story'
has "stopped state" 'stopped at <bead-id>'
has "orchestration pointer" 'orchestration.md'
has "preflight pointer" '"Working-directory preflight"'

fi

# ---- 2. WORKFLOW.md runbook and /workflow ----
# /workflow prints each next command with the argument filled in, so a fresh session types it as-is
if doc 2 "/workflow" "$skills/workflow/SKILL.md"; then
hasc "workflow prints the story cut's argument" 'next: `/dev:spec-to-stories <arg>`'
hasc "workflow prints the ticket cut's argument" 'next: `/dev:spec-to-tickets <arg>`'
fi
doc 2 "/close-epic" "$skills/close-epic/SKILL.md" || true   # no pins of its own; section 5 sweeps it
if doc 2 "runbook" "$runbook"; then
# the cut skills take the feature as their one argument; the runbook has a paragraph on it and
# writes it in the 3a and 3b rows below (chezmoi-nz0)
hasc "argument paragraph" '**The argument.**'
# the flat path (row 4b) runs the checks before the one review tool, and its review is the
# ticket review; "ticket gate" is retired so "gate" means the checks in every doc (dev-cq0.1.3)
line_has '^[|] 4b [|]' "flat path runs the checks before the review" "then the checks (the owner repo's check command), then \`/mattpocock-skills:code-review\`"
line_has '^[|] 4a [|] `/dev:implement-spec`' "4a names the ticket orchestrators" '**ticket orchestrator**'
hase "the one review tool paragraph" '^One review tool, three rows'
line_has '^[|] 4a [|] opus [|]' "session model 4a: the epic orchestrator session" 'The epic orchestrator session'

hasc "flat path's review is the ticket review" 'the ticket review (switch'
lacks "retired ticket gate name in the runbook" 'ticket gate'

# flat /to-tickets appears only in the Variants section
unchanged_file || awk '/^## /{sec=$0} /\/mattpocock-skills:to-tickets/ && sec !~ /Variants/ {print NR": "$0; n=1} END{exit n}' "$f" >/dev/null \
  || bad "/mattpocock-skills:to-tickets outside Variants"

# stale wording
for pat in 'cross-repo ticket' 'per-ticket `pr:`' 'single orchestrator' 'one orchestrator drives'; do
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
hasc "one-line flow" '/mattpocock-skills:grill-with-docs → /mattpocock-skills:to-spec → /dev:spec-to-stories → /dev:spec-to-tickets → /dev:implement-spec → /dev:close-epic'
hase "4a session model is opus" '^\| 4a \| opus'
hase "3a row" '^\| 3a \| `/dev:spec-to-stories <KEY>-<n>`'
hase "3b row" '^\| 3b \| `/dev:spec-to-tickets <KEY>-<n>`'
hase "1-3b session model is fable" '^\| 1–3b \| fable'
hasc "exploration notes path" '`<repo>/.spec-notes/<epic-id>/`'
for need in '/dev:implement-story <story-id>' '/dev:close-story' 'story bead' 'GLOSSARY.md'; do
  hasc "runbook content" "$need"
done
# the story DAG's runbook text (ADR 0011): add mode, and the human stop's merge-then-close line
# as the skills print it; the ticket cut's chain refusal is retired
hasc "add mode in the runbook" 'add mode'
hasc "human-stop merge line in the runbook" 'merge its PR, then run `/dev:close-story <story-id>`'
hasc "printed human-stop line in the runbook" 'the PR to merge and the /dev:close-story <story-id> to run'
lacks "chain refusal in the runbook" 'refus[a-z]*[^|]{0,60}dependency chain|dependency chain \(A depends'
hase "/mattpocock-skills:pr named (Variants)" '/mattpocock-skills:pr([^a-z-]|$)'

# /pr stays off the main line: the fenced flow block and stage 5
unchanged_file || awk '/^```/{fence=!fence; next} fence && /\/mattpocock-skills:pr([^a-z-]|$)/ {n=1} END{exit n}' "$f" || bad "/mattpocock-skills:pr in the fenced flow"
lackse "/mattpocock-skills:pr in stage 5" '^\| 5 .*/mattpocock-skills:pr([^a-z-]|$)'

# the stage table stays one table (rows 1..8 contiguous)
unchanged_file || awk '/^\| 1 \|/{on=1} on && !/^\|/{bad=1} /^\| 8 \|/{on=0} END{exit bad}' "$f" || bad "stage table broken by a non-row line"

fi

# ---- 3. /spec-to-stories ----
if doc 3 "/spec-to-stories" "$skills/spec-to-stories/SKILL.md"; then
has "frontmatter" 'disable-model-invocation: true'
has "preflight pointer" '"Working-directory preflight"'
has "epic gather pointer" '"gather the epic bead"'
# the argument is required; recovering the epic from the conversation or the open epic list
# is retired (chezmoi-nz0)
hasc "usage line" 'usage: /dev:spec-to-stories <KEY>-<n>|<epic-id>'
lacks "no-argument epic recovery" 'bd list --type epic --json|open epic beads|reported in the conversation'
# the orientation goes to the story bead's design field; the story cut writes nothing in an owner
# repo but beads (chezmoi-cdf, ADR 0010)
hasc "design field write" 'update <story-id> --design-file -'
hasc "orientation header line" 'Orientation from the story cut; the story body is the only contract.'
hasc "beads-only writes in owner repos" 'writes no file and runs no git write in any owner repo'
lacks "step 8 gitignore line or commit" 'chore: ignore spec notes|Gitignore step commits it|\.spec-notes|>> <owner>/\.gitignore|git -C <owner> (add|commit)'
has "no Jira comment" 'No Jira comment'
has "the design field names the other repo of a pair" "the other repo's name"
has "repo-session line" 'repo session in <home>: one story, in the home repo'
has "repo-session refusal" 'refused: the spec changes <what> outside <home>; start this at the workspace root'
has "one test pointer" 'the one test'
has "workspace-session key warnings" 'in a workspace session'
lacks "re-sync instruction" 're-sync'
lacks "Jira comment step" 'addCommentToJiraIssue'
has "epic bead writes pointer" '"epic bead writes" convention'
# the stories form a DAG detected per edge, not a pair; the cut proposes a split of a repo's
# story only for a deprecate-then-remove, the user may split for any reason (ADR 0011)
has "story DAG" 'story DAG'
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
has "add mode" 'add mode'
lacks "unconditional stories-exist refusal" 'refused: stories exist'
hasc "refusal only when every story is closed" 'refused: every story is closed'
hasc "add mode shows each story's state" 'finished, open with failed tickets, waiting'
hasc "add mode reads the failed twice: notes" 'names the `failed twice:` reason it answers'
hasc "add mode quizzes the additions only" 'quizzes the additions only'
# one forge query per finished story an addition touches, sandbox-disabled as /close-story's
hasc "forge query, GitHub" 'gh pr view <url> --json state'
hasc "forge query, Forgejo/Gitea" 'tea api --repo <owner> repos/{owner}/{repo}/pulls/<n>'
lacks "Forgejo/Gitea forge query without --repo" 'tea api repos/'
hasc "forge query runs sandbox-disabled" 'with the sandbox disabled, as `/dev:close-story` step 4 does'
hasc "MERGED forces a new story on the old one's closure" 'a new story blocked on its closure and on the new publish'
hasc "MERGED reminds the close" 'run `/dev:close-story <story-id>`'
hasc "OPEN defaults to a re-cut" '`OPEN` defaults to a re-cut'
hasc "no forge or a branch-form pr: asks the user" 'a branch-form `pr:` value asks the user'
# OPEN's re-cut marks the finished dependent so the ticket cut may re-cut it past its pr: note;
# a PR closed unmerged is refused, as /implement-story's merge guard refuses it (story review 1)
hasc "OPEN marks the finished dependent for a re-cut" '`recut: <dep repo> publish <crate> <version>`'
hasc "a PR closed unmerged is refused" 'refused: PR <url> is closed unmerged'
lacks "a PR closed unmerged takes OPEN's path" 'closed unmerged is not sealed|closed unmerged[^.]*takes `OPEN`'
# step 7 in add mode writes the additions and the rewritten dependent bodies, beads only
hasc "add mode publishes the additions only" 'publishes the additions only'
hasc "open dependent's body rewritten" 'update <story-id> --body-file -'
hasc "add mode leaves Jira untouched" 'the Jira description is untouched'

fi

# ---- 4. /spec-to-tickets ----
if doc 4 "/spec-to-tickets" "$skills/spec-to-tickets/SKILL.md"; then
has "frontmatter" 'disable-model-invocation: true'
has "no-stories refusal" 'refused: no stories'
has "every-story-cut refusal" 'refused: every story already cut'
has "every-story-cut remedy" 're-cut one with /dev:story-to-tickets <story-id>'
has "preflight pointer" '"Working-directory preflight"'
has "epic gather pointer" '"gather the epic bead"'
# the same argument rule as /spec-to-stories (chezmoi-nz0)
hasc "usage line" 'usage: /dev:spec-to-tickets <KEY>-<n>|<epic-id>'
lacks "no-argument epic recovery" 'ended on in the conversation|ask the user for it'
has "already cut line" '<repo> <story-id> already cut'
hasc "waiting rule pointer" 'the "Waiting" rule of `harness.md`'
has "no model override" 'no `model:` override'
has "waiting line" 'waiting on <dep repo> cut'
has "closed story line" '<repo> <story-id> closed'
has "skipped dependent gets explicit crate and version" 'Dependent: <repo>, skipped: no beads database, crate <crate>, version <version>.'
lacks "crate and version deferred to the notes" 'as the design field has them'
has "skipped dependent's crate and version read from the design field" 'design field'
lacks "owner-repo notes file" '\.spec-notes'
has "already-cut block carries What to build" '`## What to build` paragraph'
has "all-closed refusal" 'refused: every story closed'
has "closed-uncut dependency line" 'dependency story closed uncut'
has "failed publish line" '<repo> <story-id> publish failed: <reason>'
has "dependent of a failed publish line" 'waiting on <dep repo> publish'
has "dependency cut without a publish ticket waits" 'has no `publish <crate> <version>` child'
has "closed-uncut remedy reopens the dependency" 'bd -C <repo> reopen <id>'
has "Jira comment covers every story" 'every story of the feature that has tickets'
lacks "Jira comment limited to this run" 'tickets this run published'
lacks "re-sync instruction" 're-sync'
has "one test pointer" 'the one test'
has "epic bead writes pointer" '"epic bead writes" convention'
lacks "story-cut procedure" 'Resolve the spec to its repos|Draft the stories|Quiz the user on the stories|Write the story-cut notes'
# the ticket cut cuts the story DAG (ADR 0011, chezmoi-9v4.1.8): a cycle is refused naming its
# stories; cutters run in topological waves, one per DAG level, each dependent's brief carrying
# every upstream breakdown, a story-closure edge ordering no wave; an already cut dependent of a
# new publish ticket is re-cut inline in the same run, so the rerun hint drops that case
has "cycle refusal names the stories" 'refused: dependency cycle ('
has "topological waves" 'topological waves'
has "one wave per DAG level" 'one wave per level of the story DAG'
has "dependent brief carries every upstream breakdown" 'one `Dependency:` line per publish blocker'
has "story-closure edge orders no wave" 'a story-closure edge orders no wave'
has "the ticket cut re-cuts an already cut dependent" 're-cuts that dependent itself'
has "the re-cut adds a second bump" 'second bump'
# a skipped repo's publish line has no dependency story; the inline re-cut is keyed on the
# missing bump; a finished dependent is excluded at step 1, and a failed re-cut of a dependency
# that has its publish ticket holds no dependent back (chezmoi-9v4.1.8 review 1)
has "skipped publish line is an edge with no dependency" 'an edge with no dependency in the run'
has "re-cut keyed on the missing bump" 'has no bump child titled with that crate'
has "finished dependent excluded at step 1" 'cut failed: finished story (pr: note present)'
has "failed re-cut with a publish ticket holds nothing" 'already has its publish ticket holds nothing'
hasc "re-cut dependent also waits on a dependency without its publish" 'A dependent of the run (in the set to cut or to re-cut) with such an edge'
# a re-cut dependent that is also a dependency joins the trigger until no story joins, and no
# dependent waits on a publish the run creates; the cut-failure cascade covers only the run's
# dependencies, after the closed-uncut rule, so no story gets two report lines (review 2)
has "re-cut dependent without its publish joins the trigger" 'a dependent to re-cut without its publish ticket'
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
retired='(^|[^-A-Za-z0-9_])cut (one|two)([^-A-Za-z0-9_]|$)|<spec-slug>|story-cut\.md'
# Session mode (ADR 0008): the walk-up wording.
walkup='nearest ancestor|walking up|walk up|one level up|the home repo included|the workspace root included|no repos\.yaml above|workspace inbox|workspace'\''s inbox|home repo <home repo>'
# The story-DAG wording (ADR 0011): one story per repo (now one per PR), the keyed branch
# feat/<key>-<n> (now feat/<story-id>), chains out of scope and the one text blocker (now a
# DAG), and the two-wave cap (now topological waves).
retired_dag='one story per repo|feat/<key>-<n>|chains are out of scope|only text blocker|two waves suffice'
# the check and review loop's retired two-gate wording (dev-1xf.1.4): the Evidence run, the later
# run that reviews a fix, the third-round wording and the second-red stall
retired_loop='evidence run|a later run reviews the fix|a third round of either kind|a second red'
# a rule that moved to harness.md (dev-9k5.1.2) cited at the rules doc, doc first as "the rules
# doc's Worktrees", "the rules doc's worktree fallback", "the rules doc's Scratch space says
# (Literal paths)" or "(`orchestration.md`, Commits)", or rule first as 'the "Waiting" rule of
# `orchestration.md`'; the worktree fallback moved too, so the rules doc holds no fallback (dev-zra)
moved_names='(waiting|idle rule|commits|cut-off agents|worktrees|hand-rolled|fallback|literal paths|tmpdir|diff two files|python'\''s cache line|recursive deletes|shell commands)'
moved_rule='(rules doc|orchestration\.md)`?(, |'\''s (([a-z-]+ ){1,3}says \(|scratch space \(|[a-z-]+ )?)'"$moved_names"'([^a-z]|$)|'"$moved_names"'"?( rule)? (of|in) (the )?`?(rules doc|orchestration\.md)'
while IFS= read -r f; do
  lacksw "retired phrase in $f" "$retired"
  # no foreground spawn instruction: an Agent call returns at once whatever run_in_background
  # says, so skills and agent docs point at the waiting rule instead (chezmoi-p4q)
  lacksw "foreground spawn instruction in $f" 'run_in_background: false'
  lacksw "retired walk-up wording in $f" "$walkup"
  lacksw "retired story-DAG wording in $f" "$retired_dag"
  lacksw "retired two-gate wording in $f" "$retired_loop"
  # the retired vocabulary (dev-9k5.1.11): the epic, ticket and landing roles, the built-in
  # review by name, the review marker, the lint command and the test seams as checks
  retired_row_names
  lacksw "the retired review marker in $f" 'review markers?'
  lacksw "the retired lint command in $f" 'the lint command'
  lacksw "the retired test seams as checks in $f" 'test seams? as (the )?checks?'
  lacksw "a moved harness rule cited at the rules doc in $f" "$moved_rule"
done <<<"$swept"
# the root glossary lists the retired vocabulary under _Avoid_ (and docs/adr/ keeps its
# historical sense through .glossary-allow), so only the two-gate wording is swept there
f=$glossary_md
lacksw "retired two-gate wording in $f" "$retired_loop"

# the docs ship in the plugin: no path into the old dotfiles deployment (~/.claude/docs,
# ~/.claude/hooks) or the chezmoi source remains in any doc under docs/, the skills, the agent
# docs, the project CLAUDE.md or the runbook, spelled ~/, $HOME/ or ${HOME}/ (INFRA-30)
deployed='(~|\$HOME|\$\{HOME\})/(\.claude/docs|\.claude/hooks|\.local/share/chezmoi)'
while IFS= read -r f; do
  unchanged_file && continue
  lacks "dotfiles deployment path in $f" "$deployed"
done < <({ find "$docs" -type f -name '*.md' 2>/dev/null; find "$agents" "$skills" -type f 2>/dev/null
  echo "$user_claude_md"; echo "$runbook"; } | grep . | sort -u | drop_unchanged)

# ---- 6. shared rules the skills point at ----
if doc 6 "orchestration rules" "$agents/orchestration.md"; then
lacks "a foreground spawn" 'spawns in the foreground|foreground spawn returns|has no notification to wait for'
hasc "preflight section" '## Working-directory preflight'
has "preflight remedy" '/add-dir <'
# the typed implement command is the authority to push and open the PR, so the push is a step
# of the run, with a failed: line when it is refused (ADR 0009, chezmoi-g61)
hasc "delivery rule" '**Delivery.**'
lacks "profile-gated push in the rules doc" 'when the active profile permits'
# the epic-level stages reach an owner repo only through its beads database; files, .gitignore
# and commits there are the story orchestrator's (chezmoi-cdf, ADR 0010)
hasc "beads-only principle for the epic-level stages" 'only through its beads database'
lacks "the story cut commits the /.spec-notes/ line" 'The story cut commits'
# a ticket whose runner ended without closing it keeps its claim and bd ready omits it, so the
# story orchestrator unclaims it; a human does so only when the orchestrator could not (chezmoi-jvc)
hasc "frontier unclaim rule" '**Unclaim.**'
# the frontier admits only ready-for-agent tickets, not merely those without ready-for-human,
# so a needs-triage child filed under a story never gets a runner (chezmoi-wgi)
hasc "frontier admits ready-for-agent only" 'it is labelled `ready-for-agent`'
lacks "frontier keyed on ready-for-human alone" 'it is not labelled `ready-for-human`'
hasc "finished story tolerates untriaged children" '`needs-triage` or `wontfix`'
para_has '**Gitignore.**' "/.tmp/ among the Gitignore rule's entries" '`/.tmp/`'
# the rules docs ship in the plugin, so a brief reaches them through the plugin root: resolved
# once per session from the harness's variable and spelled as an absolute path in every brief,
# the TMPDIR rule's pattern (INFRA-30)
hasc "Plugin root rule" '**Plugin root.**'
para_has '**Plugin root.**' "the harness's plugin-root variable" 'CLAUDE_PLUGIN_ROOT'
para_has '**Plugin root.**' "resolved once per session" 'once per session'
para_has '**Plugin root.**' "the rules-doc path spelled literally in every brief" '<plugin root>/docs/agents/'
para_has '**Plugin root.**' "spelled out in every brief" 'every brief'
# a reviewer tags every finding blocking or minor and ends on a verdict line; a round with no
# blocking findings is clean; every fix-up, red or blocking, spends the check gate loop's budget. The
# rule is stated once here; the runner brief and the story review point at it (chezmoi-49k)
hasc "Review verdict rule" '**Review verdict.**'
para_has '**Review verdict.**' "the clean verdict line" 'verdict: clean'
para_has '**Review verdict.**' "the blocking verdict line" 'verdict: blocking (<n>)'
para_has '**Review verdict.**' "the blocking-or-minor tags" '**blocking** or **minor**'
para_has '**Review verdict.**' "a round with no blocking findings is clean" 'no blocking findings is **clean**'
para_has '**Review verdict.**' "every fix-up, red or blocking, spends the loop's budget" "Every fix-up, red or blocking, spends the loop's budget"
# the model (dev-9k5.1.3): one loop run at three rows, stated once as its sentence and a table
# whose rows give each level its parameters; each row pinned on its own line, so a cell kept
# elsewhere in the doc cannot stand in
hasc "the loop sentence" 'claim a unit, have a subagent build it, check it, review it, send a failure to a fresh fix-up or land it at the row above, and report one line'
line_has '^[|] Row [|]' "the table's header names every parameter" '| Orchestrator | Builds | Checks | Review spec axis | Review standards axis | Reviewer and model | Fix-up | Lands by | Exits when | Budget |'
row='^[|] [*][*]Ticket[*][*] [|]'
line_has "$row" "ticket row: the ticket orchestrator" '| ticket orchestrator |'
line_has "$row" "ticket row: one implementer in a worktree" '| one implementer in a worktree |'
line_has "$row" "ticket row: the ticket's body as spec" "| the ticket's body |"
line_has "$row" "ticket row: the ticket diff as standards" '| the ticket diff |'
line_has "$row" "ticket row: both axes at the review model, none at low with a check command" "| both axes, at the ticket's review model; none at \`low\` with a check command |"
line_has "$row" "ticket row: lands by merge under the lock after the stray-commit check" 'merge onto the integration branch under the lock, after the stray-commit check'
line_has "$row" "ticket row: a fix-up by pointer brief, same worktree" '| an implementer by pointer brief, same worktree |'
line_has "$row" "ticket row: three fix-ups" '| three fix-ups |'
row='^[|] [*][*]Story[*][*] [|]'
line_has "$row" "story row: the story orchestrator" '| story orchestrator |'
line_has "$row" "story row: ticket orchestrators over the frontier" '| ticket orchestrators in parallel over the frontier |'
line_has "$row" "story row: the story's body as spec" "| the story's body |"
line_has "$row" "story row: what entered since as standards" "what entered since the last standards review: conflict resolutions, cross-ticket coherence and the story gate's fix-up commits"
line_has "$row" "story row: both axes at the review model of the story's max tier" "| both axes, at the review model of the story's max tier |"
line_has "$row" "story row: a fix-up by pointer brief in a fix-up worktree" '| an implementer by pointer brief in a fix-up worktree |'
line_has "$row" "story row: lands by a push, the PR a draft" '| push, the PR staying a draft |'
line_has "$row" "story row: three fix-ups" '| three fix-ups |'
row='^[|] [*][*]Epic[*][*] [|]'
line_has "$row" "epic row: the epic orchestrator" '| epic orchestrator |'
line_has "$row" "epic row: story orchestrators over the frontier" '| story orchestrators in parallel over the frontier |'
line_has "$row" "epic row: the check command as the forge runs it" '| the check command as the forge runs it |'
line_has "$row" "epic row: the Jira Epic's spec" "| the Jira Epic's spec |"
line_has "$row" "epic row: no standards axis" '| none, the axis is skipped |'
line_has "$row" "epic row: the spec axis only at the review model of the epic's max tier" "| the spec axis only, at the review model of the epic's max tier |"
line_has "$row" "epic row: findings filed as tickets, the story re-run in add mode" '| findings filed as `ready-for-agent` tickets under the story, that story re-run in add mode |'
line_has "$row" "epic row: the PR marked ready, the human merges" 'the PR marked ready, the human merges'
line_has "$row" "epic row: three per story" '| three per story |'
for r in Ticket Story Epic; do
  line_has "^[|] [*][*]$r[*][*] [|]" "$r row: the check command" '| the check command'
  line_has "^[|] [*][*]$r[*][*] [|]" "$r row: the one exit" '| the checks green on the tip the review called clean |'
done
# the two scoping rules: what a review reads at a row, and which trees a row checks
hasc "review scoping rule" '**Review scope.**'
para_has '**Review scope.**' "the spec axis takes the row's own unit" "The spec axis takes the row's own unit"
para_has '**Review scope.**' "the standards axis reads what entered since" 'The standards axis reviews what entered since the last standards review'
para_has '**Review scope.**' "the review scope's why is ADR 0014" 'ADR 0014 in the plugin repo'
para_has '**Review scope.**' "the story row's standards axis takes the gate's fix-up commits" "the story gate's own fix-up commits"
hasc "check scoping rule" '**Check scope.**'
para_has '**Check scope.**' "every tree is checked once" 'Every tree is checked once'
para_has '**Check scope.**' "a tree with a check record counts as checked" 'a tree with a check record counts as checked'
para_has '**Check scope.**' "a changed tree is checked again" 'changes the tree, so it is checked again'
# the six trust rules, a closed list
hasc "trust rule 1: reviewer one tier up" '1. The reviewer runs one tier of model above the implementer'
hasc "trust rule 2: a fresh fix-up, never a message back" "2. A fix-up is a fresh implementer in the unit's worktree, never a message back"
hasc "trust rule 3: an implementer's own check runs never count" "3. An implementer's own check runs never count"
hasc "trust rule 4: the stray-commit check before every merge and push" '4. The stray-commit check runs before every merge and every push'
hasc "trust rule 5: only ready-for-agent tickets are claimed" '5. Only `ready-for-agent` tickets are claimed'
hasc "trust rule 6: the typed command authorises delivery" '6. The typed command authorises delivery'
hasc "the trust rules are a closed list" 'The list is closed: a rule that wants to join needs an ADR'
# one check command by Makefile convention, review-only without one; the check record keyed by
# tree SHA, written only by an orchestrator, the delivered tip's record the PR's Evidence
hasc "Check command rule" '**Check command.**'
para_has '**Check command.**' "make check by Makefile convention" '`make check` when its Makefile has a `check` target'
para_has '**Check command.**' "review-only without one" 'the gate is review-only'
hasc "Check record rule" '**Check record.**'
para_has '**Check record.**' "keyed by the tree SHA" 'keyed by the tree SHA'
para_has '**Check record.**' "only an orchestrator writes a record" 'Only an orchestrator writes a check record'
para_has '**Check record.**' "the delivered tip's record is the Evidence" "the record of the delivered tip's tree"
# the one gate semantics at every row (INFRA-33): the exit, the fix-up and its budget, the
# minors fix-up and the conflict resolution that rerun the checks and spend nothing, the
# reviewed tip as a sentence; the two-level loop with lint before the seams and the review
# marker exit is retired
hasc "Check gate rule" '**Check gate.**'
para_has '**Check gate.**' "one gate at every row" 'At every row the gate exits when the checks are green on the tip the review called clean'
para_has '**Check gate.**' "a red or blocking verdict goes to a fresh implementer" 'A red or a blocking verdict goes to a fresh implementer by pointer brief and the loop starts over'
para_has '**Check gate.**' "three fix-ups per unit" 'three such fix-ups per unit'
para_has '**Check gate.**' "the epic row budgets per story" 'at the epic row, three per story'
para_has '**Check gate.**' "a fourth failure is failed" 'the fourth is `failed`'
para_has '**Check gate.**' "a minors fix-up and a conflict resolution rerun the checks" 'A minors fix-up and a conflict resolution move the tip, so the checks rerun'
para_has '**Check gate.**' "and spend nothing" 'no budget is spent'
para_has '**Check gate.**' "the reviewed tip noted on the story" 'records the reviewed tip in its notes'
para_has '**Check gate.**' "the gate exits on the moved tip" 'the gate exits on the moved tip once its checks are green'
para_has '**Check gate.**' "the reviewed-tip note names the moved tip" 'the reviewed-tip note on the story bead'
para_has '**Check gate.**' "the ticket row writes no reviewed-tip note" 'the ticket row writes no such note'
# a low ticket in a repo with no check command is reviewed, so no tier and no repo leaves a
# ticket ungated (dev-5e4)
para_has '**Check gate.**' "no ticket lands with neither a check nor a review" 'No ticket lands with neither a check nor a review (dev-5e4)'
para_has '**Check gate.**' "a low ticket with no check command is reviewed" 'and the review at the `low` tier'"'"'s review model when it has none'
# the fix-up budget is bounded per invocation at every row (dev-gi1): a fresh orchestrator at any
# row starts its unit's budget at three whatever notes earlier invocations left, the epic
# orchestrator counts a story's spent budget from the notes after this invocation's epic review 1,
# an agent resumed with its context keeps its own count, and the epic row is no exception
para_has '**Check gate.**' "a fresh orchestrator starts its unit's budget at three" "starts its unit's budget at three whatever notes earlier invocations left"
para_has '**Check gate.**' "the fresh budget holds at any row" 'A fresh orchestrator at any row'
para_has '**Check gate.**' "a resumed agent keeps its own count" 'an agent resumed with its context keeps its own count'
para_has '**Check gate.**' "neither the ticket row nor the story row records spent fix-ups" 'neither the ticket row nor the story row records spent fix-ups'
para_has '**Check gate.**' "the epic orchestrator counts from the notes after this invocation's epic review 1" "counts a story's spent budget from the story's \`epic fix-up\` notes after this invocation's \`epic review 1\` note"
para_has '**Check gate.**' "the bound is per invocation, citing dev-l4j" 'bound a person wants is per invocation (dev-l4j)'
lacks "the epic row named as the budget's exception" 'The epic row is the exception'
para_has '**The epic row.**' "the epic row's checks are the forge's status on the PR tip" "the forge reports them green on the PR's tip"
# the epic row settles its own red check and minors (dev-bwh): a red check is filed like a
# blocking finding, a ticket under the story, and spends the budget; a clean verdict's minors
# take no last fix-up, which the epic orchestrator cannot run, and go to the inbox
para_has '**The epic row.**' "a red check at the epic row is filed like a blocking verdict" 'On a blocking verdict or a red check'
para_has '**The epic row.**' "the red check's ticket carries its check, command and log" 'carries its check, its command and its log pointer'
para_has '**The epic row.**' "a red check spends the epic row's budget" 'three such fix-ups per story per invocation, red or blocking alike'
para_has '**The epic row.**' "a pending check leaves the PR a draft" 'the PR stays a draft and a later invocation reads it again'
para_has '**The epic row.**' "the epic row's minors take no last fix-up" 'minors take no last fix-up at this row'
para_has '**The epic row.**' "the epic row's minors go to the inbox" 'the inbox as deferrals'
para_has '**Review verdict.**' "the Review verdict sends the epic row's minors to the inbox" 'always to the inbox (The epic row, above)'
lacks "the retired two-level check order" 'lint first, then the test seams'
# the seam-test blocking case, and the one review tool
para_has '**Review verdict.**' "no test at a story seam is blocking" 'no test at a story seam exercises the criteria'
hasc "the one review tool" '`mattpocock-skills:code-review` at every row'
fi
if doc 6 "harness rules" "$agents/harness.md"; then
# the mechanics live in the harness doc (dev-9k5.1.2): the rules above moved out of the
# orchestration doc with it, and the doc points back at the preflight that stays there
# a runner waits on its subagent's report, never on a Bash poll loop; pgrep is dead in the sandbox (chezmoi-flq)
hasc "waiting rule" '**Waiting.**'
hasc "pgrep unusable in the sandbox" '`pgrep` cannot list processes in the sandbox'
# an Agent call returns at once in this harness, so an orchestrator ends its turn after spawning
# and the child's report arrives as the Agent tool's completion notification; run_in_background
# is a JSON boolean the probe found ignored or absent for a nested agent; every subagent below
# the epic orchestrator runs Bash in the foreground only, since a child that ends a turn with background
# work running counts as idle and its real report escapes to the top-level session (chezmoi-p4q)
hasc "an Agent call returns at once" 'An Agent call returns at once'
hasc "the completion notification carries the report" "the Agent tool's completion notification"
hasc "a nested orchestrator ends its turn after spawning" 'ends its turn'
hasc "run_in_background is a JSON boolean" '`run_in_background` is a JSON boolean'
hasc "idle rule" '**Idle rule.**'
hasc "Bash in the foreground only below the epic orchestrator" 'in the foreground only'
# the Bash tool backgrounds a call that outlives its 120 s default, which is the idle state the
# rule forbids, so lint and test runs pass timeout: 600000 (dev-7k0, INFRA-30)
hasc "the 120-second default backgrounds a longer call" '120-second default'
hasc "lint and test runs carry the ten-minute timeout" 'timeout: 600000'
lacks "a foreground spawn" 'spawns in the foreground|foreground spawn returns|has no notification to wait for'
# every worktree brief starts by exporting a gitignored repo-relative TMPDIR, since the macOS
# default is unwritable in the sandbox (mktemp -d, heredocs); the export is repeated per Bash
# call and mktemp -d takes a template, since macOS mktemp ignores TMPDIR (chezmoi-3eg)
hasc "TMPDIR rule" '**TMPDIR.**'
# the rule's own paragraph (from its heading to the next blank line) carries the line, the two
# failures and the gitignore fact, so a word used elsewhere in the doc cannot stand in
para_has '**TMPDIR.**' "TMPDIR line" 'mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp'
para_has '**TMPDIR.**' "the heredoc failure" 'heredoc'
para_has '**TMPDIR.**' "the directory is gitignored" '`.tmp/` is gitignored'
para_has '**TMPDIR.**' "export repeated per Bash call" 'export TMPDIR=<worktree>/.tmp; <command>'
para_has '**TMPDIR.**' "mktemp -d takes a template under .tmp" 'mktemp -d <worktree>/.tmp/<name>.XXXXXX'
para_has '**Idle rule.**' "the Idle rule names the check command" 'every run of the check command'
lacks "the Idle rule's retired story's-checks clause" "these are the story's checks"
# the cut-off rule with its stop sweep, and the commits rule with its clean-tree check
hasc "cut-off rule" '**Cut-off agents.**'
para_has '**Cut-off agents.**' "the stop sweep" 'First the **stop sweep**'
hasc "commits rule" '**Commits.**'
para_has '**Commits.**' "the clean-tree check" '`git status --porcelain --untracked-files=no` prints nothing'
# the shell-commands discipline and the pointer back at the preflight kept in the rules doc
hasc "the -C discipline" 'This section binds every session and subagent'
hasc "the preflight stays in the rules doc" 'The working-directory preflight stays in `orchestration.md`'
fi
if doc 6 "tracker rules" "$agents/issue-tracker.md"; then
# every ticket passes the check gate; only the review is medium/high (ADR 0014)
lacks "medium and high tickets passing the check gate" '`medium` and `high` tickets pass the check gate'
hasc "every ticket passes the check gate" 'every ticket passes the check gate'
# the one test of the session mode (ADR 0008), stated once, in the opening before any section
for need in '`<home>` is the session'"'"'s repo' '`<home>/repos.yaml`' '**workspace session**' '**repo session**' 'the only owner'; do
  opening_has "the tracker doc's one test" "$need"
done
hasc "epic gather section" 'When a skill says "gather the epic bead"'
has "other-repo refusal" 'refused: epic bead lives in <repo>'
has "closed refusal" 'refused: epic bead is closed'
has "flat epic refusal" 'refused: flat epic (tickets directly under the epic bead)'
has "re-cut creates a missing publish ticket" 'has no publish ticket'
lacks "Jira comment gated on every ticket" "When all of a run's tickets are published"
hasc "spec fetch section" 'When a skill says "fetch the spec"'
has "Spec: file fallback" 'The file a `Spec: <path>` line'
# the line's one canonical form, stated in the gather section and read by the fallback (chezmoi-dz4)
has "Spec: line canonical form" '`<path>` relative to the epic bead'"'"'s repo'
# who may write on the epic bead, stated once and cited by the three cut skills (chezmoi-f0f)
hasc "epic bead writes convention" '- Epic bead writes:'
# the close check counts a story's children the way the finished-story definition does: an
# untriaged child an earlier run left under the story holds back neither its PR nor its close
# (chezmoi-afn)
hasc "close rule tolerates untriaged children" 'closed or carries `needs-triage` or `wontfix`'

fi
# ADR 0014 records the one loop and supersedes ADR 0001, which keeps its text and points at it
if doc 6 "ADR 0014" "$docs/adr/0014-one-loop-at-three-rows.md"; then
line_hase '^status: accepted$' "ADR 0014 is accepted" '^status: accepted$'
hasc "ADR 0014 supersedes ADR 0001" 'Supersedes ADR 0001'
hasc "ADR 0014 has considered options" '## Considered options'
hasc "ADR 0014 option: the two-tool review" '**The two-tool review ADR 0001 chose**'
hasc "ADR 0014 option: a per-row check list" '**A per-row check list**'
hasc "ADR 0014 option: a merger kept as a role" '**A merger kept as a role**'
hasc "ADR 0014 decides the ticket orchestrator lands its ticket" 'The ticket orchestrator lands its ticket'
hasc "ADR 0014 decides every tree is checked once" 'every tree is checked once'
fi
if doc 6 "ADR 0001" "$docs/adr/0001-two-stage-review.md"; then
hasc "ADR 0001 is superseded by 0014" 'status: superseded by ADR 0014'
hasc "ADR 0001 points at ADR 0014" 'docs/adr/0014-one-loop-at-three-rows.md'
fi

# ---- 7. /story-to-tickets ----
if doc 7 "/story-to-tickets" "$skills/story-to-tickets/SKILL.md"; then
has "spec fetch pointer" 'Fetch the spec as the tracker doc'"'"'s "fetch the spec" says'
has "story cutter trigger" '**Called, draft role ("story cutter"'
has "publish trigger" 'opens `Publish this block`'
hasc "design field read" '.[0].design'
lacks "owner-repo notes file" '\.spec-notes'
has "one test pointer" 'the one test'
has "home name in the Parent line template" 'home <home name>'
has "epic bead writes pointer" '"epic bead writes" convention'
# the pair is read per edge of the story DAG (ADR 0011): a dependent for each publish
# blocker, one bump per publish blocker, a dependency when it holds a publish ticket
has "pair read per edge" 'Dependency pair, per edge'
has "one bump per publish blocker" 'one bump per publish blocker'
has "brief carries a Dependency line per publish blocker" 'one `Dependency:` line per publish blocker'
has "brief carries a Dependent line per dependent" 'one `Dependent:` line per dependent'
# the two refusals: two publish tickets in one story, and a finished story pointing at add mode
has "two publish tickets refusal" 'refused: block carries two publish tickets; one PR publishes one version'
has "finished-story refusal names add mode" 'add mode (/dev:spec-to-stories <KEY>-<n>, or the epic bead id when the story has no key)'
has "finished story marked by add mode is re-cut" 'unless its notes carry a `recut:` line'
# a re-cut that gained a publish blocker adds a second bump and re-edges open tickets
has "re-cut adds a bump per new publish blocker" 'gained a publish blocker'
has "re-cut re-edges kept tickets onto the new bump" 'kept ones with `bd dep add <ticket id> <bump id>`'
has "re-cut matches a bump to its blocker by crate" 'a bump covers the blocker whose crate its title names'
has "publish ticket line shapes" 'a line names a publish ticket when it reads'
has "re-cut cites the tracker doc's per-edge rules" 'the tracker doc'"'"'s per-edge re-cut rules'

fi

# ---- 8. /implement-story: the deliver step pushes and opens the PR on the typed command's authority ----
if doc 8 "/implement-story" "$skills/implement-story/SKILL.md"; then
hasc "delivery rule pointer" 'the rules doc'"'"'s Delivery'
hasc "push command" 'git -C <owner> push -u origin <branch>'
hasc "refused push is a failed line" 'failed: push'
# a commit from outside the run (21f770c: a test whose throwaway init failed committed into the
# enclosing checkout) is refused before the push and before a merger's merge (dev-y1p)
hasc "deliver step's stray-commit check" 'First the **stray-commit check**, before any push'
hasc "the ticket orchestrator's landing runs the stray-commit check" 'run the **stray-commit check** on what the merge brings in'
hasc "stray-commit failed: line" 'failed: stray commit <sha> <subject>'
# the delivery records its tip and check record, which /dev:implement-spec's review set reads (dev-47z)
hasc "deliver step's delivered: note" 'note <story-id> "delivered: <tip SHA> <check record>"'
hasc "delivered: note ahead of the pr: note" 'It goes ahead of the `pr:` note'
hasc "finished story backfills a missing delivered: note" 'a finished story with no `delivered:` line'
lacks "profile-gated push" 'when the active profile permits|ask the user to run that exact command|give the user that exact command'
hasc "gitignore commit keyed on a dirty file" 'git -C <owner> status --porcelain -- .gitignore'
lacks "a gitignore hand-off from the story cut" 'the story cut appended|story cut could not commit'
hasc "a user edit in .gitignore is a failed: line, not absorbed" 'failed: <owner>/.gitignore has uncommitted edits'
hasc "exploration subagent reads the design field" '.[0].design'
hasc "exploration subagent owns the notes directory" '`<owner>/.spec-notes/<epic-id>/`'
# a failed ticket orchestrator's ticket is unclaimed at once, a second failure leaves the resume pointer on
# it, and the resume section says when a human runs the unclaim instead (chezmoi-jvc)
hasc "a failed ticket orchestrator's ticket is unclaimed" 'first `bd -C <owner> unclaim <id>`'
hasc "second failure notes the resume pointer" 'failed twice: <reason>; resume:'
hasc "hand unclaim condition in the resume section" 'by hand only when'
# the frontier keeps only ready-for-agent tickets, a deferred review finding is captured in the
# inbox through the retro capture and never as a story child, and a story counts as finished
# with an untriaged child under it (chezmoi-wgi; the Frontier rule itself is checked in 6)
hasc "frontier keeps ready-for-agent tickets only" 'keeping only the tickets labelled `ready-for-agent`'
lacks "frontier minus ready-for-human alone" 'minus `ready-for-human` tickets|other than `ready-for-human` ones|non-`ready-for-human`'
hasc "deferred findings go through the retro capture" '"capture a retro item"'
hasc "finished story tolerates untriaged children" '`needs-triage` or `wontfix`'
# the ticket orchestrator landing its ticket waits on the owner checkout's lock in one bounded
# foreground until-loop, not a check-and-sleep loop by hand (chezmoi-sn1, dev-9k5.1.7; the
# Waiting rule is checked in 6)
hasc "the landing waits on the lock with an until-loop" 'until ! [ -e <owner>/.git/index.lock ]'
hasc "the landing's lock wait is bounded by the call's timeout" 'timeout: 300000'
lacks "a lock wait sleeping and re-checking the lock by hand" 'waits [0-9]+ seconds|checks again|re-?checks the lock|checks every [0-9]+ seconds'
# the story orchestrator and the ticket orchestrator end their turn after spawning and are resumed
# by the completion notification; the ticket orchestrator and its subagents run Bash in the
# foreground only (chezmoi-p4q; the rule itself is checked in 6)
hasc "frontier spawn ends the turn" 'then end your turn: each ticket orchestrator'
hasc "ticket orchestrator's spawn ends the turn" 'then end your turn: its report'
hasc "the skill names the harness doc's Idle rule" "the harness doc's Idle rule"
# the implementer, fix-up and conflict-resolving implementer briefs (steps 2, 3 and 4's landing)
# give check and test runs an explicit ten-minute timeout, so the 120 s default never backgrounds
# them (dev-7k0, INFRA-30)
for step in 2 3 4; do
  line_has "^> $step\. " "the ticket orchestrator brief's step $step: check and test timeout" 'timeout: 600000'
done
line_has '^7\. ' "story fix-up brief names the check and test limit" 'the ten-minute limit on check and test runs'
# the per-ticket reviewer reads the standards the story review reads: the repo's own files and
# the plugin's coding-standards doc by its literal path (dev-co6)
for need in '`CODING_STANDARDS.md` or `CONTRIBUTING.md`' '<plugin root>/docs/agents/coding-standards.md` spelled as the path this session resolved'; do
  line_has '^> 3\. ' "the ticket reviewer brief's standards source" "$need"
done
# one story is one PR on `feat/<story-id>` (keyed or not); a finished story with an open agent
# ticket is guarded by one forge query; a story-closure wait says to merge and close; the
# sibling line carries the story id (chezmoi-9v4.1.5, ADR 0011)
hasc "integration branch is feat/<story-id> for keyed and keyless stories" 'named `feat/<story-id>`, keyed or not'
hasc "merge guard names the delivered story with an open agent ticket" 'a delivered story with an open `ready-for-agent` ticket'
hasc "merge guard covers a pr: line, a URL or the branch form" 'whose notes carry a `pr:` line'
hasc "merge guard's MERGED refusal says add mode" 'in add mode (or /dev:spec-to-stories'
hasc "merge guard's MERGED refusal closes the stray ticket" '; then close <ticket-id> (moved to the new story)'
hasc "step 3 defers to the forge decision of the merge guard" '(already decided in step 1 when the merge guard ran)'
hasc "merge guard decides the forge as step 3 does" 'the forge decided as step 3 says'
hasc "merge guard's Forgejo query names the repo" 'tea api --repo <owner> repos/{owner}/{repo}/pulls/<n>'
hasc "merge guard refuses a PR closed unmerged" 'CLOSED unmerged: refuse'
hasc "merge guard's add-mode hint covers an epic with no external ref" '(or /dev:spec-to-stories <epic-id> when the epic has no external ref)'
hasc "merge guard runs the forge query sandbox-disabled" 'with the sandbox disabled, as `/dev:close-story` step 4 does'
hasc "merge guard refuses a MERGED PR" 'MERGED: refuse'
hasc "merge guard: OPEN continues on the branch: note's branch" "OPEN: continue on the \`branch:\` note's branch"
hasc "merge guard asks when the forge cannot tell" '(no forge, or a branch-form `pr:` note)'
hasc "merge guard asks whether the PR or branch has merged" 'whether the PR, or for the branch form the branch, has merged into the default branch'
hasc "merge guard leaves the stray ticket until add mode carries its work over" 'until add mode has carried its work into a new story, so close it there then'
hasc "story-closure wait says to merge the PR and run /dev:close-story" 'merge its PR and run /dev:close-story <blocker-id>`'
hasc "a keyless story's branch is still feat/<story-id>" 'its branch is `feat/<story-id>`, as every story'"'"'s is (step 3)'
hasc "merge guard fires on a child that is not closed" 'while a child that is not closed (open, in_progress or blocked) is labelled `ready-for-agent`'
hasc "merge guard decides the branch form locally first" '`git -C <owner> merge-base --is-ancestor <tip SHA> origin/<default branch>`'
hasc "merge guard ends a spawned run with a failed: line" 'failed: <story-id> merge state unknown (<pr: value>): say whether it merged, then re-run'
hasc "merge guard summary says the branch form is decided locally first" 'the branch form or no forge is decided locally first, then asked (below)'
hasc "merge guard maps each ancestry exit and a failed fetch" '(exit 0: as MERGED; exit 1: as OPEN; a failed fetch of an existing origin or any other exit: it cannot decide (ask))'
hasc "merge guard skips the fetch with no origin" '`git -C <owner> fetch origin` (skipped with no `origin`), then'
hasc "merge guard finds the default branch as step 3 says" 'find `<default branch>` as step 3 says; with no `origin`, compare against the local `<default branch>`'
hasc "sibling line format carries the story id" '`<repo> <story-id> <url>`'
lacks "the sibling line as <repo> <url>" '`<repo> <url>`'
lacks "glossary's avoided term human ticket" '(^|[^-])human ticket'
# step 9 removes worktrees with the sandbox disabled up front (the sandbox denies deletes under
# .git/worktrees/ and no setting lifts that), never as a retry after the denial; it sweeps every
# worktree-agent-* and .worktrees/ worktree whose branch is merged into the integration branch,
# earlier runs' included, and reports a locked or unmerged one in the worktrees: line instead of
# forcing it (chezmoi-73d)
hasc "worktree removal runs sandbox-disabled up front" 'worktree prune` run with the sandbox disabled'
lacks "worktree removal retried sandbox-disabled only after the denial" 'retry that one command with the sandbox disabled'
hasc "the sweep covers harness and hand-rolled worktrees" 'whose branch is `worktree-agent-*` or whose path is under `<owner>/.worktrees/`'
hasc "the sweep is keyed on the branch being merged into the integration branch" 'merged into `<branch>`'
lacks "the sweep limited to this run's worktrees" 'every worktree the run made'
hasc "a locked or unmerged worktree is reported, not removed" 'reported with its path'
lacks "a locked or unmerged worktree forced" 'worktree remove[^`]* -(-force|f)'
hasc "report template shows the worktrees: line" 'worktrees: <absolute path>'
hasc "the worktrees: line appears only with content" '`waiting:` and `worktrees:` lines appear only when they have content'
lacks "the resume: line printed only with content" '`resume:` lines appear only'
# the implementer, fix-up and conflict-resolving briefs start with the
# TMPDIR line, stated once in the Owner repo section with its two riders and named in the ticket
# orchestrator brief's steps 2, 3 and 4 (the landing) and the story review's fix-up (step 7); the
# Gitignore step counts the rule's four
# entries, /.tmp/ included (chezmoi-3eg)
hasc "TMPDIR line stated in the skill" 'mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp'
hasc "export repeated per Bash call" 'repeated at the head of every Bash call'
hasc "mktemp -d takes a template under .tmp" 'mktemp -d <worktree>/.tmp/<name>.XXXXXX'
# the ticket orchestrator reads the harness doc, not this skill, so its brief points there
hasc "ticket orchestrator brief points at the harness doc's TMPDIR rule" "the harness doc's TMPDIR rule"
for step in 2 3 4; do
  hase "ticket orchestrator step $step's brief starts with the TMPDIR line" "^> $step\. .*TMPDIR line"
done
hase "the story review's fix-up brief starts with the TMPDIR line" '^7\. .*TMPDIR line'
hasc "Gitignore step counts four entries" "the rule's four entries"
lacks "Gitignore step counts three entries" "the rule's three entries"
# the reviewer brief in the ticket orchestrator's step 3 carries the two tags with their definitions and
# the verdict line (the reviewer never reads the rules doc), and step 3 and the story review's
# step 7 point at the rules doc's Review verdict for what a clean round does; the retired bar,
# clean as no finding at all, is gone (chezmoi-49k). The brief's phrases are read on the step 3
# line alone, since step 7 carries the same ones
for phrase in 'verdict: clean' 'verdict: blocking (<n>)' '**blocking** or **minor**' 'within the budget above'; do
  line_has '^> 3\. ' "ticket orchestrator step 3's reviewer brief" "$phrase"
done
hase "ticket orchestrator step 3 points at the rules doc's Review verdict" "^> 3\. .*the rules doc's Review verdict"
hase "the story review (step 7) points at the rules doc's Review verdict" "^7\. .*the rules doc's Review verdict"
lacks "the zero-findings bar" 'not clean after three rounds|no findings at all|clean means zero findings'
# the brief states its row of the rules doc's table, the check command by Makefile convention
# (none: review-only) and cites the harness doc in one line; step 3's lint-command resolution,
# the old brief's lint header and its step 2 lint list are retired (dev-9k5.1.7). Each row
# parameter is its own pin, with its own description
H='^> You are the \*\*ticket orchestrator\*\*'
hase "the brief opens on the ticket orchestrator" "$H"
for pin in "your row is the ticket row of the rules doc's table|the brief names its row of the rules doc's table" \
  'you build with one implementer in a worktree|the row builds with one implementer in a worktree' \
  'check with the check command|the row checks with the check command' \
  "review the ticket's body as the spec axis and the ticket diff as the standards axis, one tier up, none at \`low\` with a check command|the row reviews the ticket body and diff one tier up, none at low with a check command" \
  'fix up by pointer brief in the same worktree|the row fixes up by pointer brief in the same worktree' \
  'land by merging onto `<branch>` under the lock after the stray-commit check|the row lands by merging under the lock after the stray-commit check' \
  'exit when the checks are green on the tip the review called clean|the row exits on green checks at the tip the review called clean' \
  'three fix-ups|the row budgets three fix-ups'; do
  line_has "$H" "${pin#*|}" "${pin%%|*}"
done
line_has "$H" "the brief's check command by Makefile convention" 'check command `make check` when `<owner>`'"'"'s Makefile has a `check` target, else none and the gate is review-only'
line_has "$H" "the brief cites the harness doc in one line" 'The harness mechanics are in `<plugin root>/docs/agents/harness.md`'
line_has "$H" "every brief it sends cites the harness doc" 'every brief you send cites it in one line'
line_has "$H" "a missing Makefile reads as no check command" "a missing Makefile (grep's exit 2) reads as no check command"
lacks "the retired lint-command resolution" 'resolve the owner repo.s \*\*lint command\*\*|`make lint` when `<owner>`.s makefile has a `lint` target'
lacksf "the retired lint placeholder" '`<lint>`'
# the ticket orchestrator's check and review loop sits between the implementer (step 2) and the
# landing (step 4) as one step: it opens step 3 for every tier, checks ahead of the reviewer; each check
# is one logged Bash call under the worktree's .tmp/; a red is noted on the ticket; a red and a
# blocking verdict both spawn a fresh implementer on the fix-up and start the loop over from the checks,
# on one budget of three fix-ups; a low ticket exits on green; the implementer runs no checks
# (dev-cq0.1.4, dev-1xf.1.2)
G3='^> 3\. \*\*Check gate\*\*, every tier'
hase "ticket orchestrator step 3 opens with the check gate, every tier" "$G3"
line_has "$G3" "the loop step cites the rules doc's loop" "as the rules doc's Check gate says"
line_has "$G3" "a red starts the loop over from the checks" 'A red spawns a fresh implementer on the fix-up and the loop starts over from the checks'
line_has "$G3" "a blocking verdict starts the loop over from the checks, never straight to the reviewer" 'a blocking verdict spawns a fresh implementer on the fix-up and the loop starts over from the checks, never straight to the reviewer'
line_has "$G3" "a clean verdict exits the loop" '**Clean** exits the loop'
line_hase "$G3" "the check gate runs before step 3's reviewer" '\*\*Check gate\*\*.*Green:.*for `medium` and `high`, spawn a \*\*reviewer\*\*'
unchanged_file || ! grep -E "$G3" "$f" | sed 's/Green: .*//' | grep -qF -- 'spawn a **reviewer**' || bad "present: ticket orchestrator step 3 spawns a reviewer ahead of the checks' green"
line_has "$G3" "a low ticket exits the loop on green checks" 'Green: a `low` ticket exits the loop, go to step 4'
line_has "$G3" "a low ticket with no check command goes on to the reviewer" 'the gate is review-only, so a `low` ticket goes on to the reviewer as `medium` and `high` do (the rules doc'"'"'s Check gate)'
line_has '^> 2\. ' "ticket orchestrator step 2's implementer runs no gate and spawns no one" 'The implementer runs no gate and spawns no one'
# the check record (dev-9k5.1.7): keyed by the tree SHA under the owner checkout's .tmp/checks/,
# written only by the ticket orchestrator, a tree with a record not checked again
line_has "$G3" "the gate keys the check on the tree SHA" '`git -C <worktree path> rev-parse HEAD^{tree}`'
line_has "$G3" "the gate reads the tree only of a clean worktree" 'First confirm the worktree is clean, `git -C <worktree path> status --porcelain` prints nothing; a dirty worktree goes to a fresh implementer as a red does'
line_lacks "$G3" "the clean-worktree guard that hides untracked files" '`git -C <worktree path> status --porcelain --untracked-files=no`'
line_has "$G3" "a tree with a check record is not checked again" 'a tree with a record is checked: read its exit and run nothing'
line_has "$G3" "the gate writes the check record per tree" 'mkdir -p <worktree path>/.tmp; mkdir -p <owner>/.tmp/checks/<tree>; export TMPDIR=<worktree path>/.tmp; make -C <worktree path> check > <owner>/.tmp/checks/<tree>/log 2>&1; echo "command=make check exit=$?" > <owner>/.tmp/checks/<tree>/record; cat <owner>/.tmp/checks/<tree>/record'
line_has "$G3" "no check command makes the gate review-only" 'With no check command the checks are skipped and the gate is review-only'
line_has "$G3" "the gate reviews with mattpocock-skills:code-review" '`mattpocock-skills:code-review`'
line_has "$G3" "the reviewer brief names the harness-route diff" '`git -C <worktree path> diff <branch>...HEAD`'
line_lacks "$G3" "the per-round check log" 'checks-<round>-<k>.log'
line_has "$G3" "a red gate reads a forty-line tail of the log, never the whole output" 'tail -n 40 <log>'
line_has "$G3" "a red gate's note form (checks <round>: red <command>)" '`bd -C <owner> note <ticket-id> "checks <round>: red <command>"`'
line_has "$G3" "a green gate writes no note" 'a green writes no note'
line_has "$G3" "the gate's fix-up brief points at the log path" 'the log path, and no pasted output'
line_has "$G3" "red and blocking fix-ups share one budget of three, the fourth failure is failed" 'The budget is three fix-ups of either cause; the fourth red or blocking verdict is `failed`'
line_has "$G3" "the minors fix-up after a clean verdict spends no budget and advances no round" 'The minors fix-up spends no budget and advances no round'
lacks "the retired run-the-gate-again wording" 'run the check gate again, and on green spawn a reviewer again'
# the ticket orchestrator lands its own ticket (step 4): lock wait, stray-commit check, merge; a
# conflict goes to an implementer in the ticket's worktree, then a fast-forward; the resolved
# tree is checked and not reviewed again; the old separate merge brief is retired (dev-9k5.1.7)
L4='^> 4\. \*\*Land the ticket\*\*'
hase "step 4 lands the ticket" "$L4"
line_has "$L4" "a conflict goes to an implementer in the ticket's worktree" 'A conflict goes to an implementer in the ticket'"'"'s worktree'
line_has "$L4" "the conflict implementer merges the integration tip into the ticket branch" 'briefed to merge `<branch>`'"'"'s tip into the ticket branch'
line_has "$L4" "a conflicted merge is aborted, never resolved by the orchestrator" '`git -C <owner> merge --abort`'
line_has "$L4" "the orchestrator then fast-forwards" '`git -C <owner> merge --ff-only <ticket branch>`'
line_has "$L4" "the resolved tree is checked and not reviewed again" 'step 3'"'"'s checks run on the resolved tree and no reviewer runs'
# a red on the resolved tree goes to a fix-up that spends budget and restarts the whole loop,
# review included: the rules doc exempts only the minors fix-up and the resolution (story
# dev-9k5.1 review)
line_has "$L4" "a red after a resolution restarts the whole loop, review included" 'restarts step 3'"'"'s whole loop, review included'
line_lacks "$L4" "a red fix-up after a resolution skipping its review" 'starts over from the checks only'
# the story gate (step 7) is the rules doc's Check gate loop on the integration branch tip, the
# story row of its table (dev-9k5.1.9): it exits when the checks are green on the tip the review
# called clean; each pass reads the checks from the check records first (a recorded tree runs
# nothing, an unrecorded one is checked once in the clean owner checkout and recorded), then
# compares the reviewed tip the story keeps in its review: note; the review's spec axis is the
# story's body and its standards axis what entered since the ticket reviews; a red or a blocking
# verdict goes to a fresh fix-up and the loop starts over, three per story, the fourth failed; the
# minors fix-up reruns the checks and spends nothing; the story orchestrator lands its fix-up
# itself, no separate landing agent (section 5 sweeps the merger); "Running the checks" is gone. Step 8 leaves the PR a
# draft, its Evidence the delivered tip's check record; step 9 removes the records
G7='^7\. '
hase "step 7 is the story gate" '^7\. \*\*Story gate\.\*\*'
line_has "$G7" "the story gate names its row of the rules doc's table" "the story row of the rules doc's table"
line_has "$G7" "the story gate exits on green checks at the tip the review called clean" 'it exits when the checks are green on the tip the review called clean'
line_has "$G7" "the story gate runs the checks first in each pass" 'Each pass runs the checks first'
line_has "$G7" "the story gate reads the tree only of a clean owner checkout" 'confirm the owner checkout is clean, `git -C <owner> status --porcelain` prints nothing'
# the guard (dev-9k5.1.9 review 1): the owner checkout on <branch>, untracked files counted and
# why, the failed line naming the files, its exit classified as step 6 says
line_has "$G7" "the story gate confirms the owner checkout is on the integration branch" '`git -C <owner> branch --show-current` prints `<branch>`'
line_has "$G7" "the story gate's off-branch failed line" '`failed: <story-id> not on <branch>`'
line_has "$G7" "the story gate's clean-checkout guard says why untracked files count" 'untracked files count, since the check runs on the working tree while the record keys on the committed tree'
line_has "$G7" "the dirty-checkout failed line names the files" '`failed: <story-id> owner checkout dirty: <files>`, `<files>` the paths that status call printed, classified as step 6 says'
line_has "$G7" "the story gate keys the check on the tip's tree" '`git -C <owner> rev-parse <branch>^{tree}`'
line_has "$G7" "the story gate reads a recorded tree's check record and runs nothing" 'a tree with a record is checked: read its exit and run nothing'
# the check-record call is defined once, in the ticket orchestrator brief's step 3, and step 7
# names it with <owner> for the worktree path (dev-9k5.1.9 review 1)
line_has "$G7" "the story gate writes the check record with the brief's step 3 call" "the ticket orchestrator brief's step 3 check-record call with \`<owner>\` as its \`<worktree path>\`"
line_lacks "$G7" "a second copy of the check-record call" 'check > <owner>/.tmp/checks/<tree>/log'
line_has "$G7" "the story keeps the reviewed tip in its notes" "The story keeps the reviewed tip in its notes: its \`review:\` note names the tip the gate exits on after a clean review, so a rerun reviews only a tip that has moved past it"
# the story review round is numbered on from the notes, not from 1 per run, and its note names
# the tip it read (dev-9k5.1.9 review 1)
hasc "step 1 reads the story review notes" '`review:` and `story review <round>` (step 7)'
line_has "$G7" "the story review round continues across runs" "\`<round>\` one more than the last \`story review\` note's round step 1 read (1 when there is none)"
line_has "$G7" "the story review note names the reviewed tip" '`bd -C <owner> note <story-id> "story review <round> <tip SHA>: <findings>; <verdict line>"`'
line_has "$G7" "a green tip the review called clean exits the gate" 'the same SHA exits the gate'
line_has "$G7" "the story review's spec axis is the story's body" "the spec axis is the story's body"
line_has "$G7" "the story review's standards axis is what entered since the ticket reviews" 'the standards axis is what entered since the ticket reviews: the conflict resolutions and the coherence across tickets'
# the standards axis gets its inputs: the base SHA, each merge's resolution and the fix-up
# commits since the last story review (dev-9k5.1.9 review 1)
line_has "$G7" "the story review names the base SHA" '`<base>`, `git -C <owner> merge-base <default branch> <branch>`'
line_has "$G7" "the standards axis gets each merge's resolution" '`git -C <owner> show --remerge-diff <merge>`'
line_has "$G7" "the standards axis gets the fix-up commits since the last story review" "\`git -C <owner> log --no-merges --grep='^Bead: <story-id>\$' <since>..<branch>\`"
line_has "$G7" "a red or a blocking verdict goes to a fresh fix-up and starts the loop over" 'A red or a blocking verdict goes to a fresh implementer by pointer brief and the loop starts over'
line_has "$G7" "the minors fix-up reruns the checks and spends no budget" 'the minors fix-up reruns the checks and spends no budget'
line_has "$G7" "the story gate's budget is three fix-ups, red or blocking" 'The budget is three fix-ups per story, red or blocking alike'
line_has "$G7" "the story gate's fourth failure skips delivery" 'the fourth failure skips step 8 and goes to step 9'
line_has "$G7" "the story gate's stall line" '`failed: <check> <command>`'
line_has "$G7" "the story gate's stall line for a review" "(a review's as \`failed: review mattpocock-skills:code-review\`)"
line_has "$G7" "the story gate lands its fix-up itself" "you land its branch as the ticket orchestrator brief's step 4 lands a ticket"
line_lacks "$G7" "the story gate's minors fix-up spending budget" "a minors-only review's included"
lacksf "the retired Running the checks paragraph" '**Running the checks.**'
# on the first step 7 line, the checks come before the reviewed-tip compare and the review
unchanged_file || awk -v g='Each pass runs the checks first' -v m='the same SHA exits the gate' -v r='mattpocock-skills:code-review' \
  '/^7\. / { i = index($0, g); k = index($0, m); j = index($0, r); ok = (i && k && j && i < k && k < j); seen = 1; exit } END { exit !(seen && ok) }' "$f" \
  || bad "missing: the story gate (step 7) runs the checks before the reviewed-tip compare and the two-axis review"
line_has '^8\. ' "the deliver step leaves the PR a draft" 'The PR stays a draft'
line_lacks '^8\. ' "the deliver step marking the PR ready" 'gh pr ready'
line_lacks '^8\. ' "the deliver step marking the PR ready with tea" 'tea pr edit <n> --repo <owner> --ready'
line_has '^8\. ' "the deliver step's Evidence is the delivered tip's check record" "its Evidence the delivered tip's check record"
line_has '^9\. ' "step 9 removes the check records" '`rm -rf <owner>/.tmp/checks`'
# a run that ends failed on a red keeps the red tree's log in place for the human, the
# failed: line's words unchanged, while every other run still removes the records (dev-15s)
line_has '^9\. ' "step 9 keeps the red check's log on a failed: check run" 'skips the removal and keeps the red check'"'"'s log in place'
line_has '^9\. ' "step 9 still removes the records on every other run" 'Every other run, a green delivery or one failed for any other reason, removes the records'
hasc "report template's failed: line names the check" 'or <check> <command>'
# the report marks the PR a draft and always carries the resume line (dev-9k5.1.9 review 1)
hasc "report template marks the PR a draft" 'PR:      <url> (draft)'
hasc "the resume: line always appears" 'the `resume:` line always appears'
lacks "the retired Evidence phrase" 'the command and its output'

fi

# ---- 9. /close-story: the ticket check counts children as the finished-story definition does ----
if doc 9 "/close-story" "$skills/close-story/SKILL.md"; then
# a child carrying needs-triage or wontfix is a note with nothing to implement, not a ticket
# to wait for; any other open child is named with its status and label, so the remedy is
# readable from the refusal line (chezmoi-afn)
hasc "ticket check skips untriaged children" 'carries `needs-triage` or `wontfix`'
hasc "refusal names status and label" 'open tickets <child> <status> <label>'
lacks "refusal without the label" 'open tickets <child> <status>, \.\.\.'
# the Forgejo/Gitea query names the story's repo, as the intro promises for every forge
# command and as /implement-story's merge guard does; without --repo, a workspace session
# reads whichever repo the shell sits in (dev-hac)
hasc "Forgejo/Gitea query names the repo" 'tea api --repo <path> repos/{owner}/{repo}/pulls/<n>'
lacks "Forgejo/Gitea query without --repo" 'tea api repos/'

fi

# ---- 10. the story DAG in the tracker and orchestration docs (ADR 0011) ----
# a feature's stories form a DAG of text blockers, each naming a human gate ticket or a story;
# the one-text-blocker and no-chains rules are retired. Section 5 sweeps "only text blocker"
# and "chains are out of scope"; the wider chains wording is scoped to these two docs.
for d in "$agents/issue-tracker.md" "$agents/orchestration.md"; do
  doc 10 "story DAG" "$d" || continue
  has "story DAG" 'story DAG'
  has "human gate ticket" 'human gate ticket'
  # read as one line, so a phrase wrapped across a line break is still caught; the match stops
  # at a period, so it spans a paragraph break only where a paragraph ends without one. Section
  # 5's "chains are out of scope" is blanked first, so a seed of it fails there alone
  unchanged_file || ! tr -s '[:space:]' ' ' < "$f" | tr '[:upper:]' '[:lower:]' | sed 's/chains are out of scope//g' \
    | grep -qE -- 'chains[^.]{0,120}out of scope' || bad "present: retired story-DAG wording in $f (chains[^.]{0,120}out of scope)"
done
# a story held only by a story-closure blocker ends the run as a human stop naming the merge
# and the /close-story; a publish ticket waits on its story's tickets, not its repo's
f=$agents/orchestration.md
if [ -f "$f" ]; then
section "10. story DAG: $f"
hasc "story-closure human stop" 'merge its PR, then run `/dev:close-story <story-id>`'
has "publish ticket ready on its story's tickets" "as soon as its story's implementation tickets close"
lacks "publish ticket ready on its repo's tickets" "its repo's implementation tickets close"
fi
# the story body shows only blocker lines a step fills; a middle story of a chain is ordered
f=$agents/issue-tracker.md
if [ -f "$f" ]; then
section "10. story DAG: $f"
lacks "gate ticket line no step fills" '<repo> <gate ticket id>'
# the story cut writes a story line or a publish placeholder (step 2's skipped form too), so
# "the only lines" of step 4 would contradict step 2
has "story cut writes no gate ticket id" 'never a line naming a gate ticket id'
lacks "story cut's lines contradict step 2" 'the only lines the story cut writes'
has "middle story of a chain" 'in the middle of a chain'
# a repo session may hold several home stories, each the epic bead's child, or the stories
# gather (bd children <epic-id>) misses one; the ticket cut is one topological pass, since a
# dependency wave is one batch of cutters per DAG level and never splits a story
has "every repo-session story under the epic" '# repo session: every story'
lacks "one home story with a parent" 'Only the home story has a parent'
has "ticket cut in one topological pass" 'one topological pass'
# the pass is per story, not per edge: a dependent with two publish blockers gets every bump
# before its other tickets (steps 4 and 5)
has "ticket cut ordered per story" 'one topological pass over the stories'
lacks "ticket cut ordered per edge" 'one topological pass over the edges'
lacks "middle story split across waves" 'opens its own wave'
has "deploy split waits on the earlier story's closure" 'that `/dev:close-story` requires closed'
# a re-cut blocks every open ticket but the bumps on every bump, so no bump blocks on itself
# or on another bump and step 5 holds
has "re-cut exempts the bumps" 'every open ticket of the story that is not a bump'
lacks "re-cut blocks a bump on itself" 'every open ticket of the story is blocked'

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
    # test runs this over every doc a few hundred times
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
  case "$f" in "$docs/specs/"*) ;; *) cmds "$tok" ;; esac
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
hasc "the directory-wide timeout" 'timeout: 600000'
hasc "the 120-second default named" '120-second default'
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
done < <(awk '
  FNR == 1 {inq=0} /^[[:space:]]*>/ {inq=1} /^[[:space:]]*$/ {inq=0}
  inq && /CLAUDE_PLUGIN_ROOT/ {print FILENAME "\t" FNR "\t" $0}' "${brief_files[@]}")

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

checks_run
[ "$fail" = 0 ] && echo "PASS"
exit "$fail"
