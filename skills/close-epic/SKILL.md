---
name: close-epic
description: "Stage 6 of the feature workflow: after the PRs have merged, close each story, then the epic bead, and move the Jira Epic to done."
disable-model-invocation: true
---

Closes out one feature whose PRs have merged. A driver: `/dev:close-story` verifies and closes
each **story** (GLOSSARY.md), this skill closes the **epic bead** after them and updates the
Jira Epic. The rules it enforces are in `${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md`, under
"When a skill says 'close the epic'". Every precondition refuses rather than proceeds, with
no override flag: the remedy is a visible action the user takes first. Jira never sees
individual tickets or stories.

## 1. Pick the epic bead

Before any `bd` call, check `test -d <home>/.beads` (`<home>` and the session mode are as
**the one test** in `issue-tracker.md`'s opening defines them): without it, plain `bd`
climbs to an ancestor's database (another home's inbox). Missing →
`refused: no beads database in <home>`, and stop.

With an argument: a bead id → `bd show <id>`; a `<KEY>-<n>` → `bd list --type epic
--external-ref <KEY>-<n>`. Without one: `bd list -t epic -s open,in_progress --json`, drop
beads labelled `wayfinder:map`, and in a repo session keep those with at least one child (a
workspace session's epic has no children by design, so keep every one). Exactly one → use
it. Several → list them and ask which. None → say so and stop.

## 2. Gather the stories

Run the "Stories" gather of "fetch the relevant ticket" in `issue-tracker.md`, its fallback
and failure rules included. Keep each story's `<owner>`, its owner repo's absolute path; in
a repo session the only story is the home story and its owner is `<home>`. Skip
`retro`-labelled beads (issue-tracker.md).

Check for a **flat epic** separately: `bd list --parent <epic-id> --all --json` is the
epic's direct children (none in a workspace session); the `--all` is load-bearing, since
`bd list` hides closed beads. A non-story among them →
`<id> refused: flat epic (tickets directly under the epic bead); the story skills do not handle it — the small-bug path does: /mattpocock-skills:implement <ticket-id> per ticket, then bd close <epic-id>`
and stop. The gather above finding no story → refuse, naming the epic; empty direct
children alone is not a refusal.

## 3. Close each story

For every story, call `/dev:close-story` in this session through the Skill tool with the story
id and its `<owner>`, and read the outcome line it ends on: `<id> closed: <pr value>`,
`<id> already closed`, or `<id> refused: <reason>`. Run every story, so every refusal gets
reported; `/dev:close-story` puts its explicit-yes question to the user, and the user answers it.

Any refusal → list each as `<id> refused: <reason>` and stop: the epic bead stays open and
Jira is untouched. The user fixes what it names and reruns; closed stories are skipped on the
rerun.

## 4. Close the epic

A story's **pr value** is the one on its outcome line (`closed: <pr value>`); for `already
closed`, the last `pr:` line of `bd -C <owner> show <story-id> --json` (`.[0].notes`).

1. `bd close <epic-id> --reason "<each story's pr value>"`.
2. The epic bead has no external ref, or `getJiraIssue` on it finds no such issue → report
   the Jira steps as skipped, and why. Any other Jira error → report it; don't treat it as
   a missing issue.
3. `addCommentToJiraIssue` on `<KEY>-<n>`: every story's pr value once, and a one-paragraph
   summary of what shipped. Then `getTransitionsForJiraIssue`, and `transitionJiraIssue`
   with the transition whose target status category is *Done*. Zero or several candidates
   → show them and ask, never guess. Already in a Done-category status → skip, say so. A
   transition that fails on a required field (resolution, a screen) → report the error;
   don't invent a value.
4. Report: epic id, each story as `<repo> <id> <outcome>` with its `pr:` value, and the Jira
   key with its new status (or that the Jira steps were skipped, and why).
