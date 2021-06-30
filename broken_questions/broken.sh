#!/usr/bin/env bash

set -e

metabase_url= # <METABASE URL GOES HERE>
user= # <METABASE USERNAME GOES HERE>
pass= # <METABASE PASSWORD GOES HERE>

# Log in & get session id for use in curl commands below
session_id=$(curl -v -k -X POST \
  "$metabase_url/api/session" \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d "{\"username\": \"$user\", \"password\": \"$pass\"}" | jq .id)

# Trim leading & trailing doublequotes from id
session_id=$(sed -e 's/^"//' -e 's/"$//' <<<"$session_id")

# create a logfile name with date/time
logfile="log_$(date +"%Y_%m_%d_%T").txt"

# Get the ids of all questions in metabase & check the /query endpoint for an error
# Print broken question results to logfile
curl -s -k -X GET \
  "$metabase_url/api/card" \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H "X-Metabase-Session: ${session_id//[$'\t\r\n ']}" | jq -r '.[].id' | while read -r id ; do
    error=$(curl -s -k -X POST \
      "$metabase_url/api/card/$id/query" \
      -H 'Cache-Control: no-cache' \
      -H 'Content-Type: application/json' \
      -H 'Accept: application/json' \
      -H "X-Metabase-Session: ${session_id//[$'\t\r\n ']}" | jq -r .error)
    if [ "$error" != null ]; then echo "$id" >> "$logfile" ; fi
done
