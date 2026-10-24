#!/usr/bin/env bash
# Test the story cut (/spec-to-stories) in both session modes (chezmoi-gfu.1, INFRA-28) against
# the fixture workspace. The seam is a subagent run, which a script cannot spawn, so the test has
# phases, one fixture per case under .fixtures/test-story-cut-<case>:
#   scripts/test-fixture-story-cut.sh seed <case>     build the fixture, seed the spec and the epic
#                                                     bead in the case's home, print the brief
#   scripts/test-fixture-story-cut.sh assert <case>   check the bead state and the saved end block
#   scripts/test-fixture-story-cut.sh                 assert every case whose fixture is seeded
# Cases:
#   workspace     typed at the fixture root (a workspace session): the epic bead stays in the root,
#                 one parentless story each in lib and consumer with FIX-1, ## Parent naming the root,
#                 each story's design field holding the orientation, and each owner repo's tree
#                 clean at the seeded HEAD (the cut writes beads only, chezmoi-cdf)
#   repo-refuse   typed in consumer alone (a repo session) with a spec that changes fixture-lib:
#                 the refusal line, nothing created
#   repo-one      typed in consumer alone with a spec that changes only consumer: one story in
#                 consumer, parented to the epic bead, no key, nothing anywhere else
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
skill=$repo_root/skills/spec-to-stories/SKILL.md
tracker=$repo_root/docs/agents/issue-tracker.md
cases="workspace repo-refuse repo-one"

fixture() { echo "$repo_root/.fixtures/test-story-cut-$1"; }
# the case's session repo, relative to the fixture root
home_of() { case "$1" in workspace) echo . ;; *) echo consumer ;; esac; }

seed() { # <case>
  local home home_dir epic spec_rel spec
  build_fixture
  home=$(home_of "$1"); home_dir=$(home_path "$1")
  mkdir -p "$out/$home/specs"
  spec_rel=specs/feature.md   # the Spec: line's path, relative to the case's home (tracker doc, "gather the epic bead")
  spec=$out/$home/$spec_rel
  case "$1" in
    workspace)
      cat > "$spec" <<'T'
# Spec: multiply

Add `multiply` to fixture-lib (lib/src/lib.rs) and publish it as 0.2.0. The consumer
bumps fixture-lib and prints the product of 2 and 3 from consumer/src/main.rs.
T
      epic=$(bdj . create --silent --type epic --external-ref FIX-1 -l ready-for-agent "Feature: multiply" \
        --body-file - <<<"Spec: $spec_rel") ;;
    repo-refuse)
      cat > "$spec" <<'T'
# Spec: multiply

Add `multiply` to fixture-lib (the lib repo, lib/src/lib.rs) and print the product of 2 and 3
from fixture-consumer's src/main.rs.
T
      epic=$(bdj consumer create --silent --type epic -l ready-for-agent "Feature: multiply" \
        --body-file - <<<"Spec: $spec_rel") ;;
    repo-one)
      cat > "$spec" <<'T'
# Spec: print a sum

fixture-consumer's src/main.rs prints the sum of 3 and 4 with fixture_lib::add, which
already exists. No other repo changes.
T
      epic=$(bdj consumer create --silent --type epic -l ready-for-agent "Feature: print a sum" \
        --body-file - <<<"Spec: $spec_rel") ;;
  esac
  [ -n "$epic" ] || { echo "FAIL seed epic bead"; exit 1; }
  # each owner repo's HEAD at the seed, so assert can show the cut committed nothing (chezmoi-cdf)
  for r in lib consumer; do echo "$r $(git -C "$out/$r" rev-parse HEAD)"; done > "$out/seed-heads.txt"
  echo "seeded $out, epic bead $epic in $home"
  echo "brief: the session's repo is $home_dir$( [ "$home" = consumer ] && echo ' alone (a repo session: the workspace above is ignored)'); follow $skill with the argument $epic and the branch's tracker doc $tracker (this repo's skills/ loaded as the plugin: claude --plugin-dir $repo_root, the skill typed dev:spec-to-stories); approve the story quiz as drafted; FIX-1 is not in Jira, so a getJiraIssue on it answers no such issue; plain bd only, pointed at the home with BEADS_DIR=$home_dir/.beads bd <args>, and bd -C only where the skill says so; save the skill's final report block, verbatim, to $out/report.txt"
}

