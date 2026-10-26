# Orchestration rules

How an agent that runs tickets behaves. Read by every orchestrating skill: `/dev:implement-spec`
(the driver), `/dev:implement-story` and the **story orchestrator** it stands for. A skill owns its
own steps; the rules here are the ones it shares. Terms are those of `GLOSSARY.md` in the plugin repo.
The cut skills, `/dev:spec-to-stories` and `/dev:spec-to-tickets`, read only the Orchestrator role's
epic-level sentence and its "Working-directory preflight", and the ticket cut also reads the
Waiting rule in `harness.md` for its cutter waves.

The harness mechanics (waiting, the Idle rule, commits, cut-off agents, scratch space, shell
commands) are in `harness.md`, which also carries the Waiting rule the ticket cut reads; the
working-directory preflight is the one mechanic that stays here.

## Orchestrator role

The session running a skill is an **orchestrator**: the driver for `/dev:implement-spec`, the
story orchestrator for one story. It never implements. Every change to source, tests, docs, or
build files is made by a subagent spawned at the tier's model; no change is small enough to
be an exception. A one-line fix is a `complexity:low` ticket's worth of work and gets a
`haiku` implementer, not an inline edit.

The orchestrator does: read the spec, story and tickets; spawn exploration, implementer,
merger and reviewer subagents (or, in the story flow, **ticket runners**, which own those three per ticket) with
the right `model:`; pass context pointers; track the frontier; run `bd` operations (claim,
split, note, close); create and report the integration branch; and do repo plumbing that no
ticket owns, namely the branch itself and the `.gitignore` entries from Scratch space.

An **epic-level stage** (the story cut, the ticket cut and the `/dev:implement-spec` driver)
writes to an owner repo only through its beads database (`bd -C <owner>`), never a file, a
`.gitignore` line or a commit, which belong to the story orchestrator on that story's
integration branch (ADR 0010 in the plugin repo). Reading an owner repo's code stays
allowed, which is what the working-directory preflight is for.

The orchestrator never: calls `Edit`/`Write` on anything a ticket could own; runs `tdd`; runs
tests in order to fix them; resolves a merge conflict by hand; patches a review finding
itself; or "finishes off" a subagent's work when it comes back incomplete. When a subagent
fails, bails, or leaves a gap, the answer is always another subagent (a fresh implementer, a
split, or a fix-up at the right tier) with a better brief. Opening a source file to change it
is the signal to spawn.

Communication to and from subagents is sparse and goes through context pointers (spec,
story, tickets, notes, previous commits). Every orchestrator waits the same way, the driver
and a nested orchestrator (a story orchestrator or a ticket runner, which is itself a
subagent) alike: it spawns, ends its turn and is resumed by each child's completion
notification, since an Agent call returns at once in this harness (Waiting, in `harness.md`). A
nested orchestrator never resumes a child with `SendMessage`: the reply lands in the
top-level session, not in the orchestrator, whose turn is over (INFRA-27's run,
2026-10-19; this doc read that run as "a background spawn returns at once, so spawn in the
foreground", and no such spawn exists: ADR 0012 in the plugin repo). Only the driver
resumes an agent, and only a cut-off story orchestrator (Cut-off agents, in `harness.md`). A child
that needs another pass gets a fresh subagent, same tier, same worktree, with the findings
in its brief.

**Delivery.** The typed command is the authority for what it delivers. `/dev:implement-spec`
and `/dev:implement-story` are typed to deliver a PR, so the commits, the push of the
integration branch and the PR are what the user asked for, the "explicitly asked" of the
Beads profile block in the user-level `CLAUDE.md`: the orchestrator pushes and opens the
PR as steps of the run (ADR 0009 in the plugin repo). A story orchestrator spawned by
the driver has no user to ask in any case (INFRA-28's run 2, 2026-10-20: its deliver step
waited for an approval that could not come, and the feature needed a hand push and a
third run). A push or PR command that fails (no `origin`, no login, a prompt the user
denied) ends the run with a `failed: push <command>: <error>` line, the merges safe on
the local branch, and the next run's plain push is the retry (`git push --force` is
denied in settings).

