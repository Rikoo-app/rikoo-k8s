# rikoo-k8s — chart development commands. `make help` lists them.
SHELL := /bin/bash
CHART := charts/rikoo
LINT_VALUES := $(CHART)/values.lint.yaml
RENDER_DIR ?= .render

help: ## List the targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

deps: ## Fetch the sub-charts (postgres, redis, minio)
	helm dependency update $(CHART)

lint: deps ## helm lint with the lint values
	helm lint $(CHART) -f $(LINT_VALUES)

test: deps ## helm-unittest suites (plugin: helm plugin install https://github.com/helm-unittest/helm-unittest.git)
	helm unittest $(CHART) --with-subchart=false

template: deps ## Full render into $(RENDER_DIR)/default.yaml, for review
	@mkdir -p $(RENDER_DIR)
	helm template rikoo $(CHART) -n rikoo -f $(LINT_VALUES) > $(RENDER_DIR)/default.yaml
	@echo "→ $(RENDER_DIR)/default.yaml ($$(grep -c '^kind:' $(RENDER_DIR)/default.yaml) resources)"

examples: deps ## Render every example, so their values stay valid against the chart
	@mkdir -p $(RENDER_DIR)
	helm template rikoo $(CHART) -n rikoo --set rikoo.image.registry=registry.example.com/rikoo --set rikoo.image.tag=v0.0.0-lint \
	  -f examples/minimal-installation/values.yaml > $(RENDER_DIR)/minimal.yaml
	helm template rikoo $(CHART) -n rikoo --set rikoo.image.registry=registry.example.com/rikoo --set rikoo.image.tag=v0.0.0-lint \
	  -f examples/minimal-installation/values.yaml -f examples/minimal-installation/with-ingress.yaml > $(RENDER_DIR)/minimal-ingress.yaml
	helm template rikoo $(CHART) -n rikoo --set rikoo.image.registry=registry.example.com/rikoo --set rikoo.image.tag=v0.0.0-lint \
	  -f examples/minimal-installation/values.yaml \
	  -f examples/external-components/external-postgres.yaml \
	  -f examples/external-components/external-redis.yaml \
	  -f examples/external-components/external-s3.yaml > $(RENDER_DIR)/external.yaml
	helm template rikoo $(CHART) -n rikoo --set rikoo.image.tag=v0.0.0-lint \
	  -f examples/scaleway-kapsule/values.yaml > $(RENDER_DIR)/kapsule.yaml
	helm template rikoo $(CHART) -n rikoo --set rikoo.image.tag=v0.0.0-lint \
	  -f examples/local-kind/values.yaml > $(RENDER_DIR)/local-kind.yaml
	helm template rikoo $(CHART) -n rikoo --set rikoo.image.registry=registry.example.com/rikoo --set rikoo.image.tag=v0.0.0-lint \
	  -f examples/ha-external-stores/values.yaml > $(RENDER_DIR)/ha.yaml
	@echo "✓ examples rendered into $(RENDER_DIR)/"

variables-doc: ## Rewrite charts/rikoo/VARIABLES.md from the shipped contract
	node tools/variables-doc.mjs

contract-check: ## Keep the managed-name list, the shipped contract and VARIABLES.md honest
	bash tools/contract-check.sh

check: lint contract-check test examples ## lint + contract + tests + examples, what CI replays

package: deps ## Package the chart (rikoo-<version>.tgz)
	helm package $(CHART)

clean: ## Remove renders and packages
	rm -rf $(RENDER_DIR) rikoo-*.tgz

.PHONY: help deps lint variables-doc contract-check test template examples check package clean
