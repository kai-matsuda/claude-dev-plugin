#!/usr/bin/env bash
# Tests for bin/commit-trailers, the trailer hook that machine setup wires as a commit-msg hook
# (dev-ekcl, INFRA-47). Covers it run on message files in a throwaway repo, as git's hook would;
# the setup snippet's hook command run through `sh -c` with and without commit-trailers on PATH;
# and the same hook under real `git commit`s in throwaway repos, which need a git that runs
# config hooks (on one that does not, the refusal case fails and the off-PATH case passes with no
# hook run). The keys come from the repo-local dev.trailer.provenance, and global and system git
# config are switched off for the message-file runs, so no case depends on the machine's own
# config. What check-prereqs.sh prints of the snippet is tested in test-setup-skill.sh.
# Usage: scripts/test-commit-trailers-script.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_check, fx_scratch_dir, fx_git_repo, fx_report_fails
hook_snippet=$repo_root/skills/setup/commit-trailers.gitconfig
trailers=$repo_root/bin/commit-trailers

fx_scratch_dir commit-trailers-script; work=$scratch
hook_cmd=$(git config -f "$hook_snippet" hook.committrailers.command)
hookdir=$work/hookcmd
mkdir -p "$hookdir/bin" "$hookdir/empty"
printf '#!/bin/sh\nexit 7\n' >"$hookdir/bin/commit-trailers"; chmod +x "$hookdir/bin/commit-trailers"
fx_check "the snippet's hook command exits 0 when commit-trailers is not on PATH" env -i PATH="$hookdir/empty" /bin/sh -c "$hook_cmd" sh "$hookdir/msg"
fx_check "the snippet's hook command runs commit-trailers when it is on PATH" bash -c \
  'env -i PATH="$1" /bin/sh -c "$2" sh "$3"; [ $? = 7 ]' _ "$hookdir/bin" "$hook_cmd" "$hookdir/msg"
# The same hook through a real `git commit`, so git itself builds the command line: it appends
# its own "$@" to a config hook command, which the /bin/sh -c checks above do not reproduce
# (dev-ekcl.1.6). The hook entries and keys are installed from the snippet file. These cases need
# a git that runs config hooks; on one that does not, the other cases still pass and only the
# refusal case fails, so it alone proves the hook ran.
fx_scratch_dir realcommit; rcdir=$scratch
git_bin=$(command -v git); git_dir=$(dirname "$git_bin")
on_path=$repo_root/bin:$git_dir:/usr/bin:/bin   # commit-trailers calls sed, paste, awk and grep
rc_repo() { # <name>: a throwaway repo with the snippet's entries installed and the hook enabled
  fx_git_repo "$rcdir/$1" || return 1
  local k v
  while IFS='=' read -r k v; do
    git -C "$rcdir/$1" config --add "$k" "$v" || return 1
  done < <(git config -f "$hook_snippet" --list)
  git -C "$rcdir/$1" config hook.committrailers.enabled true
}
rc_commit() { # <repo name> <message> <PATH>: an empty commit by the absolute git, PATH as given
  env -i PATH="$3" HOME="$rcdir" GIT_CONFIG_NOSYSTEM=1 "$git_bin" -C "$rcdir/$1" commit -q --allow-empty -m "$2"
}
rc_refused() { # <repo name> <message> <PATH>: the commit fails and commit-trailers' error says why
  local err; err=$(rc_commit "$@" 2>&1); [ $? != 0 ] && grep -q "is not in the trailer block" <<<"$err"
}
rc_bad_msg=$(printf 'feat: x\n\nBead: dev-1\n\nprose after it\n\nRefs: INFRA-1')
# two repos built alike: only the PATH each commit runs with differs (the trailer hook on it or not).
# The off-PATH case would also pass if git never ran the hook; the refusal case on the same git
# and the same build is what shows the hook runs, so keep the two repos built by one function.
fx_check "the real-commit repo for the on-PATH cases is built" rc_repo ontrack
fx_check "the real-commit repo for the off-PATH case is built" rc_repo offtrack
fx_check "a real git commit with parseable Bead:/Refs: trailers succeeds with commit-trailers on PATH" \
  rc_commit ontrack "$(printf 'feat: x\n\nBead: dev-1\nRefs: INFRA-1')" "$on_path"
fx_check "a real git commit with a Bead: line outside the trailer block is refused" \
  rc_refused ontrack "$rc_bad_msg" "$on_path"
fx_check "a real git commit exits 0 when commit-trailers is not on PATH, whatever its trailers" \
  rc_commit offtrack "$rc_bad_msg" "$hookdir/empty:$git_dir"

