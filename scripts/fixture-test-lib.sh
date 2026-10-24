#!/usr/bin/env bash
# Helpers shared by the scripted tests (scripts/test-*.sh).
# Sets fails=0, which check and the callers' own counters count up and report_fails ends the run on.
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
# Scratch dir for one self-contained run, $repo_root/.fixtures/<name>.XXXXXX in $scratch, removed
# by the EXIT trap this installs: one per run, so concurrent runs do not race on the same fixture;
# under .fixtures/, never $TMPDIR, because the sandbox scopes a subagent's file edits to the
# session's working directories. A caller that rebuilds its fixture builds it inside $scratch,
# so the mktemp name is never free for another run to draw. The EXIT trap it installs replaces
# any EXIT trap the caller set, so a caller needing its own cleanup chains it after this call.
scratch_dir() { # <name>
  mkdir -p "${repo_root:?}/.fixtures" && scratch=$(mktemp -d "$repo_root/.fixtures/$1.XXXXXX") || return 1
  trap 'rm -rf "$scratch"' EXIT
}
