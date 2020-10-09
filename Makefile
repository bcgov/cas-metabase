SHELL := /usr/bin/env bash
include .pipeline/oc.mk
include .pipeline/git.mk

PATHFINDER_PREFIX := wksv3k

.PHONY: install
install: whoami
install:
	@set -euo pipefail; \
	helm dep up ./helm/cas-metabase; \
	helm upgrade --install --atomic --timeout 2400s --namespace $(OC_PROJECT) \
	--set image.schema.tag=$(GIT_SHA1) --set image.app.tag=$(GIT_SHA1) \
	--values ./helm/cas-metabase/values-$(OC_PROJECT).yaml \
	cas-metabase ./helm/cas-metabase;