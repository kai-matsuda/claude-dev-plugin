---
name: implement-spec
description: "Implement the result of /mattpocock-skills:to-spec and /dev:spec-to-tickets in code: one story orchestrator per startable story, across the feature's repos."
disable-model-invocation: true
---

<!-- Fork of mattpocock-skills 1.3.1 engineering/implement-spec, rewritten as the thin
     feature-level epic orchestrator (INFRA-26, ADR 0006; the epic row, INFRA-33). The plugin's
     single-repo procedure moved to /dev:implement-story, and its shared rules to
     docs/agents/orchestration.md in this plugin; this file keeps only the story gather, the
     flat-epic refusal, the working-directory preflight, the story orchestrator spawn, the epic
     review with its add-mode fix-up, the three end states and the once-only Jira step. It no
     longer tracks the plugin copy line by line: re-sync the intent, not the text. -->

You have been given a feature: an epic bead whose stories (one per repo the feature changes) hold the tickets. The issue tracker rules are in `${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md`.

The goal is every story implemented and delivered, each by its own **story orchestrator** in its own repo, and every PR reviewed against the spec. You are the **epic orchestrator**, the feature-level session: you gather, check, spawn, wait, review and report, and nothing below touches a ticket.

Your row of the rules doc's table: one story orchestrator builds each story, in parallel over the startable stories; the checks are the check command as the forge runs it on each PR; the review is the spec axis only, the Jira Epic's spec, with no standards axis, at the review model of the epic's max tier; the fix-up is the review's blocking findings filed as `ready-for-agent` tickets under the story and that story re-run in add mode; a story lands when its PR is marked ready, for the human to take from there; the gate exits when the checks are green on the tip the review called clean; the budget is three per story.

## Shared rules

Follow `${CLAUDE_PLUGIN_ROOT}/docs/agents/orchestration.md`, read before step 1: the orchestrator role (you never implement), the table's epic row, the Review section's verdict rule, the tier-to-model table, and the frontier with **text blockers**. "Text blocker", "human stop" and "stall" mean those sections and `${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md`.

The harness mechanics (Waiting, the Idle rule, Cut-off agents, literal paths) are in `${CLAUDE_PLUGIN_ROOT}/docs/agents/harness.md`.

## Names

`<home>`, `<workspace>` and the session mode are as **the one test** in the opening of `${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md` defines them. For each story, `<owner>` is the checkout of the database the story was found in, and `<owner repo>` is as the one test names it.

## Steps

1. **Pick the epic bead.** Before any `bd` call, check `test -d <home>/.beads`: without it, plain `bd` climbs to an ancestor's database (another home's inbox). Missing → `refused: no beads database in <home>`, and stop. A bead id → `bd show <id> --json` (an array; `.[0]`); an `issue_type` other than `epic` → `<id> is of type <type>, not an epic; /dev:implement-spec takes an epic bead id or <KEY>-<n>.` and stop. A `<KEY>-<n>` → `bd list --type epic --external-ref <KEY>-<n>`; none → say so and stop; several → list them and ask which. `<KEY>-<n>` is then the epic's `external_ref`.

2. **Gather the stories** with the "Stories" gather of "fetch the relevant ticket" in `${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md`, its fallback and failure rules included. A sweep that stops there spawns nothing, since that repo's story would go unseen and Done could fire early. Skip `retro`-labelled beads. Each story's `<owner>` and `<owner repo>` follow from where it was found (Names).

   **Flat epic.** `bd list --parent <epic-id> --all --json` is the epic's direct children (`--all` keeps closed ones). Any child that is not of type `story` → refuse and stop, creating nothing:

   `<id> refused: flat epic (tickets directly under the epic bead); the story skills do not handle it — the small-bug path does: /mattpocock-skills:implement <ticket-id> per ticket, then bd close <epic-id>`

   No stories at all → refuse, naming the epic.

