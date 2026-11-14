#!/usr/bin/env bash
# Tests for scripts/forge-wait.sh <owner> <gh|tea> <repo> <pr> <tip SHA>, the Forge-check wait
# script: run against stub gh and tea on PATH (FORGE_WAIT_SLEEP=0), reading its output lines and
# exit status. Covers, for gh and for tea: the forge CLI's config error (exit 1 at once), a head
# not yet at the tip, checks registered then passing, and checks failing (both exit 0 with
# "checks finished": the checks' verdict is read by Delivery step 4, not here), a gh head that moves
# during the wait (exit 1, the moved head named), a gh watch that fails
# for another reason (exit 1 unless no check is pending), a head read failing for another reason
# (retried), a recheck config error, stderr kept out of the compared values, tea without jq and a
# wrong usage.
# Each stub answers from a file of lines (one per call, the last one repeating) and counts its calls.
# Usage: scripts/test-forge-wait-script.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_scratch_dir, fx_check, fx_eq, fx_report_fails
script=$repo_root/scripts/forge-wait.sh

fx_scratch_dir forge-wait-script
scratch=$(cd "$scratch" && pwd -P)
bin=$scratch/bin st=$scratch/state
mkdir -p "$bin" "$st"

# next <name>: print the first line of $st/<name>, dropping it while more lines remain; count calls
cat > "$bin/next" <<'EOF'
#!/usr/bin/env bash
f=$ST/$1; echo x >> "$f.calls"
line=$(head -n 1 "$f"); [ "$(wc -l < "$f")" -gt 1 ] && sed -i.bak 1d "$f" && rm -f "$f.bak"
case $line in "!"*) echo "${line#!}"; exit 1 ;; esac
echo "$line"
EOF
# A line starting with "!" makes the stub print the rest and exit 1. gh: `pr view` prints the next
# head line; `pr checks --json name` prints the next probe line and fails unless the line is a JSON
# list; `pr checks --watch` prints the next watch line; `pr checks --json bucket` prints the next
# recheck line (the count of pending checks)
cat > "$bin/gh" <<'EOF'
#!/usr/bin/env bash
[ -f "$ST/warn" ] && echo "warning: a new gh is available" >&2
case "$*" in
  *"pr view"*) "$ST/../bin/next" head ;;
  *"--watch"*) "$ST/../bin/next" watch ;;
  *"--json bucket"*) "$ST/../bin/next" recheck ;;
  *"--json name"*) out=$("$ST/../bin/next" probe); echo "$out"; case $out in "["*) ;; *) exit 1 ;; esac ;;
esac
EOF
cat > "$bin/tea" <<'EOF'
#!/usr/bin/env bash
[ -f "$ST/warn" ] && echo "warning: a new tea is available" >&2
"$ST/../bin/next" status
EOF
chmod +x "$bin/next" "$bin/gh" "$bin/tea"

# put <name> <content>...: write the answer file of a stub, one line per argument; clear the counts
put() { local n=$1; shift; printf '%s\n' "$@" > "$st/$n"; rm -f "$st/$n.calls"; }
calls() { [ -f "$st/$1.calls" ] && wc -l < "$st/$1.calls" | tr -d ' ' || echo 0; }
run() { out=$(PATH="$bin:$PATH" ST=$st FORGE_WAIT_SLEEP=0 "$script" "$@" 2>&1); rc=$?; }
cfg='unable to get or create config file: permission denied'
tip=abc123
pend='{"total_count":1,"statuses":[{"status":"pending"}]}'
none='{"total_count":0,"statuses":[]}'
red='{"total_count":1,"statuses":[{"status":"failure"}]}'
green='{"total_count":1,"statuses":[{"status":"success"}]}'

# gh: config error from the head read
put head "$cfg"; put probe '[{"name":"x"}]'; put watch ok
run /o gh org/r 7 $tip
fx_check "gh config error on head: exits 1" fx_eq "$rc" 1
fx_check "gh config error on head: names it" fx_eq "$out" "forge error: $cfg"
fx_check "gh config error on head: stops at the first read" fx_eq "$(calls head)" 1