trw=$work/trailers
fx_check "trailer hook: the throwaway repo is made" fx_git_repo "$trw/repo"
trailers_keys() { # <key>...: the repo's provenance keys, replacing any set
  git -C "$trw/repo" config --unset-all dev.trailer.provenance
  local k; for k in "$@"; do git -C "$trw/repo" config --add dev.trailer.provenance "$k"; done
  return 0
}
trailers_msg() { # <message>: run the trailer hook on it from the repo; sets tout, terr (stderr), trc;
  # $trw/msg0 keeps the message as written, to compare the file against after the run
  printf '%s\n' "$1" >"$trw/msg"
  cp "$trw/msg" "$trw/msg0"
  tout=$(cd "$trw/repo" && GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null "$trailers" "$trw/msg" 2>"$trw/err"); trc=$?
  terr=$(cat "$trw/err")
}
blocked() { [ "$trc" = 1 ] && [ -z "$tout" ] && grep -q "trailer block" <<<"$terr" && grep -q "references/issue-tracker.md" <<<"$terr"; }
fx_check "the trailer hook ships in bin/ and is executable" test -x "$trailers"
trailers_keys Bead Refs
trailers_msg $'feat(setup): ship the trailer hook\n\nBody.\n\nBead: dev-clo\nRefs: INFRA-1'
fx_check "trailer hook passes Bead:/Refs: lines git parses as trailers" test "$trc" = 0
trailers_msg $'fix: thing\n\nBead: dev-clo\n\nMore prose after the trailer.'
fx_check "trailer hook blocks a Bead: line outside the last paragraph, pointing at the tracker doc" blocked
# no keys: a no-op, even on a message that fails with keys set
trailers_keys
trailers_msg $'fix: thing\n\nBead: dev-clo\n\nMore prose after the trailer.'
fx_check "trailer hook with no keys set exits 0, prints nothing and leaves the file byte-identical" bash -c \
  '[ "$1" = 0 ] && [ -z "$2$3" ] && cmp -s "$4" "$5"' _ "$trc" "$tout" "$terr" "$trw/msg" "$trw/msg0"
# a joined-then-rejected message: the repair is made in memory, the file stays as written
trailers_keys Bead Refs
trailers_msg $'fix: thing\n\nBead: dev-a\n\nProse line.\nBead: dev-b\n\nBead: dev-c\n\nCo-Authored-By: Claude <noreply@anthropic.com>'
fx_check "trailer hook blocks a message its join would not fix" blocked
fx_check "trailer hook leaves a joined-then-rejected message file byte-identical" cmp -s "$trw/msg" "$trw/msg0"
# a key holding a regex character matches only itself
trailers_keys 'Ref.s'
trailers_msg $'fix: thing\n\nRefxs: A-1\n\nMore prose after the trailer.'
fx_check "trailer hook with key Ref.s does not check a Refxs: line" test "$trc" = 0
trailers_msg $'fix: thing\n\nRef.s: A-1\n\nMore prose after the trailer.'
fx_check "trailer hook with key Ref.s checks a Ref.s: line" blocked
trailers_keys 'Re\fs'
trailers_msg $'fix: thing\n\nRe\\fs: A-1\n\nMore prose after the trailer.'
fx_check "trailer hook with a backslash in a key checks that key literally" blocked
fx_check "trailer hook error shows a backslash key literally" grep -qF '(Re\fs)' <<<"$terr"
trailers_keys Bead Refs
# with keys set (Bead, Refs), an unreadable message file fails the hook; with no keys set it
# exits 0 before reading the file, so this case does not cover that path
printf '%s\n' $'fix: thing\n\nBead: dev-a' >"$trw/unreadable"
chmod 000 "$trw/unreadable"
fx_check "trailer hook fails on an unreadable message file" bash -c \
  'cd "$2" && ! GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null "$1" "$3" 2>/dev/null' _ "$trailers" "$trw/repo" "$trw/unreadable"
chmod 600 "$trw/unreadable"
# run with no argument it prints a usage line on stderr and exits 2
fx_check "trailer hook with no argument prints a usage line and exits 2" bash -c \
  'cd "$2" && err=$(GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null "$1" 2>&1 >/dev/null); rc=$?; [ "$rc" = 2 ] && grep -q "^usage: commit-trailers <message file>" <<<"$err"' _ "$trailers" "$trw/repo"
# git runs a config hook command through `sh -c` and appends its own "$@" to the command, so the
# snippet's command hands the trailer hook the message file twice (on git 2.56.0, dev-ekcl.1.5):
# the hook reads the first argument and tolerates the rest
twice_cmd=$hook_cmd' "$@"'
twice_msg() { # <message>: the snippet's command, plus git's own "$@", on a message file; sets trc, terr
  printf '%s\n' "$1" >"$trw/msg"
  terr=$(cd "$trw/repo" && env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null PATH="$(dirname "$trailers"):$PATH" \
    /bin/sh -c "$twice_cmd" sh "$trw/msg" 2>&1 >/dev/null); trc=$?
}
trailers_keys Bead Refs
twice_msg $'fix: thing\n\nBody.\n\nBead: dev-clo\nRefs: INFRA-1'
fx_check "the snippet's hook command, given the message file twice, passes a correct message" test "$trc" = 0
twice_msg $'fix: thing\n\nBead: dev-clo\n\nMore prose after the trailer.'
fx_check "the snippet's hook command, given the message file twice, still blocks a bad message" bash -c \
  '[ "$1" = 1 ] && grep -q "trailer block" <<<"$2"' _ "$trc" "$terr"
