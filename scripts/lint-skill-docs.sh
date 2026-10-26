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
#      no "driver" and no PR opened here;
#   2. the human runbook docs/WORKFLOW.md (chezmoi-0jp.25) and the /workflow skill:
#      names only commands that exist, no stale cross-repo wording, the cut skills' argument
#      written in the runbook and filled in on /workflow's next lines (chezmoi-nz0);
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
#   4. the /spec-to-tickets driver: user-typed, the same argument rule as 3, the refusals,
#      cutters pointed at the waiting rule and without a model override, explicit dependent
#      lines, the closed and publish-failed lines, a Jira comment over every story, no
#      story-cut procedure; the cycle refusal, topological waves with every upstream
#      breakdown in a dependent's brief, the inline re-cut of an already cut dependent keyed on
#      its missing bump, a finished dependent excluded at step 1, a skipped repo's publish line
#      as an edge with no dependency, the held-back cascade narrowed to a dependency without
#      its publish ticket, and no two-wave cap (ADR 0011);
#   (3, 4 and 1 point at the shared preflight and epic gather that section 6 checks; 3, 4 and 7
#   cite the "epic bead writes" convention that section 6 checks)
#   5. the agent docs and every file under the skills dir: no retired "cut one", "cut two" or
#      <spec-slug>, as whole words, and no story-cut.md (the notes moved to the story bead's
#      design field, chezmoi-cdf); and across those, the project CLAUDE.md and the runbook:
#      none of the retired walk-up phrases ("nearest ancestor", "walking up", "walk up",
#      "one level up", "the home repo included", "the workspace root included",
#      "no repos.yaml above", "workspace inbox", "workspace's inbox", the "home repo <home repo>"
#      Parent form), and no "run_in_background: false" in any skill or agent doc, since no
#      foreground spawn exists (chezmoi-p4q).
#      That one list is the only walk-up check; sections 2-4 and 7 do not repeat it; the same
#      four file kinds also lack the retired story-DAG wording ("one story per repo", feat/<key>-<n>,
#      "chains are out of scope", "only text blocker", "two waves suffice"; ADR 0011);
#      and the check and review loop's retired two-gate wording ("Evidence run", "a later run
#      reviews the fix", "a third round of either kind", "a second red") is absent from those,
#      the root GLOSSARY.md and docs/SEQUENCES.md, never docs/specs (dev-1xf.1.4);
#   6. the shared rules: orchestration.md's working-directory preflight, and harness.md's
#      waiting rule (an Agent call returns at once, the orchestrator ends its turn and the
#      completion notification resumes it, never a Bash poll loop; pgrep is dead in the
#      sandbox) with its idle rule (Bash in the foreground only below the driver, chezmoi-p4q), the
#      model (dev-9k5.1.3): the loop sentence, the table's header and each of its three rows, the
#      two scoping rules, the six trust rules as a closed list, the check command, the check record
#      and the one gate exit, the seam-test blocking case and the one review tool, with the two-level
#      loop's lint-first order, its review-marker exit and the built-in code-review retired; ADR 0014 (its
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
#      and owns .spec-notes/<epic-id>/ (chezmoi-cdf), and a ticket whose runner failed is
#      unclaimed before the next frontier read, with the resume pointer noted on a second
#      failure and step 9's resume: line naming when a human runs the unclaim (chezmoi-jvc;
#      the Frontier's unclaim rule is checked in 6), its frontier read keeps ready-for-agent
#      tickets only, its review step captures deferred findings in the inbox through the
#      retro capture, its finished story tolerates an untriaged child (chezmoi-wgi), and its
#      merger waits on the owner lock in one bounded until-loop, never a check-and-sleep loop
#      by hand (chezmoi-sn1), and its frontier spawn and the ticket runner brief end the turn
#      after spawning and carry the idle rule (chezmoi-p4q), and its integration branch is
#      feat/<story-id> keyed or not, a delivered story with an open agent ticket passes one
#      merge guard (MERGED, CLOSED unmerged, OPEN, ask), a story-closure wait says to merge
#      and run /close-story, and the sibling line is <repo> <story-id> <url> (chezmoi-9v4.1.5,
#      ADR 0011), and its clean-up step removes worktrees with the sandbox disabled up front,
#      sweeps every worktree-agent-* and .worktrees/ worktree whose branch is merged into the
#      integration branch, earlier runs' included, and reports a locked or unmerged one in the
#      report's worktrees: line instead of forcing it (chezmoi-73d), and its implementer,
#      fix-up implementer and merger briefs start with the TMPDIR line, whose rule section 6
#      checks in orchestration.md (chezmoi-3eg), and its reviewer brief tags every finding
#      blocking or minor and ends on the verdict line, its runner step 3 and story review step 7
#      pointing at the rules doc's Review verdict, whose rule section 6 checks (chezmoi-49k),
#      and its step 3 resolves the owner's lint command once, which the runner brief's header
#      and every brief it sends carry, runner step 2 taking it from the brief (dev-cq0.1.2),
#      and its story review is the check gate loop with the review marker as its exit, a red
#      or a reviewed tip starting it over, a fourth failure stalling with failed: <check>
#      <command>, the exit iteration's run (each check's command, exit and tail) the Evidence
#      cited in step 8, and "the command and its output" gone (section 5's sweep covers the
#      Evidence run and the second-red stall) (dev-cq0.1.5, dev-1xf.1.3); section 6 checks the
#      rules doc's Check gate;
#   9. /close-story: its Forgejo/Gitea query carries --repo <path> as the intro and
#      /implement-story's merge guard do (dev-hac); its ticket check skips a child carrying
#      needs-triage or wontfix, as the finished story does, and its refusal names each open
#      child's status and label (chezmoi-afn);
#  10. the tracker and orchestration docs: both name the story DAG and the human gate ticket,
#      and neither says "only text blocker" nor puts chains out of scope; the orchestration
#      doc ends a story-closure wait as a human stop and readies a publish ticket on its
#      story's tickets; the tracker doc's story body shows no unfillable gate ticket line
#      and orders a middle story of a chain in one topological pass, creates every
#      repo-session story under the epic bead, and makes a deploy split wait on the
#      earlier story's closure (ADR 0011).
#  11. the namespace rule: in every .md file under the skills dir, docs/ (the agent docs, ADRs, specs),
#      the runbook, the project CLAUDE.md, the root GLOSSARY.md and the driver passed as $1, a
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
#      orchestration skills send to runners, cutters, implementers, reviewers and mergers) never
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
set -u
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail=0
bad() { echo "FAIL: $*"; fail=1; }
# has (grep -iF), hasc (-F), hase (-E), lacks (-iE), lacksf (-iF) and lackse (-E) check <pattern>
# against $f line by line, as those greps would; line_has (-F), line_hase (-E) and line_lacks (-F) check it
# on the lines matching <anchor> (-E), as a grep -E <anchor> | grep -q pipeline would; para_has
# (-iF) on the first paragraph opening with <heading> (that line to the next empty one), and
# opening_has (-F) on the lines before the first "## ". Each only queues its check: a section's
# checks run in one awk pass when the next section opens (section) and at the end (checks_run),
# so their FAIL lines print under their own section's header, at a cost of one process per
# section rather than one or two per check (the regression test runs the lint a few hundred
# times, and its pool is CPU-bound).
queue=
has() { queue+="i	$f	$1	$2"$'\n'; }
hasc() { queue+="c	$f	$1	$2"$'\n'; }
hase() { queue+="e	$f	$1	$2"$'\n'; }
lacks() { [ -f "$f" ] || return 0; queue+="x	$f	$1	$2"$'\n'; }
lacksf() { [ -f "$f" ] || return 0; queue+="f	$f	$1	$2"$'\n'; }
lackse() { [ -f "$f" ] || return 0; queue+="y	$f	$1	$2"$'\n'; }
line_has() { queue+="a	$f	$2	$3	$1"$'\n'; }   # <anchor> <description> <phrase>
line_hase() { queue+="A	$f	$2	$3	$1"$'\n'; }   # <anchor> <description> <pattern>
line_lacks() { [ -f "$f" ] || return 0; queue+="X	$f	$2	$3	$1"$'\n'; }   # <anchor> <description> <phrase>
para_has() { queue+="p	$f	$2	$3	$1"$'\n'; }   # <heading> <description> <phrase>
opening_has() { queue+="o	$f	$1	$2"$'\n'; }
# run the queued checks: a missing pattern or a present lacks one is a FAIL line; a lacks, lacksf
# or lackse one is followed by its first three matching lines, numbered as grep -n numbers them,
# an anchored one names its anchor, a paragraph or opening one the scope it searched
checks_run() {
  local out
  [ -n "$queue" ] || return 0
  out=$(printf '%s' "$queue" | LC_ALL=C awk -F '\t' '
    { k[NR] = $1; d[NR] = $3; p[NR] = $4; lp[NR] = tolower($4); a[NR] = $5
      if (!($2 in nat)) files[++nf] = $2
      at[$2, ++nat[$2]] = NR }
    END {
      for (j = 1; j <= nf; j++) {
        fn = files[j]; ln = 0
        while ((getline line < fn) > 0) {
          ln++; low = tolower(line)
          for (m = 1; m <= nat[fn]; m++) {
            i = at[fn, m]; t = k[i]
            if (t == "i") { if (index(low, lp[i])) hit[i] = 1 }
            else if (t == "c") { if (index(line, p[i])) hit[i] = 1 }
            else if (t == "e") { if (line ~ p[i]) hit[i] = 1 }
            else if (t == "x") { if (low ~ lp[i] && ++hit[i] <= 3) shown[i] = shown[i] ln ":" line "\n" }
            else if (t == "f") { if (index(low, lp[i]) && ++hit[i] <= 3) shown[i] = shown[i] ln ":" line "\n" }
            else if (t == "y") { if (line ~ p[i] && ++hit[i] <= 3) shown[i] = shown[i] ln ":" line "\n" }
            else if (t == "a" || t == "X") { if (line ~ a[i] && index(line, p[i])) hit[i] = 1 }
            else if (t == "A") { if (line ~ a[i] && line ~ p[i]) hit[i] = 1 }
            else if (t == "p") {
              # the paragraph opens on its heading line and closes for good at the next empty line
              if (!closed[i]) {
                if (index(line, a[i]) == 1) on[i] = 1
                if (on[i]) { if (line == "") closed[i] = 1; else if (index(low, lp[i])) hit[i] = 1 }
              }
            }
            else if (t == "o") { if (index(line, "## ") == 1) closed[i] = 1; if (!closed[i] && index(line, p[i])) hit[i] = 1 }
          }
        }
        close(fn)
      }
      for (i = 1; i <= NR; i++) {
        t = k[i]
        if (t == "x" || t == "f" || t == "y") { if (hit[i]) printf "FAIL: present: %s (%s)\n%s", d[i], p[i], shown[i] }
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
merge_scan=$(sed 's/the PR to merge//gI' "$f")
if grep -qi 'merge' <<<"$merge_scan"; then
  bad "present: merge steps (merge)"; grep -ni 'merge' <<<"$merge_scan" | head -3
fi
has "story-closure blocker is open until closed" 'open until that story is closed'
has "story-closure human stop line" 'the PR to merge and the /dev:close-story <story-id> to run'
has "human stop line carries the PR url" '<owner repo> <story-id> <pr url>'
has "human stop trigger covers story closures" 'held only by blockers naming finished stories not yet closed'
has "chain of story closures counts toward the human stop" 'itself waits only on story closures'
has "add-mode hint keyed on the failed twice: note" 'carries a `failed twice:` note'
has "add-mode stall hint" '/dev:spec-to-stories <KEY>-<n>'
has "add-mode stall hint without an external ref" '/dev:spec-to-stories <epic-id>'
has "final report waiting: names a finished story" 'a finished story not yet closed'
hasc "report template shows the story-closure human: line" 'human:   <owner repo> <story-id> <pr url>'
# the glossary avoids "human ticket" for the human gate ticket ("ready-for-human ticket" is fine)
lacks "glossary's avoided term human ticket" '(^|[^-])human ticket'
# the epic row reviews and marks ready, but opening a PR stays the story orchestrator's
lacks "PR-opening steps" 'draft PR|pr create'
lacks "the retired driver role" '(^|[^a-z])driver'
hasc "epic orchestrator role" '**epic orchestrator**'
has "harness doc cited" 'docs/agents/harness.md'
has "epic review, one PR at a time" 'one PR at a time'
has "epic review diff" 'the diff from the default branch to the integration branch'
has "epic review spec axis" "the Jira Epic's spec"
has "epic review skips the standards axis" 'no standards axis'
has "epic review model" "the review model of the epic's max tier"
has "draft until clean" 'stays a draft until its verdict is clean'
has "mark ready with gh" 'gh pr ready <n> --repo <forge-slug>'
has "mark ready with tea" 'tea pr edit <n> --repo <owner> --ready'
has "fix-up: one ready-for-agent ticket per blocking finding" 'one per blocking finding'
has "fix-up: the story re-run in add mode" 'in add mode'
has "fix-up budget" 'three per story'
has "fix-up budget's fourth" 'the fourth is `failed`'
hasc "report template's epic review line" 'review:  <verdict line>'
has "Done needs a clean epic review" 'epic review clean'
# epic review 1 of dev-9k5.1.8
has "preflight covers the review set" 'every story step 6 reviews'
has "mark-ready recorded as a ready: note" 'ready: <tip SHA>'
has "a clean draft's checks are re-polled" 're-poll its checks'
has "review set: open stories with an open PR" 'only open stories with an open PR'
has "every fix-up round spends the budget" 'every fix-up round, red or blocking'
lacks "a budget of blocking verdicts only" 'three blocking verdicts'
has "Done reads the ready: note" 'its `ready:` note on its current tip'
has "PR number placeholder defined" "the PR number from the story's \`pr:\` note"
has "cut-off reviewer rule" 'reviewer that returns an error instead of a report'
has "tea fallback evidence" "the delivered tip's check record"
has "batch clause's reason" 'reports no delivery this run'
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
hasc "waiting rule pointer" "the harness doc's Waiting"
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
if doc 2 "runbook" "$runbook"; then
# the cut skills take the feature as their one argument; the runbook has a paragraph on it and
# writes it in the 3a and 3b rows below (chezmoi-nz0)
hasc "argument paragraph" '**The argument.**'
# the flat path (row 4b) runs the checks before the built-in code-review, and its review is the
# ticket review; "ticket gate" is retired so "gate" means the checks in every doc (dev-cq0.1.3)
hasc "flat path runs the checks before the built-in code-review" "then the checks (the owner repo's lint, then the agreed test seams), then the built-in \`code-review\`"
hasc "flat path's review is the ticket review" 'the ticket review (switch'
lacks "retired ticket gate name in the runbook" 'ticket gate'

# flat /to-tickets appears only in the Variants section
awk '/^## /{sec=$0} /\/mattpocock-skills:to-tickets/ && sec !~ /Variants/ {print NR": "$0; n=1} END{exit n}' "$f" >/dev/null \
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
lacks "story-cut.md in the runbook (the notes are the story bead's design field)" 'story-cut\.md'
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
awk '/^```/{fence=!fence; next} fence && /\/mattpocock-skills:pr([^a-z-]|$)/ {n=1} END{exit n}' "$f" || bad "/mattpocock-skills:pr in the fenced flow"
lackse "/mattpocock-skills:pr in stage 5" '^\| 5 .*/mattpocock-skills:pr([^a-z-]|$)'

# the stage table stays one table (rows 1..8 contiguous)
awk '/^\| 1 \|/{on=1} on && !/^\|/{bad=1} /^\| 8 \|/{on=0} END{exit bad}' "$f" || bad "stage table broken by a non-row line"

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
lacks "frontmatter: one story per repo" 'one story per repo it changes'
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

# ---- 4. /spec-to-tickets driver ----
if doc 4 "/spec-to-tickets driver" "$skills/spec-to-tickets/SKILL.md"; then
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
hasc "waiting rule pointer" 'the "Waiting" rule of `orchestration.md`'
has "no model override" 'no `model:` override'
has "waiting line" 'waiting on <dep repo> cut'
has "closed story line" '<repo> <story-id> closed'
has "skipped dependent gets explicit crate and version" 'Dependent: <repo>, skipped: no beads database, crate <crate>, version <version>.'
lacks "crate and version deferred to the notes" 'as story-cut.md has them|as the design field has them'
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
# new publish ticket is re-cut by the driver in the same run, so the rerun hint drops that case
has "cycle refusal names the stories" 'refused: dependency cycle ('
has "topological waves" 'topological waves'
has "one wave per DAG level" 'one wave per level of the story DAG'
has "dependent brief carries every upstream breakdown" 'one `Dependency:` line per publish blocker'
has "story-closure edge orders no wave" 'a story-closure edge orders no wave'
has "driver re-cuts an already cut dependent" 're-cuts that dependent itself'
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
lacks "two-wave cap or chain refusal" 'two (dependency )?waves suffice|two suffice|at most two( dependency)? waves|chains are out of scope'
lacks "rerun hint covering an already cut dependent" 'rerun this skill for the dependent'

fi

# ---- 5. agent docs and skills: retired phrases ----
section "5. retired phrases: $agents, $skills"
# whole words only ("shortcut one", "cut ones" pass); "re-cut one" is the spec's wording, not the retired name
retired='(^|[^-A-Za-z0-9_])cut (one|two)([^-A-Za-z0-9_]|$)|<spec-slug>|story-cut\.md'
# and no foreground spawn instruction: an Agent call returns at once whatever run_in_background
# says, so skills and agent docs point at the waiting rule instead (chezmoi-p4q)
while IFS= read -r f; do
  lacks "retired phrase in $f" "$retired"
  lacks "foreground spawn instruction in $f" 'run_in_background: false'
done < <(find "$agents" "$skills" -type f 2>/dev/null | sort)

# two lists are retired everywhere a reader meets them, the four file kinds: the skills, the
# agent docs, the project CLAUDE.md and the runbook (section 2's file).
# Session mode (ADR 0008): the walk-up wording.
walkup='nearest ancestor|walking up|walk up|one level up|the home repo included|the workspace root included|no repos\.yaml above|workspace inbox|workspace'\''s inbox|home repo <home repo>'
# The story-DAG wording (ADR 0011): one story per repo (now one per PR), the keyed branch
# feat/<key>-<n> (now feat/<story-id>), chains out of scope and the one text blocker (now a
# DAG), and the two-wave cap (now topological waves).
retired_dag='one story per repo|feat/<key>-<n>|chains are out of scope|only text blocker|two waves suffice'
while IFS= read -r f; do
  lacks "retired walk-up wording in $f" "$walkup"
  lacks "retired story-DAG wording in $f" "$retired_dag"
done < <({ find "$agents" "$skills" -type f 2>/dev/null; echo "$user_claude_md"; echo "$runbook"; } | sort)
# the check and review loop's retired two-gate wording (dev-1xf.1.4): the Evidence run, the later
# run that reviews a fix, the third-round wording and the second-red stall are absent from every
# file a reader meets, the four kinds above plus the root glossary and the sequence diagrams;
# docs/specs keeps them, since a spec states the change it makes
retired_loop='evidence run|a later run reviews the fix|a third round of either kind|a second red'
while IFS= read -r f; do
  lacks "retired two-gate wording in $f" "$retired_loop"
done < <({ find "$agents" "$skills" -type f 2>/dev/null; echo "$user_claude_md"; echo "$runbook"; echo "$glossary_md"; echo "$docs/SEQUENCES.md"; } | sort)

# the docs ship in the plugin: no path into the old dotfiles deployment (~/.claude/docs,
# ~/.claude/hooks) or the chezmoi source remains in any doc under docs/, the skills, the agent
# docs, the project CLAUDE.md or the runbook, spelled ~/, $HOME/ or ${HOME}/ (INFRA-30)
deployed='(~|\$HOME|\$\{HOME\})/(\.claude/docs|\.claude/hooks|\.local/share/chezmoi)'
while IFS= read -r f; do
  lacks "dotfiles deployment path in $f" "$deployed"
done < <({ find "$docs" -type f -name '*.md' 2>/dev/null; find "$agents" "$skills" -type f 2>/dev/null
  echo "$user_claude_md"; echo "$runbook"; } | grep . | sort -u)

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
line_has "$row" "ticket row: both axes at the review model, none at low" "| both axes, at the ticket's review model; none at \`low\` |"
line_has "$row" "ticket row: lands by merge under the lock after the stray-commit check" 'merge onto the integration branch under the lock, after the stray-commit check'
line_has "$row" "ticket row: a fix-up by pointer brief, same worktree" '| an implementer by pointer brief, same worktree |'
line_has "$row" "ticket row: three fix-ups" '| three fix-ups |'
row='^[|] [*][*]Story[*][*] [|]'
line_has "$row" "story row: the story orchestrator" '| story orchestrator |'
line_has "$row" "story row: ticket orchestrators over the frontier" '| ticket orchestrators in parallel over the frontier |'
line_has "$row" "story row: the story's body as spec" "| the story's body |"
line_has "$row" "story row: what entered since as standards" 'what entered since the last standards review: conflict resolutions and cross-ticket coherence'
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
para_has '**Check gate.**' "a fourth failure is failed" 'the fourth is `failed`'
para_has '**Check gate.**' "a minors fix-up and a conflict resolution rerun the checks" 'A minors fix-up and a conflict resolution move the tip, so the checks rerun'
para_has '**Check gate.**' "and spend nothing" 'no budget is spent'
para_has '**Check gate.**' "the reviewed tip noted on the story" 'records the reviewed tip in its notes'
para_has '**Check gate.**' "the gate exits on the moved tip" 'the gate exits on the moved tip once its checks are green'
para_has '**Check gate.**' "the note records the moved tip" 'the note records that tip'
para_has '**The epic row.**' "the epic row's checks are the forge's status on the PR tip" "the forge reports them green on the PR's tip"
lacks "the retired two-level check order" 'lint first, then the test seams'
lacks "the retired review marker exit" 'the review marker is the exit'
# the seam-test blocking case, and the one review tool
para_has '**Review verdict.**' "no test at a story seam is blocking" 'no test at a story seam exercises the criteria'
hasc "the one review tool" '`mattpocock-skills:code-review` at every row'
lacks "the built-in code-review in the model" 'built-in `code-review`'
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
# the driver runs Bash in the foreground only, since a child that ends a turn with background
# work running counts as idle and its real report escapes to the top-level session (chezmoi-p4q)
hasc "an Agent call returns at once" 'An Agent call returns at once'
hasc "the completion notification carries the report" "the Agent tool's completion notification"
hasc "a nested orchestrator ends its turn after spawning" 'ends its turn'
hasc "run_in_background is a JSON boolean" '`run_in_background` is a JSON boolean'
hasc "idle rule" '**Idle rule.**'
hasc "Bash in the foreground only below the driver" 'in the foreground only'
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
para_has '**Idle rule.**' "the Idle rule names the checks" "these are the story's checks"
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
hasc "merger brief's stray-commit check" 'runs the **stray-commit check** on what the merge brings in'
hasc "stray-commit failed: line" 'failed: stray commit <sha> <subject>'
lacks "profile-gated push" 'when the active profile permits|ask the user to run that exact command|give the user that exact command'
hasc "gitignore commit keyed on a dirty file" 'git -C <owner> status --porcelain -- .gitignore'
lacks "a gitignore hand-off from the story cut" 'the story cut appended|story cut could not commit'
hasc "a user edit in .gitignore is a failed: line, not absorbed" 'failed: <owner>/.gitignore has uncommitted edits'
hasc "exploration subagent reads the design field" '.[0].design'
hasc "exploration subagent owns the notes directory" '`<owner>/.spec-notes/<epic-id>/`'
# a failed runner's ticket is unclaimed at once, a second failure leaves the resume pointer on
# it, and the resume section says when a human runs the unclaim instead (chezmoi-jvc)
hasc "a failed runner's ticket is unclaimed" 'first `bd -C <owner> unclaim <id>`'
hasc "second failure notes the resume pointer" 'failed twice: <reason>; resume:'
hasc "hand unclaim condition in the resume section" 'by hand only when'
# the frontier keeps only ready-for-agent tickets, a deferred review finding is captured in the
# inbox through the retro capture and never as a story child, and a story counts as finished
# with an untriaged child under it (chezmoi-wgi; the Frontier rule itself is checked in 6)
hasc "frontier keeps ready-for-agent tickets only" 'keeping only the tickets labelled `ready-for-agent`'
lacks "frontier minus ready-for-human alone" 'minus `ready-for-human` tickets|other than `ready-for-human` ones|non-`ready-for-human`'
hasc "deferred findings go through the retro capture" '"capture a retro item"'
hasc "finished story tolerates untriaged children" '`needs-triage` or `wontfix`'
# the merger waits on the owner checkout's lock in one bounded foreground until-loop, not a
# check-and-sleep loop the merger runs by hand (chezmoi-sn1; the Waiting rule is checked in 6)
hasc "merger waits on the lock with an until-loop" 'until ! [ -e <owner>/.git/index.lock ]'
hasc "merger's lock wait is bounded by the call's timeout" 'timeout: 300000'
lacks "merger sleeping and re-checking the lock by hand" 'waits [0-9]+ seconds|checks again|re-?checks the lock|checks every [0-9]+ seconds'
# the story orchestrator and the ticket runner end their turn after spawning and are resumed by
# the completion notification; the runner and its subagents run Bash in the foreground only
# (chezmoi-p4q; the rule itself is checked in 6)
hasc "frontier spawn ends the turn" 'then end your turn: each runner'
hasc "ticket runner's spawn ends the turn" 'then end your turn: its report'
hasc "ticket runner brief carries the idle rule" "the rules doc's Idle rule"
# the implementer, fix-up and merger briefs give lint and test runs an explicit ten-minute
# timeout, so the 120 s default never backgrounds them (dev-7k0, INFRA-30)
for step in 2 3 4; do
  line_has "^> $step\. " "the ticket runner brief's step $step: lint and test timeout" 'timeout: 600000'
done
hasc "story fix-up brief names the lint and test limit" 'the ten-minute limit on lint and test runs'
# the per-ticket reviewer reads the standards the story review reads: the repo's own files and
# the plugin's coding-standards doc by its literal path (dev-co6)
for need in '`CODING_STANDARDS.md` or `CONTRIBUTING.md`' '<plugin root>/docs/agents/coding-standards.md` spelled as the path this session resolved'; do
  line_has '^> 3\. ' "the ticket reviewer brief's standards source" "$need"
done
# one story is one PR on `feat/<story-id>` (keyed or not); a finished story with an open agent
# ticket is guarded by one forge query; a story-closure wait says to merge and close; the
# sibling line carries the story id (chezmoi-9v4.1.5, ADR 0011)
hasc "integration branch is feat/<story-id> for keyed and keyless stories" 'named `feat/<story-id>`, keyed or not'
lacks "the keyed branch form feat/<key>-<n>" 'feat/<key>-<n>'
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
hasc "the worktrees: line appears only with content" '`worktrees:` and `resume:` lines appear only when they have content'
# the implementer, fix-up implementer and merger briefs start with the TMPDIR line, stated once
# in the Owner repo section with its two riders and named in the ticket runner brief's steps 2,
# 3 and 4 and the story review's fix-up (step 7); the Gitignore step counts the rule's four
# entries, /.tmp/ included (chezmoi-3eg)
hasc "TMPDIR line stated in the skill" 'mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp'
hasc "export repeated per Bash call" 'repeated at the head of every Bash call'
hasc "mktemp -d takes a template under .tmp" 'mktemp -d <worktree>/.tmp/<name>.XXXXXX'
# the ticket runner reads the rules doc, not this skill, so its brief points there
hasc "ticket runner brief points at the rules doc's TMPDIR rule" "the rules doc's TMPDIR rule"
for step in 2 3 4; do
  hase "ticket runner step $step's brief starts with the TMPDIR line" "^> $step\. .*TMPDIR line"
done
hase "the story review's fix-up implementer brief starts with the TMPDIR line" '^7\. .*TMPDIR line'
hasc "Gitignore step counts four entries" "the rule's four entries"
lacks "Gitignore step counts three entries" "the rule's three entries"
# the reviewer brief in the runner's step 3 carries the two tags with their definitions and
# the verdict line (the reviewer never reads the rules doc), and step 3 and the story review's
# step 7 point at the rules doc's Review verdict for what a clean round does; the retired bar,
# clean as no finding at all, is gone (chezmoi-49k). The brief's phrases are read on the step 3
# line alone, since step 7 carries the same ones
for phrase in 'verdict: clean' 'verdict: blocking (<n>)' '**blocking** or **minor**' 'within the budget above'; do
  line_has '^> 3\. ' "ticket runner step 3's reviewer brief" "$phrase"
done
hase "ticket runner step 3 points at the rules doc's Review verdict" "^> 3\. .*the rules doc's Review verdict"
hase "the story review (step 7) points at the rules doc's Review verdict" "^7\. .*the rules doc's Review verdict"
lacks "the zero-findings bar" 'not clean after three rounds|no findings at all|clean means zero findings'
# the story orchestrator resolves the owner repo's lint command once, in the forge step, with a
# three-way precedence, and the runner brief's header carries it so no agent guesses it (dev-cq0.1.2)
L3='^   Resolve the owner repo'"'"'s \*\*lint command\*\*'
line_has "$L3" "step 3 resolves the lint command once" 'Resolve the owner repo'"'"'s **lint command** once'
line_has "$L3" "lint precedence: make lint first" '`make lint` when `<owner>`'"'"'s Makefile has a `lint` target'
line_has "$L3" "lint precedence: CLAUDE.md second, then none" 'else the command `<owner>`'"'"'s `CLAUDE.md` names, else none'
line_has '^> You are the ticket runner' "runner brief header carries the lint command" 'lint command `<lint>` or none'
# anchored: step 3's lint paragraph says who spells it out and where it runs; the runner brief's
# opening paragraph lists it among what every brief carries; its step 2 offers no list to choose from
line_has "$L3" "step 3's lint paragraph names the implementer, fix-up implementer and merger briefs" 'spells it out in every implementer, fix-up implementer and merger brief it sends'
line_has "$L3" "step 3's lint paragraph runs the lint as make -C <dir> lint" 'make -C <dir> lint'
line_has '^> You are the ticket runner' "the runner brief's every-brief list carries the lint command" 'the lint command `<lint>` (or none)'
line_has "$L3" "step 3's lint paragraph says where a CLAUDE.md-named command runs" 'a command `CLAUDE.md` names runs in that same checkout or worktree'
line_has '^> 2\. ' "runner step 2 leaves out the tests the lint command already runs" 'leaving out any the lint command already runs'
line_has '^> 2\. ' "runner step 2 takes the lint command from the brief" "the brief's lint command"
line_lacks '^> 2\. ' "runner step 2 offers a list of lint commands to choose from" '`make lint`'
# the ticket runner's check and review loop sits between the implementer (step 2) and the merger
# (step 4) as one step: it opens step 3 for every tier, checks ahead of the reviewer; each check
# is one logged Bash call under the worktree's .tmp/; a red is noted on the ticket; a red and a
# blocking verdict both spawn a fresh fix-up implementer and start the loop over from the checks,
# on one budget of three fix-ups; a low ticket exits on green; the implementer runs no checks
# (dev-cq0.1.4, dev-1xf.1.2)
G3='^> 3\. \*\*Check gate\*\*, every tier'
hase "ticket runner step 3 opens with the check gate, every tier" "$G3"
line_has "$G3" "the loop step cites the rules doc's loop" "as the rules doc's Check gate says"
line_has "$G3" "a red starts the loop over from the checks" 'A red spawns a fresh fix-up implementer and the loop starts over from the checks'
line_has "$G3" "a blocking verdict starts the loop over from the checks, never straight to the reviewer" 'a blocking verdict spawns a fresh fix-up implementer and the loop starts over from the checks, never straight to the reviewer'
line_has "$G3" "a clean verdict exits the loop" '**Clean** exits the loop'
line_hase "$G3" "the check gate runs before step 3's reviewer" '\*\*Check gate\*\*.*Green:.*for `medium` and `high`, spawn a \*\*reviewer\*\*'
grep -E "$G3" "$f" | sed 's/Green: .*//' | grep -qF -- 'spawn a **reviewer**' && bad "present: ticket runner step 3 spawns a reviewer ahead of the checks' green"
line_has "$G3" "a low ticket exits the loop on green checks" 'Green: a `low` ticket exits the loop, go to step 4'
line_has '^> 2\. ' "runner step 2's implementer runs no gate and spawns no one" 'The implementer runs no gate and spawns no one'
line_has "$G3" "the check gate logs both streams under the worktree's .tmp/ and echoes the exit" 'mkdir -p <worktree path>/.tmp; export TMPDIR=<worktree path>/.tmp; <check> > <worktree path>/.tmp/checks-<round>-<k>.log 2>&1; echo exit=$?'
line_has "$G3" "a red gate reads a forty-line tail of the log, never the whole output" 'tail -n 40 <log>'
line_has "$G3" "a red gate's note form (checks <round>: red <command>)" '`bd -C <owner> note <ticket-id> "checks <round>: red <command>"`'
line_has "$G3" "a green gate writes no note" 'a green writes no note'
line_has "$G3" "the gate's fix-up brief points at the log path" 'the log path, and no pasted output'
line_has "$G3" "red and blocking fix-ups share one budget of three, the fourth failure is failed" 'The budget is three fix-ups of either cause; the fourth red or blocking verdict is `failed`'
line_has "$G3" "the minors fix-up after a clean verdict spends no budget and advances no round" 'The minors fix-up spends no budget and advances no round'
lacks "the retired run-the-gate-again wording" 'run the check gate again, and on green spawn a reviewer again'
# the merger's two runs (step 4, dev-cq0.1.6): the implementer's worktree after the tip merge and
# the owner checkout after the integration merge are runs of the story's checks, the lint command
# included, in place of the tests
line_has '^> 4\. ' "the merger runs the story's checks, the lint command included, in the implementer's worktree" 'runs the story'"'"'s checks there, the lint command `<lint>` included'
line_has '^> 4\. ' "the merger reruns the story's checks, the lint command included, on the merged result in <owner>" 'reruns the story'"'"'s checks on the merged result in `<owner>`, the lint command `<lint>` included'
# the story review (step 7) is the rules doc's Check gate loop on the integration branch tip
# with the review marker as its exit: each iteration runs the checks first; a red goes to the
# fix-up implementer and merger and the loop starts over; green and a tip matching the marker
# exits, that iteration's run (each check's command, exit and tail) the PR's Evidence, cited so
# in step 8; a tip off the marker is reviewed, fixed, marked and the loop starts over; the
# fourth failure stalls with failed: <check> <command>; the separate Evidence run, the later
# run that reviewed its fix and the second-red stall are gone (dev-cq0.1.5, dev-1xf.1.3)
line_has '^7\. ' "the story review (step 7) is the rules doc's Check gate loop with the marker as its exit" "the rules doc's Check gate loop on the integration branch tip, with the **review marker** as its exit"
line_has '^7\. ' "the story review (step 7) runs the checks first in each iteration" 'Each iteration runs the checks first'
line_has '^7\. ' "a red at the story review starts the loop over" 'to the fix-up implementer below, then its merger, and the loop starts over'
line_has '^7\. ' "a green tip matching the review marker exits the loop" 'the same SHA exits the loop'
line_has '^7\. ' "the exit iteration's run is the PR's Evidence" "this iteration's run (each check's command, its exit and the last twenty lines of its log) is the PR's Evidence"
line_has '^7\. ' "a reviewed tip is marked and the loop starts over" 'write the marker on the new tip, and the loop starts over'
line_has '^7\. ' "the story loop's fourth failure skips delivery" 'the fourth failure skips step 8 and goes to step 9'
line_has '^7\. ' "the story loop's stall line" '`failed: <check> <command>`'
# one budget for the story loop, red or review, a minors-only review's fix-up included, and the
# review's own stall form (dev-1xf.1.3 review 1)
line_has '^7\. ' "red and review fix-ups share the story loop's budget of three" 'The budget is three fix-ups per story, red or review alike'
line_has '^7\. ' "a minors-only review's fix-up spends the story loop's budget" "every fix-up in the story loop spends it, a minors-only review's included"
line_has '^7\. ' "the story loop's stall line for a review" "(a review's as \`failed: review mattpocock-skills:code-review\`)"
# on the first step 7 line, the checks come before the marker compare and the review
awk -v g='Each iteration runs the checks first' -v m='the same SHA exits the loop' -v r='mattpocock-skills:code-review' \
  '/^7\. / { i = index($0, g); k = index($0, m); j = index($0, r); ok = (i && k && j && i < k && k < j); seen = 1; exit } END { exit !(seen && ok) }' "$f" \
  || bad "missing: the story review (step 7) runs the checks before the marker compare and the two-axis review"
line_has '^8\. ' "the deliver step (8) takes its Evidence from step 7's exit iteration" "its Evidence from step 7's exit iteration (each check's command, exit and twenty-line tail)"
hasc "report template's failed: line names the check" 'or <check> <command>'
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
# the one-text-blocker and no-chains rules are retired. The skills and the runbook get their
# own checks in their sections, so the forbidden phrases are scoped to these two docs.
for d in "$agents/issue-tracker.md" "$agents/orchestration.md"; do
  doc 10 "story DAG" "$d" || continue
  has "story DAG" 'story DAG'
  has "human gate ticket" 'human gate ticket'
  # read as one line, so a phrase wrapped across a line break is still caught; the chains
  # match is bounded so it cannot run across paragraphs
  for pat in 'only text blocker' 'chains[^.]{0,120}out of scope'; do
    tr '\n' ' ' < "$f" | grep -qiE -- "$pat" && bad "present: retired story-DAG wording in $f ($pat)"
  done
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
# built-in command do not count as skills. The driver passed as $1 is scanned too, wherever it
# lives. In docs/specs/ only the existence check is skipped: a spec names the skills its
# stories have yet to build.
plugin=${PLUGIN_SKILLS:-$(ls -d "$HOME"/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/*/skills 2>/dev/null | sort -V | tail -1)}
# the plugin's skill names, listed once per run: a skill dir sits at the plugin's skills level,
# directly or under one category dir (engineering/tdd), and is not a subdirectory of another
# skill (tdd/scripts)
plugin_skills=
if [ -d "$plugin" ]; then
  # one listing: the SKILL.md files that make a dir a skill ("S"), then the candidate dirs ("D")
  plugin_skills=$({ find "$plugin" -maxdepth 2 -name SKILL.md | sed 's/^/S /'
    find "$plugin" -mindepth 1 -maxdepth 2 -type d | sed 's/^/D /'; } 2>/dev/null | awk '
    { path = substr($0, 3) }
    /^S / { sub(/\/SKILL\.md$/, "", path); skill[path] = 1; next }
    { parent = path; sub(/\/[^\/]*$/, "", parent); if (!(parent in skill)) { sub(/.*\//, "", path); print path } }' | sort -u)
fi
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
          case $'\n'"$plugin_skills"$'\n' in
            *$'\n'"$name"$'\n'*) ;;
            *) bad "/$tok names no skill" ;;
          esac
        fi ;;
    esac
  done
}
section "11. namespace rule"
scanned=()
while IFS= read -r f; do
  [ -f "$f" ] && scanned+=("$f")
done < <({ find "$docs" "$agents" "$skills" -type f -name '*.md' 2>/dev/null
  echo "$runbook"; echo "$user_claude_md"; echo "$glossary_md"; echo "${1:-}"; } | grep . | sort -u)
pairs=$(cmd_tokens "${scanned[@]}") || bad "token extractor failed on ${scanned[*]}"
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
while IFS=$'\t' read -r f n line; do
  bad "plugin-root variable in a brief in $f:$n (spell the plugin root literally; the rules doc's Plugin root rule): $line"
done < <(find "$skills" -type f -name '*.md' -print0 2>/dev/null | sort -z | xargs -0 awk '
  FNR == 1 {inq=0} /^[[:space:]]*>/ {inq=1} /^[[:space:]]*$/ {inq=0}
  inq && /CLAUDE_PLUGIN_ROOT/ {print FILENAME "\t" FNR "\t" $0}' /dev/null)

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
while IFS= read -r f; do
  [ -f "$f" ] || continue
  hits=$(awk '/^[[:space:]]*```mermaid/ { inm = 1; next } inm && /^[[:space:]]*```/ { inm = 0 } inm && index($0, ";") { print FNR": "$0 }' "$f")
  [ -z "$hits" ] || { bad "present: a semicolon in a mermaid block in $f (mermaid ends the statement there)"; printf '%s\n' "$hits" | head -3; }
done < <({ find "$agents" "$skills" "$docs" -type f -name '*.md' 2>/dev/null; echo "$user_claude_md"; echo "$runbook"; echo "$glossary_md"; } | sort -u)

checks_run
[ "$fail" = 0 ] && echo "PASS"
exit "$fail"