# gh: config error from the checks-registered probe
put head $tip; put probe "failed to read configuration: x"; put watch ok
run /o gh org/r 7 $tip
fx_check "gh config error on probe: exits 1" fx_eq "$rc" 1
fx_check "gh config error on probe: names it" fx_eq "$out" "forge error: failed to read configuration: x"

# gh: head not yet at the tip is waited out, the probe is not read before it is
put head old old $tip; put probe '[{"name":"x"}]'; put watch ok
run /o gh org/r 7 $tip
fx_check "gh head behind: exits 0" fx_eq "$rc" 0
fx_check "gh head behind: finished line" fx_eq "$out" "checks finished"
fx_check "gh head behind: read the head three times, then once after the watch" fx_eq "$(calls head)" 4
fx_check "gh head behind: probed once" fx_eq "$(calls probe)" 1

# gh: checks not yet registered, then registered and passing
put head $tip; put probe "no checks reported on the 'x' branch" '[{"name":"x"}]'; put watch ok
run /o gh org/r 7 $tip
fx_check "gh registered then passing: exits 0" fx_eq "$rc" 0
fx_check "gh registered then passing: finished line" fx_eq "$out" "checks finished"
fx_check "gh registered then passing: probed twice" fx_eq "$(calls probe)" 2
fx_check "gh registered then passing: watched once" fx_eq "$(calls watch)" 1

# gh: the watch ends on failing checks; the wait is still over
put head $tip; put probe '[{"name":"x"}]'; put watch "!x fail"; put recheck 0
run /o gh org/r 7 $tip
fx_check "gh checks failing: exits 0" fx_eq "$rc" 0
fx_check "gh checks failing: finished line only" fx_eq "$out" "checks finished"

# gh: the watch fails for another reason and checks are still pending, or cannot be read
put head $tip; put probe '[{"name":"x"}]'; put watch "!dial tcp: operation not permitted"; put recheck 2
run /o gh org/r 7 $tip
fx_check "gh watch failed, checks pending: exits 1" fx_eq "$rc" 1
fx_check "gh watch failed, checks pending: names the watch output" fx_eq "$out" "forge error: dial tcp: operation not permitted"
put recheck "!dial tcp: operation not permitted"
run /o gh org/r 7 $tip
fx_check "gh watch failed, recheck failed: exits 1" fx_eq "$rc" 1
fx_check "gh watch failed, recheck failed: no finished line" fx_eq "$out" "forge error: dial tcp: operation not permitted"

# gh: config error from the watch
put watch "!$cfg"
run /o gh org/r 7 $tip
fx_check "gh config error on watch: exits 1" fx_eq "$rc" 1
fx_check "gh config error on watch: names it" fx_eq "$out" "forge error: $cfg"

# gh: the watch fails, then the recheck hits the config error: that error is reported, not the watch output
put head $tip; put probe '[{"name":"x"}]'; put watch "!dial tcp: operation not permitted"; put recheck "!$cfg"
run /o gh org/r 7 $tip
fx_check "gh recheck config error: exits 1" fx_eq "$rc" 1
fx_check "gh recheck config error: names the recheck's error" fx_eq "$out" "forge error: $cfg"

# gh: a stderr warning on every call stays out of the compared head and the counts
: > "$st/warn"
put head $tip; put probe '[{"name":"x"}]'; put watch "!x fail"; put recheck 0
run /o gh org/r 7 $tip
fx_check "gh stderr warning: exits 0" fx_eq "$rc" 0
fx_check "gh stderr warning: finished line only" fx_eq "$out" "checks finished"
rm -f "$st/warn"

