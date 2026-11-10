# Reference docs move to `references/`; coding standards belong to the user

## Problem Statement

The dev plugin ships two things in one folder, `docs/agents/`, under one name, "rules docs",
and both the folder and the name now mislead.

The first is the three docs every skill reads by path: the orchestration doc, the harness doc
and the tracker doc. They are the plugin's own procedure, and they sit beside `domain.md` and
`triage-labels.md`, which are not the plugin's at all: they are one repo's configuration for
the mattpocock-skills, and every repo that uses those skills has its own pair in its own
`docs/agents/`. A reader cannot tell from the folder which files travel with the plugin and
which belong to the repo they are standing in. The name is worse than the folder. In Claude
Code a rule is a file in a rules folder that Claude Code loads itself. The plugin's "rules
docs" are never loaded that way, and a plugin cannot ship rules, so the name promises a
mechanism the docs do not use.

The second is a default set of coding standards. The reviewer applies it to every diff in
every repo the plugin is used in. Of its seven rules, one is about the plugin's own files.
The other six are one person's preferences for any repo: keep the glossary current, amend the
ADR you contradict, how a doc states a claim, how a bead id is cited, a Rust rule. A coworker
who installs the plugin gets those six as if they were part of the workflow, and cannot
remove one without forking the plugin. The implementer is never shown any of them, so a
breach is found only at review and costs a fix-up round that reading one short file would
have saved.

`/dev:retro` has the same blind spot from the other side. Its only home for a new judgement
rule is a root `CODING_STANDARDS.md` that the reviewer alone reads, and it has nowhere to put
a rule that should hold in every repo a person works in.

## Solution

The three shared docs become the plugin's **reference docs**. They move to a `references/`
folder at the plugin root, skills read them at `${CLAUDE_PLUGIN_ROOT}/references/`, and the
words "rules doc" leave the plugin's prose. `docs/agents/` keeps only this repo's own
configuration for the mattpocock-skills, and every mention of those two files says whose
they are.

The plugin ships no coding standards. They belong to whoever uses the plugin, in two layers
that are both Claude Code rule files: the **personal standards** in `~/.claude/rules/`, for
every repo that person works in, and the **repo standards** in a repo's `.claude/rules/`.
Where the two conflict, the repo's win. The implementer and the reviewer are both told to
read both folders, by path, so the implementer can avoid a breach and the reviewer can still
catch one. `/dev:retro` files a new rule against the layer that owns it.

The decisions are recorded in ADR 0018 (the plugin ships no coding standards) and in the
2026-11-09 amendment to ADR 0013 (the reference docs and their folder).

## User Stories

1. As someone installing the dev plugin, I want it to ship no coding standards, so that my
   repos are reviewed against my rules and not against its author's preferences.
2. As someone installing the dev plugin, I want to keep my own standards in my user-level
   rules folder, so that they apply in every repo I work in without copying them into each.
3. As a repo owner, I want the repo's standards in its own rules folder, so that everyone who
   works in the repo gets them from the checkout.
4. As a repo owner, I want the repo standards to win over anyone's personal standards where
   they conflict, so that the repo is consistent whoever works in it.
5. As a repo owner with a root `CODING_STANDARDS.md` or `CONTRIBUTING.md`, I want the reviewer
   to keep reading it, so that I am not forced to convert it before I update the plugin.
6. As someone with no rule files at all, I want the workflow to run unchanged, so that
   standards are optional and a missing folder is never an error.
7. As an implementer, I want my brief to name both rules folders, so that I read the
   standards before I write and do not learn of a breach from the review.
8. As an implementer, I want a path-scoped rule to reach me only when I touch files it
   covers, so that a Rust rule costs me nothing in a shell repo.
9. As a reviewer, I want my brief to name both rules folders and any root standards file, so
   that I apply every standard that holds in this repo, wherever its owner keeps it.
10. As a reviewer, I want my brief to say how a breach is reported (the rule's heading, the
    file and line, and the reader who would be misled or broken), so that reports stay in one
    form now that the standards doc that said so is gone.
