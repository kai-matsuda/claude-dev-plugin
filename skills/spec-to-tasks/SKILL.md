---
name: spec-to-tasks
description: "The task cut: after /dev:spec-to-stories, cut every uncut story of a feature into tasks through one story cutter per story, quiz the user once on the merged breakdown, publish through /dev:story-to-tasks and summarise on the Jira epic."
disable-model-invocation: true
---

<!-- Once a fork of mattpocock-skills 1.3.1's engineering breakdown skill, rewritten as the thin
     task cut over story cutters (INFRA-27, ADR 0007). The story cut moved to
     /dev:spec-to-stories and the per-story cut is /dev:story-to-tasks; this file keeps only the
     story gather and its refusals, the working-directory preflight (shared, in orchestration.md), the
     story cutter spawn in topological waves with the inline re-cut of an already cut
     dependent (ADR 0011), the merged task quiz, the inline publish in dependency order and
     the one Jira comment. The argument is required and the no-argument
     epic recovery is retired (chezmoi-nz0). It tracks no plugin copy. -->

# Spec To Tasks

The **task cut** (`${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md`): every **story** of a feature that has no tasks yet is cut into **tasks**, tracer-bullet vertical slices in that story's repo, each declaring the tasks that **block** it. The **story cut** (`/dev:spec-to-stories`) made the stories; this skill runs one **story cutter** per story: you gather, check, spawn, quiz, publish and report, and you never draft a task yourself.

The issue tracker rules are in `${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md`. This skill performs its "When a skill says 'gather the epic bead'", the "Stories" gather of its "When a skill says 'fetch the relevant task'", with its database guard, and the Jira comment of "publish a story's tasks"; `/dev:story-to-tasks` performs the rest of that operation and of "When the breakdown touches a dependency repo". Read those sections before step 1, and the "Working-directory preflight" of `${CLAUDE_PLUGIN_ROOT}/docs/agents/orchestration.md` before step 2.

**Names**: `<home>`, `<workspace>`, `<owner repo>` and `<owner>` are as **the one test** in the tracker doc's opening defines them, with the session mode. For each story, `<owner>` is the checkout of the database the story was found in, and `<owner repo>` is as the one test names it. `<epic-id>` is the epic bead's id and `<KEY>-<n>` its `external_ref`.

## Process

### 1. Gather the stories

The argument is required: a Jira key `<KEY>-<n>` or an epic bead id, the one on the `next: /dev:spec-to-tasks ...` line `/dev:spec-to-stories` ended on or `/dev:workflow` prints. With none, stop on one line, `usage: /dev:spec-to-tasks <KEY>-<n>|<epic-id> (the one /dev:spec-to-stories ended on; /dev:workflow prints it)`, and do nothing else: the argument alone names the feature, so a fresh session types what `/dev:workflow` printed.

**The home database.** Before any `bd` call, check that `<home>` has a database by the tracker doc's "Has a database" rule ("First time in a repo"): without one, plain `bd` climbs to an ancestor's database (another home's inbox) and would gather that database's epic bead. Missing → `refused: no beads database in <home>; run /dev:spec-to-stories first`, spawning nothing.

**The epic bead.** Gather it as the tracker doc's "gather the epic bead" says, `<skill>` being `/dev:spec-to-tasks`, with its refusals; for a key, none found → `<KEY>-<n> refused: no epic bead; run /dev:spec-to-stories first`. Then gather its stories with the "Stories" gather, its fallback and failure rules included (a sweep that stops there cuts nothing, since that repo's story would go unseen). Skip `retro`-labelled beads.

Also refuse with one line, spawning nothing and creating nothing, when:

- the gather finds no story → `<epic-id> refused: no stories; run /dev:spec-to-stories first`;
- every story is `closed` → `<epic-id> refused: every story closed; nothing to cut` (`/dev:spec-to-stories` refuses too: with every story closed the feature is delivered, and more work on it is a new feature);
- every story that is not `closed` already has a child (`bd -C <owner> list --parent <story-id> --all --json` non-empty) → `<epic-id> refused: every story already cut (<repo> <story-id>, ...); re-cut one with /dev:story-to-tasks <story-id>`.

**The set to cut.** It is every story that is not `closed` and has no children: a story closed by hand is never spawned. Print every closed story as `<repo> <story-id> closed`, every dependent to re-cut (below) as `<repo> <story-id> re-cut in this run` (a step-1 progress line: step 6 reports the re-cut story by its block or by its own failure or waiting line), every finished dependent (below) as its `cut failed:` line, and every other story as `<repo> <story-id> already cut`.

**The story DAG.** Read the body of each story that is not `closed` (`bd -C <owner> show <story-id> --json`), and keep its design field (`.[0].design`), the story cut's orientation for that repo. Each `## Blocked by` line is one edge of the story DAG (`${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md`, "Text blocker"), read per edge, as `/dev:story-to-tasks`'s **Dependency pair, per edge** reads it:

