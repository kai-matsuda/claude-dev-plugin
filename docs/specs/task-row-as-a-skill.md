# The task row as a skill: `/dev:task-orchestrator` and `/dev:implement-task`

## Problem Statement

The feature workflow composes downward only part of the way. `/dev:implement-spec` spawns
one `/dev:implement-story` per story, but the task row below the story is not a skill: it
is a 1,500-word brief pasted into every spawn by `/dev:implement-story`, and the only
other way to run a bead through an implementer is the upstream `/mattpocock-skills:implement`,
which has no check gate, no check record, no stray-commit check and opens no PR. So a
task under a story and a standalone bead (an accepted retro item, a small bug) take two
different routes with two different guarantees, and the standalone route is the weaker one.

The runbook's own small-bug path makes this worse: it creates a flat epic, an epic bead with
tasks directly under it, which both implement skills then refuse, and asks the person to
close the epic bead by hand once its tasks are done.

Two words make the composition hard to read. The unit is called a "ticket", a word that in
the tools means any level of something to do (a Jira ticket is an Epic), while the beads
issue type the unit carries is `task`. And the task row lands its own unit on the
integration branch, so the ticket orchestrator needs the owner checkout, a lock, and a
conflict-resolution budget, all of which exist only because sibling tasks land in parallel.

## Solution

The task row becomes a skill of its own, `/dev:task-orchestrator`, spawned by a story
orchestrator and never typed. It owns one task from claim to a reviewed branch and reports
one line. The story orchestrator lands each reviewed branch itself, serially, one per
report, so the lock goes away.

A standalone task is delivered by a new typed command, `/dev:implement-task <id>`: a story
orchestrator with a frontier of one, no story bead and no story gate, which spawns one task
orchestrator and delivers the task's branch as a PR opened ready. The chain is then
`implement-spec → implement-story → task-orchestrator` and `implement-task → task-orchestrator`.

The unit is renamed from "ticket" to **task** throughout, the flat epic and the small-bug
path are retired, and the decision that moves the landing out of the task row is recorded as
an ADR amending ADR 0014.

## User Stories

