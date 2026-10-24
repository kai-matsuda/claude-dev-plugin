#!/usr/bin/env bash
# Tests for skills/setup-repo: user-invoked frontmatter, the machine-setup check comes
# before any write, and the skill covers the Jira key, bd init and the glossary/ADR layout.
# Usage: scripts/test-setup-repo-skill.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # check, report_fails
doc=$repo_root/skills/setup-repo/SKILL.md

fm=$(front "$doc")
check "skill file exists" test -s "$doc"
check "frontmatter names the skill setup-repo" grep -qx 'name: setup-repo' <<<"$fm"
check "frontmatter is user-invoked" grep -qx 'disable-model-invocation: true' <<<"$fm"
check "frontmatter has a description" grep -q '^description: .' <<<"$fm"

body=$(awk 'NR==1{next} f{print} $0=="---"{f=1}' "$doc")   # everything after the frontmatter
line() { grep -n -m1 -- "$1" <<<"$body" | cut -d: -f1; }
has() { check "$1" grep -q -- "$2" <<<"$body"; }
before() { check "$1" bash -c '[ -n "$1" ] && [ -n "$2" ] && [ "$1" -lt "$2" ]' _ "$2" "$3"; }
has "it points at /dev:setup when the machine setup is missing" '/dev:setup'
machine=$(line '^1\. \*\*Check the machine setup')
explore=$(line '^2\. \*\*Explore')
present=$(line '^3\. \*\*Present')
confirm=$(line '^4\. \*\*Confirm')
write=$(line '^5\. \*\*Write')
before "the machine-setup check precedes the write step" "$machine" "$write"
before "explore precedes present" "$explore" "$present"
before "present precedes confirm" "$present" "$confirm"
before "confirm precedes the write step" "$confirm" "$write"
has "it follows explore, present, confirm, write" 'explore, present, confirm, write'
has "it records the Jira key in the ## Agent skills block" '## Agent skills'
has "it runs bd init non-interactively with CLAUDE.md as agents file" 'bd init --non-interactive --agents-file CLAUDE.md'
before "bd init runs before the CLAUDE.md edit, so the key is not swept into the init commit" "$(line '^   - `\.beads/`')" "$(line '^   - `CLAUDE.md`')"
has "it prunes the bd init extras per the tracker doc" 'AGENTS.md'
has "it skips bd init when .beads/ exists" '\.beads/'
has "it lays out GLOSSARY.md" 'GLOSSARY.md'
has "it handles a multi-context layout" 'GLOSSARY-MAP.md'
has "it lays out docs/adr/" 'docs/adr/'

report_fails
