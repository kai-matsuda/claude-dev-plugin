# One loop, three rows: the orchestration model restated

## Problem Statement

The orchestration works, but nobody can hold it in their head. A reader of the rules doc
and the two implement skills meets four nested agent levels (driver, story orchestrator,
ticket runner, then implementer, reviewer, fix-up implementer and merger), seven role
names, two check-and-review loops that are almost but not quite the same (different exits,
different budget accounting for a minors fix-up), two review tools, test seams that are
sometimes a testing boundary and sometimes a list of commands to run, and a check that the
same tree gets four times over (the runner once, the merger twice, the story orchestrator
once more) because each role was told separately when to run it. Around all of that sit
the harness mechanics (the TMPDIR line, the Idle rule, Waiting, Cut-off agents, the Commits
rule, the `-C` discipline), repeated into every brief, so the rules doc reads as five
thousand words of model when the model is a few hundred. Typing `/dev:implement-spec` or
reading a failed run means re-deriving which of those rules applied where.

## Solution

State the orchestration once as **one loop run at three rows**. Every row, ticket, story
and epic, is the same loop: claim a unit, have a subagent build it, check it, review it,
send a failure to a fresh fix-up or land it one level up, report one line. A table gives
each row its parameters; the loop's text, two scoping rules and six trust rules are shared.
The roles become five with uniform names: **epic orchestrator**, **story orchestrator**,
**ticket orchestrator**, **implementer**, **reviewer**. One check command, resolved by
convention, runs at every row, and a tree is checked once. One review tool runs at every
row, its spec axis pointed at the row's own unit and its standards axis at what entered
since the last standards review. The mechanics move out of the model into a harness doc
every brief cites in one line. Parallelism inside a story stays.

## User Stories

1. As the human running `/dev:implement-spec`, I want the orchestration stated as one loop and
   a table, so that I can predict what the run does at any row without reading every skill.
2. As the human reading a failed run, I want every row to fail the same way (a fourth
   failure is `failed`, one line, the same words), so that I know where to look.
3. As the human, I want the agent roles named uniformly by their row (epic, story, ticket
   orchestrator), so that a name tells me the level and nothing else.
4. As the human, I want the harness mechanics in one document the briefs cite, so that the
   model doc is about how a feature flows and nothing else.
5. As the human, I want one sequence diagram of the loop beside the table, so that I do not
   reconcile three stage diagrams that are the same shape.
6. As the human, I want the glossary to carry the new role names and retire the old ones
   under `_Avoid_`, so that every doc and skill uses one vocabulary and the glossary lint
   catches a slip.
7. As a ticket orchestrator, I want to run one check command, so that I do not resolve a
   lint command and a seam list and an order to run them in.
8. As an orchestrator at any row, I want a tree that a trusted agent already checked green
   to count as checked, so that I spend a check run only on a tree nobody has seen.
9. As an orchestrator at any row, I want the record of a check (command, exit, log) kept per
   tree by the agent who ran it, so that the PR's Evidence is a lookup and not a rerun.
10. As a ticket orchestrator, I want to land my own ticket (take the lock, run the
    stray-commit check, merge), so that no merger role exists between my gate and the
    integration branch.
11. As a ticket orchestrator whose merge conflicts, I want to hand the conflict to an
    implementer in the ticket's worktree and then fast-forward, so that I never edit a file
    and the conflict is resolved by an agent allowed to.
12. As a ticket orchestrator, I want a conflict resolution to rerun the checks and not the
    review, so that parallelism does not pay a review round for every merge it causes.
13. As a story orchestrator, I want the gate to exit when the checks are green on the tip
    the review called clean, so that a fix after the review is always re-checked and never
    re-reviewed by accident or twice by rule.
14. As an orchestrator at any row, I want a minors fix-up to move the tip, rerun the checks
    and spend no budget, so that the same rule holds at the ticket and the story.
