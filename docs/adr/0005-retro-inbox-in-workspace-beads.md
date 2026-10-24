---
status: accepted, amended by ADR 0008
---

> Amended by `0008-session-mode-declared-by-where-it-starts.md`: the inbox is the beads
> database of the home, the database the session started in. In a workspace session that
> is the workspace's beads as below; in a repo session it is the repo's own, and an item
> whose fix lives elsewhere is filed there as `retro:foreign` and triaged as
> `ready-for-human`. The lifecycle below is unchanged.

> Amended 2026-10-22 (chezmoi-wgi, INFRA-27): `/dev:retro` is no longer the inbox's only
> writer. A finding the story review of `/dev:implement-story` defers is captured there the
> same way, as a `needs-triage` retro item, and never as a child of the story, since the
> frontier admits only `ready-for-agent` tickets and a `needs-triage` child would sit in
> `bd ready` with nothing to implement. The lifecycle below is unchanged.

# Retro findings land in a workspace inbox; a human triages them into owning repos

`/dev:retro` reads a session and proposes environment improvements. Each candidate that traces
to a moment in the session is filed as a `needs-triage` bead in the workspace's own beads
database, the **inbox**, with a `target:<repo>` label naming the repo whose file the fix
would change. Nothing is applied. `/dev:triage`, run with the user present, collapses repeats,
shows each item against five tests (moment, recurrence, layer, blast radius, owner), asks
which to accept, and routes each accepted item as a bead in the owning repo with
acceptance criteria and a complexity tier. The inbox bead then closes with a reason naming
the routed bead. Rejected items close as `wontfix`.

## Considered options

- **The retro applies its own findings.** Fastest. Rejected because a new blocking check
  or a new coding standard affects everyone who commits, and the plugin's own docs record
  users burned by auto-installed hooks. A human decides what becomes permanent.
- **The retro asks for acceptance in the same session.** The plugin default. Rejected
  because `/dev:implement-spec` runs unattended and a retro chained after it has nobody to
  ask; the findings would be lost with the session.
- **A markdown inbox file in the workspace repo.** Reviewable and diffable. Rejected
  because it needs a format, grows without bound, offers no ids for the routed bead to
  point back at, and duplicates what `bd` already provides: labels, queries, close
  reasons.
- **Beads owned by the workspace for the whole lifecycle.** One place to look. Rejected
  because the work happens in the owning repo: claim, close, and the commit's `Bead:`
  trailer all resolve against that repo's database, and its own `bd ready` must show the
  work.
- **A bead in the owning repo and a Jira issue per item for visibility.** Rejected: two
  things to close that drift, and it breaks the rule that Jira never sees individual
  tickets. Visibility is one comment per triage run on a standing Jira epic, when the
  manifest names one.

## Consequences

- At most one open bead per item at any time. The inbox bead is open until triage; the
  routed bead from then on. Closed inbox beads are the record of every item's fate.
- A cross-repo view of routed beads needs `bd repo sync`, which reads each repo's
  `issues.jsonl`. JSONL export is off by default in beads, so that view waits until the
  repos receiving routed items enable `export.auto` in their `.beads/config.yaml`.
- `bd -C` writes into another repo's `.beads/` fall outside the sandbox's writable paths
  and run with the sandbox disabled, one command at a time. Widening the sandbox's
  writable paths to cover the workspace removes those prompts if they prove tiresome.
- The inbox's `target:` label is a guess by the retro. Triage confirms it against the
  manifest; `target:unknown` means the human is asked.
- Items that need a person, such as an access grant, route with `ready-for-human` and wait
  on the owning repo's frontier like any other bead.
