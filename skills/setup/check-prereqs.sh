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
if grep -qs '"mattpocock-skills@' "$plugins_dir/installed_plugins.json"; then present mattpocock-skills
else absent mattpocock-skills "install it from the official marketplace"; fi

# Atlassian MCP: read from config, never by running `claude mcp list` (that health-checks every
# server, needs the network, and fails inside the sandbox). A server name in ~/.claude.json or an
# installed plugin named for it counts; whether it is authenticated is the owner's to confirm.
if grep -Eiqs '"[^"]*atlassian[^"]*"' "$HOME/.claude.json" \
   || grep -Eiqs '"[^"]*atlassian[^"@]*@' "$plugins_dir/installed_plugins.json"; then present "Atlassian MCP"
else absent "Atlassian MCP" "connect the Atlassian connector, for the Jira Epic"; fi

# the stub and the baseline are always printed, for the owner to paste
here=$(cd "${BASH_SOURCE[0]%/*}" && pwd)
echo; echo "=== paste into ~/.claude/CLAUDE.md ==="; cat "$here/claude-md-stub.md"
echo; echo "=== merge into ~/.claude/settings.json (merge the arrays; do not replace) ==="; cat "$here/baseline-settings.json"
echo

if [ "$missing" = 0 ]; then echo "all prerequisites present"; else exit 1; fi
