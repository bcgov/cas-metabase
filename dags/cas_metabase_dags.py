# -*- coding: utf-8 -*-
"""
DAG cas_metabase_cert_renewal
Triggering the cas-metabase-acme-renewal cron job
"""
from dag_configuration import default_dag_args
from trigger_k8s_cronjob import trigger_k8s_cronjob
from walg_backups import create_backup_task
from airflow.operators.python_operator import PythonOperator
from datetime import datetime, timedelta
from airflow import DAG
import os

TWO_DAYS_AGO = datetime.now() - timedelta(days=2)

namespace = os.getenv('GGIRCS_NAMESPACE')

default_args = {
    **default_dag_args,
    'start_date': TWO_DAYS_AGO
}

"""
###############################################################################
#                                                                             #
# DAG triggering the wal-g backup job                                         #
#                                                                             #
###############################################################################
"""

metabase_full_backup_dag = DAG('walg_backup_metabase_full', default_args=default_args,
                             schedule_interval='0 8 * * *', is_paused_upon_creation=False)

create_backup_task(metabase_full_backup_dag,
                   namespace, 'cas-metabase-patroni')

"""
###############################################################################
#                                                                             #
# DAG to restore data from PROD (if in test)                                  #
#                                                                             #
###############################################################################
"""

"""
If we're in the test namespace, dag first restores data from prod and then fixes the db connection passwords to be for the test db.
"""
prod_test_restore_dag = DAG('cas_metabase_prod_test_restore', schedule_interval=None,
                    default_args=default_args)

def prod_test_restore(dag):
    return PythonOperator(
        python_callable=trigger_k8s_cronjob,
        task_id='metabase-prod-test-restore',
        op_args=['cas-metabase-prod-test-restore', namespace],
        dag=dag)

def fix_db_pass(dag):
    return PythonOperator(
        python_callable=trigger_k8s_cronjob,
        task_id='metabase-db-pass',
        op_args=['cas-metabase-db-pass', namespace],
        dag=dag)

prod_test_restore(prod_test_restore_dag) >> fix_db_pass(prod_test_restore_dag)
