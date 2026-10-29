#!/usr/bin/env bash
# Build a throwaway workspace to test the cross-repo stages against (ADR 0003, INFRA-25).
# Usage: scripts/fixture-workspace.sh [--stories | --stage-boundary | --dag] [OUT_DIR]   (default: <repo root>/.fixtures/workspace)
#
# All three seeds leave what a workspace-session story cut leaves: the FIX-1 epic bead (ready-for-agent)
# in the root's own database (OUT/.beads), and story beads in lib and consumer (one each under
# --stories and --stage-boundary, two each under --dag), parentless with external ref FIX-1, each
# "## Parent" line reading "Home <basename of OUT>, epic bead <id>, FIX-1". Without a flag no beads
# are created.
# A skill run on any seed is briefed with OUT, the fixture root, as the session's repo (a
# workspace session, ADR 0008), never a checkout inside it; scripts/test-fixture-story-cut.sh,
# test-fixture-story-cutter.sh, test-fixture-retro.sh and test-fixture-triage.sh print such briefs.
#
# --stage-boundary seeds the state /spec-to-stories leaves behind, before /spec-to-tasks runs:
# that shape and nothing else. The epic's description carries "Spec: specs/multiply.md", the
# path relative to the epic bead's repo as the tracker doc's "gather the epic bead" has it,
# naming OUT/specs/multiply.md (written untracked at the workspace root), and the consumer story's
# "## Blocked by" section is the line "lib publish fixture-lib 0.2.0 (not created yet)". No task
# of any kind. Tested by scripts/test-fixture-stage-boundary.sh; scripts/test-fixture-story-cutter.sh
# briefs a story cutter on it and asserts its block leaves every database as seeded.
#
# --stories adds the tasks: ready-for-agent tasks under each story, a ready-for-human publish
# task under the lib story blocked on the lib tasks, and a "## Blocked by" line
# "lib <publish bead-id>" on the consumer story. Tested by scripts/test-fixture-stories.sh.
#
# --dag seeds the four-story expand-migrate-contract shape of ADR 0011, a story DAG of text
# blockers across lib and consumer, from the same epic (FIX-1): "Story: lib expand" (a task
# pair and "publish fixture-lib 0.2.0"); "Story: consumer migrate", "## Blocked by" "lib <that
# publish id>", with its bump and a task switching the consumer from add to multiply, blocked on
# the bump (lib contract removes add, so the consumer must stop calling it first); "Story: lib contract", "## Blocked by" "consumer <consumer migrate's
# story id>", with one task and "publish fixture-lib 0.3.0"; "Story: consumer bump", "## Blocked
# by" "lib <the 0.3.0 publish id>", with its bump. Each publish task is the only one in its story,
# ready-for-human, with native edges from its story's implementation tasks; the stories carry
# no native edge. Tested by scripts/test-fixture-dag.sh.
#
# Output: OUT/ (workspace root: repos.yaml, .beads), OUT/lib (crate fixture-lib) and
# OUT/consumer (crate fixture-consumer, depends on lib by absolute path, so it also builds
# from a plain git worktree such as consumer/.worktrees/<id>). Each is a git repo on
# main with its own .beads/ and no remotes. Rerunning deletes OUT and rebuilds the same
# fresh state.
#
# --stories and --dag, publish step (by hand, after the lib PR-ready step): a publish task
# ("publish fixture-lib 0.2.0"; under --dag also "publish fixture-lib 0.3.0") is a human stop.
# Closing it is bd close <publish> --reason <version> AND bumping fixture-lib's version to that
# version in Cargo.toml on lib's integration branch; closing the task alone leaves lib's
# Cargo.toml at the old version and the consumer bump task cannot build against it.
# Alternatively seed lib at the version the publish task names.
#
# Sandbox: every fixture repo keeps its git dir under OUT/.git-dirs/, with a `.git` file in
# the checkout pointing at it. The Bash sandbox denies writes to `config` and `hooks/` inside
# any directory named `.git`, which git init needs and rm -rf hits, and no setting lifts that
# (chezmoi-chk), so this is what lets the script and its tests run in-sandbox. A fixture
# built by an older fixture-workspace.sh keeps a real `.git`: delete it once with the sandbox off.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
seed=plain   # plain | stories | stage-boundary | dag
case "${1:-}" in --stories) seed=stories; shift ;; --stage-boundary) seed=stage-boundary; shift ;; --dag) seed=dag; shift ;; esac
if [ "$#" -gt 1 ] || case "${1:-}" in -*) true ;; *) false ;; esac; then
  echo "usage: scripts/fixture-workspace.sh [--stories | --stage-boundary | --dag] [OUT_DIR]   (the flag must come first)" >&2
  exit 2