**Subagent type.** A story orchestrator and a ticket runner are spawned with
`subagent_type: "general-purpose"`, the type that carries the Agent tool; `Explore` and
`Plan` do not, and a runner without it can spawn no one (INFRA-28's run 1, where
`chezmoi-gfu.1.6`'s runner handed its seams to a reviewer instead). A subagent that finds it
has no Agent tool reports `failed: no Agent tool` at once; the work is never done inline.

## Scratch space

**Exploration notes** go in `.spec-notes/<epic-id>/`, repo-relative, written by
`/dev:implement-story`'s exploration subagent and shared by every later subagent of that story.
The directory is that skill's alone: the story cut's orientation is the story bead's design
field, not a file.

**Gitignore.** Before the first ticket, `.gitignore` covers `/.claude/worktrees/`,
`/.worktrees/`, `/.spec-notes/` and `/.tmp/` (the TMPDIR rule in `harness.md`, read at the root of a
worktree too, since a worktree checks out the same `.gitignore`). Add what is missing and
commit that first, so no ticket branch carries scratch files. The entries and their commit
are the story orchestrator's alone (`/dev:implement-story`'s Gitignore step): no earlier stage
adds a line, and an edit of the user's beside them is never committed.

**Plugin root.** These rules docs, the runbook (`docs/WORKFLOW.md`) and the hooks ship in
the dev plugin, so every skill reaches them through the plugin root, `<plugin root>`, the
directory the harness names in its plugin-root variable `CLAUDE_PLUGIN_ROOT`. A skill
resolves it once per session: its text writes `${CLAUDE_PLUGIN_ROOT}/docs/agents/<doc>.md`,
which the harness fills in with the absolute path when it loads the skill (as it fills in
`hooks/hooks.json`'s `guard-rm.sh` command). Bash never has the variable, in the main
session or a subagent, so only if the text still shows it does the session fall back to the
`Base directory for this skill: <path>` line the Skill tool prints on loading a plugin skill:
that path is `<plugin root>/skills/<skill>`, so the root is two levels up (under
`claude --plugin-dir .` it is that checkout). With neither, it ends with
`failed: plugin root unresolved` rather than guessing a path. From then on the session
spells the absolute rules-doc path literally in every brief,
`<plugin root>/docs/agents/orchestration.md` with `<plugin root>` replaced by the path it
resolved, as the TMPDIR rule in `harness.md` spells `<worktree>`: never `$CLAUDE_PLUGIN_ROOT`, never a `~/`
path. A subagent's Bash has no such variable (unset in this rule's own ticket run,
2026-10-24) and the worktree guard refuses a path
built from one (Literal paths in `harness.md`), so a brief that names a variable sends its subagent to a
doc it cannot open. Every pointer a brief carries, "the harness doc's TMPDIR rule" or "the
harness doc's Idle rule", names that doc by its own absolute path, `<plugin root>/docs/agents/harness.md`.

## Complexity tier

Each ticket carries a `complexity:low|medium|high` label that maps to an implementation model
and a review model. The table and its rules are in `issue-tracker.md`, "Complexity labels";
the mapping is mechanical.

The reviewer is always one tier of model above the implementer, because a same-tier reviewer
shares its blind spots. Set `model:` on every Agent call explicitly; never let it default to
the orchestrator's own model. The built-in `code-review` skill runs at whatever model invokes
it, so reviewers are spawned at the review model and never run by the implementer. A merger
runs at the implementation model of the ticket it merges. The end-of-run review and its fix-up run at the max tier of the tickets in scope (the
story's tickets for a story, the epic's for an epic): review at that tier's review model,
fix-up at its implementation model.

## Review

**Check gate.** The check gate is one loop, at the ticket level and the story level alike
(GLOSSARY.md: Test seam, Check, Check gate). Run the story's checks, the owner repo's lint
and its test seams: lint first, then the test seams, and the first red stops the run.
A red goes to a fresh fix-up implementer, never to a reviewer, and the loop starts over.
With the checks green, run the review: a clean verdict exits at the ticket level, while
at the story level the review marker is the exit (`/dev:implement-story` step 7), and
a blocking verdict goes to a fresh fix-up implementer and the loop starts over.
Either cause spends the budget, three fix-ups per ticket at the ticket level and
three per story at the story level; a fourth failure is `failed`.

