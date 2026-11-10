---
status: accepted
---

# The plugin ships no coding standards; they live in the user's rules folders

The plugin shipped a default set of coding standards, `docs/agents/coding-standards.md`,
which the reviewer read on top of a repo's own `CODING_STANDARDS.md`. Only one of its seven
rules was about the plugin's own files. The rest were one person's preferences for any repo
(keep the glossary and the ADRs current, how a doc states a claim, a Rust rule), and a
coworker who installs the plugin got them as if they were part of the workflow. The
implementer was never shown any of them, so a breach was found only at review and cost a
fix-up round.

## Decision

- **The plugin ships no coding standards.** They belong to whoever uses the plugin, in two
  layers: the personal standards in `~/.claude/rules/`, for every repo that person works
  in, and the repo standards in a repo's `.claude/rules/`. Where the two conflict, the
  repo's win.
- **Both layers are Claude Code rule files**, one topic to a file, scoped by path where a
  rule applies to some files only (a Rust rule to `.rs` files).
- **The implementer and the reviewer both read them.** Their briefs name both folders by
  path, and say that the repo's win, so neither depends on what Claude Code loads into a
  subagent. The reviewer's brief keeps a root `CODING_STANDARDS.md` or `CONTRIBUTING.md`
  on its list where a repo has one, and carries how a breach is reported: the rule's
  heading, the file and line, and the reader who would be misled or broken.
- **`/dev:retro` writes to the layer that owns the rule.** A rule for one repo goes to that
  repo's `.claude/rules/`. A rule for every repo is filed as a finding that names the
  `~/.claude/rules/` file, and the routing decides who owns it. The plugin names no tool
  and no repo that puts files in that folder.
- **The seven rules are sorted by owner.** "Another skill's rule is cited in one form"
  stays in this repo, beside "A verified value is the value every later step uses". The
  other six are personal standards. "Bead ids cite provenance in parentheses" is widened
  on the way, from the plugin's docs and lint comments to any doc or comment.

## Considered options

- **Keep the plugin's default set.** Rejected: it ships one person's preferences as the
  workflow, and a user cannot remove a rule without forking the plugin.
- **Standards for the reviewer only, in a root `CODING_STANDARDS.md`.** This is the
  mattpocock-skills convention, and its reason is the implementer's context. Rejected: a
  path-scoped rule file loads only for the files it covers, so the cost is small, and a
  breach the implementer could have avoided costs a review round.
- **Vendoring `mattpocock-skills:code-review` to point it at the two folders.** Rejected:
  the plugin's briefs can name the folders, and ADR 0013's reason against vendoring
  stands.

## Consequences

- A user with no rule files gets no standards beyond the review skill's own baseline.
- The Claude Code docs say a subagent loads project rules; they do not say so for
  user-level rules. That is why the briefs name both folders by path.
- The widened bead id rule flags older sentences that name a bead as their reason outside
  parentheses, when they are next edited.
- The lint's cross-skill cite section and the reviewer-brief pins name the old doc and
  change with it.
- Where a person's `~/.claude/rules/` comes from is machine setup (ADR 0013), outside the
  plugin.
