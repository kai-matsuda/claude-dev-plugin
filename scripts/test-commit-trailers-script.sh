#!/usr/bin/env bash
# Tests for `bin/commit-trailers`, the trailer hook that machine setup wires as a commit-msg hook
# (dev-ekcl, INFRA-47). Covers it run on message files in a throwaway repo, as git's hook would;
# the setup snippet's hook command run through `sh -c` with and without `commit-trailers` on PATH;
# and the same hook under real `git commit`s in throwaway repos and, for the split-paragraph
# cases, a git worktree of one (dev-i023). The real-commit cases need a git that runs config
# hooks; on one that does not, the cases asserting a refusal or a provenance trailer after a join
# fail, while the off-PATH exit-0 case passes with no hook run. The skip path's inline join needs
# git, awk, sed, paste, mv and rm on PATH; a parity case runs it and the script over the same
# message shapes, and the cases for a failed join run it without awk and with an unwritable
# directory. The unwritable-directory case fails when run as root, which ignores the directory's
# mode, so run this script as a normal user.
# The keys come from the repo-local dev.trailer.provenance, and global and system git config are
# switched off for the message-file runs, so no case depends on the machine's own config. What
# check-prereqs.sh prints of the snippet is tested in test-setup-skill.sh.
# Usage: `scripts/test-commit-trailers-script.sh`
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
# a git that runs config hooks; on one that does not, the off-PATH exit-0 case still passes, and
# the refusal case and the join cases fail, so they prove the hook ran.
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
# the shape of 1febf1a: Bead/Refs, a blank line, then Co-Authored-By and Claude-Session. Built in
# a git worktree of the throwaway repo, as an implementer commits (dev-i023).
split_msg=$(printf 'fix: x\n\nBody line.\n\nBead: dev-1\nRefs: INFRA-1\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\nClaude-Session: https://claude.ai/code/session_x\n')
printf '%s\n' "$split_msg" >"$rcdir/split-msg"
rc_wt() { # <name>: a repo as rc_repo makes it, plus a worktree of it at <name>-wt on its own branch
  rc_repo "$1" && git -C "$rcdir/$1" commit -q --allow-empty -m "chore: base" --no-verify &&
    git -C "$rcdir/$1" worktree add -q -b "wt-$1" "$rcdir/$1-wt"
}
off_path=$hookdir/empty:$git_dir:/usr/bin:/bin   # no commit-trailers; awk, paste and mv on it for the skip path
rc_split() { # <name> <PATH> [message file]: commit the message (the split one by default) in the worktree <name>-wt
  env -i PATH="$2" HOME="$rcdir" GIT_CONFIG_NOSYSTEM=1 "$git_bin" -C "$rcdir/$1-wt" commit -q --allow-empty -F "${3:-$rcdir/split-msg}"
}
bead_trailer() { # <name>: the worktree's last commit has the Bead trailer dev-1
  [ "$("$git_bin" -C "$rcdir/$1-wt" log -1 --format='%(trailers:key=Bead,valueonly)' | tr -d '\n')" = dev-1 ]
}
fx_check "the worktree repo for the split case with commit-trailers on PATH is built" rc_wt splitin
fx_check "the worktree repo for the split case without commit-trailers on PATH is built" rc_wt splitout
fx_check "a commit of split Bead/Refs and attribution paragraphs, commit-trailers on PATH, in a worktree succeeds" \
  rc_split splitin "$on_path"
fx_check "that commit, commit-trailers on PATH, has a Bead trailer" bead_trailer splitin
fx_check "a commit of split Bead/Refs and attribution paragraphs, commit-trailers not on PATH, in a worktree succeeds" \
  rc_split splitout "$off_path"
fx_check "that commit, commit-trailers not on PATH, has a Bead trailer" bead_trailer splitout
# the skip path's join touches only the 1febf1a shape: with prose between the paragraphs, or with
# the keys unset, the blank line before the attribution lines stays
blank_before_attr() { # <name>: the worktree's last commit has an empty line right before Co-Authored-By
  "$git_bin" -C "$rcdir/$1-wt" log -1 --format=%B | awk '/^Co-Authored-By/ { f = (prev == "") } { prev = $0 } END { exit !f }'
}
printf '%s\n' "$(printf 'fix: x\n\nBead: dev-1\n\nProse between.\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\n')" >"$rcdir/prose-msg"
fx_check "the repo for the prose-between shape is built" rc_wt prose
fx_check "the repo for the keys-unset shape is built" rc_wt nokeys
fx_check "the keys-unset repo has no provenance keys" git -C "$rcdir/nokeys" config --unset-all dev.trailer.provenance
kept_blank() { # <name> <message file>: commit it with the hook skipping; the blank line stays
  rc_split "$1" "$off_path" "$2" && blank_before_attr "$1"
}
fx_check "a skipped hook leaves a message with prose between the paragraphs as written" kept_blank prose "$rcdir/prose-msg"
fx_check "a skipped hook with the keys unset leaves the split message as written" kept_blank nokeys "$rcdir/split-msg"

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
printf '%s\n' $'fix: thing\n\nBead: dev-a' >"$trw/unreadable-nokeys"
chmod 000 "$trw/unreadable-nokeys"
trailers_keys
fx_check "trailer hook with no keys set exits 0 on an unreadable message file" bash -c \
  'cd "$2" && GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null "$1" "$3" 2>/dev/null' _ "$trailers" "$trw/repo" "$trw/unreadable-nokeys"