15. As a reviewer at the ticket row, I want the ticket's body (acceptance criteria, the
    story's test seams) as my spec, so that I judge the diff against what the ticket asked.
16. As a reviewer at the story row, I want the story's body as my spec and the conflict
    resolutions and cross-ticket coherence as my standards scope, so that I review what the
    ticket reviews could not see and nothing they already saw.
17. As a reviewer at the epic row, I want each story's PR against the Jira Epic's spec and
    no standards axis, so that the epic review answers "does this set of PRs deliver the
    feature" and reads no line a third time.
18. As a reviewer, I want "no test at a story seam exercises the criteria" to be a blocking
    finding, so that TDD is enforced where the seams live even though the gate no longer
    runs them one by one.
19. As an implementer, I want the story's test seams in my brief as where my tests go, so
    that red-green happens at the boundary the story named.
20. As an epic orchestrator, I want to run the epic review once every story has delivered
    and hold the PRs as drafts until it passes, so that the human's review comes after the
    agents' loop rather than racing it.
21. As an epic orchestrator with a blocking verdict, I want to file the findings as
    `ready-for-agent` tickets under the story and re-run its story orchestrator in add
    mode, three times per story, so that the epic row has a fix-up like every other row.
22. As the human, I want to be the merge of a ready PR and not a cell in the table, so that
    the machine's boundary is clear.
23. As a repo owner, I want the check command named `make check`, so that the command, the
    glossary's **Check** and the GNU convention say the same word.
24. As a repo owner whose Makefile has no `check` target, I want the gate to be review-only
    rather than fail, so that a repo opts in by adding a target.
25. As `/dev:setup-repo`, I want to install or document the `check` target, so that a new
    repo arrives with its check command.
26. As the plugin's CI, I want to run the check command itself, so that the forge and the
    gate agree on what green means.
27. As `/dev:retro`, I want one ADR recording why the loop is one and the merger is gone, so
    that a future reader does not reopen the question.
28. As the human, I want the rename to touch this repo only, so that the dotfiles repo waits
    for its own change.

## Implementation Decisions

- **The table is the model.** The rules doc's model section opens with the loop's one
  sentence and a table with one row per level and these parameters: orchestrator; what
  builds the unit; checks; review spec axis; review standards axis; reviewer and its model;
  fix-up; lands by; exits when; budget. Ticket: ticket orchestrator; one implementer in a
  worktree; the check command; the ticket's body; the ticket diff; the two-axis review one
  tier up, none at `low`; implementer by pointer brief in the same worktree; merge onto the
  integration branch under the lock with the stray-commit check; checks green on the tip the
  review called clean; three fix-ups. Story: story orchestrator; ticket orchestrators in
  parallel over the frontier; the check command; the story's body; what entered since
  (conflict resolutions, cross-ticket coherence); the two-axis review at the story's tier;
  implementer by pointer brief in a fix-up worktree; push, the PR staying a draft; the same
  exit; three. Epic: epic orchestrator; story orchestrators in parallel over the frontier;
  the check command as the forge runs it; the Jira Epic's spec; no standards axis; the
  two-axis review at the epic's max tier; findings filed as `ready-for-agent` tickets under
  the story and that story re-run in add mode; PR marked ready, the human merges;
  `/dev:close-story` then `/dev:close-epic`; three per story.
- **Role names.** Driver becomes **epic orchestrator**, ticket runner becomes **ticket
  orchestrator**; story orchestrator stays. The generic "orchestrator" in the shared rules
  means any of the three. The driver's special properties (the one agent a `SendMessage`
  reply reaches, the one whose `TaskStop` reaches the run) move under the epic orchestrator
  unchanged, since they belong to being the session. The merger is no longer a role; the
  fix-up implementer is a brief shape of the implementer, not a role.
- **Check command.** One command per owner repo, `make check` when its Makefile has a
  `check` target, otherwise none and the gate is review-only. Test seams stop being checks:
  no cheapest-first order, no per-seam logs. They remain the story's testing boundary, named
  in its body, handed to the implementer as where tests go and to the reviewer as what the
  criteria must be exercised at.
