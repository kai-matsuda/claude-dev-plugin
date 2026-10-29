---
status: accepted
---

> Supersedes in part ADR 0014 (`docs/adr/0014-one-loop-at-three-rows.md`): its decision
> "The ticket orchestrator lands its ticket", with the lock wait it named and the landing's
> conflict-resolution budget that ADR 0014's dev-6qi amendment note set at the ticket row.

# The story row lands its tasks

ADR 0014 had the unit's orchestrator land its own unit: it waited on the owner checkout's
lock, ran the stray-commit check and merged. The orchestrator waited on the owner checkout's
lock because several ticket orchestrators could land at once, and the task row (the ticket
row, renamed below) needed access to the owner checkout so it could merge. Landings are in fact serial by
construction: a task orchestrator reports its reviewed branch, and the story orchestrator
resumes on one report at a time. With landings serial, the lock and the task row's
owner-checkout access guarded nothing, and they kept the task row from being a plain skill
that any orchestrator could run with a frontier of one.

## Decision

- **The story row lands its tasks.** The task orchestrator reports its reviewed branch and
  never touches the owner checkout. The story orchestrator, in the turn that report
  resumes it, runs the stray-commit check and merges the task branch onto the integration
  branch. A conflict goes to an implementer in the task's worktree, briefed to merge the
  integration tip into the task branch; the story orchestrator checks the resolved tree and
  fast-forwards. The resolved tree is not reviewed again at the task row: the story row's
  standards axis sees it. A landing closes the task. No lock is needed.
- **The three-resolutions budget moves with the landing.** A landing takes at most three
  conflict resolutions, apart from the fix-up budget, so the story row holds the budget,
  three conflict resolutions per landing, where ADR 0014's dev-6qi amendment note put it
  at the ticket row.
- **The task row is reusable.** With no lock and no owner-checkout access, a story
  orchestrator can run it as one skill over a frontier of one, the same row it runs over a
  frontier of many.
- **The unit is renamed.** What ADR 0014 calls a ticket is a task throughout; the rename
  changes no behaviour.

## Considered options

- **The story row sending a red resolved tree to a fix-up itself**: after a conflict
  resolution, a red check goes straight to an implementer on a fix-up brief from the story
  row. Rejected because the story row would then run a task-row gate and read a task's
  budget notes, work that belongs to the task row.
- **A typed skill that is also the spawned one**: one skill a human types and a story
  orchestrator spawns as the task row. Rejected because it puts two modes in one skill: a
  typed skill authorises delivery (ADR 0009) while a spawned row only reports a branch.
- **A chore skill**: `/dev:implement-chore` as the typed delivery skill. Rejected because
  `chore` is a Conventional Commits type the repo enforces, and the branch `chore/<id>`
  would deliver `fix:` commits.

## Consequences

- ADR 0014 keeps its text, with a note pointing here; its other decisions stand.
- The rules doc's table and its Landing a task paragraph state the story row as the lander.
