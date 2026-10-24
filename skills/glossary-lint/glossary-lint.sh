#!/bin/sh
# glossary-lint: flags prose that uses a word a GLOSSARY.md lists under _Avoid_.
#
# Run from anywhere inside a git repo. Every tracked GLOSSARY.md applies to the
# files under its own directory, so a root glossary covers the repo and a
# context glossary (src/<context>/GLOSSARY.md) covers its context.
#
# Prose is tracked Markdown, minus glossaries and docs/specs/ (past plans),
# plus doc comments in the languages listed in DOC_COMMENT below. Fenced blocks
# and `code spans` are skipped: identifiers are not prose.
#
# Senses a glossary permits go in .glossary-allow at the repo root, one per
# line as "<path> <term>  # reason"; each allows the term everywhere in <path>.
#
# Entries are "**Term**:" lines followed by "_Avoid_: a, b (note)", the format
# /domain-modeling writes; *Avoid*, **Avoid**, __Avoid__ and bare Avoid also
# parse. A glossary that yields no entries gets a warning on stderr.
#
# Exit status: 0 clean (or no glossary), 1 violations found.
set -eu
cd "$(git rev-parse --show-toplevel)"

glossaries=$(git ls-files -- 'GLOSSARY.md' '**/GLOSSARY.md')
if [ -z "$glossaries" ]; then
  echo "glossary-lint: no GLOSSARY.md in this repo; nothing to check"
  exit 0
fi

files=$(git ls-files -- '*.md' '*.rs' \
  ':!GLOSSARY.md' ':!**/GLOSSARY.md' ':!GLOSSARY-MAP.md' ':!docs/specs/')

# The glossary list goes through the environment: BSD awk rejects newlines in -v.
export GLOSSARY_LINT_GLOSSARIES="$glossaries"
# shellcheck disable=SC2086 # $files is a newline-separated path list
exec awk -v allowfile=.glossary-allow '
# Doc-comment line prefixes by file extension. Extend per language.
function doc_prefix(file) {
  if (file ~ /\.rs$/) return "^[[:space:]]*//[/!] ?"
  return ""
}
BEGIN {
  ng = split(ENVIRON["GLOSSARY_LINT_GLOSSARIES"], gs, "\n")
  for (g = 1; g <= ng; g++) {
    dir = gs[g]; sub(/GLOSSARY\.md$/, "", dir)
    head = ""; entries = 0
    while ((getline line < gs[g]) > 0) {
      # Tested before the entry heading: **Avoid**: is bold too.
      if (tolower(line) ~ /^[_*]*avoid[_*]*:/) {
        # /domain-modeling writes _Avoid_:; accept *Avoid*, **Avoid**, __Avoid__, Avoid.
        sub(/^[_*]*[Aa][Vv][Oo][Ii][Dd][_*]*: */, "", line); gsub(/\([^)]*\)/, "", line)
        n = split(line, parts, ",")
        for (i = 1; i <= n; i++) {
          t = tolower(parts[i]); gsub(/^ +| +$/, "", t)
          if (t == "") continue
          k = dir SUBSEP t
          use[k] = (k in use) ? use[k] " or " tolower(head) : tolower(head)
        }
      } else if (line ~ /^\*\*[^*]+\*\*:/) {
        head = line; sub(/^\*\*/, "", head); sub(/\*\*:.*/, "", head)
        entries++
      }
    }
    close(gs[g])
    # A glossary with no **Term**: entries checks nothing; say so rather than pass silently.
    if (!entries)
      printf "glossary-lint: warning: parsed no **Term**: entries from %s; has the glossary format changed?\n", gs[g] > "/dev/stderr"
  }
  while ((getline line < allowfile) > 0) {
    sub(/#.*/, "", line)
    if (split(line, f, " ") >= 2) {
      term = f[2]; for (i = 3; i in f; i++) term = term " " f[i]
      allow[f[1], tolower(term)] = 1
    }
  }
  hits = 0
}
FNR == 1 { fence = 0; prefix = doc_prefix(FILENAME); md = FILENAME ~ /\.md$/ }
{
  text = $0
  if (!md) {
    if (prefix == "" || text !~ prefix) next
    sub(prefix, "", text)
  }
  if (text ~ /^[[:space:]]*```/) { fence = !fence; next }
  if (fence) next
  gsub(/`[^`]*`/, "", text)
  lower = tolower(text)
  for (k in use) {
    split(k, p, SUBSEP)
    if (index(FILENAME, p[1]) != 1) continue
    if ((FILENAME, p[2]) in allow) continue
    if (lower ~ ("(^|[^a-z0-9_])" p[2] "(s|es)?([^a-z0-9_]|$)")) {
      printf "%s:%d: \"%s\" is on the glossary avoid list; use %s\n", FILENAME, FNR, p[2], use[k]
      hits++
    }
  }
}
END {
  if (hits) { printf "glossary-lint: %d violation(s)\n", hits; exit 1 }
}
' $files
