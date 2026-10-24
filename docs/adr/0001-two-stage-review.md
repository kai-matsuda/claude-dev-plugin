---
status: accepted, amended
---

> Amended by chezmoi-1d7 (INFRA-27 retro, 2026-10-20): findings no longer go back to the
> first implementer by `SendMessage` but to a fresh fix-up implementer in the same
> worktree. The why is in `docs/agents/orchestration.md`, Orchestrator role.

# Two review tools, one tier up, at two stages

`/dev:implement-spec` reviews code twice with different tools. Each `medium` or `high`
ticket gets a correctness review from the built-in `code-review` skill; the finished
integration branch gets a two-axis review (repo standards + fidelity to the spec) from
`mattpocock-skills:code-review`. The per-ticket review is run by a reviewer subagent
the orchestrator spawns at the ticket's review model, not by the implementer calling
the skill itself, because the built-in skill runs at whatever model invokes it and
our rule is that a reviewer sits one model tier above the implementer.

## Considered options

- **mattpocock two-axis review at both stages** (the plugin default). Its sub-agents
  accept a `model:`, so the implementer could run it and still get a one-tier-up
  reviewer. Rejected because a single ticket's "spec" is one bead body: the Spec axis
  has little to check per ticket, and the Standards axis repeats work the epic-level
  pass does over the same diff.
- **Built-in `code-review` called by the implementer, at higher effort.** Simplest and
  cheapest. Rejected because the review then runs at the implementer's own model; a
  same-tier reviewer shares the implementer's blind spots, which is the case the
  one-tier-up rule exists for.

## Consequences

- One extra hop per `medium`/`high` ticket: implementer reports → orchestrator spawns
  reviewer → findings go back to the implementer (`SendMessage`, so its context stays
  intact) → implementer fixes. Amended: see the note above.
- Effort for the built-in review follows the tier: `medium` → `medium`, `high` →
  `high`. `low` tickets have no review gate; green tests are the gate.
- Docs must never name the review skill bare, `code-review` with no namespace: four skills answer to that name in a
  session, and which one wins is an accident of load order.
