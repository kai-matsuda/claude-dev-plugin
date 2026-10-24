#!/usr/bin/env bash
# Test the story cutter (a /story-to-tickets draft run, as /spec-to-tickets step 3 briefs it;
# chezmoi-oye, INFRA-27) against the stage-boundary seed. The seam is a subagent run, which a
# script cannot spawn, so the test has phases, one fixture per case under
# .fixtures/test-story-cutter-<case>:
#   scripts/test-fixture-story-cutter.sh seed <case>     build the stage-boundary seed, record its
#                                                        state, print the story cutter brief
#   scripts/test-fixture-story-cutter.sh assert <case>   check the saved block's shape and that no
#                                                        fixture database or checkout changed
#   scripts/test-fixture-story-cutter.sh                 assert every case whose fixture is seeded
# Cases, both typed at the fixture root (a workspace session, the only one with a pair):
#   lib        the dependency story, briefed with its dependent: the block ends on the publish
#              ticket, after at least one implementation ticket
#   consumer   the dependent story, briefed with the dependency's breakdown: the block opens on
#              the bump to the proposed version and carries no publish ticket
# Either way the cutter drafts only: every bead, HEAD and working tree stays as the seed left it.
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
skill=$repo_root/skills/story-to-tickets/SKILL.md
tracker=$repo_root/docs/agents/issue-tracker.md
cases="lib consumer"

fixture() { echo "$repo_root/.fixtures/test-story-cutter-$1"; }
home_of() { echo .; }

# The pair the seed describes, read from the consumer story's text blocker line (the one
# place the seed states the crate and the proposed version): prints "<crate> <version>".
pair() { fx_field consumer "$(fx_one consumer '.issue_type=="story"')" .description | sed -n 's/^lib publish \(.*\) (not created yet)$/\1/p'; }

# The state the cutter must leave alone, per repo (`.` is the root). Beads: the listing, which
# under the bd this repo runs carries each bead's text fields, labels, dependencies and
# updated_at (bumped by an edit), so an edit, a label or an edge changes it as a create does;
# it lacks bd show's revision, which this diff does not need. Git: HEAD and the porcelain status, less what the test itself writes at the root.
beads_state() { fx_all "$1" | jq -S .; }   # <repo>
git_state() { # <repo>
  git -C "$out/$1" rev-parse HEAD
  git -C "$out/$1" status --porcelain -- . ':!.beads' ':!report.txt' ':!seed'
}
seed_file() { echo "$out/seed/$1.$2"; }   # <repo> <beads|git>

seed() { # <case>
  local r epic story dep crate version
  fx_build_fixture --stage-boundary
  epic=$(fx_one . '.issue_type=="epic"'); story=$(fx_one "$1" '.issue_type=="story"'); read -r crate version <<<"$(pair)"
  [ -n "$epic" ] && [ -n "$story" ] && [ -n "$version" ] || { echo "FAIL find the epic bead, the $1 story and the pair"; exit 1; }
  mkdir -p "$out/seed"
  for r in lib consumer .; do beads_state "$r" > "$(seed_file "$r" beads)"; git_state "$r" > "$(seed_file "$r" git)"; done
  echo "seeded $out, epic bead $epic, story $story in $1"
  case "$1" in
    lib) dep="Dependent: story $(fx_one consumer '.issue_type=="story"') in consumer, crate $crate, version $version." ;;
    consumer) dep="Dependency: story $(fx_one lib '.issue_type=="story"') in lib, crate $crate, version $version. Its breakdown is the block after this brief." ;;
  esac
  echo "brief: the session's repo is $out (a workspace session); you are a story cutter for epic bead $epic: story $story in the repo at $out/$1. The story bead's design field is the story cut's orientation for that repo; the skill reads it first. $dep Follow $skill (this repo's skills/ loaded as the plugin: claude --plugin-dir $repo_root, the skill typed dev:story-to-tickets) with the argument $story and the path $out/$1, and the branch's tracker doc $tracker; FIX-1 is not in Jira, so a getJiraIssue on it answers no such issue; plain bd only, pointed at the home with BEADS_DIR=$out/.beads bd <args>, and bd -C only where the skill says so; save the block the skill ends on, verbatim, to $out/report.txt"
  if [ "$1" = consumer ]; then cat <<T

lib $(fx_one lib '.issue_type=="story"') Story: fixture-lib multiply
1. Add multiply to fixture-lib. Tier: complexity:low. Blocked by: none. What it delivers: fixture_lib::multiply(left, right) returns the product, beside add.
2. Test multiply in fixture-lib. Tier: complexity:low. Blocked by: 1. What it delivers: cargo test covers multiply at the story's test seam.
3. publish $crate $version. Tier: complexity:low. Blocked by: 1, 2. What it delivers: the human stop that publishes $crate $version so the consumer can bump to it.
T
  fi
}