11. As a reviewer, I want to be told the repo's standards win, so that I do not report a
    breach of a personal rule the repo has overridden.
12. As a reviewer reading a rule by path, I want to apply it only where the rule says it
    applies, so that reading the folder directly does not undo a rule's path scope.
13. As a task orchestrator, I want the standards text in the implementer and reviewer briefs
    to match at the task row and the story row, so that the task gate and the story gate hold
    a diff to the same standards.
14. As someone running `/dev:retro` in a repo, I want a new rule for that repo filed against
    a file in the repo's rules folder, so that the fix lands where the rule will be read.
15. As someone running `/dev:retro`, I want a rule that should hold in every repo filed as a
    finding that names the user-level rules file, so that it reaches whoever maintains my
    personal standards.
16. As a plugin user who manages `~/.claude` with a tool the author does not use, or with
    none, I want the plugin to name no tool and no repo that fills that folder, so that the
    retro's finding is right for my setup too.
17. As someone running `/dev:retro`, I want a mechanical breach to still get a check and not
    a rule, so that the move to rule files does not weaken the "build the check" default.
18. As someone running `/dev:retro`, I want its account of who reads the standards to say
    that the implementer reads them too, so that the skill no longer argues for
    reviewer-only standards.
19. As a skill author, I want one folder that holds exactly the docs the plugin's skills
    share, so that I know where a shared procedure goes and what ships with the plugin.
20. As a skill author, I want each reference doc to have one short name (the orchestration
    doc, the harness doc, the tracker doc), so that a cite reads the same in every skill.
21. As a skill author, I want the lint to fail on a path into the old folder for any of the
    three docs, so that a stale path cannot ship.
22. As a skill author, I want the glossary lint to fail on "rules doc" in new prose, so that
    the old name does not come back.
23. As a reader of the plugin repo, I want `docs/agents/` to hold only this repo's
    mattpocock-skills configuration, so that I can tell it from what the plugin ships.
24. As a reader of a skill, I want a mention of `domain.md` or `triage-labels.md` to say it
    is the file in the repo being worked on, so that I do not look for it in the plugin.
25. As a reader of an accepted ADR, I want its text left in the words of its day, so that
    history is not rewritten to fit a rename.
26. As a maintainer of this repo, I want the two rules about the plugin's own files kept as
    this repo's standards, scoped to the files they govern, so that removing the default set
    loses nothing this repo needs.
27. As a maintainer of this repo, I want the root `CODING_STANDARDS.md` gone once its one
    rule has moved, so that this repo keeps its standards in one place.
28. As a maintainer of this repo, I want the lint's version-bump rule to watch the new
    folder, so that a change to a reference doc cannot merge without a bump.
29. As a maintainer of this repo, I want the lint's missing-document rule to follow the docs
    to their new folder, so that a deleted reference doc still fails the check.
30. As a maintainer of this repo, I want the lint's cross-skill cite rule to follow that rule
    to its new file, so that the pin survives the move.
31. As someone setting up a machine, I want the user-level `CLAUDE.md` stub to name the
    reference docs and their folder, so that the text I paste describes the plugin I
    installed.
32. As someone reading the README or the runbook, I want them to say where the reference
    docs live and that coding standards are the user's, in two layers, so that I learn the
    layout without reading an ADR.
33. As someone reading the glossary, I want entries for reference doc, personal standards and
    repo standards, and no entry that still points at the deleted standards doc, so that the
    vocabulary matches the plugin.
34. As someone updating the plugin, I want the version to say this release changes what the
    plugin ships, so that I know to refresh my machine setup.
35. As Kai, I want this release to land after my personal standards are deployed on my
    machines, so that the six rules are never unenforced in my own repos.

## Implementation Decisions

**The reference docs**

