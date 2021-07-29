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
DAG cas_metabase_cert_renewal
Renews site certificates for cas metabase
"""
dag = DAG('cas_metabase_cert_renewal', schedule_interval='0 8 * * *',
          default_args=default_args, is_paused_upon_creation=False)

cert_renewal_task = PythonOperator(
    python_callable=trigger_k8s_cronjob,
    task_id='cert_renewal',
    op_args=['cas-metabase-acme-renewal', namespace],
    dag=dag)

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