# gh: the head moves during the wait (a push after the verified read): the checks watched are not the
# tip's, so no finished line, exit 1 and a line naming the moved head; also when the watch ended red
put head $tip def456; put probe '[{"name":"x"}]'; put watch ok
run /o gh org/r 7 $tip
fx_check "gh head moved during the wait: exits 1" fx_eq "$rc" 1
fx_check "gh head moved during the wait: names the moved head" fx_eq "$out" "forge error: head moved: the PR head is def456, not the verified tip $tip"
fx_check "gh head moved during the wait: re-read the head after the watch" fx_eq "$(calls head)" 2
put head $tip def456; put probe '[{"name":"x"}]'; put watch "!x fail"; put recheck 0
run /o gh org/r 7 $tip
fx_check "gh head moved, checks failing: exits 1" fx_eq "$rc" 1
fx_check "gh head moved, checks failing: names the moved head" fx_eq "$out" "forge error: head moved: the PR head is def456, not the verified tip $tip"
# the head re-read fails for a config error
put head $tip "!$cfg"; put probe '[{"name":"x"}]'; put watch ok
run /o gh org/r 7 $tip
fx_check "gh config error on the head re-read: exits 1" fx_eq "$rc" 1
fx_check "gh config error on the head re-read: names it" fx_eq "$out" "forge error: $cfg"

# gh: a head read that fails for a non-config reason is retried
put head "!dial tcp: operation not permitted" $tip; put probe '[{"name":"x"}]'; put watch ok
run /o gh org/r 7 $tip
fx_check "gh head read failed: exits 0" fx_eq "$rc" 0
fx_check "gh head read failed: finished line" fx_eq "$out" "checks finished"
fx_check "gh head read failed: read the head twice, then once after the watch" fx_eq "$(calls head)" 3

# gh: a head re-read after the watch that fails for a non-config reason is retried, not read as a moved head
put head $tip "!dial tcp: operation not permitted" $tip; put probe '[{"name":"x"}]'; put watch ok
run /o gh org/r 7 $tip
fx_check "gh head re-read failed: exits 0" fx_eq "$rc" 0
fx_check "gh head re-read failed: finished line" fx_eq "$out" "checks finished"
fx_check "gh head re-read failed: read the head three times" fx_eq "$(calls head)" 3

# tea: config error
put status "$cfg"
run /o tea /o 7 $tip
fx_check "tea config error: exits 1" fx_eq "$rc" 1
fx_check "tea config error: names it" fx_eq "$out" "forge error: $cfg"
fx_check "tea config error: stops at the first read" fx_eq "$(calls status)" 1

# tea: no status yet (head not seen), then pending, then passing
put status "$none" "$pend" "$green"
run /o tea /o 7 $tip
fx_check "tea registered then passing: exits 0" fx_eq "$rc" 0
fx_check "tea registered then passing: finished line" fx_eq "$out" "checks finished"
fx_check "tea registered then passing: read three times" fx_eq "$(calls status)" 3

# tea: a stderr warning stays out of the JSON
: > "$st/warn"
put status "$green"
run /o tea /o 7 $tip
fx_check "tea stderr warning: exits 0" fx_eq "$rc" 0
fx_check "tea stderr warning: finished line only" fx_eq "$out" "checks finished"
rm -f "$st/warn"

# tea: no jq on PATH is refused, not waited out
mkdir -p "$scratch/nojq"; ln -sf "$bin/tea" "$scratch/nojq/tea"
for t in mktemp rm cat; do ln -sf "$(command -v $t)" "$scratch/nojq/$t"; done
put status "$green"
out=$(PATH="$scratch/nojq" ST=$st FORGE_WAIT_SLEEP=0 /bin/bash "$script" /o tea /o 7 $tip 2>&1); rc=$?
fx_check "tea without jq: exits 2" fx_eq "$rc" 2
fx_check "tea without jq: refused line" fx_eq "$out" "refused: tea needs jq on PATH"

# tea: failing checks end the wait too
put status "$pend" "$red"
run /o tea /o 7 $tip
fx_check "tea checks failing: exits 0" fx_eq "$rc" 0
fx_check "tea checks failing: finished line" fx_eq "$out" "checks finished"
fx_check "tea checks failing: read twice" fx_eq "$(calls status)" 2

# usage
run /o gh org/r 7
fx_check "too few args: exits 2" fx_eq "$rc" 2
fx_check "too few args: refused line" fx_eq "$out" "refused: usage: forge-wait.sh <owner> <gh|tea> <repo> <pr> <tip SHA>"
run /o hub org/r 7 $tip
fx_check "unknown forge: exits 2" fx_eq "$rc" 2
fx_check "unknown forge: refused line" fx_eq "$out" "refused: forge must be gh or tea, not hub"

fx_report_fails
