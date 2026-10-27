#!/usr/bin/env bash
# Tests for the check target detection the story orchestrator resolves once per invocation in
# skills/implement-story/SKILL.md (step 3): the command is lifted from the doc as written and run on
# scratch repos, so it finds a check target however the Makefile defines it (GNUmakefile,
# makefile, an included file, one of several targets in a rule, a double-colon rule), takes
# neither a check:= variable nor a prerequisite-only check for one, reads a missing Makefile as
# none, and runs neither the check recipe nor a $(MAKE) line in it while it asks.
# Usage: scripts/test-check-target.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_scratch_dir, fx_check, fx_report_fails
skill=$repo_root/skills/implement-story/SKILL.md

detect=$(grep -o '`make -C <owner> -pRrq[^`]*`' "$skill" | tr -d '`')
fx_check "the brief names one make database query" test "$(grep -c . <<<"$detect")" = 1

fx_scratch_dir check-target
# has_check <dir>: the doc's command with <owner> spelled as <dir>
has_check() { bash -c "${detect//<owner>/\"\$1\"}" _ "$1"; }
lacks_check() { ! has_check "$1"; }
# make_repo <name> <file> <body>: a scratch repo holding one makefile; prints its path
make_repo() { mkdir -p "$scratch/$1" && printf '%b' "$3" > "$scratch/$1/$2"; echo "$scratch/$1"; }

fx_check "a check target in Makefile" has_check "$(make_repo plain Makefile 'check:\n\t@true\n')"
fx_check "a check target in GNUmakefile" has_check "$(make_repo gnu GNUmakefile 'check:\n\t@true\n')"
fx_check "a check target in makefile" has_check "$(make_repo lower makefile 'check:\n\t@true\n')"
inc=$(make_repo inc Makefile 'include rules.mk\n')
printf 'check:\n\t@true\n' > "$inc/rules.mk"
fx_check "a check target in an included .mk file" has_check "$inc"
fx_check "check as one of several targets in a rule" has_check "$(make_repo multi Makefile 'lint check test: ; @true\n')"
fx_check "a double-colon check rule" has_check "$(make_repo dcolon Makefile 'check::\n\t@true\n')"
fx_check "a check:= variable is not a target" lacks_check "$(make_repo var Makefile 'check:=x\nall:\n\t@true\n')"
fx_check "a check = variable is not a target" lacks_check "$(make_repo var2 Makefile 'check = x\nall:\n\t@true\n')"
fx_check "check named only as a prerequisite is not a target" lacks_check "$(make_repo prereq Makefile 'all: check\n\t@true\n')"
fx_check "no Makefile reads as no check target" lacks_check "$(mkdir -p "$scratch/none" && echo "$scratch/none")"
run=$(make_repo run Makefile 'check:\n\t$(MAKE) mark\n\ttouch ran\nmark:\n\ttouch marked\n')
# runs_no_recipe <dir>: the check target is found and neither its recipe nor its $(MAKE) line ran
runs_no_recipe() { has_check "$1" && [ ! -e "$1/ran" ] && [ ! -e "$1/marked" ]; }
fx_check "the query runs no recipe, not even a \$(MAKE) line" runs_no_recipe "$run"
fx_check "this repo's own check target" has_check "$repo_root"

fx_report_fails
