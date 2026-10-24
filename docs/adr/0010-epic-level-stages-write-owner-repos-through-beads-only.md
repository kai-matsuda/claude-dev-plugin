---
status: accepted
---

# The epic-level stages write to an owner repo only through its beads database

The story cut (`/dev:spec-to-stories`) wrote its exploration of each owner repo to that repo's
`.spec-notes/<epic-id>/story-cut.md` (ADR 0007). A file in an owner repo must be ignored
before anything commits there, so the story cut also appended a `/.spec-notes/` line to
every owner repo's `.gitignore` and committed it behind a set of guards (a clean
`.gitignore`, a branch checked out, no merge in progress), with a hand-off to
`/dev:implement-story`'s Gitignore step for a line it could not commit. One short orientation
text had grown a commit procedure in every owner repo, at a stage whose job is to publish
beads, and the notes stayed on the one checkout that ran the cut.

The orientation now goes to the story bead's **design field**
(`bd -C <owner> update <story-id> --design-file -`), opened by a header line saying it is
orientation and that the story body stays the only contract. Nothing in ADR 0007 asked for
a file: the notes are the files and modules the spec touches, the boundaries behind the
test seams, the glossary terms and ADRs that bear on the repo, and for a pair the other
repo, the crate and its versions, which fits a bead text field. Every later reader (the
story cutter brief, `/dev:story-to-tickets`, `/dev:implement-story`'s exploration subagent) takes
it from the `bd show --json` it already runs, and the field travels with the bead over the
Dolt remote to every checkout that pulls it. The bead's notes stay `/dev:implement-story`'s line log of `branch:`, `review:`
and `pr:`.

The principle behind the move, recorded here so no later stage picks the habit up: the
**epic-level stages**, the story cut, the ticket cut and the `/dev:implement-spec` driver,
write to an owner repo only through its beads database, where the stories and tickets
belong by design. No file, no `.gitignore` line, no commit. Reading an owner repo's code
stays allowed (the story cut's exploration), so the working-directory preflight stays.
Files, `.gitignore` entries and commits in an owner repo are the story orchestrator's
alone, on that story's integration branch: `.spec-notes/<epic-id>/` and its gitignore
entry become `/dev:implement-story`'s, under the orchestration doc's Gitignore rule, which
already commits the worktree entries. The directory stays, since its exploration subagent
writes there and the PR body file lives there (sandboxed and unsandboxed runs see
different `$TMPDIR`s).

## Considered options

- **Keep the file and the guarded commit.** Already built and tested. Rejected: it is the
  one stage that breaks the principle above, every owner repo paid a commit for a text
  that fits a field, and a guard failure left a hand-off for the next stage to carry.
- **Keep the file, commit nothing, let `/dev:implement-story` ignore it.** Drops the guards but
  leaves an untracked file in every owner repo between the stages, visible to the user's
  own `git status` and lost on any other checkout. Rejected.
- **The notes in the story body.** One field fewer to read. Rejected: ADR 0007's line is
  that the story body is the only contract, and orientation beside it would read as one;
  the design field keeps them apart and is what beads provides for exactly this.
- **The notes on the epic bead.** One place for the whole feature. Rejected: the epic bead
  lives in the home's database, which a story cutter or orchestrator typed in an owner repo
  cannot reach, and the "epic bead writes" convention keeps that bead to the story cut's
  skip record.

## Consequences

- `/dev:spec-to-stories` writes no file and runs no git write in any owner repo; its step 8
  writes the design field, and its report loses its `notes:` line.
- The story cutter brief, `/dev:story-to-tickets` step 2 and `/dev:implement-story` step 2 read
  `.[0].design` and no longer name a file; the skipped-dependent case in `/dev:spec-to-tickets`
  reads the pair's crate and versions from the dependency story's design field.
- The orchestration doc's Orchestrator role carries the principle in one sentence and its
  Gitignore rule names the story orchestrator as the only writer of the entries; the lint
  pins both and retires `story-cut.md` across the skills, the agent docs and the runbook.
  `GLOSSARY.md` gains **Epic-level stage**.
- The story cut fixture test asserts the design field, a clean tree and an unchanged HEAD
  in every owner repo after the cut.
- ADR 0007 is amended: its `story-cut.md` and the `.spec-notes` slug it chose now apply
  to `/dev:implement-story`'s notes only. ADR 0003's "the cut stages write only beads,
  `.spec-notes` and one `.gitignore` line" narrows to beads alone.
