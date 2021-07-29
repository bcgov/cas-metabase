SHELL := /usr/bin/env bash

GIT_SHA1=$(shell git rev-parse HEAD)

.PHONY: whoami
whoami:
	$(call oc_whoami)

.PHONY: install
install: whoami
install:
	@set -euo pipefail; \
	dagConfig=$$(echo '{"org": "bcgov", "repo": "cas-metabase", "ref": "$(GIT_SHA1)", "path": "dags/cas_metabase_dags.py"}' | base64 -w0); \
	helm dep up ./helm/cas-metabase; \
	if [[ $(ENVIRONMENT) == test ]]; then \
		helm upgrade --install --atomic --wait-for-jobs --timeout 300s --namespace "$(GGIRCS_NAMESPACE_PREFIX)-$(ENVIRONMENT)" \
		--set metabase.image.tag=$(GIT_SHA1) --set metabase.nginxSidecar.image.tag=$(GIT_SHA1) \
		--set gcsProdBackupSAKey="gcp-$(GGIRCS_NAMESPACE_PREFIX)-prod-read-only-service-account-key" \
		--set ciipDatabaseHost="cas-ciip-portal-patroni-readonly.$(CIIP_NAMESPACE_PREFIX)-$(ENVIRONMENT).svc.cluster.local" \
		--set download-cas-metabase-dags.dagConfiguration="$$dagConfig" \
		--values ./helm/cas-metabase/values-$(ENVIRONMENT).yaml \
		cas-metabase ./helm/cas-metabase; \
	else \
		helm upgrade --install --atomic --wait-for-jobs --timeout 300s --namespace "$(GGIRCS_NAMESPACE_PREFIX)-$(ENVIRONMENT)" \
		--set metabase.image.tag=$(GIT_SHA1) --set metabase.nginxSidecar.image.tag=$(GIT_SHA1) \
		--set download-cas-metabase-dags.dagConfiguration="$$dagConfig" \
		--values ./helm/cas-metabase/values-$(ENVIRONMENT).yaml \
		cas-metabase ./helm/cas-metabase; \
	fi;
