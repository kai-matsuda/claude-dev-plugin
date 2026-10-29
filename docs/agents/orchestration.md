# Orchestration rules

How the agents that run a feature behave: one loop, run at three rows. Read by every
orchestrating skill: `/dev:implement-spec` (the **epic orchestrator**), `/dev:implement-story`
(the **story orchestrator**) and the **task orchestrator** brief it sends. A skill owns its
own steps; the rules here are the ones they share. Terms are those of `GLOSSARY.md` in the
plugin repo. The cut skills, `/dev:spec-to-stories` and `/dev:spec-to-tasks`, read only the
Orchestrator role's epic-level sentence and its "Working-directory preflight", and the task
cut also reads the Waiting rule in `harness.md` for its cutter waves.

The harness mechanics (waiting, the Idle rule, commits, cut-off agents, scratch space, shell
commands) are in `harness.md`, which also carries the Waiting rule the task cut reads; the
working-directory preflight is the one mechanic that stays here.

## The loop

Every row runs one loop: claim a unit, have a subagent build it, check it, review it, send a failure to a fresh fix-up or land it at the row above, and report one line.

The table gives each row its parameters; the loop's text, the two scoping rules and the six
trust rules below are shared by all three rows. The unit is a task, a story or an epic. The
human is not a row: a ready PR is theirs to merge.

| Row | Orchestrator | Builds | Checks | Review spec axis | Review standards axis | Reviewer and model | Fix-up | Lands by | Exits when | Budget |
|---|---|---|---|---|---|---|---|---|---|---|
| **Task** | task orchestrator | one implementer in a worktree | the check command | the task's body | the task diff | both axes, at the task's review model; none at `low` | an implementer by pointer brief, same worktree | merge onto the integration branch under the lock, after the stray-commit check | the checks green on the tip the review called clean | three fix-ups; three conflict resolutions per landing |
| **Story** | story orchestrator | task orchestrators in parallel over the frontier | the check command | the story's body | what entered since the last standards review: conflict resolutions, cross-task coherence and the story gate's fix-up commits | both axes, at the review model of the story's max tier | an implementer by pointer brief in a fix-up worktree | push, the PR staying a draft | the checks green on the tip the review called clean | three fix-ups |
| **Epic** | epic orchestrator | story orchestrators in parallel over the frontier | the check command as the forge runs it | the Jira Epic's spec | none, the axis is skipped | the spec axis only, at the review model of the epic's max tier | findings filed as `ready-for-agent` tasks under the story, that story re-run in add mode | the PR marked ready, the human merges, then `/dev:close-story` and `/dev:close-epic` | the checks green on the tip the review called clean | three per story |

**Landing a task.** The task orchestrator waits on the owner checkout's lock, runs the
stray-commit check and merges its task branch onto the integration branch. A `git merge`
that applies is a command, not an edit, so it does not break the never-implement rule. A
conflict goes to an implementer in the task's worktree, briefed to merge the integration
tip into the task branch; the task orchestrator then fast-forwards. The resolved tree is
a new tree, so it is checked, and it is not reviewed again at the task row: the story
row's standards axis sees it.
A landing takes at most three conflict resolutions, apart from the fix-up budget, since a
sibling that moved the integration branch is no failure of the task's. A landing runs from
the first lock wait until a merge applies, a refused fast-forward's conflict counting among
its three, and the fourth conflict ends the task `failed` with the merge aborted. A red on a
resolved tree goes to a fix-up, which spends the budget and starts a new landing, so the
budget bounds the landings and the cap the resolutions in each (dev-6qi).

