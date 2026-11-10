#!/usr/bin/env bash
# Checks a worktree's tip once per tree (glossary: Check record). Keyed by the tip's tree SHA:
# a green record under <owner>/.tmp/checks/<tree>/record is printed and the script exits 0 with
# no make run. Otherwise it runs make check in the worktree with TMPDIR inside the worktree's
# .tmp, both streams to <owner>/.tmp/checks/<tree>/log, writes "command=make check exit=<n>" to
# record, prints that line (and on a red the log's last forty lines) and exits with the check's
# status. A worktree that is not a git checkout, or an owner with no check target (the
# orchestration doc's make database query), is one refusal line, a non-zero exit and no record.
# Usage: scripts/check.sh <worktree path> <owner>
set -uo pipefail
[ "$#" = 2 ] || { echo "check.sh refused: usage: check.sh <worktree path> <owner>"; exit 2; }
wt=$1 owner=$2

top=$(git -C "$wt" rev-parse --show-toplevel 2>/dev/null) \
  && [ "$top" = "$(cd "$wt" && pwd -P)" ] \
  || { echo "check.sh refused: $wt is not a git checkout"; exit 2; }
tree=$(git -C "$wt" rev-parse 'HEAD^{tree}' 2>/dev/null) \
  || { echo "check.sh refused: $wt has no commit to check"; exit 2; }

dir=$owner/.tmp/checks/$tree
green="command=make check exit=0"
if [ -f "$dir/record" ] && [ "$(cat "$dir/record")" = "$green" ]; then
  cat "$dir/record"; exit 0
fi

(set +o pipefail; make -C "$owner" -pRrq : 2>/dev/null | awk '/^# Not a target:/{n=1;next} /^check::?([^=:]|$)/&&!n{c=1; if (/^check::? *[^ :]/) f=1} c&&/^#  (commands|recipe) to execute/{f=1} /^$/{c=0} {n=0} END{exit !f}') \
  || { echo "check.sh refused: no check target in $owner; run /dev:setup-repo there"; exit 2; }

mkdir -p "$wt/.tmp" "$dir" 2>/dev/null || { echo "check.sh refused: cannot create $dir"; exit 2; }
TMPDIR=$(cd "$wt/.tmp" && pwd -P) make -C "$wt" check >"$dir/log" 2>&1
rc=$?
echo "${green%0}$rc" > "$dir/record"
cat "$dir/record"
[ "$rc" = 0 ] || tail -n 40 "$dir/log"
exit "$rc"
