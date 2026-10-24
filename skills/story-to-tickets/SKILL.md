---
name: story-to-tickets
description: "Break one story bead into tracer-bullet tickets for its owner repo, with native blocking edges, published as children of the story. Use when given a story bead id to cut or re-cut into tickets, typed alone or called by /dev:spec-to-tickets or a story-cutter brief."
---

<!-- Derived from mattpocock-skills 1.3.1 engineering/to-tickets, steps 1-5 kept in the
     plugin's order. Local changes: the input is one story bead (legacy flat epic,
     non-story, closed and finished stories refused, a finished one unless add mode
     marked it with a recut: note), optionally in another repo (bd -C);
     context is the story body and its Jira epic; tickets for the owner repo only; one
     complexity tier per ticket; two modes, alone (quiz, then publish) and called (a "story
     cutter" brief returns the breakdown, a "Publish this block" brief publishes it); Spec: file
     fallback; the story's design field as orientation; re-cut edge moves; publishing, dependency-repo and
     re-cut rules live in ${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md; ticket template without
     `## Blocked by`. Re-sync against the plugin copy when it updates; keep those edits. -->

# Story To Tickets

Break one **story** (`GLOSSARY.md`: the part of a feature that lands in one repo) into a set of **tickets**: tracer-bullet vertical slices in that repo, each declaring the tickets that **block** it.

The issue tracker rules are in `${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md`. This skill performs its "When a skill says 'fetch the spec'" operation in step 1, its "When a skill says 'publish a story's tickets'" operation, and its "When the breakdown touches a dependency repo" section when the story is one side of a dependency pair. Read "fetch the spec" before step 1 and the other two before step 3.

**Input**: a story bead id, and `<path>`, the absolute path of its owner repo, when that is not the session's repo. With `<path>`, check `test -d <path>/.beads` first (missing → `no beads database at <path>`, stop), then run every `bd` call below as `bd -C <path> ...`, except step 1's epic bead read, which runs plainly in the session's own database (`<home>`'s). When a `bd -C` fails with `Operation not permitted`, the tracker doc's "bd writes outside the session's repo" says what to do.

**Names**: `<owner>` is `<path>`, or the session's repo (`git rev-parse --show-toplevel`) with no path, and every `bd` call but the epic bead read runs in `<owner>`'s database (plainly with no path). `<home>`, `<home name>`, `<owner repo>` and the session mode are as **the one test** in the tracker doc's opening defines them; in a repo session `<path>`, if given, is `<home>` itself. `<KEY>-<n>` is the story's Jira key: `## Parent`'s, else its `external_ref`. A story with no key gets no Jira fetch and no Jira comment, and its tickets' `## Parent` omits the key.

**Mode**:

- **Called**: a brief from another skill or agent: it names a caller, and may name a role. The **publish role** is a brief that opens `Publish this block` and carries the approved block, in the shape `/dev:spec-to-tickets` step 5 sends: `Publish this block, as approved at the /dev:spec-to-tickets ticket quiz: story <story-id> in the repo at <owner>.`, then one `Dependency:` line per publish blocker and one `Dependent:` line per dependent (each naming the story id and its repo), then the block. Step 5 runs on that block as the caller approved it; each of steps 1 to 4 says what the publish role runs of it. A `Publish this block` brief carrying no block → `<id> refused: publish brief carries no breakdown`, stop. A block whose header story id differs from the brief's `story <story-id>` → `<id> refused: publish block is for <header story id>, not <id>`, stop. Every other called brief (the "story cutter" brief, or a caller-only brief naming no role) is the **draft role**: step 4 returns the breakdown and creates nothing, edits nothing. For a dependency story the brief (draft or publish) carries its `Dependent:` lines, plus the crate and the version proposed at the story quiz; for a dependent story it carries one `Dependency:` line per publish blocker; step 5 fills each dependent's text blocker from the `Dependent:` lines, the crate and the version; the `Dependency:` lines name the same publish-blocker edges step 3 reads from `## Blocked by`.
- **Alone**: anything else: the user typing it, or a bare story id passed with no brief from another skill or agent. Step 4 quizzes the user; step 5 runs on their approval.

## Process

### 1. Gather context

Work from whatever is already in the conversation context.

`bd show <id> --json` returns an array; read `.[0]`. Refuse with one line and create nothing when:

- `issue_type` is `epic` and its direct children (`bd list --parent <id> --all --json`) include a non-story bead → `<id> refused: flat epic (tickets directly under the epic bead); the story skills do not handle it — the small-bug path does: /mattpocock-skills:implement <ticket-id> per ticket, then bd close <epic-id>`;
- `issue_type` is anything but `story` → `<id> refused: <id> is <type>, not a story`;
- `status` is `closed` → `<id> refused: story is closed`;
- its notes hold a `pr:` line → `<id> refused: finished story (pr: note present); a later run never touches it; to add work to it use add mode (/dev:spec-to-stories <KEY>-<n>, or the epic bead id when the story has no key)`, unless its notes carry a `recut:` line (`recut: <dep repo> publish <crate> <version>`, written by add mode's `OPEN` path while the PR is still open) naming a `## Blocked by` publish blocker that no bump child covers yet: then the cut goes on as a re-cut that adds that blocker's bump with its edges and drops nothing, and the next run delivers the same PR again.

From the story body read the deliverable paragraph, `## Test seams`, `## Parent` (home name, epic bead id, `<KEY>-<n>`) and `## Blocked by`. Read the story's existing children with `bd list --parent <id> --all --json`: any child at all makes this a **re-cut**.

**Publish role**: the refusals, the story-body read and the children read above all run, so a publish brief against a closed story, or a finished one with no such `recut:` line, ends on its refusal line with no bead created, and `## Blocked by` reaches step 3's pair detection. It stops here: it needs no spec, so a Jira error cannot stop it.

Fetch the spec as the tracker doc's "fetch the spec" says, `<id>` being the story id. Read `<epic-id>` and the home name from `## Parent`. The line reads `Home <name>` or the older `Home repo <name>` (`<name>` is the word after `Home`, or after `Home repo`), compared to `<home name>` ignoring case. Reach the epic bead with plain `bd show <epic-id> --json`, never `bd -C <path>` even when the story is read with one, and only when the names match and `test -d <home>/.beads` (plain `bd` climbs to an ancestor's database without it): the epic bead then lives in `<home>`'s database, the session's. Any other name means its database is not the session's, and no `bd -C` is tried, so the fetch reaches its last resort. No epic id or no home name in `## Parent`, a different home name, or a failing `bd show` counts as no epic bead. The last resort is the story body: say `cutting from the story body alone` and go on.

### 2. Explore the codebase (optional)

Whether or not you explore, read the story's design field first as orientation, when it is set: `.[0].design` of step 1's `bd show <id> --json`, what the story cut learned about this repo. It orients; the story body still bounds the work.

If you have not already explored the owner repo, do so to understand the current state of the code. Ticket titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching (the owner repo's and the workspace's).

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

**Publish role**: skipped whole, the design field included: the caller's breakdown was drafted from an explored repo.

### 3. Draft vertical slices

Break the story into **tracer bullet** tickets, every one landing in the owner repo. Work the story needs from another repo is not a ticket here: name it in step 4 as a gap for the user (alone) or the caller (called).

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests): vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window
- Any prefactoring should be done first

