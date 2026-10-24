---
status: accepted, amended by ADR 0007, ADR 0008 and ADR 0011
---

> Amended by `0007-ticket-cut-runs-story-cutters-in-waves.md`: the story cut and the
> ticket cut are two typed stages (`/dev:spec-to-stories`, `/dev:spec-to-tickets`), and the ticket
> cut runs one story cutter per story in dependency waves, reversing the "parallel
> subagents for the story-to-tickets cut" option rejected below. The story-per-repo shape
> and every other rule here are unchanged.

> Amended by `0008-session-mode-declared-by-where-it-starts.md`: "the home repo included"
> and "the home story included" below hold only for a repo session, whose one story is the
> home's. In a workspace session the home is the workspace root, which owns no story, so
> every story is parentless in its owner repo and tied to the feature by its Jira key. The
> story body's `## Parent` line reads `Home <home name>, epic bead <epic-id>, <KEY>-<n>`.

> Amended 2026-10-22 (chezmoi-afn, INFRA-27): "any of its tickets" in the first
> consequence below counts children the way the finished story does (chezmoi-wgi). A child
> carrying `needs-triage` or `wontfix` is a note an earlier run left under the story, not a
> ticket: `/dev:close-story` skips it, and it stays open for `/dev:triage`. The `ready-for-human`
> publish ticket is a ticket and must still be closed.

> Amended by `0011-a-story-is-one-pr-and-stories-form-a-dag.md`: a story is one PR, and a
> repo holds one story per PR, usually one. "One story per repo" below reads that way, and
> the first consequence's "a resumed `/dev:implement-spec` never waits on `/dev:close-story`" no
> longer holds: a story may be blocked on another story's closure.

# A feature is cut into one story per repo, and every feature-level skill drives story-level ones

A feature's beads were a flat tree: an epic bead with ticket children in the home repo, and
parentless cross-repo tickets elsewhere tied to it only by the Jira key. One orchestrator
in the home repo drove tickets in every repo, so the `/dev:implement-spec` text carried a
per-repo clause for every step and its context reached 400-500K tokens on a single-repo
run. We add one tier: a **story** per repo the feature changes, the home repo included, a
`story`-type bead in that repo carrying the epic's Jira key, parent of that repo's tickets,
and the only place its integration branch and PR are recorded (`branch:` and `pr:` notes).
Cross-repo blocking moves to the story: the dependent story carries the one text blocker
naming the publish ticket, and no ticket of a story is on the frontier while a text blocker
of its story is open. Jira never sees a story; the one Jira comment groups tickets by story.
Each feature-level skill becomes a thin, user-typed driver over a model-invokable
story-level skill: `/dev:spec-to-tickets` over `/dev:story-to-tickets`, `/dev:implement-spec` over
`/dev:implement-story`, `/dev:close-epic` over `/dev:close-story`. `/dev:implement-spec` spawns a **story
orchestrator** per story whose text blockers are closed, the home story included, and each
story orchestrator spawns a **ticket runner** per frontier ticket that owns one ticket's
claim, implementer, reviewer, merger and close and reports one line. Both run at `opus`,
and so does the driver session (`/model opus` at stage 4a, replacing the runbook's sonnet).
`/dev:implement-story` shapes its own PR body with `mattpocock-skills:pr` at delivery, so `/mattpocock-skills:pr`
leaves the runbook's main line. A story's review runs at the highest review model among
its tickets; a story carries no complexity label of its own. Epics in the old flat shape
are refused as legacy, with no compatibility path.

ADR 0003 stands for sequencing (dependency publishes, then dependents migrate) and is
amended where it speaks of cross-repo tickets and per-ticket text blockers.

## Considered options

- **"Lane", "leg" or "part" as the name.** The agile "story" is a vertical slice of user
  value, which is what tickets already are, and the glossary parked "story" on two Avoid
  lists because Jira has Stories. Kept "story" anyway: bd has a native `story` type, Jira
  Stories are never created here, and the glossary fixes the meaning. Revisit if the
  overload bites.
- **The epic bead doubling as the home story.** Saves one bead per feature. Rejected: every
  per-repo rule would carry an "unless it is the home repo" clause, which is the shape that
  made the flat skill unreadable. `bd ready --parent` recurses, so grandchild tickets cost
  nothing; `bd children` does not, so `/dev:close-epic` walks two levels.
- **A Jira Story per repo.** Rejected for the reason ADR 0003 rejected a Jira Epic per
  repo: it doubles the human-facing surface for every library change, and nothing a human
  needs lives there.
- **Separate sessions per story instead of nested orchestrators.** The user types
  `/dev:implement-story` in each repo; no `bd -C`, hand-rolled worktrees or `/add-dir`
  preflight at all. Rejected as the default because it loses AFK across independent
  stories, but it falls out for free: the story skill is parametrised by owner repo, so it
  runs unchanged when typed in that repo's own session.
- **Headless `claude -p` per story.** Fully separate and fully AFK. Rejected for now:
  untested under the sandbox and permission modes.
- **One parametrised skill per level instead of two.** Rejected on one fact: a subagent
  cannot invoke a skill marked `disable-model-invocation` (probed), and the gate is per
  skill, so a driver that stays user-typed cannot also be the spawnable story skill.
- **Parallel subagents for the story-to-tickets cut.** Rejected: the dependent's tickets
  depend on the API the dependency's tickets define, so one context should see both, and
  subagents cannot quiz the user, so every granularity edit would be relayed. The cut runs
  inline, in sequence, with one merged quiz.
- **`sonnet` for story orchestrators and ticket runners.** The runbook's rationale for the
  stage 4a session. Deferred: a 400-500K context was observed on sonnet and the cause is
  not yet known (`chezmoi-cf0`); `opus` until it is.
- **A story without the ticket runner.** Stories cap tickets per orchestrator but not the
  per-ticket churn (polls, reports, relayed findings). The runner bounds each context by one
  ticket. Depth-three nesting (driver → story orchestrator → ticket runner → implementer)
  was probed and works.

## Consequences

- `/dev:close-story` refuses while any of its tickets is open, the `ready-for-human` publish
  ticket included; closing the publish ticket with the published version stays a separate,
  deliberate command. Closing a story is bookkeeping: the dependent story's text blocker is
  the publish ticket, so a resumed `/dev:implement-spec` never waits on `/dev:close-story`.
- The story body holds one paragraph of what the repo delivers, its test seams, `## Parent`
  (home repo, epic bead, Jira key) and `## Blocked by`; never a copy of the spec.
- The `/add-dir` preflight checks only stories that can start this run.
- Shared rules (orchestrator role, scratch space, tier mapping) move to a doc under
  `docs/agents/` so neither skill of a pair loads the other's text.
- The plugin's `/mattpocock-skills:to-tickets` keeps its name and stays the flat, no-story path for the
  runbook's small-bug variant; `/dev:close-epic` refuses that shape, which is harmless since
  that variant has no Jira epic.
- The in-flight epic under LAB-14 finishes on the old skills.