chmod 600 "$trw/unreadable-nokeys"
trailers_keys Bead Refs
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

# the skip path's inline join and the script's join are one behaviour in two copies, since the
# hook command cannot call a script the plugin version may lack: both run over the same shapes
# and must leave the same message file
parity_msg() { # <message>: the script, then the snippet's command with commit-trailers off PATH, on copies
  printf '%s\n' "$1" >"$trw/pmsg-script"; cp "$trw/pmsg-script" "$trw/pmsg-inline"
  (cd "$trw/repo" && GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null "$trailers" "$trw/pmsg-script" 2>/dev/null)
  (cd "$trw/repo" && env -i PATH="$off_path" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null /bin/sh -c "$hook_cmd" sh "$trw/pmsg-inline" 2>/dev/null)
  cmp -s "$trw/pmsg-script" "$trw/pmsg-inline"
}
parity_joined() { # <message>: parity, and the message was joined (it changed)
  parity_msg "$1" && ! cmp -s "$trw/pmsg-inline" <(printf '%s\n' "$1")
}
attr=$'Co-Authored-By: Claude <noreply@anthropic.com>\nClaude-Session: https://example.test/s'
trailers_keys Bead Refs
fx_check "parity: the 1febf1a shape is joined alike" parity_joined $'fix: x\n\nBody.\n\nBead: dev-1\nRefs: INFRA-1\n\n'"$attr"
fx_check "parity: two blank lines between the paragraphs are joined alike" parity_joined $'fix: x\n\nBead: dev-1\n\n\n'"$attr"
fx_check "parity: a tab-only blank line between the paragraphs is joined alike" parity_joined $'fix: x\n\nBead: dev-1\n\t\n'"$attr"
fx_check "parity: a space-only blank line before the provenance paragraph is joined alike" parity_joined $'fix: x\n \nBead: dev-1\n\n'"$attr"
fx_check "parity: a CRLF message is joined alike" parity_joined $'fix: x\r\n\r\nBead: dev-1\r\n\r\nCo-Authored-By: Claude <noreply@anthropic.com>\r'
fx_check "parity: trailing # comment lines are joined alike" parity_joined $'fix: x\n\nBead: dev-1\n\n'"$attr"$'\n# comment'
fx_check "parity: trailing blank lines are joined alike" parity_joined $'fix: x\n\nBead: dev-1\n\n'"$attr"$'\n\n'
fx_check "parity: a provenance line as the subject is left alike" parity_msg $'Bead: dev-1\n\n'"$attr"
fx_check "parity: prose between the paragraphs is left alike" parity_msg $'fix: x\n\nBead: dev-1\n\nProse.\n\n'"$attr"
fx_check "parity: no attribution paragraph is left alike" parity_msg $'fix: x\n\nBead: dev-1\nRefs: INFRA-1'
trailers_keys 'Ref.s'
# git parses no Ref.s trailer, so the script refuses (and keeps) such a message that the inline
# join would join; what the two share is that the key is literal, not a regex
fx_check "parity: a key with a regex character does not match a look-alike line" parity_msg $'fix: x\n\nRefxs: A-1\n\n'"$attr"
inline_joins() { # <message>: the snippet's command, commit-trailers off PATH, changed the message
  printf '%s\n' "$1" >"$trw/imsg"
  (cd "$trw/repo" && env -i PATH="$off_path" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null /bin/sh -c "$hook_cmd" sh "$trw/imsg" 2>/dev/null)
  ! cmp -s "$trw/imsg" <(printf '%s\n' "$1")
}
fx_check "the inline join matches a key with a regex character as written" inline_joins $'fix: x\n\nRef.s: A-1\n\n'"$attr"
inline_leaves() { ! inline_joins "$1"; }
fx_check "the inline join does not match a look-alike of that key" inline_leaves $'fix: x\n\nRefxs: A-1\n\n'"$attr"
trailers_keys Bead Refs
# a join that fails is reported on stderr, and the commit is not blocked
join_failure() { # <PATH> <dir>: the snippet's command on a split message in <dir>; sets terr, trc
  mkdir -p "$2"; printf '%s\n' $'fix: x\n\nBead: dev-1\n\n'"$attr" >"$2/msg"; cp "$2/msg" "$2/msg0"
  terr=$(cd "$trw/repo" && env -i PATH="$1" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null /bin/sh -c "$hook_cmd" sh "$2/msg" 2>&1 >/dev/null); trc=$?
}
mkdir -p "$trw/noawk"
for t in git sed paste mv rm; do ln -sf "$(command -v $t)" "$trw/noawk/$t"; done
join_failure "$trw/noawk" "$trw/jf1"
fx_check "a failed join (no awk on PATH) exits 0, leaves the message and says so on stderr" bash -c \
  '[ "$1" = 0 ] && cmp -s "$2/msg" "$2/msg0" && grep -q "could not join the trailer paragraphs" <<<"$3"' _ "$trc" "$trw/jf1" "$terr"
join_failure "$off_path" "$trw/jf2"   # creates the message; the directory is then made read-only
chmod 555 "$trw/jf2"
join_failure "$off_path" "$trw/jf2"
chmod 755 "$trw/jf2"
fx_check "a failed join (no write next to the message) exits 0, leaves the message and says so on stderr" bash -c \
  '[ "$1" = 0 ] && cmp -s "$2/msg" "$2/msg0" && grep -q "could not join the trailer paragraphs" <<<"$3"' _ "$trc" "$trw/jf2" "$terr"

fx_report_fails
