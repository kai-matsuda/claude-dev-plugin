#!/usr/bin/env bash
# Tests for skills/setup: the frontmatter is user-invoked, the baseline settings snippet is
# valid settings JSON with nothing org-specific, and check-prereqs.sh reports each
# prerequisite and changes nothing. No check reads the SKILL.md body, only its frontmatter
# structure (the spec's Testing Decisions). Driven from outside: jq on the snippet, the
# helper run against stub binaries on a throwaway PATH.
# Usage: scripts/test-setup-skill.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_check, fx_front, fx_scratch_dir, fx_report_fails
skill=$repo_root/skills/setup
snippet=$skill/baseline-settings.json
stub=$skill/claude-md-stub.md
prereqs=$skill/check-prereqs.sh
lint=$skill/commit-lint.sh

fm=$(fx_front "$skill/SKILL.md")
fx_check "frontmatter names the skill setup" grep -qx 'name: setup' <<<"$fm"
fx_check "frontmatter is user-invoked" grep -qx 'disable-model-invocation: true' <<<"$fm"
fx_check "frontmatter has a description" grep -q '^description: .' <<<"$fm"

# the snippet
fx_check "baseline snippet is valid JSON" jq -e . "$snippet"
fx_check "baseline denies reading secret files" jq -e '.permissions.deny | any(test("\\.env")) and any(test("\\.ssh"))' "$snippet"
fx_check "baseline asks on destructive git and bd dolt push" jq -e '
  .permissions.ask | any(test("git reset --hard")) and any(test("git clean")) and any(test("bd dolt push"))' "$snippet"
fx_check "baseline ask entries take any argument, bare commands included" jq -e '
  .permissions.ask | map(select(test("git reset --hard|git clean|bd dolt push"))) | all(endswith("*)") and (endswith(" *)") | not))' "$snippet"
fx_check "baseline excluded commands take any argument, bare commands included" jq -e '
  .sandbox.excludedCommands | all(endswith("*") and (endswith(" *") | not))' "$snippet"
fx_check "baseline denies Read and Edit alike on every secret path" jq -e '
  .permissions.deny | (map(select(startswith("Read("))|.[5:-1]) | sort) == (map(select(startswith("Edit("))|.[5:-1]) | sort)' "$snippet"
fx_check "every destructive-git ask and excluded git entry has a git -C form too" jq -e '
  (.permissions.ask + .sandbox.excludedCommands) as $all
  | $all | map(select(test("git (reset --hard|clean|stash drop|stash clear|push|fetch|pull)")))
  | length >= 7 and all(. as $e | $all | index($e | sub("git "; "git -C * ")) != null)' "$snippet"
fx_check "baseline denies the forge and docker credential files" jq -e '
  .permissions.deny | any(test("config/gh")) and any(test("config/tea")) and any(test("docker/config.json"))' "$snippet"
fx_check "baseline allows bd" jq -e '.permissions.allow | index("Bash(bd *)") != null' "$snippet"
fx_check "baseline enables the sandbox" jq -e '.sandbox.enabled == true' "$snippet"
fx_check "baseline makes the beads and Dolt directories writable" jq -e '
  .sandbox.filesystem.allowWrite | index("~/.beads") != null and index("~/.dolt") != null' "$snippet"
fx_check "baseline excludes push and fetch from the sandbox" jq -e '
  .sandbox.excludedCommands | any(test("^git push")) and any(test("^git fetch"))' "$snippet"
no_org() { ! jq -c '[.. | strings]' "$1" |
  grep -Eiq 'cargo|rustup|crates|npm|pip|gh |tea |github|gitea|mice'; }
fx_check "baseline carries no toolchain, registry or forge line" no_org "$snippet"
fx_check "baseline has no allowed network domains" jq -e '(.sandbox.network.allowedDomains // []) | length == 0' "$snippet"
fx_check "baseline sandbox holds only the enabled flag, the exclusions and the writable dirs" jq -e '
  .sandbox | keys == ["enabled", "excludedCommands", "filesystem"]' "$snippet"
fx_check "CLAUDE.md stub exists and is non-empty" test -s "$stub"

