# The check-and-review loop: one loop at both levels, the review marker as its exit

## Problem Statement

INFRA-31 shipped the check gate as two gates stitched together. At the ticket level the
runner re-gates after a blocking review's fix-up, which is already most of a loop, but the
rule is spread over a gate paragraph, a verdict paragraph and a "third round of either
kind" clause. At the story level it is two separate things: a pre-review gate with its own
one-round red path, then the review, then a distinct **Evidence run** whose red is fixed
by an unreviewed fix-up that the review marker rule has to excuse ("the marker stays put,
so a later run reviews the fix"). A reader has to hold three sequences in their head
(ticket gate, story gate, Evidence run) to know what happens on a red, and the one place
a fix can still reach the PR unreviewed is exactly the one the design was meant to close.

## Solution

One loop, stated once in the rules doc and run at both levels: run the checks (lint, then
the test seams, first red stops); a red goes to a fresh fix-up implementer and the loop
starts over; else run the review; a blocking verdict goes to a fresh fix-up implementer
and the loop starts over; a clean verdict exits. Three fix-ups per loop, of either cause;
a fourth failure is `failed`. The ticket runner runs it between implementer and merger;
the story orchestrator runs it on the integration branch with the **review marker** as
its exit: an iteration whose checks are green and whose tip matches the marker exits, and
that iteration's run is the PR's Evidence. A check fix after the review moves the tip off
the marker, so the same run reviews it, and the separate Evidence run and its glossary
term go away. Vocabulary: **Check gate** stays and absorbs the loop; **Evidence run** is
retired; **Review marker** describes the exit.

## User Stories

1. As a reader of the rules doc, I want the check gate stated as one loop, so that what
   happens on a red or a blocking verdict is one sequence, not three.
2. As a ticket runner, I want a red check and a blocking verdict handled the same way, a
   fresh fix-up implementer and the loop started over from the checks, so that no fix-up
   reaches a reviewer before the checks have passed on it.
3. As a ticket runner, I want a budget of three fix-ups per ticket of either cause, so
   that the limit is one number and a ticket cannot alternate between red checks and
   blocking reviews past it.
4. As the owner of a `low` ticket, which has no reviewer, I want its loop to be the checks
   alone, so that the same rule covers every tier without a special case.
5. As a story orchestrator, I want the review marker to be the loop's exit, so that I carry
   no "did a fix-up run?" state: an iteration exits when its checks are green and its tip
   matches the marker.
6. As a story orchestrator, I want a red after the review to move the tip off the marker
   and be reviewed by the same run, so that no fix reaches the PR unreviewed and the
   marker rule needs no "a later run reviews the fix" excuse.
7. As a story orchestrator, I want the PR's Evidence to be the exit iteration's check run,
   so that the Evidence is always on the exact tip that is pushed and no separate step
   produces it.
8. As a story orchestrator on a rerun whose tip matches the marker, I want the loop to run
   the checks once and exit, so that an already reviewed tip is not re-reviewed and still
   gets fresh Evidence.
9. As a story orchestrator, I want a fourth failure of the loop to stall the run with the
   check or the review named, so that a structurally broken branch is reported, not
   ground on.
10. As the owner of a feature, I want the review to stay one round per tip as today, so
    that a second two-axis review costs its fable tokens only when a check fix moved the
    tip.
11. As the owner of a feature, I want the minors fix-up to stay outside the loop and
    unreviewed, so that a nit never buys a fourth check run.
12. As a reader of the glossary, I want **Evidence run** gone and **Check gate** and
    **Review marker** rewritten for the loop, so that the vocabulary names what the code
    does.
13. As a reader of the sequence diagrams, I want Stage 1 and Stage 2 drawn as the loop, so
    that the diagrams and the texts agree.
14. As a maintainer of the plugin, I want the loop pinned by the skill-doc lint and the
    retired phrases forbidden, each pin proven by a regression case, so that the two-gate
    shape cannot creep back.
15. As a maintainer of the plugin, I want the lint's INFRA-31 pins that assert the
    two-gate shape (the separate Evidence run paragraph, the "second red" stall, the
    "third round of either kind" wording) replaced rather than piled on, so that the lint
    describes one design.

## Implementation Decisions

- **The rule, once.** The rules doc's Review section replaces its Check gate paragraph
  with **the loop**: run the checks (lint first, then the test seams, first red stops); a
  red goes to a fresh fix-up implementer and the loop starts over; else run the review; a
  blocking verdict goes to a fresh fix-up implementer and the loop starts over; a clean
  verdict exits. Three fix-ups per loop, of either cause; a fourth failure is `failed`. The
  Review verdict paragraph's "Blocking rounds and red check rounds count toward a ticket's
  three-round limit" becomes a pointer at the loop's budget. Both levels cite the paragraph
  rather than restating it.
- **Ticket level.** The runner brief's gate step and review step become one loop step:
  checks (as INFRA-31 shipped them: read-only in the worktree, one Bash call per check,
  log under the worktree's `.tmp/`, exit echoed, forty-line tail on red, `checks <round>:
  red <command>` note on red only) → on red, fresh fix-up implementer by log path and start
  over → on green, the reviewer for `medium` and `high` (unchanged: built-in code-review at
  the tier's effort, findings and verdict noted) → on blocking, fresh fix-up implementer
  pointed at the note and start over → on clean, exit; minors to one last unreviewed
  fix-up implementer, then the merger. `low` exits on green checks. Budget: three fix-ups
  of either cause; the fourth red or blocking verdict is `failed`. The implementer runs no
  checks for the loop and spawns no one.
- **Story level.** The story review step becomes the loop with the marker as its exit.
  Each iteration: run the checks on the integration branch tip; red → fix-up implementer
  and merger, start over; else compare the `review:` marker with the tip: match → exit,
  this iteration's run (each check's command, exit and twenty-line tail) is the PR's
  Evidence; no match → two-axis review, findings to fix-up implementer and merger, write
  the marker on the new tip, start over. First run: checks, review, fix-up, marker, checks,
  exit. Rerun on a marked tip: checks, exit. Red after the review: the tip moves off the
  marker and the next iteration reviews the fix. The review never fails on a verdict, as
  today. Budget: three fix-ups; the fourth failure skips delivery with `failed: <check>
  <command>` (or the review's) in the report. The separate Evidence run paragraph is
  removed; the delivery step takes its Evidence from the exit iteration.
- **Vocabulary.** **Evidence run** is removed from the glossary (and its `_Avoid_` terms
  with it). **Check gate** is rewritten: the loop both levels run, checks then review,
  restarting after every fix-up. **Review marker** is rewritten: the loop's exit at the
  story level; a tip that matches runs the checks once and exits; one that has moved is
  reviewed again in the same run. No new term.
- **Lint and diagrams.** The lint's pins for the two-gate shape (the Evidence run
  paragraph, "skip the gate and the review and go to the Evidence run", the second-red
  stall, "a third round of either kind", "run the check gate again, and on green spawn a
  reviewer again") are replaced by pins for the loop: the paragraph and its order, the
  start-over on either failure, the marker exit, the three-fix-up budget, and `lacks` for
  "Evidence run" and "a later run reviews the fix". Stage 1 and Stage 2 of the sequence
  diagrams are redrawn as the loop. The plugin version is bumped.
- **Unchanged from INFRA-31.** How a check runs, the lint resolution, the merger's runs as
  the checks, the flat path, the context discipline, the records (red note only; story
  notes stay `branch:`, `review:`, `pr:`). No ADR: a rule restatement.

## Testing Decisions

- One seam, `make ci`: the skill-doc lint and its regression test. A good case pins what a
  doc must say (`has`/`para_has`) or must no longer say (`lacks`) and is proven by a
  regression case that drops or swaps the line and expects the lint to fail. Prior art:
  INFRA-31's own pins and cases for the check gate, the Review verdict pins, the TMPDIR
  line cases.
- Pins: the rules doc's loop paragraph, its lint-then-seams order, its start-over on
  either failure, its budget; the runner brief's one loop step, red and blocking both
  starting over, the budget, `low` exiting on green; the story review step's marker exit,
  the Evidence taken from the exit iteration, the fourth-failure stall; `lacks` for
  "Evidence run", "a later run reviews the fix", "a third round of either kind", the
  separate Evidence run paragraph. Each with a drop-line or seeded-phrase case.
- The glossary lint covers the rewritten entries.
- Not tested here: a live fixture run of the story orchestrator. The next feature run
  exercises the loop; `/dev:retro` catches what the pins miss.

## Out of Scope

- Any change to how a check runs, to the lint resolution, to the merger, to the flat path
  or to the records.
- Putting the minors fix-up inside the loop.
- Skipping the exit iteration's check run when no fix-up moved the tip.
- A separate budget for red checks or for the story level.
- A live fixture test of the loop.

## Further Notes

The ticket level is already close: INFRA-31's runner brief re-gates after a blocking
fix-up, so most of this feature's work there is restating that as the loop and fixing the
budget's wording. The story level is where the design changes: the pre-review gate, the
review and the Evidence run were three steps with two red paths; they become one loop with
one red path, and the review marker, which INFRA-31 used as a skip, becomes the exit
condition, which is what removes the last unreviewed fix. The cost is at most one extra
check run per fix-up, bounded by the budget.
