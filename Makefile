.DEFAULT_GOAL := help

.PHONY: help lint ci fixtures

help: ## Show this help
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

lint: ci fixtures ## Everything: ci, then the fixture tests last (needs bd and cargo)

ci: ## Lint the skill docs and run the lint, guard-rm and setup tests (what GitHub Actions calls: no fixtures)
	scripts/lint-skill-docs.sh
	scripts/test-lint-skill-docs.sh
	scripts/test-guard-rm.sh
	scripts/test-setup-skill.sh

fixtures: ## Run the scripted fixture tests against throwaway beads databases (needs bd and cargo)
	scripts/test-fixture-stage-boundary.sh
	scripts/test-fixture-stories.sh
	scripts/test-fixture-dag.sh
	scripts/test-fixture-triage.sh skill
