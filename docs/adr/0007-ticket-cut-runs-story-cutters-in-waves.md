---
status: accepted, amended by ADR 0008 and ADR 0010
---

> Amended by `0008-session-mode-declared-by-where-it-starts.md`: the cut stages no longer
> check the workspace root; a cross-repo feature is typed at the workspace root, so every
> owner repo is inside the primary working directory.
>
> Amended by `0010-epic-level-stages-write-owner-repos-through-beads-only.md`: the story
> cut's orientation lives in the story bead's design field, not in a `story-cut.md` file,
> and `.spec-notes/<epic-id>/` is `/dev:implement-story`'s alone. The story body stays the only
> contract.

# The spec is cut in two typed stages, and the ticket cut runs one story cutter per story in dependency waves

`/dev:spec-to-tickets` held both cuts of a spec in one skill: the story cut (one story per
repo, the pair and its version, the story quiz) and the ticket cut (each story into
tickets, the merged ticket quiz, publish, the Jira comment), with a resume path for a run
that stopped between them. It was the one feature-level skill that was not the thin driver
ADR 0006 asks for, and its one context explored and cut every repo of the feature. We
split it into two user-typed stages. **`/dev:spec-to-stories`** is the story cut: it ends at
the story quiz, publishes the stories, writes its exploration of each owner repo to that
repo's `.spec-notes/<epic-id>/story-cut.md` as orientation for every later stage, and adds
no Jira comment. **`/dev:spec-to-tickets`** is the ticket cut, a thin driver over
`/dev:story-to-tickets`: it refuses an epic with no stories, spawns one **story cutter** per
uncut story in **dependency waves** (the dependency's story first, then its dependents with
the dependency's returned breakdown in their brief; chains are out of scope, so at most
two waves), runs today's one merged ticket quiz itself and applies the user's edits to the
returned blocks, publishes inline and in dependency order by calling `/dev:story-to-tickets`,
and adds the one Jira comment. A cutter is a subagent that calls `/dev:story-to-tickets`,
inherits the session's model (unless a default subagent model is configured), fetches the
spec from Jira itself as the alone path does, and creates nothing; it is spawned even for a
single-story feature, so the driver has one path.
Both stages run the `/dev:implement-spec` working-directory preflight, the story cut for every
non-home owner repo and the ticket cut for every story it will cut, so `/add-dir` is typed
once per session at the first stage that needs it. The story body stays the only contract
between the stages and never carries the spec; the notes are orientation. The `.spec-notes`
slug at every stage is the epic bead id, since it exists with or without a Jira key.

This reverses the "parallel subagents for the story-to-tickets cut" option ADR 0006
rejected. Its two objections are answered rather than dismissed: the dependent's cutter sees
the dependency's tickets because the waves hand them over, and nothing is relayed to a
cutter because the driver owns the quiz and the edits and the cutter only ever drafts.

## Considered options

- **One driver that calls `/dev:spec-to-stories` inline and then fans out.** One command for
  the user. Rejected: the called skill would have to drop `disable-model-invocation`,
  which every feature-level skill carries, and the glossary's Stage is named by the
  command you type; two stages with their own quizzes are two stages.
- **The ticket quiz inside each cutter, or no ticket quiz.** Subagents cannot quiz the
  user (ADR 0006), and dropping the quiz trusts the story quiz alone. Rejected: the
  driver quizzes once and edits the blocks; the cutter is never asked to redo anything.
- **A spec snapshot file written by the driver, or the spec embedded in each story bead.**
  Both spare the cutter a Jira call. Rejected once a probe showed the Atlassian tools work
  inside a subagent without a prompt: a fetch per cutter costs seconds, sees every comment
  up to the cut, and the not-in-Jira and no-key fallbacks already exist in
  `/dev:story-to-tickets`. Embedding was also already refused by ADR 0006 (story bodies are the
  most-read beads in the flow). "Every spec always in a file the epic bead names" is a
  separate decision about where specs live, parked.
- **The Jira key as the `.spec-notes` slug.** Deterministic but couples agent-side scratch
  to Jira; a feature with no key needs a fallback anyway. The epic bead id is the feature's
  identity in every mode.
- **Exploration subagents per repo at the story cut.** Bounds that stage's context too.
  Deferred: the split decision needs one context that has seen every repo, the story cut's
  exploration is shallow, and features rarely touch more than two repos.
- **Inline cut when there is exactly one story.** Saves a spawn, costs a second path in the
  driver. Rejected.

## Consequences

- Partial state resumes: `/dev:spec-to-tickets` cuts only the stories with no tickets, reports
  the rest as already cut, reads an already-cut dependency's tickets from beads for its
  dependent's brief, and refuses only when every story is cut. A failed cutter is reported
  and the run goes on with the blocks it has; a failed dependency cutter leaves its
  dependents waiting on that cut.
- `/dev:story-to-tickets` step 1 gains one spec fallback before "story body alone": the file a
  `Spec:` line on the epic bead names, read through `bd -C <home> show <epic-id>`, so the
  alone path and the cutter path are the same path. Its called mode keys on the role the
  brief assigns: "story cutter" for draft, and for publish the "Publish this block" brief
  that passes the approved breakdown; the bare word "publish" elsewhere in a brief does
  not select it.
- The runbook's stage 3 becomes 3a and 3b, both at fable; `/dev:workflow` points "no stories" at
  `/dev:spec-to-stories` and "some story has no tickets" at `/dev:spec-to-tickets`; the tracker doc
  and the orchestration doc say "story cut", "ticket cut" and `<epic-id>` where they said
  "cut one", "cut two" and `<spec-slug>`. `/dev:implement-story`'s exploration subagent reads
  `story-cut.md` first.
- `/dev:spec-to-stories` and the driver no longer track the plugin's `/mattpocock-skills:to-tickets` line by
  line; `/dev:story-to-tickets` keeps its re-sync note.
- Both stages' preflight also checks the workspace root holding `repos.yaml`, since the
  story cut reads the manifest before it can name any owner repo and `Read` is refused
  outside the working directories. A session that adds the root can edit every repo under
  it; ADR 0003's Consequences records why that session-scoped widening is accepted.
- Re-splitting stories stays out of scope: `/dev:spec-to-stories` refuses an epic whose stories
  exist, as `/dev:spec-to-tickets` did.
