#!/usr/bin/env bash
# Tests for skills/setup: the frontmatter is user-invoked, the baseline settings snippet is
# valid settings JSON with nothing org-specific, check-prereqs.sh reports each
# prerequisite and changes nothing, and the snippet's trailer hook runs under real git
# commits in throwaway repos. No check reads the SKILL.md body, only its frontmatter
# structure (the spec's Testing Decisions). Driven from outside: jq on the snippet, the
# helper run against stub binaries on a throwaway PATH; the real-commit cases instead run the
# real git and the trailer hook's real script under bin/, and need a git that runs config hooks; on a git that does not,
# the refusal case fails and the off-PATH case passes with no hook run.
# Usage: scripts/test-setup-skill.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_check, fx_front, fx_scratch_dir, fx_report_fails
skill=$repo_root/skills/setup
snippet=$skill/baseline-settings.json
stub=$skill/claude-md-stub.md
prereqs=$skill/check-prereqs.sh
hook_snippet=$skill/commit-trailers.gitconfig
trailers=$repo_root/bin/commit-trailers

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
  .sandbox.excludedCommands | map(select(test("forge-wait") | not)) | all(endswith("*") and (endswith(" *") | not))' "$snippet"
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
# the implementer's reset (dev-16ml, INFRA-43) runs unattended: no ask rule may match it
no_ask_match() { # <snippet> <command>
  local pat
  while IFS= read -r pat; do
    pat=${pat#Bash(}; pat=${pat%)}
    [[ $2 == $pat ]] && return 1
  done < <(jq -r '.permissions.ask[]' "$1")
  return 0
}
fx_check "the implementer's reset with -C matches no ask rule" no_ask_match "$snippet" 'git -C /x/worktree reset --keep feat/x'
fx_check "the implementer's plain reset matches no ask rule" no_ask_match "$snippet" 'git reset --keep feat/x'
ask_matches() { ! no_ask_match "$@"; }
fx_check "the ask rule still catches a hard reset" ask_matches "$snippet" 'git reset --hard feat/x'
# the forge-check wait: one narrow rule pair covers the plugin's forge-wait command, which the
# plugin ships in bin/ so Claude Code puts it on PATH while the plugin is enabled (dev-21sr, INFRA-44).
# The pair names the bare command, so it holds across plugin updates
fw_pat='forge-wait * * * * *'
fx_check "baseline excludes forge-wait with its five arguments from the sandbox" jq -e --arg p "$fw_pat" '
  .sandbox.excludedCommands | index($p) != null' "$snippet"
fx_check "baseline allows forge-wait with its five arguments without a prompt" jq -e --arg p "Bash($fw_pat)" '
  .permissions.allow | index($p) != null' "$snippet"
fx_check "baseline exempts no forge CLI and no other script, only forge-wait" jq -e '
  (.sandbox.excludedCommands + .permissions.allow)
  | map(select(test("gh|tea|forge|scripts"))) | length == 2 and all(startswith("Bash(forge-wait ") or startswith("forge-wait "))' "$snippet"
fx_check "baseline names no path and no placeholder in the forge-wait pair" jq -e '
  (.sandbox.excludedCommands + .permissions.allow) | map(select(test("forge-wait"))) | all(test("/|FORGE_WAIT") | not)' "$snippet"
fx_check "no exclusion or allow entry starts with a wildcard" jq -e '
  (.sandbox.excludedCommands + .permissions.allow) | map(sub("^Bash\\("; "")) | all(startswith("*") | not)' "$snippet"
no_org() { ! jq -c '[.. | strings]' "$1" |
  grep -Eiq 'cargo|rustup|crates|npm|pip|gh |tea |github|gitea|mice'; }
fx_check "baseline carries no toolchain, registry or forge-CLI line" no_org "$snippet"
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
prints_baseline() { # <machine>: $out holds the snippet verbatim, the forge-wait rules with no path in them
  [[ $out == *"$(cat "$snippet")"* ]]
}
fx_check "full machine prints the baseline snippet as the file holds it" prints_baseline full
fx_check "full machine prints no FORGE_WAIT_PATH placeholder" bash -c '! grep -q "FORGE_WAIT_PATH" <<<"$1"' _ "$out"
fx_check "the plugin ships forge-wait as an executable in bin/" test -x "$repo_root/bin/forge-wait"
fx_check "the plugin no longer ships forge-wait.sh under scripts/" bash -c '[ ! -e "$1" ]' _ "$repo_root/scripts/forge-wait.sh"
# what the printed rules match, as a shell glob. fw_rule_match models a matcher that splits a
# compound command on && || ; | & and requires every part to match (how permission rules are
# documented to behave; on Claude Code 2.1.308 sandbox.excludedCommands also took no compound
# command, dev-re7g);
# fw_whole_match models one that does not split and globs the whole string
fw_rules() { # the printed rule pair, one per line
  jq -r '(.sandbox.excludedCommands[], (.permissions.allow[] | sub("^Bash\\("; "") | sub("\\)$"; ""))) | select(test("forge-wait"))' \
    <<<"$1"
}
fw_rule_match() { # <command>
  local pat seg
  while IFS= read -r pat; do
    while IFS= read -r seg; do
      seg=${seg#"${seg%%[![:space:]]*}"}; seg=${seg%"${seg##*[![:space:]]}"}
      [[ $seg == $pat ]] || return 1
    done < <(printf '%s\n' "$2" | sed -e 's/&&/;/g' -e 's/||/;/g' -e 's/|/;/g' -e 's/&/;/g' | tr ';' '\n')
  done <<<"$1"
}
fw_whole_match() { # <rules> <command>: every rule globbed against the whole command string, unsplit
  local pat
  while IFS= read -r pat; do [[ $2 == $pat ]] || return 1; done <<<"$1"
}
fw_printed=$(fw_rules "$(cat "$snippet")")
fw_hit() { fw_rule_match "$fw_printed" "$1"; }
fw_miss() { ! fw_hit "$1"; }
fx_check "the printed rules are two, one exclusion and one allow" test "$(grep -c . <<<"$fw_printed")" = 2
fx_check "the printed rules match the bare command with its five arguments" fw_hit "forge-wait /x/owner gh a/b 12 abc1234"
fx_check "the printed rules match the bare command with the tea forge" fw_hit "forge-wait /x/owner tea o/r 3 abc1234"
# note: fw_rule_match splits a compound command first, so the compound checks below would also pass
# under a free-trailing-* rule; the whole-string check below is what tells the two rules apart
fx_check "the printed rules miss a compound command after the five arguments" fw_miss "forge-wait /x gh a/b 1 c && touch /x/y"
fx_check "the printed rules miss a command chained with ;" fw_miss "forge-wait /x gh a/b 1 c; rm -rf /x"
fx_check "the printed rules miss a piped command" fw_miss "forge-wait /x gh a/b 1 c | sh"
fx_check "the printed rules miss a command run first" fw_miss "touch /x/y && forge-wait /x gh a/b 1 c"
fx_check "the printed rules miss the command with four arguments" fw_miss "forge-wait /x gh a/b 1"
# tells the five-* rule from a free trailing * ("forge-wait *"): the call with a short argument
# list matches the free rule and misses the printed one
fx_check "a free trailing * rule would match the command with three arguments" fw_rule_match "forge-wait *" "forge-wait /x gh a/b"
fx_check "the printed rules miss the command with three arguments" fw_miss "forge-wait /x gh a/b"
# known limit: a glob cannot stop the whole-string match, so if the matcher does not split a
# compound command, the five * words span "a b c d e && touch /x/y" and the rule matches it; the
# script's own argument checks and a matcher that splits are what stop it, not the glob
fx_check "known limit: unsplit, the printed rules match a compound command whose first part has five words" fw_whole_match "$fw_printed" "forge-wait /x gh a/b 1 c && touch /x/y"
fx_check "the printed rules miss the command with no arguments" fw_miss "forge-wait"
# PATH=... forge-wait starts with PATH=, so the rule text does not match it
fx_check "the printed rules miss a PATH=-prefixed call" fw_miss "PATH=/x/evil:/usr/bin forge-wait /x gh a/b 1 c"
fx_check "the printed rules miss a differently named command" fw_miss "forge-wait2 /x gh a/b 1 c"
fx_check "the printed rules miss a path-qualified forge-wait" fw_miss "/home/owner/src/x/bin/forge-wait /x gh a/b 1 c"
fx_check "the printed rules miss a gh command carrying forge-wait as an argument" fw_miss "gh pr merge forge-wait x y z w"
fx_check "the printed rules miss a tea command" fw_miss "tea pr list --repo /x"
# the trailer hook's gitconfig snippet (dev-ekcl.1.3, INFRA-47): the printed `git config --global`
# commands are generated from it, one per entry in the snippet's order; a repeated key is added,
# not replaced, so pasting the lines twice leaves each key once
fx_check "the trailer hook snippet ships in the setup skill's directory" test -f "$hook_snippet"
fx_check "the snippet holds the hook entry and the two provenance keys, in that order" test "$(git config -f "$hook_snippet" --list)" = 'hook.committrailers.event=commit-msg
hook.committrailers.command=command -v commit-trailers >/dev/null || exit 0; commit-trailers "$@"
dev.trailer.provenance=Bead
dev.trailer.provenance=Refs'
hook_section() { # the printed hook commands: the lines under the "wire the trailer hook" header
  sed -n '/^=== wire the trailer hook/,/^$/p' <<<"$out" | sed '1d;$d'
}
fx_check "full machine prints the snippet's commands, line for line" test "$(hook_section)" = "git config --global --replace-all hook.committrailers.event 'commit-msg'
git config --global --replace-all hook.committrailers.command 'command -v commit-trailers >/dev/null || exit 0; commit-trailers \"\$@\"'
git config --global --replace-all dev.trailer.provenance 'Bead'
git config --global --add dev.trailer.provenance 'Refs'"
fx_scratch_dir interleaved; ildir=$scratch   # a copy of the skill whose snippet repeats a key non-adjacently
cp -R "$skill/." "$ildir/"
printf '[dev "trailer"]\n\tprovenance = Bead\n[hook "committrailers"]\n\tevent = commit-msg\n[dev "trailer"]\n\tprovenance = Refs\n' >"$ildir/commit-trailers.gitconfig"
real_prereqs=$prereqs; prereqs=$ildir/check-prereqs.sh; run full; il_out=$out; prereqs=$real_prereqs; run full
fx_check "a key repeated non-adjacently in the snippet is replaced once, then added" test "$(sed -n '/^=== wire the trailer hook/,/^$/p' <<<"$il_out" | sed '1d;$d')" = "git config --global --replace-all dev.trailer.provenance 'Bead'
git config --global --replace-all hook.committrailers.event 'commit-msg'
git config --global --add dev.trailer.provenance 'Refs'"
fx_check "full machine prints no copy command" bash -c '! grep -qE "(^| )cp " <<<"$1"' _ "$out"
fx_check "full machine names no commit-lint.sh" bash -c '! grep -q "commit-lint" <<<"$1"' _ "$out"
fx_check "the plugin no longer ships commit-lint.sh" bash -c '[ ! -e "$1" ]' _ "$skill/commit-lint.sh"
hook_cmd=$(git config -f "$hook_snippet" hook.committrailers.command)
fx_scratch_dir hookcmd; hookdir=$scratch   # outside $work, so the changes-nothing snapshot below is unaffected
mkdir -p "$hookdir/bin" "$hookdir/empty"
printf '#!/bin/sh\nexit 7\n' >"$hookdir/bin/commit-trailers"; chmod +x "$hookdir/bin/commit-trailers"
fx_check "the snippet's hook command exits 0 when commit-trailers is not on PATH" env -i PATH="$hookdir/empty" /bin/sh -c "$hook_cmd" sh "$hookdir/msg"
fx_check "the snippet's hook command runs commit-trailers when it is on PATH" bash -c \
  'env -i PATH="$1" /bin/sh -c "$2" sh "$3"; [ $? = 7 ]' _ "$hookdir/bin" "$hook_cmd" "$hookdir/msg"
# The same hook through a real `git commit`, so git itself builds the command line: it appends
# its own "$@" to a config hook command, which the /bin/sh -c checks above do not reproduce
# (dev-ekcl.1.6). The hook entries and keys are installed from the snippet file. These cases need
# a git that runs config hooks; on one that does not, the other cases still pass and only the
# refusal case fails, so it alone proves the hook ran.
fx_scratch_dir realcommit; rcdir=$scratch
git_bin=$(command -v git); git_dir=$(dirname "$git_bin")
on_path=$repo_root/bin:$git_dir:/usr/bin:/bin   # commit-trailers calls sed, paste, awk and grep
rc_repo() { # <name>: a throwaway repo with the snippet's entries installed and the hook enabled
  fx_git_repo "$rcdir/$1" || return 1
  local k v
  while IFS='=' read -r k v; do
    git -C "$rcdir/$1" config --add "$k" "$v" || return 1
  done < <(git config -f "$hook_snippet" --list)
  git -C "$rcdir/$1" config hook.committrailers.enabled true
}
rc_commit() { # <repo name> <message> <PATH>: an empty commit by the absolute git, PATH as given
  env -i PATH="$3" HOME="$rcdir" GIT_CONFIG_NOSYSTEM=1 "$git_bin" -C "$rcdir/$1" commit -q --allow-empty -m "$2"
}
rc_refused() { # <repo name> <message> <PATH>: the commit fails and commit-trailers' error says why
  local err; err=$(rc_commit "$@" 2>&1); [ $? != 0 ] && grep -q "is not in the trailer block" <<<"$err"
}
rc_bad_msg=$(printf 'feat: x\n\nBead: dev-1\n\nprose after it\n\nRefs: INFRA-1')
# two repos built alike: only the PATH each commit runs with differs (the trailer hook on it or not).
# The off-PATH case would also pass if git never ran the hook; the refusal case on the same git
# and the same build is what shows the hook runs, so keep the two repos built by one function.
fx_check "the real-commit repo for the on-PATH cases is built" rc_repo ontrack
fx_check "the real-commit repo for the off-PATH case is built" rc_repo offtrack
fx_check "a real git commit with parseable Bead:/Refs: trailers succeeds with commit-trailers on PATH" \
  rc_commit ontrack "$(printf 'feat: x\n\nBead: dev-1\nRefs: INFRA-1')" "$on_path"
fx_check "a real git commit with a Bead: line outside the trailer block is refused" \
  rc_refused ontrack "$rc_bad_msg" "$on_path"
fx_check "a real git commit exits 0 when commit-trailers is not on PATH, whatever its trailers" \
  rc_commit offtrack "$rc_bad_msg" "$hookdir/empty:$git_dir"
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
fx_check "empty machine still prints the baseline snippet" prints_baseline empty

# `commit-trailers`, the trailer hook machine setup wires as a commit-msg hook (dev-ekcl): run in
# a throwaway repo on message files, as git's hook would. The keys come from the repo-local
# dev.trailer.provenance, and global and system git config are switched off for the run, so no
# case depends on the machine's own config.
trw=$work/trailers
fx_check "trailer hook: the throwaway repo is made" fx_git_repo "$trw/repo"
trailers_keys() { # <key>...: the repo's provenance keys, replacing any set
  git -C "$trw/repo" config --unset-all dev.trailer.provenance
  local k; for k in "$@"; do git -C "$trw/repo" config --add dev.trailer.provenance "$k"; done
  return 0
}
trailers_msg() { # <message>: run the trailer hook on it from the repo; sets tout, terr (stderr), trc;
  # $trw/msg0 keeps the message as written, to compare the file against after the run
  printf '%s\n' "$1" >"$trw/msg"
  cp "$trw/msg" "$trw/msg0"
  tout=$(cd "$trw/repo" && GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null "$trailers" "$trw/msg" 2>"$trw/err"); trc=$?
  terr=$(cat "$trw/err")
}
blocked() { [ "$trc" = 1 ] && [ -z "$tout" ] && grep -q "trailer block" <<<"$terr" && grep -q "references/issue-tracker.md" <<<"$terr"; }
fx_check "the trailer hook ships in bin/ and is executable" test -x "$trailers"
trailers_keys Bead Refs
trailers_msg $'feat(setup): ship the trailer hook\n\nBody.\n\nBead: dev-clo\nRefs: INFRA-1'
fx_check "trailer hook passes Bead:/Refs: lines git parses as trailers" test "$trc" = 0
trailers_msg $'fix: thing\n\nBead: dev-clo\n\nMore prose after the trailer.'
fx_check "trailer hook blocks a Bead: line outside the last paragraph, pointing at the tracker doc" blocked
# no keys: a no-op, even on a message that fails with keys set
trailers_keys
trailers_msg $'fix: thing\n\nBead: dev-clo\n\nMore prose after the trailer.'
fx_check "trailer hook with no keys set exits 0, prints nothing and leaves the file byte-identical" bash -c \
  '[ "$1" = 0 ] && [ -z "$2$3" ] && cmp -s "$4" "$5"' _ "$trc" "$tout" "$terr" "$trw/msg" "$trw/msg0"
# a joined-then-rejected message: the repair is made in memory, the file stays as written
trailers_keys Bead Refs
trailers_msg $'fix: thing\n\nBead: dev-a\n\nProse line.\nBead: dev-b\n\nBead: dev-c\n\nCo-Authored-By: Claude <noreply@anthropic.com>'
fx_check "trailer hook blocks a message its join would not fix" blocked
fx_check "trailer hook leaves a joined-then-rejected message file byte-identical" cmp -s "$trw/msg" "$trw/msg0"
# a key holding a regex character matches only itself
trailers_keys 'Ref.s'
trailers_msg $'fix: thing\n\nRefxs: A-1\n\nMore prose after the trailer.'
fx_check "trailer hook with key Ref.s does not check a Refxs: line" test "$trc" = 0
trailers_msg $'fix: thing\n\nRef.s: A-1\n\nMore prose after the trailer.'
fx_check "trailer hook with key Ref.s checks a Ref.s: line" blocked
trailers_keys 'Re\fs'
trailers_msg $'fix: thing\n\nRe\\fs: A-1\n\nMore prose after the trailer.'
fx_check "trailer hook with a backslash in a key checks that key literally" blocked
fx_check "trailer hook error shows a backslash key literally" grep -qF '(Re\fs)' <<<"$terr"
trailers_keys Bead Refs
# with keys set (Bead, Refs), an unreadable message file fails the hook; with no keys set it
# exits 0 before reading the file, so this case does not cover that path
printf '%s\n' $'fix: thing\n\nBead: dev-a' >"$trw/unreadable"
chmod 000 "$trw/unreadable"
fx_check "trailer hook fails on an unreadable message file" bash -c \
  'cd "$2" && ! GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null "$1" "$3" 2>/dev/null' _ "$trailers" "$trw/repo" "$trw/unreadable"
chmod 600 "$trw/unreadable"
# run with no argument it prints a usage line on stderr and exits 2
fx_check "trailer hook with no argument prints a usage line and exits 2" bash -c \
  'cd "$2" && err=$(GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null "$1" 2>&1 >/dev/null); rc=$?; [ "$rc" = 2 ] && grep -q "^usage: commit-trailers <message file>" <<<"$err"' _ "$trailers" "$trw/repo"
# git runs a config hook command through `sh -c` and appends its own "$@" to the command, so the
# snippet's command hands the trailer hook the message file twice (on git 2.56.0, dev-ekcl.1.5):
# the hook reads the first argument and tolerates the rest
twice_cmd=$hook_cmd' "$@"'
twice_msg() { # <message>: the snippet's command, plus git's own "$@", on a message file; sets trc, terr
  printf '%s\n' "$1" >"$trw/msg"
  terr=$(cd "$trw/repo" && env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null PATH="$(dirname "$trailers"):$PATH" \
    /bin/sh -c "$twice_cmd" sh "$trw/msg" 2>&1 >/dev/null); trc=$?
}
trailers_keys Bead Refs
twice_msg $'fix: thing\n\nBody.\n\nBead: dev-clo\nRefs: INFRA-1'
fx_check "the snippet's hook command, given the message file twice, passes a correct message" test "$trc" = 0
twice_msg $'fix: thing\n\nBead: dev-clo\n\nMore prose after the trailer.'
fx_check "the snippet's hook command, given the message file twice, still blocks a bad message" bash -c \
  '[ "$1" = 1 ] && grep -q "trailer block" <<<"$2"' _ "$trc" "$terr"
# the harness's attribution guidance splits the trailers into two paragraphs: the hook joins them
trailers_msg $'fix: thing\n\nBody.\n\nBead: dev-qgww\nRefs: INFRA-42\n\nCo-Authored-By: Claude <noreply@anthropic.com>\nClaude-Session: https://example.test/s'
fx_check "trailer hook passes trailers split from the attribution lines" test "$trc" = 0
fx_check "trailer hook joins the split trailers into one paragraph" bash -c \
  '[ "$(grep -c "^$" "$1")" = 2 ]' _ "$trw/msg"
fx_check "trailer hook: the joined message commits" env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git -C "$trw/repo" commit -q --allow-empty -F "$trw/msg"
fx_check "trailer hook: git parses the committed Bead trailer" bash -c \
  '[ "$(git -C "$1" log -1 --format="%(trailers:key=Bead,valueonly)" | tr -d "\n")" = dev-qgww ]' _ "$trw/repo"
trailers_msg $'fix: thing\n\nBead: dev-qgww\n\nProse after the trailers.\nCo-Authored-By: Claude <noreply@anthropic.com>'
fx_check "trailer hook blocks trailers followed by a prose paragraph" blocked
trailers_msg $'fix: thing\n\nBead: dev-qgww\n\nProse after the trailers.\n\nCo-Authored-By: Claude <noreply@anthropic.com>'
fx_check "trailer hook blocks a mid-body Bead: before prose and attribution" blocked
trailers_msg $'fix: thing\n\nProse line.\nBead: dev-qgww\n\nCo-Authored-By: Claude <noreply@anthropic.com>'
fx_check "trailer hook blocks a Bead: inside a prose paragraph before attribution" blocked
fx_check "trailer hook leaves a rejected message file unrewritten" bash -c \
  '[ "$(cat "$1")" = "$2" ]' _ "$trw/msg" $'fix: thing\n\nProse line.\nBead: dev-qgww\n\nCo-Authored-By: Claude <noreply@anthropic.com>'
# trailing "#" comment lines (git commit -v style) do not stop the join
trailers_msg $'fix: thing\n\nBead: dev-qgww\n\nCo-Authored-By: Claude <noreply@anthropic.com>\n# Please enter the commit message\n#'
fx_check "trailer hook joins split trailers that are followed by # comment lines" bash -c \
  '[ "$1" = 0 ] && [ "$(grep -c "^$" "$2")" = 1 ]' _ "$trc" "$trw/msg"
# attribution keys are matched whatever their case, as git matches trailer keys
trailers_msg $'fix: thing\n\nBody.\n\nBead: dev-pf49\nRefs: INFRA-42\n\nCo-authored-by: Claude <noreply@anthropic.com>\nclaude-session: https://example.test/s'
fx_check "trailer hook joins split trailers whose attribution keys are lowercase" bash -c \
  '[ "$1" = 0 ] && [ "$(grep -c "^$" "$2")" = 2 ]' _ "$trc" "$trw/msg"
trailers_msg $'fix: thing\n\nBead: dev-pf49\n\nCo-Authored-By: Claude <noreply@anthropic.com>'
fx_check "trailer hook joins split trailers with one attribution key alone" bash -c \
  '[ "$1" = 0 ] && [ "$(grep -c "^$" "$2")" = 1 ]' _ "$trc" "$trw/msg"
trailers_msg $'fix: thing\n\nBead: dev-pf49\n\nCO-AUTHORED-BY: Claude <noreply@anthropic.com>\nCLAUDE-SESSION: https://example.test/s'
fx_check "trailer hook joins split trailers whose attribution keys are all caps" bash -c \
  '[ "$1" = 0 ] && [ "$(grep -c "^$" "$2")" = 1 ]' _ "$trc" "$trw/msg"
# a CRLF message file
trailers_msg $'fix: thing\r\n\r\nBead: dev-qgww\r\n\r\nCo-Authored-By: Claude <noreply@anthropic.com>\r'
fx_check "trailer hook passes split trailers in a CRLF message" test "$trc" = 0
fx_check "trailer hook joins the split trailers of a CRLF message" bash -c \
  '[ "$(tr -d "\r" <"$1" | grep -c "^$")" = 1 ]' _ "$trw/msg"
# only the configured keys are checked
trailers_keys Ticket
trailers_msg $'fix: thing\n\nTicket: T-1\n\nMore prose after the trailer.'
fx_check "trailer hook with only Ticket set checks a Ticket: line" blocked
trailers_msg $'fix: thing\n\nBead: dev-clo\n\nMore prose after the trailer.'
fx_check "trailer hook with only Ticket set does not check a Bead: line" test "$trc" = 0
trailers_keys Bead Refs
# the subject and the blank line after it are no concern of the trailer hook
trailers_msg 'Added a thing.'
fx_check "trailer hook passes a non-Conventional subject" test "$trc" = 0
trailers_msg $'fix: thing\nbody right under the subject'
fx_check "trailer hook passes a body with no blank line after the subject" test "$trc" = 0

fx_report_fails