- **Every tree is checked once.** A check is one run of the check command on a tree,
  identified by the tip's tree SHA. The agent who runs it writes a **check record** (the
  command, its exit and the log) under the owner checkout's scratch directory keyed by that
  tree SHA; a later agent at any row that reaches a tree with a record treats it as checked.
  Only an orchestrator writes a record; an implementer's own runs never count. The PR's
  Evidence is the record of the delivered tip's tree. A sibling landing, a conflict
  resolution or a fix-up changes the tree, so it is re-checked.
- **One gate semantics.** At every row the gate exits when the checks are green on the tip
  the review called clean. A red or a blocking verdict goes to a fresh implementer by pointer
  brief and the loop starts over; three such fix-ups per unit, the fourth is `failed`. A
  minors fix-up and a conflict resolution move the tip, so the checks rerun, but no reviewer
  runs again and no budget is spent. The story records the reviewed tip in its notes so a
  rerun knows it; this is a sentence under the gate, not a glossary term.
- **One review tool, spec parametrised.** `mattpocock-skills:code-review` at every row, run
  one tier up (the row's review model: the ticket's tier, the story's tier, the epic's max
  tier). The spec axis takes the row's unit: ticket body, story body, Jira Epic spec. The
  standards axis reviews what entered since the last standards review: the ticket diff at
  the ticket row; conflict resolutions and cross-ticket coherence at the story row; nothing
  at the epic row, where the axis is skipped. The built-in `code-review` leaves the model.
  The Review verdict rule adds one blocking case: no test at a story seam exercises the
  unit's criteria. ADR 0001 is superseded.
- **Landing a ticket.** The ticket orchestrator waits on the owner checkout's lock as the
  merger did, runs the stray-commit check, and merges. A `git merge` that applies is a
  command, not an edit, so it does not break the orchestrator's never-edit rule. A conflict
  goes to an implementer in the ticket's worktree, briefed to merge the integration tip into
  the ticket branch; the orchestrator then fast-forwards. The resolved tree is checked (a
  new tree) and not re-reviewed at the ticket row; the story row's standards axis sees it.
- **The epic row's review and fix-up.** The epic orchestrator runs the review once every
  story reports delivered, one PR at a time in its owner repo, diff from the default branch
  to the integration branch, spec the Jira Epic. PRs stay drafts until the verdict is clean,
  then are marked ready. On a blocking verdict the epic orchestrator cuts the findings
  itself into `ready-for-agent` tickets under the story, one per blocking finding, and
  re-runs that story's orchestrator in add mode; three per story.
- **Six trust rules, a closed list.** Reviewer one tier up; fresh fix-up, same worktree,
  never a message back; an implementer's own check runs never count; stray-commit check
  before every merge and push; only `ready-for-agent` tickets are claimed; the typed command
  authorises delivery. A rule that wants to join needs an ADR.
- **Three documents.** The rules doc becomes the model: roles, the table, the loop, the two
  scoping rules, the six trust rules, the frontier and the tier table, nothing about the
  harness. A new harness doc beside it holds the mechanics (TMPDIR line, Idle rule, Waiting,
  Cut-off agents, Commits, the `-C` discipline, the worktree routes), and every brief cites
  it in one line instead of restating them. The sequences doc shrinks to one diagram of the
  loop beside the table; the three stage diagrams go.
- **Skills follow the table.** `/dev:implement-spec`, `/dev:implement-story` and the ticket
  orchestrator brief each state their row's parameters and pin into the two docs; the merger
  brief, the lint-command resolution and the seam-running procedure are removed; the
  story-review step becomes the gate; the epic review and its fix-up are added to
  `/dev:implement-spec`. `/dev:setup-repo` installs or documents the `check` target. The
  runbook and `/dev:workflow` name the new roles and the one review tool.