- The orchestration doc, the harness doc and the tracker doc move to a `references/` folder
  at the plugin root. The move is hard: nothing is left at the old paths, no stub and no
  redirect. An installed copy is a whole version in the plugin cache, so the two layouts
  never coexist on a machine.
- Every place that addresses one of the three follows the move: skills, the docs themselves,
  the runbook and the sequences doc, the README, hook and script comments, the lint and its
  tests, and the fixtures. A skill addresses a reference doc as
  `${CLAUDE_PLUGIN_ROOT}/references/<doc>`, resolved as the Plugin root rule already says.
- They stay a folder that skills read by path. There is no hub skill that other skills load,
  and nothing loads them automatically.
- The set is called the reference docs. Each has one name: the orchestration doc, the
  harness doc, the tracker doc. "The rules doc", which today means the orchestration doc in
  most skills, and "the model doc" become "the orchestration doc". Section names inside the
  docs do not change.
- The glossary's Reference doc entry lists "rules doc" under its avoided terms, in the same
  change that removes the last use, so the glossary lint is green at every commit.
  Accepted ADRs keep their text and are exempted in the glossary lint's allow list, one line
  each with its reason.
- `docs/agents/` keeps `domain.md` and `triage-labels.md`. Every mention of either in a skill
  or a reference doc names it as the file in the repo being worked on (that repo's
  `docs/agents/`), never as a sibling of the reference docs.

**The standards**

- The default standards doc is deleted. No skill, doc or lint names it afterwards.
- Every brief that starts an implementer or a reviewer, at the task row and the story row
  and in the orchestration doc's own account of them, names both rules folders by path:
  `~/.claude/rules/` and the `.claude/rules/` of the repo being worked on. The brief says the
  repo's standards win where the two conflict, that a missing or empty folder is not an
  error, and that a rule read this way applies only where the rule's own text or path scope
  says it does.
- The epic row is unchanged. Its review runs the spec axis only and names no standards
  (ADR 0014); a finding it files becomes a task, which the task row holds to the standards.
- The briefs name the folders by path because the Claude Code docs say a subagent loads
  project rules and do not say so for user-level rules. The briefs must not depend on what
  the harness loads.
- The reviewer's brief also keeps a root `CODING_STANDARDS.md` or `CONTRIBUTING.md` on its
  list where the repo has one, counted with the repo's standards, and carries the breach
  report form: the rule's heading, the file and line, and the reader who would be misled or
  broken. The implementer's brief names the two folders only.
- The review skill itself, `mattpocock-skills:code-review`, is not vendored and not changed.
  The plugin's briefs carry everything.
- The seven rules of the deleted doc are sorted by owner. "Another skill's rule is cited in
  one form" becomes a rule file in this repo's `.claude/rules/`, and so does "A verified
  value is the value every later step uses" from this repo's root `CODING_STANDARDS.md`,
  which is then deleted. Each is one file, scoped by path to the plugin files it governs.
  The other six rules leave this repo. They are Kai's personal standards and are delivered
  by a separate feature in the dotfiles repo.
- The glossary's Provenance cite entry stops pointing at the deleted doc and stops limiting
  the cite to "rules-doc" sentences.

**The retro**

- In the coding standards category, a judgement rule for one repo is a finding whose location
  is a file under that repo's `.claude/rules/`: one topic to a file, path-scoped where the
  rule covers some files only. A rule that should hold in every repo is a finding whose
  location is the `~/.claude/rules/` file, existing or proposed. Its label follows the
  tracker doc's existing "capture a retro item" rule for a file outside the home. No new
  routing rule is added, and the skill names no tool and no repo that deploys that folder.
- The skill's reference text changes with it: the standards are read at implementation and
  at review, the rules folders replace `CODING_STANDARDS.md` in its list of files, and the
  default stays that a mechanical breach gets a deterministic check before any rule.

**The lint and the release**

