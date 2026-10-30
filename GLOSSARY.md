# Feature workflow

The vocabulary of the Jira + beads feature workflow defined in this repo (runbook in
`docs/WORKFLOW.md`, agent rules in `docs/agents/`). Several words
here name more than one thing in the tools; this file fixes which is which.

## Language

**Jira Epic**:
The one Jira issue a feature has. It holds the spec, triage labels, and stakeholder
discussion; it is the human-facing layer and never sees individual tasks. Never a bare
"epic", which could as well mean the epic bead.
_Avoid_: Jira ticket

**Epic bead**:
The beads issue that anchors a feature on the agent side, linked to its Jira Epic by
`--external-ref`. An open epic bead means the feature is in flight. Never a bare "epic"
either.
_Avoid_: root bead

**Malformed epic**:
An epic bead with a direct child that is not a story. The story-tier skills refuse it, by the
malformed-epic refusal of the tracker doc's "gather the epic bead", and suggest nothing;
`/dev:workflow` reports it without positioning it.
_Avoid_: flat epic

**Story**:
The part of one feature that lands in one repo as one PR: what that PR must deliver, and
the parent of the feature's tasks there. A story is one PR, with one integration branch
(`feat/<story-id>`), re-deliverable while the PR is open and sealed once it merges; a
feature has one story per PR, usually one per repo, each tied to the feature by its Jira
key. A story exists only in beads; Jira never sees it. It is a partition by delivery, not
a user story; Jira Stories are a different thing this workflow never creates.
_Avoid_: user story, lane, leg, repo slice, cross-repo task, delivery round

**Map**:
A beads issue of epic type that holds a wayfinding effort's decision tasks. It is
agent-internal, is not a feature, and is never counted as a feature in flight.
_Avoid_: wayfinder epic, planning epic

**Task**:
A bead holding one implementation slice, the bottom of the epic → story → task hierarchy
and the one unit an implementer builds: a story's task (its parent is the story for the
repo it changes) or a standalone task. Its beads issue type is `task`. Tasks exist only in
beads, never in Jira. The harness's own "task" (`TaskStop`, a task notification) is named
by its tool, never by the bare word.
_Avoid_: ticket (any level of something to do; a story is not one), sub-task

**Standalone task**:
A task with no story: a triaged retro item or a small bug. It is
the task row's unit all the same.
_Avoid_: loose bead, orphan task

**Test seam**:
The highest public boundary of a repo through which a feature can be tested, one of the
few a story names under its `## Test seams`: the story's testing boundary, not a check.
The implementer's brief names the seams as where its tests go, and the reviewer's as where
the unit's criteria must be exercised; no test at a seam exercising them is a blocking
finding.
_Avoid_: test boundary, test surface, test entry point

**Story cut**:
The first of the two cuts a spec goes through: the spec resolved into its stories, one
per repo it changes unless the spec or the user splits a repo's into several, each with
its owner repo, what that PR delivers, its test seams, and its edges to the other stories
(which side publishes and at what version, or whose closure it waits on). It ends at the
story quiz and leaves the stories in beads with no tasks. On a feature whose stories
exist it runs in **add mode**: the same quiz over additions only. Its one refusal there is
a feature whose every story is closed: that feature is delivered, and more work on it is a
new feature, not an addition. A re-cut is the task cut's word, never this one's.
_Avoid_: cut one, story split, repo split

**Story DAG**:
A feature's stories and the edges between them, each edge a text blocker on the story
that waits: a publish edge or a story-closure edge. It may hold chains and several edges
per story, never a cycle; the story cut refuses one before any bead exists, and the task
cut before its first wave.
_Avoid_: story graph, dependency graph