**Review verdict.** Every reviewer, the ticket runner's per-ticket reviewer (the runner
brief's step 3 in `/dev:implement-story`) and the story review's two sub-agents (its step 7)
alike, tags every finding **blocking** or **minor** and ends its report on one verdict
line. A finding is blocking when an acceptance criterion is unmet, a behaviour is wrong or
a test is missing; it is minor when it changes no behaviour an acceptance criterion names
(wording, naming, a nit). The last line is `verdict: clean` when no finding is blocking,
else `verdict: blocking (<n>)`, `<n>` the count of blocking findings. A round with
no blocking findings is **clean**, whatever its minors: they go to one last fix-up
implementer before the merger, or to the inbox as a deferral when the orchestrator judges
them out of the ticket's or the story's scope (the tracker doc's "capture a retro item";
Frontier, Deferrals, below), never to a bead of the story; then the ticket closes, or the
story proceeds to delivery, and no reviewer runs over that last fix-up.
Every fix-up, red or blocking, spends the loop's budget (the Check gate rule above); at
the ticket level a clean round's fix-up does not (at the story level it does, since the
loop starts over after it: `/dev:implement-story` step 7). A round that reports every
acceptance criterion met plus three wording nits is clean, and the ticket goes to the
merger after one fix-up. Before this rule a round was clean only with no finding of either
kind (INFRA-29's runs, 2026-10-22 to 2026-10-23): `chezmoi-9v4.1.5` failed twice on rounds
that reported every criterion met plus four, then one, wording findings, costing two
runner restarts and a fourth driver run, and `chezmoi-9v4.1.1` took seven Fable rounds.

## Frontier

The **frontier** is the set of tickets an orchestrator may start now. Work only the frontier.
A ticket is on it when all of these hold:

- it is open and unclaimed, and `bd ready` lists it in its owner repo (`bd -C <owner> ready
  -n 0 --json`, since the default limit is 100). Native edges stay inside one database, so
  `bd ready` honours them;
- it is labelled `ready-for-agent`. `bd ready` does not treat labels specially, so the
  orchestrator does: a ticket without that label (`ready-for-human`, `needs-triage`,
  `needs-info`, `wontfix`, or no triage label at all) is never claimed and never gets an
  implementer, reviewer or merger. Lacking `ready-for-human` is not enough: a review
  deferral filed as a `needs-triage` child of the story is listed by `bd ready` and has
  nothing to implement (INFRA-27's resumed run, 2026-10-20: four such children of
  `chezmoi-a0q.1` sat in `bd ready`, one of them a list of seven deferrals, and the driver
  stopped to ask for a triage);
- it has not failed twice in this run (`/dev:implement-story`'s step 5). Unclaimed, it is back in
  `bd ready`, so only the run's own count keeps it off;
- no **text blocker** of the ticket's story is open.

A text blocker is a line `<repo> <bead-id>` under the `## Blocked by` section of the
ticket's story, one edge of the feature's **story DAG** (`issue-tracker.md`'s "Before the
story quiz"); a ticket has none of its own, and a story may carry several. Each line names
either a **human gate ticket**, a `ready-for-human` ticket that clears when a person closes
it (a publish ticket, closed with the published version), or a story, which clears when
`/dev:close-story` closes it after its PR merges, so once that story is finished its line
waits on a merge and a `/dev:close-story` run, never on any agent. `bd ready` knows nothing of
text blockers and lists a ticket whose story's blocker is still open, so the orchestrator
reads each line and checks that bead in its own database: `bd -C <owner> show <bead-id>
--json`, status `closed`, where `<owner>` is `<repo>`'s path by the one test in
`issue-tracker.md`'s opening. An open text blocker holds back every ticket of the story,
until every line's bead is `closed`. A line that names no id (`(not created: no beads
database)`) and a blocker that cannot be read both count as open. In a repo session
`<home>` is the only owner, so a text blocker in another repo is unreadable and counts as
open: such a story is run from the workspace session that cut it. A story with no text
blocker holds back nothing beyond `bd ready`.

A publish ticket, like every human gate ticket, is `ready-for-human`, so it is off the frontier, yet it appears in `bd ready`
(and under `--parent <story-id>`) as soon as its story's implementation tickets close.

**Unclaim.** A claim outlives its runner and hides the ticket from `bd ready` (Cut-off agents
in `harness.md`), so a ticket left claimed is off every later run's frontier until someone unclaims it
(INFRA-27's run 1, 2026-10-20: `chezmoi-a0q.1.5` stayed `in_progress` and assigned after two
failed runners, and the user ran `bd unclaim` by hand twice). So the story orchestrator
`bd -C <owner> unclaim <id>`s every ticket whose runner returned without closing it, a
`failed` report or a cut-off, before its next frontier read, and when a ticket leaves the
frontier after its second failure it also notes the resume pointer on the ticket: open,
unassigned, listed by `bd ready`, the note saying what to type. A person runs `bd unclaim` by
hand only when the orchestrator could not. A run that ended in an error instead of a report
leaves its tickets claimed, and the re-run's own unclaim covers them, so the hand run only
saves waiting for it. A claim bd refuses to release because another actor holds it needs
`--force`, which the orchestrator never adds: it reports the holder on a `failed:` line and
leaves the call to a person. `/dev:implement-story`'s step 9 names both beside its `resume:` line.

**Deferrals.** A finding the story review puts off (out of the story's scope, a follow-up,
a note with nothing to implement) is a retro item: the story orchestrator captures it in
the inbox as the tracker doc's "capture a retro item" says, with plain `bd` in `<home>`,
that section's labels and the finding as the body's Moment, and never creates a child of
the story for it; the review's sub-agents report findings and create no bead either. A child is a ticket, and one carrying `needs-triage`
stays open until `/dev:triage` decides it, which no run of the orchestrator can do. So a story
is **finished** (`GLOSSARY.md`) when every child is `closed` or carries `ready-for-human`,
`needs-triage` or `wontfix` and its `pr:` note exists: an untriaged child an earlier run
left under a story holds back neither its review nor its PR, and `/dev:implement-story`'s step
6 counts the same way before its review.

A `closed` ticket is never on the frontier, so a resumed run skips everything earlier runs
closed. Re-evaluate the frontier after every close: a closed ticket may release native and
text blockers, and each newly released ticket goes to a ticket runner at once.

When nothing is in flight (implementer, reviewer, merger, fix-up) and the frontier is empty,
the run ends. It is a **human stop** if a `ready-for-human` ticket is open, or if a story
is held only by text blockers naming finished stories (each with its `pr:` note, waiting on
a merge and a `/dev:close-story`; `GLOSSARY.md`'s Human stop), and a **stall** otherwise. A
human stop's report names the open ticket, and for each such blocker the blocking story,
its PR and the action: merge its PR, then run `/dev:close-story <story-id>` in its repo. A
stall's report names each stuck ticket with its open blocker. A run
whose tickets are all closed ends the same way when a test seam stays red or the push is
refused (Delivery), with the seam or the push and its command on a `failed:` line.

## Working-directory preflight

Run by `/dev:spec-to-stories`, `/dev:spec-to-tickets` and `/dev:implement-spec`, each at the step that
names it, before any non-home repo is read and before any subagent is spawned. The skill
names the directories to check. Each must be a working directory of the session: the
"Primary working directory" or one of the "Additional working directories" in the
environment block (a directory inside one counts). Compare absolute paths against that
listing; `Read` and `ls` are permitted only on a working directory, so they cannot tell you
a directory is missing. `<home>` (the one test in `issue-tracker.md`'s opening) never
counts as missing. In a repo session the only owner is `<home>`, so in practice nothing
is missing. In a workspace session `<home>` is the workspace, and every
`<workspace>/<owner repo>` is normally inside the primary working directory, so in
practice only a manifest `path` that leaves the workspace is missing; the comparison
above still decides. `/dev:implement-spec` checks only the owner repos it starts.

Any missing → refuse, with no override: print one line per missing directory, its
absolute path in place of `<dir>`, then stop. Create nothing, spawn nothing and write
nothing.

```
/add-dir <dir>
```

The remedy is the user's visible action; rerunning the command once they have run it
should pass. If the refusal repeats after `/add-dir`, the environment block did not
refresh mid-session: restart the session with the directory added (`claude --add-dir
<dir>`, or `/add-dir` before invoking the skill). A `/add-dir` typed at the story cut
carries the ticket cut and `/dev:implement-spec` in the same session.