**The epic row.** The epic orchestrator runs its review once every story reports
delivered, one PR at a time in its owner repo: the diff from the default branch to the
story's integration branch, the Jira Epic's spec as the spec axis. Every PR stays a draft
until its verdict is clean, then is marked ready, so the human's review comes after the
agents' loop. There the checks are green when the forge reports them green on the PR's tip,
and the delivered tip's check record is the PR's Evidence. On a blocking verdict or a red check the epic orchestrator cuts the findings itself into
`ready-for-agent` tasks under the story, one per blocking finding, a red check being one
finding that carries its check, its command and its log pointer, and re-runs that story's
orchestrator in add mode; three such fix-ups per story per invocation, red or blocking alike. A pending
check is neither: the PR stays a draft and a later invocation reads it again. Whatever its
verdict, an epic review's minors take no last fix-up at this row, since the epic orchestrator
implements nothing and its one fix-up is a task under the story, where no minor goes
(Review verdict): they go to the inbox as deferrals at once, the tracker doc's "capture a retro item", and on a clean
verdict the PR is marked ready once its checks are green.

## Orchestrator role

Five roles run a feature, named by their row: the **epic orchestrator**, the **story
orchestrator**, the **task orchestrator**, the **implementer** and the **reviewer**. The
plain word "orchestrator" in these rules means any of the three. A fix-up is a
brief shape of the implementer, not a role, and no agent merges for another: the task
orchestrator lands its own task.

- The **epic orchestrator** is the session running `/dev:implement-spec`: it spawns one story
  orchestrator per startable story, runs the epic row's review and reads the end state;
  nothing below it touches a task. It is the one agent a `SendMessage` reply reaches, so it
  alone resumes a cut-off story orchestrator (Cut-off agents, in `harness.md`), and its
  `TaskStop` reaches every agent of the run, since both belong to being the session.
- The **story orchestrator** implements one story: it works the story's frontier in its
  owner repo, one task orchestrator per task, runs the story row's gate and delivers the
  integration branch and its PR. Spawned per story by the epic orchestrator, or the session
  itself when `/dev:implement-story` is typed in the story's repo.
- The **task orchestrator** owns one task from claim to landing: its implementer, its
  gate and its fix-ups. It reports one line to its story orchestrator and is discarded, so no
  task's churn outlives it.
- The **implementer** builds a unit or fixes one, test-first at the story's test seams, and
  commits; it is the only role that edits a file.
- The **reviewer** runs the row's review and reports its findings and its verdict line.

An orchestrator never implements. Every change to source, tests, docs, or build files is
made by a subagent spawned at the tier's model; no change is small enough to be an
exception. A one-line fix is a `complexity:low` task's worth of work and gets a `haiku`
implementer, not an inline edit.

The orchestrator does: read the spec, story and tasks; spawn exploration, implementer and
reviewer subagents (or, at the story row, task orchestrators, which own those per task)
with the right `model:`; pass context pointers; track the frontier; run the check command and
write its check record; run `bd` operations (claim, split, note, close); create and report the
integration branch; and do repo plumbing that no task owns, namely the branch itself and
the `.gitignore` entries from Scratch space.

An **epic-level stage** (the story cut, the task cut and the `/dev:implement-spec` epic
orchestrator) writes to an owner repo only through its beads database (`bd -C <owner>`), never a file, a
`.gitignore` line or a commit, which belong to the story orchestrator on that story's
integration branch (ADR 0010 in the plugin repo). Reading an owner repo's code stays
allowed, which is what the working-directory preflight is for.

The orchestrator never: calls `Edit`/`Write` on anything a task could own; runs `tdd`; runs
tests in order to fix them; resolves a merge conflict by hand; patches a review finding
itself; or "finishes off" a subagent's work when it comes back incomplete. When a subagent
fails, bails, or leaves a gap, the answer is always another subagent (a fresh implementer, a
split, or a fix-up at the right tier) with a better brief. Opening a source file to change it
is the signal to spawn.

Communication to and from subagents is sparse and goes through context pointers (spec,
story, tasks, notes, previous commits). Every orchestrator waits the same way, the epic
orchestrator and a nested one (a story or task orchestrator, which is itself a subagent)
alike: it spawns, ends its turn and is resumed by each child's completion notification,
since an Agent call returns at once in this harness (Waiting, in `harness.md`). A nested
orchestrator never resumes a child with `SendMessage`: the reply lands in the top-level
session, not in the orchestrator, whose turn is over (INFRA-27's run, 2026-10-19; ADR 0012
in the plugin repo). Only the epic orchestrator resumes an agent, and only a cut-off story
orchestrator. A child that needs another pass gets a fresh subagent, same tier, same
worktree, with the findings in its brief.

