.DEFAULT_GOAL := help

.PHONY: help check lint ci fixtures

# run one step and print its elapsed seconds after it, then its CPU seconds (the times builtin: the
# shell's user and sys, then the step's), so a CI log says where the time went and whether the
# step waited or worked
step = t=$$(date +%s); $(1); rc=$$?; echo "$(1): $$(( $$(date +%s) - t ))s"; times; exit $$rc
# run the steps side by side, each one's output, elapsed seconds and CPU seconds held in its own
# log under .tmp/make, then print the logs in step order; red when any step is
side_by_side = @mkdir -p .tmp/make; pids=; for s in $(1); do \
	  { $(call step,$$s); } \
	    > .tmp/make/$$(basename $$s).log 2>&1 & pids="$$pids $$!"; \
	done; rc=0; for p in $$pids; do wait $$p || rc=1; done; \
	for s in $(1); do cat .tmp/make/$$(basename $$s).log; done; exit $$rc

help: ## Show this help
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

# the steps of ci and of the fixtures, one list each; a step is one script, run by its path
ci_steps = scripts/lint-skill-docs.sh skills/glossary-lint/glossary-lint.sh \
  scripts/check-test-git-init.sh scripts/test-lint-skill-docs.sh scripts/test-guard-rm.sh \
  scripts/test-phases.sh scripts/test-glossary-lint.sh scripts/test-setup-skill.sh \
  scripts/test-setup-repo-skill.sh scripts/test-readme.sh scripts/test-ci-workflow.sh \
  scripts/test-check-target.sh
# a fixture build mostly waits on bd, so the fixture tests, each on its own scratch paths, run
# side by side
fixture_steps = scripts/test-fixture-stage-boundary.sh scripts/test-fixture-stories.sh \
  scripts/test-fixture-dag.sh scripts/test-fixture-retro.sh scripts/test-fixture-story-cut.sh \
  scripts/test-fixture-story-cutter.sh scripts/test-fixture-triage.sh

# every step of ci and the fixtures runs in one side-by-side run, so no step waits on another
# and the longest one starts at once (ordering only: they still share the runner's cores); red
# when any is
check: ## Everything: ci and the fixture tests at once (needs bd and cargo); the target CI calls
	$(call side_by_side,$(ci_steps) $(fixture_steps))

lint: check ## Deprecated alias of check, kept for one release

ci: ## Lint the skill docs and the glossary terms, and run every script test that needs no beads database
	$(call side_by_side,$(ci_steps))

fixtures: ## Run the scripted fixture tests at once against throwaway beads databases (needs bd and cargo)
	$(call side_by_side,$(fixture_steps))
