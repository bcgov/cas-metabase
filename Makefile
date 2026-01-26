SHELL := /usr/bin/env bash

GIT_SHA1=$(shell git rev-parse HEAD)


.PHONY: install_database
install_database:
	@set -euo pipefail; \
	echo "Installing database chart: cas-postgres/cas-postgres-cluster..."; \
	helm repo add cas-postgres https://bcgov.github.io/cas-postgres/; \
	helm repo update; \
	helm upgrade --install --atomic --wait-for-jobs --timeout 1800s --namespace "$(GGIRCS_NAMESPACE_PREFIX)-$(ENVIRONMENT)" \
		--values ./helm/cas-metabase-postgres-cluster/values.yaml \
		--values ./helm/cas-metabase-postgres-cluster/values-$(ENVIRONMENT).yaml \
		cas-metabase-db cas-postgres/cas-postgres-cluster --version 1.2.0;

.PHONY: install_app
install_app: 
	@set -euo pipefail; \
	echo "Installing metabase chart..."; \
	helm dep up ./helm/cas-metabase; \
	helm upgrade --install --atomic --wait-for-jobs --timeout 1800s --namespace "$(GGIRCS_NAMESPACE_PREFIX)-$(ENVIRONMENT)" \
		--values ./helm/cas-metabase/values-$(ENVIRONMENT).yaml \
		cas-metabase ./helm/cas-metabase; \

.PHONY: install
install: install_database install_app

.PHONY: lint_chart
lint_chart: ## Checks the configured helm chart template definitions against the remote schema
lint_chart:
	@set -euo pipefail; \
	helm dep up ./helm/cas-metabase; \
	helm template --validate \
		--set gcsProdBackupSAKey="fake-sa-key" \
		--set ciipDatabaseHost="cas-ciip-portal-patroni-readonly.fake-env.svc.cluster.local" \
		--values ./helm/cas-metabase/values-prod.yaml \
		cas-metabase ./helm/cas-metabase;