</vertical-slice-rules>

Give each ticket its **blocking edges**: the other tickets of this story that must complete before it can start. A ticket with no blockers can start immediately. Each ticket's verification runs at the story's `## Test seams`.

Give each ticket one tier from the tracker doc's "Complexity labels" table.

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is one mechanical change (rename a column, retype a shared symbol) whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into a tracer bullet; sequence it as **expand–contract**. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own ticket blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in a ticket blocked by every migrate batch. When even the batches can't stay green alone, keep the sequence but let them share an integration branch (the story's) that all block a final integrate-and-verify ticket; green is promised only there.

**Dependency pair, per edge.** Read the pair per edge of the story DAG, not once per story. The story is a **dependent** for each publish blocker it carries: each `## Blocked by` line naming a publish ticket is one edge (a line names a publish ticket when it reads `<dep repo> publish <crate> <version>`, placeholder or not-created form included, or when its id is a bead titled `publish <crate> <version>`: `bd show <id> --json`, with `-C` for the dep repo's path; called, the brief's `Dependency:` lines name the same edges), and the breakdown gets one bump per publish blocker, every other ticket of the story blocked natively on every bump. It is a **dependency** when it has a publish ticket child, when the caller's brief carries a `Dependent:` line (called), or (alone) when a sibling story from the tracker doc's "Stories" gather for `<KEY>-<n>` has a `## Blocked by` line naming a publish ticket in `<owner repo>` (`<owner repo> publish <crate> <version>`, filled or placeholder); each such sibling is a dependent. A line naming a story (`<repo> <story-id>`) is a story-closure edge and adds no publish ticket. Alone with no such sibling, say so and add no publish ticket. A story can be both. Then the breakdown carries that section's extra tickets: the bumps first in a dependent, the publish ticket last in a dependency, edges as it says. One PR publishes one version, so a block with two `publish <crate> <version>` tickets in this one story → `<id> refused: block carries two publish tickets; one PR publishes one version`, stop.

