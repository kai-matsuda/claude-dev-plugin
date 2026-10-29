---
status: accepted
---

> Supersedes in part ADR 0014 (`docs/adr/0014-one-loop-at-three-rows.md`): its decision
> "The ticket orchestrator lands its ticket", with the lock wait it named and the landing's
> conflict-resolution budget it carried.

# The story row lands its tasks

ADR 0014 had the unit's orchestrator land its own unit: it waited on the owner checkout's
lock, ran the stray-commit check and merged. The lock existed because several ticket
orchestrators landed at once, and the task row (the ticket row, renamed below) needed
access to the owner checkout so it could merge. Landings are in fact serial by
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
  three conflict resolutions per landing, where ADR 0014 and its dev-6qi amendment put it
  at the ticket row.
- **The task row is reusable.** With no lock and no owner-checkout access, a story
  orchestrator can run it as one skill over a frontier of one, the same row it runs over a
  frontier of many.
- **The unit is renamed.** What ADR 0014 calls a ticket is a task throughout; the rename
  changes no behaviour.

## Considered options

- **The story row sending a red resolved tree to a fix-up itself**: after a conflict
  resolution, a red check goes straight to a fix-up implementer from the story row.
  Rejected because the resolution is already an implementer's work in the task's worktree;
  a red check on that tree is that implementer's to fix within the landing's budget, and a
  second path for the same failure would split the budget in two.
- **A typed skill that is also the spawned one**: one skill a human types and a task
  orchestrator spawns. Rejected because a typed skill authorises delivery (ADR 0009) while
  a spawned row only reports a branch; one name for both blurs who may push.
- **A chore skill**: a small skill for the landing step alone. Rejected because the landing
  is two commands and a branch on a conflict, which the story row already runs in its own
  turn; a skill would add a spawn for no isolation.

## Consequences

- ADR 0014 keeps its text, with a note pointing here; its other decisions stand.
- The rules doc's table and Landing a task section state the story row as the lander.