- **This repo's Makefile.** `check` is the target that runs everything; `lint` stays as an
  alias for one release. CI runs `check`. The README names `make check`.
- **Glossary.** New: **Ticket orchestrator**, **Epic orchestrator**, **Check command**,
  **Check record**. Redefined: **Check** (one run of the check command on a tree), **Check
  gate** (the one semantics, with the reviewed-tip note as a sentence), **Test seam** (the
  testing boundary, not a check), **Review verdict** (per row; the seam-test blocking case;
  the standards scope), **Stray-commit check** (the orchestrator, no merger), **Story
  orchestrator** and **Driver** (the latter folded into **Epic orchestrator**). Retired as
  terms, kept under `_Avoid_`: **Review marker**, **Ticket runner**, **Driver**, merger,
  fix-up implementer.
- **One ADR**, superseding ADR 0001: one loop at three rows; one check command and every
  tree checked once; one two-axis review with the spec parametrised and standards scoped to
  what entered; the ticket orchestrator lands its ticket. Its considered options are the
  two-tool review ADR 0001 chose, a per-row check list, and a merger kept as a role.

## Testing Decisions

- A good case pins what a doc must say or must no longer say and is proven by a regression
  case that drops or swaps the line and expects the lint to fail; it tests the words an
  agent reads, never how a script is written.
- Seam one: the skill-doc lint under `make check`, extended per doc. Pins: the model doc's
  table and its rows, the loop sentence, the two scoping rules, the six trust rules; the
  harness doc cited by one line in every brief; the implement skills' row parameters, the
  conflict route, the epic review and its add-mode fix-up, the draft-until-clean rule.
  `lacks` for the retired words and phrases in the model docs and skills: merger, ticket
  runner, driver, review marker, test seams as checks, the lint command, the built-in review
  by name, and the stage-five list grown by them. Each with a drop-line or seeded-phrase
  case in the lint's own test. Prior art: the check gate's pins and cases, the review
  verdict pins, the TMPDIR line cases.
- Seam two: the glossary lint, free. The new `_Avoid_` terms make every tracked doc outside
  the specs directory a test of the rename.
- Seam three: the Makefile's `check` target, the CI workflow test asserting the forge runs
  it, and the README test naming it.
- Agent seam, not scripted: one dry run of the rewritten `/dev:implement-story` on the
  stories fixture by a subagent, reading the briefs it produces for the five roles and the
  one-line reports. The first feature run after this one exercises the model for real;
  `/dev:retro` catches what the pins miss.
- No new test script.

## Out of Scope

- The dotfiles repo: its `lint` target stays, so it has no check command under the new
  convention until its own change renames it.
- Serial tickets inside a story; parallelism is kept.
- Any change to the cuts (`/dev:spec-to-stories`, `/dev:spec-to-tickets`,
  `/dev:story-to-tickets`), to triage, to the retro, or to the complexity tier table.
- A configuration line for the check command (manifest or CLAUDE.md); the Makefile
  convention is the only resolution.
- A fixture test of the loop.
- Standards review at the epic row.
- A third review axis or keeping the built-in review for correctness.

## Further Notes

The grill that produced this spec settled every row by asking what each existing rule was
*for*: the merger existed so an orchestrator never resolves a conflict (kept, as the
conflict route); the review marker so a rerun knows a reviewed tip (kept, as a sentence);
the per-role check instructions so no unchecked tree reaches the branch (kept, as "every
tree is checked once"); ADR 0001's two tools so a ticket's review was not vacuous (no longer
true once the ticket's criteria are the spec axis). What remains after that is the table.

The epic review is new behaviour, not a restatement: today the human is the only reviewer
of a delivered PR. Holding PRs as drafts until the epic verdict is clean is what makes the
human's review come after the agents' loop; `/dev:close-story` is unchanged.

The check command convention is the plugin's own. The AGENTS.md format lists build and
test commands as prose with no schema; GNU's `make check` is the one widely known target
name, and it matches the glossary's word.
