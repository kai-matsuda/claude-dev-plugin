.DEFAULT_GOAL := help

.PHONY: help check lint ci fixtures

# run one step and print its elapsed seconds after it, so a CI log says where the time went
timed = @t=$$(date +%s); $(1); rc=$$?; echo "$(1): $$(( $$(date +%s) - t ))s"; exit $$rc
# run the steps side by side, each one's output and elapsed seconds held in its own log under
# .tmp/make, then print the logs in step order; red when any step is
side_by_side = @mkdir -p .tmp/make; pids=; for s in $(1); do \
	  { t=$$(date +%s); $$s; rc=$$?; echo "$$s: $$(( $$(date +%s) - t ))s"; exit $$rc; } \
	    > .tmp/make/$$(basename $$s).log 2>&1 & pids="$$pids $$!"; \
	done; rc=0; for p in $$pids; do wait $$p || rc=1; done; \
	for s in $(1); do cat .tmp/make/$$(basename $$s).log; done; exit $$rc

help: ## Show this help
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

# ci and the fixtures run side by side, the fixtures' output held in a log and printed after ci's
# so neither interleaves the other; red when either is
check: ## Everything: ci and the fixture tests at once (needs bd and cargo); the target CI calls
	@mkdir -p .tmp; $(MAKE) fixtures > .tmp/check-fixtures.log 2>&1 & pid=$$!; \
	$(MAKE) ci; rc=$$?; wait $$pid; frc=$$?; cat .tmp/check-fixtures.log; \
	[ $$rc = 0 ] && [ $$frc = 0 ]

lint: check ## Deprecated alias of check, kept for one release

ci: ## Lint the skill docs and the glossary terms, and run every script test that needs no beads database (check runs it beside the fixtures)
	$(call timed,scripts/lint-skill-docs.sh)
	$(call timed,sh skills/glossary-lint/glossary-lint.sh)
	$(call timed,scripts/check-test-git-init.sh)
	$(call timed,scripts/test-lint-skill-docs.sh)
	$(call timed,scripts/test-guard-rm.sh)
	$(call timed,scripts/test-phases.sh)
	$(call timed,scripts/test-glossary-lint.sh)
	$(call timed,scripts/test-setup-skill.sh)
	$(call timed,scripts/test-setup-repo-skill.sh)
	$(call timed,scripts/test-readme.sh)
	$(call timed,scripts/test-ci-workflow.sh)
	$(call timed,scripts/test-check-target.sh)

# a fixture build mostly waits on bd, so the fixture tests, each on its own scratch paths, run
# side by side
fixtures: ## Run the scripted fixture tests at once against throwaway beads databases (needs bd and cargo)
	$(call side_by_side,scripts/test-fixture-stage-boundary.sh scripts/test-fixture-stories.sh \
	  scripts/test-fixture-dag.sh scripts/test-fixture-retro.sh scripts/test-fixture-story-cut.sh \
	  scripts/test-fixture-story-cutter.sh scripts/test-fixture-triage.sh)