fi
out=${1:-$repo_root/.fixtures/workspace}

# Safety: only ever delete something that looks like a fixture.
case "$out" in /*) ;; *) out=$PWD/$out ;; esac
case "/$out/" in */../*|*/./*) echo "refusing to rm -rf $out: path has . or .. components" >&2; exit 1 ;; esac
out=$(printf '%s' "$out" | tr -s /)      # collapse runs of /
while [ "${out%/}" != "$out" ]; do out=${out%/}; done   # strip every trailing /
case "$out" in
  "$repo_root"/.fixtures/?*) ;;
  *) echo "refusing to rm -rf $out: must be under $repo_root/.fixtures/" >&2; exit 1 ;;
esac
rm -rf "$out" || { echo "cannot delete $out: a fixture built by an older fixture-workspace.sh keeps a real .git the sandbox will not delete; remove it once with the sandbox off" >&2; exit 1; }
mkdir -p "$out/lib/src" "$out/consumer/src" "$out/.git-dirs"

git_init() { # <dir> <name>   git dir at OUT/.git-dirs/<name>, see "Sandbox" above
  git -C "$1" init -q -b main --separate-git-dir "$out/.git-dirs/$2"
  git -C "$1" config user.name "Fixture"
  git -C "$1" config user.email "fixture@example.invalid"
  git -C "$1" config beads.role maintainer      # silences "beads.role not configured" when no global value
}
commit() { # <dir> <message>   (--no-verify: the global commit-lint hook wants a Bead: trailer)
  # <dir> must be its own repo's top level: git discovers upward, so an add in a dir whose init
  # failed would commit into the enclosing checkout
  [ "$(git -C "$1" rev-parse --show-toplevel)" = "$(cd "$1" && pwd -P)" ] || { echo "refusing to commit: $1 is not a repo's top level" >&2; exit 1; }
  git -C "$1" add -A && git -C "$1" commit -q --no-verify -m "$2"
}
bd_init() { # <dir> <prefix>   bd -C cannot init: it needs an existing .beads, so cd in a subshell
  # --remote '': bd init looks upward for a .git directory, which the fixture's .git file does
  # not stop, so it would reach the enclosing checkout and adopt its origin as the Dolt remote.
  # export.auto false: the same walk makes every bd write under BD_EXPORT_AUTO print a "repair"
  # line that adds the enclosing origin to the fixture; this config beats the env var.
  ( cd "$1" && bd init --non-interactive --skip-agents --skip-hooks --prefix "$2" --remote '' >/dev/null )
  bd -C "$1" config set export.auto false >/dev/null
}

# --- lib: a cargo library crate -------------------------------------------------
git_init "$out/lib" lib
cat > "$out/lib/Cargo.toml" <<'T'
[package]
name = "fixture-lib"
version = "0.1.0"
edition = "2024"

[dependencies]
T
cat > "$out/lib/src/lib.rs" <<'T'
pub fn add(left: u64, right: u64) -> u64 {
    left + right
}
T
printf '/target\n' > "$out/lib/.gitignore"
cargo generate-lockfile --offline --manifest-path "$out/lib/Cargo.toml" >/dev/null
commit "$out/lib" "chore: initial commit"
bd_init "$out/lib" lib

# --- consumer: depends on lib by path ------------------------------------------
git_init "$out/consumer" consumer
# absolute path written at build time: "../lib" would not resolve from consumer/.worktrees/<id>
cat > "$out/consumer/Cargo.toml" <<T
[package]
name = "fixture-consumer"
version = "0.1.0"
edition = "2024"

[dependencies]
fixture-lib = { path = "$out/lib" }
T
cat > "$out/consumer/src/main.rs" <<'T'
fn main() {
    println!("{}", fixture_lib::add(2, 2));
}
T
printf '/target\n' > "$out/consumer/.gitignore"
cargo generate-lockfile --offline --manifest-path "$out/consumer/Cargo.toml" >/dev/null
commit "$out/consumer" "chore: initial commit"
bd_init "$out/consumer" consumer

# --- workspace root: manifest + inbox ------------------------------------------
git_init "$out" workspace
cat > "$out/repos.yaml" <<'T'
# Repo manifest: every repo in this workspace, where it is checked out, and what it
# publishes. Nodes only. Edges (who depends on whom) stay in each repo's Cargo.toml or
# go.mod, which is already authoritative.
#
# Read by any skill that must route a file, crate, or module to the repo that owns it,
# and so to the beads database a task belongs in: retro items aimed at a dependency,
# cross-repo tasks in /implement-spec. Why one file at the workspace root and not
# one per repo: README.md beside this file.
#
# Resolution, in order. Stop at the first hit.
#   1. A path inside a git checkout: `git rev-parse --show-toplevel` on it.
#   2. A path under $HOME outside any checkout: `chezmoi source-path <file>` succeeds,
#      so the chezmoi repo owns it.
#   3. A crate or module name: the repo whose `packages` lists it.
#   4. Nothing matched: file in the current repo with label `retro:foreign` and the
#      intended target in the body. Never drop the item.
# Then `bd -C <repo path> create ...`. A repo without `.beads/` is a finding of its own:
# run `bd init` there first (see issue-tracker.md, "First time in a repo").
#
# Fields. `path` defaults to `<name>` relative to this file's directory. `url` defaults
# to `url-template` with `{name}` substituted. `packages` lists the crate names a cargo
# workspace publishes (its `crates/*` members) or the Go module path; empty means
# nothing depends on this repo by name.
#
# Optional: `triage.jira-epic: <KEY>-<n>` names a standing Jira epic that /triage comments
# on once per run. Absent, /triage skips the comment.

url-template: ssh://git@example.invalid/fixture/{name}.git
registry: fixture # cargo registry name; the fixture crates use path dependencies only

repos:
  lib:
    packages: [fixture-lib]
  consumer:
    packages: []
T
printf '/lib/\n/consumer/\n/.git-dirs/\n' > "$out/.gitignore"
commit "$out" "chore: initial commit"
bd_init "$out" workspace

# --- --stories: a story-shaped feature FIX-1 ----------------------------------
mk() { # <repo> <bd create args...>   prints the new bead id
  bd -C "$out/$1" create --silent "${@:2}"
}
# The epic bead (in the root database) and the stories, as a workspace-session story cut leaves
# them: the stories are parentless, linked by external ref, each body a summary, its test seams,
# the Parent line and, when the story waits on something, one "## Blocked by" line. The epic is
# labelled ready-for-agent like /to-spec does.
mk_epic() { # [bd create args...]   prints the epic bead id
  mk . --type epic --external-ref FIX-1 --labels ready-for-agent "Feature: multiply" "$@"
}
mk_story() { # <repo> <title> <epic-id> <"## Blocked by" line, or empty> <summary> <test seams>   prints the story id
  local summary=$5 seams=$6 blocked=${4:+$'\n\n## Blocked by\n\n'$4}
  mk "$1" --type story --external-ref FIX-1 "$2" --body-file - <<T
$summary

## Test seams

$seams

## Parent

Home $(basename "$out"), epic bead $3, FIX-1$blocked
T
}
# the two stories --stories and --stage-boundary share
mk_lib_story() { # <epic-id>   prints the story id
  mk_story lib "Story: fixture-lib multiply" "$1" "" \
    "Add multiply to fixture-lib and publish it so the consumer can use it." \
    "fixture_lib::multiply through cargo test."
}
mk_con_story() { # <epic-id> <"## Blocked by" line>   prints the story id
  mk_story consumer "Story: fixture-consumer uses multiply" "$1" "$2" \
    "Bump fixture-lib in the consumer and print the product." \
    "cargo run output of fixture-consumer."
}
if [ "$seed" = stories ]; then
  # epic first (stories are created in dependency order, the epic is not a story)
  epic=$(mk_epic)

  # lib: story, two tasks, publish task blocked on both
  lib_story=$(mk_lib_story "$epic")
  lib_t1=$(mk lib --parent "$lib_story" --labels complexity:low,ready-for-agent "Add multiply to fixture-lib")
  lib_t2=$(mk lib --parent "$lib_story" --labels complexity:low,ready-for-agent \
    --deps "blocked-by:$lib_t1" "Test multiply in fixture-lib")
  lib_pub=$(mk lib --parent "$lib_story" --no-inherit-labels --labels ready-for-human,complexity:low \
    --deps "blocked-by:$lib_t1,blocked-by:$lib_t2" "publish fixture-lib 0.2.0")

  # consumer: parentless story, bump task, task blocked on the bump
  con_story=$(mk_con_story "$epic" "lib $lib_pub")
  con_bump=$(mk consumer --parent "$con_story" --labels complexity:low,ready-for-agent "Bump fixture-lib to 0.2.0")
  mk consumer --parent "$con_story" --labels complexity:low,ready-for-agent \
    --deps "blocked-by:$con_bump" "Print multiply result" >/dev/null
fi

# --- --dag: four stories, expand-migrate-contract (ADR 0011) ---------------------
mk_dag_story() { # <repo> <title> <epic-id> <"## Blocked by" line, or empty>   prints the story id
  mk_story "$1" "$2" "$3" "$4" "$2 in the fixture's expand-migrate-contract shape." \
    "cargo test and cargo run output of the fixture crates."
}
if [ "$seed" = dag ]; then
  epic=$(mk_epic)

  expand=$(mk_dag_story lib "Story: lib expand" "$epic" "")
  e1=$(mk lib --parent "$expand" --labels complexity:low,ready-for-agent "Add multiply to fixture-lib")
  e2=$(mk lib --parent "$expand" --labels complexity:low,ready-for-agent \
    --deps "blocked-by:$e1" "Test multiply in fixture-lib")
  pub2=$(mk lib --parent "$expand" --no-inherit-labels --labels ready-for-human,complexity:low \
    --deps "blocked-by:$e1,blocked-by:$e2" "publish fixture-lib 0.2.0")

  migrate=$(mk_dag_story consumer "Story: consumer migrate" "$epic" "lib $pub2")
  m1=$(mk consumer --parent "$migrate" --labels complexity:low,ready-for-agent "Bump fixture-lib to 0.2.0")
  mk consumer --parent "$migrate" --labels complexity:low,ready-for-agent \
    --deps "blocked-by:$m1" "Switch consumer from add to multiply" >/dev/null

  contract=$(mk_dag_story lib "Story: lib contract" "$epic" "consumer $migrate")
  c1=$(mk lib --parent "$contract" --labels complexity:low,ready-for-agent "Remove add from fixture-lib")
  pub3=$(mk lib --parent "$contract" --no-inherit-labels --labels ready-for-human,complexity:low \
    --deps "blocked-by:$c1" "publish fixture-lib 0.3.0")

  cbump=$(mk_dag_story consumer "Story: consumer bump" "$epic" "lib $pub3")
  mk consumer --parent "$cbump" --labels complexity:low,ready-for-agent "Bump fixture-lib to 0.3.0" >/dev/null
fi

# --- --stage-boundary: what /spec-to-stories leaves behind, no tasks ---------
if [ "$seed" = stage-boundary ]; then
  spec_rel=specs/multiply.md   # relative to the epic bead's repo, the root (header, "Spec:")
  mkdir -p "$out/specs"
  cat > "$out/$spec_rel" <<'T'
# Spec: multiply

Add multiply to fixture-lib and publish it as 0.2.0. The consumer bumps fixture-lib
and prints the product.
T
  epic=$(mk_epic --body-file - <<T
Add multiply to fixture-lib and use it from the consumer.

Spec: $spec_rel
T
)
  mk_lib_story "$epic" >/dev/null
  mk_con_story "$epic" "lib publish fixture-lib 0.2.0 (not created yet)" >/dev/null
fi

echo "fixture workspace: $out"
