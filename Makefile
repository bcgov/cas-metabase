DOCKER:=docker
DOCKER_COMPOSE:=docker-compose
PREFIX:=wenzowski
OC:=oc
OC_DEV_PROJECT:=wksv3k-dev
OC_TEST_PROJECT:=wksv3k-test
OC_PROD_PROJECT:=wksv3k-prod
OC_TOOLS_PROJECT:=wksv3k-tools

build:
	# Build images locally
	${DOCKER} build -t docker.io/${PREFIX}/metabase ./metabase
.PHONY: build

up: build
	# Run images locally using docker-compose
	${DOCKER_COMPOSE} up -d
.PHONY: up

logs:
	${DOCKER_COMPOSE} logs -f
.PHONY: logs

down:
	# Halt locally running images
	${DOCKER_COMPOSE} down
.PHONY: down

clean:
	# Halt locally running images and PURGE ALL PERSISTENT VOLUMES
	${DOCKER_COMPOSE} down -v
.PHONY: clean

push: build
	# Push built images to the docker hub
	${DOCKER} push docker.io/${PREFIX}/metabase
.PHONY: push

whoami:
	# Ensure the openshift client has a valid access token
	@@${OC} whoami
.PHONY: whoami

tools_project: whoami
	# Ensure the openshift client is using the correct project namespace
	@@${OC} project ${OC_TOOLS_PROJECT}
.PHONY: tools_project

import: tools_project push
	# Import prebuilt images...
	#   - metabase
	@@${OC} import-image docker.io/${PREFIX}/metabase --confirm -o yaml > openshift/metabase.yml
	#   - postgresql-10-rhel7
	@@${OC} import-image registry.access.redhat.com/rhscl/postgresql-10-rhel7 --confirm -o yaml > openshift/postgres.yml
	# done.
