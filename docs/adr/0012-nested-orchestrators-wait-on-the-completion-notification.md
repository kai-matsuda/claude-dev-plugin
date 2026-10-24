---
status: accepted
---

# Nested orchestrators wait on the completion notification; there is no foreground spawn

INFRA-27's run (2026-10-19) saw a story orchestrator spawn a child in the background,
end its turn, and watch the child's report go to the top-level session; it handed back
`failed` mid-task. The orchestration rules read that run as "a background spawn returns at
once, so a nested orchestrator (one that is itself a subagent) spawns in the foreground,
where the call returns with the report", and `/dev:implement-spec`, `/dev:implement-story`, the
ticket runner brief and `/dev:spec-to-tickets` each wrote `run_in_background` set to `false`
on their Agent calls. INFRA-29's run 2 (2026-10-23, `chezmoi-10j`) showed the rule rested
on a spawn that does not exist. Every Agent call in the chain, driver to story
orchestrator to ticket runner to implementer, carried the field as the JSON string
`"false"`, which is truthy, so each "foreground" spawn launched in the background; the
driver's own call, which omitted the field, launched async too; and a ticket runner
reported that the Agent tool it saw had no `run_in_background` parameter at all (Claude
Code 2.1.306). A probe the same day (a haiku parent spawning a haiku child that ran
`sleep` in a background Bash call and ended its turn) fixed the mechanism: a child's end
of turn is what its parent is notified of; a parent that ended its turn after spawning
was resumed by that notification, so long as the child was live; a child that ended a turn
with background work still running counted as idle, its parent was resumed with the
interim report and marked finished, and the child's real report escaped to the top-level
session.

We decide that **every orchestrator waits the same way**: it spawns, ends its turn, and is
resumed by the Agent tool's completion notification carrying the child's report. The
driver and a nested orchestrator (a story orchestrator, a ticket runner) are no longer two
cases, since an Agent call returns at once for both, and the driver never relays a report
by `SendMessage`. `run_in_background` is documented as a JSON boolean, with the probe's
finding beside it, and no skill writes it on an Agent call. The **idle rule** follows:
every subagent below the driver runs Bash in the foreground only (`timeout` up to
600000 ms) and never starts a background call or a `Monitor` on a bead, the merger's lock
wait included, because a turn that ends with one still running is reported to the parent
as finished with an interim result, and the real one is lost to the chain; a turn that
ends with an Agent child mid-turn keeps the parent waiting, which is how a nested
orchestrator waits at all. `/dev:implement-spec`,
`/dev:implement-story`, the ticket runner brief and `/dev:spec-to-tickets` point at the rules doc's
Waiting rule, and the skill-doc lint pins the agreed wording and fails any skill or agent
doc that says `run_in_background: false` again.

This supersedes the INFRA-27 reasoning the rules doc cited: the observation (a background
spawn's report goes to the top) was right, the remedy (spawn in the foreground) named a
mode the harness does not offer, and the observed failure was the no-polling rule's
mechanism, not an exception to it. `chezmoi-sn1`'s check (2026-10-22), which put the
merger's lock wait in a foreground Bash call because a background call ended the merger's
turn with nothing reported, stands: it was the idle rule seen once, before it had a name.

## Considered options

- **Keep the foreground spawn and fix the field to a real boolean.** The transcripts show
  the string, so the first reading was a serialisation slip. Rejected: the probe found the
  spawn async with the field omitted, and the runner found no such parameter on its Agent
  tool, so a boolean `false` has nothing to switch; the rule would still describe a spawn
  that does not exist and the next run would fail the same way.
- **The driver relays every escaped report by `SendMessage`.** What INFRA-29's run 2 did
  by hand, twice. Rejected: it makes the driver a message router for every nested level,
  it needs a human to notice the escape, and it only exists because the nested
  orchestrator ended its turn without the harness counting it as waiting, which the idle
  rule prevents.
- **Nested orchestrators poll the bead (`bd show` loop, `Monitor`) instead of waiting.**
  What the story orchestrator fell back to. Rejected: a `Monitor` is a background call,
  so it trips the idle rule itself; a foreground `bd show` loop holds a shell for the
  child's whole run and reports nothing the notification will not; and both woke agents
  with stale state in that run.
- **Flatten the chain so only the driver spawns.** No nested orchestrator, no escaped
  report. Rejected: ADR 0006 and ADR 0011 put the ticket runner's implementer, reviewer
  and merger below a story orchestrator on purpose, and the driver's context cannot hold a
  feature's every ticket.

## Consequences

- `orchestration.md`'s Orchestrator role, Waiting and Cut-off agents sections state the
  rule and the idle rule, cite the probe with version and date, and no longer say
  "foreground" of a spawn; a fresh session reading it knows that a ticket runner whose
  implementer was just spawned ends its turn and is resumed by the completion notification.
- `/dev:implement-spec` step 5, `/dev:implement-story` step 4 and its ticket runner brief, and
  `/dev:spec-to-tickets` step 3 end the turn after the batch and point at the Waiting rule;
  the brief carries the idle rule to every agent it spawns. `GLOSSARY.md` gains **Idle
  rule**, and its Dependency wave no longer says the wave runs in the foreground.
- `scripts/lint-skill-docs.sh` fails any skill or agent doc saying `run_in_background:
  false`, pins the Waiting and Idle rule wording in the rules doc and the pointers in the
  four skills; `scripts/test-lint-skill-docs.sh` covers the seeded violation.
- The merger's lock wait (`chezmoi-sn1`) is unchanged in form and now has its reason: the
  idle rule.
- The probe's finding is tied to Claude Code 2.1.306; a harness that later honours a
  foreground spawn changes nothing here, since ending the turn and being resumed by the
  notification works either way.