1. As a person running `/dev:implement-story`, I want each task built by a skill rather than a pasted brief, so that the task row's procedure is maintained in one file and every spawn gets the same one.
2. As a person running `/dev:implement-story`, I want the story orchestrator to land each reviewed task branch itself, so that no lock on the owner checkout is needed and a cut-off task orchestrator never leaves one behind.
3. As a person with a standalone task (an accepted retro item, a small bug), I want to type `/dev:implement-task <id>` and get a PR, so that it has the same check gate, review, check record and stray-commit check as a task under a story.
4. As a person with a standalone task, I want its PR opened ready rather than draft, so that my review starts at once, there being no epic review above it.
5. As a person with a standalone task, I want the task closed when its PR is open and its forge checks are green, so that nothing waits on me to close a bead by hand.
6. As a person who types `/dev:implement-task` on a task that belongs to a story, I want a one-line refusal naming the story, so that a story's task is never delivered outside its story's PR.
7. As a person who types `/dev:task-orchestrator` by hand, I want a one-line refusal, so that the spawned-only skill never runs without a story orchestrator's brief.
8. As a person re-typing `/dev:implement-task` on a task whose PR merged, I want the merge guard's refusal, so that a sealed branch stays sealed.
9. As a person re-typing `/dev:implement-task` on a task whose earlier run failed, I want the run to re-enter at the gate on the branch's commits with a fresh budget, so that nothing built is thrown away.
10. As a story orchestrator, I want to send a short brief (task id, owner, branch, check command, published version, plugin root, a retry's reason), so that the brief carries only what the story run alone knows and the skill derives the rest from the task.
11. As a story orchestrator, I want a task orchestrator's report to be one of `reviewed: <branch> <worktree> <tip>`, `needs split: <cut>` or `failed: <reason>`, so that landing, splitting and retrying each have one trigger.
12. As a story orchestrator, I want a conflict on landing sent to an implementer in that task's worktree and the resolved tree checked before the fast-forward, so that no unchecked edit reaches the integration branch.
13. As a story orchestrator, I want a red check on a resolved tree to end that landing as `failed` and the task's retry to enter at the gate on the resolved branch, so that the story orchestrator relays and never gates a task itself.
14. As a story orchestrator, I want at most three conflict resolutions per landing, apart from the task's fix-up budget, so that a sibling that moved the branch is bounded without being counted as the task's failure.
15. As a task orchestrator, I want to never touch the owner checkout, so that parallel task orchestrators cannot interfere and the skill is the same whichever story orchestrator spawned it.
16. As a task orchestrator, I want to enter at the gate when the branch already carries commits (a cut-off's replacement, a retry after a conflict resolution's red), so that there is one procedure with two entries and no modes.
17. As a reader of the rules doc, I want the task row's "lands by" cell to say it reports a reviewed branch and the story row's to say it merges it, so that the table matches the skills.
18. As a reader of the rules doc, I want the check-record call and the delivery procedure stated there once, so that neither skill points at another skill's step numbers.
19. As a reader of the rules doc, I want `/dev:implement-task` described in one paragraph under the table as the story row with a frontier of one, so that the table keeps three rows.
20. As a reader of the glossary, I want the unit called a task, its beads issue type, with "ticket" on the avoid list, so that "ticket" never stands for any level of the hierarchy.
21. As a reader of the glossary, I want a **Standalone task** entry, so that a task with no story has a name.
22. As a reader of the glossary, I want the task orchestrator and story orchestrator entries to say who lands and who delivers, so that the roles match the skills.
23. As a reader of the runbook, I want the small-bug route to be one `bd create` and `/dev:implement-task`, so that a small bug needs no epic bead and no hand close.
24. As a reader of the runbook, I want stage 4b to name `/dev:implement-task` and nothing to name `/mattpocock-skills:implement` or `/mattpocock-skills:to-tickets`, so that the plugin has one route per unit.
25. As a person with an epic bead that has a non-story child, I want a one-line refusal naming the child, so that a malformed epic is fixed by hand rather than routed somewhere.
26. As a person running `/dev:triage`, I want an accepted item to be a standalone task that `/dev:implement-task` delivers, so that triage's output has a route.
27. As a person writing a standalone task, I want `## Test seams` to be optional on its body, so that a small bug needs no named seam while a reviewer still enforces one when it is named.
28. As a person running `/dev:implement-task`, I want the check command resolved by the same `make` probe `/dev:implement-story` uses and the same refusal when there is none, so that every owner repo's one check target gates every row.
29. As a person running `/dev:implement-task` with no forge, I want the pushed branch as the deliverable and `checks: skipped: no forge` in the report, as a story gets, so that the no-forge path is one path.
30. As a person running `make ci`, I want the glossary lint to prove the rename, so that no doc outside the ADRs says "ticket" after it.
31. As a person reading an ADR written before the rename, I want its text and filename unchanged with an allowlist line, so that history reads as it was written.
32. As a person reading ADR 0014, I want a note that its landing decision is superseded in part by the new ADR, so that the two agree on which is current.
33. As a person reviewing the change, I want the rename as its own commit ahead of the restructure, so that churn and behaviour are read apart.
34. As a person cleaning up after a run, I want worktrees and branches prefixed `task/`, and a `ticket/` worktree an older run left reported rather than removed, so that the sweep never removes what it does not recognise.
35. As a person running `/dev:implement-spec`, I want nothing to change in what I type or read, so that the epic row is untouched by this.

## Implementation Decisions

**Order of work.** Two commits, in order. The first renames the unit across the skills, the
agent docs, the runbook and the README, with the glossary already renamed; it is mechanical
and ends green under `make ci`. The second is the restructure. The order is forced: the
glossary lint flags every `_Avoid_` word in prose, so the glossary change and the prose
rename cannot be apart. ADR prose is allowlisted per file rather than rewritten; ADR
filenames keep their old words.

**The rename.** Ticket → task everywhere the unit is meant: the task row, the task
orchestrator, the task cut, the publish task, the human gate task, `ready-for-agent` tasks.
"Jira ticket" stays an avoid term under Jira Epic. The harness's own "task" (`TaskStop`, a
task notification) is named by its tool, never by the bare word, and the glossary says so.
Branch and worktree prefixes become `task/<slug>`; the clean-up sweep's shape test reads
`refs/heads/task/<slug>` at `<owner>/.worktrees/<slug>`, so a `ticket/` worktree from an
older run is reported as not a task worktree and left in place.

