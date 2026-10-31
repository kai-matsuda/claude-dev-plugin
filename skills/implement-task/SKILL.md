---
name: implement-task
description: "Implement one standalone task bead in its repo: spawn one task orchestrator, land its reviewed branch, deliver it as a PR opened ready and close the task. Use when given a task bead id with no story (an accepted retro item, a small bug) to implement, typed in the repo whose beads hold it."
---

<!-- The story row with a frontier of one (INFRA-37): /dev:implement-story's plumbing, one
     /dev:task-orchestrator, a fast-forward landing and the rules doc's Delivery section, with no
     story bead, no story gate and the PR opened ready. -->

You have been given a **standalone task** bead id: a task with no story (`GLOSSARY.md`), typed in the repo whose beads hold it, a workspace's own tasks included. The issue tracker rules are in `${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md`.

The goal is the task built and reviewed by one task orchestrator on the branch `feat/<task-id>`, delivered as a PR **opened ready** (or, with no forge, the pushed branch), and the task closed at delivery.

## Shared rules

The session running this skill is a **story orchestrator**, the story row with a frontier of one: no story bead and no story gate (the rules doc's The standalone task). It follows `${CLAUDE_PLUGIN_ROOT}/docs/agents/orchestration.md`: Orchestrator role, Scratch space, Complexity tier, Frontier, Check gate, Repo plumbing and Cut-off probe and Delivery, with the harness mechanics in `${CLAUDE_PLUGIN_ROOT}/docs/agents/harness.md`. Read both before step 1. There is one task, so there is no story gate: the task gate is the review, and the task gate's green record on the delivered tip is the check. You never implement and never resolve a conflict by hand: every change comes from a subagent.

## Owner repo

`<owner>` is the session's repo, `git rev-parse --show-toplevel`. Every `bd` command is `bd -C <owner> …`; every `git` command you run is `git -C <owner> …`; every file path is absolute; paths are spelled out literally, one command per Bash call (the harness doc's Literal paths); every forge command names the repo (the rules doc's Repo plumbing and Cut-off probe, its Forge decision). `<plugin root>` is resolved as the rules doc's Plugin root rule says. `<KEY>-<n>` is the task's `external_ref`; with none, commits carry `Bead:` alone. `<branch>` is `feat/<task-id>`, the integration branch, as the story row's is `feat/<story-id>`. `<task-slug>` is the task id, so the task orchestrator's hand-rolled worktree branch `task/<task-slug>` is `task/<task-id>`, never the integration branch.

## Steps

1. **Read the task.** `bd -C <owner> show <task-id> --json` (an array; `.[0]`). Refuse with one line and create nothing when:
   - the bead is not of `issue_type` `task`: `<id> is of type <type>, not a task; /dev:implement-task takes a standalone task bead id.`;
   - its `.parent` is a bead of `issue_type` `story` (`bd -C <owner> show <parent> --json`): `<id> refused: its parent <story-id> is a story; run /dev:implement-story <story-id>` (a story's task is delivered only in its story's PR);
   - it is not `closed` and not labelled `ready-for-agent`: `<id> refused: not ready-for-agent (labels: <labels>); run /dev:triage first`.

   The task's notes (`.[0].notes`) are what earlier runs left behind, one line each, the last of a kind winning: `branch:` (step 2), `review:` (step 4) and `delivered:`, `pr:` and `checks red:` (step 5). A `closed` task with a `pr:` note is **finished**: touch nothing (no worktree removed, no check record deleted), run only step 6's stray scan and report from its notes. A `closed` task with none was closed by hand: `<id> refused: closed without a pr: note`.

   **Merge guard.** An open task with a `pr:` note (a run cut off between the `pr:` note and the close, or a task reopened for more work) passes the rules doc's Repo plumbing and Cut-off probe, its Merge guard before anything else, its Forge decision made first (its remote pre-check and proof run here). MERGED: refuse with `<task-id> refused: PR <url> already merged; file the rest as a new standalone task (bd create, then /dev:implement-task <new-id>)` and create nothing. CLOSED unmerged: refuse with `<task-id> refused: PR <url> is closed unmerged` and create nothing. OPEN: the Merge guard's outcome, and deliver again (steps 2 to 5 once more, on it). `<default branch>` is found as step 2 says. When the section cannot decide a branch form or no forge, ask the user whether the branch has merged into the default branch, and wait. That form has no URL, so the `pr:` value stands in for `<url>` in the refusals.

2. **Branch and plumbing**, as the story row's. Find the default branch: `git -C <owner> symbolic-ref --short refs/remotes/origin/HEAD` minus `origin/`; with no `origin/HEAD`, whichever of `main` and `master` exists. A `branch:` note means an earlier run made the branch: `git -C <owner> switch <branch>` if the owner checkout is off it. Otherwise `git -C <owner> switch -c feat/<task-id> <default branch>`, then `bd -C <owner> note <task-id> "branch: feat/<task-id>"`. The owner checkout stays on `<branch>` until the run ends.

   Apply the rules doc's Repo plumbing and Cut-off probe on `<branch>`, `<unit-id>` being `<task-id>`: its Gitignore commit; its Check target, resolved with the owner checkout on `<branch>`, whose refusal ends the run before the task orchestrator starts (the check command is `make check`); and its Forge decision, already made in step 1 when the merge guard ran.

3. **Spawn the task orchestrator.** A `review:` note naming `<branch>`'s tip (`git -C <owner> rev-parse <branch>`) means an earlier run landed the reviewed tip and failed at delivery: go straight to step 5. A task that is `in_progress` while no task orchestrator of this run holds it was claimed by a cut-off or failed run: `bd -C <owner> unclaim <task-id>` first; one bd refuses because another actor holds it is never forced, and ends the run with `failed: <task-id> claimed by <actor>`. Then probe for a failed run's commits as the rules doc's Cut-off probe says: a hit means its next spawn is a gate entry on the branch, worktree path and tip the probe found, a miss a claim entry. A gate entry re-enters at the gate on those commits with a fresh budget (`/dev:task-orchestrator`'s "Two entries"), so nothing built is thrown away.

   Spawn one **task orchestrator** with `subagent_type: "general-purpose"` (the rules doc's Subagent type) at `model: opus`, then end your turn: its report line arrives as the Agent tool's completion notification and resumes you (the harness doc's Waiting; you never poll). Its brief, filled in:

   > Call the Skill tool with `dev:task-orchestrator` and follow it as the task orchestrator for task `<task-id>`. Owner `<owner>`; integration branch `<branch>`; check command `make check`; plugin root `<plugin root>`, spelled out as the absolute path. A retry adds `retry: <first failure's reason>`. A gate entry adds `gate entry: <task branch> <worktree path> <tip SHA>`. Report the skill's one line and nothing after it.

4. **Act on the report.**
   - `<task-id> reviewed: <task branch> <worktree path> <tip SHA>`: land it. Confirm `git -C <owner> branch --show-current` prints `<branch>`, `git -C <owner> status --porcelain --untracked-files=no` prints nothing and `git -C <owner> rev-parse <task branch>` prints `<tip SHA>`, else end with `failed: <task-id> not on <branch>`, `failed: <task-id> owner checkout dirty` or `failed: <task-id> <task branch> moved past its reviewed tip`. Run the rules doc's Delivery section's stray-commit check on `<branch>..<task branch>` (a hit ends the run with its `failed: stray commit <sha> <subject>` line), then `git -C <owner> merge --ff-only <task branch>`: nothing else moves `<branch>`, so it fast-forwards to the reviewed tip, and a refused one ends the run with `failed: <task-id> <branch> diverged from <task branch>`. Note the landed tip, `bd -C <owner> note <task-id> "review: <tip SHA>"`, and go to step 5.
   - `<task-id> needs split: <cut>`: create each proposed bead as a standalone task, `bd -C <owner> create --type task --labels complexity:<tier>,ready-for-agent --deps blocked-by:<new-id>,... "<title>" --body-file -` with the cut's edges and tier (else the original's), move every bead the original blocked onto the new ones (`bd -C <owner> dep add <dependent> <new-id>`), close the original with `bd -C <owner> close <task-id> --reason "split into <ids>"`, and go to step 6 with a `split:` line per new bead.
   - `<task-id> failed: <reason>`: `bd -C <owner> unclaim <task-id>` (a refusal as in step 3). A first failure gets one fresh task orchestrator, step 3's probe deciding its entry and `retry: <reason>` in its brief. A second ends the run: `bd -C <owner> note <task-id> "failed twice: <reason>; resume: /dev:implement-task <task-id>"` and a `failed:` line in step 6. An API error in place of a report line is a cut-off, not a failure: spawn its replacement as step 3 says, the failure count unchanged.

5. **Deliver**, as the rules doc's Delivery section says, with the standalone task as its unit (`<unit-id>` is `<task-id>`, `<branch>` the task's branch, `<check record>` the record of its tip's tree): its stray-commit check before any push, the push, the PR body, the forge-check wait, then the `delivered:` and `pr:` notes in that order. Its `<tree>` is the reviewed tip's, which the task orchestrator's last check recorded green; with no green record there (`exit=0` in `<owner>/.tmp/checks/<tree>/record`), run the rules doc's Check record call with `<owner>` as its `<worktree path>`, `timeout: 600000`, and a red ends the run with `failed: check make check`. Each `failed:` line the Delivery section ends on goes to step 6 with no `PR:` line, and the task stays open.

   With a forge, the PR is opened **ready**, not draft, after the push and before the PR body: no epic review sits above a standalone task, so the human's review starts at once. Reuse the open PR an earlier run opened for `<branch>` (`gh pr list --repo <forge-slug> --head <branch> --json url -q '.[0].url'`, or `tea pr list --repo <owner> --state open --fields head,url --output json` filtered on `head`); otherwise `gh pr create --repo <forge-slug> --head <branch> --base <default branch> --title "<task title>" --body-file -`, or `tea pr create --repo <owner> --head <branch> --base <default branch> --title "<task title>" --description "<body>"`. The body names the task and the Jira key when there is one; the Delivery section's PR body step then writes it whole. With no forge there is no PR: the Delivery section's no-forge path applies, the pushed branch is the deliverable (the local branch with no `origin`), and the report carries `checks: skipped: no forge`.

   **Close at delivery.** After the `pr:` note, `bd -C <owner> close <task-id> --reason "delivered: <pr: value>"`: no close skill runs after a standalone task's merge, and nothing waits on a person to close the bead.

6. **Clean up and report.** Remove the landed task's worktree when it is merged into `<branch>` (`git -C <owner> merge-base --is-ancestor <task branch> <branch>` exits 0): `git -C <owner> worktree remove <worktree path>`, then `git -C <owner> worktree prune`, both with the sandbox disabled (the sandbox denies deletes under the git common directory's `worktrees/`). Leave every other worktree in place, an unmerged failed attempt's above all (the next run's gate entry), and name it on the `worktrees:` line. After a delivery, `rm -rf <owner>/.tmp/checks`; a run that ends on a `failed:` line keeps the records. Name every path on a `??` line of `git -C <owner> status --porcelain --untracked-files=all` on a `stray:` line, and delete none.

   Final report, one block:

   ```
   task:    <task-id> <title>
   repo:    <owner>
   PR:      <url>    (or  branch: <name> @ <tip SHA>)
   failed:  <reason>                                  (the task orchestrator's second failure,
            or push <command>: <error>                or the push the Delivery section could not make,
            or forge check <name> <run URL>           or each forge check that went red)
   checks:  skipped: <no forge | no workflows | none reported>
   split:   <new-id> <title>                          (one per bead of a needs-split cut)
   worktrees: <absolute path> <unmerged <worktree branch> | <error>>
   stray:   <path>
   resume:  /dev:implement-task <task-id>
   ```

   A run that did not deliver has no `PR:` line. The `failed:`, `checks:`, `split:`, `worktrees:` and `stray:` lines appear only with content; the `resume:` line always appears, naming the first new bead after a split.
