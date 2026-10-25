#!/usr/bin/env bash
# Helpers shared by the fixture tests (scripts/test-fixture-*.sh, test-lint-skill-docs.sh,
# test-guard-rm.sh, test-glossary-lint.sh, test-setup-skill.sh, test-setup-repo-skill.sh,
# test-ci-workflow.sh, test-readme.sh).
# Every helper is fx_-prefixed, so it neither shadows nor is shadowed by a sourcing script's own
# functions. The bead helpers read $out, the fixture workspace, when called; sets fails=0, which
# fx_check counts up and fx_report_fails ends the run on.
fails=0
fx_check() { # <description> <command...>
  local d=$1; shift
  if "$@" >/dev/null 2>&1; then echo "ok   $d"; else echo "FAIL $d"; fails=$((fails+1)); fi
}
# The one footer, as a script's last statement: a blank line, then "all passed" (the script
# then ends 0) or "<n> failed" (exit 1).
fx_report_fails() {
  echo
  if [ "$fails" = 0 ]; then echo "all passed"; else echo "$fails failed"; exit 1; fi
}
fx_eq() { [ "$1" = "$2" ]; }
# True when <dir> is a git repo's own top level. A throwaway repo checks this after init and
# before any add or commit: git discovers upward, so after a failed init an add -A and commit
# would land in the enclosing checkout.
fx_is_repo_top() { # <dir>
  local top
  top=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) && [ "$top" = "$(cd "$1" && pwd -P)" ]
}
# The one way a test script (scripts/test-*.sh; make ci's check-test-git-init.sh refuses a
# git init anywhere else in one) makes a throwaway git repo: an empty repo on main at <dir>, its
# git dir at <git dir> (default <dir>.gd), with the test identity set and hooks and signing off
# in its config, so later git -C <dir> calls need no flags. Fails unless <dir> is the new repo's
# own top level: under the sandbox git init can exit 0 leaving no HEAD (the hook template copy and
# the config write are denied), and git then discovers upward, so an add and commit land in the
# enclosing checkout (21f770c).
# Separate git dir and empty template: the sandbox refuses writes inside any dir named .git.
fx_git_repo() { # <dir> [<git dir>]
  local dir=$1 gd=${2:-$1.gd} parent
  mkdir -p "$dir" && parent=$(cd "$dir/.." && pwd -P) || return 1
  GIT_CEILING_DIRECTORIES=$parent git init -q -b main --template= --separate-git-dir="$gd" "$dir" || return 1
  GIT_CEILING_DIRECTORIES=$parent fx_is_repo_top "$dir" || return 1
  git -C "$dir" config user.name Fixture && git -C "$dir" config user.email fixture@example.invalid \
    && git -C "$dir" config core.hooksPath /dev/null && git -C "$dir" config hook.commitlint.enabled false \
    && git -C "$dir" config commit.gpgsign false
}
# Front matter of a SKILL.md: the lines between the opening and closing ---.
fx_front() { awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$1"; }
# Native blockers of bead <id> in <repo>: the ids it depends on with type blocks, sorted, comma-joined.
fx_blockers() { # <repo> <id>
  fx_field "$1" "$2" '[.dependencies // [] | .[] | select(.dependency_type=="blocks") | .id] | sort | join(",")'
}
# Build the fixture workspace at $out with fixture-workspace.sh <seed flag> (the phased tests'
# seed step); exits on a failed build.
fx_build_fixture() { fx_cache_drop; "${repo_root:?}/scripts/fixture-workspace.sh" "$@" "${out:?}" >/dev/null || { echo "FAIL build fixture"; exit 1; }; }
# Scratch dir for one self-contained run, $repo_root/.fixtures/<name>.XXXXXX in $scratch, removed
# by the lib's EXIT trap: one per run, so concurrent runs (parallel review subagents) do not
# race on the same fixture; under .fixtures/, never $TMPDIR, because the sandbox scopes a
# subagent's file edits to the session's working directories (chezmoi-66n, chezmoi-3ev). A caller that rebuilds its fixture builds it inside $scratch, so the
# mktemp name is never free for another run to draw. The phased tests (fixture-phases.sh's
# callers, test-fixture-triage.sh) keep their fixed per-case paths on purpose: seed and assert
# are separate processes with a briefed skill run between them, and a person drives them one
# at a time.
fx_scratch_dir() { # <name>
  mkdir -p "${repo_root:?}/.fixtures" && scratch=$(mktemp -d "$repo_root/.fixtures/$1.XXXXXX")
}
# bd init walks up to the enclosing checkout and would sync with its origin.
# A git trace catches that even when the remote answers, and the check runs before the build's
# exit status so a build that dies on the remote says why. It sees only contact made through
# the git binary, the way bd reaches a git+ssh remote; dolt's own HTTP transport would slip by.
# Both read $script (fixture-workspace.sh) and $out; the trace sits beside OUT, which each build deletes.
fx_no_remote_git() { # the trace exists (every build runs git init) and has no remote-contacting git
  [ -s "$out.git-trace" ] && ! grep -qE "trace: (built-in|exec): git (ls-remote|clone|fetch|push|pull)( |$)" "$out.git-trace"
}
fx_traced_build() { # <what> <fixture-workspace.sh args...>   exits on a failed build
  local rc
  rm -f "$out.git-trace"; fx_cache_drop
  GIT_TRACE=$out.git-trace "${script:?set script to fixture-workspace.sh}" "${@:2}" >/dev/null; rc=$?
  fx_check "$1: runs no git command that contacts a remote" fx_no_remote_git
  [ "$rc" = 0 ] || { echo "FAIL build $1"; exit 1; }
}
# The bead reads. bd list --json carries every field the assertions read, so each database is
# listed once per process and every lookup reads that list: no bd show per bead. The list sits
# in $fx_cache, keyed by the repo's path; $$ is the same in every $(...) subshell, where most
# reads run, so one subshell's list serves the next. A build, or any write through fx_bdj (a
# raw bd write leaves the lists stale), drops every list; sourcing drops one left by a killed
# process that had this pid, and the EXIT trap the lib installs removes the cache.
fx_cache_drop() { rm -rf "${fx_cache:?}"; }
fx_bdj() { # <repo> <bd args...>
  case $2 in list|show|ready) ;; *) fx_cache_drop ;; esac
  bd -C "${out:?set out to the fixture workspace}/$1" "${@:2}"
}
# Every bead in <repo>, as bd list --json gives it plus, on each dependency, the id,
# dependency_type and title bd show would give it.
fx_all() { # <repo>
  local f
  f=$fx_cache/$(printf '%s' "${out:?}/$1" | cksum | cut -d' ' -f1).json
  if [ ! -s "$f" ]; then
    mkdir -p "$fx_cache" && fx_bdj "$1" list --all --json --limit 0 | jq '
      (map({(.id): .title}) | add // {}) as $t
      | map(if .dependencies then .dependencies |= map(. + {id: .depends_on_id, dependency_type: .type, title: $t[.depends_on_id]}) else . end)
      ' > "$f.tmp" && mv "$f.tmp" "$f" || { rm -f "$f.tmp"; return 1; }
  fi
  cat "$f"
}
fx_field() { # <repo> <id> <jq expr on the issue>
  fx_all "$1" | jq -r --arg id "$2" ".[] | select(.id == \$id) | $3"
}
# The children of bead <id> in <repo>, closed ones too, as a JSON array (bd list --all --parent).
fx_children() { # <repo> <id>
  fx_all "$1" | jq --arg id "$2" 'map(select(.parent == $id))'
}
# Id of the single bead in <repo> matching a jq predicate; empty (and a failed check) unless exactly one.
fx_one() { # <repo> <jq predicate>
  local ids; ids=$(fx_all "$1" | jq -r ".[] | select($2) | .id")
  [ "$(grep -c . <<<"$ids")" = 1 ] && printf '%s' "$ids"
}
# Full state of one repo with ids replaced by titles, so two builds compare equal.
fx_snapshot() { # <repo>
  fx_all "$1" | jq -S '
    (map({(.id): .title}) | add // {}) as $t
    | map({title, issue_type, status, labels: (.labels // [] | sort), external_ref,
        description: ((.description // "") | gsub("\\b(lib|consumer|workspace)-[a-z0-9]+(\\.[0-9]+)*"; "ID")),
        parent: (.parent // null | if . then $t[.] else null end),
        dependencies: ((.dependencies // []) | map({type: .dependency_type, on: .title}) | sort_by(.on, .type))})
    | sort_by(.title)'
}
fx_cache=${repo_root:?}/.fixtures/.bd-cache.$$
fx_cache_drop
trap 'rm -rf "${fx_cache:?}"; [ -z "${scratch:-}" ] || rm -rf "${scratch:?}"' EXIT
