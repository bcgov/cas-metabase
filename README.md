
Cas Docker Metabase image
=========================

![Lifecycle:Stable](https://img.shields.io/badge/Lifecycle-Stable-97ca00)

This is a docker image based on the official metabase docker image: https://hub.docker.com/r/metabase/metabase

`run_metabase.sh` has been modified to support running with a random user ID instead of root.

#### Download a built image
to get a built image: `https://gcr.io/cas-google-storage/metabase:{latest, v0.36.6 or Commit SHA}`

#### OpenShift 3.11 Guidelines
https://docs.openshift.com/container-platform/3.11/creating_images/guidelines.html

#### Bugs
There is a bug in metabase where enum types cannot be filtered. Attempting to do so results in a type mismatch error. The issue is documented on the [metabase github](https://github.com/metabase/metabase/issues/7092).
The workaround:
Find the id of the problem field from the data model in the metabase admin view & manually update the `base_type` and `database_type` columns in the `metabase_field` data directly.
ex: `update metabase_field set base_type='type/PostgresEnum', database_type = 'your_schema.your_enum_type' where id=<field id>;`