# the harness's attribution guidance splits the trailers into two paragraphs: the hook joins them
trailers_msg $'fix: thing\n\nBody.\n\nBead: dev-qgww\nRefs: INFRA-42\n\nCo-Authored-By: Claude <noreply@anthropic.com>\nClaude-Session: https://example.test/s'
fx_check "trailer hook passes trailers split from the attribution lines" test "$trc" = 0
fx_check "trailer hook joins the split trailers into one paragraph" bash -c \
  '[ "$(grep -c "^$" "$1")" = 2 ]' _ "$trw/msg"
fx_check "trailer hook: the joined message commits" env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git -C "$trw/repo" commit -q --allow-empty -F "$trw/msg"
fx_check "trailer hook: git parses the committed Bead trailer" bash -c \
  '[ "$(git -C "$1" log -1 --format="%(trailers:key=Bead,valueonly)" | tr -d "\n")" = dev-qgww ]' _ "$trw/repo"
trailers_msg $'fix: thing\n\nBead: dev-qgww\n\nProse after the trailers.\nCo-Authored-By: Claude <noreply@anthropic.com>'
fx_check "trailer hook blocks trailers followed by a prose paragraph" blocked
trailers_msg $'fix: thing\n\nBead: dev-qgww\n\nProse after the trailers.\n\nCo-Authored-By: Claude <noreply@anthropic.com>'
fx_check "trailer hook blocks a mid-body Bead: before prose and attribution" blocked
trailers_msg $'fix: thing\n\nProse line.\nBead: dev-qgww\n\nCo-Authored-By: Claude <noreply@anthropic.com>'
fx_check "trailer hook blocks a Bead: inside a prose paragraph before attribution" blocked
fx_check "trailer hook leaves a rejected message file unrewritten" bash -c \
  '[ "$(cat "$1")" = "$2" ]' _ "$trw/msg" $'fix: thing\n\nProse line.\nBead: dev-qgww\n\nCo-Authored-By: Claude <noreply@anthropic.com>'
# trailing "#" comment lines (git commit -v style) do not stop the join
trailers_msg $'fix: thing\n\nBead: dev-qgww\n\nCo-Authored-By: Claude <noreply@anthropic.com>\n# Please enter the commit message\n#'
fx_check "trailer hook joins split trailers that are followed by # comment lines" bash -c \
  '[ "$1" = 0 ] && [ "$(grep -c "^$" "$2")" = 1 ]' _ "$trc" "$trw/msg"
# attribution keys are matched whatever their case, as git matches trailer keys
trailers_msg $'fix: thing\n\nBody.\n\nBead: dev-pf49\nRefs: INFRA-42\n\nCo-authored-by: Claude <noreply@anthropic.com>\nclaude-session: https://example.test/s'
fx_check "trailer hook joins split trailers whose attribution keys are lowercase" bash -c \
  '[ "$1" = 0 ] && [ "$(grep -c "^$" "$2")" = 2 ]' _ "$trc" "$trw/msg"
trailers_msg $'fix: thing\n\nBead: dev-pf49\n\nCo-Authored-By: Claude <noreply@anthropic.com>'
fx_check "trailer hook joins split trailers with one attribution key alone" bash -c \
  '[ "$1" = 0 ] && [ "$(grep -c "^$" "$2")" = 1 ]' _ "$trc" "$trw/msg"
trailers_msg $'fix: thing\n\nBead: dev-pf49\n\nCO-AUTHORED-BY: Claude <noreply@anthropic.com>\nCLAUDE-SESSION: https://example.test/s'
fx_check "trailer hook joins split trailers whose attribution keys are all caps" bash -c \
  '[ "$1" = 0 ] && [ "$(grep -c "^$" "$2")" = 1 ]' _ "$trc" "$trw/msg"
# a CRLF message file
trailers_msg $'fix: thing\r\n\r\nBead: dev-qgww\r\n\r\nCo-Authored-By: Claude <noreply@anthropic.com>\r'
fx_check "trailer hook passes split trailers in a CRLF message" test "$trc" = 0
fx_check "trailer hook joins the split trailers of a CRLF message" bash -c \
  '[ "$(tr -d "\r" <"$1" | grep -c "^$")" = 1 ]' _ "$trw/msg"
# only the configured keys are checked
trailers_keys Ticket
trailers_msg $'fix: thing\n\nTicket: T-1\n\nMore prose after the trailer.'
fx_check "trailer hook with only Ticket set checks a Ticket: line" blocked
trailers_msg $'fix: thing\n\nBead: dev-clo\n\nMore prose after the trailer.'
fx_check "trailer hook with only Ticket set does not check a Bead: line" test "$trc" = 0
trailers_keys Bead Refs
# the subject and the blank line after it are no concern of the trailer hook
trailers_msg 'Added a thing.'
fx_check "trailer hook passes a non-Conventional subject" test "$trc" = 0
trailers_msg $'fix: thing\nbody right under the subject'
fx_check "trailer hook passes a body with no blank line after the subject" test "$trc" = 0

fx_report_fails
