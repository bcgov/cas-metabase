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
	--set metabase.image.tag=$(GIT_SHA1) \
	--set networkSecurityPolicies.ciip.namespace="$(CIIP_NAMESPACE_PREFIX)-$(ENVIRONMENT)" \
	--values ./helm/cas-metabase/values-$(ENVIRONMENT).yaml \
	cas-metabase ./helm/cas-metabase;