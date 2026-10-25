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
reviewer sees it, lint first, then the seams, stopping at the first red. Both levels run
one loop: checks, then review; a red or a blocking verdict goes to a fresh fix-up
implementer and the loop starts over from the checks, so a review fix-up meets the checks
before it meets the reviewer again; a clean verdict exits; three fix-ups of any cause is
the budget. The ticket runner runs the loop on each implementer's branch, for every tier;
the story orchestrator runs it on the integration branch, where the review marker makes
it converge: the iteration whose tip matches the marker runs the checks and exits, and
that run is the PR's Evidence. Check output stays on disk; an orchestrator reads an exit
code and, on red, a tail. Vocabulary in `GLOSSARY.md` (Test seam, Check, Check gate).

## User Stories

1. As the owner of a feature, I want a reviewer to read only branch tips that are green,
   so that review tokens buy judgement and never a failing test.
2. As the owner of a feature, I want a red lint caught by one Bash call rather than by an
   opus or fable reviewer, so that the cheapest check is the first one that runs.
3. As a ticket runner, I want to run the story's checks myself on the implementer's
   branch, so that *ready for review* is verified and not taken on trust.
4. As a ticket runner, I want a red check to go to a fresh fix-up implementer with the
   failing command and a log path, so that the fix happens where fixes already happen.
5. As a ticket runner, I want one loop, checks then review, that starts over from the
   checks after any fix-up and allows three fix-ups of either cause, so that a review
   fix-up meets the checks before the reviewer and a ticket cannot loop twice as long by
   failing both ways.
6. As the owner of a `complexity:low` ticket, which has no reviewer, I want the check gate
   between its implementer and its merger, so that it gets one independent check before
   the owner checkout is touched.
7. As a story orchestrator, I want the checks run on the integration branch before the
   two-axis review, so that the review covers whatever the pre-review fix-up changed.
8. As a story orchestrator, I want a fourth failure of the loop to stall the run with
   the check and its command named, so that the story review never grinds on a branch
   that is structurally broken.
9. As a story orchestrator, I want the loop to exit only on an iteration whose checks
   are green and whose tip matches the review marker, so that the PR's Evidence is on
   the reviewed tip that is pushed and a check fix after the review is reviewed by the
   same run.
10. As a story orchestrator on a rerun whose tip matches the review marker, I want the
    loop to run the checks once and exit, so that an already reviewed tip is not
    re-reviewed.
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
- **The rule** lives in the rules doc's Review section, stated once as **the loop** both
  levels run: run the checks (lint first, then the seams, stopping at the first red); a red
  goes to a fresh fix-up implementer and the loop starts over; else run the review; a
  blocking verdict goes to a fresh fix-up implementer and the loop starts over; a clean
  verdict exits the loop. At most three fix-ups per loop, of either cause; a fourth failure
  is `failed`. No reviewer ever sees a tip the checks have not passed, and no fix-up is
  re-reviewed before the checks have passed on it. The Idle rule's list of lint and test
  commands names the checks. No ADR: the rule is cheap to reverse and not surprising once
  the glossary names the gate.
- **Lint resolution.** The story orchestrator resolves the owner repo's lint entry point
  once per run, in the step that decides the forge: `make lint` when the Makefile has a
  `lint` target, else the command the owner's `CLAUDE.md` names, else none. It is
  spelled into every runner, fix-up and merger brief. The story body shape, the story cut
  and ADR 0006 are untouched.
- **Ticket level.** Once the implementer reports, the ticket runner runs the loop in the
  implementer's worktree on its branch (which has the integration branch's tip merged).
  The checks: the whole set, read-only, one Bash call per check with the ten-minute
  timeout, both streams redirected to a log under the worktree's `.tmp/` directory and the
  exit code echoed. A red: the runner reads the log's tail, notes
  `checks <round>: red <command>` on the ticket, spawns a fresh fix-up implementer at
  the tier's implementation model, same worktree and branch, with a pointer-only brief
  (ticket id, worktree path and branch, the failing command, the log path, the TMPDIR
  line), and starts the loop over. The review: for `medium` and `high`, the reviewer at
  the tier's review model as today, its findings and verdict noted on the ticket; `low`
  has no reviewer, so its loop is the checks alone. A blocking verdict: a fresh fix-up
  implementer pointed at the note, and the loop starts over from the checks. A clean
  verdict exits; its minors go to one last fix-up implementer, unreviewed as today, then
  the merger. Three fix-ups of either cause is the budget; the fourth red or blocking
  verdict is `failed`. The implementer runs no checks for the loop and spawns no one; it
  is never resumed.
- **Merger.** Its two runs, in the worktree after merging the integration branch's tip
  and in the owner checkout after the integration merge, become runs of the checks, lint
  included.
- **Story level.** The story review step runs the same loop on the integration branch,
  with the review marker as its exit. Each iteration: run the checks on the tip; a red
  goes to a fix-up implementer and its merger, then the loop starts over; else compare the
  marker with the tip: a match exits the loop, and that iteration's run, each check's
  command, exit and tail, is the PR's Evidence; no match runs the two-axis review, sends
  its findings to the fix-up implementer and merger, writes the marker on the new tip, and
  starts over. So a first run goes checks, review, fix-up, marker, checks, exit; a rerun on
  a marked tip goes checks, exit; and a red after the review moves the tip off the marker,
  so the same run reviews the fix. The one-round rule holds as today, the review never
  failing on a verdict; a second review happens only when a check fix moved the tip. Three
  fix-ups is the budget; the fourth failure stalls with `failed: <check> <command>` (or
  the review's) in the report. Logs under the owner checkout's `.tmp/`, swept with the
  worktrees.
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
- Pins: the rules doc's Review section states the loop, the lint-then-seams order and the
  three-fix-up budget; the story orchestrator's forge step resolves the lint command with
  its three-way precedence; the story review step runs the loop with the marker as its
  exit, stalls on the fourth failure, and cites the Evidence as command, exit and tail
  (and no longer "the command and its output" or "a rerun reviews it"); the runner brief
  runs the loop between implementer and merger for every tier, sends a red to a fresh
  fix-up implementer with the log path and a blocking verdict to one pointed at the note,
  starts over from the checks after either, and notes the red; the merger's runs are the
  checks; the runbook's flat path runs the checks before `code-review` and calls the
  review the ticket review.
- The glossary lint already covers the three entries and their `_Avoid_` lists.
- Not tested here: a live fixture run of the story orchestrator. The next real feature
  exercises the gate; `/dev:retro` catches what the pins miss.

## Out of Scope

- A `## Checks` or `## Lints` section in the story body, or any change to the story cut.
- Caching a green across runs, or skipping the exit iteration's check run when no fix-up
  moved the tip.
- A separate round budget for red checks.
- Running the checks on the integration branch tip before each ticket's gate to rule out
  a red inherited from another ticket: the merger's post-merge run keeps the integration
  branch green, so a red at a ticket's gate is that ticket's.
- A live fixture test of the gate.

## Further Notes

The loop replaces two loops the first draft of this spec had (red → checks again;
blocking → reviewer again) with one, and closes the hole the review marker rule used to
excuse: a check fix after the review is no longer "unreviewed, a rerun reviews it", since
the moved tip fails the marker comparison and the same run reviews it. The cost is at
most one extra check run per fix-up, and the budget bounds it. The minors fix-up stays
outside the loop and unreviewed, as the rules doc has it: putting it inside would buy a
check run for a nit that changes no behaviour.
