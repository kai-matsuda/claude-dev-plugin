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
`scripts/forge-wait.sh`, run with its five arguments from the installed cache, is both
excluded from the sandbox (`sandbox.excludedCommands`) and allowed (`permissions.allow`). The
file in the plugin holds the placeholder `FORGE_WAIT_PATH`; the printed snippet has in its
place the installed script's real path (resolved with `pwd -P`), with no wildcard before the
script name, and ends in five `*` words: `<path> * * * * *`. The path names the installed
plugin version, so the owner pastes the printed snippet again after each plugin update, as
for the commit-msg hook. The file's `FORGE_WAIT_PATH` is filled in only by `check-prereqs.sh`, so the snippet is printed, never copied from the file; the owner (or a setup tool such as chezmoi) pastes the printed one.
Without the pair the delivery's forge-check wait fails on the forge CLI's config error
inside the sandbox and, in a permission mode that prompts for an unlisted command (the
default; ADR 0009), needs an unsandboxed rerun with a permission prompt, which an
unattended story orchestrator cannot answer (dev-tt2l, INFRA-44). The pattern is the exact path, so a `../` path, a script of the same name elsewhere, a
`forge-wait.sh2` and a `gh` or `tea` command carrying the path as an argument do not match,
and the five `*` words stand for the script's five arguments, so a call with fewer than five
words does not match (a free trailing `*` would have matched it). What a glob cannot pin: a
`*` matches any text, spaces included, so read as one whole string `<path> * * * * *` also
matches `<path> a b c d e && other`. A compound command stays out of the rule only where the
matcher splits it into its parts and tests each, as permission rules are documented to do;
whether `sandbox.excludedCommands` splits a compound command is not verified (dev-6xui), and a
matcher that does not split lets such a command ride the exclusion. `forge-wait.sh` itself
refuses (exit 2) a forge other than `gh` or `tea`, a repo not `owner/name`, a PR number that
is not digits and a tip that is not 7 to 64 hex digits, which bounds what the script does with
its own five arguments but not what follows an `&&` after them. Before the owner pastes the
printed pair no machine has it, so the plain run is still rerun with the sandbox disabled, and
the pair printed for one plugin version matches only that version's path, so after a plugin
update the plain run is rerun until the owner pastes the new pair. A fork installed under
another marketplace name and a `--plugin-dir` checkout run from a different path and are
covered once the owner pastes the pair that checkout's own `check-prereqs.sh` prints. Toolchain, registry and forge-CLI entries are the owner's own to add.
