# CAS Metabase Helm chart

![Lifecycle:Stable](https://img.shields.io/badge/Lifecycle-Stable-97ca00)

## Testing for broken questions

Over time, metabase questions can become broken. Making changes to the underlying database schema or updating the version of metabase are the most likely points where a question or set of questions can break. To check for broken questions, we have a script `broken_questions.sh` that will query the API and return data on any questions that are currently broken (questions that take longer than 60s will timeout and are also caught by the script).
To run it (from the root directory):

`./broken_questions/broken_questions.sh $METABASE_PATH $METABASE_API_USER $METABASE_API_PASSWORD`
(`./broken_questions/broken_questions.sh -h` for details on usage)

This will output a list of broken questions both in your terminal, and (if there are broken questions) it will create a timestamped logfile with the broken question data containing the id of the question, the name of the question, the id of the collection containing the question, the name of the user who authored the question, the timestamp of when that question was last updated, the timestamp of the last query run, the number of dashboards the question is used in and the error message associated with the broken question.

Example output:

id | name         |  collection_id |   author   |    updated_at       |    last_run         |  dashboard_count |         error
1  | question 1   |        1       |  Joey Joe  | 1970-01-01 00:00:01 | 1999-01-01 00:00:01 |         0        | No such field "missing_id"

It is a good idea to run this script whenever upgrading metabase or making changes to the underlying schema to see what effect it may have on the metabase end users. It is also helpful to run it periodically and contact the authors of broken questions to see if those questions are still useful and should be fixed or if they can be cleaned up / archived.

## Database Disaster Recovery
[Steps for database recovery](https://github.com/bcgov/cas-postgres#point-in-time-recovery)