**Task cut**:
The second cut: every story of a feature cut into its tasks, with their blocking edges
and tiers, in dependency order (the dependency's story before its dependents). It ends at
the publish of each story's tasks to beads and the one Jira comment covering them.
_Avoid_: cut two, task breakdown, ticket cut

**Session repo**:
The git repo the session is typed in, `git rev-parse --show-toplevel` of its working
directory. It fixes the session's mode and is the home of everything the session starts.
_Avoid_: current repo, cwd

**Session mode**:
Whether a session is a workspace session or a repo session, decided by **the one test**:
the session repo holds `repos.yaml` or it does not. The test is stated once, in the
tracker doc's opening, and every skill points at it rather than restating it. Its names:
`<home>` is the session repo and `<home name>` its basename, the word a `## Parent` line
carries after `Home`.
_Avoid_: discovered mode, walk-up, workspace detection

**Workspace session**:
A session whose session repo holds `repos.yaml`: it is typed at a workspace root. The
session routes across the manifest's repos: stories and tasks go to their owner repos,
retro items to the repo that owns the file. The only way a feature spans repos.
_Avoid_: cross-repo mode, workspace mode, multi-repo session

**Repo session**:
A session whose session repo holds no `repos.yaml`. It never routes: the one owner repo is
the session repo, and a workspace above it, if any, is ignored. A spec that needs a second
repo is refused, not cut to a subset, and a retro item whose fix lives elsewhere files
here as `retro:foreign`.
_Avoid_: single-repo mode, local mode, standalone session

**Home**:
The database the session started in: the workspace in a workspace session, the home repo
in a repo session. It holds the feature's epic bead, the spec, and the inbox. Stories and
tasks live there only in a repo session, whose home repo is their owner repo; a
workspace owns no story.

**Home repo**:
The home of a repo session: the one repo whose beads database holds the feature's epic
bead and its only story. The role says nothing about who depends on whom: a feature may
start in a library and need a change in a consumer, or the other way round. Build and
merge rules name repos by cargo's words instead, **dependency** and **dependent**, and
either may be the home repo. A workspace session has no home repo; its home is the
workspace.
_Avoid_: primary repo, main repo, parent repo (and consumer or dependency as a name for it)

**Human gate task**:
A `ready-for-human` task whose closure by a person releases a story blocked on it in
text: a publish, a deploy, a flag flip. It is blocked natively on its own story's
implementation tasks and sits last in it; one story has at most one publish task,
since one PR publishes one version.
_Avoid_: human task (any `ready-for-human` task is one; a gate task is one a
story waits on), manual step

**Publish task**:
The human gate task in a dependency repo's story that stands for publishing its crate
to the registry. It is closed by a person with the published version as the reason, which
the dependent's bump task reads.
_Avoid_: release task, publish gate

**Owner repo**:
The repo whose beads database holds a story and its tasks. The story cut fixes it
from the repo manifest before the story quiz and never re-routes it; every later stage
reads it back as the database the story was found in.
_Avoid_: target repo, task repo

**Text blocker**:
A line under a story's `## Blocked by` naming the bead that story waits on: a human gate
task, or another story, in any repo's database, the story's own included. The feature's
stories and these lines form a DAG; a story may carry several. Beads edges do not cross
databases, so `bd ready` ignores it and the orchestrator honours it by hand: no task of
that story is on the frontier until every text blocker is `closed`. It takes one of three
forms:
- `<repo> <bead-id>`: the blocker exists, and the line clears once that bead is `closed`:
  a gate task closed by a person, a story closed by `/dev:close-story` after its PR merged.
- `<repo> publish <crate> <version> (not created yet)`: the placeholder the story cut
  writes; it counts as open until the dependency's task cut creates the publish task
  and rewrites the line to `<repo> <bead-id>`.
- `<repo> publish <crate> <version> (not created: no beads database)`: the dependency
  repo was skipped, so no publish task exists there; the line counts as open until a
  person edits it.
_Avoid_: soft dep, cross-repo edge, external blocker, story dep

**Publish edge**:
An edge of the story DAG whose text blocker names a publish task (filled, or a publish
placeholder): the story carrying it is the **dependent**, which gets one bump task for
it, and the story holding the publish task is the **dependency**. Only publish edges
order the task cut's dependency waves.
_Avoid_: publish dep, crate edge

**Story-closure edge**:
An edge of the story DAG whose text blocker names another story, `<repo> <story-id>`: the
waiting story starts once that story is closed by `/dev:close-story` after its PR merges. It
adds no task and orders no wave; a run held only by such edges ends as a human stop.
_Avoid_: story dep, sibling blocker, merge edge

**Finished story**:
A story whose children are all closed or carry `ready-for-human`, `needs-triage` or
`wontfix`, and whose `pr:` note exists, so an earlier run reviewed and delivered it. An
untriaged child an earlier run left under the story never holds the PR, nor the close at
`/dev:close-story` once the PR merges: it is not a task to run, and the frontier never
admits it. Each story has its own
integration branch, review and PR, recorded on the story bead; a later run leaves a
finished story untouched and only reports its PR or branch. Finished is not sealed: while
its PR is open, add mode may mark it for a re-cut (a `recut:` note naming the new publish
blocker, the one note that lets the task cut past its `pr:` note), and the next run
delivers the same PR again.
_Avoid_: done story, finished repo, touched repo, sealed story (that is a merged PR)

**Merge guard**:
The one forge query `/dev:implement-story` runs before committing to a delivered story (a
`pr:` note) that has an open `ready-for-agent` task: a merged PR refuses and points at
add mode, a PR closed unmerged refuses, an open one continues on the story's branch, and
a branch-form note or no forge is decided locally, else asked. It is how a sealed story
stays sealed. `/dev:implement-task` runs the same guard on an open standalone task with a
`pr:` note: merged and closed-unmerged refuse, an open one delivers again.
_Avoid_: merge check, PR check, seal check

**Check command**:
The one command an owner repo's check runs: `make check`. Every owner repo has a `check`
target: `/dev:setup-repo` adds one, and a story run in a repo with none fails at once
(`docs/agents/orchestration.md`, "Review"). Every row runs the same one, resolved once per
story run by the story orchestrator, which hands it to each task orchestrator.
_Avoid_: gate command, CI command, lint command

**Check**:
One run of the check command on a tree, named by the tip's tree SHA. Every tree is checked
once green: a tree with a green check record counts as checked, one with a red record is
checked again, and a sibling landing, a conflict resolution or a fix-up's commit makes a new
tree that is checked again; a fix-up that commits nothing makes none.
_Avoid_: pre-flight, verification step

**Check record**:
The command, its exit and its log of one check, written by the orchestrator that ran it
under the owner checkout's scratch directory, keyed by the tree SHA. Only an orchestrator
writes one, an implementer's own runs never count, and the PR's Evidence is the record of
the delivered tip's tree. The story orchestrator names that tip and its record in the
delivered-tip note on the story bead (`delivered: <tip SHA> <check record>`), the one tip
the epic review reads.
_Avoid_: check stamp, check cache, run log

**Check gate**:
The one gate every row (task, story, epic) runs: the check command, then the review. It
exits when the checks are green on the tip the review called clean. A red or a blocking
verdict goes to a fresh implementer by pointer brief (at the epic row, to `ready-for-agent`
tasks under the story) and the loop starts over, three such
fix-ups per unit (per story at the epic row) per invocation and the fourth `failed`; a minors fix-up and
a conflict resolution move the tip, so the checks rerun, but no reviewer runs again and no
budget is spent: the gate exits on the moved tip once its checks are green. The story
orchestrator records that tip in the reviewed-tip note (`review: <tip SHA>`), so a rerun
knows it: on the story bead under `/dev:implement-story`, on the task bead under
`/dev:implement-task`, which has no story bead; the task row writes no such note.
_Avoid_: test gate, lint gate, seam gate, check and review loop, review marker

**Review verdict**:
The line a reviewer's report ends on, at every row: `verdict: clean` when no finding is
blocking, else `verdict: blocking (<n>)`. Every finding is tagged **blocking** (an
acceptance criterion unmet, a behaviour wrong, a test missing, or no test at a story seam
exercising the criteria) or **minor** (wording, naming, a nit that changes no behaviour an
acceptance criterion names). The spec axis judges the row's unit (task body, story body,
Jira Epic spec); the standards axis judges what entered since the last standards review,
and is skipped at the epic row. A clean round sends its minors to one last
fix-up or to the inbox (at the epic row, always the inbox) and moves on; a blocking
round's fix-up fixes its in-scope minors too and the rest go to the inbox at once, and every minor still unfixed when the unit
lands or fails goes to the inbox; a red or blocking fix-up spends the check gate's
budget, a minors fix-up spends none (`docs/agents/orchestration.md`, "Review").
_Avoid_: zero findings, nit-free, pass/fail

