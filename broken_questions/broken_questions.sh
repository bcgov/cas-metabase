#!/usr/bin/env bash

set -e

metabase_url=$1
user=$2
pass=$3

# =============================================================================
# Usage:
# -----------------------------------------------------------------------------
usage() {
    cat << EOF
$0 <Metabase URL> <User> <Password>

Requires 3 parameters:
- Metabase URL: The URL to the metabase instance
- User:         The username to be used to sign in and access the API
- Password:     The user's password

Uses the Metabase API to sign in & check the /api/query endpoint for an error for each question in Metabase.
If no errors are found, an OK message is printed and this script exits 0.
If any errors are found a logfile is created with all the IDs of questions that returned an error,
the values: {ID, creator, updated_at, error} are printed to the console.

Options

  -h, --help
    Prints this message

EOF
}

if [ "$1" = '-h' ]; then
    usage
    exit 0
fi

if [ "$#" != 3 ]; then
    echo "Passed $# parameters. Expected 3."
    usage
    echo "exiting with status 1"
    exit 1
fi

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
    query=$(curl -s -k -X POST \
      "$metabase_url/api/card/$id/query" \
      -H 'Cache-Control: no-cache' \
      -H 'Content-Type: application/json' \
      -H 'Accept: application/json' \
      -H "X-Metabase-Session: ${session_id//[$'\t\r\n ']}")
    if jq -e . >/dev/null 2>&1 <<<"$query"; then
      error=$(echo "$query" | jq -r ".error")
      if [ "$error" != null ]; then \
        error_string=$(curl -s -k -X GET \
          "$metabase_url/api/card/$id" \
          -H 'Cache-Control: no-cache' \
          -H 'Content-Type: application/json' \
          -H 'Accept: application/json' \
          -H "X-Metabase-Session: ${session_id//[$'\t\r\n ']}" | jq -r '.|[.id, .creator.email, .updated_at] | @tsv')
        echo -e "$error_string $(printf '\t') $error" >> "$logfile";
      fi
    else
      if echo "$query" | grep -q "504"; then
        echo "matched";
        curl -s -k -X GET \
          "$metabase_url/api/card/$id" \
          -H 'Cache-Control: no-cache' \
          -H 'Content-Type: application/json' \
          -H 'Accept: application/json' \
          -H "X-Metabase-Session: ${session_id//[$'\t\r\n ']}" | jq -r '.|[.id, .creator.email, .updated_at] + ["Error: Query Timeout"] | @tsv' >> "$logfile"
      else
        echo "ID: $id: Failed to parse JSON, or got false/null"
      fi
    fi
done

 # If a logfile was created, print the IDs of the broken questions and exit 1. Else exit 0.
if [ -f "$logfile" ]; then
    echo "Broken questions:"
    echo "(id, creator, last_updated, error)"
    cat "$logfile"
    exit 0
else
    echo "OK - No broken questions found."
    exit 0
fi
