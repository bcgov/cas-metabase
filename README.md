
Cas Docker Metabase image
=========================

This is a docker image based on the official metabase docker image: https://hub.docker.com/r/metabase/metabase

`run_metabase.sh` has been modified to support running with a random user ID instead of root.

#### Download a built image
to get a built image: `https://gcr.io/cas-google-storage/metabase:{latest, v0.36.6 or Commit SHA}`

#### OpenShift 3.11 Guidelines
https://docs.openshift.com/container-platform/3.11/creating_images/guidelines.html