**Epic orchestrator**:
The session that runs `/dev:implement-spec`, the epic row's orchestrator: it spawns one story
orchestrator per startable story, runs the epic review once every story has delivered,
holding each PR a draft until its verdict is clean, and reads the end state; nothing below
it touches a task. It is the only agent whose turn a `SendMessage` reply reaches, so it
alone resumes a cut-off story orchestrator, and its `TaskStop` reaches every agent of the
run.
_Avoid_: feature orchestrator, top-level orchestrator, main session, driver

**Story orchestrator**:
The story row's orchestrator: it works one story's frontier in its owner repo, one task
orchestrator per task, lands each reviewed task branch (the stray-commit check, the
merge, a conflict to an implementer in the task's worktree and then a fast-forward, at
most three resolutions per landing, a red on a resolved tree to a fresh task
orchestrator), runs the story's check gate on the integration branch and delivers it as a
draft PR. Landings are serial, one per report, so no lock is needed. Spawned per story by
the epic orchestrator, or the session itself when `/dev:implement-story` is typed in the
story's repo. The session running `/dev:implement-task` on a standalone task is one too,
with a frontier of that one task, no story bead and no story gate: the task's branch is
what it delivers, as a PR opened ready.
_Avoid_: sub-orchestrator, repo agent, merger, chore orchestrator

