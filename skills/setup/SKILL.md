---
name: setup
description: Machine setup for the dev plugin. Checks the prerequisites and prints the user-level CLAUDE.md stub and the baseline settings snippet to paste. Use once per machine.
disable-model-invocation: true
---

# Setup

Machine setup, run once per machine from any directory. It reports and prints; it never
edits `~/.claude` or any file outside the repo it runs in, and the check itself writes no file. The owner pastes what it prints.

1. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/setup/check-prereqs.sh`. It lists `bd`, `gh` or
   `tea`, `jq` (the check reads the plugin and MCP config with it), the
   `mattpocock-skills` plugin and the Atlassian MCP, each as `present:`,
   `missing:` or `confirm:`, then prints the `CLAUDE.md` stub, the baseline settings
   snippet and the commands that install `commit-lint.sh` as the commit-msg hook, on
   every machine. The Atlassian MCP is `present:` only when `~/.claude.json`
   (top level or this project) or the project's `.mcp.json` lists it under `mcpServers`;
   otherwise it is `confirm:`, never `missing:`, because a claude.ai connector is in no file.
2. Show the owner the output. Tell them the stub goes into `~/.claude/CLAUDE.md` and the
   snippet is merged into `~/.claude/settings.json` (merge the arrays; do not replace
   existing entries), and that they run the hook commands as printed: they copy the
   script this plugin ships to `~/.config/git/commit-lint.sh` and point git's global
   `hook.commitlint` at it. The source path names the installed plugin version, so the
   copy is repeated after each plugin update; a machine setup tool (chezmoi, say)
   installs it from the plugin cache on every apply rather than keeping its own copy.
   The output ends with `all prerequisites present` or, while Atlassian is unconfirmed,
   `all checked prerequisites present; confirm Atlassian in /mcp`; the owner may already
   hold the stub, snippet and hook, so they compare rather than paste.
3. For each `missing:` line, tell the owner how to install it (the line names the source).
   For a `confirm:` line, ask the owner to check `/mcp` for the Atlassian server.
4. Finish with `/dev:setup-repo` as the next step, per repo.

The baseline is org-neutral apart from one rule pair: it denies reads of secret files, asks before destructive git
and `bd dolt push`, allows `bd`, and enables the sandbox with the beads and Dolt
directories writable and push, fetch and pull excluded. `~/.config/bd` is writable too,
because `bd` writes its user-level config there. The pair is plugin-specific: the plugin's own
`scripts/forge-wait.sh`, run with its arguments from the installed cache
(`~/.claude/plugins/cache/claude-dev-plugin/dev/*/scripts/forge-wait.sh *`, the `*` after
`dev/` standing for the plugin version), is both excluded from the sandbox
(`sandbox.excludedCommands`) and allowed (`permissions.allow`). The printed snippet has the
owner's home spelled out in place of `~`, because a Bash pattern is matched against the
command string and nothing confirms the matchers expand `~`; the file in the plugin keeps `~`,
so the owner (or a setup tool such as chezmoi) pastes the printed snippet, never the file.
Without the pair the delivery's forge-check wait fails on the forge CLI's config error
inside the sandbox and, in a permission mode that prompts for an unlisted command (the
default; ADR 0009), needs an unsandboxed rerun with a permission prompt, which an
unattended story orchestrator cannot answer (dev-tt2l, INFRA-44). The pattern starts at the
cache root, so a `gh` or `tea` command carrying that path as an argument does not match, and
the space before the trailing `*` rules out `forge-wait.sh2`. Residual breadth: the version
`*` can span `/`, so any file named `forge-wait.sh` under `scripts/` below `dev/` in the
plugin cache matches (the cache is not sandbox-writable); and whether
`sandbox.excludedCommands` reads the space before `*` as a word boundary is not verified, so
if it does not, `forge-wait.sh2` is excluded there too. A fork installed under another
marketplace name and a `--plugin-dir` checkout run from outside that path and are not
covered. Toolchain, registry and forge-CLI entries are the owner's own to add.
