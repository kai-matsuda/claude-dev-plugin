---
name: spec-to-stories
description: "The story cut: resolve a spec to one story per PR, usually one per repo it changes, quiz the user on the split, publish the stories to beads, each carrying its repo's orientation in its design field."
disable-model-invocation: true
---

<!-- The story cut as its own typed stage (INFRA-27, ADR 0007), taken out of the old
     /dev:spec-to-tasks, which keeps the task cut as a thin skill over story cutters. This
     file keeps the epic bead and spec gather with its refusals, the manifest resolution,
     the working-directory preflight (shared, in orchestration.md), the inline exploration, the story
     quiz, the publish and the orientation written to each story's design field (chezmoi-cdf,
     ADR 0010: the story cut writes beads only). The argument is required and the no-argument
     epic recovery is retired (chezmoi-nz0). It is not a fork of a plugin skill and
     tracks no plugin copy. Every bd and Jira rule lives in
     ${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md; this file names the operations it performs. -->

# Spec To Stories

The **story cut** (`${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md`): break a spec into **stories**, one per PR, usually one per repo it changes, each the part of the feature that lands in one PR, and the **story DAG** of their edges. It ends at the story quiz and the published stories; the **task cut** (`/dev:spec-to-tasks`) cuts each story into tasks afterwards. On a feature whose stories exist it runs in add mode and adds to the story DAG.

The issue tracker rules are in `${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md`. This skill performs its "Before the story quiz", "When a skill says 'publish the stories'" and "When the breakdown touches a dependency repo" operations (the story cut's part: detection, the proposed version, the stories' order), the "Stories" gather of "When a skill says 'fetch the relevant task'", with its database guard, "When a skill says 'gather the epic bead'" and "When a skill says 'fetch the spec'". Read all six before step 1, and the "Working-directory preflight" of `${CLAUDE_PLUGIN_ROOT}/docs/agents/orchestration.md` before step 3. Every `bd` command shape, label, body shape and order below is the doc's.

**Names**: `<home>`, `<workspace>`, `<owner repo>` and `<owner>` are as **the one test** in the tracker doc's opening defines them, with the session mode. `<KEY>-<n>` is the epic bead's `external_ref`. `<epic-id>` is the epic bead's id.

**Beads only.** This skill writes no file and runs no git write in any owner repo, `<home>` included: its only writes there are beads, the stories (with their design field, step 8) and the epic bead's skipped-story record. Reading an owner repo's code (step 4) is allowed, which is what the preflight is for. Files, `.gitignore` entries and commits in an owner repo are the story orchestrator's alone, as the Orchestrator role of `${CLAUDE_PLUGIN_ROOT}/docs/agents/orchestration.md` says (ADR 0010, `${CLAUDE_PLUGIN_ROOT}/docs/adr/0010-epic-level-stages-write-owner-repos-through-beads-only.md`).

## Process

### 1. Gather context

The argument is required: a Jira key `<KEY>-<n>` or an epic bead id, the one `/mattpocock-skills:to-spec` reported or `/dev:workflow` prints. With none, stop on one line, `usage: /dev:spec-to-stories <KEY>-<n>|<epic-id> (the key /mattpocock-skills:to-spec reports; /dev:workflow prints it)`, and do nothing else: the argument alone names the feature, so a fresh session types what `/dev:workflow` printed. The spec may already be in the conversation; the argument still names the feature.

**The home database.** Before any `bd` call, check that `<home>` has a database by the tracker doc's "Has a database" rule ("First time in a repo"). Without one, plain `bd` climbs to an ancestor's database (another home's inbox), so the key sweep below would search that inbox and step 7 would file the epic bead and the home story there. A `.beads/` that `where` does not name → `refused: bd -C <home> where names <path>, not <home>/.beads`, create nothing. No `.beads/` → offer the tracker doc's "First time in a repo" and act only on the user's explicit yes: `bd init` runs only from `<home>`'s top level (the tracker doc's "First time in a repo" says why), so give the user the exact command to run in `<home>`, and continue once `bd -C <home> where` prints `<home>/.beads` on its first line. When the user reports an abort → `refused: bd init in <home> aborted: <error>`; when `where` names another database → `refused: bd -C <home> where names <path>, not <home>/.beads`; either way, create nothing. On a no → `refused: no beads database in <home>`, create nothing.

**The epic bead.** Gather it as the tracker doc's "gather the epic bead" says, `<skill>` being `/dev:spec-to-stories`, with its refusals; for a key, none found means there is none yet (a run without a prior `/mattpocock-skills:to-spec`: step 7 creates it, carrying the key).

**Stories that exist.** Run the tracker doc's "Stories" gather on the epic bead. None → a first run, steps 2 to 8 as written. Some, and every one `closed` → `<epic-id> refused: every story is closed (<repo> <story-id>, ...); next: /dev:close-epic`, one `<repo> <story-id>` per story found: the feature is delivered, and more work on it is a new feature. Any story not closed → **add mode** (the section after step 8): the same steps over the additions only, never the stories-exist refusal.

**The spec.** `<KEY>-<n>` is the argument's key when it is one, else the epic bead's `external_ref`. Fetch it as the tracker doc's "fetch the spec" says, reading the epic bead with `bd show <epic-id> --json`. The last resort is the epic bead's description when it is prose rather than a Jira URL; with none → `refused: no spec for <KEY>-<n>` (`refused: no spec for <epic-id>` when a bead id argument has no key), stop. No epic bead yet → the tracker doc's "without a prior `/mattpocock-skills:to-spec`" paragraph, at step 7; the key sweep has already shown there is none.

### 2. Resolve the spec to its repos

Resolve the spec to the repos it changes as "Before the story quiz" says, by the session mode.

In a workspace session, resolve through the manifest, from `repos.yaml` and its resolution order alone: one story per manifest repo, each with its owner repo and `<owner>` path. The workspace root owns no story (the tracker doc's "Before the story quiz"): name a change to its own files in the story quiz as done by hand at the root. Read no owner repo's files yet; step 3 comes first.

In a repo session, say `repo session in <home>: one story, in the home repo` and draft that single story. When the spec visibly changes another repo, refuse instead and create nothing: `refused: the spec changes <what> outside <home>; start this at the workspace root`, `<what>` naming what the spec changes there.

### 3. Preflight

Run the "Working-directory preflight" of `${CLAUDE_PLUGIN_ROOT}/docs/agents/orchestration.md` on every owner repo other than `<home>`, so none in a repo session; on a refusal, create nothing. A `/add-dir` typed here carries the task cut and `/dev:implement-spec` in the same session.

### 4. Explore every owner repo

Explore each owner repo inline, in this session, so the split is decided by one context that has seen all of them: the code the spec touches, its public boundaries, and for a pair of repos where one imports the other, the dependent's `Cargo.toml` (or `go.mod`) and the crate's current version. Story text uses each repo's domain glossary vocabulary and respects its ADRs and, in a workspace session, the workspace's (`<home>/docs/adr/`). Keep what you learn per repo; step 8 writes it down.

### 5. Draft the stories

A story is one PR, so the draft is one story per PR, usually one per repo ("Before the story quiz"). Propose a second story in a repo by yourself only when the spec describes a deprecate-then-remove: the story that removes is split from the one that deprecates. Its shape, so it closes no cycle: each migrating story's publish edge names the deprecating half and its version; the removing half waits on each migrating story's closure and publishes its own version; on each migrating repo the split proposes a second story that bumps to the removal's version, with a publish edge on the removing half; and any other importer's edge names the half it needs (a migration needs the deprecation, a bump past the removal needs the removal). Four stories for one dependency and one consumer: deprecate, migrate, remove, bump. With no migrating story (every importer is outside the manifest), the removing half waits on the deprecating half's closure instead, so the two never run at once in one repo; with no import edge between stories, neither half then holds a publish task (the dependency section), so the quiz shows no version for them. Otherwise the quiz shows both publish versions. Propose no other split; the user may split a repo's story for any reason at the quiz (step 6).

For each story draft: its owner repo, a title naming what that PR delivers, one paragraph of what that PR must deliver, its `## Test seams` (the public boundaries in that repo its tasks will test at), and its edges.

The stories and their edges form the **story DAG**. Detect its edges one at a time, as "When the breakdown touches a dependency repo" says (its detection rule and step 1): for each edge between stories in two repos where one imports the other's crate, the importer is the **dependent**, the crate's owner the **dependency**, and you propose the publish version from the crate's current one. The edge is the dependent's blocker on the dependency's publish task, which the task cut creates; a story may be the dependent of several edges and the dependency of others (a chain), but holds at most one publish task, since one PR publishes one version. Any other edge is a blocker on another story's closure: the deprecate-then-remove's removing story on each migrating story (on the deprecating story when no migrating story exists), or an edge the user names at the quiz. Write each story's direct needs only, never an edge implied by a path.

The story DAG has no cycle, whatever kind of edge closes it ("Before the story quiz"). When this step's draft closes one, stop before any bead exists that this run would create, step 7's epic bead included, and name the stories on it: `refused: the stories form a cycle (<repo> <story title> -> <repo> <story title> -> ...)`, the first story repeated at the end, and create nothing. A story has no id yet, so its title names it. (A cycle the user's change closes at the quiz does not end the skill; step 6 rejects that change.) The cases the dependency section puts out of scope (a dependency pinned by git tag or ssh URL; a repo that would publish several crates in one story) stop the skill: tell the user which one and why.

In a workspace session, when the epic bead exists and has no `external_ref`, say now that publishing will refuse (tracker doc, "publish the stories" step 1), so the user can fix the key or the split at the quiz. With no epic bead yet (a key argument that found none), say now that step 7 creates the epic bead carrying that key as its `--external-ref`, with no Jira epic created (tracker doc, "without a prior `/mattpocock-skills:to-spec`").

### 6. Quiz the user on the stories

Present the stories as a numbered list in the story DAG's topological order, each after every story it waits on, so the user sees the DAG. For each story, show:

- **Repo**: its owner repo
- **Delivers**: the one paragraph
- **Test seams**: where its tasks test
- **Blocked by**: one line per edge, `<dep repo> publish <crate> <version>` for a publish edge, `<repo> #<n> <story title>` (closure) for a story-closure edge, `#<n>` its number in this list; or none
- **Publish task** (dependency story): `publish <crate> <version>`, from `<current version>`, `ready-for-human`, created by the task cut; at most one per story
- **Bump tasks** (dependent story): `Bump <crate> to <version>`, one per publish edge, before its other tasks, created by the task cut

When the cut publishes more than once (a chain, or a deprecate-then-remove with a migrating story, whose repo publishes before and after), list every publish version together under the stories, in topological order, each with the story that publishes it.

Ask the user:

- Is the split right: does every repo the spec changes have a story, and does any repo need a second story? The user may split a repo's story for any reason: two deliveries stacked on each other's closure, two independent slices, a step that is not a publish, such as a deploy. For a split, ask which stories the new one waits on and which wait on it; a split at a deploy makes the later story wait on the earlier one's closure, and the earlier story's paragraph (its contract) names the deploy as its last step, a `ready-for-human` task its task cut creates, so `/dev:close-story`'s every-child-closed rule holds the story open until the deploy is done ("Before the story quiz").
- Are the edges right: does each story wait on exactly what it directly needs?
- Does each paragraph say what that PR must deliver, and nothing another story delivers?
- Is each proposed version right?

Apply each change and check the story DAG for a cycle again. When a change closes one, print step 5's line, `refused: the stories form a cycle (<repo> <story title> -> ...)`, as a quiz message, reject that change and keep iterating with the stories as they were before it. Iterate until the user approves the stories.

### 7. Publish the stories

No epic bead yet → create it first, in `<home>`, as the tracker doc's "without a prior `/mattpocock-skills:to-spec`" paragraph says, carrying the argument's key as `--external-ref <KEY>-<n>`; no Jira epic is created, since that key already names one. Then run "When a skill says 'publish the stories'" on the approved stories, its steps in order: the key check, the database check per owner repo (with its offer and its skipped-story rules), then the stories in the story DAG's topological order, each after every story it waits on so its id exists, with the body shape (the paragraph, `## Test seams`, `## Parent`, `## Blocked by`). A story carries one `## Blocked by` line per edge, as many as it has: a story-closure edge as `<repo> <story-id>`, the id of the story already created; a publish edge as `<dep repo> publish <crate> <version> (not created yet)`, which the task cut fills in (or step 2's `(not created: no beads database)` form for a skipped dependency). A story waiting on the closure of a story skipped for no beads database is not created either, nor any story with an edge on it in turn, closure or publish: report each as `<repo> skipped: waits on <skipped repo>'s story`, and write no line for any of them. No line names a gate task id: the story cut creates no tasks. When a `bd -C` fails with `Operation not permitted`, the tracker doc's "bd writes outside the session's repo" says what to do. Keep each story's id, owner repo and `<owner>` path.

Record each story skipped for no beads database on the epic bead, as that doc's step 2 says; a story skipped for waiting on one is reported only (the end report's line) and gets no note: nothing downstream reads it, since no story, line or publish task exists for it. Write nothing else on it: the tracker doc's "epic bead writes" convention.

No Jira comment: the task cut adds the one comment, grouped by story, so the Jira epic never carries a stories-only comment it would repeat.

### 8. Write the orientation on each story

For each published story (a skipped one has none), write what step 4 found in its repo to the story bead's **design field**: `bd [-C <owner>] update <story-id> --design-file -` with the text on stdin, `-C` as "publish the stories" takes it (when the owner is not `<home>`). The first line is the header, verbatim: `Orientation from the story cut; the story body is the only contract.` Then, covering that repo only: the story id and title, the files and modules the spec touches, the public boundaries behind its test seams, the glossary terms and ADRs that bear on it, and every edge of the story, both directions: for a publish edge the other repo's name (a skipped repo's included, so the task cut can match on it), the crate, its current version and the approved one; for a story-closure edge the other story's repo, id and title, and which side waits. The field is orientation for the task cut and `/dev:implement-story`, which read it from the `bd show --json` they already run (`.[0].design`), never a contract: the story body stays the only one, and the field holds no copy of the spec. It travels with the bead over the Dolt remote, so every checkout that pulls the beads sees it. The bead's notes are left alone: they are `/dev:implement-story`'s line log (`branch:`, `review:`, `pr:`), and add mode's `recut:` line is the one note the story cut writes there.

End on the story list in topological order, one block per story with one line per edge and per publish, so the report shows the DAG and every publish version, then the skipped stories and the next command:

```
<owner repo> <story-id> <story title>
  blocked by: <dep repo> publish <crate> <version> (not created yet)     (one per publish edge)
  blocked by: <repo> <story-id>                                           (one per story-closure edge)
  publishes: <crate> <version> (from <current version>)                   (only on a dependency)
<repo> skipped: no beads database                                       (one per skipped story)
<repo> skipped: waits on <skipped repo>'s story                         (one per story skipped for an edge on a skipped story)
next: /dev:spec-to-tasks <KEY>-<n>                                         (or /dev:spec-to-tasks <epic-id> with no key)
```

## Add mode

On a feature whose stories exist (step 1), the story cut adds to the story DAG (ADR 0011, `${CLAUDE_PLUGIN_ROOT}/docs/adr/0011-a-story-is-one-pr-and-stories-form-a-dag.md`). It never re-splits, retitles or deletes a story and never touches a closed one; what the task cut does with a story stays the task cut's. A new story in a closed story's repo needs no forge query and no line on it: the closure already happened.

**The stories and their state.** For each story the gather found, read the story from the Stories gather's `--json` output and its children with `bd [-C <owner>] children <story-id> --json`, and list the stories in topological order as `<repo> <story-id> <story title>: <state>`, the state being the first of closed, finished, open with failed tasks, waiting, open that holds. Finished is the glossary's **finished story**, shown with its last `pr:` value; open with failed tasks is a story with an open child whose notes carry a `failed twice:` line, shown with each such `<task-id>: <reason>`; waiting is a story whose `## Blocked by` names a blocker still open, each line read as the rules doc's Frontier says (a line with no id, or a blocker that cannot be read, counts as open), shown with that line; any state's story carrying a `pr:` note is shown with its last value too.

**The additions.** They come from the conversation and the `failed twice:` notes: a reason naming another repo's crate (an API the dependent's migration needs, a version it must bump to) is the case `/dev:implement-spec`'s Stall report points here for. Steps 2 to 4 run on the repos the additions touch only, and step 5 drafts the additions only, by its rules: new stories with their owner repo, title, paragraph, test seams and edges, to each other and to existing stories; each new publish edge's version proposed from the crate's current one; and on an existing dependent that is not finished, a second `## Blocked by` line directly, whose bump the task cut adds; a finished one goes through the forge query below. An addition proposed for a note names the `failed twice:` reason it answers, as `answers <task-id>: <reason>`. Step 5's cycle check runs over the whole story DAG, existing stories included.

**A finished story an addition touches.** An addition touches a finished story when it gives that story a new blocker line or is new work in that story's repo. New work in a merged story's repo is a new story there, never a task under the old one (ADR 0011); for a new story in a finished story's repo the forge answer decides only its edge: `MERGED` gives it the closure line, `OPEN` lets the user drop it at the quiz, the default keeping it so the two never run at once in one repo. Ask the forge once per such story, however many additions touch it, on its last `pr:` value, detecting the forge from the owner repo's `origin` remote: `gh pr view <url> --json state` on `github.com`, `tea api --repo <owner> repos/{owner}/{repo}/pulls/<n>` on a Forgejo/Gitea host (`"merged": true` is merged; its `state` reads `closed` for merged and unmerged alike). Run that one forge command with the sandbox disabled, as `/dev:close-story`'s "The forge shows MERGED" section does: forge CLIs keep their tokens outside the sandbox. Then:

- `MERGED`: the story takes no more work. The addition becomes a new story in that repo, carrying a `<repo> <story-id>` line on the merged story's closure: a merged dependent gets a new story blocked on its closure and on the new publish (the publish edge's line too); a merged dependency gets a new story that publishes (its publish task is the task cut's), and each open dependent gains that publish edge's line. The end report reminds the user to run `/dev:close-story <story-id>` on the merged story, so that closure line clears.
- `OPEN` defaults to a re-cut: the story keeps its PR and takes the new blocker line and, for a publish edge, the note `recut: <dep repo> publish <crate> <version>` (step 7), which lets the task cut re-cut it past its `pr:` note and add its bump (`/dev:spec-to-tasks` "Finished dependents", `/dev:story-to-tasks`'s "Gather context" section); the next run delivers the same PR again (**finished story**, `${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md`). A story-closure line needs no note: it adds no task. If the user prefers at the quiz, a new story blocked on its closure takes the addition instead.
- A PR closed unmerged is refused, as `/dev:implement-story`'s merge guard refuses it: neither sealed nor deliverable again until someone acts. The additions that touch that story are dropped from the quiz with every line another story gains from them, reported `<repo> <story-id> refused: PR <url> is closed unmerged; reopen it and rerun /dev:spec-to-stories <KEY>-<n>, or close the story (bd [-C <owner>] close <story-id>) and rerun to add the work as a new story` (the epic bead id for `<KEY>-<n>` when the epic has no key).
- No forge (the origin host is neither GitHub nor Forgejo/Gitea, or there is no origin) or a branch-form `pr:` value asks the user whether that delivery merged: a yes is `MERGED`'s path, a no `OPEN`'s; any other answer drops the additions that touch that story from the quiz, with every line another story gains from them, reported `<repo> <story-id> skipped: merge state unknown`. A failing forge command is reported as `<story-id> forge check failed: <error>`, never taken as no forge, and the user is asked the same.

**The quiz (step 6)** shows the existing stories with their state above the additions, never re-asks the existing split, and quizzes the additions only: each new story, each line a dependent gains, each touched finished story's forge answer with the path it takes. Iterate as step 6 says until the user approves the additions.

**Publish (step 7)** publishes the additions only: the new stories in topological order with step 7's body shape and line forms, a line naming an existing story by its id; and each existing dependent that gains a line (not finished, or finished on `OPEN`'s path) has its body rewritten with its new lines appended under `## Blocked by`, the section added last when the body has none, `bd [-C <owner>] update <story-id> --body-file -` with the whole body on stdin (`.[0].description` with the lines added); a finished one on `OPEN`'s path that gains a publish line also gets its note, `bd [-C <owner>] note <story-id> "recut: <dep repo> publish <crate> <version>"`, one per such line. These are beads only. The epic bead gets nothing beyond step 7's skipped-story notes ("epic bead writes"), and Jira nothing: no comment, and the Jira description is untouched, since it changes only when the feature's promise does, by hand. Step 8 writes the orientation of each new story and rewrites a dependent's design field the same way, `bd [-C <owner>] update <story-id> --design-file -` with `.[0].design` plus the new edge on stdin, the header line kept. End on the additions and the rewritten dependents in step 8's report form, then one `<repo> <story-id> merged: run /dev:close-story <story-id>` line per touched `MERGED` story, then the next command.