# the prerequisite check, on throwaway machines. PATH is the machine's bin dir (stubs) plus a
# tools dir of symlinks to only what the helper needs, so a host /usr/bin/gh never leaks in.
fx_scratch_dir setup; work=$scratch
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
for m in full tea empty nobd noforge stale noauth unreadable stray emptyrec nojq subdir projmcp mcpjson; do machine "$m"; done
# a claude that fails (as it does inside the sandbox): the helper must not depend on it
printf '#!/bin/sh\necho "sandbox: operation not permitted" >&2\nexit 1\n' >"$work/full/bin/claude"; chmod +x "$work/full/bin/claude"
mkbin "$work/full/bin" bd gh;  mcp_config full; plugin_installed full
mkbin "$work/tea/bin" bd tea;  mcp_config tea;  plugin_installed tea
# full but for one prerequisite each
mkbin "$work/nobd/bin" gh;     mcp_config nobd;    plugin_installed nobd
mkbin "$work/noforge/bin" bd;  mcp_config noforge; plugin_installed noforge
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
only_missing() { # <prerequisite>: $out names it, and only it, on a missing: line, and $rc is non-zero
  [ "$rc" != 0 ] && [ "$(grep '^missing: ' <<<"$out" | cut -d' ' -f2- | sed 's/ (.*//')" = "$1" ]
}
# portable listing: names, contents, and anything newer than a marker (GNU and BSD alike)
snapshot() { { find "$work" | sort; find "$work" -type f -exec cksum {} + | sort
               find "$work" -newer "$work/.marker"; } | cksum; }
touch "$work/.marker"; sleep 1
before=$(snapshot)
touch "$work/full/cwd/probe"
fx_check "the changes-nothing snapshot detects a new file" test "$(snapshot)" != "$before"
rm "$work/full/cwd/probe"; touch "$work/.marker"; sleep 1
before=$(snapshot)
run full
fx_check "full machine exits 0" test "$rc" = 0
fx_check "full machine says all prerequisites are present" grep -q '^all prerequisites present' <<<"$out"
fx_check "full machine prints the CLAUDE.md stub" bash -c '[[ $1 == *"$(cat "$2")"* ]]' _ "$out" "$stub"
fx_check "full machine prints the baseline snippet" bash -c '[[ $1 == *"$(cat "$2")"* ]]' _ "$out" "$snippet"
fx_check "full machine names the shipped commit-lint.sh to install" grep -qF "$lint" <<<"$out"
fx_check "full machine says commit-lint.sh goes to ~/.config/git" grep -qF '~/.config/git/commit-lint.sh' <<<"$out"
fx_check "full machine prints the commit-msg hook config" bash -c '
  grep -qF "git config --global hook.commitlint.event commit-msg" <<<"$1" &&
  grep -q "git config --global hook.commitlint.command .*config/git/commit-lint.sh" <<<"$1"' _ "$out"
out_line() { grep -n "$1" <<<"$out" | head -1 | cut -d: -f1; }
stub_leads_with_command_grep() { # before the cd rule, the printed stub's first shell line (dev-5o3)
  local g c; g=$(out_line 'command grep'); c=$(out_line 'cd <repo>')
  [ -n "$g" ] && [ -n "$c" ] && [ "$g" -lt "$c" ]
}
fx_check "the printed CLAUDE.md stub leads its shell lines with command grep" stub_leads_with_command_grep
fx_check "full machine changes nothing" test "$(snapshot)" = "$before"
run tea
fx_check "tea satisfies the forge prerequisite" test "$rc" = 0
run nobd
fx_check "a machine missing only bd reports bd, alone, and exits non-zero" only_missing bd
run noforge
fx_check "a machine missing only the forge CLI reports it, alone, and exits non-zero" only_missing "gh or tea"
run stale
fx_check "a stale mattpocock-skills cache does not count" only_missing mattpocock-skills
run emptyrec
fx_check "an empty mattpocock-skills record does not count" only_missing mattpocock-skills
run full
fx_check "a real .mcpServers Atlassian entry is present" grep -q '^present: Atlassian' <<<"$out"
run noauth
fx_check "no config: Atlassian is a line to confirm, not present" grep -q '^confirm: Atlassian' <<<"$out"
fx_check "no config: Atlassian is not missing and the exit is 0" bash -c '! grep -q "^missing" <<<"$1" && [ "$2" = 0 ]' _ "$out" "$rc"
run unreadable
fx_check "unreadable config: Atlassian is a confirm line, never missing" grep -q '^confirm: Atlassian' <<<"$out"
fx_check "unreadable config: exit 0, summary says Atlassian is still to confirm" bash -c '[ "$2" = 0 ] && grep -q "^all checked prerequisites present; confirm Atlassian" <<<"$1" && ! grep -q "^all prerequisites present" <<<"$1"' _ "$out" "$rc"
run nojq "" "$work/toolsnojq"
fx_check "no jq: jq is reported missing, by name" grep -q '^missing: jq' <<<"$out"
fx_check "no jq: exit non-zero" test "$rc" != 0
run subdir deep/er
fx_check "project-scoped install counts from a subdirectory" grep -q '^present: mattpocock-skills' <<<"$out"
ln -s "$work/subdir/cwd" "$work/subdir/link"
out=$(cd "$work/subdir/link/deep" && env -i PATH="$work/subdir/bin:$work/tools" HOME="$work/subdir/home" SETUP_PLUGINS_DIR="$work/subdir/plugins" "$(command -v bash)" "$prereqs" 2>&1)
fx_check "project-scoped install counts through a symlinked path" grep -q '^present: mattpocock-skills' <<<"$out"
run projmcp
fx_check "Atlassian under .projects[<path>].mcpServers is present" grep -q '^present: Atlassian' <<<"$out"
run mcpjson
fx_check "Atlassian in the project .mcp.json is present" grep -q '^present: Atlassian' <<<"$out"
run stray
fx_check "a stray atlassian string outside .mcpServers is not present" bash -c '! grep -q "^present: Atlassian" <<<"$1"' _ "$out"
fx_check "stray string: Atlassian is a confirm line" grep -q '^confirm: Atlassian' <<<"$out"
run empty
fx_check "empty machine exits non-zero" test "$rc" != 0
for p in bd "gh or tea" mattpocock-skills; do
  fx_check "empty machine reports $p missing" grep -q "^missing: $p" <<<"$out"