3. **Find the startable stories.** Read each story with `bd -C <owner> show <story-id> --json` and `bd -C <owner> children <story-id> --json`. A **finished story** (`${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md`) is one where every child is `closed` or carries `ready-for-human`, `needs-triage` or `wontfix` and its notes carry a `pr:` line (the rules doc's Frontier, Deferrals); it is left untouched. A story is **startable** when it is not finished and every text blocker in its `## Blocked by` is `closed`, each read as the rules doc's Frontier section says (a line with no id, or a blocker that cannot be read, counts as open). A blocker naming a story (`<repo> <story-id>`) is open until that story is closed, which `/dev:close-story` does once its PR has landed; the story's own state is read with the same `bd -C <owner> show`, not from its `pr:` note. Print every story as `<owner repo> <story-id> <finished | startable | waiting on <blocker line as written>> <title>`, then work from that list. No startable story → go to step 6, which reviews any finished story still owed its epic review.

4. **Preflight.** Run the "Working-directory preflight" of `${CLAUDE_PLUGIN_ROOT}/docs/agents/orchestration.md` on every startable story's owner repo: one `/add-dir <owner>` line per missing repo, then stop, spawning nothing. A story that is finished or waiting needs no working directory.

5. **Spawn.** One story orchestrator per startable story, all in a single message: Agent calls with `subagent_type: "general-purpose"` (the rules doc's Subagent type) and `model: "opus"`. Each brief is two pointers and an instruction, nothing else:

   > Story `<story-id>` in the repo at `<owner>`. Call the Skill tool with `dev:implement-story`, and report the block it ends on.

   Then end your turn: an Agent call returns at once, and each orchestrator's block arrives as the Agent tool's completion notification and resumes you (the harness doc's Waiting; never a poll). Step 6 needs every report before it reviews, so it runs once the last of the batch is in. A closed publish ticket cannot happen mid-run (a human closes it), so no waiting story becomes startable while the batch runs and the set is fixed per run.

   **Cut off.** An orchestrator that returns an error instead of a report block is resumed, not respawned (the harness doc's Cut-off agents): the stop sweep, then `SendMessage` the same agent id the resume line. A session limit ends the epic orchestrator's turn with the same error, so this continues from the user's next message once the limit has reset. The orchestrator's block then arrives like a batch report and step 6 waits for it as for the others; a resume that returns an error again is that story's `failed:` line in step 7, with the error as its reason. An orchestrator missing from `ListAgents` with no completion notification is probed with that same resume line. A reply saying it was stopped by the user means its work is cancelled and nothing is retried: the `/dev:implement-spec` the user typed is the ask for a fresh orchestrator on that story, spawned as step 5 does, which re-reads the story and its tickets from the beads.

6. **Epic review.** Once every story of the batch has reported, read every story again from its bead (step 3's reads; the reports are pointers, the beads are the truth). Each story that reports delivered (a finished story whose `pr:` note names a PR, or a `<branch> <tip SHA>` with no forge) is reviewed, unless its last `epic review` note is clean on its current tip (`git -C <owner> rev-parse <branch>`, the branch from its `branch:` note). Review one PR at a time in its owner repo: spawn one reviewer, end your turn, and spawn the next when its report arrives. The reviewer is an Agent call with `subagent_type: "general-purpose"` at the review model of the epic's max tier: the max `complexity:` label among the children of every story of the epic, mapped by the tracker doc's "Complexity labels". `<plugin root>` is the plugin root spelled as a literal path, as the rules doc's Plugin root rule says. The brief:

   > Review story `<story-id>` in the repo at `<owner>`: call the Skill tool with `mattpocock-skills:code-review` on the diff from the default branch to the integration branch, `git -C <owner> diff <default branch>...<branch>`. Run the spec axis only, against the Jira Epic's spec (`<KEY>-<n>`, read with `getJiraIssue`), and no standards axis. Tag each finding blocking or minor and end on the verdict line, as the Review verdict rule in `<plugin root>/docs/agents/orchestration.md` says. The harness mechanics are in `<plugin root>/docs/agents/harness.md`. Report the findings and the verdict line.

   With no external ref on the epic bead, the brief names the spec that the tracker doc's spec fetch finds instead. Record each verdict on the story: `bd -C <owner> note <story-id> "epic review <k>: <tip SHA> <verdict line>"`, `<k>` counting this story's epic reviews.

   **Draft until clean.** Every PR stays a draft until its verdict is clean. On a clean verdict, the checks as the forge runs them must be green on that same tip: `gh pr checks <n> --repo <forge-slug>`; a forge that runs no checks on the PR (`tea`, or none configured) passes on the review alone. A red check is a blocking finding, filed as below; a pending one leaves the draft, and the story's `review:` line says `checks pending`. Green: mark the PR ready, `gh pr ready <n> --repo <forge-slug>` or `tea pr edit <n> --repo <owner> --ready`, the forge decided and each command run with the sandbox disabled, as `/dev:implement-story` step 3 says. With no forge there is no PR to mark, and the clean verdict is the story's outcome. The minors of a clean verdict go to the inbox as deferrals (the tracker doc's "capture a retro item"), never to a bead of the story.

   **Fix-up.** A blocking verdict is cut by you into tickets under the story, one per blocking finding: `bd -C <owner> create "<the finding, as a title>" --parent <story-id> --type task --labels ready-for-agent,complexity:<the story's max tier> --description "<the finding, its file and line, and the fix the reviewer asked for>"`, a beads write, the only kind an epic-level stage makes in an owner repo. Then re-run that story's orchestrator in add mode: once every PR of this round is reviewed, spawn one story orchestrator per story with filed tickets, with step 5's brief, all in one message, and end your turn. The added `ready-for-agent` tickets make the story startable again, and `/dev:implement-story` continues on the story's branch and its open PR. When that batch is in, run this step again on those stories. The budget is three per story: three blocking verdicts are fixed up, and the fourth is `failed`: file nothing, leave the draft, and report `failed: <story-id> epic review blocking after three fix-ups`.

7. **End.** When the last review is in and no fix-up batch is running, read the end state from the beads. The epic bead stays **open**: `/dev:close-epic` closes it after the PRs land.

   - **Done**, when every story is finished with its epic review clean and its PR marked ready (open `ready-for-human` tickets aside; Done wins, and their `human:` lines stay in the report). In the first run that ends Done, the Jira step of "the spec is done" in `${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md`, with every story's `pr:` value. What the doc lacks: read the Jira epic with `getJiraIssue` and `comment` among the fields, as that step's already-made check; a key not found in Jira, or an epic bead with no external ref → report the Jira step as skipped, and why; any other Jira error → report it.
   - **Human stop**, when a `ready-for-human` ticket is open in any story, or a waiting story is held only by blockers naming finished stories not yet closed. Build the list from the beads read in this step, so a resumed run that spawned nothing still reports it: every open `ready-for-human` child of every story, plus each waiting story whose blocker is one of those open `ready-for-human` tickets, plus each waiting story whose blocker names a finished story that is not yet closed. A run whose only open waits are story closures is this end state, not a Stall: for each such blocker print `human: <owner repo> <story-id> <pr url>: the PR to merge and the /dev:close-story <story-id> to run` (the url from the story's `pr:` note), and `waiting: <repo> <story-id>` for the story behind it. A blocker naming a story that is not finished waits on its own orchestrator and is a Stall's, unless that story itself waits only on story closures: then it counts toward the human stop, and the `human:` line names the root of the chain (A for C waits on B waits on A), the first finished story not yet closed. Relay an orchestrator's `human:` line verbatim when it returned one, since `/dev:implement-story` adds what the user does next (for a publish ticket: land the PR, publish `<crate> <version>`, `bd -C <owner> close <bead-id> --reason "published <version>"`); otherwise report `<owner repo> <bead-id> <title>`, taking crate and version from a `publish <crate> <version>` title. Report any other waiting story as Stall does (a placeholder or unreadable blocker, shown as written). End with the resume command: `/dev:implement-spec <KEY>-<n>` from the home, or `/dev:implement-spec <epic-id>` when the epic has no external ref. A resumed run leaves finished stories untouched and starts the stories that the closed human gate tickets and story closures released.
   - **Stall**, otherwise: report each story orchestrator's `failed:` lines, each story whose epic review failed after three fix-ups or whose forge checks are pending, and every waiting story whose blocker is neither an open `ready-for-human` ticket nor a finished story awaiting its closure (a placeholder or unreadable blocker, shown as written). When an open child of a story carries a `failed twice:` note (step 7's children reads) whose reason names another repo's crate, add one sentence: `/dev:spec-to-stories <KEY>-<n>` (or `/dev:spec-to-stories <epic-id>` when the epic has no external ref), add mode, adds the story that crate's repo needs. No Jira step.

   Final report, one block per story, then the end state:

   ```
   story:   <story-id> <title>
   repo:    <owner>
   PR:      <url>            (or  branch: <name> @ <tip SHA>; from the orchestrator's block, or the story's pr:/branch: notes when it was finished or waiting)
   review:  <verdict line> <marked ready | draft, fix-up <k> of 3 | draft, checks pending | failed>
                                                           (the story's last epic review, step 6)
   failed:  <bead-id> <open blocker or failure reason>     (one per line, as the orchestrator's block has them:
                                                            a ticket, <check> <command> for a red check,
                                                            or push <command>: <error>; or step 6's epic review line)
   human:   <bead-id> <title>                              (one per open ready-for-human ticket in the story)
   human:   <owner repo> <story-id> <pr url>: the PR to merge and the /dev:close-story <story-id> to run
                                                           (in the blocking story's block: a finished story another story waits on, not yet closed)
   waiting: <repo> <story-id>                              (each story whose text blocker names a human gate ticket or a finished story not yet closed)
   resume:  <command>
   state:   <finished | stopped at <bead-id> | waiting on <blocker line as written> | failed>
   ```

   The lines share `/dev:implement-story`'s final report shape, and `review:`, `failed:`, `human:`, `waiting:` and `resume:` appear only when they have content.

   End state: `Done`, `Human stop` with the resume command, or `Stall`; each story's epic review outcome (clean and marked ready, fixed up and re-run, or failed); and the Jira outcome (commented and transitioned to `<status>`, commented only, skipped, or already made).
