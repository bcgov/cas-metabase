# -*- coding: utf-8 -*-
"""
DAG cas_metabase_cert_renewal
Triggering the cas-metabase-acme-renewal cron job
"""
from dag_configuration import default_dag_args
from trigger_k8s_cronjob import trigger_k8s_cronjob
from airflow.operators.python_operator import PythonOperator
from datetime import datetime, timedelta
from airflow import DAG
import os

START_DATE = datetime.now() - timedelta(days=2)

namespace = os.getenv('GGIRCS_NAMESPACE')

default_args = {
    **default_dag_args,
    'start_date': START_DATE,
}

dag = DAG('cas_metabase_cert_renewal', schedule_interval='0 8 * * *',
          default_args=default_args)

cert_renewal_task = PythonOperator(
    python_callable=trigger_k8s_cronjob,
    task_id='cert_renewal',
    op_args=['cas-metabase-acme-renewal', namespace],
    dag=dag)
