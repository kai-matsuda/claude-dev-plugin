#!/usr/bin/env bash
# The forge-check wait (glossary: Forge-check wait) as one plain command, so a narrow sandbox
# exemption or permission rule can match it: waits until the PR's head is the pushed <tip SHA> and
# its checks have registered, then until they have finished. It reads no verdict: Delivery step 4
# reads the checks afterwards. Output lines, one exit status:
#   checks finished                   exit 0; no check is pending now. A red check also gets here:
#                                     the step's read of the checks decides pass or fail.
#   forge error: <text>               exit 1, at once: the forge CLI's config error (`unable to get or
#                                     create config file` or `failed to read configuration`) from a
#                                     read in the loop, never looped on to the caller's timeout
#   refused: <reason>                 exit 2, a wrong usage or forge
# A wait that outlasts its caller's `timeout` is killed by it and prints nothing: the caller reads
# the checks anyway. Other failed reads (a head not yet seen, "no checks reported") are retried.
# gh: loops on `gh pr view --json headRefOid` and a `gh pr checks --json name` probe every
# FORGE_WAIT_SLEEP seconds (default 10), then waits with `gh pr checks --watch --interval 30`, whose
# own output and exit status are dropped (a config error there surfaces in the step's read). tea:
# loops on the pushed tip's commit status every FORGE_WAIT_SLEEP seconds (default 30) until it has a
# status and none is pending; needs jq. <repo> is gh's owner/name slug (tea finds its repo from
# <owner>, the checkout's absolute path); <pr> is unused on tea.
# Usage: scripts/forge-wait.sh <owner> <gh|tea> <repo> <pr> <tip SHA>
set -uo pipefail
refuse() { echo "refused: $*"; exit 2; }
[ "$#" = 5 ] || refuse "usage: forge-wait.sh <owner> <gh|tea> <repo> <pr> <tip SHA>"
owner=$1 forge=$2 repo=$3 pr=$4 tip=$5
cfg_err() { # <text>: exit 1 with it when it is the forge CLI's config error
  case $1 in
    *'unable to get or create config file'*|*'failed to read configuration'*) echo "forge error: $1"; exit 1 ;;
  esac
}
case $forge in
  gh)
    nap=${FORGE_WAIT_SLEEP:-10}
    while :; do
      h=$(gh pr view "$pr" --repo "$repo" --json headRefOid -q .headRefOid 2>&1); cfg_err "$h"
      if [ "$h" = "$tip" ]; then
        c=$(gh pr checks "$pr" --repo "$repo" --json name 2>&1) && break
        cfg_err "$c"
      fi
      sleep "$nap"
    done
    gh pr checks "$pr" --repo "$repo" --watch --interval 30 >/dev/null 2>&1
    ;;
  tea)
    nap=${FORGE_WAIT_SLEEP:-30}
    while :; do
      s=$(tea api --repo "$owner" "repos/{owner}/{repo}/commits/$tip/status" 2>&1); cfg_err "$s"
      echo "$s" | jq -e '.total_count > 0 and ([.statuses[] | select(.status == "pending")] | length == 0)' >/dev/null 2>&1 && break
      sleep "$nap"
    done
    ;;
  *) refuse "forge must be gh or tea, not $forge" ;;
esac
echo "checks finished"