**Task orchestrator**:
The task row's orchestrator, the subagent running `/dev:task-orchestrator`: it owns one
task from claim to a reviewed branch, its implementer, its check gate and its fix-ups,
and never touches the owner checkout. It enters at the gate when the branch already carries
commits (a cut-off's replacement, or a retry after a conflict resolution's red). Spawned
per frontier task by a story orchestrator (`/dev:implement-story` or `/dev:implement-task`),
never typed, to which it reports one line (`reviewed`, `needs split` or `failed`) and is
discarded.
_Avoid_: task agent, worker, task runner

**Claim entry**:
The task orchestrator's entry for a fresh task, a brief with no `gate entry:` line: it
claims the task, spawns the implementer in a new worktree reset onto the integration
branch tip, then runs the check gate. Every spawn is one but a gate entry.
_Avoid_: fresh entry, cold start

**Gate entry**:
The task orchestrator's entry when the task's branch already carries commits: a cut-off
task orchestrator's replacement on its surviving branch, the one retry after a red on
a conflict-resolved tree, or a first failure's retry whose Cut-off probe finds commits.
It claims the task and goes straight to the check gate on the
branch, worktree path and tip its brief names, with a fresh budget and no implementer
build; after a red on a resolved tree, the brief also carries that red record's log.
_Avoid_: re-entry, resume entry

**Implementer**:
The one agent kind that edits files: it builds a task, fixes a failed check or a review
finding by pointer brief, or resolves a merge conflict, always fresh and in the unit's
worktree. A fix-up or a conflict resolution is an implementer given a different brief,
not a role of its own (ADR 0014).
_Avoid_: fix-up implementer, fixer

