---
name: triage
description: "Decide the inbox with the user: accept or reject each needs-triage bead, then route the accepted ones to the owning repo's beads with acceptance criteria and a complexity tier."
disable-model-invocation: true
---

Works the **inbox**: the `needs-triage` beads in the home's beads database (**the one
test** in the tracker doc's (`${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md`) opening: the workspace's in a workspace session, the repo's in
a repo session), filed by `/dev:retro` or by hand. A human accepts or rejects each one; you
make the accepted ones implementable the way `/dev:story-to-tasks` makes a story implementable:
acceptance criteria, a complexity tier, and a bead in the repo that owns the change. The
accept question in step 4 is the point of this skill, so it runs only with the user
present.

Vocabulary (`${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md`): **inbox**, **retro item**, **repo manifest**,
**workspace**, **home**. In a workspace session a `bd -C <owner>` write lands outside the
session's repo; the tracker doc's "bd writes outside the session's repo" says what the
sandbox allows. A repo session runs plain `bd` only.

## 1. Load the inbox

Apply the one test. No database in `<home>` by the tracker doc's "Has a database" rule
("First time in a repo") → stop; no skill initialises a database
unattended, and plain `bd` would climb to an ancestor's. In a workspace session read the
manifest; there is no manifest in a repo session. Then, plainly, in `<home>`:
`bd list -l needs-triage -s open --json`. An argument narrows it: a label such as
`retro`, or bead ids. Nothing open → say the inbox is empty and stop.

## 2. Collapse repeats

`bd find-duplicates` over the open beads. It has no label filter, and a repo session's
home also holds the feature's epic, stories and tasks, so keep only pairs where both
beads carry `needs-triage`. Each such pair → `bd duplicate <later> --of <earlier>`, and
the earlier one gains a recurrence. Then, per survivor, search the owner:
`bd -C <target repo> search "<title words>"` for a manifest repo in a workspace session,
plain `bd search "<title words>"` when the owner is `<home>` (`target:<home name>`, or
any item in a repo session). An open inbox bead never counts as "already tracked": a
search of `<home>` also finds the inbox itself, so only a bead without `needs-triage`
counts. An open bead that already covers the fix → close the inbox bead with
`--reason "already tracked: <owner repo> <id>"`. Done when no two open inbox beads
describe one fix.

## 3. Present

Numbered, in the inbox's severity order. Per item, the five tests a human needs to decide
in seconds:

- **Moment**: the point in the session it traces to, from the bead body.
- **Recurrence**: how many moments it has gathered (notes from `/dev:retro`, duplicates from
  step 2). One is a candidate; two is a pattern.
- **Layer**: check, standard, pointer, skill, or access, and whether that is the right
  layer for the violation. A mechanical violation belongs in a check; a judgement call in
  the reviewer's standards; a line in `CLAUDE.md` only when it is a pointer.
- **Blast radius**: blocks every commit, or stays local to the agent's environment.
- **Owner**: in a workspace session, the repo from the `target:` label, confirmed against
  the manifest (`target:<home name>` needs no entry: the workspace root owns it);
  `unknown` → apply the manifest header's resolution order to the file named in the
  body; still nothing → ask, and a file outside every manifest repo and the root is
  **foreign**. In a repo session it is always `<home>`; a `retro:foreign` item means the
  fix lives outside it and a person carries it across.

## 4. Ask

AskUserQuestion, multi-select, "Which of these do you accept?", up to four items per
question and four questions per call; repeat until every item has an answer. Ticked →
accepted. Unticked → rejected. Free text naming an item as deferred or needing more
information → it stays `needs-triage`, gains `needs-info`, and the text goes on it with
`bd note`. Done when every open inbox bead has one of the three outcomes.

## 5. Route the accepted

Per accepted item, the tracker doc's "route a triaged item" section has the commands; this
is what goes into them.

1. **Owner path**: in a workspace session, `<owner>` from the manifest, or `<home>` when
   the file is the workspace's own or foreign (step 3). In a repo session, `<home>`. An
   owner other than `<home>` with no database by the tracker doc's "Has a database" rule
   → say so; when its `.beads/` is missing, run that doc's "First time in a repo" only on
   the user's yes, since it commits there. Without a database after that, skip the item:
   it stays open in the inbox, and nothing is created for it.
2. **Body** in the `to-tickets` issue template. "What to build" is the behaviour the
   environment will have afterwards, from the agent's point of view. Acceptance criteria
   are checkable without the original session: the check fails on a seeded violation; a
   fresh session follows the pointer; the reviewer cites the new rule. Name no file paths
   in the body except the one file the fix changes.
3. **Tier** from the complexity table, rounding up. **Ready label**: `ready-for-agent`, or
   `ready-for-human` when the fix needs a person: an access grant, a tool install, a vendor
   dashboard. A `retro:foreign` item is always `ready-for-human`, and so is a foreign one
   in a workspace session; either keeps its intended location in the body.
4. Create the bead in the owner repo, then close the inbox bead with `--reason "routed:
   <owner repo> <new id>"`: the tracker doc's two routing commands, unchanged when the
   owner is `<home>`. A new bead and a closed inbox bead, never a relabel in place.

Rejected items: `bd label add <id> wontfix`, then `bd close <id> --reason wontfix`. Done
when every accepted item has a bead in its owner repo and no accepted or rejected inbox
bead is still open.

## 6. Tell the humans

Workspace session only; a repo session has no manifest, so skip and say nothing. The
manifest's `triage.jira-epic` names a standing Jira epic → one `addCommentToJiraIssue`
on it listing each routed item (title, repo, bead id, ready label) and the count rejected.
Absent → skip and say so once. Never an issue per item.

## 7. Report

One line per inbox bead handled:

`<inbox id> → <repo> <new id> complexity:<tier> <ready label>` · or `wontfix` · or
`needs-info`

Then what to type next: `/dev:implement-task <id>` in the owner repo, or `bd -C <repo> ready` to
see it on that repo's frontier.
