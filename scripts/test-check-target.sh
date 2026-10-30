#!/usr/bin/env bash
# Tests for the check target detection the story orchestrator resolves once per invocation in
# docs/agents/orchestration.md (Story plumbing, Check target): the command is lifted from the doc as written and run on
# scratch repos, so it finds a check target however the Makefile defines it (GNUmakefile,
# makefile, an included file, one of several targets in a rule, a double-colon rule), takes
# neither a check:= variable, a prerequisite-only check nor a .PHONY: check with no rule for one,
# reads a missing Makefile as none, and runs neither the check recipe nor a $(MAKE) line in it
# while it asks. skills/setup-repo/SKILL.md (step 2) asks the same query from the repo's root.
# Usage: scripts/test-check-target.sh
set -uo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/scripts/fixture-test-lib.sh"   # fx_scratch_dir, fx_check, fx_report_fails
rules_doc=$repo_root/docs/agents/orchestration.md

detect=$(grep -o '`make -C <owner> -pRrq[^`]*`' "$rules_doc" | tr -d '`')
fx_check "the rules doc names one make database query" test "$(grep -c . <<<"$detect")" = 1
setup=$(grep -o '`make -pRrq[^`]*`' "$repo_root/skills/setup-repo/SKILL.md" | tr -d '`')
fx_check "setup-repo asks the same query from the repo's root" test "$setup" = "${detect/-C <owner> /}"

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
fx_check "a .PHONY: check with no rule is not a target" lacks_check "$(make_repo phony Makefile '.PHONY: check\nall:\n\t@true\n')"
fx_check "a .PHONY check with only prerequisites is a target" has_check "$(make_repo phonyprereq Makefile '.PHONY: check\ncheck: all\nall:\n\t@true\n')"
fx_check "a .PHONY check with a recipe is a target" has_check "$(make_repo phonyrecipe Makefile '.PHONY: check\ncheck:\n\t@true\n')"
fx_check "a check rule with an empty recipe is a target" has_check "$(make_repo empty Makefile 'check: ;\n')"
fx_check "no Makefile reads as no check target" lacks_check "$(mkdir -p "$scratch/none" && echo "$scratch/none")"
run=$(make_repo run Makefile 'check:\n\t$(MAKE) mark\n\ttouch ran\nmark:\n\ttouch marked\n')
# runs_no_recipe <dir>: the check target is found and neither its recipe nor its $(MAKE) line ran
runs_no_recipe() { has_check "$1" && [ ! -e "$1/ran" ] && [ ! -e "$1/marked" ]; }
fx_check "the query runs no recipe, not even a \$(MAKE) line" runs_no_recipe "$run"
# make 3.82 and later name a recipe "#  recipe to execute", 3.81 (the macOS make) "#  commands to
# execute"; the query's awk reads both, fed here a database in the newer wording
filter=${detect#*| }
# reads_db <database>: the doc's awk, run on a canned make database
reads_db() { printf '%b' "$1" | bash -c "$filter"; }
fx_check "a check recipe in make 4's database wording" reads_db "check:\n#  recipe to execute (from 'Makefile', line 2):\n\t@true\n\n"
fx_check "this repo's own check target" has_check "$repo_root"

fx_report_fails
