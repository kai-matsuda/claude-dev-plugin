# Every tree is checked once: the check record becomes a script

## Problem Statement

A feature's trees are checked far more often than the rules allow. The rules doc says every
tree is checked once green and names a check record, keyed by the tip's tree SHA under the
owner checkout's scratch directory, that any orchestrator at any row reads before it spends
a check run. In practice no record is ever written: the last three days of this repo's own
bead-driven PRs left no `.tmp/checks/` behind, only ad-hoc logs named by whichever agent ran
`make check` that time. The rule asks each orchestrator to assemble a seven-part compound
shell command from prose, and none does, so every row re-runs the full check on trees that
were already green.

Three other layers add to the bill. The implementer runs the full check command itself
before it reports, and under trust rule 3 that run counts for nothing, so the task
orchestrator runs the same tree again. The forge re-runs the pushed tip, which the story
gate just passed. And the check command itself takes 5-10 minutes in the owner repos (82s
in this one, one script being the whole critical path), so each repeat is felt.

The word "checks" has also been standing in for three different things: the orchestrator's
recorded check, the forge's run, and the implementer's own test runs, which the glossary
did not name.

## Solution

The check record stops being a compound command the orchestrator remembers and becomes one
script the dev plugin ships. An orchestrator runs the script on a worktree and gets the
record line back: a tree with a green record returns at once, any other tree runs the
check command, writes the record and its log, and prints the record line, with the tail of
the log on a red. The skip and the record are side effects of running the script, so they
cannot be forgotten.

The implementer never runs the check command or the script; it does **seam runs**, its own
test runs at its unit's test seams, as many as it likes, and the orchestrator's one script
run is the first and only full check of that tree. The forge's run stays as the one
independent check. The check command stays `make check`, in every repo, and is never split
into a faster subset; the only permitted asymmetry is a `ci` target that extends `check`
with steps the forge alone can run, stated as a rule now so the name cannot drift, and this
repo's own `ci` target, which means the opposite, goes.

## User Stories

1. As a task orchestrator, I want one script call to check a worktree's tip, so that I never assemble the record command from prose.
2. As a task orchestrator, I want the script to return at once on a tree with a green record, so that a tree already checked at another row costs me nothing.
3. As a task orchestrator, I want the script to print the record line and, on a red, the last forty lines of the log, so that one Bash call is all a check costs my context.
4. As a story orchestrator, I want the script to accept the owner checkout as the worktree when the owner is on the integration branch, so that the story gate and the conflict-resolution check use the same call.
5. As a story orchestrator, I want the script's record to be the one the delivered-tip note and the PR's Evidence cite, so that the record stays the proof of the delivered tree.
6. As an orchestrator at any row, I want a red record to skip nothing and be replaced by the next run, so that a flaky red never sticks to its tree.
7. As an orchestrator, I want the script to place the check's `TMPDIR` inside the worktree, so that a check's scratch files never land in the owner checkout or the system temp directory.
8. As an orchestrator, I want the script to refuse a worktree that is not a git checkout or an owner with no `check` target with one line, so that a misbrief fails fast instead of writing a record for nothing.
9. As an implementer, I want my brief to tell me to run seam runs and never the check command or the script, so that my build loop stays short and I never duplicate the gate.
10. As an implementer on a standalone task with no test seams, I want my brief to tell me to run the tests of the modules I touch, so that I still have a fast loop.
11. As a reviewer, I want the glossary to name a seam run, so that my findings can say which kind of run is missing without calling it a check.
12. As a repo owner, I want `make check` to stay the one gate in every repo, so that the forge, the orchestrators and I at the terminal run the same thing.
13. As a repo owner whose forge needs a step the gate cannot run locally, I want a rule that lets me add a `ci` target extending `check`, so that the extension has one name and one shape.
14. As a repo owner, I want `/dev:setup-repo` to write no `ci` target, so that the extension exists only where a repo needs it.
15. As a plugin maintainer, I want this repo's `ci` target, a subset of `check`, removed, so that the name means one thing.
16. As a plugin maintainer, I want the script tested on scratch repos, so that green skip, red rerun, record contents and placement cannot regress silently.
17. As a plugin maintainer, I want the skill-doc lint to pin that the rules doc and the orchestrator skills name the script and not the compound command, so that the prose cannot drift back.
18. As a plugin maintainer, I want the lint to pin that implementer briefs say seam run and never the check command, so that the duplication cannot return through a brief.
19. As a plugin maintainer, I want ADR 0015 to carry the `ci` extension rule as an amendment, so that a future reader sees why `ci.yml` runs `make check` and when a `ci` target is allowed.
20. As a person watching a run, I want the record directory to be left alone by the clean-up step, so that a record outlives the run that wrote it and a resumed run can read it.
21. As a person debugging a red, I want the log of every checked tree kept under the owner's scratch directory keyed by tree SHA, so that I can read the full log of the tree the orchestrator named.

