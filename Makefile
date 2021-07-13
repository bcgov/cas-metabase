SHELL := /usr/bin/env bash

GIT_SHA1=$(shell git rev-parse HEAD)

.PHONY: whoami
whoami:
	$(call oc_whoami)

.PHONY: install
install: whoami
install:
	@set -euo pipefail; \
	helm dep up ./helm/cas-metabase; \
	helm upgrade --install --atomic --timeout 300s --namespace "$(GGIRCS_NAMESPACE_PREFIX)-$(ENVIRONMENT)" \
	--set metabase.image.tag=$(GIT_SHA1) --set metabase.nginxSidecar.image.tag=$(GIT_SHA1) \
	--values ./helm/cas-metabase/values-$(ENVIRONMENT).yaml \
	if [[ $(ENVIRONMENT) == test ]]; then \
		--set gcsProdBackupSAKey="gcp-$(GGIRCS_NAMESPACE_PREFIX)-prod-read-only-service-account-key" \
		--set ciipDatabaseHost="cas-ciip-portal-patroni-readonly.$(CIIP_NAMESPACE_PREFIX)-$(ENVIRONMENT).svc.cluster.local" \
	fi; \
	cas-metabase ./helm/cas-metabase;
