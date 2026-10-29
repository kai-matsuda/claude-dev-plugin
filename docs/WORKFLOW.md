# Feature workflow (human runbook)

How a feature moves from idea to merged code using the Matt Pocock engineering skills,
Jira, and beads. The commands below are user-typed; the agent cannot invoke them on its
own. `/dev:implement-story` and `/dev:close-story` are also invoked by
`/dev:implement-spec` and `/dev:close-epic`, so you type them yourself only in the Variants cases.
The agent-side rules these commands rely on live in the dev plugin's `docs/agents/`. Bold
terms (epic, story and task orchestrator, text blocker, human stop, finished story) are
defined in the plugin's `GLOSSARY.md`, and the ADRs this runbook cites for the why are the
plugin's `docs/adr/`. Both live in the plugin repo (`vangogh500/claude-dev-plugin`):
`GLOSSARY.md` at its root, `docs/adr/` beside this file; a feature's own glossary and ADRs
live in its repo.

In a session, `/dev:workflow` prints this file, then one line per open epic bead saying
where it is in the flow and what to type next.

## One line

```
/mattpocock-skills:grill-with-docs → /mattpocock-skills:to-spec → /dev:spec-to-stories → /dev:spec-to-tasks → /dev:implement-spec → /dev:close-epic
                                                                    └ or /dev:implement-story <story-id> in one story's repo

/dev:retro → /dev:triage → /dev:implement-task <bead>                 environment improvements, after any session
```

## Prerequisites (once per repo)

- `.beads/` exists (`bd init --non-interactive --agents-file CLAUDE.md`, then prune the
  Codex/Cursor extras it generates; see `docs/agents/issue-tracker.md`).
- The repo's `CLAUDE.md` has an `## Agent skills` block naming the Jira project key.
- Atlassian MCP connected (Jira access is through MCP, not a CLI).

## Prerequisites (once per workspace)

A **workspace** is one organisation's checkouts as siblings under one root, which is
itself a small git repo (`mice-labs/workspace` → `~/src/mice-labs`). A session typed at
that root, the directory holding `repos.yaml`, is a **workspace session**; typed anywhere
else it is a repo session, and a workspace above it is ignored. A feature with a story in
more than one repo is typed at the workspace root from `/mattpocock-skills:to-spec` on, and so are its
`/dev:spec-to-stories`, `/dev:spec-to-tasks`, `/dev:implement-spec` and `/dev:close-epic`. `/dev:retro` and
`/dev:triage` route across repos from there; typed in a repo they stay in that repo.

- The workspace repo is cloned at `~/src/<org>` and every repo you work in is cloned
  inside it. `repos.yaml` at the root has one entry per repo; a repo missing from it
  surfaces as `target:unknown` at triage, which is the prompt to add it.
- `.beads/` exists at the workspace root (same `bd init` as per repo). It is the
  home of a workspace session: the **inbox** is the home's beads, and the workspace's own
  beads live there too.
