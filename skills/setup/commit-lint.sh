#!/bin/sh
# commit-lint: checks a commit message against the "Commit messages" rules in
# ~/.claude/CLAUDE.md (the stub beside this file) and the trailer rules in
# docs/agents/issue-tracker.md. Shipped here, in the dev plugin, for machine setup
# to install as ~/.config/git/commit-lint.sh (check-prereqs.sh prints where and
# how); edit it here, never the installed copy. The global hook.commitlint in
# ~/.gitconfig runs it on commit-msg in every repo, with the message file as $1;
# exit 1 blocks.
#
# Blocks, on the subject (the first non-comment line):
#   - not "type(scope): subject" with type feat, fix, refactor, test, docs or
#     chore (scope optional, "!" allowed);
#   - over 72 characters, capitalised after the colon, or ending in a period.
# Blocks a body that does not start after one blank line, and a "Bead:" or
# "Refs:" line that `git interpret-trailers --parse` does not return: it sits
# in a paragraph before the last, or the last paragraph also holds prose, and
# either way git drops it from the trailers.
# Repairs, before those checks, a Bead:/Refs: paragraph followed by a separate
# Co-Authored-By:/Claude-Session: paragraph by joining them in the message file.
# Warns: no "Bead:" trailer in a repo with .beads/ (hand-made commits have
# none); "#" lines in a merge message, which `git merge --no-edit` keeps.
# Git's own subjects (Merge, Revert, fixup!, squash!, amend!) skip the subject
# rules. Bypass once with `git commit --no-verify`; opt a repo out with
# `git config hook.commitlint.enabled false`. Lint by hand: sh <this> <file>.
set -eu
msg=$1
top=$(git rev-parse --show-toplevel)
merging=0
[ -f "$(git rev-parse --git-path MERGE_HEAD)" ] && merging=1
beads=0
[ -d "$top/.beads" ] && beads=1
# Repairs one shape in place: a paragraph of only Bead:/Refs: lines, a blank line, then a
# last paragraph of only Co-Authored-By:/Claude-Session: lines (what the harness's
# attribution guidance produces) becomes one trailer paragraph. Anything else is left alone.
joined=$(awk '
{ line[++n] = $0 }
END {
  e = n
  while (e > 0 && (line[e] ~ /^[[:space:]]*$/ || line[e] ~ /^#/)) e--
  a = e
  while (a > 0 && line[a] ~ /^(Co-Authored-By|Claude-Session): /) a--
  if (a == e || a == 0 || line[a] !~ /^[[:space:]]*$/) fix = 0
  else {
    b = a
    while (b > 0 && line[b] ~ /^[[:space:]]*$/) b--
    p = b
    while (p > 0 && line[p] ~ /^(Bead|Refs): /) p--
    fix = (p < b && p > 0 && line[p] ~ /^[[:space:]]*$/)
  }
  for (i = 1; i <= n; i++) if (!(fix && i > b && i <= a)) print line[i]
  exit fix ? 0 : 3
}' "$msg") && printf '%s\n' "$joined" >"$msg" || :
# Provenance lines git itself reads as trailers; awk compares this with the lines present.
provenance='^(Bead|Refs): '
parsed=$(git interpret-trailers --parse "$msg" | grep -cE "$provenance" || :)

exec awk -v merging="$merging" -v beads="$beads" -v provenance="$provenance" -v parsed="$parsed" '
/^#/ { comments++; next }
{ line[++n] = $0 }
END {
  for (s = 1; s <= n && line[s] ~ /^[[:space:]]*$/; s++) ;
  if (s > n) exit 0                       # empty: git refuses it anyway
  subject = line[s]
  auto = subject ~ /^(Merge |Revert "|fixup! |squash! |amend! )/
  if (!auto) {
    if (subject !~ /^(feat|fix|refactor|test|docs|chore)(\([^)]+\))?!?: [^ ]/)
      err("subject is not \"type(scope): subject\" with type feat, fix, refactor, test, docs or chore")
    else {
      rest = subject; sub(/^[^:]*: /, "", rest)
      if (rest ~ /^[A-Z]/) err("subject starts with a capital after the colon; use lowercase")
    }
    if (subject ~ /\.$/) err("subject ends with a period")
    if (length(subject) > 72) err("subject is " length(subject) " characters; the limit is 72")
  }
  if (s < n && line[s + 1] !~ /^[[:space:]]*$/) err("no blank line between the subject and the body")
  for (i = s; i <= n; i++) {
    if (line[i] ~ /^Bead: /) bead = 1
    if (line[i] ~ provenance) present++
  }
  if (present > parsed)
    err("\"Bead:\"/\"Refs:\" is not in the trailer block git parses; trailers go in the last paragraph, together with Co-Authored-By, and nothing else goes there")
  if (beads && !auto && !bead) warn("no \"Bead:\" trailer; add one if this work came from a bead")
  if (merging && comments) warn("\"#\" lines in a merge message are kept by `git merge --no-edit`; delete them")
  if (errors) {
    printf "commit-lint:   %s\n", subject > "/dev/stderr"
    print "commit-lint: rules in ~/.claude/CLAUDE.md, \"Commit messages\"; bypass once with --no-verify" > "/dev/stderr"
    exit 1
  }
}
function err(m)  { printf "commit-lint: error: %s\n", m > "/dev/stderr"; errors++ }
function warn(m) { printf "commit-lint: warning: %s\n", m > "/dev/stderr" }
' "$msg"
