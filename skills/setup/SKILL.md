---
name: setup
description: Machine setup for the dev plugin. Checks the prerequisites and prints the user-level CLAUDE.md stub and the baseline settings snippet to paste. Use once per machine.
disable-model-invocation: true
---

# Setup

Machine setup, run once per machine from any directory. It reports and prints; it never
edits `~/.claude` or any file outside the repo it runs in. The owner pastes what it prints.

1. Run `bash <skill dir>/check-prereqs.sh`, where `<skill dir>` is this skill's base
   directory (the Skill tool prints it). It lists `bd`, `gh` or `tea`, the
   `mattpocock-skills` plugin and the Atlassian MCP as `present:` or `missing:`.
2. If it prints `all prerequisites present` and exits 0, say so, and also say that
   the stub and snippet are in `<skill dir>` (`claude-md-stub.md`, `baseline-settings.json`)
   should the owner want to compare them with their own. Change nothing.
3. Otherwise, for each `missing:` line, tell the owner how to install it (the line names
   the source). Then print the two files below, each in a fenced block, with a one-line
   instruction: the stub goes into `~/.claude/CLAUDE.md`, the snippet is merged into
   `~/.claude/settings.json` (merge the arrays; do not replace existing entries).
   - `<skill dir>/claude-md-stub.md`
   - `<skill dir>/baseline-settings.json`
4. Finish with `/dev:setup-repo` as the next step, per repo.

The baseline is org-neutral: it denies reads of secret files, asks before destructive git
and `bd dolt push`, allows `bd`, and enables the sandbox with the beads and Dolt
directories writable and push and fetch excluded. Toolchain, registry and forge entries
are the owner's own to add.
