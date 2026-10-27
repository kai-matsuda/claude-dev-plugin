commit 7b8adc286b2f20f29837c95999fefa17f283efee
Author: Kai Matsuda <matsudaskai@gmail.com>
Date:   Mon Oct 26 01:58:14 2026 -0400

    docs(agents): move the harness mechanics out of the rules doc
    
    Bead: dev-9k5.1.2
    Refs: INFRA-33
    Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
    Claude-Session: https://claude.ai/code/session_0177D7iX5a5m5SZrjpKWcv2H

diff --git a/.claude-plugin/plugin.json b/.claude-plugin/plugin.json
index 3c4df1d..49df609 100644
--- a/.claude-plugin/plugin.json
+++ b/.claude-plugin/plugin.json
@@ -1,7 +1,7 @@
 {
   "name": "dev",
-  "version": "0.2.19",
-  "description": "A Jira + beads feature workflow for Claude Code: spec, story cut, ticket cut, AFK implementation through story orchestrators and ticket runners, review, PR, retro and triage.",
+  "version": "0.2.20",
+  "description": "A Jira + beads feature workflow for Claude Code: spec, story cut, ticket cut, AFK implementation through story and ticket orchestrators, review, PR, retro and triage.",
   "author": {
     "name": "Kai Matsuda",
     "url": "https://github.com/vangogh500"
diff --git a/docs/agents/harness.md b/docs/agents/harness.md
new file mode 100644
index 0000000..78523ac
--- /dev/null
+++ b/docs/agents/harness.md
@@ -0,0 +1,183 @@
+# Harness mechanics
+
+How an agent behaves inside this harness (Claude Code): how it waits, what it runs in the
+foreground, how it commits, where scratch files go and what to do when an agent is cut off.
+These are mechanics, not the orchestration model: the model, the review loop and the frontier
+are in `orchestration.md`, and every brief that sends a subagent to commit or run Bash cites
+this doc. The working-directory preflight stays in `orchestration.md`, where the skills that
+run it pin it. Terms are those of `GLOSSARY.md` in the plugin repo.
+
+**Waiting.** An orchestrator waits for its subagent's report by ending its turn.
+An Agent call returns at once in this harness ("Async agent launched successfully"),
+whichever way `run_in_background` is written. `run_in_background` is a JSON boolean, so
+the string `"false"` is truthy and launches in the background, which is how every call in
+INFRA-29's run 2 was written (2026-10-23, Claude Code 2.1.306); the driver's call that
+omitted the field launched async as well; and a ticket runner of that run reported that
+the Agent tool it saw had no `run_in_background` parameter at all. So on 2.1.306 the field
+is absent for a nested agent, and a boolean `false` there has nothing to switch; whether a
+top-level session's boolean `false` is honoured was not tested, and nothing here depends
+on it. There is no foreground spawn. A child's report reaches its parent only as
+the Agent tool's completion notification, and only while the parent is still waiting on
+work it spawned; so after spawning, the orchestrator ends its turn, the notification
+resumes it with the report, and the driver never has to relay a report by `SendMessage`.
+A batch is the same: spawn every call in one message, end the turn, and act on each
+report as its notification arrives. An orchestrator never polls: not in a Bash loop,
+foreground or background, on `bd show` of the ticket's status, on `sleep` or on the
+process list, and not with a `Monitor` on a bead, which is a background call behind a
+filter (the Idle rule).
+`pgrep` cannot list processes in the sandbox (`sysmond service not found`,
+`Cannot get process list`), so a wait loop built on it exits at once and reports done over
+a child still running; a `bd show` loop holds a shell for as long as the child runs and
+tells the orchestrator nothing the report will not (INFRA-28's run 1, 2026-10-20: 21 of 45
+background shells were killed, one printing the same two `in_progress` tickets for an hour).
+
+**Idle rule.** Every subagent below the driver runs Bash in the foreground only (`timeout`
+up to 600000 ms) and never starts a background Bash call or a `Monitor` on a bead; the
+merger's lock wait is no exception. The harness notifies a parent of a child's turn ending
+only when nothing is live below the child. A turn that ends with an Agent child mid-turn
+keeps the parent waiting, which is how a nested orchestrator waits (above); a turn that
+ends with a background Bash call or a `Monitor` still running counts as idle, not live.
+The parent is then resumed with that interim notification as the child's report, the
+parent is marked finished when the parent's own turn ends, and the child's real report,
+once the background call completes, escapes to the top-level session (the probe of
+2026-10-23: a haiku parent spawned a haiku child that ran `sleep` in a background Bash call
+and ended its turn; the parent was resumed with the interim notification and listed as
+finished, and the child's final line went to the top-level session). A `Monitor` is that
+same background call behind a filter, so it is no better. Nor is a call left at the Bash
+tool's 120-second default: the harness moves one that runs longer to the background, the
+same idle state, so every lint or test run (`make lint`, `make ci`, `make fixtures`,
+`scripts/test-*.sh` or the owner repo's own; these are the story's checks, the Check gate
+rule in `orchestration.md`) passes `timeout: 600000` on its Bash call (INFRA-30's run: two `make lint` calls
+were backgrounded that way, and one agent went looking for its own process with `ps`).
+This is the mechanism behind the no-polling rule above, and why INFRA-29's until-loops
+and Monitors woke agents with stale state. The one shell wait is a merger's wait on the owner checkout's lock (the
+ticket runner brief's step 4): a single foreground Bash call running an `until` loop over
+`<owner>/.git/index.lock` and `MERGE_HEAD`, with the call's `timeout` as the five-minute
+bound, so it returns when the lock clears and is killed when it does not (chezmoi-sn1's
+check, 2026-10-22, saw the background form end the merger's turn with nothing reported).
+The Bash tool's text says foreground `sleep` is blocked and points at `Monitor`; the same
+check ran the foreground loop unblocked in a session and in a subagent alike, and the
+observed run wins.
+
+**Commits.** A commit a hook rejects (commit-msg or pre-commit) is fixed and retried
+before any other `git` operation, and a branch is merged only onto a clean tree:
+`git status --porcelain --untracked-files=no` prints nothing. `git merge` carries
+uncommitted changes through when they touch no file the merge does, so a skipped retry
+goes unnoticed (INFRA-28's run 1, 2026-10-20: an implementer whose subject failed the
+72-character limit merged `feat/infra-28` over its uncommitted fixes and committed them
+after the merge). Every brief to an agent that commits or merges (implementer, fix-up
+implementer, merger) names this rule.
+
+**Cut-off agents.** An Agent call that returns an API error (`HTTP 429 You've hit your
+session limit`) in place of a report is a **cut-off**: the child and everything below it
+stop where they are, context, worktree and claimed ticket intact (INFRA-28's run 1,
+2026-10-20). The driver's turn is the only one a `SendMessage` reply reaches, so only the
+driver resumes an agent, and only a story orchestrator. First the **stop sweep**:
+`ListAgents`, then `TaskStop` on every agent id the driver did not itself spawn (the
+orchestrators' runners, implementers, reviewers and mergers), since a child whose parent's
+turn was cut off is owned by no one else and stays listed as running however quiet it is
+(that run's implementer, "quiet for over 30 minutes"). Then one line to the same agent id,
+`resume: re-read the story and its tickets from the beads and carry on`. The beads and notes
+are the truth: a hand-written state summary (what that run sent) and a respawn both lose
+what the agent still holds. A story orchestrator missing from `ListAgents` with no
+notification is probed with that same line, and one whose reply says the user stopped it
+is the replaced case: its work is cancelled, and the `/dev:implement-spec` the user types
+spawns a fresh orchestrator that re-reads the beads (INFRA-30's run, 2026-10-24).
+
+Every other agent is replaced, never resumed: to its orchestrator a cut-off child is a
+`failed: cut off by <error>` report, and the next pass gives the work a fresh subagent,
+same tier, same worktree, as a child that needs another pass gets one. A cut-off
+is no verdict on the ticket: it rejoins the frontier with its failure count unchanged. Its
+claim outlives the runner, and `bd ready` excludes an `in_progress` ticket, so the story
+orchestrator `bd -C <owner> unclaim <ticket-id>`s it before the next frontier read. The
+fresh runner's implementer resets the worktree onto the integration branch tip as its brief
+says, so what a cut-off implementer left unmerged on `ticket/<slug>` is lost and the ticket
+starts over; what reached the integration branch stays.
+
+## Scratch space
+
+**Worktrees.** Spawn each implementer with the Agent tool's `isolation: "worktree"` (a
+fix-up implementer is the exception: it is spawned without `isolation`, into the worktree
+and branch the first implementer reported, and reaches it with `git -C <path>`). The
+harness creates the worktree under `.claude/worktrees/agent-<id>/` on a branch named
+`worktree-agent-<id>`, registers it with the sandbox, and makes it the subagent's real
+working directory, so the brief carries no paths and the subagent runs plain commands with
+no `cd`. The harness removes it again if the subagent changed nothing.
+
+Fall back to a hand-rolled `git worktree add .worktrees/<ticket-slug> -b ticket/<ticket-slug>`
+only when `isolation` is unavailable. On that route the brief gives the subagent its absolute
+worktree path, and the subagent reaches it with `git -C <path>` and absolute file paths.
+Removing a worktree keeps its `ticket/<ticket-slug>` branch, so on a later run `-b` fails
+with "branch already exists": run `git worktree prune`, then re-add it without `-b`
+(`git worktree add .worktrees/<ticket-slug> ticket/<ticket-slug>`).
+
+Either way the worktree starts on the wrong base: the harness branches from
+`origin/<default-branch>` (unless the repo sets `worktree.baseRef: "head"`), and a
+hand-rolled one from whatever was checked out. The subagent's first act is to reset onto the
+integration branch tip.
+
+**Literal paths.** Inside a harness worktree, a guard checks each `git` and `bd` call
+against the worktree and refuses one whose path comes from a shell variable or sits in a
+construct it cannot parse (seen in INFRA-26's `chezmoi-0jp.22` fixture run). Spell every
+path out literally, one plain command per Bash call.
+
+**TMPDIR.** Every worktree brief (implementer, fix-up implementer, merger) starts with
+`mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp`, `<worktree>` the absolute
+worktree path spelled out literally: on the hand-rolled route the path the brief gives, on
+the harness route the one `pwd` prints, since that brief carries none and the worktree
+guard refuses an `export TMPDIR=` whose value holds a variable (`$PWD`) as it refuses one
+in a `git` call (Literal paths). `.tmp/` is gitignored (`/.tmp/`, the Gitignore rule in `orchestration.md`) and
+sits inside the worktree, so the sandbox lets the agent write there whatever temp
+directory it inherited, as long as the worktree is where the Worktrees rule puts it, in
+the session's repo or under `~/src`. It prevents two failures from INFRA-29's runs (2026-10-23), whose
+worktree agents inherited the macOS default temp directory, which the sandbox denies:
+`mktemp -d` failing with `mkdtemp failed on /var/folders/.../T/...: Operation not
+permitted` (the root of the `rm -rf` incident, chezmoi-cyc), and a heredoc or here-string
+failing with `cannot create temp file for here document`, which breaks any script that uses
+one (`scripts/lint-skill-docs.sh` did, twice), since bash 3.2 writes a heredoc to a file
+under `TMPDIR`. What a worktree agent inherits varies: the worktree probe of 2026-10-23
+saw the sandbox's `/tmp/claude-502` there, and its heredocs passed with and without the
+line, which makes the agent independent of the draw. Two riders, from that probe. Shell
+state does not survive a Bash call (the next call saw the old `TMPDIR` again), so the
+`export` is repeated at the head of every call that runs `mktemp`, a heredoc or a script:
+`export TMPDIR=<worktree>/.tmp; <command>`. And macOS `mktemp` (`/usr/bin/mktemp` on
+Darwin 27, whatever its manual says of `-t`) ignores `TMPDIR` altogether, with or without
+`-t`, and uses the user temp directory under `/var/folders`, so `mktemp -d` always takes
+an explicit template under the directory, `mktemp -d <worktree>/.tmp/<name>.XXXXXX` (the
+bare form failed under the export, the template form passed;
+`scripts/fixture-test-lib.sh`'s `fx_scratch_dir` is the same form).
+
+**Diff two files.** To compare a file with a git object, write the other side under
+`<worktree>/.tmp` (`git show <rev>:<path> ><worktree>/.tmp/<name>`) and diff the two
+paths. Under the sandbox `diff <(...)` fails with `diff: /dev/fd/N: Operation not
+permitted` while `cat <(...)` passes, and INFRA-30's run lost 38 comparisons that way.
+
+**Python's cache line.** Under the sandbox a `python3` call prints
+`python3: error: couldn't create cache file '/var/folders/.../xcrun_db-...'
+(errno=Operation not permitted)` on stderr and still runs. Read stdout past that line
+rather than treating the call as failed, or reach for `jq` when the input is JSON.
+
+**Nothing else goes under `/tmp` or the inherited `$TMPDIR`.** A subagent's file-edit
+permissions are scoped to the session's working directories, so a worktree there
+`git worktree add`s fine and then every Write inside it is denied. It looks like a
+permissions bug on the path, not a location mistake. The same goes for a file handed to a command that runs with the sandbox disabled
+(`gh pr edit --body-file`): the sandboxed and unsandboxed runs see
+different `$TMPDIR`s, so the file is written under `.spec-notes/` or the command fails with
+"no such file or directory" (seen in INFRA-28's PR #5).
+
+**Recursive deletes.** The plugin's PreToolUse hook `<plugin root>/hooks/guard-rm.sh` refuses
+an `rm -r` on a variable not guarded as `"${x:?}"` or on a `/*` target before it runs, in
+every repo and subagent that has `jq`, so a brief carries no ban of its own (chezmoi-cyc).
+
+## Shell commands
+
+For context around a match, or any `{m,n}` repeat, use `command grep`, not `grep`.
+
+This section binds every session and subagent, orchestrating or not. Never prefix a command
+with `cd <repo> && …`: the Bash tool already starts in the repo root, and permission rules
+are matched against each part of a compound command separately, so the redundant `cd` is
+the one part no allowlist covers and it costs a prompt on an otherwise allowed command. To
+act on another directory, use the flag the command gives (`git -C <dir>`, `bd -C <dir>`,
+`cargo --manifest-path`, `make -C <dir>`) or an absolute path, rather than moving the shell.
+The shell's `grep` is Claude Code's bundled ugrep, which fails a wide bounded repeat with
+"exceeds complexity limits"; `grep -n` piped to `cut` also works.
diff --git a/docs/agents/orchestration.md b/docs/agents/orchestration.md
index b854586..6f3807c 100644
--- a/docs/agents/orchestration.md
+++ b/docs/agents/orchestration.md
@@ -7,6 +7,9 @@ The cut skills, `/dev:spec-to-stories` and `/dev:spec-to-tickets`, read only the
 epic-level sentence and its "Working-directory preflight", and the ticket cut the Waiting
 rule for its cutter waves.
 
+The harness mechanics (waiting, the Idle rule, commits, cut-off agents, scratch space, shell
+commands) are in `harness.md`; only the working-directory preflight stays here.
+
 ## Orchestrator role
 
 The session running a skill is an **orchestrator**: the driver for `/dev:implement-spec`, the
@@ -38,67 +41,15 @@ Communication to and from subagents is sparse and goes through context pointers
 story, tickets, notes, previous commits). Every orchestrator waits the same way, the driver
 and a nested orchestrator (a story orchestrator or a ticket runner, which is itself a
 subagent) alike: it spawns, ends its turn and is resumed by each child's completion
-notification, since an Agent call returns at once in this harness (Waiting, below). A
+notification, since an Agent call returns at once in this harness (Waiting, in `harness.md`). A
 nested orchestrator never resumes a child with `SendMessage`: the reply lands in the
 top-level session, not in the orchestrator, whose turn is over (INFRA-27's run,
 2026-10-19; this doc read that run as "a background spawn returns at once, so spawn in the
 foreground", and no such spawn exists: ADR 0012 in the plugin repo). Only the driver
-resumes an agent, and only a cut-off story orchestrator (Cut-off agents, below). A child
+resumes an agent, and only a cut-off story orchestrator (Cut-off agents, in `harness.md`). A child
 that needs another pass gets a fresh subagent, same tier, same worktree, with the findings
 in its brief.
 
-**Waiting.** An orchestrator waits for its subagent's report by ending its turn.
-An Agent call returns at once in this harness ("Async agent launched successfully"),
-whichever way `run_in_background` is written. `run_in_background` is a JSON boolean, so
-the string `"false"` is truthy and launches in the background, which is how every call in
-INFRA-29's run 2 was written (2026-10-23, Claude Code 2.1.306); the driver's call that
-omitted the field launched async as well; and a ticket runner of that run reported that
-the Agent tool it saw had no `run_in_background` parameter at all. So on 2.1.306 the field
-is absent for a nested agent, and a boolean `false` there has nothing to switch; whether a
-top-level session's boolean `false` is honoured was not tested, and nothing here depends
-on it. There is no foreground spawn. A child's report reaches its parent only as
-the Agent tool's completion notification, and only while the parent is still waiting on
-work it spawned; so after spawning, the orchestrator ends its turn, the notification
-resumes it with the report, and the driver never has to relay a report by `SendMessage`.
-A batch is the same: spawn every call in one message, end the turn, and act on each
-report as its notification arrives. An orchestrator never polls: not in a Bash loop,
-foreground or background, on `bd show` of the ticket's status, on `sleep` or on the
-process list, and not with a `Monitor` on a bead, which is a background call behind a
-filter (the Idle rule).
-`pgrep` cannot list processes in the sandbox (`sysmond service not found`,
-`Cannot get process list`), so a wait loop built on it exits at once and reports done over
-a child still running; a `bd show` loop holds a shell for as long as the child runs and
-tells the orchestrator nothing the report will not (INFRA-28's run 1, 2026-10-20: 21 of 45
-background shells were killed, one printing the same two `in_progress` tickets for an hour).
-
-**Idle rule.** Every subagent below the driver runs Bash in the foreground only (`timeout`
-up to 600000 ms) and never starts a background Bash call or a `Monitor` on a bead; the
-merger's lock wait is no exception. The harness notifies a parent of a child's turn ending
-only when nothing is live below the child. A turn that ends with an Agent child mid-turn
-keeps the parent waiting, which is how a nested orchestrator waits (above); a turn that
-ends with a background Bash call or a `Monitor` still running counts as idle, not live.
-The parent is then resumed with that interim notification as the child's report, the
-parent is marked finished when the parent's own turn ends, and the child's real report,
-once the background call completes, escapes to the top-level session (the probe of
-2026-10-23: a haiku parent spawned a haiku child that ran `sleep` in a background Bash call
-and ended its turn; the parent was resumed with the interim notification and listed as
-finished, and the child's final line went to the top-level session). A `Monitor` is that
-same background call behind a filter, so it is no better. Nor is a call left at the Bash
-tool's 120-second default: the harness moves one that runs longer to the background, the
-same idle state, so every lint or test run (`make lint`, `make ci`, `make fixtures`,
-`scripts/test-*.sh` or the owner repo's own; these are the story's checks, the Check gate
-rule under Review below) passes `timeout: 600000` on its Bash call (INFRA-30's run: two `make lint` calls
-were backgrounded that way, and one agent went looking for its own process with `ps`).
-This is the mechanism behind the no-polling rule above, and why INFRA-29's until-loops
-and Monitors woke agents with stale state. The one shell wait is a merger's wait on the owner checkout's lock (the
-ticket runner brief's step 4): a single foreground Bash call running an `until` loop over
-`<owner>/.git/index.lock` and `MERGE_HEAD`, with the call's `timeout` as the five-minute
-bound, so it returns when the lock clears and is killed when it does not (chezmoi-sn1's
-check, 2026-10-22, saw the background form end the merger's turn with nothing reported).
-The Bash tool's text says foreground `sleep` is blocked and points at `Monitor`; the same
-check ran the foreground loop unblocked in a session and in a subagent alike, and the
-observed run wins.
-
 **Delivery.** The typed command is the authority for what it delivers. `/dev:implement-spec`
 and `/dev:implement-story` are typed to deliver a PR, so the commits, the push of the
 integration branch and the PR are what the user asked for, the "explicitly asked" of the
@@ -111,122 +62,26 @@ denied) ends the run with a `failed: push <command>: <error>` line, the merges s
 the local branch, and the next run's plain push is the retry (`git push --force` is
 denied in settings).
 
-**Commits.** A commit a hook rejects (commit-msg or pre-commit) is fixed and retried
-before any other `git` operation, and a branch is merged only onto a clean tree:
-`git status --porcelain --untracked-files=no` prints nothing. `git merge` carries
-uncommitted changes through when they touch no file the merge does, so a skipped retry
-goes unnoticed (INFRA-28's run 1, 2026-10-20: an implementer whose subject failed the
-72-character limit merged `feat/infra-28` over its uncommitted fixes and committed them
-after the merge). Every brief to an agent that commits or merges (implementer, fix-up
-implementer, merger) names this rule.
-
 **Subagent type.** A story orchestrator and a ticket runner are spawned with
 `subagent_type: "general-purpose"`, the type that carries the Agent tool; `Explore` and
 `Plan` do not, and a runner without it can spawn no one (INFRA-28's run 1, where
 `chezmoi-gfu.1.6`'s runner handed its seams to a reviewer instead). A subagent that finds it
 has no Agent tool reports `failed: no Agent tool` at once; the work is never done inline.
 
-**Cut-off agents.** An Agent call that returns an API error (`HTTP 429 You've hit your
-session limit`) in place of a report is a **cut-off**: the child and everything below it
-stop where they are, context, worktree and claimed ticket intact (INFRA-28's run 1,
-2026-10-20). The driver's turn is the only one a `SendMessage` reply reaches, so only the
-driver resumes an agent, and only a story orchestrator. First the **stop sweep**:
-`ListAgents`, then `TaskStop` on every agent id the driver did not itself spawn (the
-orchestrators' runners, implementers, reviewers and mergers), since a child whose parent's
-turn was cut off is owned by no one else and stays listed as running however quiet it is
-(that run's implementer, "quiet for over 30 minutes"). Then one line to the same agent id,
-`resume: re-read the story and its tickets from the beads and carry on`. The beads and notes
-are the truth: a hand-written state summary (what that run sent) and a respawn both lose
-what the agent still holds. A story orchestrator missing from `ListAgents` with no
-notification is probed with that same line, and one whose reply says the user stopped it
-is the replaced case: its work is cancelled, and the `/dev:implement-spec` the user types
-spawns a fresh orchestrator that re-reads the beads (INFRA-30's run, 2026-10-24).
-
-Every other agent is replaced, never resumed: to its orchestrator a cut-off child is a
-`failed: cut off by <error>` report, and the next pass gives the work a fresh subagent,
-same tier, same worktree, as a child that needs another pass gets one. A cut-off
-is no verdict on the ticket: it rejoins the frontier with its failure count unchanged. Its
-claim outlives the runner, and `bd ready` excludes an `in_progress` ticket, so the story
-orchestrator `bd -C <owner> unclaim <ticket-id>`s it before the next frontier read. The
-fresh runner's implementer resets the worktree onto the integration branch tip as its brief
-says, so what a cut-off implementer left unmerged on `ticket/<slug>` is lost and the ticket
-starts over; what reached the integration branch stays.
-
 ## Scratch space
 
-**Worktrees.** Spawn each implementer with the Agent tool's `isolation: "worktree"` (a
-fix-up implementer is the exception: it is spawned without `isolation`, into the worktree
-and branch the first implementer reported, and reaches it with `git -C <path>`). The
-harness creates the worktree under `.claude/worktrees/agent-<id>/` on a branch named
-`worktree-agent-<id>`, registers it with the sandbox, and makes it the subagent's real
-working directory, so the brief carries no paths and the subagent runs plain commands with
-no `cd`. The harness removes it again if the subagent changed nothing.
-
-Fall back to a hand-rolled `git worktree add .worktrees/<ticket-slug> -b ticket/<ticket-slug>`
-only when `isolation` is unavailable. On that route the brief gives the subagent its absolute
-worktree path, and the subagent reaches it with `git -C <path>` and absolute file paths.
-Removing a worktree keeps its `ticket/<ticket-slug>` branch, so on a later run `-b` fails
-with "branch already exists": run `git worktree prune`, then re-add it without `-b`
-(`git worktree add .worktrees/<ticket-slug> ticket/<ticket-slug>`).
-
-Either way the worktree starts on the wrong base: the harness branches from
-`origin/<default-branch>` (unless the repo sets `worktree.baseRef: "head"`), and a
-hand-rolled one from whatever was checked out. The subagent's first act is to reset onto the
-integration branch tip.
-
-**Literal paths.** Inside a harness worktree, a guard checks each `git` and `bd` call
-against the worktree and refuses one whose path comes from a shell variable or sits in a
-construct it cannot parse (seen in INFRA-26's `chezmoi-0jp.22` fixture run). Spell every
-path out literally, one plain command per Bash call.
-
 **Exploration notes** go in `.spec-notes/<epic-id>/`, repo-relative, written by
 `/dev:implement-story`'s exploration subagent and shared by every later subagent of that story.
 The directory is that skill's alone: the story cut's orientation is the story bead's design
 field, not a file.
 
 **Gitignore.** Before the first ticket, `.gitignore` covers `/.claude/worktrees/`,
-`/.worktrees/`, `/.spec-notes/` and `/.tmp/` (the TMPDIR rule below, read at the root of a
+`/.worktrees/`, `/.spec-notes/` and `/.tmp/` (the TMPDIR rule in `harness.md`, read at the root of a
 worktree too, since a worktree checks out the same `.gitignore`). Add what is missing and
 commit that first, so no ticket branch carries scratch files. The entries and their commit
 are the story orchestrator's alone (`/dev:implement-story`'s Gitignore step): no earlier stage
 adds a line, and an edit of the user's beside them is never committed.
 
-**TMPDIR.** Every worktree brief (implementer, fix-up implementer, merger) starts with
-`mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp`, `<worktree>` the absolute
-worktree path spelled out literally: on the hand-rolled route the path the brief gives, on
-the harness route the one `pwd` prints, since that brief carries none and the worktree
-guard refuses an `export TMPDIR=` whose value holds a variable (`$PWD`) as it refuses one
-in a `git` call (Literal paths). `.tmp/` is gitignored (`/.tmp/`, the Gitignore rule) and
-sits inside the worktree, so the sandbox lets the agent write there whatever temp
-directory it inherited, as long as the worktree is where the Worktrees rule puts it, in
-the session's repo or under `~/src`. It prevents two failures from INFRA-29's runs (2026-10-23), whose
-worktree agents inherited the macOS default temp directory, which the sandbox denies:
-`mktemp -d` failing with `mkdtemp failed on /var/folders/.../T/...: Operation not
-permitted` (the root of the `rm -rf` incident, chezmoi-cyc), and a heredoc or here-string
-failing with `cannot create temp file for here document`, which breaks any script that uses
-one (`scripts/lint-skill-docs.sh` did, twice), since bash 3.2 writes a heredoc to a file
-under `TMPDIR`. What a worktree agent inherits varies: the worktree probe of 2026-10-23
-saw the sandbox's `/tmp/claude-502` there, and its heredocs passed with and without the
-line, which makes the agent independent of the draw. Two riders, from that probe. Shell
-state does not survive a Bash call (the next call saw the old `TMPDIR` again), so the
-`export` is repeated at the head of every call that runs `mktemp`, a heredoc or a script:
-`export TMPDIR=<worktree>/.tmp; <command>`. And macOS `mktemp` (`/usr/bin/mktemp` on
-Darwin 27, whatever its manual says of `-t`) ignores `TMPDIR` altogether, with or without
-`-t`, and uses the user temp directory under `/var/folders`, so `mktemp -d` always takes
-an explicit template under the directory, `mktemp -d <worktree>/.tmp/<name>.XXXXXX` (the
-bare form failed under the export, the template form passed;
-`scripts/fixture-test-lib.sh`'s `fx_scratch_dir` is the same form).
-
-**Diff two files.** To compare a file with a git object, write the other side under
-`<worktree>/.tmp` (`git show <rev>:<path> ><worktree>/.tmp/<name>`) and diff the two
-paths. Under the sandbox `diff <(...)` fails with `diff: /dev/fd/N: Operation not
-permitted` while `cat <(...)` passes, and INFRA-30's run lost 38 comparisons that way.
-
-**Python's cache line.** Under the sandbox a `python3` call prints
-`python3: error: couldn't create cache file '/var/folders/.../xcrun_db-...'
-(errno=Operation not permitted)` on stderr and still runs. Read stdout past that line
-rather than treating the call as failed, or reach for `jq` when the input is JSON.
-
 **Plugin root.** These rules docs, the runbook (`docs/WORKFLOW.md`) and the hooks ship in
 the dev plugin, so every skill reaches them through the plugin root, `<plugin root>`, the
 directory the harness names in its plugin-root variable `CLAUDE_PLUGIN_ROOT`. A skill
@@ -243,35 +98,10 @@ spells the absolute rules-doc path literally in every brief,
 resolved, as the TMPDIR line spells `<worktree>`: never `$CLAUDE_PLUGIN_ROOT`, never a `~/`
 path. A subagent's Bash has no such variable (unset in this rule's own ticket run,
 2026-10-24) and the worktree guard refuses a path
-built from one (Literal paths), so a brief that names a variable sends its subagent to a
+built from one (Literal paths in `harness.md`), so a brief that names a variable sends its subagent to a
 doc it cannot open. Every pointer a brief carries, "the rules doc's TMPDIR rule" or "the
 rules doc's Idle rule", names that doc by the same absolute path.
 
-**Nothing else goes under `/tmp` or the inherited `$TMPDIR`.** A subagent's file-edit
-permissions are scoped to the session's working directories, so a worktree there
-`git worktree add`s fine and then every Write inside it is denied. It looks like a
-permissions bug on the path, not a location mistake. The same goes for a file handed to a command that runs with the sandbox disabled
-(`gh pr edit --body-file`): the sandboxed and unsandboxed runs see
-different `$TMPDIR`s, so the file is written under `.spec-notes/` or the command fails with
-"no such file or directory" (seen in INFRA-28's PR #5).
-
-**Recursive deletes.** The plugin's PreToolUse hook `<plugin root>/hooks/guard-rm.sh` refuses
-an `rm -r` on a variable not guarded as `"${x:?}"` or on a `/*` target before it runs, in
-every repo and subagent that has `jq`, so a brief carries no ban of its own (chezmoi-cyc).
-
-## Shell commands
-
-For context around a match, or any `{m,n}` repeat, use `command grep`, not `grep`.
-
-This section binds every session and subagent, orchestrating or not. Never prefix a command
-with `cd <repo> && …`: the Bash tool already starts in the repo root, and permission rules
-are matched against each part of a compound command separately, so the redundant `cd` is
-the one part no allowlist covers and it costs a prompt on an otherwise allowed command. To
-act on another directory, use the flag the command gives (`git -C <dir>`, `bd -C <dir>`,
-`cargo --manifest-path`, `make -C <dir>`) or an absolute path, rather than moving the shell.
-The shell's `grep` is Claude Code's bundled ugrep, which fails a wide bounded repeat with
-"exceeds complexity limits"; `grep -n` piped to `cut` also works.
-
 ## Complexity tier
 
 Each ticket carries a `complexity:low|medium|high` label that maps to an implementation model
@@ -360,7 +190,7 @@ A publish ticket, like every human gate ticket, is `ready-for-human`, so it is o
 (and under `--parent <story-id>`) as soon as its story's implementation tickets close.
 
 **Unclaim.** A claim outlives its runner and hides the ticket from `bd ready` (Cut-off agents
-above), so a ticket left claimed is off every later run's frontier until someone unclaims it
+in `harness.md`), so a ticket left claimed is off every later run's frontier until someone unclaims it
 (INFRA-27's run 1, 2026-10-20: `chezmoi-a0q.1.5` stayed `in_progress` and assigned after two
 failed runners, and the user ran `bd unclaim` by hand twice). So the story orchestrator
 `bd -C <owner> unclaim <id>`s every ticket whose runner returned without closing it, a
diff --git a/scripts/lint-skill-docs.sh b/scripts/lint-skill-docs.sh
index e65d0ea..0eeb617 100755
--- a/scripts/lint-skill-docs.sh
+++ b/scripts/lint-skill-docs.sh
@@ -566,30 +566,9 @@ done < <({ find "$docs" -type f -name '*.md' 2>/dev/null; find "$agents" "$skill
 
 # ---- 6. shared rules the skills point at ----
 if doc 6 "orchestration rules" "$agents/orchestration.md"; then
+lacks "a foreground spawn" 'spawns in the foreground|foreground spawn returns|has no notification to wait for'
 hasc "preflight section" '## Working-directory preflight'
 has "preflight remedy" '/add-dir <'
-# a runner waits on its subagent's report, never on a Bash poll loop; pgrep is dead in the sandbox (chezmoi-flq)
-hasc "waiting rule" '**Waiting.**'
-hasc "pgrep unusable in the sandbox" '`pgrep` cannot list processes in the sandbox'
-# an Agent call returns at once in this harness, so an orchestrator ends its turn after spawning
-# and the child's report arrives as the Agent tool's completion notification; run_in_background
-# is a JSON boolean the probe found ignored or absent for a nested agent; every subagent below
-# the driver runs Bash in the foreground only, since a child that ends a turn with background
-# work running counts as idle and its real report escapes to the top-level session (chezmoi-p4q)
-hasc "an Agent call returns at once" 'An Agent call returns at once'
-hasc "the completion notification carries the report" "the Agent tool's completion notification"
-hasc "a nested orchestrator ends its turn after spawning" 'ends its turn'
-hasc "run_in_background is a JSON boolean" '`run_in_background` is a JSON boolean'
-hasc "idle rule" '**Idle rule.**'
-hasc "Bash in the foreground only below the driver" 'in the foreground only'
-# the Bash tool backgrounds a call that outlives its 120 s default, which is the idle state the
-# rule forbids, so lint and test runs pass timeout: 600000 (dev-7k0, INFRA-30)
-hasc "the 120-second default backgrounds a longer call" '120-second default'
-hasc "lint and test runs carry the ten-minute timeout" 'timeout: 600000'
-lacks "a foreground spawn" 'spawns in the foreground|foreground spawn returns|has no notification to wait for'
-# the merger's wait on the owner checkout's lock is the one shell wait, a bounded foreground
-# until-loop, since a background call ends the merger's turn early (chezmoi-sn1, the idle rule)
-hasc "merger lock wait is the one shell wait" 'The one shell wait'
 # the typed implement command is the authority to push and open the PR, so the push is a step
 # of the run, with a failed: line when it is refused (ADR 0009, chezmoi-g61)
 hasc "delivery rule" '**Delivery.**'
@@ -606,17 +585,6 @@ hasc "frontier unclaim rule" '**Unclaim.**'
 hasc "frontier admits ready-for-agent only" 'it is labelled `ready-for-agent`'
 lacks "frontier keyed on ready-for-human alone" 'it is not labelled `ready-for-human`'
 hasc "finished story tolerates untriaged children" '`needs-triage` or `wontfix`'
-# every worktree brief starts by exporting a gitignored repo-relative TMPDIR, since the macOS
-# default is unwritable in the sandbox (mktemp -d, heredocs); the export is repeated per Bash
-# call and mktemp -d takes a template, since macOS mktemp ignores TMPDIR (chezmoi-3eg)
-hasc "TMPDIR rule" '**TMPDIR.**'
-# the rule's own paragraph (from its heading to the next blank line) carries the line, the two
-# failures and the gitignore fact, so a word used elsewhere in the doc cannot stand in
-para_has '**TMPDIR.**' "TMPDIR line" 'mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp'
-para_has '**TMPDIR.**' "the heredoc failure" 'heredoc'
-para_has '**TMPDIR.**' "the directory is gitignored" '`.tmp/` is gitignored'
-para_has '**TMPDIR.**' "export repeated per Bash call" 'export TMPDIR=<worktree>/.tmp; <command>'
-para_has '**TMPDIR.**' "mktemp -d takes a template under .tmp" 'mktemp -d <worktree>/.tmp/<name>.XXXXXX'
 para_has '**Gitignore.**' "/.tmp/ among the Gitignore rule's entries" '`/.tmp/`'
 # the rules docs ship in the plugin, so a brief reaches them through the plugin root: resolved
 # once per session from the harness's variable and spelled as an absolute path in every brief,
@@ -654,7 +622,52 @@ para_has '**Check gate.**' "three fix-ups per ticket at the ticket level" 'three
 para_has '**Check gate.**' "three per story at the story level" 'three per story at the story level'
 para_has '**Check gate.**' "either cause spends the budget" 'Either cause spends the budget'
 para_has '**Check gate.**' "a fourth failure is failed" 'a fourth failure is `failed`'
+fi
+if doc 6 "harness rules" "$agents/harness.md"; then
+# the mechanics live in the harness doc (dev-9k5.1.2): the rules above moved out of the
+# orchestration doc with it, and the doc points back at the preflight that stays there
+# a runner waits on its subagent's report, never on a Bash poll loop; pgrep is dead in the sandbox (chezmoi-flq)
+hasc "waiting rule" '**Waiting.**'
+hasc "pgrep unusable in the sandbox" '`pgrep` cannot list processes in the sandbox'
+# an Agent call returns at once in this harness, so an orchestrator ends its turn after spawning
+# and the child's report arrives as the Agent tool's completion notification; run_in_background
+# is a JSON boolean the probe found ignored or absent for a nested agent; every subagent below
+# the driver runs Bash in the foreground only, since a child that ends a turn with background
+# work running counts as idle and its real report escapes to the top-level session (chezmoi-p4q)
+hasc "an Agent call returns at once" 'An Agent call returns at once'
+hasc "the completion notification carries the report" "the Agent tool's completion notification"
+hasc "a nested orchestrator ends its turn after spawning" 'ends its turn'
+hasc "run_in_background is a JSON boolean" '`run_in_background` is a JSON boolean'
+hasc "idle rule" '**Idle rule.**'
+hasc "Bash in the foreground only below the driver" 'in the foreground only'
+# the Bash tool backgrounds a call that outlives its 120 s default, which is the idle state the
+# rule forbids, so lint and test runs pass timeout: 600000 (dev-7k0, INFRA-30)
+hasc "the 120-second default backgrounds a longer call" '120-second default'
+hasc "lint and test runs carry the ten-minute timeout" 'timeout: 600000'
+lacks "a foreground spawn" 'spawns in the foreground|foreground spawn returns|has no notification to wait for'
+# the merger's wait on the owner checkout's lock is the one shell wait, a bounded foreground
+# until-loop, since a background call ends the merger's turn early (chezmoi-sn1, the idle rule)
+hasc "merger lock wait is the one shell wait" 'The one shell wait'
+# every worktree brief starts by exporting a gitignored repo-relative TMPDIR, since the macOS
+# default is unwritable in the sandbox (mktemp -d, heredocs); the export is repeated per Bash
+# call and mktemp -d takes a template, since macOS mktemp ignores TMPDIR (chezmoi-3eg)
+hasc "TMPDIR rule" '**TMPDIR.**'
+# the rule's own paragraph (from its heading to the next blank line) carries the line, the two
+# failures and the gitignore fact, so a word used elsewhere in the doc cannot stand in
+para_has '**TMPDIR.**' "TMPDIR line" 'mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp'
+para_has '**TMPDIR.**' "the heredoc failure" 'heredoc'
+para_has '**TMPDIR.**' "the directory is gitignored" '`.tmp/` is gitignored'
+para_has '**TMPDIR.**' "export repeated per Bash call" 'export TMPDIR=<worktree>/.tmp; <command>'
+para_has '**TMPDIR.**' "mktemp -d takes a template under .tmp" 'mktemp -d <worktree>/.tmp/<name>.XXXXXX'
 para_has '**Idle rule.**' "the Idle rule names the checks" "these are the story's checks"
+# the cut-off rule with its stop sweep, and the commits rule with its clean-tree check
+hasc "cut-off rule" '**Cut-off agents.**'
+para_has '**Cut-off agents.**' "the stop sweep" 'First the **stop sweep**'
+hasc "commits rule" '**Commits.**'
+para_has '**Commits.**' "the clean-tree check" '`git status --porcelain --untracked-files=no` prints nothing'
+# the shell-commands discipline and the pointer back at the preflight kept in the rules doc
+hasc "the -C discipline" 'This section binds every session and subagent'
+hasc "the preflight stays in the rules doc" 'The working-directory preflight stays in `orchestration.md`'
 fi
 if doc 6 "tracker rules" "$agents/issue-tracker.md"; then
 # the one test of the session mode (ADR 0008), stated once, in the opening before any section
diff --git a/scripts/test-lint-skill-docs.sh b/scripts/test-lint-skill-docs.sh
index 515ae38..5023829 100755
--- a/scripts/test-lint-skill-docs.sh
+++ b/scripts/test-lint-skill-docs.sh
@@ -484,11 +484,11 @@ drop_line skills/story-to-tickets/SKILL.md 'Fetch the spec as the tracker doc'
 expect "story-to-tickets without its spec fetch fails" 1
 
 fresh
-drop_line docs/agents/orchestration.md '**Waiting.**'
-expect "orchestration doc without the waiting rule fails" 1
+drop_line docs/agents/harness.md '**Waiting.**'
+expect "harness doc without the waiting rule fails" 1
 
 fresh
-drop_line docs/agents/orchestration.md '`pgrep` cannot list processes in the sandbox'
+drop_line docs/agents/harness.md '`pgrep` cannot list processes in the sandbox'
 expect "orchestration doc without the pgrep warning fails" 1
 
 fresh
@@ -744,8 +744,8 @@ drop_line skills/implement-story/SKILL.md 'failed twice: <reason>; resume:'
 expect "implement-story without the resume pointer on a second failure fails" 1
 
 fresh
-drop_line docs/agents/orchestration.md 'The one shell wait'
-expect "orchestration doc without the merger's one shell wait fails" 1
+drop_line docs/agents/harness.md 'The one shell wait'
+expect "harness doc without the merger's one shell wait fails" 1
 
 fresh
 drop_line skills/implement-story/SKILL.md 'named `feat/<story-id>`, keyed or not'
@@ -922,21 +922,21 @@ expect "implement-story printing the worktrees: line unconditionally fails" 1
 # every worktree brief starts with the TMPDIR line: the rule in the orchestration doc with its
 # per-call export and its mktemp template, the line in each of the three briefs (chezmoi-3eg)
 fresh
-drop_line docs/agents/orchestration.md '**TMPDIR.**'
-expect "orchestration doc without the TMPDIR rule fails" 1
+drop_line docs/agents/harness.md '**TMPDIR.**'
+expect "harness doc without the TMPDIR rule fails" 1
 
 # the checks read the rule's own paragraph: a word kept elsewhere in the doc does not pass them
 for phrase in 'mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp' 'export TMPDIR=<worktree>/.tmp; <command>' \
   'mktemp -d <worktree>/.tmp/<name>.XXXXXX' '`.tmp/` is gitignored'; do
   fresh
-  drop_phrase docs/agents/orchestration.md "$phrase"
-  expect "orchestration doc without '$phrase' fails" 1
+  drop_phrase docs/agents/harness.md "$phrase"
+  expect "harness doc without '$phrase' fails" 1
 done
 
 fresh
-swap_phrase docs/agents/orchestration.md 'heredoc' 'here-document'
-printf '\nA heredoc elsewhere in the doc.\n' >> "$scratch/docs/agents/orchestration.md"
-expect "orchestration doc whose TMPDIR rule names no heredoc fails" 1
+swap_phrase docs/agents/harness.md 'heredoc' 'here-document'
+printf '\nA heredoc elsewhere in the doc.\n' >> "$scratch/docs/agents/harness.md"
+expect "harness doc whose TMPDIR rule names no heredoc fails" 1
 
 fresh
 drop_phrase docs/agents/orchestration.md ' and `/.tmp/`'
@@ -999,10 +999,35 @@ expect "orchestration doc saying a foreground spawn returns with the report fail
 
 for phrase in 'An Agent call returns at once' "the Agent tool's completion notification" 'ends its turn' 'in the foreground only' '`run_in_background` is a JSON boolean' '**Idle rule.**'; do
   fresh
-  drop_line docs/agents/orchestration.md "$phrase"
-  expect "orchestration doc without '$phrase' fails" 1
+  drop_line docs/agents/harness.md "$phrase"
+  expect "harness doc without '$phrase' fails" 1
 done
 
+# the cut-off and commits rules, and the idle rule's check-command list and timeout, moved to
+# the harness doc with the rest of the mechanics (dev-9k5.1.2)
+for phrase in '**Cut-off agents.**' 'First the **stop sweep**' '**Commits.**' '`git status --porcelain --untracked-files=no` prints nothing' \
+  '120-second default' 'timeout: 600000' "these are the story's checks"; do
+  fresh
+  drop_phrase docs/agents/harness.md "$phrase"
+  expect "harness doc without '$phrase' fails" 1
+done
+
+fresh
+drop_line docs/agents/harness.md 'This section binds every session and subagent'
+expect "harness doc without the -C discipline fails" 1
+
+fresh
+mv "$scratch/docs/agents/harness.md" "$scratch/docs/agents/harness-gone.md"
+expect "a missing harness doc fails naming it" 1 "missing document: $scratch/docs/agents/harness.md"
+
+fresh
+echo 'spawn each child with `run_in_background: false`' >> "$scratch/docs/agents/harness.md"
+expect "run_in_background: false seeded in the harness doc fails" 1
+
+fresh
+echo 'a nested orchestrator (one that is itself a subagent) spawns in the foreground' >> "$scratch/docs/agents/harness.md"
+expect "harness doc regaining the nested foreground spawn fails" 1
+
 fresh
 drop_line skills/implement-story/SKILL.md 'then end your turn: each runner'
 expect "implement-story whose frontier spawn does not end the turn fails" 1
@@ -1478,8 +1503,8 @@ for phrase in 'ticket level and the story level' 'lint first, then the test seam
   expect "orchestration doc's Check gate loop without '$phrase' fails" 1
 done
 fresh
-drop_phrase docs/agents/orchestration.md "these are the story's checks"
-expect "orchestration doc's Idle rule without the checks fails" 1
+drop_phrase docs/agents/harness.md "these are the story's checks"
+expect "harness doc's Idle rule without the checks fails" 1
 
 # the lint command's resolution in /implement-story step 3 and the runner brief's header: each
 # pin is proven by dropping its phrase (dev-cq0.1.2)
