---
status: accepted
---

# A story is one PR, and a feature's stories form a DAG

ADR 0006 cut a feature into one story per repo and made the story the unit that carries
an integration branch, a review and a PR. ADR 0003 allows a feature that delivers the same
repo twice: an expand-migrate-contract refactor publishes after expand and again after
contract, and a point release re-publishes a dependency when a migration exposes a flaw in
its API. The skills could not do either (`chezmoi-ays`). A **finished story** was never
touched again, so new agent work in a delivered repo had nowhere to go but the old story's
branch and PR, merged or not; `/dev:spec-to-tickets` refused any story that was both a
dependent and a dependency as a chain, and its waves were capped at two; the only text
blocker a story could carry named a publish ticket, and a feature was allowed one.

We decide that **a story is one PR**: one integration branch, named `feat/<story-id>`, one
PR, re-reviewed whenever its tip moves (the review marker), re-deliverable while the PR is
open, and sealed once it merges. "One story per repo" becomes **one story per PR, usually
one per repo**. New work in a repo whose story's PR has merged is a new story there, never
a ticket under the old one. A feature's stories form a **DAG**: every edge is a text line
under `## Blocked by`, in any repo's database including the story's own, naming either a
**human gate ticket** (a `ready-for-human` ticket a person closes; the publish ticket is
one, closed with the published version) or a **story**, which clears when `/dev:close-story`
closes it after its PR merges. Cycles are refused; chains are not. Edges are written
minimally, direct needs only, never one implied by a path through a gate ticket. Native
edges stay what they were, between the tickets inside one story. One publish ticket per
story, since one PR publishes one version.

`/dev:spec-to-stories` proposes one story per repo and splits a repo's story by itself only
when the spec describes a deprecate-then-remove; the user may split at the quiz for any
reason (two deliveries stacked on each other's closure, two independent slices, a
non-publish gate such as a deploy). On a feature whose stories already exist it enters
**add mode** instead of refusing, unless every story is closed: that feature is delivered,
and more work on it is a new feature, not an addition, so that one case is still refused.
Add mode shows the stories with their state, reads their
`failed twice:` notes, quizzes the additions (new stories with their edges and publish
versions, a second blocker line and bump on a dependent that is still open) and publishes
only those. For each finished story an addition touches it asks the forge once: a `MERGED`
PR forces a new story (and a `/dev:close-story`), an `OPEN` one defaults to a re-cut (a
`recut:` note on the story lets the ticket cut past its `pr:` note), a PR closed unmerged
is refused as `/dev:implement-story` refuses it, no forge asks the user. The addition's content comes from the conversation and the notes; the Jira
epic's description changes only when the feature's promise does. `/dev:spec-to-tickets` runs
its cutters in topological waves and re-cuts an already-cut dependent itself when a new
publish ticket lands. `/dev:implement-story` guards the one place a commit follows: a finished
story with an open `ready-for-agent` child gets one forge query, and a merged PR refuses.
`/dev:implement-spec` reports a story waiting on another story's closure as a **human stop**
(merge the PR, then `/dev:close-story`), and its Stall report points at add mode when a failure
names another repo's crate. The inbox is untouched: it takes **follow-ups**, work the
feature does not need to finish; what the feature needs is a story.

## Considered options

- **Delivery rounds inside one story**: `branch:`/`review:`/`pr:` notes grouped per publish
  ticket, a gate of "every child not behind an open publish ticket is closed", a new branch
  once the last PR merged. Rejected: it puts back into `/dev:implement-story` the per-round
  clause ADR 0006 removed, and it cannot reopen a story `/dev:close-story` has closed.
- **Sealing a story at delivery (`pr:` note) rather than at merge.** Beads-only and
  deterministic. Rejected: the common point release is found by the human reviewing the
  dependent's open PR, who wants the fix in that PR, not a flawed PR merged so a new story
  can branch from main. The price of sealing at merge is one forge query at the cut and
  one in `/dev:implement-story`, since beads cannot tell an open PR from a merged one until
  `/dev:close-story` runs.
- **Routing the point release through `/dev:retro` and `/dev:triage`.** The inbox is the one entry
  for work found after the cut. Rejected: it is the entry for work the feature does *not*
  need; a lib fix the migration cannot finish without is a change to the feature's story
  set, which the story cut owns. `/dev:triage` would also have had to learn versions and
  blocker lines.
- **A new `dev:add-story` skill.** A second router beside the story cut, with none of its
  quiz, exploration or dependency detection. Rejected.
- **Native edges between two stories in the same repo.** Possible, since they share a
  database. Rejected: every reader of story edges reads `## Blocked by`, and a second read
  path is the per-repo clause again; the same-repo edge is also always transitive through a
  gate ticket and would wait on `/dev:close-story` bookkeeping instead.
- **beads external dependencies and gates**, ADR 0003's "revisit when documented". Probed
  2026-10-22 on bd 1.3.1 in the fixture: `bd dep add <id> external:<project>:<capability>`,
  `bd config set external_projects.<project> <path>` and `bd ship` all work, but `bd ready`
  and `bd blocked` never honoured the edge, configured or not, shipped or not; `bd dep list`
  warns the target "has no row in this database". `bd gate` (`gh:pr` waits for a merge,
  `bead` for a close) is Gas Town formula machinery resolved through `routes.jsonl` and
  closed by `bd gate check` polling. Rejected on behaviour; the text blocker stays.
- **Branch names keyed by the Jira epic** (`feat/<key>-<n>`, suffixed with the story id
  only when a repo holds two). Rejected for `feat/<story-id>` always: one rule, it names
  the deliverable, and the keyless case already used it. Branches lose the key; commits
  (`Refs:`), the PR body and the story bead keep it.

## Consequences

- `GLOSSARY.md`: **Story**, **Story cut**, **Publish ticket**, **Text blocker**,
  **Finished story**, **Dependency wave**, **Human stop** and **Inbox** amended;
  **Human gate ticket**, **Point release**, **Follow-up**, **Story DAG**, **Publish
  edge**, **Story-closure edge** and **Merge guard** added.
- ADR 0003 is amended where it says chains are out of scope and a feature has one text
  blocker; ADR 0006 where it says one story per repo and that a resumed `/dev:implement-spec`
  never waits on `/dev:close-story`. A dependency repo publishing several crates stays out of
  scope: one PR publishes one version.
- `/dev:close-story`'s "the last `pr:` line wins" becomes the live path for every re-delivery;
  `/dev:close-story` promptness now matters, and the human stop line says so.
- The sibling line in PR bodies reads `<repo> <story-id> <url>`.
- The fixture gains a two-publish variant and a test for it; the one-publish shape stays
  green, with branch names the one visible change.
- `chezmoi-0m7` is superseded: a blocker naming a story means its closure, not its publish.