**`/dev:task-orchestrator`.** A skill in the plugin, spawned only; typed bare it refuses
with one line naming the two skills that spawn it. It is the task row of the rules doc's
table: claim, one implementer in a worktree, the check gate (checks with records, the
two-axis review one tier up, none at `low`, fix-ups by pointer brief in the same worktree,
three per task and the fourth `failed`, minors to one last fix-up or the inbox), and one
report line: `reviewed: <branch> <worktree path> <tip SHA>`, `needs split: <cut>`, or
`failed: <reason>`. It never touches the owner checkout and never closes the task. It has
two entries and no modes: at claim for a fresh task, at the gate when the branch already
carries commits (a cut-off's replacement, or a retry after a conflict resolution's red),
selected by the brief. Its brief carries only what the story run alone knows: task id,
owner path, integration branch, check command, published version if any, plugin root as a
literal path, and on a retry the first failure's reason (for a gate entry, the branch tip
and the red record's log). Story id, Jira key, tier, home and session mode it derives from
the task bead.

**The story row lands.** `/dev:implement-story` spawns task orchestrators with the short
brief and, in the turn each `reviewed:` report resumes, lands that branch: the
stray-commit check, `git merge`, and on a conflict an implementer in the task's worktree
briefed to merge the integration tip into the task branch, the resolved tree checked with
the rules doc's check-record call, then `--ff-only`; at most three resolutions per landing,
the fourth `failed` with the merge aborted. A red on a resolved tree ends that landing
`failed: red after conflict resolution`; the task's one retry (the existing first-failure
rule) is a fresh task orchestrator entering at the gate on the resolved branch. A landing
closes the task. Landings are serial by construction, one notification per turn, so the lock
wait and its `index.lock` / `MERGE_HEAD` probe are removed, and the story gate's fix-up
branches land by the same procedure. Everything else in the story row is unchanged.

**`/dev:implement-task`.** A typed skill. It reads the bead and refuses with one line when
it is not of issue type `task`, when its parent is a story (naming `/dev:implement-story
<story-id>`), or when it is not `ready-for-agent`; it is run in the repo whose beads hold the
task, a workspace's own tasks included. It is the story row with a frontier of one: the
story orchestrator's plumbing (the check command by the same `make` probe and the same
refusal with none, the default branch, the forge decision, the gitignore rule, the branch
`task/<id>` off the default branch with a `branch:` note), one task orchestrator spawned
with the same brief shape, and on `reviewed:` the rules doc's Delivery: the stray-commit
check, the push, the PR via `mattpocock-skills:pr` with the check record as Evidence, the
forge-check wait, then `delivered:` and `pr:` notes and the close. There is no story gate:
the task gate is the review, and its green record on the same tip is the check. The PR
opens ready, not draft, since no spec sits above the task's own body. The merge guard
applies on a rerun by the `pr:` note; a rerun on a failed task re-enters by the `branch:`
note at the gate with a fresh budget. The report is the story block minus the story lines.
The rules doc describes it in one paragraph under the table; the table keeps three rows.

**Shared procedures move to the rules doc.** The check-record call (the one compound Bash
call that writes a record) and a Delivery section parametrised by the unit (story or
standalone task) live in the orchestration rules; both skills cite them. The draft PR, the
sibling line and the sibling refresh stay in `/dev:implement-story`. No skill points at
another skill's step numbers. The harness doc's pointer at the lock wait is dropped with the
lock.