- The skill-doc lint follows all of the above. Its missing-document rule covers the three
  docs at their new folder. A path to one of them under the old folder fails, in a skill or
  a doc. The reviewer-brief pin is replaced by a pin on both briefs naming both rules
  folders. The cross-skill cite section reads that rule from its new file. The version-bump
  rule watches `references/` beside the paths it watches today. Its environment overrides
  are renamed where their names say "agent docs".
- The user-level `CLAUDE.md` stub that `/dev:setup` hands over names the reference docs and
  `references/`.
- The README and the runbook say where the reference docs live, and that coding standards
  are the user's, in the two layers. `/dev:setup` and `/dev:setup-repo` create no rules
  folder and write no starter rule.
- The release is a minor version bump: it changes the layout the plugin ships, the text of
  the machine setup's stub, and what a reviewer applies by default.
- The records drafted with the design are part of this feature: ADR 0018, the amendment
  note on ADR 0013 (which gains this feature's bead and Jira ids) and the three glossary
  entries. They are in the checkout, uncommitted, when this spec is published.

## Testing Decisions

- A good test drives the lints and the skills from outside: the exit code and message of a
  lint run on fixture skill docs, and the fixture tests that run a stage against a throwaway
  beads database. No test greps a skill for a phrase outside the lint's own pins, and each
  new pin comes with a fixture that breaks it.
- There is one seam, `make check` in this repo.
- The skill-doc lint and its regression test gain cases: a skill or doc that names a
  reference doc under the old folder fails, naming the file; an implementer brief or a
  reviewer brief that omits either rules folder fails; a missing reference doc under
  `references/` fails as a missing document; a change under `references/` without a version
  bump fails on a branch.
- The glossary lint gains its case through the glossary itself: with "rules doc" under the
  avoided terms, any leftover use in prose fails, and the allow-listed ADRs pass.
- The retro fixture test gains two cases: a finding for a personal rule names the
  `~/.claude/rules/` file in its body and carries the label a file outside the home gets; a
  finding for a repo rule names a file under the repo's `.claude/rules/` and carries the
  home's target label.
- Prior art: the lint's regression test and its fixture skill docs, the retro fixture test,
  and the glossary lint's own test.
- One check is by hand and decides nothing: a throwaway rule file in `~/.claude/rules/`, and
  a subagent asked whether it can see it. The result goes in ADR 0018's consequences. The
  briefs name the folders by path whichever way it comes out.

## Out of Scope

- The six personal rules as files, and how they reach `~/.claude/rules/` on Kai's machines.
  That is the dotfiles feature INFRA-44.
- Removing the plugin's remaining coupling to chezmoi in the deployed-file rule (bead
  `dev-srqp`).
- Vendoring the mattpocock-skills, or moving their per-repo configuration into
  `references/`.
- A hub skill that loads the reference docs, or any automatic loading of them.
- Scaffolding a rules folder or a starter rule in `/dev:setup` or `/dev:setup-repo`.
- Converting any other repo's `CODING_STANDARDS.md` into rule files.
- Rewriting the text of accepted ADRs to the new names.
- Refreshing the stub in Kai's dotfiles after the release. The dotfiles repo's setup drift
  check reports it once the new version is installed, as it does for every stub change.

## Further Notes

- Order: the dotfiles feature lands first, so the six rules are in `~/.claude/rules/` before
  this release deletes them from the plugin. While both exist, the reviewer sees those rules
  twice, which is harmless.
- That the repo's rules take precedence over the user's in Claude Code is recalled, not
  checked against the docs here. The briefs state the precedence themselves, so the workflow
  does not depend on it.
- The dotfiles feature widens "Bead ids cite provenance in parentheses" from the plugin's
  docs and lint comments to any doc or comment. Older sentences in this repo that name a
  bead as their reason outside parentheses are flagged when they are next edited, not all at
  once.
- An agent's sandbox can read `~/.claude/rules/` and cannot write it. That is one more
  reason the retro files a finding for a personal rule and does not write the file.
- Writing files under this repo's `.claude/rules/` from a sandboxed shell works. Whether the
  edit tool prompts for that folder was not tested.
