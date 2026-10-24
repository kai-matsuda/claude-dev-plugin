---
status: accepted
---

# The typed implement command is the authority to push and open the PR

`/dev:implement-story`'s deliver step pushed the integration branch "when the active profile
permits; otherwise ask the user to run that exact command and wait for it". The Beads
profile block in the user-level `CLAUDE.md` forbids pushes "unless explicitly asked", so
a story orchestrator read the profile as conservative and waited. Spawned by
`/dev:implement-spec` in the background, it had no user to ask: INFRA-28's run 2 (2026-10-20)
ended with the push pending, the feature needed a hand push and a third run, and the
story bead went without its `pr:` note until then. The same settings file listed the PR
commands under permissions `ask`, which bypass mode skips, so run 3 opened the PR with no
prompt and no rule saying it could.

Typing `/dev:implement-spec` or `/dev:implement-story` is now the explicit ask. The skills exist
to deliver a PR, the run already commits through its subagents on that authority, and the
push and the PR are the same deliverable: the orchestrator pushes and opens the PR
without asking again. The permission mode stays the user's gate: in a prompting mode an
unsandboxed `git push` or forge command prompts like any other, and bypass mode is the
user's choice to skip that. A refused push (no `origin`, no login, a denied prompt) ends
the run with a `failed: push <command>: <error>` line and no `PR:` line; the merges stay
on the local branch and the next run pushes again. The push and PR entries leave the
settings `ask` list, since they restated the retired rule and were inert in bypass mode
anyway; `git push --force` and publishing stay denied, and the deny now also matches the
`git -C <owner> push --force` form the skills run, which only the removed `ask` entry
had caught.

## Considered options

- **A human stop carrying the push and PR commands on a `human:` line.** Keeps the
  profile's letter. Rejected: every feature would need a hand push and a rerun to reach
  its `pr:` note, the sibling line and `/dev:close-story` would have no PR to read until
  then, and a human stop means an open `ready-for-human` ticket (`GLOSSARY.md`), which
  this is not.
- **Asking only in the typed form, pushing only when spawned.** Rejected: one procedure
  parametrised by the owner repo is what `/dev:implement-story` is, and the authority is the
  same command either way.
- **Keeping the `ask` entries as a second gate.** Rejected: they prompt only where the
  permission mode already prompts (push and the forge CLIs run outside the sandbox and are
  not in `allow`), and they vanish in bypass mode, so they decide nothing the mode does
  not; what they did was contradict the rule above on paper.

## Consequences

- A run of `/dev:implement-spec` or `/dev:implement-story` ends with the PR open or a `failed:
  push` line, never waiting for the user. The run is AFK, as the runbook's stage 4a says.
- Stage 4a of the runbook stays as written (AFK, the run opens the PR); a skill that
  delivers a branch cites the rules doc's Delivery paragraph, never the Beads profile.
- A user who wants to confirm each push runs the skill in a prompting permission mode; the
  prompt reaches them from the background orchestrator and a denial is reported as a
  refused push.
- The `failed:` line in a stall report can now name a push or a seam with every ticket
  closed (`GLOSSARY.md`, "Stall").