**Flat epics retired.** The runbook's small-bug route becomes a standalone task: one `bd
create` (or an accepted retro item from `/dev:triage`), then `/dev:implement-task`. Stage 4b
names `/dev:implement-task`; `/mattpocock-skills:implement` and `/mattpocock-skills:to-tickets`
leave the runbook, the tracker doc and the skills. An epic bead with a non-story direct
child is a malformed epic: both implement skills and the epic gather refuse with `<epic-id>
refused: <child-id> is not a story` and point nowhere. The words "flat epic" and the legacy
shape paragraph go; ADR 0006 keeps its history.

**Test seams on a standalone task.** Its body may carry `## Test seams`; absent, the
reviewer's "no test at a story seam" blocking case does not apply and the implementer puts
tests where `tdd` agrees them. `/dev:triage` is unchanged.

**ADR 0016**, "the story row lands its tasks": supersedes in part ADR 0014's "the ticket
orchestrator lands its ticket", with a superseded-in-part note on 0014 in the style of the
amendments it already carries; records the rename in one sentence; moves the
three-resolutions budget to the story row in the table. The plugin version is bumped on
merge.

**Unchanged.** `/dev:implement-spec` and the epic row; the check gate's loop, budgets and
review verdicts; the Frontier rules; the inbox capture; the forge decision; the TMPDIR line
and the harness doc's other rules.

## Testing Decisions

- A good case pins what a doc must say or must no longer say and is proven by a regression
  case that drops or swaps the line and expects the lint to fail; it tests the words an
  agent reads, never how a script is written.
- Seam one: the skill-doc lint under `make ci`, extended. A section for
  `/dev:task-orchestrator`: the spawned-only refusal, the two entries, the `reviewed:` line,
  no owner-checkout write. A section for `/dev:implement-task`: the story-task and non-task
  refusals, the PR opened ready, the close at delivery, the merge guard. Pins on
  `/dev:implement-story` for the landing: serial, no lock, three resolutions, red on a
  resolved tree → `failed` and the retry at the gate. Pins on the rules doc for the Delivery
  section and the table's changed task-row cell. `lacks` sweeps for the retired words: the
  lock wait, `index.lock`, flat epic, the small-bug path, `/mattpocock-skills:implement`,
  `to-tickets`, chore. Each pin with a drop-line case in the lint's own test. Prior art: the
  one-loop-three-rows spec's pins and cases.
- Seam two: the glossary lint, free. "ticket" on Task's `_Avoid_` list makes every tracked
  doc a test of the rename; the ADR allowlist lines are the one exception, each with a
  reason.
- Seam three: the script tests that exist (`test-readme.sh`, `test-ci-workflow.sh`,
  `test-check-target.sh`), unchanged, prove the rename broke no named command.
- Agent seam, not scripted: one dry run of `/dev:implement-story` on the stories fixture,
  reading the briefs it produces and one landing; one of `/dev:implement-task` on a
  hand-made standalone task in a throwaway repo, reading the PR it opens. `/dev:retro`
  catches what the pins miss.
- No new test script, no new fixture.

## Out of Scope

- Any change to the check gate's behaviour: budgets, the review axes, the `low` tier's
  review skip, the minors rule.
- `/dev:implement-spec` and the epic row.
- A `/dev:close-task`: a standalone task closes at delivery.
- Running several standalone tasks as one unit: that is a story.
- Required test seams on standalone tasks, or any change to `/dev:triage`.
- Rewriting ADR prose for the rename.
- Migrating existing `ticket/` branches or worktrees.
- Renaming the beads issue type or any `bd` vocabulary.

## Further Notes

- The grilling that produced this spec rejected: a typed `/dev:implement-task` that also
  serves as the spawned skill (two modes in one skill); a `/dev:implement-chore` as the
  typed delivery (`chore` is a Conventional Commits type the repo enforces, and the branch
  `chore/<id>` would deliver `fix:` commits); keeping "ticket" as the unit's name; and
  wrapping a small bug in a story of one task (a story bead per bug and a redundant
  story-gate review).
- The story orchestrator sending a red-on-resolved-tree to a fix-up itself was rejected
  because it would make the story row run a task-row gate and read a task's budget notes.
- The glossary is already renamed in the working tree; the first commit makes the rest of
  the repo agree with it.
