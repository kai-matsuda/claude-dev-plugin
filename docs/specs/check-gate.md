# The check gate: every deterministic pre-check runs before a reviewer

## Problem Statement

A ticket's reviewer and the story review's two sub-agents are the most expensive agents
in the workflow: each runs one model tier above the implementer (sonnet, opus or fable)
and reads the whole diff plus every standards source. Today they are the first
independent eyes on a branch tip. The ticket runner takes the implementer's *ready for
review* on trust and spawns the reviewer; the story orchestrator reviews the integration
branch, merges the fix-up, writes the review marker, and only then runs the story's test
seams. A red lint or test is found by the reviewer, if at all, after the costly read, and
a seam that fails after the marker is fixed by an unreviewed fix-up that the marker rule
has to excuse ("a rerun reviews it"). INFRA-28's run recorded the shape of it: a runner
handed its seams to a reviewer.

## Solution

Cheapest gate first. A story's **checks** are the owner repo's lint and its test seams;
the **check gate** is the read-only run of those checks on a branch tip before any
reviewer sees it, lint first, then the seams, stopping at the first red. The ticket
runner runs it on each implementer's branch, for every tier; the story orchestrator runs
it on the integration branch before the two-axis review and again after the fix-up, the
second run being the PR's Evidence. A red goes to a fresh fix-up implementer with a
pointer at the log, never to a reviewer, and counts toward the ticket's existing
three-round budget. Check output stays on disk; an orchestrator reads an exit code and,
on red, a tail. Vocabulary in `GLOSSARY.md` (Test seam, Check, Check gate).

## User Stories

1. As the owner of a feature, I want a reviewer to read only branch tips that are green,
   so that review tokens buy judgement and never a failing test.
2. As the owner of a feature, I want a red lint caught by one Bash call rather than by an
   opus or fable reviewer, so that the cheapest check is the first one that runs.
3. As a ticket runner, I want to run the story's checks myself on the implementer's
   branch, so that *ready for review* is verified and not taken on trust.
4. As a ticket runner, I want a red check to go to a fresh fix-up implementer with the
   failing command and a log path, so that the fix happens where fixes already happen.
5. As a ticket runner, I want red check rounds and blocking review rounds to share one
   three-round budget, so that a ticket cannot loop twice as long by failing both ways.
6. As the owner of a `complexity:low` ticket, which has no reviewer, I want the check gate
   between its implementer and its merger, so that it gets one independent check before
   the owner checkout is touched.
7. As a story orchestrator, I want the checks run on the integration branch before the
   two-axis review, so that the review covers whatever the pre-review fix-up changed.
8. As a story orchestrator, I want a second red before the review to stall the run with
   the check and its command named, so that the story review never reads a branch that
   is structurally broken.
9. As a story orchestrator, I want the checks run again after the review's fix-up, so
   that the PR's Evidence is on the tip that is pushed.
10. As a story orchestrator on a rerun whose tip matches the review marker, I want to
    skip the gate and the review and land at the Evidence run, so that an already
    reviewed tip is not re-checked twice.
11. As a merger, I want both of my runs to be the checks, lint included, so that a lint
    two tickets each pass alone still fails on their merged result.
12. As a story orchestrator, I want the owner repo's lint command resolved once per run
    and spelled into every brief, so that no implementer, fix-up or merger guesses it.
13. As the story cut, I want the story body shape unchanged, so that `## Test seams`
    stays the only thing a story says about testing and lints stay a repo fact.
14. As a ticket runner, I want a check's output written to a log and never into my
    context, so that a 2,000-line test run does not grow the agent that must outlive the
    whole ticket.
15. As a fix-up implementer, I want the brief to name the log path and not paste the
    output, so that I read as much as I need with a fresh context.
16. As a story orchestrator, I want the PR's Evidence to be each check's command, exit
    and tail, so that the PR body stays readable and my context stays small.
17. As a resumed run, I want a red check noted on the ticket as `checks <round>: red
    <command>`, so that the bead's line log shows why the ticket took another round.
18. As a resumed run, I want no note for a green check, so that the bead's line log
    carries only what changed.
19. As someone running the flat single-ticket path, I want the checks run before
    `code-review`, so that the small-bug path follows the same rule as the orchestrated
    one.
20. As a reader of the docs, I want **Test seam**, **Check** and **Check gate** in the
    glossary, so that "gate" stops meaning the review in one doc and the checks in
    another.
21. As a reader of the runbook, I want the single-ticket path's review called the ticket
    review, so that it does not collide with the check gate.
22. As a maintainer of the plugin, I want each new rule pinned by the skill-doc lint and
    each pin proven by its regression test, so that a later edit cannot drop the gate
    silently.
23. As a maintainer of the plugin, I want the sequence diagrams to show the gate, so that
    the story and ticket stages read as they run.

## Implementation Decisions

