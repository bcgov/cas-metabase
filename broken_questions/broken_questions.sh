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
If any errors are found logfile is created with metadata for the questions that returned an error.
{ID, name, creator, updated_at, last_run_date, dashboard_count, error} is also printed to the console.

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

# create a temp templog
templog="temp_log.txt"

# create a templog name with date/time
logfile="log_$(date +"%Y_%m_%d_%T").txt"

# count of broken questions
declare -i broken_count=0

echo "Checking for broken questions..."

# Get the ids of all questions in metabase & check the /query endpoint for an error
# Print broken question results to templog
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
          -H "X-Metabase-Session: ${session_id//[$'\t\r\n ']}" | jq -r '.|[.id, .name, .collection_id // "null", .creator.email, .updated_at, .last_query_start // "never", .dashboard_count] | @tsv')
        echo -e "$error_string $(printf '\t') $error" >> "$templog";
        broken_count+=1
        echo -en "\rBroken questions found: $broken_count"
      fi
    else
      if echo "$query" | grep -q "504"; then
        curl -s -k -X GET \
          "$metabase_url/api/card/$id" \
          -H 'Cache-Control: no-cache' \
          -H 'Content-Type: application/json' \
          -H 'Accept: application/json' \
          -H "X-Metabase-Session: ${session_id//[$'\t\r\n ']}" | jq -r '.|[.id, .name, .collection_id // "null", .creator.email, .updated_at, .last_query_start // "never", .dashboard_count] + ["Error: Query Timeout"] | @tsv' >> "$templog"
        broken_count+=1
        echo -en "\rBroken questions found: $broken_count"
      else
        echo "ID: $id: Failed to parse JSON, or got false/null"
      fi
    fi
done

 # If a templog was created, print the IDs of the broken questions and exit 1. Else exit 0.
if [ -f "$templog" ]; then
    echo "Broken questions:"
    # Prettify output of templog to a timestamped logfile
    sed -i "1iid\tname\tcollection_id\tcreator_email\tupdated_at\tlast_run\tdashboard_count" "$templog"
    cat "$templog" | sed -e 's/  Position:.*//g' | sed -e 's/  Hint:.*//g' | column -t -s$'\t' >> "$logfile"
    cat "$templog" | sed -e 's/  Position:.*//g' | sed -e 's/  Hint:.*//g' | column -t -s$'\t'
    exit 0
else
    echo "OK - No broken questions found."
    exit 0
fi
