# Harness mechanics

How an agent behaves inside this harness (Claude Code): how it waits, what it runs in the
foreground, how it commits, where scratch files go and what to do when an agent is cut off.
These are mechanics, not the orchestration model: the model, the review loop and the frontier
are in `orchestration.md`, and a brief that sends a subagent to commit or run Bash points
at this doc for them. The working-directory preflight stays in `orchestration.md`, where the skills that
run it pin it. Terms are those of `GLOSSARY.md` in the plugin repo.

**Waiting.** An orchestrator waits for its subagent's report by ending its turn.
An Agent call returns at once in this harness ("Async agent launched successfully"),
whichever way `run_in_background` is written. `run_in_background` is a JSON boolean, so
the string `"false"` is truthy and launches in the background, which is how every call in
INFRA-29's run 2 was written (2026-10-23, Claude Code 2.1.306); the epic orchestrator's call that
omitted the field launched async as well; and a ticket orchestrator of that run reported that
the Agent tool it saw had no `run_in_background` parameter at all. So on 2.1.306 the field
is absent for a nested agent, and a boolean `false` there has nothing to switch; whether a
top-level session's boolean `false` is honoured was not tested, and nothing here depends
on it. There is no foreground spawn. A child's report reaches its parent only as
the Agent tool's completion notification, and only while the parent is still waiting on
work it spawned; so after spawning, the orchestrator ends its turn, the notification
resumes it with the report, and the epic orchestrator never has to relay a report by `SendMessage`.
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

