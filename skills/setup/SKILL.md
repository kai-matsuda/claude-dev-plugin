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

The baseline is org-neutral apart from one rule pair: it denies reads of secret files, asks
before destructive git and `bd dolt push`, allows `bd`, and enables the sandbox with the beads
and Dolt directories writable and push, fetch and pull excluded. `~/.config/bd` is writable too,
because `bd` writes its user-level config there. The pair is plugin-specific: the plugin's own
`forge-wait`, the script the plugin ships in its `bin/` directory, run with its five arguments,
is both excluded from the sandbox (`sandbox.excludedCommands`) and allowed
(`permissions.allow`). Claude Code puts a plugin's `bin/` on the Bash tool's `PATH` while the
plugin is enabled (a `--plugin-dir` copy included); outside that, with the plugin disabled or
removed, the bare call fails with `command not found`, and an unsandboxed rerun does not help,
since the command is missing. The agent calls it by its bare name and both rules name the bare command,
ending in five `*` words: `forge-wait * * * * *`. Neither rule holds a path or a plugin version,
so the owner (or a setup tool such as chezmoi) pastes the pair once and it stays valid across
plugin updates; the printed snippet is the file's text as it is.
Without the pair the delivery's forge-check wait fails on the forge CLI's config error inside
the sandbox and, in a permission mode that prompts for an unlisted command (the default; ADR
0009), needs an unsandboxed rerun with a permission prompt, which an unattended story
orchestrator cannot answer (dev-tt2l, INFRA-44). The pattern is the bare command name, so a
`forge-wait2`, a path-qualified `forge-wait`, a `PATH=… forge-wait …` call (its text starts with
`PATH=`) and a `gh` or `tea` command carrying `forge-wait` as an argument do not match, and the
five `*` words stand for the command's five arguments, so a call with fewer than five words does
not match (a free trailing `*` would have matched it). A bare name pins no file, so what keeps
another `forge-wait` from riding the exclusion is that no sandbox-writable directory is on `PATH`
(dev-21sr): an agent that could write to a `PATH` directory could already plant a `git` that rides
the baseline's `git push*` exclusion, so the bare name adds no new class of risk, and a machine
that puts a writable directory on `PATH` ahead of the plugin's `bin/` loses that protection for the
baseline's git exclusions as for this pair.
What a glob cannot pin: a `*` matches any text, spaces included, so read as one whole string
`forge-wait * * * * *` also matches `forge-wait a b c d e && other`. A compound command stays out of the
rule only where the matcher splits it into its parts and tests each, as permission rules are
documented to do, and a matcher that does not split would let such a command ride the exclusion.
On Claude Code 2.1.308 neither rule took a compound command (dev-re7g): the plain five-argument
run went through outside the sandbox (probed with the exact-path form of the rules), while the
command with its five arguments `&& touch` a file
outside the sandbox raised a permission prompt and, once approved, ran wholly in the sandbox,
the script itself failing on the forge CLI's config error. On another version this is unverified,
and the probe is run again there before the pair is trusted.
`forge-wait` itself refuses (exit 2) a forge other than `gh` or `tea`, a repo not
`owner/name`, a PR number that is not digits and a tip that is not 7 to 64 hex digits, which
bounds what the script does with its own five arguments but not what follows an `&&` after them.
Before the owner pastes the printed pair no machine has it, so the plain run is still rerun with
the sandbox disabled. After it is pasted it holds across plugin updates, and a fork installed
under another marketplace name or a `--plugin-dir` checkout is covered while it is the enabled
plugin whose `bin/` is on `PATH`. Toolchain, registry and forge-CLI entries are the owner's own to add.
