#!/usr/bin/env bash
# Report each prerequisite of the dev plugin as present or missing. Read-only: it writes
# nothing, anywhere. Exit 0 when all are present, 1 when any prerequisite is missing. The
# baseline settings lines (exclusions and forge-wait permissions), though they start `missing:`,
# are informational and set no exit code; the last line says when any is not merged.
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

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

# The baseline's sandbox.excludedCommands and forge-wait allow entries against the user's
# settings file, so an owner whose sandboxed push fails sees which exclusion is not pasted.
# Informational like the Atlassian line: it sets no exit code. An absent or unreadable file, or no
# jq to read it, is a confirm: line. An empty file or one holding null is readable and holds no
# entry, so each baseline entry is missing: from it. Exact string match, as the entries are the rules.
settings=$HOME/.claude/settings.json
gap=0
if lacking=$(jq -r --slurpfile have "$settings" '
     ($have[0] // {}) as $s
     | (.sandbox.excludedCommands[] | select(. as $e | ($s.sandbox.excludedCommands // []) | index($e) | not)
        | "missing: sandbox.excludedCommands entry " + .),
       (.permissions.allow[] | select(test("forge-wait"))
        | select(. as $e | ($s.permissions.allow // []) | index($e) | not)
        | "missing: permissions.allow entry " + .)' "$here/baseline-settings.json" 2>/dev/null); then
  [ -z "$lacking" ] || { echo "$lacking"; gap=0; while IFS= read -r _; do gap=$((gap+1)); done <<<"$lacking"; }
else echo "confirm: baseline settings ($settings absent or unreadable, or jq absent; compare it with the baseline below)"; fi

# the stub and the baseline are always printed, for the owner to paste
echo; echo "=== paste into ~/.claude/CLAUDE.md ==="; cat "$here/claude-md-stub.md"
echo
echo "=== merge into ~/.claude/settings.json (merge the arrays; do not replace) ==="
# the forge-wait rules name the bare command Claude Code puts on the Bash tool's PATH from the
# plugin's bin/ while the plugin is enabled, so the pair names no plugin version and is pasted
# once; with the plugin disabled the command is not found (dev-21sr, INFRA-44;
# skills/setup/SKILL.md)
cat "$here/baseline-settings.json"
# the commit-msg hook: its command names the bare `commit-trailers` from the plugin's bin/, so
# the lines name no path or version. One command per entry of the shipped snippet, in its
# order; --replace-all on a key's first value anywhere in the snippet and --add on its later
# values, so pasting them again leaves each key once. The hook command itself changes between
# plugin versions (its skip path joins split trailers inline, dev-i023), so an owner who pasted
# the lines before that change pastes them again: the header says so.
echo; echo "=== wire the trailer hook, run on commit-msg in every repo (paste again if you pasted these lines before plugin version 0.4.33: the hook command changed in it) ==="
# Plain bash reads the snippet, since git is not a prerequisite this check can count on; the
# snippet's form is `[section "subsection"]` headers and tab-indented `name = value` entries,
# a value in double quotes holding \" for a quote and \\ for a backslash.
config_unescape() { # <value>: git config's \\ and \" escapes undone, left to right; sets unescaped
  local rest=$1; unescaped=
  while [[ -n $rest ]]; do
    if [[ $rest == '\\'* || $rest == '\"'* ]]; then unescaped+=${rest:1:1}; rest=${rest:2}
    else unescaped+=${rest:0:1}; rest=${rest:1}; fi
  done
}
seen=; section=; expected=
while IFS= read -r line; do
  if [[ $line =~ ^\[([a-z]+)\ \"([a-z]+)\"\]$ ]]; then section=${BASH_REMATCH[1]}.${BASH_REMATCH[2]}
  elif [[ $line =~ ^[[:space:]]+([a-z]+)\ =\ (.*)$ ]]; then
    key=$section.${BASH_REMATCH[1]} val=${BASH_REMATCH[2]}
    if [[ $val == \"*\" ]]; then val=${val#\"}; val=${val%\"}; config_unescape "$val"; val=$unescaped; fi
    [[ $key == hook.committrailers.command ]] && expected=$val
    val=${val//\'/\'\\\'\'}   # a single quote inside the printed single-quoted value
    flag=--replace-all; [[ $seen == *" $key "* ]] && flag=--add; seen+=" $key "
    echo "git config --global $flag $key '$val'"
  fi
done <"$here/commit-trailers.gitconfig"
echo
# the hook command set on this machine, against the one the lines above set (dev-h115, INFRA-47):
# current when equal, stale when another command is set, missing when none is. Informational: it
# sets no exit code, as the lines above do not, so the owner pastes the lines to clear it.
if ! installed=$(git config --global --get hook.committrailers.command 2>/dev/null); then
  echo "trailer hook: missing (no hook.committrailers.command set; paste the lines above)"
elif [ "$installed" = "$expected" ]; then echo "trailer hook: current"
else echo "trailer hook: stale (the command set differs from the lines above; paste them again)"; fi
echo

if [ "$missing" != 0 ]; then exit 1
elif [ "$gap" != 0 ]; then
  msg="prerequisites present; baseline settings entries not merged: $gap"
  [ "$atlassian" = 1 ] || msg="$msg; confirm Atlassian in /mcp"
  echo "$msg"
elif [ "$atlassian" = 1 ]; then echo "all prerequisites present"
else echo "all checked prerequisites present; confirm Atlassian in /mcp"; fi
