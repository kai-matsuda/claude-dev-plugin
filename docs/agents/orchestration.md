# Orchestration rules

How an agent that runs tickets behaves. Read by every orchestrating skill: `/dev:implement-spec`
(the driver), `/dev:implement-story` and the **story orchestrator** it stands for. A skill owns its
own steps; the rules here are the ones it shares. Terms are those of `GLOSSARY.md` in the plugin repo.
The cut skills, `/dev:spec-to-stories` and `/dev:spec-to-tickets`, read only the Orchestrator role's
epic-level sentence and its "Working-directory preflight", and the ticket cut the Waiting
rule for its cutter waves.

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
notification, since an Agent call returns at once in this harness (Waiting, below). A
nested orchestrator never resumes a child with `SendMessage`: the reply lands in the
top-level session, not in the orchestrator, whose turn is over (INFRA-27's run,
2026-10-19; this doc read that run as "a background spawn returns at once, so spawn in the
foreground", and no such spawn exists: ADR 0012 in the plugin repo). Only the driver
resumes an agent, and only a cut-off story orchestrator (Cut-off agents, below). A child
that needs another pass gets a fresh subagent, same tier, same worktree, with the findings
in its brief.

**Waiting.** An orchestrator waits for its subagent's report by ending its turn.
An Agent call returns at once in this harness ("Async agent launched successfully"),
whichever way `run_in_background` is written. `run_in_background` is a JSON boolean, so
the string `"false"` is truthy and launches in the background, which is how every call in
INFRA-29's run 2 was written (2026-10-23, Claude Code 2.1.306); the driver's call that
omitted the field launched async as well; and a ticket runner of that run reported that
the Agent tool it saw had no `run_in_background` parameter at all. So on 2.1.306 the field
is absent for a nested agent, and a boolean `false` there has nothing to switch; whether a
top-level session's boolean `false` is honoured was not tested, and nothing here depends
on it. There is no foreground spawn. A child's report reaches its parent only as
the Agent tool's completion notification, and only while the parent is still waiting on
work it spawned; so after spawning, the orchestrator ends its turn, the notification
resumes it with the report, and the driver never has to relay a report by `SendMessage`.
A batch is the same: spawn every call in one message, end the turn, and act on each
report as its notification arrives. An orchestrator never polls: not in a Bash loop,
foreground or background, on `bd show` of the ticket's status, on `sleep` or on the
process list, and not with a `Monitor` on a bead, which is a background call behind a
filter (the Idle rule).
`pgrep` cannot list processes in the sandbox (`sysmond service not found`,
`Cannot get process list`), so a wait loop built on it exits at once and reports done over
a child still running; a `bd show` loop holds a shell for as long as the child runs and
tells the orchestrator nothing the report will not (INFRA-28's run 1, 2026-10-20: 21 of 45
background shells were killed, one printing the same two `in_progress` tickets for an hour).

**Idle rule.** Every subagent below the driver runs Bash in the foreground only (`timeout`
up to 600000 ms) and never starts a background Bash call or a `Monitor` on a bead; the
merger's lock wait is no exception. The harness notifies a parent of a child's turn ending
only when nothing is live below the child. A turn that ends with an Agent child mid-turn
keeps the parent waiting, which is how a nested orchestrator waits (above); a turn that
ends with a background Bash call or a `Monitor` still running counts as idle, not live.
The parent is then resumed with that interim notification as the child's report, the
parent is marked finished when the parent's own turn ends, and the child's real report,
once the background call completes, escapes to the top-level session (the probe of
2026-10-23: a haiku parent spawned a haiku child that ran `sleep` in a background Bash call
and ended its turn; the parent was resumed with the interim notification and listed as
finished, and the child's final line went to the top-level session). A `Monitor` is that
same background call behind a filter, so it is no better. This is the mechanism behind
the no-polling rule above, and why INFRA-29's until-loops and Monitors woke agents with
stale state. The one shell wait is a merger's wait on the owner checkout's lock (the
ticket runner brief's step 4): a single foreground Bash call running an `until` loop over
`<owner>/.git/index.lock` and `MERGE_HEAD`, with the call's `timeout` as the five-minute
bound, so it returns when the lock clears and is killed when it does not (chezmoi-sn1's
check, 2026-10-22, saw the background form end the merger's turn with nothing reported).
The Bash tool's text says foreground `sleep` is blocked and points at `Monitor`; the same
check ran the foreground loop unblocked in a session and in a subagent alike, and the
observed run wins.

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

**Commits.** A commit a hook rejects (commit-msg or pre-commit) is fixed and retried
before any other `git` operation, and a branch is merged only onto a clean tree:
`git status --porcelain --untracked-files=no` prints nothing. `git merge` carries
uncommitted changes through when they touch no file the merge does, so a skipped retry
goes unnoticed (INFRA-28's run 1, 2026-10-20: an implementer whose subject failed the
72-character limit merged `feat/infra-28` over its uncommitted fixes and committed them
after the merge). Every brief to an agent that commits or merges (implementer, fix-up
implementer, merger) names this rule.

**Subagent type.** A story orchestrator and a ticket runner are spawned with
`subagent_type: "general-purpose"`, the type that carries the Agent tool; `Explore` and
`Plan` do not, and a runner without it can spawn no one (INFRA-28's run 1, where
`chezmoi-gfu.1.6`'s runner handed its seams to a reviewer instead). A subagent that finds it
has no Agent tool reports `failed: no Agent tool` at once; the work is never done inline.

**Cut-off agents.** An Agent call that returns an API error (`HTTP 429 You've hit your
session limit`) in place of a report is a **cut-off**: the child and everything below it
stop where they are, context, worktree and claimed ticket intact (INFRA-28's run 1,
2026-10-20). The driver's turn is the only one a `SendMessage` reply reaches, so only the
driver resumes an agent, and only a story orchestrator. First the **stop sweep**:
`ListAgents`, then `TaskStop` on every agent id the driver did not itself spawn (the
orchestrators' runners, implementers, reviewers and mergers), since a child whose parent's
turn was cut off is owned by no one else and stays listed as running however quiet it is
(that run's implementer, "quiet for over 30 minutes"). Then one line to the same agent id,
`resume: re-read the story and its tickets from the beads and carry on`. The beads and notes
are the truth: a hand-written state summary (what that run sent) and a respawn both lose
what the agent still holds.

Every other agent is replaced, never resumed: to its orchestrator a cut-off child is a
`failed: cut off by <error>` report, and the next pass gives the work a fresh subagent,
same tier, same worktree, as a child that needs another pass gets one. A cut-off
is no verdict on the ticket: it rejoins the frontier with its failure count unchanged. Its
claim outlives the runner, and `bd ready` excludes an `in_progress` ticket, so the story
orchestrator `bd -C <owner> unclaim <ticket-id>`s it before the next frontier read. The
fresh runner's implementer resets the worktree onto the integration branch tip as its brief
says, so what a cut-off implementer left unmerged on `ticket/<slug>` is lost and the ticket
starts over; what reached the integration branch stays.

## Scratch space

**Worktrees.** Spawn each implementer with the Agent tool's `isolation: "worktree"` (a
fix-up implementer is the exception: it is spawned without `isolation`, into the worktree
and branch the first implementer reported, and reaches it with `git -C <path>`). The
harness creates the worktree under `.claude/worktrees/agent-<id>/` on a branch named
`worktree-agent-<id>`, registers it with the sandbox, and makes it the subagent's real
working directory, so the brief carries no paths and the subagent runs plain commands with
no `cd`. The harness removes it again if the subagent changed nothing.

Fall back to a hand-rolled `git worktree add .worktrees/<ticket-slug> -b ticket/<ticket-slug>`
only when `isolation` is unavailable. On that route the brief gives the subagent its absolute
worktree path, and the subagent reaches it with `git -C <path>` and absolute file paths.
Removing a worktree keeps its `ticket/<ticket-slug>` branch, so on a later run `-b` fails
with "branch already exists": run `git worktree prune`, then re-add it without `-b`
(`git worktree add .worktrees/<ticket-slug> ticket/<ticket-slug>`).

Either way the worktree starts on the wrong base: the harness branches from
`origin/<default-branch>` (unless the repo sets `worktree.baseRef: "head"`), and a
hand-rolled one from whatever was checked out. The subagent's first act is to reset onto the
integration branch tip.

**Literal paths.** Inside a harness worktree, a guard checks each `git` and `bd` call
against the worktree and refuses one whose path comes from a shell variable or sits in a
construct it cannot parse (seen in INFRA-26's `chezmoi-0jp.22` fixture run). Spell every
path out literally, one plain command per Bash call.

**Exploration notes** go in `.spec-notes/<epic-id>/`, repo-relative, written by
`/dev:implement-story`'s exploration subagent and shared by every later subagent of that story.
The directory is that skill's alone: the story cut's orientation is the story bead's design
field, not a file.

**Gitignore.** Before the first ticket, `.gitignore` covers `/.claude/worktrees/`,
`/.worktrees/`, `/.spec-notes/` and `/.tmp/` (the TMPDIR rule below, read at the root of a
worktree too, since a worktree checks out the same `.gitignore`). Add what is missing and
commit that first, so no ticket branch carries scratch files. The entries and their commit
are the story orchestrator's alone (`/dev:implement-story`'s Gitignore step): no earlier stage
adds a line, and an edit of the user's beside them is never committed.

**TMPDIR.** Every worktree brief (implementer, fix-up implementer, merger) starts with
`mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp`, `<worktree>` the absolute
worktree path spelled out literally: on the hand-rolled route the path the brief gives, on
the harness route the one `pwd` prints, since that brief carries none and the worktree
guard refuses an `export TMPDIR=` whose value holds a variable (`$PWD`) as it refuses one
in a `git` call (Literal paths). `.tmp/` is gitignored (`/.tmp/`, the Gitignore rule) and
sits inside the worktree, so the sandbox lets the agent write there whatever temp
directory it inherited, as long as the worktree is where the Worktrees rule puts it, in
the session's repo or under `~/src`. It prevents two failures from INFRA-29's runs (2026-10-23), whose
worktree agents inherited the macOS default temp directory, which the sandbox denies:
`mktemp -d` failing with `mkdtemp failed on /var/folders/.../T/...: Operation not
permitted` (the root of the `rm -rf` incident, chezmoi-cyc), and a heredoc or here-string
failing with `cannot create temp file for here document`, which kills any script that uses
one (`scripts/lint-skill-docs.sh` did, twice), since bash 3.2 writes a heredoc to a file
under `TMPDIR`. What a worktree agent inherits varies: the worktree probe of 2026-10-23
saw the sandbox's `/tmp/claude-502` there, and its heredocs passed with and without the
line, which makes the agent independent of the draw. Two riders, from that probe. Shell
state does not survive a Bash call (the next call saw the old `TMPDIR` again), so the
`export` is repeated at the head of every call that runs `mktemp`, a heredoc or a script:
`export TMPDIR=<worktree>/.tmp; <command>`. And macOS `mktemp` (`/usr/bin/mktemp` on
Darwin 27, whatever its manual says of `-t`) ignores `TMPDIR` altogether, with or without
`-t`, and uses the user temp directory under `/var/folders`, so `mktemp -d` always takes
an explicit template under the directory, `mktemp -d <worktree>/.tmp/<name>.XXXXXX` (the
bare form failed under the export, the template form passed;
`scripts/fixture-test-lib.sh`'s `scratch_dir` is the same form).

**Diff two files.** To compare a file with a git object, write the other side under
`<worktree>/.tmp` (`git show <rev>:<path> ><worktree>/.tmp/<name>`) and diff the two
paths. Under the sandbox `diff <(...)` fails with `diff: /dev/fd/N: Operation not
permitted` while `cat <(...)` passes, and INFRA-30's run lost 38 comparisons that way.

**Python's cache line.** Under the sandbox a `python3` call prints
`python3: error: couldn't create cache file '/var/folders/.../xcrun_db-...'
(errno=Operation not permitted)` on stderr and still runs. Read stdout past that line
rather than treating the call as failed, or reach for `jq` when the input is JSON.

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
resolved, as the TMPDIR line spells `<worktree>`: never `$CLAUDE_PLUGIN_ROOT`, never a `~/`
path. A subagent's Bash has no such variable (unset in this rule's own ticket run,
2026-10-24) and the worktree guard refuses a path
built from one (Literal paths), so a brief that names a variable sends its subagent to a
doc it cannot open. Every pointer a brief carries, "the rules doc's TMPDIR rule" or "the
rules doc's Idle rule", names that doc by the same absolute path.

**Nothing else goes under `/tmp` or the inherited `$TMPDIR`.** A subagent's file-edit
permissions are scoped to the session's working directories, so a worktree there
`git worktree add`s fine and then every Write inside it is denied. It looks like a
permissions bug on the path, not a location mistake. The same goes for a file handed to a command that runs with the sandbox disabled
(`gh pr edit --body-file`): the sandboxed and unsandboxed runs see
different `$TMPDIR`s, so the file is written under `.spec-notes/` or the command fails with
"no such file or directory" (seen in INFRA-28's PR #5).

**Recursive deletes.** The plugin's PreToolUse hook `<plugin root>/hooks/guard-rm.sh` refuses
an `rm -r` on a variable not guarded as `"${x:?}"` or on a `/*` target before it runs, in
every repo and subagent that has `jq`, so a brief carries no ban of its own (chezmoi-cyc).

## Shell commands

For context around a match, or any `{m,n}` repeat, use `command grep`, not `grep`.

This section binds every session and subagent, orchestrating or not. Never prefix a command
with `cd <repo> && …`: the Bash tool already starts in the repo root, and permission rules
are matched against each part of a compound command separately, so the redundant `cd` is
the one part no allowlist covers and it costs a prompt on an otherwise allowed command. To
act on another directory, use the flag the command gives (`git -C <dir>`, `bd -C <dir>`,
`cargo --manifest-path`, `make -C <dir>`) or an absolute path, rather than moving the shell.
The shell's `grep` is Claude Code's bundled ugrep, which fails a wide bounded repeat with
"exceeds complexity limits"; `grep -n` piped to `cut` also works.

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
Only blocking rounds count toward a ticket's three-round limit: a round that reports every
acceptance criterion met plus three wording nits is clean, and the ticket goes to the
merger after one fix-up. Before this rule a round was clean only with no finding of either
kind (INFRA-29's runs, 2026-10-22 to 2026-10-23): `chezmoi-9v4.1.5` failed twice on rounds
that reported every criterion met plus four, then one, wording findings, costing two runner
restarts and a fourth driver run, and `chezmoi-9v4.1.1` took seven Fable rounds.

## Frontier

The **frontier** is the set of tickets an orchestrator may start now. Work only the frontier.
A ticket is on it when all of these hold:

- it is open and unclaimed, and `bd ready` in its owner repo lists it (`bd -C <owner> ready
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
above), so a ticket left claimed is off every later run's frontier until someone unclaims it
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