**Delivery.** The typed command is the authority for what it delivers. `/dev:implement-spec`
and `/dev:implement-story` are typed to deliver a PR, so the commits, the push of the
integration branch and the PR are what the user asked for, the "explicitly asked" of the
Beads profile block in the user-level `CLAUDE.md`: the orchestrator pushes and opens the
PR as steps of the run (ADR 0009 in the plugin repo). A story orchestrator spawned by
the epic orchestrator has no user to ask in any case (INFRA-28's run 2, 2026-10-20: its
deliver step waited for an approval that could not come, and the feature needed a hand push
and a third run). A push or PR command that fails (no `origin`, no login, a prompt the user
denied) ends the run with a `failed: push <command>: <error>` line, the merges safe on
the local branch, and the next run's plain push is the retry (`git push --force` is
denied in settings).

**Subagent type.** A story orchestrator and a task orchestrator are spawned with
`subagent_type: "general-purpose"`, the type that carries the Agent tool; `Explore` and
`Plan` do not, and an orchestrator without it can spawn no one (INFRA-28's run 1, where
`chezmoi-gfu.1.6`'s orchestrator handed its seams to a reviewer instead). A subagent that
finds it has no Agent tool reports `failed: no Agent tool` at once; the work is never done
inline.

## Scoping rules

**Review scope.** One review tool, `mattpocock-skills:code-review` at every row, runs with
two axes, one tier up (Complexity tier).
The spec axis takes the row's own unit: the task's body (its acceptance criteria and the
story's test seams), the story's body, the Jira Epic's spec.
The standards axis reviews what entered since the last standards review: the task diff at
the task row; the conflict resolutions, the coherence across tasks and the story gate's own fix-up commits at the story row,
since each task's diff was reviewed at its own row; nothing at the epic row, where the axis
is skipped. So no line is read for standards twice (ADR 0014 in the plugin repo).

**Check scope.** Every tree is checked once green. A check is one run of the check command on
a tree, named by the tip's tree SHA, and a tree with a green check record (`exit=0`) counts as checked at
any row, whichever orchestrator wrote it, so a later agent spends no check run on it.
A red record skips nothing: a later pass or a resumed run checks that tree again, its record
replacing the red one, so a flaky or environmental red never sticks to its tree (dev-6qi). A
sibling landing, a conflict resolution or a fix-up's commit
changes the tree, so it is checked again;
after a red, a fix-up that commits nothing leaves it red-recorded, so it is checked again too
(Check gate).

## Trust rules

Six rules hold at every row:

1. The reviewer runs one tier of model above the implementer, since a same-tier reviewer shares its blind spots (Complexity tier).
2. A fix-up is a fresh implementer in the unit's worktree, never a message back to the agent that built the unit.
3. An implementer's own check runs never count: only a check record an orchestrator wrote does.
4. The stray-commit check runs before every merge and every push.
5. Only `ready-for-agent` tasks are claimed (Frontier).
6. The typed command authorises delivery (Delivery; ADR 0009 in the plugin repo).

The list is closed: a rule that wants to join needs an ADR.

## Scratch space

**Exploration notes** go in `.spec-notes/<epic-id>/`, repo-relative, written by
`/dev:implement-story`'s exploration subagent and shared by every later subagent of that story.
The directory is that skill's alone: the story cut's orientation is the story bead's design
field, not a file.

**Gitignore.** Before the first task, `.gitignore` covers `/.claude/worktrees/`,
`/.worktrees/`, `/.spec-notes/` and `/.tmp/` (the TMPDIR rule in `harness.md`, read at the root of a
worktree too, since a worktree checks out the same `.gitignore`). Add what is missing and
commit that first, so no task branch carries scratch files. The entries and their commit
are the story orchestrator's alone (`/dev:implement-story`'s Gitignore step): no earlier stage
adds a line, and an edit of the user's beside them is never committed.

**Plugin root.** These rules docs, the runbook (`docs/WORKFLOW.md`) and the hooks ship in
the dev plugin, so every skill reaches them through the plugin root, `<plugin root>`, the
directory the harness names in its plugin-root variable `CLAUDE_PLUGIN_ROOT`. A skill
resolves it once per session: its text writes `${CLAUDE_PLUGIN_ROOT}/docs/agents/<doc>.md`,
which the harness fills in with the absolute path when it loads the skill (as it fills in
`hooks/hooks.json`'s `guard-rm.sh` command). Bash never has the variable, in the
session or a subagent, so only if the text still shows it does the session fall back to the
`Base directory for this skill: <path>` line the Skill tool prints on loading a plugin skill:
that path is `<plugin root>/skills/<skill>`, so the root is two levels up (under
`claude --plugin-dir .` it is that checkout). With neither, it ends with
`failed: plugin root unresolved` rather than guessing a path. From then on the session
spells the absolute rules-doc path literally in every brief,
`<plugin root>/docs/agents/orchestration.md` with `<plugin root>` replaced by the path it
resolved, as the TMPDIR rule in `harness.md` spells `<worktree>`: never `$CLAUDE_PLUGIN_ROOT`, never a `~/`
path. A subagent's Bash has no such variable (unset in this rule's own task run,
2026-10-24) and the worktree guard refuses a path
built from one (Literal paths in `harness.md`), so a brief that names a variable sends its subagent to a
doc it cannot open. Every pointer a brief carries, "the harness doc's TMPDIR rule" or "the
harness doc's Idle rule", names that doc by its own absolute path, `<plugin root>/docs/agents/harness.md`.

## Complexity tier

Each task carries a `complexity:low|medium|high` label that maps to an implementation model
and a review model. The table and its rules are in `issue-tracker.md`, "Complexity labels";
the mapping is mechanical.

The reviewer is always one tier of model above the implementer (trust rule 1). Set `model:`
on every Agent call explicitly; never let it default to the orchestrator's own model. The
review tool runs at whatever model invokes it, so reviewers are spawned at the review model
and never run by the implementer. An implementer resolving a task's conflict runs at that
task's implementation model. The story row's review and fix-up run at the max tier of the
story's tasks, the epic row's at the max tier of the epic's: review at that tier's review
model, fix-up at its implementation model.

## Review

**Check command.** One command per owner repo, `make check`, and every owner repo has a `check`
target (ADR 0015): `/dev:setup-repo` adds one, and a story run in a repo with none ends at once
with `failed: no check target`. So every tree is checked, and a commit that moves the tip after
the review always has its new tree checked. Every row runs the same command; nothing else is a
check. The story orchestrator resolves it once per run and hands it to each task orchestrator in its brief, so the parallel tasks of one run
share one gate (dev-yyu). Test seams are not checks: no order
among them and no log per seam. A test seam stays the story's testing boundary, named in its
body: the implementer's brief names the seams as where its tests go, and the reviewer's as
where the unit's criteria must be exercised.

**Check record.** The orchestrator that runs the check command on a tree writes a check
record, the command, its exit and the log, under the owner checkout's scratch directory
(`<owner>/.tmp/`) keyed by the tree SHA; a later agent at any row that reaches a tree with a
green record treats it as checked, and one with a red record checks it again (Check scope). Only an orchestrator writes a check record: an
implementer's own runs never count (trust rule 3). The PR's Evidence is the record of the delivered tip's tree.

The call that writes a record is one foreground Bash call with `timeout: 600000`, a compound call (an exception to one command per Bash call), run once per tree: `mkdir -p <worktree path>/.tmp; mkdir -p <owner>/.tmp/checks/<tree>; export TMPDIR=<worktree path>/.tmp; make -C <worktree path> check > <owner>/.tmp/checks/<tree>/log 2>&1; echo "command=make check exit=$?" > <owner>/.tmp/checks/<tree>/record; cat <owner>/.tmp/checks/<tree>/record`. `<tree>` is the tip's tree, `git -C <worktree path> rev-parse HEAD^{tree}`, and `<worktree path>` the checkout holding that tip: the task's worktree, or `<owner>` when the owner checkout is on the branch. A green costs one `exit=0` line and no check output enters the orchestrator's context; a red is read by `tail -n 40 <log>`, never a whole log.

**Check gate.** At every row the gate exits when the checks are green on the tip the review called clean.
Each pass runs the check command on the tip, unless its tree has a green record, then the review.
A `low` task's gate is the checks alone, with no review.
A red or a blocking verdict goes to a fresh implementer by pointer brief and the loop starts over
(at the epic row, to `ready-for-agent` tasks under the story, The epic row above);
three such fix-ups per unit (at the epic row, three per story), and the fourth is `failed`,
one line whose reason names the last failure's cause, a red check or a blocking verdict (dev-aeo).
At the epic row it is `failed: <story-id> checks red after three fix-ups` after a red check and `failed: <story-id> epic review not clean after three fix-ups` after a blocking verdict, and no other wording.
A fix-up that commits nothing (a flaky red it could not reproduce, say) leaves the tip and its tree
where they were, and the loop starts over from the checks all the same: after a red that tree's
record is red, and a red record skips nothing (Check scope), so the checks rerun on the unchanged tree
rather than one red record spending the whole budget, and a flaky red can go green there (dev-vnf).
After a blocking verdict the unchanged tree keeps its green record, so the pass runs no check and
the review runs again; at the story row a green on a tip the `review:` note still names exits.
A fix-up that commits nothing still spends the budget, so a red that stays red on an unchanged tree
still fails at the fourth.
A fresh orchestrator at any row starts its unit's budget at three whatever notes earlier invocations left,
and an agent resumed with its context keeps its own count (Cut-off agents in `harness.md`).
The epic orchestrator counts a story's spent budget from the story's `epic fix-up` notes after this invocation's `epic review 1` note (The epic row, above).
The bound a person wants is per invocation (dev-l4j): a person who types `/dev:implement-spec` or `/dev:implement-story` again starts a new invocation,
and a replaced task orchestrator's task starts over from the integration branch tip,
so neither the task row nor the story row records spent fix-ups for a later invocation to count from.
A minors fix-up and a conflict resolution move the tip, so the checks rerun, but no reviewer
runs again and no budget is spent: the gate exits on the moved tip once its checks are green.
The story orchestrator records the reviewed tip in its notes, the reviewed-tip note on the story bead
(`review: <tip SHA>`), which names that moved tip, so a rerun knows the tip the review called
clean and reviews only a tip that has moved past it; the task row writes no such note.
On delivery it records the delivered tip and its check record, `delivered: <tip SHA> <check record>`,
which the epic row reads as the story's delivered tip.

**Review verdict.** Every reviewer, at every row, tags every finding **blocking** or **minor** and ends its report on one verdict line. A
finding is blocking when an acceptance criterion is unmet, a behaviour is wrong, a test is
missing, or no test at a story seam exercises the criteria the unit names; it is minor when it changes
no behaviour an acceptance criterion names (wording, naming, a nit). The last line is
`verdict: clean` when no finding is blocking, else `verdict: blocking (<n>)`, `<n>` the
count of blocking findings. A round with no blocking findings is **clean**, whatever its
minors: they go to one last fix-up, or to the inbox as a deferral when the
orchestrator judges them out of the unit's scope (the tracker doc's "capture a retro item";
Frontier, Deferrals, below), never to a bead of the story, and at the epic row, which has
no last fix-up, always to the inbox (The epic row, above); then the unit lands, and no
reviewer runs over that last fix-up. A blocking round's minors are sorted the same way:
those in the unit's scope go to its fix-up, pointed at the round's note, with its blockers,
and the rest to the inbox at once. Every fix-up's report names each minor it fixed and each
it left unfixed. No minor is dropped (dev-a9a):
every minor still unfixed when the unit lands or fails goes to the inbox as a deferral, the
tracker doc's "capture a retro item". When the unit lands, that is each minor a fix-up
reports it left unfixed. When the unit ends `failed`, it is also every minor of its review
notes that no fix-up's report names as fixed, since a later clean round need not report a
minor again and its review note would be its only trace. At the epic row every round's minors go to the inbox at once (The epic
row, above).
Every fix-up, red or blocking, spends the loop's budget (the Check gate rule above); a
minors fix-up spends none, at any row. A round that reports
every acceptance criterion met plus three wording nits is clean, and the task lands after
one fix-up. Before this rule a round was clean only with no finding of either kind
(INFRA-29's runs, 2026-10-22 to 2026-10-23): `chezmoi-9v4.1.5` failed twice on rounds that
reported every criterion met plus four, then one, wording findings, costing two restarts of
its orchestrator and a fourth run of the feature, and `chezmoi-9v4.1.1` took seven Fable
rounds.

## Delivery

The delivery procedure, parametrised by the unit it delivers: a **story** (`/dev:implement-story`, and `/dev:implement-spec`'s story orchestrators) or a **standalone task** (delivered by its own skill). `<unit-id>` is the unit's bead, `<branch>` the branch it delivers (the story's integration branch, or the standalone task's branch), `<tip SHA>` that branch's tip, `<tree>` the tip's tree (`git -C <owner> rev-parse <branch>^{tree}`, the one the check gate's exit read), and `<check record>` the record of that tree, `<owner>/.tmp/checks/<tree>/record`. The typed command is the authority for the push and the PR (the Delivery paragraph above). What stays with each skill: opening the PR (a draft for a story, ready for a standalone task), the lines it appends to the PR body, the sibling refresh, and where a `failed:` line below goes in its report. A step below that ends the delivery on a `failed:` line writes no `delivered:` or `pr:` note and no `PR:` line.

1. **Stray-commit check**, before any push: read every commit the push would carry but merges, `git -C <owner> log --no-merges --format='%H%x09%ae%x09%(trailers:key=Bead,valueonly,separator=%x2C)%x09%s' <default branch>..<branch>`, against the run's author, `git -C <owner> config user.email`. A commit with another author or no `Bead:` trailer came from outside the run (a test whose throwaway repo failed to init commits into the enclosing checkout): push nothing and end the delivery with one `failed: stray commit <sha> <subject>` line per such commit.
2. **Push.** With a forge: `git -C <owner> push -u origin <branch>`, so the PR carries every merge. A refused push ends the delivery with a `failed: push <command>: <error>` line. With no forge: push the branch when `<owner>` has an `origin` (the same command, the same `failed: push` line when refused); with no `origin` the branch stays local and the report names it.
3. **PR body.** Call the Skill tool with `mattpocock-skills:pr` to write the body, its Evidence the delivered tip's check record (`<check record>`: its command and exit, and `tail -n 20` of its log), then append the skill's own lines and write the body back on stdin (`gh pr edit <n> --repo <forge-slug> --body-file -`, or `tea pr edit <n> --repo <owner> --description-file -`).
4. **Forge-check wait**, before the delivery is recorded, so a unit is never finished on a PR its CI rejects. Whether the forge has checks to wait for is read from the pushed tip's tree first: `git -C <owner> ls-tree -d --name-only <branch> .github/workflows` on `gh`, and the same for `.forgejo/workflows`, `.gitea/workflows` and `.github/workflows` on `tea`; no directory listed means no checks: skip the wait, with `checks: skipped: no workflows` in the report (a GitHub repo whose only checks come from an outside app is skipped too). With no forge there are no checks to wait for, and the report carries `checks: skipped: no forge`. Otherwise wait in one foreground Bash call with `timeout: 600000` (the Idle rule in `harness.md`; never a background call or a `Monitor`; a compound call, an exception to one command per Bash call), with the sandbox disabled as every forge command is, `<tip SHA>` the tip just pushed: on `gh`, `until [ "$(gh pr view <n> --repo <forge-slug> --json headRefOid -q .headRefOid)" = <tip SHA> ] && gh pr checks <n> --repo <forge-slug> --json name > /dev/null 2>&1; do sleep 10; done; gh pr checks <n> --repo <forge-slug> --watch --interval 30` (the loop waits until the PR's head is the pushed tip and its checks have registered, so the last tip's finished checks never stand in for them; the watch waits for them to finish); on `tea`, `until tea api --repo <owner> repos/{owner}/{repo}/commits/<tip SHA>/status | jq -e '.total_count > 0 and ([.statuses[] | select(.status == "pending")] | length == 0)' > /dev/null; do sleep 30; done`. Workflows that never run on the PR (push-only triggers, path filters) leave the loop waiting until the `timeout` ends it. Whether the call returns or its `timeout` ends it, then read the checks: `gh pr checks <n> --repo <forge-slug> --json name,bucket,link`, each check its `name`, `bucket` and `link`; or `tea api --repo <owner> repos/{owner}/{repo}/commits/<tip SHA>/status | jq -r '.statuses[] | [.context, .status, .target_url] | @tsv'`, each its context, status and URL. A read that fails with anything but gh's `no checks reported` is a forge error, never a skip: the delivery ends at it as at a red check, with `failed: forge check <command>: <error>`. No check at all (gh's `no checks reported`, or no status line) is a forge with no checks: `checks: skipped: none reported` in the report, and delivery goes on. A red check (`bucket` `fail` or `cancel`, status `failure` or `error`) wins over any check still pending. With none red, a check still pending (`bucket` `pending`, status `pending`) runs the wait call again, at most six calls in all; one pending after the sixth counts as red. A red check ends the delivery: `bd -C <owner> note <unit-id> "checks red: <tip SHA>"`, so the unit is not finished even when an earlier delivery left a `pr:` note, and no `delivered:` or `pr:` note is written; one `failed: forge check <name> <run URL>` line per red check. The fix is the human's (or a task added in add mode): a rerun on the same tip pushes it again and waits on the same checks. Every check green (`pass` or `skipping`, status `success` or `warning`): delivery goes on.
5. **Record the delivery**, in this order. `bd -C <owner> note <unit-id> "delivered: <tip SHA> <check record>"` first, `<tip SHA>` the tip just delivered (`git -C <owner> rev-parse <branch>`) and `<check record>` its record's path. Only a delivery writes it, so a run that fails anywhere before it leaves the last `delivered:` line naming an earlier tip, and the epic row reviews a story only on the tip that line names. Then `bd -C <owner> note <unit-id> "pr: <url>"`, or `pr: <branch> <tip SHA>` when there is no forge. The `delivered:` note goes ahead of the `pr:` note, since a `pr:` note makes the unit finished: a run cut off between the two leaves no `pr:` note, and the next run delivers again.

## Frontier

The **frontier** is the set of tasks an orchestrator may start now. Work only the frontier.
A task is on it when all of these hold:

- it is open and unclaimed, and `bd ready` lists it in its owner repo (`bd -C <owner> ready
  -n 0 --json`, since the default limit is 100). Native edges stay inside one database, so
  `bd ready` honours them;
- it is labelled `ready-for-agent`. `bd ready` does not treat labels specially, so the
  orchestrator does: a task without that label (`ready-for-human`, `needs-triage`,
  `needs-info`, `wontfix`, or no triage label at all) is never claimed and never gets a
  task orchestrator, implementer or reviewer. Lacking `ready-for-human` is not enough: a review
  deferral filed as a `needs-triage` child of the story is listed by `bd ready` and has
  nothing to implement (INFRA-27's resumed run, 2026-10-20: four such children of
  `chezmoi-a0q.1` sat in `bd ready`, one of them a list of seven deferrals, and the run
  stopped to ask for a triage);
- it has not failed twice in this run (`/dev:implement-story`'s step 5). Unclaimed, it is back in
  `bd ready`, so only the run's own count keeps it off;
- no **text blocker** of the task's story is open.

A text blocker is a line `<repo> <bead-id>` under the `## Blocked by` section of the
task's story, one edge of the feature's **story DAG** (`issue-tracker.md`'s "Before the
story quiz"); a task has none of its own, and a story may carry several. Each line names
either a **human gate task**, a `ready-for-human` task that clears when a person closes
it (a publish task, closed with the published version), or a story, which clears when
`/dev:close-story` closes it after its PR merges, so once that story is finished its line
waits on a merge and a `/dev:close-story` run, never on any agent. `bd ready` knows nothing of
text blockers and lists a task whose story's blocker is still open, so the orchestrator
reads each line and checks that bead in its own database: `bd -C <owner> show <bead-id>
--json`, status `closed`, where `<owner>` is `<repo>`'s path by the one test in
`issue-tracker.md`'s opening. An open text blocker holds back every task of the story,
until every line's bead is `closed`. A line that names no id (`(not created: no beads
database)`) and a blocker that cannot be read both count as open. In a repo session
`<home>` is the only owner, so a text blocker in another repo is unreadable and counts as
open: such a story is run from the workspace session that cut it. A story with no text
blocker holds back nothing beyond `bd ready`.

A publish task, like every human gate task, is `ready-for-human`, so it is off the frontier, yet it appears in `bd ready`
(and under `--parent <story-id>`) as soon as its story's implementation tasks close.

**Unclaim.** A claim outlives its task orchestrator and hides the task from `bd ready`
(Cut-off agents in `harness.md`), so a task left claimed is off every later run's frontier
until someone unclaims it (INFRA-27's run 1, 2026-10-20: `chezmoi-a0q.1.5` stayed
`in_progress` and assigned after two failed runs of its orchestrator, and the user ran
`bd unclaim` by hand twice). So the story orchestrator `bd -C <owner> unclaim <id>`s every
task whose task orchestrator returned without closing it, a `failed` report or a
cut-off, before its next frontier read, and when a task leaves the frontier after its
second failure it also notes the resume pointer on the task: open, unassigned, listed by
`bd ready`, the note saying what to type. A person runs `bd unclaim` by hand only when the
orchestrator could not. A run that ended in an error instead of a report leaves its tasks
claimed, and the re-run's own unclaim covers them, so the hand run only saves waiting for
it. A claim bd refuses to release because another actor holds it needs `--force`, which the
orchestrator never adds: it reports the holder on a `failed:` line and leaves the call to a
person. `/dev:implement-story`'s step 9 names both beside its `resume:` line.

**Deferrals.** A finding the story review puts off (out of the story's scope, a follow-up,
a note with nothing to implement) is a retro item: the story orchestrator captures it in
the inbox as the tracker doc's "capture a retro item" says, with plain `bd` in `<home>`,
that section's labels and the finding as the body's Moment, and never creates a child of
the story for it; the reviewer reports findings and creates no bead either. A child is a task, and one carrying `needs-triage`
stays open until `/dev:triage` decides it, which no run of the orchestrator can do. So a story
is **finished** (`GLOSSARY.md`) when every child is `closed` or carries `ready-for-human`,
`needs-triage` or `wontfix` and its `pr:` note exists: an untriaged child an earlier run
left under a story holds back neither its review nor its PR, and `/dev:implement-story`'s step
6 counts the same way before its review.

A `closed` task is never on the frontier, so a resumed run skips everything earlier runs
closed. Re-evaluate the frontier after every close: a closed task may release native and
text blockers, and each newly released task goes to a task orchestrator at once.

When nothing is in flight (task orchestrator, implementer, reviewer) and the frontier is
empty, the invocation ends. It is a **human stop** if a `ready-for-human` task is open, or if a story
is held only by text blockers naming finished stories (each with its `pr:` note, waiting on
a merge and a `/dev:close-story`; `GLOSSARY.md`'s Human stop), and a **stall** otherwise. A
human stop's report names the open task, and for each such blocker the blocking story,
its PR and the action: merge its PR, then run `/dev:close-story <story-id>` in its repo. A
stall's report names each stuck task with its open blocker. A run
whose tasks are all closed ends the same way when the checks stay red or the push is
refused (Delivery), with the check command or the push and its command on a `failed:` line.

## Working-directory preflight

Run by `/dev:spec-to-stories`, `/dev:spec-to-tasks` and `/dev:implement-spec`, each at the step that
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
carries the task cut and `/dev:implement-spec` in the same session.
