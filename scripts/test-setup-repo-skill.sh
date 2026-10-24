#!/usr/bin/env bash
# Tests for skills/setup-repo: user-invoked frontmatter, the machine-setup check comes
# before any write, and the skill covers the Jira key, bd init and the glossary/ADR layout.
# Usage: scripts/test-setup-repo-skill.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # check, report_fails
doc=$repo_root/skills/setup-repo/SKILL.md

front() { awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$1"; }
fm=$(front "$doc")
check "skill file exists" test -s "$doc"
check "frontmatter names the skill setup-repo" grep -qx 'name: setup-repo' <<<"$fm"
check "frontmatter is user-invoked" grep -qx 'disable-model-invocation: true' <<<"$fm"
check "frontmatter has a description" grep -q '^description: .' <<<"$fm"

line() { grep -n -m1 -- "$1" "$doc" | cut -d: -f1; }
has() { check "$1" grep -q -- "$2" "$doc"; }
has "it points at /dev:setup when the machine setup is missing" '/dev:setup'
machine=$(line 'machine setup')
write=$(line '^[0-9]*\. \*\*Write')
check "the machine-setup check precedes the write step" bash -c '[ -n "$1" ] && [ -n "$2" ] && [ "$1" -lt "$2" ]' _ "$machine" "$write"
has "it follows explore, present, confirm, write" 'explore, present, confirm, write'
has "it records the Jira key in the ## Agent skills block" '## Agent skills'
has "it runs bd init non-interactively with CLAUDE.md as agents file" 'bd init --non-interactive --agents-file CLAUDE.md'
has "it prunes the bd init extras per the tracker doc" 'AGENTS.md'
has "it skips bd init when .beads/ exists" '\.beads/'
has "it lays out GLOSSARY.md" 'GLOSSARY.md'
has "it lays out docs/adr/" 'docs/adr/'

report_fails
