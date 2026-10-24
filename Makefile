.DEFAULT_GOAL := help

.PHONY: help lint

help: ## Show this help
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

lint: ## Lint the skill docs, then run the lint's regression test
	scripts/lint-skill-docs.sh
	scripts/test-lint-skill-docs.sh
