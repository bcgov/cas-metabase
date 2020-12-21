SHELL := /usr/bin/env bash
include .pipeline/oc.mk
include .pipeline/git.mk

PATHFINDER_PREFIX := 9212c9

.PHONY: whoami
whoami:
	$(call oc_whoami)

.PHONY: install
install: whoami
install:
	@set -euo pipefail; \
	helm dep up ./helm/cas-metabase; \
	helm upgrade --install --atomic --timeout 300s --namespace $(OC_PROJECT) \
	--set metabase.image.tag=$(GIT_SHA1) \
	--values ./helm/cas-metabase/values-$(OC_PROJECT).yaml \
	cas-metabase ./helm/cas-metabase;