- A line naming a publish task is a **publish edge**: it reads `<dep repo> publish <crate> <version>` (the `(not created yet)` or `(not created: no beads database)` form), or `<dep repo> <id>` where that bead is titled `publish <crate> <version>` (`bd -C <dep owner> show <id> --json`). The story is a **dependent** for it. A `(not created: no beads database)` line names a repo the story cut skipped, which has no story: it is an edge with no dependency in the run, ordering no wave and holding the dependent back from nothing, and step 3's **Dependent story** line carries it as written. Otherwise its **dependency** is the story in `<dep repo>` holding that publish task: the task's parent (`.[0].parent`) for the filled form; for the `(not created yet)` form, the story there that has a `publish <crate> <version>` child, else the story there whose design field names that crate and approved version. For the `(not created yet)` form, none or several match → ask the user which story before spawning.
- A line naming a story (`<repo> <story-id>`) is a **story-closure edge**: the story waits on that story's closure, which is for the run (`/dev:implement-spec`), not the cut.

A story may be the dependent of several publish edges and the dependency of several (one publish task, however many dependents name it), and a chain (A depends on B depends on C) is cut like any other DAG.

**Cycles.** Follow every edge, publish and story-closure alike. Edges that close a cycle → `<epic-id> refused: dependency cycle (<repo> <story-id> -> <repo> <story-id> -> ... -> <repo> <story-id>); the story DAG has none`, naming each story on it, and tell the user which `## Blocked by` lines close it; spawn nothing and create nothing.

**Skipped repos.** Read the epic bead's notes (`bd show <epic-id> --json`, `.[0].notes`) for its `skipped: <repo> no beads database` lines: each is a repo the story cut skipped, kept for the dependency briefs and the Jira comment.

**Finished dependents.** A story that is not `closed`, already has children, and carries a `pr:` note (`.[0].notes`) is a finished story (`${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md`): it is never re-cut and never spawned, with one exception: add mode's `OPEN` path (`/dev:spec-to-stories`'s **A finished story an addition touches**) notes the story `recut: <dep repo> publish <crate> <version>` when it gives it a publish blocker, and a finished story carrying a `recut:` line for that edge's crate is a dependent to re-cut for it, below, as if it were not finished (its PR is still open, and the next run delivers it again). When it is the dependent of a publish edge whose publish task this run creates (its dependency joins the run as "Dependents to re-cut" says) and carries no `recut:` line for that edge, report it `<repo> <story-id> cut failed: finished story (pr: note present); add mode decides (/dev:spec-to-stories <KEY>-<n>)` (the epic bead id when the epic has no key). Its `## Blocked by` line is still filled by its dependency's publish (step 5), and its own dependents are cut with its breakdown built from beads.