- **Vocabulary.** Three glossary entries, already written: **Test seam** (the highest
  public boundary of a repo a feature can be tested through, named under a story's
  `## Test seams`), **Check** (one deterministic command whose exit code decides, the
  owner repo's lint or a test seam; a story's checks are both together) and **Check gate**
  (the read-only run of a story's checks on a branch tip, cheapest first, before any
  reviewer). The runbook's "ticket gate" for the single-ticket path's code-review is
  renamed "ticket review".
- **The rule** lives in the rules doc's Review section: no reviewer sees a branch tip
  until the story's checks are green on it, at both the ticket and the story level; lint
  first, then the seams, stopping at the first red. The Idle rule's list of lint and test
  commands names the checks. No ADR: the rule is cheap to reverse and not surprising once
  the glossary names the gate.
- **Lint resolution.** The story orchestrator resolves the owner repo's lint entry point
  once per run, in the step that decides the forge: `make lint` when the Makefile has a
  `lint` target, else the command the owner's `CLAUDE.md` names, else none. It is
  spelled into every runner, fix-up and merger brief. The story body shape, the story cut
  and ADR 0006 are untouched.
- **Ticket level.** The ticket runner, after the implementer reports and before any
  reviewer or merger, runs the whole check set read-only in the implementer's worktree on
  its branch (which has the integration branch's tip merged), one Bash call per check
  with the ten-minute timeout, both streams redirected to a log under the worktree's
  `.tmp/` directory and the exit code echoed. Green: the reviewer for `medium` and
  `high`, the merger for `low`. Red: the runner reads the log's tail, notes
  `checks <round>: red <command>` on the ticket, and spawns a fresh fix-up implementer
  at the tier's implementation model, same worktree and branch, with a pointer-only brief
  (ticket id, worktree path and branch, the failing command, the log path, the TMPDIR
  line); then the gate runs again. Red rounds and blocking review rounds share the
  ticket's three-round budget; a third round of either kind is `failed`. The implementer
  runs no gate and spawns no one; it is never resumed.
- **Merger.** Its two runs, in the worktree after merging the integration branch's tip
  and in the owner checkout after the integration merge, become runs of the checks, lint
  included.
- **Story level.** The story review step becomes: review marker matches the tip → jump to
  the Evidence run; else the check gate on the integration branch tip (red: one fix-up
  and merger round, then the gate again; a second red skips the review and stalls with
  `failed: <check> <command>`) → the two-axis review → fix-up and merger → the review
  marker → the checks again on the new tip, whose command, exit and tail per check are
  the PR's Evidence (a red there keeps today's one fix-up round, and the marker rule's
  rerun clause). Logs under the owner checkout's `.tmp/`, swept with the worktrees.
- **Flat path.** The runbook's single-ticket path runs the checks before `code-review`.
- **Context discipline.** No orchestrator ever reads a check's output whole: a green is
  one `exit=0` line; a red is a forty-line tail for the runner and a twenty-line tail per
  check in the Evidence; the fix-up implementer reads the log itself.
- **Records.** Only a red is noted on a ticket. The story bead's line log gains nothing:
  `branch:`, `review:` and `pr:` stay its only lines.
- **Diagrams.** The story and ticket sequence diagrams gain the gate between implementer
  and reviewer, and before and after the story review.

## Testing Decisions

- One seam: `make ci`, the skill-doc lint and its regression test. A good case pins what
  a skill doc or the rules doc must say (a `has` pattern) or must no longer say (a
  `lacks` pattern) and is proven by a regression case that drops the line and expects
  the lint to fail. Prior art: the review verdict, TMPDIR line, deferral and merge guard
  pins in the lint, each with its drop-line case in the regression test.
- Pins: the rules doc's Review section states the rule and the lint-then-seams order; the
  story orchestrator's forge step resolves the lint command with its three-way
  precedence; the story review step runs the gate before the review, stalls on a second
  pre-review red, and cites the Evidence as command, exit and tail (and no longer "the
  command and its output"); the runner brief runs the gate between implementer and
  reviewer for every tier, sends a red to a fresh fix-up implementer with the log path,
  counts it toward the three rounds, and notes the red; the merger's runs are the checks;
  the runbook's flat path runs the checks before `code-review` and calls the review the
  ticket review.
- The glossary lint already covers the three entries and their `_Avoid_` lists.
- Not tested here: a live fixture run of the story orchestrator. The next real feature
  exercises the gate; `/dev:retro` catches what the pins miss.

## Out of Scope

- A `## Checks` or `## Lints` section in the story body, or any change to the story cut.
- Caching a green across runs, or skipping the Evidence run when no fix-up moved the tip.
- A separate round budget for red checks.
- Running the checks on the integration branch tip before each ticket's gate to rule out
  a red inherited from another ticket: the merger's post-merge run keeps the integration
  branch green, so a red at a ticket's gate is that ticket's.
- A live fixture test of the gate.

## Further Notes

The post-review Evidence run is kept unconditional even when the review found nothing
and no fix-up moved the tip: it is one Bash call per check, and skipping it would mean
carrying "did a fix-up run?" state across the step. The one remaining unreviewed-fix case
is a red at the Evidence run, which is narrower than today's: that fix-up exists only
because the review asked for changes, so the red is in reviewed-and-requested work.
