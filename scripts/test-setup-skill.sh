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
check "baseline allows bd" jq -e '.permissions.allow | index("Bash(bd *)") != null' "$snippet"
check "baseline enables the sandbox" jq -e '.sandbox.enabled == true' "$snippet"
check "baseline makes the beads and Dolt directories writable" jq -e '
  .sandbox.filesystem.allowWrite | index("~/.beads") != null and index("~/.dolt") != null' "$snippet"
check "baseline excludes push and fetch from the sandbox" jq -e '
  .sandbox.excludedCommands | any(test("^git push")) and any(test("^git fetch"))' "$snippet"
no_org() { ! jq -c '[.permissions.allow[]?, .sandbox.network.allowedDomains[]?, .sandbox.filesystem.allowRead[]?]' "$1" |
  grep -Eiq 'cargo|rustup|crates|npm|pip|gh |tea |github|gitea|mice'; }
check "baseline carries no toolchain, registry or forge line" no_org "$snippet"
check "baseline has no allowed network domains" jq -e '(.sandbox.network.allowedDomains // []) | length == 0' "$snippet"
check "CLAUDE.md stub exists and is non-empty" test -s "$stub"

# the prerequisite check, on throwaway machines: <case>/bin on PATH, <case>/plugins as plugins dir
scratch_dir setup; work=$scratch
mkbin() { # <bin dir> <names...>: stub executables
  local d=$1; shift; mkdir -p "$d"
  for n in "$@"; do printf '#!/bin/sh\nexit 0\n' >"$d/$n"; chmod +x "$d/$n"; done
}
machine() { mkdir -p "$work/$1/bin" "$work/$1/home" "$work/$1/cwd" "$work/$1/plugins"; }
for m in full empty tea; do machine "$m"; done
mkbin "$work/full/bin" bd gh
printf '#!/bin/sh\necho "claude.ai Atlassian: connected"\n' >"$work/full/bin/claude"; chmod +x "$work/full/bin/claude"
mkdir -p "$work/full/plugins/cache/mkt/mattpocock-skills"
mkbin "$work/tea/bin" bd tea
cp "$work/full/bin/claude" "$work/tea/bin/claude"
mkdir -p "$work/tea/plugins/cache/mkt/mattpocock-skills"
run() { # <machine>: run the helper there; sets out and rc
  out=$(cd "$work/$1/cwd" && env -i PATH="$work/$1/bin:/usr/bin:/bin" HOME="$work/$1/home" \
        SETUP_PLUGINS_DIR="$work/$1/plugins" "$prereqs" 2>&1)
  rc=$?
}
snapshot() { find "$work" -exec stat -f '%N %m %z' {} + 2>/dev/null | sort | cksum; }
before=$(snapshot)
run full
check "full machine exits 0" test "$rc" = 0
check "full machine says all prerequisites are present" grep -q '^all prerequisites present' <<<"$out"
check "full machine changes nothing" test "$(snapshot)" = "$before"
run tea
check "tea satisfies the forge prerequisite" test "$rc" = 0
run empty
check "empty machine exits non-zero" test "$rc" != 0
for p in bd "gh or tea" mattpocock-skills Atlassian; do
  check "empty machine reports $p missing" grep -q "^missing: $p" <<<"$out"
done

report_fails