done
fx_check "empty machine asks to confirm Atlassian, not missing" bash -c 'grep -q "^confirm: Atlassian" <<<"$1" && ! grep -q "^missing: Atlassian" <<<"$1"' _ "$out"
fx_check "empty machine still prints the CLAUDE.md stub" bash -c '[[ $1 == *"$(cat "$2")"* ]]' _ "$out" "$stub"
fx_check "empty machine still prints the baseline snippet" bash -c '[[ $1 == *"$(cat "$2")"* ]]' _ "$out" "$snippet"

# commit-lint.sh, the commit-msg hook machine setup installs (dev-clo): run in a throwaway repo
# on message files, as git's hook would
lintw=$work/lint
fx_check "commit-lint: the throwaway repo is made" fx_git_repo "$lintw/repo"
lint_msg() { # <message>: lint it from the repo; sets lout and lrc
  printf '%s\n' "$1" >"$lintw/msg"
  lout=$(cd "$lintw/repo" && sh "$lint" "$lintw/msg" 2>&1); lrc=$?
}
fx_check "commit-lint ships beside the stub" test -s "$lint"
lint_msg $'feat(setup): ship commit-lint\n\nBody.\n\nBead: dev-clo\nRefs: INFRA-1'
fx_check "commit-lint passes a Conventional Commits message with trailers" test "$lrc" = 0
lint_msg 'Added a thing.'
fx_check "commit-lint blocks a subject with no type" bash -c '[ "$1" = 1 ] && grep -q "error: subject is not" <<<"$2"' _ "$lrc" "$lout"
lint_msg 'feat: Ship it'
fx_check "commit-lint blocks a capital after the colon" bash -c '[ "$1" = 1 ] && grep -q "capital" <<<"$2"' _ "$lrc" "$lout"
lint_msg "feat: $(printf 'x%.0s' $(seq 70))"
fx_check "commit-lint blocks a subject over 72 characters" bash -c '[ "$1" = 1 ] && grep -q "the limit is 72" <<<"$2"' _ "$lrc" "$lout"
lint_msg $'fix: thing\n\nBead: dev-clo\n\nMore prose after the trailer.'
fx_check "commit-lint blocks a Bead: line outside the last paragraph" bash -c '[ "$1" = 1 ] && grep -q "trailer block" <<<"$2"' _ "$lrc" "$lout"
lint_msg $'fix: thing\nbody right under the subject'
fx_check "commit-lint blocks a body with no blank line after the subject" bash -c '[ "$1" = 1 ] && grep -q "no blank line" <<<"$2"' _ "$lrc" "$lout"
lint_msg $'Merge branch \'x\''
fx_check "commit-lint lets git's own Merge subject through" test "$lrc" = 0

fx_report_fails
