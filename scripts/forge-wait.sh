#!/usr/bin/env bash
# The forge-check wait (glossary: Forge-check wait) as one plain command, so a narrow sandbox
# exemption or permission rule can match it: waits until the PR's head is the pushed <tip SHA> and
# its checks have registered, then until they have finished. It reads no verdict: Delivery step 4
# reads the checks afterwards. Output lines, one exit status:
#   checks finished                   exit 0; no check is pending now. A red check also gets here:
#                                     the step's read of the checks decides pass or fail.
#   forge error: <text>               exit 1, at once: the forge CLI's config error (`unable to get or
#                                     create config file` or `failed to read configuration`) from a
#                                     read in the loop or the watch, never looped on to the caller's
#                                     timeout; or a gh watch that failed with checks still pending;
#                                     or a gh head that moved off the tip during the wait
#   refused: <reason>                 exit 2, a wrong usage, an unknown forge, or tea without jq
# gh and tea stderr is kept apart from the compared head SHA and the JSON, but scanned for the config
# error, so a stray warning never keeps the head from equalling the tip.
# A wait that outlasts its caller's `timeout` is killed by it and prints nothing: the caller reads
# the checks anyway. Other failed reads (a head not yet seen, "no checks reported") are retried,
# and so is a read that fails for a reason outside the wait, such as a sandbox network denial: it
# loops to the caller's `timeout` with no output, so a repeat of it is the caller's to spot.
# gh: loops on `gh pr view --json headRefOid` and a `gh pr checks --json name` probe every
# FORGE_WAIT_SLEEP seconds (default 10), then waits with `gh pr checks --watch --interval 30`.
# A watch that exits non-zero is a red check or a failed watch: a recheck of the pending checks
# (`gh pr checks --json bucket`) tells them apart, so `checks finished` prints only when the recheck
# reads and counts none pending; a config error or a recheck that fails or counts one pending
# prints `forge error: <watch output>` and exits 1. gh reads checks by PR number, so the head is
# verified at <tip SHA> before the probe and read again after the watch and recheck (a failed read
# of it is retried like the first, a config error exits 1): a head that is no longer the tip (a push
# to the PR meanwhile) prints `forge error: head moved: the PR head is <head>, not the verified tip
# <tip SHA>` and exits 1, never `checks finished`. So `checks finished` is for the tip's checks as
# of that second head read; Delivery step 4's later read of the checks is by PR number again.
# tea: loops on the pushed tip's commit status
# every FORGE_WAIT_SLEEP seconds (default 30) until it has a status and none is pending; needs jq on PATH (refused: exit 2 without it).
# <repo> is gh's owner/name slug and <pr> its PR number: tea uses neither (it finds its repo from
# <owner>, the checkout's absolute path, and reads the status by <tip SHA>).
# Usage: scripts/forge-wait.sh <owner> <gh|tea> <repo> <pr> <tip SHA>
set -uo pipefail
refuse() { echo "refused: $*"; exit 2; }
[ "$#" = 5 ] || refuse "usage: forge-wait.sh <owner> <gh|tea> <repo> <pr> <tip SHA>"
owner=$1 forge=$2 repo=$3 pr=$4 tip=$5
errf=$(mktemp "${TMPDIR:-/tmp}/forge-wait.XXXXXX") || refuse "no scratch file"
trap 'rm -f "$errf"' EXIT
# cfg_err <stdout>: exit 1 with the text when stdout or the stderr of the last call (in $errf) holds
# the forge CLI's config error; the compared SHA and JSON are stdout alone
cfg_err() {
  local t="$1$(cat "$errf")"
  case $t in
    *'unable to get or create config file'*|*'failed to read configuration'*) echo "forge error: $t"; exit 1 ;;
  esac
}
case $forge in
  gh)
    nap=${FORGE_WAIT_SLEEP:-10}
    while :; do
      h=$(gh pr view "$pr" --repo "$repo" --json headRefOid -q .headRefOid 2>"$errf"); cfg_err "$h"
      if [ "$h" = "$tip" ]; then
        c=$(gh pr checks "$pr" --repo "$repo" --json name 2>"$errf") && break
        cfg_err "$c"
      fi
      sleep "$nap"
    done
    if ! w=$(gh pr checks "$pr" --repo "$repo" --watch --interval 30 2>"$errf"); then
      cfg_err "$w"; w=$w$(cat "$errf")
      p=$(gh pr checks "$pr" --repo "$repo" --json bucket -q '[.[] | select(.bucket == "pending")] | length' 2>"$errf"); cfg_err "$p"
      if [ "$p" != 0 ]; then echo "forge error: $w"; exit 1; fi
    fi
    # gh pr checks reads by PR number, so the checks just waited on are the tip's only if the head is
    # still the verified tip
    while :; do
      h=$(gh pr view "$pr" --repo "$repo" --json headRefOid -q .headRefOid 2>"$errf"); rc=$?; cfg_err "$h"
      [ "$rc" = 0 ] && break
      sleep "$nap"
    done
    if [ "$h" != "$tip" ]; then
      echo "forge error: head moved: the PR head is $h, not the verified tip $tip"; exit 1
    fi
    ;;
  tea)
    command -v jq >/dev/null || refuse "tea needs jq on PATH"
    nap=${FORGE_WAIT_SLEEP:-30}
    while :; do
      s=$(tea api --repo "$owner" "repos/{owner}/{repo}/commits/$tip/status" 2>"$errf"); cfg_err "$s"
      echo "$s" | jq -e '.total_count > 0 and ([.statuses[] | select(.status == "pending")] | length == 0)' >/dev/null 2>&1 && break
      sleep "$nap"
    done
    ;;
  *) refuse "forge must be gh or tea, not $forge" ;;
esac
echo "checks finished"
