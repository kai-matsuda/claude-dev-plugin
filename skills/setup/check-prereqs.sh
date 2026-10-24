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

if [ -n "$(find "$plugins_dir" -type d -name mattpocock-skills -print -quit 2>/dev/null)" ]; then present mattpocock-skills
else absent mattpocock-skills "install it from the official marketplace"; fi

if command -v claude >/dev/null 2>&1 && claude mcp list 2>/dev/null | grep -qi atlassian; then present "Atlassian MCP"
else absent "Atlassian MCP" "connect the Atlassian connector, for the Jira Epic"; fi

if [ "$missing" = 0 ]; then echo "all prerequisites present"; else exit 1; fi
