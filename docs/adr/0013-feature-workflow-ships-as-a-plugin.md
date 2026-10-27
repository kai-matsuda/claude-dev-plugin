---
status: accepted
---

> Amended 2026-10-26 (dev-iyr, INFRA-33): the fixture tests no longer stay local. With
> `0014-one-loop-at-three-rows.md`'s single check command, GitHub Actions calls `make check`,
> which runs `make ci` and the fixture tests side by side; `make lint` is a deprecated alias
> of `make check`. The last consequence below describes the setup before that change.

# The feature workflow ships as a Claude Code plugin, not as dotfiles

The feature workflow lived in the chezmoi source of `vangogh500/dotfiles` and reached a machine with `make apply`.
That reaches a second personal machine in one command, but not a work machine, where a
personal dotfiles repo (shell, ssh, git identity) has no business, and not a coworker. The
unit that should travel is the workflow alone: its skills (13 today), the rules docs and runbook, the
glossary and ADRs, and the `guard-rm` and `bd prime` hooks. A Claude Code plugin carries
exactly that set and nothing a machine owner would need to review, so the workflow moves
to its own public, MIT-licensed repo, `claude-dev-plugin`, which is both the plugin and
its marketplace, and is installed from that marketplace on every machine, Kai's included.
Skills become `/dev:<skill>`; the rules docs are addressed as
`${CLAUDE_PLUGIN_ROOT}/docs/agents/...`.

A plugin cannot carry a user-level `CLAUDE.md`, permission or sandbox settings, or a git
hook under `~/.config/git`. Those three stay per machine as the machine setup: `/dev:setup`
checks the prerequisites (`bd`, `gh` or `tea`, `jq`, mattpocock-skills, the Atlassian MCP) and
hands over the stub and the baseline settings snippet to paste; chezmoi keeps applying
them on Kai's machines. The baseline carries nothing org-specific. Per-repo configuration
stays where it was: the Jira project key in the repo's `CLAUDE.md`, written by
`/dev:setup-repo`, is the single configuration point, so a work repo and a personal repo
differ in one line and no Jira instance is named anywhere.

## Considered options

- **chezmoi on every machine.** Already works for the mac mini. Rejected: it carries the
  whole personal environment onto a work machine and gives a coworker nothing to install.
- **Plugin manifest inside the dotfiles repo.** One repo, no move. Rejected: the
  marketplace would be the dotfiles repo, so a coworker clones shell and ssh config to get
  skills, and every path would exist in both the chezmoi and the plugin form.
- **Vendoring the mattpocock-skills forks.** Would make the plugin self-contained.
  Rejected for now: `code-review`, `pr` and `tdd` are in the official marketplace and the
  skills were derived from it; vendoring freezes them at 1.3.1. It is listed as a
  prerequisite and revisited if the dependency bites.
- **One setup skill for machine and repo.** The precedent has one. Rejected: the halves
  differ in when they run, where, what they write and who runs them; one skill would
  re-check the machine on every repo.

## Consequences

- Every bare `/dev:implement-story`-style reference, about 250, is rewritten to `/dev:...`,
  about 30 user-level rules-doc paths to `${CLAUDE_PLUGIN_ROOT}/docs`, and the skill-doc
  lint's namespace rule allows `dev:` and `mattpocock-skills:` only.
- Machines run the cached version until an update: the semver in `plugin.json` is bumped
  on every merge to main (patch for wording, minor for a new or renamed skill, major for
  a change to the beads or Jira contract), no tags, and the lint refuses a change under
  `skills/` or `docs/` that leaves the version alone. Development runs Claude Code in the
  plugin repo with `--plugin-dir .`.
- The cutover is hard: the dotfiles PR that enables the plugin also deletes the skills,
  docs, hook and their tests, and lands only after a fresh marketplace install works on
  Kai's machine, so the bare and `dev:` forms never coexist.
- The move is a fresh first commit citing the dotfiles repo and the commit it came from,
  not a history rewrite. ADRs 0001 to 0012 move with the workflow; the dotfiles repo's
  `docs/adr/` keeps a one-line pointer to this ADR. The `repos.yaml` rename bead moves to
  this repo's beads; the Atlassian MCP settings bead stays in dotfiles.
- The work runs as two features: the content move as a one-story feature in the plugin
  repo once it is bootstrapped by hand, and the dotfiles cutover as a second feature in its
  own repo session, since a repo session refuses a two-repo spec (ADR 0008).
- The lint and the guard-rm test run in `make ci`, the target GitHub Actions calls; the
  fixture tests stay local (`make lint`) until the rest is stable.
