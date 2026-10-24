---
name: setup
description: Machine setup for the dev plugin. Checks the prerequisites and prints the user-level CLAUDE.md stub and the baseline settings snippet to paste. Use once per machine.
disable-model-invocation: true
---

# Setup

Machine setup, run once per machine from any directory. It reports and prints; it never
edits `~/.claude` or any file outside the repo it runs in, and the check itself writes no file. The owner pastes what it prints.

1. Run `bash <skill dir>/check-prereqs.sh`, where `<skill dir>` is this skill's base
   directory (the Skill tool prints it). It lists `bd`, `gh` or `tea`, the
   `mattpocock-skills` plugin and the Atlassian MCP as `present:` or `missing:`, then prints
   the `CLAUDE.md` stub and the baseline settings snippet, on every machine. The Atlassian
   MCP is a `confirm:` line unless `~/.claude.json` lists it under `mcpServers`; a claude.ai
   connector is in no file, so ask the owner to confirm it in `/mcp`. It is never `missing:`.
2. Show the owner the output. Tell them the stub goes into `~/.claude/CLAUDE.md` and the
   snippet is merged into `~/.claude/settings.json` (merge the arrays; do not replace
   existing entries). When it ends with `all prerequisites present`, say so; the owner may
   already hold the stub and snippet, so they compare rather than paste.
3. For each `missing:` line, tell the owner how to install it (the line names the source).
4. Finish with `/dev:setup-repo` as the next step, per repo.

The baseline is org-neutral: it denies reads of secret files, asks before destructive git
and `bd dolt push`, allows `bd`, and enables the sandbox with the beads and Dolt
directories writable and push and fetch excluded. Toolchain, registry and forge entries
are the owner's own to add.
