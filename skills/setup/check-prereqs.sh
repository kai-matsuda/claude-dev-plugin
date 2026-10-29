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

# jq reads the two config files below; without it those checks cannot tell, so name it
if command -v jq >/dev/null 2>&1; then present jq
else absent jq "needed to read the plugin and MCP config; install it"; fi

# installed means listed in installed_plugins.json, not merely left in the cache,
# with a non-empty record, user-scoped or project-scoped to this directory or an ancestor
# (matched on the logical and the physical path, so a symlinked checkout counts)
phys=$(pwd -P)
if jq -e --arg pwd "$PWD" --arg phys "$phys" '
     def within($p): $p != null and ($p == $pwd or $p == $phys
       or ($pwd | startswith($p + "/")) or ($phys | startswith($p + "/")));
     [.plugins // {} | to_entries[] | select(.key | startswith("mattpocock-skills@"))
     | .value[]? | select((.scope // "user") != "project" or within(.projectPath))] | length > 0' \
   "$plugins_dir/installed_plugins.json" >/dev/null 2>&1; then present mattpocock-skills
else absent mattpocock-skills "install it from the official marketplace"; fi

# Atlassian MCP: never `claude mcp list` (it health-checks every server and fails in the sandbox).
# The claude.ai connector lives outside any file, so this is a line the owner confirms, kept out of
# `missing` and the exit code. Upgraded to present only when a readable config lists an Atlassian
# server under mcpServers: ~/.claude.json top level or .projects[<this dir or an ancestor>],
# or this directory's .mcp.json (SETUP_PROJECT_MCP_JSON overrides the path; scoped with jq, not a whole-file grep).
atlassian=0
if jq -e --arg pwd "$PWD" --arg phys "$phys" '
     def hit: (.mcpServers // {}) | keys | any(test("atlassian"; "i"));
     hit or ([.projects // {} | to_entries[]
       | select(.key == $pwd or .key == $phys or ($pwd | startswith(.key + "/")) or ($phys | startswith(.key + "/")))
       | .value | hit] | any)' "$HOME/.claude.json" >/dev/null 2>&1; then atlassian=1
elif jq -e '(.mcpServers // {}) | keys | any(test("atlassian"; "i"))' "${SETUP_PROJECT_MCP_JSON:-$PWD/.mcp.json}" >/dev/null 2>&1; then atlassian=1; fi
if [ "$atlassian" = 1 ]; then present "Atlassian MCP"
else echo "confirm: Atlassian MCP (claude.ai connector or mcpServers entry; check /mcp)"; fi

# the stub and the baseline are always printed, for the owner to paste
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
echo; echo "=== paste into ~/.claude/CLAUDE.md ==="; cat "$here/claude-md-stub.md"
echo; echo "=== merge into ~/.claude/settings.json (merge the arrays; do not replace) ==="; cat "$here/baseline-settings.json"
# the commit-msg hook: a machine setup tool installs the shipped script rather than vendoring
# it, again after each plugin update, since $here names the installed version
lint_dest='~/.config/git/commit-lint.sh'
echo; echo "=== install as $lint_dest, run on commit-msg in every repo (again after a plugin update) ==="
echo "mkdir -p ~/.config/git && cp $here/commit-lint.sh $lint_dest"
echo "git config --global hook.commitlint.event commit-msg"
echo "git config --global hook.commitlint.command 'f=\$HOME/${lint_dest#\~/}; [ -f \"\$f\" ] || exit 0; sh \"\$f\" \"\$@\"'"
echo

if [ "$missing" != 0 ]; then exit 1
elif [ "$atlassian" = 1 ]; then echo "all prerequisites present"
else echo "all checked prerequisites present; confirm Atlassian in /mcp"; fi
