# claude-dev-plugin

The `dev` plugin for Claude Code: a Jira + beads feature workflow. One Jira Epic per
feature for people; beads for the agent's stories and tickets; skills that cut a spec
into stories and tickets, implement them AFK through story orchestrators and ticket
runners, review, open the PR, and close the loop with retro and triage.

Skills are addressed as `/dev:<skill>`. Start with `/dev:workflow` for the runbook.

## Install

Two forms. Pick one.

**Marketplace install**, from inside Claude Code:

```
/plugin marketplace add vangogh500/claude-dev-plugin
/plugin install dev@claude-dev-plugin
```

or declare the marketplace and plugin in `~/.claude/settings.json` (example: the
registration below is an example only, merge it with your own entries):

```json
{
  "extraKnownMarketplaces": {
    "claude-dev-plugin": { "source": { "source": "github", "repo": "vangogh500/claude-dev-plugin" } }
  },
  "enabledPlugins": { "dev@claude-dev-plugin": true }
}
```

**Plugin-directory install**, from a checkout of this repo, for development or to run an
unreleased version:

```
claude --plugin-dir .
```

Run it from the repo root; the flag loads that checkout in place of the installed copy.

## Prerequisites

- [`bd`](https://github.com/gastownhall/beads), the beads issue tracker
- `gh` (GitHub) or `tea` (Gitea) for pull requests
- the `mattpocock-skills` plugin from the official marketplace (`code-review`, `pr`, `tdd`)
- the Atlassian MCP connector, for the Jira Epic

## Setup

- `/dev:setup` once per machine: checks the prerequisites and hands you the user-level
  `CLAUDE.md` stub and the baseline settings snippet to paste.
- `/dev:setup-repo` once per repo: records the Jira project key in the repo's
  `CLAUDE.md`, initialises beads, and lays out `GLOSSARY.md` and `docs/adr/`.

The baseline settings are org-neutral. Toolchain, registry and forge entries are yours to
add; the lines below are examples only, not part of the plugin, so replace them with the
ones your machine uses:

```json
{
  "permissions": {
    "allow": [
      "Bash(cargo *)",
      "Bash(npm *)",
      "Bash(gh *)"
    ]
  }
}
```

## Developing

Run Claude Code in this repo with `claude --plugin-dir .` to load the checkout next to
the installed copy. Check your changes with `make lint`, which runs the skill-doc lint and
its tests (it needs `bd` and `cargo` for the fixture tests). Bump the version in
`.claude-plugin/plugin.json` on every merge to main. Decisions are in `docs/adr/`,
vocabulary in `GLOSSARY.md`.
