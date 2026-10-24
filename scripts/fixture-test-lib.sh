#!/usr/bin/env bash
# Helpers shared by the fixture tests (scripts/test-fixture-*.sh, test-lint-skill-docs.sh,
# test-guard-rm.sh, test-glossary-lint.sh, test-setup-skill.sh, test-setup-repo-skill.sh,
# test-ci-workflow.sh).
# The bead helpers read $out, the fixture workspace, when called; sets fails=0, which check
# counts up and report_fails ends the run on.
fails=0
check() { # <description> <command...>
  local d=$1; shift
  if "$@" >/dev/null 2>&1; then echo "ok   $d"; else echo "FAIL $d"; fails=$((fails+1)); fi
}
# The one footer, as a script's last statement: a blank line, then "all passed" (the script
# then ends 0) or "<n> failed" (exit 1).
report_fails() {
  echo
  if [ "$fails" = 0 ]; then echo "all passed"; else echo "$fails failed"; exit 1; fi
}
eq() { [ "$1" = "$2" ]; }
# True when <dir> is a git repo's own top level. A throwaway repo checks this after init and
# before any add or commit: git discovers upward, so after a failed init an add -A and commit
# would land in the enclosing checkout.
is_repo_top() { # <dir>
  local top
  top=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) && [ "$top" = "$(cd "$1" && pwd -P)" ]
}
# Front matter of a SKILL.md: the lines between the opening and closing ---.
front() { awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$1"; }
# Native blockers of bead <id> in <repo>: the ids it depends on with type blocks, sorted, comma-joined.
blockers() { # <repo> <id>
  field "$1" "$2" '[.dependencies // [] | .[] | select(.dependency_type=="blocks") | .id] | sort | join(",")'
}
# Build the fixture workspace at $out with fixture-workspace.sh <seed flag> (the phased tests'
# seed step); exits on a failed build.
build_fixture() { "${repo_root:?}/scripts/fixture-workspace.sh" "$@" "${out:?}" >/dev/null || { echo "FAIL build fixture"; exit 1; }; }
# Scratch dir for one self-contained run, $repo_root/.fixtures/<name>.XXXXXX in $scratch, removed
# by the EXIT trap this installs (replacing any the caller set): one per run, so concurrent runs
# (parallel review subagents) do not race on the same fixture; under .fixtures/, never $TMPDIR,
# because the sandbox scopes a subagent's file edits to the session's working directories
# (chezmoi-66n, chezmoi-3ev). A caller that rebuilds its fixture builds it inside $scratch, so the
# mktemp name is never free for another run to draw. The phased tests (fixture-phases.sh's
# callers, test-fixture-triage.sh) keep their fixed per-case paths on purpose: seed and assert
# are separate processes with a briefed skill run between them, and a person drives them one
# at a time.
scratch_dir() { # <name>
  mkdir -p "${repo_root:?}/.fixtures" && scratch=$(mktemp -d "$repo_root/.fixtures/$1.XXXXXX") || return 1
  trap 'rm -rf "$scratch"' EXIT
}
# bd init walks up to the enclosing checkout and would sync with its origin.
# A git trace catches that even when the remote answers, and the check runs before the build's
# exit status so a build that dies on the remote says why. It sees only contact made through
# the git binary, the way bd reaches a git+ssh remote; dolt's own HTTP transport would slip by.
# Both read $script (fixture-workspace.sh) and $out; the trace sits beside OUT, which each build deletes.
no_remote_git() { # the trace exists (every build runs git init) and has no remote-contacting git
  [ -s "$out.git-trace" ] && ! grep -qE "trace: (built-in|exec): git (ls-remote|clone|fetch|push|pull)( |$)" "$out.git-trace"
}
traced_build() { # <what> <fixture-workspace.sh args...>   exits on a failed build
  local rc
  rm -f "$out.git-trace"
  GIT_TRACE=$out.git-trace "${script:?set script to fixture-workspace.sh}" "${@:2}" >/dev/null; rc=$?
  check "$1: runs no git command that contacts a remote" no_remote_git
  [ "$rc" = 0 ] || { echo "FAIL build $1"; exit 1; }
}
bdj() { bd -C "${out:?set out to the fixture workspace}/$1" "${@:2}"; }
all() { bdj "$1" list --all --json --limit 0; }
field() { # <repo> <id> <jq expr on the issue>
  bdj "$1" show "$2" --json | jq -r ".[0] | $3"
}
# Id of the single bead in <repo> matching a jq predicate; empty (and a failed check) unless exactly one.
one() { # <repo> <jq predicate>
  local ids; ids=$(all "$1" | jq -r ".[] | select($2) | .id")
  [ "$(grep -c . <<<"$ids")" = 1 ] && printf '%s' "$ids"
}
# Full state of one repo with ids replaced by titles, so two builds compare equal.
snapshot() { # <repo>
  local a ids id shown=()
  a=$(all "$1")
  for id in $(jq -r '.[].id' <<<"$a"); do shown+=("$(bdj "$1" show "$id" --json)"); done
  jq -S --argjson all "$a" -s '
    ($all | map({(.id): .title}) | add // {}) as $t
    | map(.[0] | {title, issue_type, status, labels: (.labels // [] | sort), external_ref,
        description: ((.description // "") | gsub("\\b(lib|consumer|workspace)-[a-z0-9]+(\\.[0-9]+)*"; "ID")),
        parent: (.parent // null | if . then $t[.] else null end),
        dependencies: ((.dependencies // []) | map({type: .dependency_type, on: .title}) | sort_by(.on, .type))})
    | sort_by(.title)' < <([ "${#shown[@]}" -eq 0 ] || printf '%s\n' "${shown[@]}")
}