# The saved block with its markdown dressing stripped (heading marks, list markers, bold), one
# line per source line; and the tickets, each numbered item joined into one line with the lines
# under it, up to the next item or a blank line (what follows the list, a cross-repo gap or a
# closing remark, is not a ticket).
block() { sed -E 's/^[[:space:]]*[#>*-]*[[:space:]]*//; s/[[:space:]*]+$//' "$out/report.txt" 2>/dev/null; }
tickets() { block | awk '/^[0-9]+[.)] /{if (t) print t; t=$0; next} /^$/{if (t) print t; t=""; next} t{t=t " " $0} END{if (t) print t}'; }
tier_re='complexity:(low|medium|high)'
no_blocker_re='[Bb]locked[- ]by\**:?\**[[:space:]]*(none|nothing|n/a|—|–)\**([.;,]|$|[[:space:]]+[A-Z])'
every_ticket() { # <regex>   every ticket line matches, and there is at least one
  local t; t=$(tickets); [ -n "$t" ] && [ "$(grep -cE "$1" <<<"$t")" = "$(grep -c . <<<"$t")" ]
}
no_match() { [ -n "$2" ] && ! grep -qE "$1" <<<"$2"; }   # <regex> <text>   text present, regex absent
# A draft block has no bead ids, so a missing ticket shows in the numbering: the tickets run
# 1..N with no gap, and every number a Blocked by field names is an earlier ticket's.
numbered_in_order() { [ "$(tickets | sed -E 's/^([0-9]+).*/\1/')" = "$(seq 1 "$(tickets | grep -c .)")" ]; }
blockers_name_earlier_tickets() {
  local n ref
  while read -r n; do
    for ref in $(tickets | sed -n "${n}p" | sed -E 's/.*[Bb]locked[- ]by\**:?\**[[:space:]]*//; s/\. .*//' | tr -s ' ,;' '\n' | sed -E 's/[.)]+$//' | grep -E '^[0-9]+$'); do
      [ "$ref" -lt "$n" ] || return 1
    done
  done < <(tickets | sed -E 's/^([0-9]+).*/\1/')
}

assert() { # <case>
  local r story title crate version publish_re
  fx_check "the run saved its end block" test -s "$out/report.txt"
  story=$(fx_one "$1" '.issue_type=="story"'); title=$(fx_field "$1" "$story" .title); read -r crate version <<<"$(pair)"
  publish_re="^[0-9]+[.)] \**publish $crate ${version//./\\.}"   # a ticket titled as the tracker doc's publish ticket
  fx_check "the block is headed '$1 $story $title'" grep -Fqx "$1 $story $title" <<<"$(block)"
  fx_check "the block lists two tickets or more" test "$(tickets | grep -c .)" -ge 2
  fx_check "the tickets are numbered 1..N with no gap" numbered_in_order
  fx_check "every ticket carries a complexity tier" every_ticket "$tier_re"
  fx_check "every ticket names its blockers" every_ticket '[Bb]locked[- ]by'
  fx_check "every numbered blocker is an earlier ticket of the block" blockers_name_earlier_tickets
  case "$1" in
    lib)
      fx_check "the block carries the publish ticket 'publish $crate $version'" grep -qE "$publish_re" <<<"$(tickets)"
      fx_check "the publish ticket is the last ticket" grep -qE "$publish_re" <<<"$(tickets | tail -n 1)"
      fx_check "the publish ticket is complexity:low" grep -qE "$publish_re.*complexity:low" <<<"$(tickets | tail -n 1)"
      fx_check "the publish ticket is blocked, not free to start" no_match "$no_blocker_re" "$(tickets | tail -n 1)" ;;
    consumer)
      fx_check "the first ticket is the bump to $version" grep -qiE "bump.*${version//./\\.}|${version//./\\.}.*bump" <<<"$(tickets | head -n 1)"
      fx_check "the bump has no blocker inside the story" grep -qE "$no_blocker_re" <<<"$(tickets | head -n 1)"
      fx_check "no other ticket is free to start (each is blocked by the bump)" fx_eq "$(tickets | tail -n +2 | grep -cE "$no_blocker_re")" 0
      fx_check "the block carries no publish ticket (the dependency's is lib's)" fx_eq "$(tickets | grep -ciE "$publish_re")" 0 ;;
  esac
  for r in lib consumer .; do
    fx_check "$r bead count unchanged: the cutter created nothing" fx_eq "$(fx_all "$r" | jq length)" "$(jq -s '.[0] | length' "$(seed_file "$r" beads)")"
    fx_check "$r beads unchanged since the seed: no create, no edit, no edge" fx_eq "$(beads_state "$r")" "$(cat "$(seed_file "$r" beads)")"
    fx_check "$r HEAD and working tree unchanged since the seed" fx_eq "$(git_state "$r")" "$(cat "$(seed_file "$r" git)")"
  done
}

source "$repo_root/scripts/fixture-phases.sh"
run_phases "$@"
