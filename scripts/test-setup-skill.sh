#!/usr/bin/env bash
# Tests for skills/setup: the frontmatter is user-invoked, the baseline settings snippet is
# valid settings JSON with nothing org-specific, and check-prereqs.sh reports each
# prerequisite and changes nothing. Driven from outside: jq on the snippet, the helper run
# against stub binaries on a throwaway PATH.
# Usage: scripts/test-setup-skill.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # check, scratch_dir, report_fails
skill=$repo_root/skills/setup
snippet=$skill/baseline-settings.json
stub=$skill/claude-md-stub.md
prereqs=$skill/check-prereqs.sh

# front <file>: the frontmatter lines, between the first two --- lines
front() { awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$1"; }
fm=$(front "$skill/SKILL.md")
check "frontmatter names the skill setup" grep -qx 'name: setup' <<<"$fm"
check "frontmatter is user-invoked" grep -qx 'disable-model-invocation: true' <<<"$fm"
check "frontmatter has a description" grep -q '^description: .' <<<"$fm"

# the snippet
check "baseline snippet is valid JSON" jq -e . "$snippet"
check "baseline denies reading secret files" jq -e '.permissions.deny | any(test("\\.env")) and any(test("\\.ssh"))' "$snippet"
check "baseline asks on destructive git and bd dolt push" jq -e '
  .permissions.ask | any(test("git reset --hard")) and any(test("git clean")) and any(test("bd dolt push"))' "$snippet"
check "baseline ask entries take any argument, bare commands included" jq -e '
  .permissions.ask | map(select(test("git reset --hard|git clean|bd dolt push"))) | all(endswith("*)") and (endswith(" *)") | not))' "$snippet"
check "baseline excluded commands take any argument, bare commands included" jq -e '
  .sandbox.excludedCommands | all(endswith("*") and (endswith(" *") | not))' "$snippet"
check "baseline denies Read and Edit alike on every secret path" jq -e '
  .permissions.deny | (map(select(startswith("Read("))|.[5:-1]) | sort) == (map(select(startswith("Edit("))|.[5:-1]) | sort)' "$snippet"
check "every destructive-git ask and excluded git entry has a git -C form too" jq -e '
  (.permissions.ask + .sandbox.excludedCommands) as $all
  | $all | map(select(test("git (reset --hard|clean|stash drop|stash clear|push|fetch|pull)")))
  | length >= 7 and all(. as $e | $all | index($e | sub("git "; "git -C * ")) != null)' "$snippet"
check "baseline denies the forge and docker credential files" jq -e '
  .permissions.deny | any(test("config/gh")) and any(test("config/tea")) and any(test("docker/config.json"))' "$snippet"
check "baseline allows bd" jq -e '.permissions.allow | index("Bash(bd *)") != null' "$snippet"
check "baseline enables the sandbox" jq -e '.sandbox.enabled == true' "$snippet"
check "baseline makes the beads and Dolt directories writable" jq -e '
  .sandbox.filesystem.allowWrite | index("~/.beads") != null and index("~/.dolt") != null' "$snippet"
check "baseline excludes push and fetch from the sandbox" jq -e '
  .sandbox.excludedCommands | any(test("^git push")) and any(test("^git fetch"))' "$snippet"
no_org() { ! jq -c '[.. | strings]' "$1" |
  grep -Eiq 'cargo|rustup|crates|npm|pip|gh |tea |github|gitea|mice'; }
check "baseline carries no toolchain, registry or forge line" no_org "$snippet"
check "baseline has no allowed network domains" jq -e '(.sandbox.network.allowedDomains // []) | length == 0' "$snippet"
check "CLAUDE.md stub exists and is non-empty" test -s "$stub"

# the prerequisite check, on throwaway machines. PATH is the machine's bin dir (stubs) plus a
# tools dir of symlinks to only what the helper needs, so a host /usr/bin/gh never leaks in.
scratch_dir setup; work=$scratch
mkdir -p "$work/tools"
for t in find grep cat jq dirname; do
  src=$(command -v "$t") && ln -s "$src" "$work/tools/$t"
done
mkdir -p "$work/toolsnojq"
for t in find grep cat dirname; do ln -s "$work/tools/$t" "$work/toolsnojq/$t"; done
mkbin() { # <bin dir> <names...>: stub executables
  local d=$1; shift; mkdir -p "$d"
  for n in "$@"; do printf '#!/bin/sh\nexit 0\n' >"$d/$n"; chmod +x "$d/$n"; done
}
machine() { mkdir -p "$work/$1/bin" "$work/$1/home" "$work/$1/cwd" "$work/$1/plugins"; }
mcp_config() { printf '{"mcpServers":{"claude_ai_Atlassian_Rovo":{"type":"http"}}}\n' >"$work/$1/home/.claude.json"; }
plugin_installed() { printf '{"version":2,"plugins":{"mattpocock-skills@claude-plugins-official":[{}]}}\n' >"$work/$1/plugins/installed_plugins.json"; }
for m in full tea empty stale noauth unreadable stray emptyrec nojq subdir projmcp mcpjson; do machine "$m"; done
# a claude that fails (as it does inside the sandbox): the helper must not depend on it
printf '#!/bin/sh\necho "sandbox: operation not permitted" >&2\nexit 1\n' >"$work/full/bin/claude"; chmod +x "$work/full/bin/claude"
mkbin "$work/full/bin" bd gh;  mcp_config full; plugin_installed full
mkbin "$work/tea/bin" bd tea;  mcp_config tea;  plugin_installed tea
# stale cache dir only, no installed_plugins.json entry
mkbin "$work/stale/bin" bd gh; mcp_config stale
mkdir -p "$work/stale/plugins/cache/mkt/mattpocock-skills"
# a claude that reports the server as unauthenticated, with no config: not present
mkbin "$work/noauth/bin" bd gh; plugin_installed noauth
printf '#!/bin/sh\necho "claude.ai Atlassian: Needs authentication"\n' >"$work/noauth/bin/claude"; chmod +x "$work/noauth/bin/claude"
# an installed_plugins.json record with no installs
mkbin "$work/emptyrec/bin" bd gh
printf '{"version":2,"plugins":{"mattpocock-skills@claude-plugins-official":[]}}\n' >"$work/emptyrec/plugins/installed_plugins.json"
# an unreadable config (a directory stands in for a file the sandbox refuses to read)
mkbin "$work/unreadable/bin" bd gh; plugin_installed unreadable; mkdir "$work/unreadable/home/.claude.json"
# a stray 'atlassian' string outside .mcpServers
mkbin "$work/stray/bin" bd gh; plugin_installed stray
printf '{"projects":{"/src/atlassian-tools":{"allowedTools":["atlassian"]}},"mcpServers":{"other":{}}}\n' >"$work/stray/home/.claude.json"
# nojq: a machine whose tools dir has no jq; subdir: project-scoped install, run from below it
mkbin "$work/nojq/bin" bd gh; plugin_installed nojq; mcp_config nojq
mkbin "$work/subdir/bin" bd gh; mkdir -p "$work/subdir/cwd/deep/er"
printf '{"version":2,"plugins":{"mattpocock-skills@m":[{"scope":"project","projectPath":"%s"}]}}\n' \
  "$(cd "$work/subdir/cwd" && pwd -P)" >"$work/subdir/plugins/installed_plugins.json"
# Atlassian under .projects[<path>].mcpServers, and in the project's .mcp.json
mkbin "$work/projmcp/bin" bd gh; plugin_installed projmcp
printf '{"projects":{"%s":{"mcpServers":{"atlassian":{}}}}}\n' "$(cd "$work/projmcp/cwd" && pwd -P)" >"$work/projmcp/home/.claude.json"
mkbin "$work/mcpjson/bin" bd gh; plugin_installed mcpjson
printf '{"mcpServers":{"atlassian":{}}}\n' >"$work/mcpjson/project-mcp.json"
run() { # <machine> [subdir] [tools dir]: run the helper there; sets out and rc
  out=$(cd "$work/$1/cwd/${2:-}" && env -i PATH="$work/$1/bin:${3:-$work/tools}" HOME="$work/$1/home" \
        SETUP_PLUGINS_DIR="$work/$1/plugins" SETUP_PROJECT_MCP_JSON="$work/$1/project-mcp.json" "$(command -v bash)" "$prereqs" 2>&1)
  rc=$?
}
# portable listing: names, contents, and anything newer than a marker (GNU and BSD alike)
snapshot() { { find "$work" | sort; find "$work" -type f -exec cksum {} + | sort
               find "$work" -newer "$work/.marker"; } | cksum; }
touch "$work/.marker"; sleep 1
before=$(snapshot)
touch "$work/full/cwd/probe"
check "the changes-nothing snapshot detects a new file" test "$(snapshot)" != "$before"
rm "$work/full/cwd/probe"; touch "$work/.marker"; sleep 1
before=$(snapshot)
run full
check "full machine exits 0" test "$rc" = 0
check "full machine says all prerequisites are present" grep -q '^all prerequisites present' <<<"$out"
check "full machine prints the CLAUDE.md stub" bash -c '[[ $1 == *"$(cat "$2")"* ]]' _ "$out" "$stub"
check "full machine prints the baseline snippet" bash -c '[[ $1 == *"$(cat "$2")"* ]]' _ "$out" "$snippet"
check "full machine changes nothing" test "$(snapshot)" = "$before"
run tea
check "tea satisfies the forge prerequisite" test "$rc" = 0
run stale
check "a stale mattpocock-skills cache does not count" grep -q '^missing: mattpocock-skills' <<<"$out"
run emptyrec
check "an empty mattpocock-skills record does not count" grep -q "^missing: mattpocock-skills" <<<"$out"
run full
check "a real .mcpServers Atlassian entry is present" grep -q '^present: Atlassian' <<<"$out"
run noauth
check "no config: Atlassian is a line to confirm, not present" grep -q '^confirm: Atlassian' <<<"$out"
check "no config: Atlassian is not missing and the exit is 0" bash -c '! grep -q "^missing" <<<"$1" && [ "$2" = 0 ]' _ "$out" "$rc"
run unreadable
check "unreadable config: Atlassian is a confirm line, never missing" grep -q '^confirm: Atlassian' <<<"$out"
check "unreadable config: exit 0, summary says Atlassian is still to confirm" bash -c '[ "$2" = 0 ] && grep -q "^all checked prerequisites present; confirm Atlassian" <<<"$1" && ! grep -q "^all prerequisites present" <<<"$1"' _ "$out" "$rc"
run nojq "" "$work/toolsnojq"
check "no jq: jq is reported missing, by name" grep -q '^missing: jq' <<<"$out"
check "no jq: exit non-zero" test "$rc" != 0
run subdir deep/er
check "project-scoped install counts from a subdirectory" grep -q '^present: mattpocock-skills' <<<"$out"
ln -s "$work/subdir/cwd" "$work/subdir/link"
out=$(cd "$work/subdir/link/deep" && env -i PATH="$work/subdir/bin:$work/tools" HOME="$work/subdir/home" SETUP_PLUGINS_DIR="$work/subdir/plugins" "$(command -v bash)" "$prereqs" 2>&1)
check "project-scoped install counts through a symlinked path" grep -q '^present: mattpocock-skills' <<<"$out"
run projmcp
check "Atlassian under .projects[<path>].mcpServers is present" grep -q '^present: Atlassian' <<<"$out"
run mcpjson
check "Atlassian in the project .mcp.json is present" grep -q '^present: Atlassian' <<<"$out"
run stray
check "a stray atlassian string outside .mcpServers is not present" bash -c '! grep -q "^present: Atlassian" <<<"$1"' _ "$out"
check "stray string: Atlassian is a confirm line" grep -q '^confirm: Atlassian' <<<"$out"
run empty
check "empty machine exits non-zero" test "$rc" != 0
for p in bd "gh or tea" mattpocock-skills; do
  check "empty machine reports $p missing" grep -q "^missing: $p" <<<"$out"
done
check "empty machine asks to confirm Atlassian, not missing" bash -c 'grep -q "^confirm: Atlassian" <<<"$1" && ! grep -q "^missing: Atlassian" <<<"$1"' _ "$out"
check "empty machine still prints the CLAUDE.md stub" bash -c '[[ $1 == *"$(cat "$2")"* ]]' _ "$out" "$stub"
check "empty machine still prints the baseline snippet" bash -c '[[ $1 == *"$(cat "$2")"* ]]' _ "$out" "$snippet"

report_fails