**Stray-commit check**:
The read of every commit a push or a merge would carry but merges, before it runs: one whose
author is not the run's `user.email`, or that has no `Bead:` trailer, came from outside the
run (a test whose throwaway repo failed to init commits into the enclosing checkout).
The story orchestrator runs it before every merge and every push (a trust rule): before
each landing of a reviewed branch onto the integration branch, and before each push of it;
a hit stops the merge or push with `failed: stray commit <sha> <subject>`.
_Avoid_: push guard, stray check

**Forge-check wait**:
The story orchestrator's wait, after the delivery push, for the PR's forge checks on the
pushed tip, before the delivery is recorded: a red check is a `failed: forge check <name>
<run URL>` line and leaves the story unfinished; a repo with no forge or no checks delivers
with a `checks: skipped` line. The one shell wait the Idle rule allows.
_Avoid_: CI wait, check poll

**Cut-off**:
An Agent call that returns an API error (a session or rate limit) in place of its report.
The child and everything below it stop where they are, state intact: a story orchestrator
is resumed by the epic orchestrator, every other agent is replaced by a fresh one in the same
worktree, and a cut-off task rejoins the frontier with its failure count unchanged. A
task orchestrator's `failed` line is its own verdict on its task, not a cut-off, and neither is a
story orchestrator the user stopped: that one is replaced on the next typed command.
_Avoid_: crash, timeout

**Stop sweep**:
What the epic orchestrator does before resuming a cut-off story orchestrator: `ListAgents`, then
`TaskStop` on every agent it did not itself spawn, since a child whose parent's turn was
cut off is owned by no one else and stays listed as running however quiet it is.
_Avoid_: cleanup, kill, orphan reaping

**Idle rule**:
Every subagent below the epic orchestrator runs Bash in the foreground only, never a background call
or a `Monitor`: a turn that ends with one still running counts as idle, so the parent is
resumed with an interim report and marked finished, and the real report escapes to the
top-level session; a lint or test run passes `timeout: 600000`, since one left at the
120-second default is backgrounded. A turn that ends with an Agent child mid-turn is not
idle; that is how a nested orchestrator waits (ADR 0012).
_Avoid_: foreground rule, no-background rule, sync rule

**TMPDIR line**:
The first line of every brief to an agent that works in a worktree (an implementer, whatever
its brief): `mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp`, the worktree path
spelled out literally, so `mktemp`, heredocs and the scripts that use them
write under a gitignored directory inside the worktree instead of a temp directory the
sandbox denies. Its two riders: the `export` is repeated at the head of every Bash call,
since shell state does not survive one, and `mktemp -d` takes a template under `.tmp`,
since macOS `mktemp` ignores `TMPDIR`. Stated in the orchestration rules' Scratch space.
_Avoid_: tmp line, scratch export, temp rule

**Story cutter**:
The agent that drafts one story's tasks during the task cut: it explores the story's
owner repo and returns the breakdown, creating nothing. The task quiz and the publish
stay with the session that spawned it, so no edit is relayed back to it. One per story,
spawned a dependency wave at a time, each dependent's cutter given the dependency's
breakdown.
_Avoid_: cut agent, breakdown agent, task drafter

**Draft role**:
What `/dev:story-to-tasks` does when called by a story cutter brief, or any brief that
names no role: it returns the breakdown as one block and creates nothing.
_Avoid_: dry run, preview mode

**Publish role**:
What `/dev:story-to-tasks` does when called by a brief that opens `Publish this block` and
carries an approved block: it publishes that block as given, drafting nothing of its own.
The task cut sends one per story after the task quiz.
_Avoid_: publish mode (and the bare word "publish" as a trigger)

**Dependency wave**:
One batch of story cutters the task cut spawns together and waits for as a whole: one wave
per level of the stories' DAG, in topological order, so each cutter gets the breakdown of
every story its own waits on. A cycle is refused before the first wave. The word is the
task cut's: a batch of task orchestrators is not a wave.

