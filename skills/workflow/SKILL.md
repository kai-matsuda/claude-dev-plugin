---
name: workflow
description: Print the human runbook for the Jira + beads feature workflow (grill → spec → story cut → tasks → implement → close-epic) and say where each open epic is in it.
disable-model-invocation: true
---

Read `${CLAUDE_PLUGIN_ROOT}/docs/WORKFLOW.md` and present the whole file as-is. Ignore any argument.

Then report the repo's position in the flow, from beads only — no Jira, forge, or git
calls. Print, don't act: the next command is always the user's to type.

- No `.beads/` in the working directory → one line, "prerequisites (top of the runbook)".
  Stop.
- `bd list -t epic -s open,in_progress --json`, dropping any bead labelled
  `wayfinder:map` (a map is not a feature). None left → "nothing in flight — start at
  `/mattpocock-skills:grill-with-docs`", and go on to the standalone tasks below (stop there
  only when they print nothing either).
- For each remaining epic, print one line:

  `<bead-id> (<KEY>-<n>) "<title>" — <position> · next: <command>`

  `<KEY>-<n>` is the bead's external ref; omit the parenthesis when it has none. `<arg>` in
  the next commands below is `<KEY>-<n>`, or `<bead-id>` when it has none: the argument
  `/dev:spec-to-stories`, `/dev:spec-to-tasks` and `/dev:implement-spec` take, printed filled in so
  the user types the line as-is.

## Standalone tasks

A **standalone task** is an open task bead with no parent, such as an accepted retro item or a
small bug; a story's tasks have a parent and are positioned under their story. Run
`bd list -t task -s open --json` and keep the tasks with no parent. For each, print one line,
with its id filled in:

`<task-id> (<KEY>-<n>) "<title>" — standalone task · next: /dev:implement-task <task-id>`

Print the `<KEY>-<n>` parenthesis only when the bead has an external ref, as for epics. Print
the `next:` form as-is; `/dev:implement-task <task-id>` takes the bead id, not `<KEY>-<n>`. Print
these lines after the epic lines, under a `standalone tasks:` heading, and only when at least one
is open.

## Malformed epic

Check the epic by the malformed-epic refusal of the tracker doc's "gather the epic bead". A
malformed epic is reported by this skill and not positioned. Print
`<epic-id> (<KEY>-<n>) "<title>" refused: <child-id> is not a story`, suggest
nothing, and go to the next epic.

## Position of a story-shaped epic

**Gather the stories** the way `/dev:implement-spec`, `/dev:spec-to-tasks` and `/dev:close-epic` do: the "Stories" gather of "fetch the relevant
task" in `${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md`, its fallback and failure rules
included. A sweep that stops there is reported on that epic's line, and no position is
printed for it, since that repo's unfinished story would otherwise drop out.

A story's **tasks** are its children, read in its owner repo `<owner>` (the absolute
path of the repo it was found in; `<owner repo>` is its manifest entry name):
`bd -C <owner> list --parent <story-id> --all --json`. A story is **finished** (the
`${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md` term) when every child is `closed` or carries `ready-for-human`,
`needs-triage` or `wontfix`, and its notes (`bd -C <owner> show <story-id> --json`,
`.[0].notes`) hold a `pr:` line.

The position is the first row that holds:

| The epic's stories | position · next |
|---|---|
| none | after `/mattpocock-skills:to-spec` · next: `/dev:spec-to-stories <arg>` |
| some story has no tasks | after the story cut · next: `/dev:spec-to-tasks <arg>` |
| no task `in_progress` or `closed` | after `/dev:spec-to-tasks` · next: `/dev:implement-spec <arg>`, or `/dev:implement-story <story-id>` in one story's repo |
| some story not finished | in stage 4 · next: `/dev:implement-spec <arg>`, or `/dev:implement-story <story-id>` in that story's repo |
| every story finished | PRs delivered · once they merge: `/dev:close-epic` |

Under rows 3 and 4 (after `/dev:spec-to-tasks` and stage 4), print `bd -C <owner> ready --parent <story-id>`
as-is for each story not finished; its `complexity:` labels are what to set `/model` from.
In stage 4 also print each unfinished story, one per line: `<owner repo> <story-id> <title>`.
Under row 5, list any open `ready-for-human` task the same way, since `/dev:close-story`
refuses while one is open. Under row 2, name each story that has no tasks.
