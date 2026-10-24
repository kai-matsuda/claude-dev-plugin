.DEFAULT_GOAL := help

.PHONY: help lint ci fixtures

help: ## Show this help
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

lint: ci ## Everything: ci, then the fixture tests last (needs bd and cargo)
	$(MAKE) fixtures

ci: ## Lint the skill docs and run the lint, guard-rm, setup, README and workflow tests (the target CI calls: no fixtures)
	scripts/lint-skill-docs.sh
	scripts/test-lint-skill-docs.sh
	scripts/test-guard-rm.sh
	scripts/test-setup-skill.sh
	scripts/test-setup-repo-skill.sh
	scripts/test-readme.sh
	scripts/test-ci-workflow.sh

fixtures: ## Run the scripted fixture tests against throwaway beads databases (needs bd and cargo)
	scripts/test-fixture-stage-boundary.sh
	scripts/test-fixture-stories.sh
	scripts/test-fixture-dag.sh
	scripts/test-fixture-retro.sh
	scripts/test-fixture-story-cut.sh
	scripts/test-fixture-story-cutter.sh
	scripts/test-fixture-triage.sh