## Implementation Decisions

- **One script, shipped by the dev plugin**, invoked by orchestrators as `<plugin root>/scripts/check.sh <worktree path> <owner>`; briefs already carry `<plugin root>`. It computes the tip's tree SHA of the worktree, reads `<owner>/.tmp/checks/<tree>/record`, and exits 0 printing that record line when it reads `exit=0`. Otherwise it creates the worktree's `.tmp` and the record directory, exports `TMPDIR` as the worktree's `.tmp`, runs `make -C <worktree path> check` with its output to the tree's `log`, writes `command=make check exit=<n>` to `record`, prints the record line and, on a non-zero exit, the last forty lines of the log. Its exit status is the check's. A worktree that is not a git checkout, or an owner whose Makefile has no `check` target (the rules doc's make database query), is one refusal line and a non-zero exit with no record written.
- **The record's shape and place are unchanged**: `<owner>/.tmp/checks/<tree SHA>/{record,log}`, the record one line `command=make check exit=<n>`. Only an orchestrator runs the script, so trust rule 3 keeps its wording; a record written by anything else still counts for nothing, and nothing in the plugin writes one but the script.
- **The rules doc's Check record paragraph names the script** and drops the compound command; the task and story orchestrator skills, and `/dev:implement-task`, point at it wherever they run the check command. The glossary's **Check command** stays `make check`; the script is how an orchestrator runs it, not a new command.
- **Implementer briefs** at every row say: seam runs at the unit's test seams (the tests of the touched modules for a standalone task that names none); never the check command, never the script. The glossary's **Seam run** term (already published) is the word they use.
- **Records are never pruned.** The clean-up steps leave `<owner>/.tmp/checks/` alone; the directory is gitignored and a person prunes it by hand.
- **The `ci` extension rule**, stated once in the rules doc's Check command paragraph: `make check` is the gate everywhere and the forge runs it; a repo whose forge needs steps it cannot run locally may add a `ci` target whose first prerequisite is `check` plus those steps, and its workflow then runs `make ci`; `ci` is never a subset of `check`; no other repo has a `ci` target and `/dev:setup-repo` writes none. ADR 0015 gains a short amendment note recording this as the one permitted extension of its "one command" decision. No lint on other repos' `ci` targets until a second repo has one.
- **This repo's Makefile** loses its `ci` target (the subset without the fixture tests); `make check` and `make fixtures` stay. `ci.yml` keeps running `make check`.
- The forge-check wait, the check gate's loop, the fix-up budget and the tree-SHA key are unchanged.

## Testing Decisions

- A good test runs the shipped script against scratch repos and reads what it left behind and printed; it never reads the script's source. Prior art: `scripts/test-check-target.sh` and `scripts/test-guard-rm.sh`, which test a shipped command on scratch repos through `scripts/fixture-test-lib.sh`'s `fx_check`.
- **The script test** (new, `scripts/test-check-script.sh` or like, added to the Makefile's `ci_steps`) covers: a first run on a tree writes `record` and `log` and prints the record line; a second run on the same tree runs no make and prints the same line; a red run leaves `exit=<n>`, prints the log's tail, and a third run re-runs make; a commit that changes nothing in the tree hits the record; a changed tree misses it; the worktree being the owner itself; `TMPDIR` inside the worktree during the check; the two refusals.
- **The skill-doc lint** (`scripts/lint-skill-docs.sh`, tested by `scripts/test-lint-skill-docs.sh`) pins: the rules doc's Check record paragraph names `scripts/check.sh` and holds no `mkdir -p <owner>/.tmp/checks` compound; the orchestrator skills and `/dev:implement-task` name the script where they run the check; implementer briefs say "seam run" and carry the never-the-check-command sentence; the Check command paragraph carries the `ci` rule; `/dev:setup-repo` says it writes no `ci` target.
- `scripts/test-ci-workflow.sh` gains one check: the Makefile has no `ci` target.
- No story-run fixture: none briefs an implementer and an orchestrator end to end today, and the script cannot run without writing the record, so the script test covers it.

## Out of Scope

- Shortening any owner repo's check command (home-infra, the `chain-*` repos, this repo's 82s lint test). Each is its own feature in its own repo, cut after its critical path is measured; none is checked out on this machine yet.
- A CI-side cache keyed by tree SHA, or any local-record shortcut past the forge-check wait.
- A lint over other repos' `ci` targets.
- Letting an implementer's run write a record (would break trust rule 3 and needs an ADR).
- Pruning old records.

## Further Notes

- Evidence for the diagnosis: this repo's `.tmp/` holds `b3p-check.log`, `check-xc2.log`, `check-run.log` and others from the last week's runs, and no `.tmp/checks/`.
- The glossary term **Seam run** was published ahead of this spec (PR #60).
- `pre-check` is not on the seam run's avoid list because the Forge decision already uses it for its remote pre-check.