header='Orientation from the story cut; the story body is the only contract.'
seed_head() { awk -v r="$1" '$1==r{print $2}' "$out/seed-heads.txt"; }
# the story cut writes beads only (chezmoi-cdf, ADR 0010): the orientation is the story's design
# field behind its header line, and the owner repo keeps a clean tree, the same HEAD and no notes
# directory. .beads/ is left out of the tree check: bd itself edits .beads/config.yaml on a
# database's first create.
assert_owner() { # <repo> <story-id> <other repo of the pair, or "">
  check "$1 working tree is clean after the cut" eq "$(git -C "$out/$1" status --porcelain -- . ':!.beads' ':!specs')" ""
  check "$1 HEAD is unchanged: the cut committed nothing" eq "$(git -C "$out/$1" rev-parse HEAD)" "$(seed_head "$1")"
  check "$1 has no .spec-notes directory" test ! -e "$out/$1/.spec-notes"
  check "$1 story design field opens with the orientation header" \
    eq "$(field "$1" "$2" '.design // "" | split("\n")[0]')" "$header"
  check "$1 story design field says more than the header" \
    test "$(field "$1" "$2" '.design // "" | split("\n") | length')" -gt 1
  if [ -n "$3" ]; then
    check "$1 story design field names its pair $3 and a version" \
      grep -qiE "$3.*[0-9]+\.[0-9]+\.[0-9]+|[0-9]+\.[0-9]+\.[0-9]+.*$3" <<<"$(field "$1" "$2" '.design // "" | gsub("\n"; " ")')"
  fi
}

assert() { # <case>
  local epic s1 s2 body
  check "the run saved its end block" test -s "$out/report.txt"
  case "$1" in
    workspace)
      epic=$(one . '.issue_type=="epic"')
      s1=$(one lib '.issue_type=="story"'); s2=$(one consumer '.issue_type=="story"')
      check "the epic bead is the root's only bead" eq "$(all . | jq length)" 1
      check "one story in lib, one in consumer" eq "$([ -n "$s1" ] && [ -n "$s2" ] && echo yes)" yes
      check "no tickets in lib or consumer" eq "$(all lib | jq length)$(all consumer | jq length)" 11
      for pair in "lib $s1 consumer" "consumer $s2 lib"; do
        set -- $pair
        assert_owner "$1" "$2" "$3"
        check "$1 story carries FIX-1" eq "$(field "$1" "$2" .external_ref)" FIX-1
        check "$1 story has no parent" eq "$(field "$1" "$2" '.parent // "none"')" none
        check "$1 story ## Parent names the root as home" grep -Fqx "Home $(basename "$out"), epic bead $epic, FIX-1" \
          <<<"$(field "$1" "$2" .description)"
      done
      check "consumer story is blocked by lib's publish ticket, not created yet" \
        grep -qE '^lib publish fixture-lib [0-9]+\.[0-9]+\.[0-9]+ \(not created yet\)$' <<<"$(field consumer "$s2" .description)" ;;
    repo-refuse)
      check "end block refuses with 'start this at the workspace root'" \
        grep -qE 'refused: the spec changes .* outside .*consumer; start this at the workspace root' "$out/report.txt"
      check "consumer holds only the epic bead" eq "$(all consumer | jq length)" 1
      check "nothing in the root" eq "$(all . | jq length)" 0
      check "nothing in lib" eq "$(all lib | jq length)" 0 ;;
    repo-one)
      epic=$(one consumer '.issue_type=="epic"')
      s2=$(one consumer '.issue_type=="story"')
      check "one story in consumer beside the epic bead" eq "$([ -n "$s2" ] && all consumer | jq length)" 2
      assert_owner consumer "$s2" ""
      check "the story is the epic bead's child" eq "$(field consumer "$s2" '.parent // "none"')" "$epic"
      check "the story carries no labels" eq "$(field consumer "$s2" '.labels // [] | length')" 0
      check "## Parent names consumer as home and the epic bead" \
        grep -qE "^Home consumer, epic bead $epic(,|\$)" <<<"$(field consumer "$s2" .description)"
      check "no key was required (no external ref anywhere)" eq "$(all consumer | jq '[.[] | select(.external_ref)] | length')" 0
      check "nothing in the root (no sweep, no inbox write)" eq "$(all . | jq length)" 0
      check "nothing in lib" eq "$(all lib | jq length)" 0 ;;
  esac
}

source "$repo_root/scripts/fixture-phases.sh"
run_phases "$@"