**Frontier**:
Per story: the tasks of one story that `bd ready --parent <story-id>` lists and that
carry `ready-for-agent` (`bd ready` lists a `ready-for-human` or `needs-triage` child
all the same), and none at all while the story has an open text blocker
(`docs/agents/orchestration.md`, "Frontier"). A task whose orchestrator ended
without closing it is unclaimed by the story orchestrator before its next frontier read,
since a claim outlives its orchestrator and hides the task from `bd ready`; a task that failed
twice in a run is off that run's frontier though `bd ready` lists it. (The grilling skill uses the
same word for askable questions; in this repo it means tasks.)
_Avoid_: ready list, todo, backlog

**Invocation**:
One typed `/dev:implement-spec`, `/dev:implement-story` or `/dev:implement-task`, from the
command to its end state. It includes everything the command does before it reports: its
re-polls of pending checks, and its continuation from the person's next message after a
session limit cut it off. Every fix-up budget is bounded per invocation: three fix-ups per
unit, and only a person typing the command again grants more. A later invocation reads
what earlier ones left in the beads as history, never as spent budget, so a story whose
epic review failed is reviewed again by every invocation until it is clean or a person
closes its PR.
_Avoid_: typed run, fresh run (and "attempt" for one invocation)

**Human stop**:
The end of an invocation of `/dev:implement-spec` or `/dev:implement-story` whose frontier is empty, with
nothing in flight, while the feature waits on a person's action: a `ready-for-human`
task is open, or a story waits on another story's closure (merge its PR, then
`/dev:close-story`). The invocation reports the action and what waits behind it; rerunning the
command after the person takes it resumes the feature.
_Avoid_: pause, handoff, blocked run

**Stall**:
The end of an invocation of `/dev:implement-spec` or `/dev:implement-story` whose frontier is empty, with
nothing in flight and no `ready-for-human` task open, while some task the story still
waits for is open (Finished story above), the check gate loop has failed a fourth time,
red or review, after its three fix-ups, or the push was refused. The invocation reports each
stuck task with its open blocker, a red check as `failed: <check> <command>`, a review
as `failed: review mattpocock-skills:code-review`, or the refused push with its command.
_Avoid_: deadlock, hang

**Repo manifest**:
The file `repos.yaml` at a workspace root, listing every repo in that workspace, its
checkout path, and the crate or module names it publishes. Its presence in the session
repo is what makes a session a workspace session. Skills use it to route a task or retro
item to the repo, and so the beads database, that owns the file it would change. It holds
nodes only; dependency edges stay in each repo's own `Cargo.toml` or `go.mod`. The cargo
`lynx` registry is a different thing.
_Avoid_: repo list, workspace config

**Workspace**:
A git repo whose working tree is the directory holding one organisation's repo
checkouts as gitignored siblings, `~/src/mice-labs` on this machine. It tracks the repo
manifest, a README, `docs/adr/` for decisions that span repos, and the specs and epic
beads of features started there. A session typed at its root is a workspace session.
(Cargo uses the same word for a multi-crate `Cargo.toml`; here it means the checkout
directory.)
_Avoid_: src dir, projects folder, meta-repo

