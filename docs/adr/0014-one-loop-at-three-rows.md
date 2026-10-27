---
status: accepted
---

> Supersedes ADR 0001 (two review tools, one tier up, at two stages).

> Amended by ADR 0015 (`docs/adr/0015-every-owner-repo-has-a-check-target.md`, dev-0l6,
> INFRA-33, 2026-10-27): every owner repo has a `check` target, so the review-only gate below is retired,
> with the two amendments that patched it.
>
> Amended by dev-5e4 (INFRA-33, 2026-10-27): a `low` ticket in a repo with no check command
> is reviewed, so no ticket lands with neither a check nor a review. The why is in
> `docs/agents/orchestration.md`, Check gate.
>
> Amended by dev-2p5 (INFRA-33, 2026-10-27): a review-only gate takes no minors fix-up, its minors
> going to the inbox, so a commit after the clean review never lands with neither a check nor a
> review; a ticket's conflict resolution waits for the story row's standards axis
> (`docs/agents/orchestration.md`, Check gate).

# One loop at three rows, one check command, one review tool

The orchestration had two check-and-review loops that were almost the same, a different
review tool at each, and a role (the merger) that existed to land a ticket. A reader had to
re-derive which rule applied where, and the same tree was checked up to four times. It is
now stated once: **one loop run at three rows** (ticket, story, epic). Each row claims a
unit, has a subagent build it, checks it, reviews it, sends a failure to a fresh fix-up or
lands it one level up, and reports one line. The model doc (`docs/agents/orchestration.md`)
holds the table of each row's parameters; this ADR holds why the loop is one.

## Decision

- **One check command, and every tree is checked once.** A repo's check command is
  `make check` when its Makefile has a `check` target, otherwise none and the gate is
  review-only. A check is one run of that command on a tree, named by the tip's tree SHA;
  the orchestrator who runs it writes a check record, and a later agent at any row that
  reaches the tree treats it as checked. An implementer's own runs never count. Test seams
  stop being a list of checks: they stay the story's testing boundary, handed to the
  implementer as where its tests go and to the reviewer as where the criteria must be
  exercised.
- **One review tool with two axes, the spec parametrised.** `mattpocock-skills:code-review`
  runs at every row, one tier above the implementer. Its spec axis takes the row's own unit
  (the ticket's body, the story's body, the Jira Epic's spec). Its standards axis reviews
  only what entered since the last standards review: the ticket diff at the ticket row, the
  conflict resolutions and cross-ticket coherence at the story row, nothing at the epic row.
  So the per-ticket review is no longer vacuous (its spec is the ticket's acceptance
  criteria) and no line is read for standards twice.
- **The ticket orchestrator lands its ticket.** It waits on the owner checkout's lock, runs
  the stray-commit check and merges. A conflict goes to an implementer in the ticket's
  worktree, briefed to merge the integration tip into the ticket branch; the orchestrator
  then fast-forwards. The resolved tree is checked, not re-reviewed at the ticket row.
- **One gate.** At every row the gate exits when the checks are green on the tip the review
  called clean; three fix-ups per unit, the fourth is `failed`.

## Considered options

- **The two-tool review ADR 0001 chose**: the built-in review per ticket for
  correctness, `mattpocock-skills:code-review` per story for standards and spec, with the
  reviewer spawned by the orchestrator so it runs one tier up. Rejected because its reason
  no longer holds: ADR 0001 gave the ticket a different tool since a ticket's spec was one
  bead body and the Spec axis had little to check, but the ticket's acceptance criteria and
  the story's test seams are a usable spec, and a scoped standards axis stops repeating work
  across rows. Two tools meant two loops with two exits.
- **A per-row check list**: each row names the commands it runs (lint, then each test seam
  cheapest-first). Rejected because every role was told separately when to run what, which
  checked one tree four times and made the gate differ by row. One command per repo, keyed
  by tree, lets a record from any row count at every other.
- **A merger kept as a role**: a separate agent between the ticket's gate and the
  integration branch, so an orchestrator never resolves a conflict. Rejected because the
  guarantee it bought (an orchestrator never edits a file) holds without it: a `git merge`
  that applies is a command, not an edit, and a conflict goes to an implementer. The merger
  re-checked trees the ticket orchestrator had just checked.

## Consequences

- Five roles, named by their row: epic orchestrator, story orchestrator, ticket
  orchestrator, implementer, reviewer. The merger and the fix-up implementer are not roles;
  a fix-up is a brief shape of the implementer.
- A repo with no `check` target gets a review-only gate, so adding the target is how a repo
  opts in to checks.
- `low` tickets still have no review; their checks are the gate. Amended: with no check
  command their gate is the review (see the note above).
- The reviewer's blocking cases gain one: no test at a story seam exercises the unit's
  criteria. That is where TDD is enforced now that the gate does not run seams one by one.
- Docs must never name the review skill bare, `code-review` with no namespace: four skills
  answer to that name in a session.
- ADR 0001 keeps its text and points here.