**Idle rule.** Every subagent below the epic orchestrator runs Bash in the foreground only (`timeout`
up to 600000 ms) and never starts a background Bash call or a `Monitor` on a bead; the
ticket orchestrator's lock wait is no exception. The harness notifies a parent of a child's turn ending
only when nothing is live below the child. A turn that ends with an Agent child mid-turn
keeps the parent waiting, which is how a nested orchestrator waits (above); a turn that
ends with a background Bash call or a `Monitor` still running counts as idle, not live.
The parent is then resumed with that interim notification as the child's report, the
parent is marked finished when the parent's own turn ends, and the child's real report,
once the background call completes, escapes to the top-level session (the probe of
2026-10-23: a haiku parent spawned a haiku child that ran `sleep` in a background Bash call
and ended its turn; the parent was resumed with the interim notification and listed as
finished, and the child's final line went to the top-level session). A `Monitor` is that
same background call behind a filter, so it is no better. Nor is a call left at the Bash
tool's 120-second default: the harness moves one that runs longer to the background, the
same idle state, so every run of the check command (`make check`, the Check command rule
in `orchestration.md`) and any other long lint or test run passes `timeout: 600000` on its
Bash call (INFRA-30's run: two `make lint` calls
were backgrounded that way, and one agent went looking for its own process with `ps`).
This is the mechanism behind the no-polling rule above, and why INFRA-29's until-loops
and Monitors woke agents with stale state. The one shell wait is a ticket orchestrator's wait on the owner checkout's lock (the
ticket orchestrator brief's step 4): a single foreground Bash call running an `until` loop over
`<owner>/.git/index.lock` and `MERGE_HEAD`, with the call's `timeout` as the five-minute
bound, so it returns when the lock clears and is killed when it does not (chezmoi-sn1's
check, 2026-10-22, saw the background form end the ticket orchestrator's turn with nothing reported).
The Bash tool's text says foreground `sleep` is blocked and points at `Monitor`; the same
check ran the foreground loop unblocked in a session and in a subagent alike, and the
observed run wins.

**Commits.** A commit a hook rejects (commit-msg or pre-commit) is fixed and retried
before any other `git` operation, and a branch is merged only onto a clean tree:
`git status --porcelain --untracked-files=no` prints nothing. `git merge` carries
uncommitted changes through when they touch no file the merge does, so a skipped retry
goes unnoticed (INFRA-28's run 1, 2026-10-20: an implementer whose subject failed the
72-character limit merged `feat/infra-28` over its uncommitted fixes and committed them
after the merge). A message with a trailer paragraph (`Bead:`, `Refs:`) is written whole,
trailers included, to `<worktree>/.tmp/commit-msg` with the Write tool and committed with
`git -C <worktree> commit -F <worktree>/.tmp/commit-msg`, a form the worktree guard accepts;
a second `-m $'...'` for the trailers is refused as "git in a form too complex to verify"
and costs a retry (INFRA-35, 2026-10-27). Every brief to an agent that commits or merges
(implementer, fix-up included, ticket orchestrator, story orchestrator) names this rule.

**Cut-off agents.** An Agent call that returns an API error (`HTTP 429 You've hit your
session limit`) in place of a report is a **cut-off**: the child and everything below it
stop where they are, context, worktree and claimed ticket intact (INFRA-28's run 1,
2026-10-20). The epic orchestrator's turn is the only one a `SendMessage` reply reaches, so only the
epic orchestrator resumes an agent, and only a story orchestrator. First the **stop sweep**:
`ListAgents`, then `TaskStop` on every agent id the epic orchestrator did not itself spawn (the
orchestrators' ticket orchestrators, implementers and reviewers), since a child whose parent's
turn was cut off is owned by no one else and stays listed as running however quiet it is
(that run's implementer, "quiet for over 30 minutes"). Then one line to the same agent id,
`resume: re-read the story and its tickets from the beads and carry on`. The beads and notes
are the truth: a hand-written state summary (what that run sent) and a respawn both lose
what the agent still holds. A story orchestrator missing from `ListAgents` with no
notification is probed with that same line, and one whose reply says the user stopped it
is the replaced case: its work is cancelled, and the `/dev:implement-spec` the user types
spawns a fresh orchestrator that re-reads the beads (INFRA-30's run, 2026-10-24).

Every other agent is replaced, never resumed: to its orchestrator a cut-off child is a
`failed: cut off by <error>` report, and the next pass gives the work a fresh subagent,
same tier, same worktree, as a child that needs another pass gets one. A cut-off
is no verdict on the ticket: it rejoins the frontier with its failure count unchanged. Its
claim outlives the orchestrator, and `bd ready` excludes an `in_progress` ticket, so the story
orchestrator `bd -C <owner> unclaim <ticket-id>`s it before the next frontier read. The
fresh ticket orchestrator's implementer resets the worktree onto the integration branch tip as its brief
says, so what a cut-off implementer left unmerged on `ticket/<slug>` is lost and the ticket
starts over; what reached the integration branch stays.

## Scratch space

**Worktrees.** Spawn each implementer with the Agent tool's `isolation: "worktree"` (an
implementer on a fix-up or on a merge-conflict resolution is the exception: it is spawned
without `isolation`, into the worktree and branch the first implementer reported, and reaches
it with `git -C <path>`). The
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

**TMPDIR.** Every worktree brief (implementer, fix-up included) starts with
`mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp`, `<worktree>` the absolute
worktree path spelled out literally: on the hand-rolled route the path the brief gives, on
the harness route the one `pwd` prints, since that brief carries none and the worktree
guard refuses an `export TMPDIR=` whose value holds a variable (`$PWD`) as it refuses one
in a `git` call (Literal paths). `.tmp/` is gitignored (`/.tmp/`, the Gitignore rule in `orchestration.md`) and
sits inside the worktree, so the sandbox lets the agent write there whatever temp
directory it inherited, as long as the worktree is where the Worktrees rule puts it, in
the session's repo or under `~/src`. It prevents two failures from INFRA-29's runs (2026-10-23), whose
worktree agents inherited the macOS default temp directory, which the sandbox denies:
`mktemp -d` failing with `mkdtemp failed on /var/folders/.../T/...: Operation not
permitted` (the root of the `rm -rf` incident, chezmoi-cyc), and a heredoc or here-string
failing with `cannot create temp file for here document`, which breaks any script that uses
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
`scripts/fixture-test-lib.sh`'s `fx_scratch_dir` is the same form).

**Diff two files.** To compare a file with a git object, write the other side under
`<worktree>/.tmp` (`git show <rev>:<path> ><worktree>/.tmp/<name>`) and diff the two
paths. Under the sandbox `diff <(...)` fails with `diff: /dev/fd/N: Operation not
permitted` while `cat <(...)` passes, and INFRA-30's run lost 38 comparisons that way.

**Python's cache line.** Under the sandbox a `python3` call prints
`python3: error: couldn't create cache file '/var/folders/.../xcrun_db-...'
(errno=Operation not permitted)` on stderr and still runs. Read stdout past that line
rather than treating the call as failed, or reach for `jq` when the input is JSON.

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