**Dependents to re-cut.** A story that is not `closed`, already has children, is not finished (or is finished and its notes carry a `recut:` line for that edge's crate), is the dependent of a publish edge whose dependency is among the run's stories and has no `publish <crate> <version>` child yet (in the set to cut, or a dependent to re-cut without its publish task), and has no bump child titled with that crate (in the child listing the every-story-cut check read; a bump covers the blocker whose crate its title names, and for an edge a `recut:` line names, whose crate and version, since a point release bumps a crate the story already bumps) is a dependent to re-cut: this run's cut of the dependency creates the publish task, and the dependent has no bump for that blocker yet. A dependent re-cut in this run that is also a dependency creates its own missing publish task (its brief carries `Dependent:` lines), so the rule is applied until no story joins. One that already has that bump is `already cut`. This skill re-cuts that dependent itself, in this same run: it joins the run beside the set to cut, gets its cutter in the wave after its dependency, and goes through the one merged quiz and step 5 like any cut story. Its `/dev:story-to-tasks` re-cut adds its bump for the new blocker (a second bump when it already had one) and re-edges its open tasks onto it, as the tracker doc's per-edge re-cut rules say.

**The run's stories.** They are the set to cut and the dependents to re-cut.

**A dependency cut without its publish task**, per publish edge: when the edge's dependency already has children, has no `publish <crate> <version>` child (its publish died, or it was closed by hand without one) and is not re-cut in this run, nothing in this run creates that task, and the dependent's line for that edge still reads `(not created yet)`. A dependent of the run (in the set to cut or to re-cut) with such an edge is neither spawned nor published, whatever its other edges: report it `<repo> <story-id> waiting on <dep repo> publish`, with step 5's rerun hint.

### 2. Preflight

Run the "Working-directory preflight" of `${CLAUDE_PLUGIN_ROOT}/docs/agents/orchestration.md` on the owner repo of every one of the run's stories; on a refusal, spawn nothing. An already cut story that is not re-cut needs no working directory. The preflight covers every story it will cut, so a cutter never starts in a repo it cannot read.

### 3. Spawn the story cutters in topological waves

One story cutter per story of the run, a single-story feature included, in **topological waves** (`${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md`, "Dependency wave"): one wave per level of the story DAG, over the publish edges between the run's stories. A story's level is 0 when none of its publish edges has a dependency among the run's stories, else one more than the highest level among those dependencies; each wave holds every story of one level, lowest first, so a four-story chain is cut in four waves, and each dependent's cutter is given the breakdown of every story it waits on. Only publish edges order the waves: a story-closure edge orders no wave, so a story waiting on a sibling's closure cuts in the wave its publish edges give it, and its brief carries no line for that edge. A dependency outside the run (already cut and not re-cut, or finished) orders no wave either: its breakdown is built from beads.

Each wave is one message of Agent calls with no `model:` override, so every cutter inherits the session's model unless a default subagent model is configured (which then wins). Then end your turn: an Agent call returns at once, and each cutter's block arrives as the Agent tool's completion notification and resumes you, as the "Waiting" rule of `harness.md` says (never a poll); the next wave needs every block of the one before, so it, and after the last wave the quiz, runs once the last block of the wave is in. A wave with no story is not sent.

Each brief is two pointers and an instruction, in the shape of `/dev:implement-spec`'s **Spawn** brief:

> You are a story cutter for epic bead `<epic-id>`: story `<story-id>` in the repo at `<owner>`. The story bead's design field is the story cut's orientation for that repo; `/dev:story-to-tasks` reads it first. <dependency or dependent lines> Call the Skill tool with `dev:story-to-tasks` and report the block it ends on.

`<owner>` is an absolute path. The lines between come from the story's publish edges, in the per-story cut's shape (`/dev:story-to-tasks`'s **Mode**); a story that is both a dependent and a dependency carries both kinds:

- **Dependency story**: one line per dependent that is not `closed`, those already cut included (step 5 fills in their blocker line too), `Dependent: story <dependent story-id> in <dependent repo>, crate <crate>, version <version>.`, crate and version from that dependent's `## Blocked by` line. A dependent the story cut skipped (a `skipped: <repo> no beads database` note) has no story and no `## Blocked by` line, so read its crate and version yourself: the dependency is the story whose design field (read at step 1) names the skipped repo as its pair, and that field holds the crate, its current version and the approved one. The line is `Dependent: <repo>, skipped: no beads database, crate <crate>, version <version>.` with the approved version: the publish task is still created, and there is no blocker line to fill in. No design field, or none naming the repo or the crate → ask the user for them before spawning.
- **Dependent story**: one `Dependency:` line per publish blocker, each `Dependency: story <dep story-id> in <dep repo>, crate <crate>, version <version>. Its breakdown:` and that dependency's block, so the cutter has every upstream breakdown. The block is the one its cutter returned in an earlier wave, or, when the dependency was already cut, built from beads: `bd -C <dep owner> children <dep story-id> --json` as `/dev:story-to-tasks`'s end block (`<dep repo> <dep story-id> <title>`, then `<bead-id> <title> complexity:<tier> blocked-by:<ids|none>` per task), each task also carrying the `## What to build` paragraph of its description (`bd -C <dep owner> show <bead-id> --json`, `.[0].description`), since the title and edges alone do not say what the dependent must match. A skipped dependency has no block: the line is its `## Blocked by` line as written.
- **Dependent to re-cut**: its `Dependency:` lines as above, then `This is a re-cut: the story has tasks, and each publish blocker new since its last cut needs its bump: on <dep repo> crate <crate>, ...`, one `on <dep repo> crate <crate>` per new blocker.

The spec is never in the brief: each cutter fetches it as `/dev:story-to-tasks`'s "Gather context" section says (Jira, the epic bead's `Spec:` file, the story body). A cutter creates nothing and edits nothing.

A cutter that returns no block headed `<owner repo> <story-id> <story title>` (a refusal, an error, nothing) is reported `<repo> <story-id> cut failed: <reason>`, its own last line or the error as the reason, and the run goes on with the blocks it has. A dependent is held back only when it has a publish edge to a dependency of the run whose cutter failed or that was itself held back, and that dependency has no `publish <crate> <version>` child yet: it is not spawned, down the DAG; report it `<repo> <story-id> waiting on <dep repo> cut`. Nor is a dependent spawned whose dependency story is `closed` with no children (closed by hand, its `## Blocked by` still reading `(not created yet)`): report it `<repo> <story-id> waiting on <dep repo>: dependency story closed uncut`, and step 5 does not publish it either. Tell the user the way forward: reopen the dependency story (`bd -C <repo> reopen <id>`) and rerun, or edit the dependent's `## Blocked by` by hand. A failed re-cut of a dependency that already has its publish task holds nothing: its dependents are spawned, with its breakdown built from beads. No block at all → end (step 6) with nothing published.

### 4. Quiz the user on the tasks

Present every returned block in one merged quiz, in the story DAG's topological order (each story after every story it waits on, by any edge; the rest in gather order), each task with its title, tier, blockers inside its story, and what it delivers. A re-cut block also shows its kept and dropped tasks, its new bump and its moved edges, as `/dev:story-to-tasks`'s **Re-cut** returns them. Put each block's cross-repo gaps beside the story they belong to. Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct: does each task only depend on tasks of its story that genuinely gate it, and is each check asserting files other tasks of its story create blocked, directly or transitively, on all of them?
- Does the dependent's work match the API the dependency's tasks define?
- Should any tasks be merged, split, or moved to another story?

Apply every edit to the blocks yourself; no cutter is asked to redo anything. Iterate until the user approves the whole breakdown.

### 5. Publish

Inline in this session, one story at a time in step 4's order, call the Skill tool with `dev:story-to-tasks`, args carrying the publish brief:

> Publish this block, as approved at the `/dev:spec-to-tasks` task quiz: story `<story-id>` in the repo at `<owner>`. <`Dependency:` lines as in step 3 without their breakdowns, for a dependent> <`Dependent:` lines as in step 3, for a dependency> <the block, as approved>

Each publishes its own tasks as its step 5 says; a dependency's publish also fills in the blocker line of every dependent story, a dependent re-cut in this run, already cut or finished included, and a re-cut's publish adds its bump and moves its edges. When a `bd -C` fails with `Operation not permitted`, the tracker doc's "bd writes outside the session's repo" says what to do.

**Before each dependent's publish**, a re-cut story included, `bd -C <owner> show <dependent story-id> --json` must show `## Blocked by` naming `<dep repo> <publish bead-id>` for each of its publish edges, checked per edge. A line still `(not created yet)` and its dependency has a `publish <crate> <version>` child → rewrite that line as the tracker doc's "When the breakdown touches a dependency repo" step 3 says. Still `(not created yet)` with no such child → do not publish the dependent; report it `waiting on <dep repo> publish`. A `(not created: no beads database)` line stays as it is.

**A failed publish.** A publish that ends on no block, or a `bd` error, is reported `<repo> <story-id> publish failed: <reason>`, its own last line or the error as the reason, and the run goes on with the stories that do not depend on it. When the failed story is a dependency, none of its dependents in the run is published, and so on down the DAG: report each `<repo> <story-id> waiting on <dep repo> publish`, its `## Blocked by` still reading `(not created yet)`, so no dependent holds a publish id that does not exist.

**The rerun hint.** Tell the user what a rerun does: a story the failed publish left with tasks counts as already cut, so they finish it with `/dev:story-to-tasks <story-id>` (a re-cut, which creates the publish task when the dependency story has none and fills in each dependent's blocker line). A dependent still uncut is then cut by rerunning this skill. A dependent that already has tasks is not covered by a rerun, which re-cuts a dependent only in the run that creates its dependency's publish task: the user re-cuts it with `/dev:story-to-tasks <dependent story-id>`, whose re-cut adds the bump.

Do NOT close or modify the epic bead: step 1 only reads its skip notes, as the tracker doc's "epic bead writes" convention says.

### 6. Comment on the Jira epic, and end

When anything was published and the epic bead has a `<KEY>-<n>`, fetch the Jira epic with `getJiraIssue` (cloud ID from the tracker doc), for the comment only, then add the tracker doc's one comment: covering every story of the feature that has tasks, not only this run's, so a run that died before its comment loses nothing: grouped by story in dependency order (step 4's, with a story cut in an earlier run placed by the same rule), each heading `<repo> <story bead-id> <story title>` with that story's tasks (a story cut in an earlier run is read from beads, `bd -C <owner> children <story-id> --json`, with its edges), the publish task with its version and the bump where they fall, the epic bead id, and one `<repo> skipped: no beads database` line per skip note step 1 read. No comment, and the reason, when nothing was published, there is no key, or Jira answers that no such issue exists (`<KEY>-<n> is not in Jira`, a 404 can also be a permission denial); any other Jira failure is reported as the reason, the tasks already being published.

End on, in step 4's order, one block per published story as `/dev:story-to-tasks` ends (`<owner repo> <story-id> <story title>`, then its tasks with tier and blockers), then one line each:

```
<repo> <story-id> already cut
<repo> <story-id> closed
<repo> <story-id> cut failed: <reason>
<repo> <story-id> waiting on <dep repo> cut
<repo> <story-id> waiting on <dep repo>: dependency story closed uncut
<repo> <story-id> publish failed: <reason>
<repo> <story-id> waiting on <dep repo> publish
<repo> skipped: no beads database
<KEY>-<n> commented                     (or  no Jira comment: <reason>)
```
