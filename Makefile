.DEFAULT_GOAL := help

.PHONY: help check lint ci fixtures

# run one step and print its elapsed seconds after it, so a CI log says where the time went
timed = @t=$$(date +%s); $(1); rc=$$?; echo "$(1): $$(( $$(date +%s) - t ))s"; exit $$rc

help: ## Show this help
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

check: ci ## Everything: ci, then the fixture tests last (needs bd and cargo); the target CI calls
	$(MAKE) fixtures

lint: check ## Deprecated alias of check, kept for one release

ci: ## Lint the skill docs and run every script test that needs no beads database (check runs it first)
	$(call timed,scripts/lint-skill-docs.sh)
	$(call timed,scripts/check-test-git-init.sh)
	$(call timed,scripts/test-lint-skill-docs.sh)
	$(call timed,scripts/test-guard-rm.sh)
	$(call timed,scripts/test-glossary-lint.sh)
	$(call timed,scripts/test-setup-skill.sh)
	$(call timed,scripts/test-setup-repo-skill.sh)
	$(call timed,scripts/test-readme.sh)
	$(call timed,scripts/test-ci-workflow.sh)

fixtures: ## Run the scripted fixture tests against throwaway beads databases (needs bd and cargo)
	$(call timed,scripts/test-fixture-stage-boundary.sh)
	$(call timed,scripts/test-fixture-stories.sh)
	$(call timed,scripts/test-fixture-dag.sh)
	$(call timed,scripts/test-fixture-retro.sh)
	$(call timed,scripts/test-fixture-story-cut.sh)
	$(call timed,scripts/test-fixture-story-cutter.sh)
	$(call timed,scripts/test-fixture-triage.sh)
