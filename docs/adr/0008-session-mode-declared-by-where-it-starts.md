---
status: accepted
---

# Session mode is declared by where the session starts, never discovered by walking up

Every workflow skill used to discover whether it was inside a workspace: it walked up from
the session's repo to the nearest ancestor holding `repos.yaml` and, finding one, routed
across that workspace's repos. A session inside a checkout therefore behaved differently
depending on where the checkout happened to sit, and `/dev:retro` typed anywhere outside a
workspace (this dotfiles repo included) stopped and filed nothing.

The mode is now declared by the directory the session starts in. The session's repo is
`git rev-parse --show-toplevel`. If that directory holds `repos.yaml`, the session is a
**workspace session** and routes across the manifest's repos. Otherwise it is a **repo
session**, and any workspace above it is ignored entirely: no skill walks up. The two
modes apply to every skill of the feature workflow, the cut stages, the implement drivers,
the close stages, `/dev:retro` and `/dev:triage` alike.

The **home** is the database the session started in, a repo or a workspace. It holds the
feature's epic bead, the spec, and the **inbox**. Stories and tickets live in their owner
repos as before (ADR 0005, 0006); in a repo session the only owner is the home repo, so a
spec that visibly needs a second repo is refused with "start this at the workspace root"
rather than cut to a one-repo subset. A retro item whose fix lives outside a repo
session's home files there anyway, labelled `retro:foreign` with the intended location in
the body, and triage accepts it as `ready-for-human`: never dropped, never silently
crossing a repo boundary. Decisions keep ADR 0004's split whichever session writes them:
an ADR that spans repos goes to the workspace, one about a single repo to that repo.

## Considered options

- **Discovered mode (the walk-up), with a repo fallback for the retro only.** The smallest
  change. Rejected because two routing rules in one workflow is worse than either alone,
  and the walk-up is what made a session's behaviour depend on where a checkout sits.
- **A separate `workspace.yaml` marker.** Would let a workspace exist before it has a
  manifest and rule out a stray `repos.yaml` inside a checkout. Rejected for now: a
  workspace with no manifest routes nothing, so to the skills it is no workspace, and the
  header fields that look workspace-level already live in `repos.yaml`. A rename of
  `repos.yaml` to `workspace.yaml` is filed as a follow-up (`chezmoi-69m`), to ship with
  the matching `git mv` in the workspace.
- **Triage in place when the owner repo is the inbox's own database.** One bead per item
  instead of a routed bead beside a closed inbox bead. Rejected: it adds an exception to
  every sentence that describes the inbox, mixes relabelled beads into the record of closed
  inbox beads, and leaves the routed bead open where `/dev:retro`'s repeat check would
  annotate a ticket already being worked. Triage always routes the same way.
- **All ADRs at the home.** Rejected: a single-repo decision filed at the workspace is
  invisible to anyone working that repo alone.

## Consequences

- A cross-repo feature is started at the workspace root, and so are `/dev:implement-spec`,
  `/dev:spec-to-tickets` and `/dev:close-epic` for it. Every owner repo is then a subdirectory of
  the primary working directory, so the `/add-dir` preflight passes by construction unless
  a manifest `path` leaves the workspace.
- In a workspace session every story is in another database than the epic bead, so the
  epic bead must carry a Jira key: the rule that already held for any story outside the
  home repo now holds for all of them. The workspace's `CLAUDE.md` names the Jira project
  key like any repo's.
- A story cut in a workspace session can still be run with `/dev:implement-story` or
  `/dev:story-to-tickets` typed in its owner repo, as a repo session. What needs another
  database is then out of reach and degrades: the spec falls back to the story body, the
  sibling line is skipped, and a text blocker in another repo cannot be read and counts as
  open, so a dependent story is run from the workspace.
- A feature begun in a repo session that turns out to need a second repo is restarted at
  the workspace; a skill to move its context is filed as a follow-up (`chezmoi-bz8`).
- A home with no `.beads/` fails fast: `/dev:retro` stops with its candidate list as the
  result, the story cut offers `bd init` and acts only on an explicit yes, and the later
  stages refuse. No skill initialises a database unattended.
- ADR 0004's "found by walking up from any checkout" and its read of the workspace root
  from inside a checkout, ADR 0005's "the workspace's own beads database" and ADR 0007's
  preflight check of the workspace root (with the note it added to ADR 0003's
  Consequences), ADR 0003's home repo and ADR 0006's home story are amended by this
  decision; the manifest's location and the inbox's role are otherwise unchanged.
