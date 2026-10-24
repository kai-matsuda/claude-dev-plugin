---
name: setup
description: Machine setup for the dev plugin. Checks the prerequisites and prints the user-level CLAUDE.md stub and the baseline settings snippet to paste. Use once per machine.
disable-model-invocation: true
---

# Setup

Machine setup, run once per machine from any directory. It reports and prints; it never
edits `~/.claude` or any file outside the repo it runs in, and the check itself writes no file. The owner pastes what it prints.

1. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/setup/check-prereqs.sh`. It lists `bd`, `gh` or
   `tea`, `jq`, the `mattpocock-skills` plugin and the Atlassian MCP, each as `present:`,
   `missing:` or `confirm:`, then prints the `CLAUDE.md` stub and the baseline settings
   snippet, on every machine. The Atlassian MCP is `present:` only when `~/.claude.json`
   (top level or this project) or the project's `.mcp.json` lists it under `mcpServers`;
   otherwise it is `confirm:`, never `missing:`, because a claude.ai connector is in no file.
2. Show the owner the output. Tell them the stub goes into `~/.claude/CLAUDE.md` and the
   snippet is merged into `~/.claude/settings.json` (merge the arrays; do not replace
   existing entries). The output ends with `all prerequisites present` or, while Atlassian
   is unconfirmed, `all checked prerequisites present; confirm Atlassian in /mcp`; the owner
   may already hold the stub and snippet, so they compare rather than paste.
3. For each `missing:` line, tell the owner how to install it (the line names the source).
   For a `confirm:` line, ask the owner to check `/mcp` for the Atlassian server.
4. Finish with `/dev:setup-repo` as the next step, per repo.

The baseline is org-neutral: it denies reads of secret files, asks before destructive git
and `bd dolt push`, allows `bd`, and enables the sandbox with the beads and Dolt
directories writable, push, fetch and pull excluded, and Bash commands auto-allowed
while sandboxed (`autoAllowBashIfSandboxed`). Toolchain, registry and forge entries
are the owner's own to add.