**Re-cut.** `closed` children stay as they are. The breakdown lists every open child as kept or dropped, beside the new tickets; a claimed or `in_progress` child is always kept. Each dropped ticket names the new tickets replacing it, and every kept ticket (the publish ticket included) that the dropped one blocked moves its edge onto those replacements. Apply the tracker doc's per-edge re-cut rules to the publish ticket, the bumps and the text blockers. A dependent that gained a publish blocker since its last cut (a new `## Blocked by` line with no bump yet) gets its own bump for it (a second one when it already had one; a bump covers the blocker whose crate its title names, and for a blocker a `recut:` line names, whose crate and version: a point release bumps a crate the story already bumps), and every open ticket that is not a bump, its publish ticket included, takes a native edge onto the new bump: new tickets with `--deps`, kept ones with `bd dep add <ticket id> <bump id>`; list each as a moved edge.

**Publish role**: of this step only the dependency-pair detection runs, so step 5 knows which side the story is on and takes the pair's order from there; the slices, tiers, edges and the pair's extra tickets are the block's as approved. A dependency story (the brief names a dependent) whose block carries no `publish <crate> <version>` ticket → `<id> refused: publish block for a dependency story carries no publish ticket`, stop; a block carrying two is refused as at step 3.

### 4. Quiz the user (alone) or return the breakdown (called)

The breakdown is a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Tier**: its `complexity:` label
- **Blocked by**: which other tickets of this story (if any) must complete first
- **What it delivers**: the end-to-end behaviour this ticket makes work

In a re-cut, also each kept or dropped existing ticket by id and status, each dropped ticket's replacements, and each moved edge as `<kept id>: blocked-by <dropped id> → <new tickets>`. The list ends with any cross-repo gap from step 3.

**Alone**: present it and ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct: does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown, then go to step 5.

**Called, draft role ("story cutter", or no role named)**: return it as one block headed `<owner repo> <story-id> <story title>` and stop. Nothing is created or edited. When the caller later sends a `Publish this block` brief with its edits from the merged quiz, go to step 5 with that version.

**Publish role**: skipped whole; step 5 publishes the block as Mode defines.

### 5. Publish the tickets to the configured tracker

Publish the approved breakdown as the tracker doc's "publish a story's tickets" says: in dependency order (blockers first) so each edge names a real id, the body from the issue template below. In a dependency pair, follow the order in its step 6 for this story's part: a dependency story's part ends on filling in the text blocker of each dependent that has a story, as that section's step 3 says, the dependent's story id and repo from the brief (called) or the sibling gather (alone); a `skipped: no beads database` dependent has no story and no line to fill. In a re-cut, once the new tickets exist and before closing a dropped ticket, run `bd dep add <kept id> <new id>` for each moved edge, then `bd close <dropped id> --reason "re-cut into <new ids>"`, so no kept ticket reaches the frontier on a closed blocker.

The Jira comment: **alone**, add the tracker doc's one-story comment, covering this story, when step 1 found the Jira epic. **Called** (publish), add none; the caller adds one for every story.

Do NOT close or modify the story or the epic bead, apart from the dependent story's text blocker line the tracker doc tells you to fill in; the epic bead is never written, as the tracker doc's "epic bead writes" convention says.

End on one block: `<owner repo> <story-id> <story title>`, then one line per ticket `<bead-id> <title> complexity:<tier> blocked-by:<ids|none>`, then the Jira comment's issue key or `no Jira comment`.

<issue-template>

## Parent

The story and the feature, in the tracker doc's form (`Story <story-id> in <owner repo>; home <home name>, epic bead <epic-id>, <KEY>-<n>`). The home name, epic id and key carry forward from the story's own `## Parent` line; `<home name>` is the session's only when that line names none.

## What to build

The end-to-end behaviour this ticket makes work, from the user's perspective, not layer-by-layer implementation.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

</issue-template>

Avoid specific file paths or code snippets: they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts, not a working demo, just the important bits.
