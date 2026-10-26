#!/usr/bin/env bash
# Tests for README.md: the sections a coworker needs (what the plugin is, the five
# prerequisites, both install forms, /dev:setup and /dev:setup-repo, the developing
# section), the settings blocks marked as examples, and every JSON block parsing.
# Driven from outside: grep and awk on the README, jq on its settings block.
# Usage: scripts/test-readme.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_check, fx_report_fails
readme=$repo_root/README.md

# section <heading>: the lines under a level-2 heading, up to the next one
section() { awk -v h="## $1" '$0==h{on=1;next} /^## /{on=0} on' "$readme"; }
# json_blocks: the bodies of the ```json fences, one block after another
json_blocks() { awk '/^```json$/{on=1;next} /^```$/{on=0} on' "$readme"; }

fx_check "README exists and is non-empty" test -s "$readme"
fx_check "README names the plugin dev" grep -q 'The `dev` plugin' "$readme"
fx_check "README has a Prerequisites section" grep -qx '## Prerequisites' "$readme"
fx_check "README has an Install section" grep -qx '## Install' "$readme"
fx_check "README has a Setup section" grep -qx '## Setup' "$readme"
fx_check "README has a Developing section" grep -qx '## Developing' "$readme"

pre=$(section Prerequisites)
fx_check "prerequisite: bd" grep -q '`bd`' <<<"$pre"
fx_check "prerequisite: gh or tea for pull requests" bash -c 'grep -q "gh" <<<"$1" && grep -q "tea" <<<"$1"' _ "$pre"
fx_check "prerequisite: the mattpocock-skills plugin" grep -q 'mattpocock-skills' <<<"$pre"
fx_check "prerequisite: the Atlassian MCP connector" grep -q 'Atlassian MCP' <<<"$pre"
fx_check "prerequisite: jq, which the setup check reads its config with" grep -q '`jq`' <<<"$pre"

inst=$(section Install)
fx_check "marketplace install: marketplace add" grep -q '/plugin marketplace add' <<<"$inst"
fx_check "marketplace install: plugin install" grep -q '/plugin install dev@claude-dev-plugin' <<<"$inst"
fx_check "plugin-directory install: claude --plugin-dir ." grep -q 'claude --plugin-dir \.' <<<"$inst"
fx_check "install: the settings block is marked as an example" grep -qi 'example' <<<"$inst"
fx_check "install: every JSON block parses" bash -c '[ -n "$1" ] && jq -e . <<<"$1" >/dev/null' _ "$(json_blocks)"

setup=$(section Setup)
fx_check "setup names /dev:setup" grep -q '/dev:setup`' <<<"$setup"
fx_check "setup names /dev:setup-repo" grep -q '/dev:setup-repo`' <<<"$setup"

dev=$(section Developing)
fx_check "developing: the plugin-directory flag" grep -q -- '--plugin-dir' <<<"$dev"
fx_check "developing: make check" grep -q 'make check' <<<"$dev"
fx_check "developing: bump plugin.json version on merge to main" bash -c 'grep -q "plugin.json" <<<"$1" && grep -q "version" <<<"$1" && grep -q "main" <<<"$1"' _ "$dev"

fx_report_fails