- Per machine, by hand (`/dev:setup`'s baseline leaves it out): add `~/src` to the
  sandbox read and write allowlists in your user settings, so a workspace session can
  `bd -C` into any manifest repo's `.beads/` without a prompt.
- Per machine, by hand: `git config --global beads.role maintainer`. `bd` reads this from
  the shell's current directory, so without the global value every `bd -C <other repo>`
  prints a warning.
- Optional: `triage.jira-epic: <KEY>-<n>` in `repos.yaml` names a standing Jira epic that
  `/dev:triage` comments on once per run. Absent, it skips the comment.

Cross-repo notes:

- `bd -C <repo>` into a repo outside `~/src` is denied by the sandbox; the skills rerun
  that one command with the sandbox disabled, which prompts once.
- Every repo with a story that can start this run must be a working directory of the
  session, or `/dev:implement-spec` refuses before starting anything and prints one line per
  missing repo,
  `/add-dir <absolute path>`. Run those, then the same command again. Subagents edit only
  inside working directories, so this check is what stops a run from failing mid-story.
- A story that needs another repo's published crate carries a text blocker naming that
  repo's **human gate task**, the publish task; a story that must follow another
  story's PR carries one naming that story. A story can carry several, one per
  `## Blocked by` line, and the stories together form a **story DAG**. `/dev:implement-spec`
  skips the story until every blocker clears. A run that ends while a `ready-for-human`
  task (the publish task) is still open is the **human stop**, and the report names
  what to publish. The human step, in order:
  1. land the dependency's PR with the version bumped;
  2. publish;
  3. `bd -C <workspace>/<repo> close <publish-id> --reason "published <version>"`;
  4. resume from the workspace root with `/dev:implement-spec <KEY>-<n>`, or
     `/dev:implement-spec <epic-id>` when the epic has no external ref.

  A story held only by a story-closure blocker (a blocker naming a finished story whose
  PR is not yet closed out) is a human stop too. The report prints, for each,
  `human: <owner repo> <story-id> <pr url>: the PR to merge and the /dev:close-story <story-id> to run`
  and `waiting: <repo> <story-id>` for the story behind it. When the stories wait in a
  chain (C waits on B waits on A, none yet closed), the `human:` line names the root of
  the chain (A), the first finished story not yet closed, not the direct blocker. The
  human step: merge its PR, then run `/dev:close-story <story-id>` in its repo, then
  `/dev:implement-spec <KEY>-<n>` again.

  A blocker that names no readable id ends the run as a **stall**, not a human stop; fix
  the blocker text, then run the same command. When a task's `failed twice:` note names
  another repo's crate, the stall report adds that `/dev:spec-to-stories <KEY>-<n>`, in add
  mode, adds the story that crate's repo needs.
- One `bd ready` across every repo needs `bd repo sync` at the workspace root, which
  reads each repo's JSONL export under `.beads/`. That export is on everywhere through
  `BD_EXPORT_AUTO=true` in the shell profile, a per-machine line you add by hand (bd has no
  user-level config file for it, and `/dev:setup` does not set it), and the file is hidden
  by the global git ignore. Each
  repo still needs one `bd repo add ./<name>` at the workspace root the first time it
  gets a `.beads/`. Without the sync, the closed inbox beads are the cross-repo record:
  `bd list -l retro --all` from the workspace root.
- Why the manifest and the inbox live where they do:
  the plugin's `docs/adr/0004-manifest-at-workspace-root.md` and
  `docs/adr/0005-retro-inbox-in-workspace-beads.md`.

## Stages

| # | You type | What happens | Ends with |
|---|---|---|---|
| 1 | `/mattpocock-skills:grill-with-docs` | Relentless interview on the plan; as terms and decisions settle, `GLOSSARY.md` and `docs/adr/NNNN-*.md` are written inline. | A conversation that holds the design; domain docs updated. |
| 2 | `/mattpocock-skills:to-spec` | No interview. Synthesises the conversation into the spec template. Asks you to confirm the **test seams** (highest point the feature can be tested through; fewer is better). | **Jira Epic** in the repo's project with the spec, `ready-for-agent`; an epic bead linked via `--external-ref`. |
| 3a | `/dev:spec-to-stories <KEY>-<n>` | The **story cut**, with its own story quiz. Splits the spec into **stories**, one per PR and usually one per repo it changes, each resolved to its owner through `repos.yaml`; a split into several stories in one repo is yours to ask for, and proposed on its own only for a deprecate-then-remove. A story that follows another carries a `## Blocked by` line naming it (a publish placeholder for a crate the dependency publishes, which the task cut turns into a human gate task), so the stories form a **story DAG**; the quiz shows it. Iterate until stories and owners are right. On a feature whose stories exist it runs in **add mode**: the same steps over the additions only, with one forge query per finished story an addition touches; when every story is closed it prints `<epic-id> refused: every story is closed (<repo> <story-id>, ...); next: /dev:close-epic`. | A story bead per PR (a repo session's stories are children of the epic bead), each carrying the story cut's orientation in its design field; in add mode, the additions only. No Jira comment. |
| 3b | `/dev:spec-to-tasks <KEY>-<n>` | The **task cut**, with its own task quiz. Cuts each story into vertical tracer-bullet tasks, sized to one context window, with blocking edges (wide refactors become expand → migrate → contract). Cuts the stories in one topological pass over the story DAG, in waves; creates each dependency story's **publish task** (`ready-for-human`, the human gate task) and fills in the dependent story's blocker, and re-cuts an already cut dependent inline when a new publish task lands. Iterate until granularity and edges are right. Among its refusals: a dependency cycle (`dependency cycle (<repo> <story-id> -> <repo> <story-id> -> ... -> <repo> <story-id>)`; the story DAG has none). | Each story's tasks as children with native `blocked-by` deps and one `complexity:<tier>` each. One summary comment on the Jira epic. |
| 4a | `/dev:implement-spec` | AFK. The session is the **epic orchestrator**: it starts one **story orchestrator** per startable story, each in its own repo; a story waits while any text blocker is open, a blocker naming a story staying open until `/dev:close-story` closes it. Each story orchestrator runs one **task orchestrator** per task (an opus session whose implementer subagent works in a worktree at the tier's model; each task orchestrator runs the **check gate** (the checks, then, for `medium` and `high`, a review one tier up with `/mattpocock-skills:code-review`) before it lands the task itself) onto one integration branch, runs the same check gate on that branch at the story's review model, and delivers the PR as a draft that stays a draft; the epic orchestrator marks it ready once its spec-axis review is clean, and files any findings as tasks that re-run the story in add mode; those tasks land on the story's integration branch (`feat/<story-id>`, keyed or not; the Jira key stays on the commits, the PR body and the bead). Tasks close and the story bead is left open; Jira epic → in review. When a run ends with a `ready-for-human` task (the publish task) open, or a story waiting only on a sibling's closure, it stops (the **human stop**) and reports what to publish or merge; do the human step (Cross-repo notes above), then `/dev:implement-spec <KEY>-<n>` again. | PRs delivered: one integration branch and a draft-turned-ready PR per story, with `branch:` and `pr:` notes on the story bead; or the stop report naming the publish task, its crate and version, or, for a story-closure stop, the PR to merge and the story to close. |
| 4b | `/dev:implement-task <task-id>` | For a standalone task: a triaged retro item or a small bug, a task with no story. A task under a story is delivered by `/dev:implement-story`, since only that writes the story's `branch:` and `pr:` notes. Set `/model opus` first: the session is the story orchestrator with a frontier of one, and it spawns one task orchestrator that runs the check gate (the checks, then, for `medium` and `high`, a review one tier up with `/mattpocock-skills:code-review`), lands the task, and delivers it. | A PR opened ready on `task/<task-id>`, with `delivered:` and `pr:` notes; bead closed at delivery. |
| 5 | review and merge each story's PR | You, on the forge. Nothing to type; the agent never merges. A story another waits on to close is merged, then closed with `/dev:close-story <story-id>`, before the run resumes; a dependency's publish edge instead takes the human step above (land its PR, publish, close the publish task). | Every story's PR merged. |
| 6 | `/dev:close-epic` | Runs `/dev:close-story` for each story (which checks its tasks are closed and its PR shows `MERGED` on the forge, and closes the story bead), then closes the epic bead; comments the PR links on the Jira epic and transitions it to done. Refuses rather than overrides. Retro items carrying the same key never block it: they are environment work, not slices of the feature, and the skill skips `retro`-labelled beads. | Epic done. |
| 7 | `/dev:retro` (optional) | Reads the session for improvements to the agent's environment, keeps the candidates that trace to a moment in it, and files each as a `needs-triage` bead in the home's inbox naming the repo that likely owns the fix. Applies nothing; can run unattended. | Inbox beads, ids reported. |
| 8 | `/dev:triage` | Shows the open inbox with the five tests (moment, recurrence, layer, blast radius, owner) and asks which to accept. Accepted items get acceptance criteria, a `complexity:<tier>`, and a bead in the repo that owns the change; the inbox bead closes pointing at it. Rejected close as `wontfix`. | Routed beads on each repo's frontier; one Jira comment when the manifest names a standing epic. |

**The argument.** `/dev:spec-to-stories` and `/dev:spec-to-tasks` take the feature as their one
argument: `<KEY>-<n>`, or `<epic-id>` when the epic bead has no external ref. Typed without
it, each stops on a usage line and does nothing: neither recovers the epic from the
conversation or from the open epic beads, so a fresh session types what `/dev:workflow` prints,
each open epic's next command with its argument filled in. `/mattpocock-skills:to-spec` reports the key.
`/dev:implement-spec` takes the argument in the same form (the resume step in Cross-repo notes).

**The story tier.** A feature gets one **story** per PR, usually one per repo it changes. The story
bead owns its branch (`feat/<story-id>`, keyed or not; the Jira key stays on its commits,
PR body and bead) and PR (`branch:` and `pr:` notes on the bead) and holds its
tasks as children; a repo session's stories are the epic bead's children, and every
workspace-session story carries the epic's Jira key. A story is
**finished** when every child is closed or carries `ready-for-human`, `needs-triage` or
`wontfix`, and its `pr:` note exists. Order
between stories is a text blocker on the dependent, one `## Blocked by` line per edge,
each naming a human gate task (another repo's publish task) or a story (open until
its `/dev:close-story`); the stories form a DAG, and there are no per-task edges across
repos.

**Add mode** is how a point release is added mid-feature. When a run stalls on a
`failed twice:` note whose reason names another repo's crate, run `/dev:spec-to-stories
<KEY>-<n>` again: on a feature whose stories exist it adds the missing story (a new
publish and the dependent's second blocker) instead of refusing, as long as some story is
not yet closed (with every story closed, more work is a new feature). A finished story it
touches is checked on the forge: a merged one gets a new story that waits on its closure
rather than more work, an open one is re-cut (a `recut:` note lets the task cut add its
bump), and one closed unmerged is refused until you reopen the PR or close the story. Run `/dev:spec-to-tasks` for the additions, then
`/dev:implement-spec` resumes.

`/dev:close-story <story-id>` is the per-repo close: type it in a story's repo once its PR
has merged, for example after a dependency's story merges and you want that repo's bead
closed before the rest of the feature is. It refuses while any task of the story is
open, the publish task included, so on a dependency's story run it after the publish
task is closed. `/dev:close-epic` calls it for every story, so you need it by hand only for
that early close.

## Complexity tiers

Assigned per task at the task cut (`/dev:spec-to-tasks`, or `/dev:story-to-tasks` for a one-story re-cut); round up when unsure.

| Tier | Implement | Review | Typical |
|---|---|---|---|
| `complexity:low` | haiku | sonnet | one file, mechanical, spec determines the code |
| `complexity:medium` | sonnet | opus | several files, some judgement, new tests |
| `complexity:high` | opus | fable | concurrency, public API of a published crate, persisted formats, open design questions |

`bd list -l complexity:high` shows what will cost the most; `bd ready -l complexity:low`
is cheap work to hand off.

One review tool, three rows: at the task, the story and the epic, `/mattpocock-skills:code-review`
is run by a reviewer: at the task on both axes (repo standards, fidelity to the spec) at the
task's review model, for `medium` and `high`; at the story
on both axes, and at the epic on the spec axis only, each at the review model of the max tier beneath it. Why: the plugin's `docs/adr/0014-one-loop-at-three-rows.md`. Never write bare
`/code-review` in a doc — four skills answer to that name.

## Session model per stage

The tier table above sets *subagent* models; this sets what your own session runs
(`/model`). Subagent models never depend on it, except the task cut's story cutters
(one subagent per story), which inherit it unless a default subagent model is configured
(see the plugin's `docs/adr/0007-ticket-cut-runs-story-cutters-in-waves.md`).

| Stage | `/model` | Why |
|---|---|---|
| 1–3b | fable | Design judgement; every later stage inherits its mistakes. |
| 4a | opus | The epic orchestrator session, the story orchestrators it starts and their task orchestrators all run at opus (the plugin's `docs/adr/0006-one-story-per-repo.md`). Each task orchestrator's implementer and reviewer follow the tier table; the orchestrator runs the check gate itself. |
| 4b | opus | The session is a story orchestrator with a frontier of one; its task orchestrator's implementer and reviewer follow the tier table. |
| 5 | no switch | You review and merge on the forge. |
| 6 | sonnet | Tool-call sequencing with explicit stop points. |
| 7 | no switch | It reads the session it runs in. |
| 8 | opus | Acceptance is yours; the agent writes acceptance criteria and tiers for small environment changes, which needs judgement but not fable. |

## Variants

- **Too fuzzy or too big to grill in one sitting** → `/mattpocock-skills:wayfinder` first. It builds a map of
  *decision* beads and resolves them one at a time until the route is clear; then start
  at stage 1 with the resolved decisions in hand.
- **One story in its own session** → in the story's repo, `/dev:implement-story <story-id>`.
  It is what `/dev:implement-spec` runs per story; typing it yourself reaches the same PR
  with the same `branch:` and `pr:` notes. Set `/model opus` first: that session is the
  story orchestrator. While stage 4 runs, `/dev:workflow` lists each unfinished story's repo
  and id.
- **Small bug, no spec needed** → describe it, and the route is one `bd create`, then `/dev:implement-task <task-id>` (give the task a `complexity:<tier>` and a `ready-for-agent` label): no epic bead, no Jira epic and nothing to close by hand. An accepted `/dev:triage` item takes the same route.
- **A branch you wrote by hand** → `/mattpocock-skills:pr` (`/model opus`) shapes the PR body: smallest
  visual that explains the change, before/after evidence, one-way vs two-way door and
  blast radius.
- **Hard bug** → `/mattpocock-skills:diagnosing-bugs` (model-invokable; saying "diagnose this" also reaches it).
- **Design question you can't settle by talking** → `/mattpocock-skills:prototype` for a throwaway answer;
  `/mattpocock-skills:research` to read primary sources in the background.
- **Review something already written** → `/mattpocock-skills:code-review` (two axes:
  repo standards, and fidelity to the spec/task).
- **Improve the codebase, not a feature** → `/mattpocock-skills:improve-codebase-architecture` scans for
  deepening opportunities and grills through the one you pick.
- **Unsure which of the above** → `/mattpocock-skills:ask-matt`.

## Where things live

| Artifact | Place |
|---|---|
| Spec | Jira epic description (long ones also `docs/specs/<slug>.md` in the home) |
| Decisions extracted from a spec | `docs/adr/NNNN-<slug>.md` |
| Terminology | `GLOSSARY.md` |
| Tasks, deps, progress | beads (`bd show`, `bd ready`, `bd graph`) |
| A repo's slice of the feature | its story bead, in that repo's beads; the `branch:` and `pr:` notes live there, and a repo session's story is a child of the epic bead |
| The feature's epic bead | the home's beads (the workspace root in a workspace session), linked to the Jira epic by `--external-ref <KEY>-<n>` |
| Exploration notes | `<repo>/.spec-notes/<epic-id>/` |
| A worktree agent's temp files | `<worktree>/.tmp/`, where the TMPDIR line points `TMPDIR` (gitignored as `/.tmp/`) |
| Human status and discussion | the Jira epic |
| Agent-side rules | `docs/agents/*.md` in the dev plugin repo (`vangogh500/claude-dev-plugin`; the installed copy serves every repo), repo `CLAUDE.md` (overrides) |
| Which repo owns a file or crate | `repos.yaml` at the workspace root (the repo manifest) |
| Decisions that span repos | `docs/adr/` at the workspace root |
| Retro inbox | the home's beads, label `needs-triage`; closed ones record where each item went |