**Inbox**:
The home's beads database in its role as the place `/dev:retro` files candidates as
`needs-triage` beads and `/dev:triage` decides them: the workspace's beads in a workspace
session, the repo's own in a repo session. Once accepted, an item lives as a bead in the
repo whose file it changes, and the inbox bead closes pointing at it, even when both are
the same database. The inbox takes follow-ups, what the feature does not need to finish;
what the feature needs is a story, added by the story cut.
_Avoid_: retro backlog, workspace beads (those also hold the workspace's own work)

**Follow-up**:
Work found during a feature that the feature does not need to finish. It goes to the
inbox as a `needs-triage` bead and leaves the feature; it is never a story of the feature.
Retro items and deferred findings are its two kinds.
_Avoid_: spin-off, side quest, out-of-scope task

**Point release**:
A story added to a dependency repo after the feature's first delivery there, whose
publish task a still-open dependent story waits on: the fix for a flaw in the published
API that the dependent's migration exposed. Cut by the story cut in add mode, never routed
through the inbox, since the feature needs it.
_Avoid_: hotfix, patch story, follow-up publish

**Retro item**:
One candidate improvement to the agent's environment, traceable to a moment in a session.
An inbox bead until triaged; after acceptance, a `retro`-labelled bead in the owning repo.
In a repo session an item whose fix lives outside the home is still filed there, labelled
`retro:foreign` with the intended location in its body, and accepted as `ready-for-human`.
_Avoid_: action item, suggestion

**Deferred finding**:
A story-review finding the story orchestrator puts off rather than sends to a fix-up:
out of the story's scope, or a note with nothing to implement; one kind of
follow-up.
It is captured as a retro item in the inbox and never as a child of the story, since a
child is a task and `bd ready` would list it to the next run
(`docs/agents/orchestration.md`, "Frontier", Deferrals).
_Avoid_: deferral task, follow-up task, needs-triage child

**Provenance cite**:
The bead id inside parentheses closing the clause of a rules-doc sentence or lint-script
comment that records why a rule exists, as in "(dev-6qi)"; a bead named as a sentence's
subject is not one (`docs/agents/coding-standards.md`, "Bead ids cite provenance in parentheses").
_Avoid_: footnote id, inline bead reference

**Stage**:
One numbered row of the runbook's Stages table, named by the command you type to run it.
A feature's position in the flow is the stage its epic bead is between or in.
_Avoid_: phase

**Epic-level stage**:
A stage that works the whole feature across its owner repos: the story cut, the task cut
and the `/dev:implement-spec` epic orchestrator. It writes to an owner repo only through that repo's beads
database; files, `.gitignore` entries and commits there are the story orchestrator's (ADR 0010).
_Avoid_: feature-level skill

**Dev plugin**:
The feature workflow as the unit that is installed: the skills, the rules docs, the
runbook, this glossary, the ADRs and the hooks, packaged as the Claude Code plugin `dev`
and served from its own marketplace repo, `claude-dev-plugin`. Its skills are addressed
as `/dev:<skill>`. Whatever a machine needs that a plugin cannot carry is the machine
setup, not the plugin (ADR 0013). No one part stands for the whole: not the
orchestration rules doc, not the runbook skill, not the skills.

**Machine setup**:
The per-machine part of running the dev plugin, which a plugin cannot carry: the
user-level `CLAUDE.md` stub that points at the plugin's docs, the baseline settings, the
commit-lint git hook (the script ships in the plugin; the hook config cannot), and
the lines the runbook has the owner add by hand (the `~/src` sandbox allowlist,
`beads.role`, `BD_EXPORT_AUTO`). `/dev:setup` checks the prerequisites and hands the owner
the stub, the baseline and the hook commands, nothing more; on Kai's own machines
chezmoi applies all of it and the skill finds nothing missing.
_Avoid_: bootstrap, onboarding

**Repo setup**:
The per-repo part: the Jira project key in the repo's `CLAUDE.md`, a beads database, and
the glossary and ADR layout, written by `/dev:setup-repo`. The project key is the one
configuration point the feature skills read; a repo without it is refused.
_Avoid_: project config

**Baseline settings**:
The settings snippet the dev plugin ships for the machine setup: the denies on secret
files, the asks on destructive git and on pushing beads, the `bd` allow, and the sandbox
enabled with the beads and Dolt directories writable and push and fetch outside it. It
holds nothing org-specific; toolchain, registry and forge lines are the machine owner's.
_Avoid_: recommended settings, the settings file
