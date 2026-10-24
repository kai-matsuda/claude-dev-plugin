#!/usr/bin/env bash
# Report each prerequisite of the dev plugin as present or missing. Read-only: it writes
# nothing, anywhere. Exit 0 when all are present, 1 when any is missing.
# SETUP_PLUGINS_DIR overrides the plugins directory (default ~/.claude/plugins).
set -uo pipefail
plugins_dir=${SETUP_PLUGINS_DIR:-$HOME/.claude/plugins}
missing=0
present() { echo "present: $1"; }
absent() { echo "missing: $1 ($2)"; missing=$((missing+1)); }

if command -v bd >/dev/null 2>&1; then present bd; else absent bd "the beads issue tracker, https://github.com/gastownhall/beads"; fi

if command -v gh >/dev/null 2>&1 || command -v tea >/dev/null 2>&1; then present "gh or tea"
else absent "gh or tea" "the forge CLI for pull requests"; fi

# installed means listed in installed_plugins.json, not merely left in the cache
# with a non-empty record, user-scoped or project-scoped to this directory
if jq -e --arg pwd "$PWD" '[.plugins // {} | to_entries[] | select(.key | startswith("mattpocock-skills@"))
     | .value[]? | select((.scope // "user") != "project" or .projectPath == $pwd)] | length > 0' \
   "$plugins_dir/installed_plugins.json" >/dev/null 2>&1; then present mattpocock-skills
else absent mattpocock-skills "install it from the official marketplace"; fi

# Atlassian MCP: never `claude mcp list` (it health-checks every server and fails in the sandbox).
# The claude.ai connector lives outside any file, so this is a line the owner confirms, kept out of
# `missing` and the exit code. Upgraded to present only when a readable ~/.claude.json lists an
# Atlassian server under .mcpServers (scoped with jq, not a whole-file grep).
if jq -e '(.mcpServers // {}) | keys | any(test("atlassian"; "i"))' "$HOME/.claude.json" >/dev/null 2>&1
then present "Atlassian MCP"
else echo "confirm: Atlassian MCP (claude.ai connector or mcpServers entry; check /mcp)"; fi

# the stub and the baseline are always printed, for the owner to paste
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
echo; echo "=== paste into ~/.claude/CLAUDE.md ==="; cat "$here/claude-md-stub.md"
echo; echo "=== merge into ~/.claude/settings.json (merge the arrays; do not replace) ==="; cat "$here/baseline-settings.json"
echo

if [ "$missing" = 0 ]; then echo "all prerequisites present"; else exit 1; fi
