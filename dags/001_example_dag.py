# ########################################################################################
#  Copyright 2022 Viacheslav Kolupaev; author's website address:
#
#     https://vkolupaev.com/?utm_source=c&utm_medium=link&utm_campaign=airflow-standalone
#
#  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
#  file except in compliance with the License. You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software distributed under
#  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied. See the License for the specific language governing
#  permissions and limitations under the License.
# ########################################################################################

"""
###  001_example_dag
Maintainer: Viacheslav Kolupaev

If you need to add or remove some package (dependency) for Apache Airflow, then you
need to:
1. Make changes to the `requirements.txt` file.
2. Rebuild the image using the `docker_build_airflow_local.sh` script.
3. Restart container using the `docker_run_airflow_local.sh` script.
"""

from datetime import timedelta

import pendulum

from airflow import DAG
from airflow.models import Variable
from airflow.operators.bash import BashOperator
from airflow.providers.docker.operators.docker import DockerOperator

from common_package import common_module

with DAG(
    # `airflow.models.dag`: https://airflow.apache.org/docs/apache-airflow/2.3.1/_api/airflow/models/dag/index.html#airflow.models.dag.DAG
    dag_id='001_example_dag',
    description='Example DAG.',

    # Cron Presets: https://airflow.apache.org/docs/apache-airflow/stable/dag-run.html#cron-presets
    schedule_interval='*/15 * * * *',

    timetable=None,

    # Data Interval: https://airflow.apache.org/docs/apache-airflow/stable/dag-run.html#data-interval
    start_date=pendulum.datetime(year=2022, month=5, day=31, tz="UTC"),
    end_date=None,

    # These args will get passed on to each operator
    # You can override them on a per-task basis during operator initialization
    default_args={
        'depends_on_past': False,
        'email': ['airflow@example.com'],
        'email_on_failure': False,
        'email_on_retry': False,
        'retries': 0,
        'retry_delay': timedelta(minutes=5),
        'trigger_rule': 'always',
        # 'queue': 'bash_queue',
        # 'pool': 'backfill',
        # 'priority_weight': 10,
        # 'end_date': datetime(2016, 1, 1),
        # 'wait_for_downstream': False,

        # Only scheduled tasks will be checked against SLA.
        # Manually triggered tasks will not invoke an SLA miss.
        'sla': timedelta(minutes=5),

        'execution_timeout': timedelta(minutes=6),

        # Callbacks: https://airflow.apache.org/docs/apache-airflow/stable/logging-monitoring/callbacks.html
        'on_failure_callback': common_module.task_failure_alert,
        'on_success_callback': common_module.task_success_alert,
        'on_retry_callback': None,
        'sla_miss_callback': common_module.sla_callback,
    },
    max_active_tasks=1,
    max_active_runs=1,
    default_view='graph',
    dagrun_timeout=timedelta(minutes=10),
    # Catchup: https://airflow.apache.org/docs/apache-airflow/stable/dag-run.html#catchup
    catchup=False,
    doc_md=None,
    params=None,
    sla_miss_callback=common_module.sla_callback,
    tags=['vkolupaev', 'docker', 'boilerplate'],


) as dag:
    dag.doc_md = __doc__  # providing that you have a docstring at the beginning of the DAG

    # Getting environment variables: Airflow UI → Admin → Variables.
    private_environment = {
        'APP_API_ACCESS_HTTP_BEARER_TOKEN': Variable.get(
            key='APP_API_ACCESS_HTTP_BEARER_TOKEN',
            default_var=None,
            deserialize_json=False,
        ),
        'DB_PASSWORD': Variable.get(
            key='DB_PASSWORD',
            default_var=None,
            deserialize_json=False,
        ),
    }
    non_private_environment = {
        'APP_ENV_STATE': Variable.get(
            key='APP_ENV_STATE',
            default_var=None,
            deserialize_json=False,
        ),
        'DB_USER': Variable.get(
            key='DB_USER',
            default_var=None,
            deserialize_json=False,
        ),
        'IS_DEBUG': Variable.get(
            key='IS_DEBUG',
            default_var=None,
            deserialize_json=False,
        ),
    }
    all_environment = private_environment
    all_environment.update(non_private_environment)

    # t1, t2 and t3 are examples of tasks created by instantiating operators

    # OPTION 1.
    # Running a container using a bash script.
    t1 = BashOperator(
        task_id='t1_run_bash_operator',
        dag=dag,
        bash_command='pip freeze',
        env=all_environment,
        #append_env=False,  # the argument is missing from previous versions of the operator.
    )

    # OPTION 2.
    # Running a container using `airflow.providers.docker.operators.docker`.
    # There is no argument to publish a container on some port.
    t2 = DockerOperator(
        task_id='t2_run_container_using_docker_operator',
        dag=dag,
        image='boilerplate:latest',
        api_version='auto',
        command=None,
        container_name='boilerplate-2',
        cpus=0.5,
        # Default for Linux = 'unix:///var/run/docker.sock'
        # Check: `curl --unix-socket /var/run/docker.sock http:/localhost/version`
        docker_url='unix:///var/run/docker.sock',
        environment=non_private_environment,
        private_environment=private_environment,
        force_pull=False,
        mem_limit='200m',
        host_tmp_dir=None,
        network_mode='boilerplate-net',
        tls_ca_cert=None,
        tls_client_cert=None,
        tls_client_key=None,
        tls_hostname=None,
        tls_ssl_version=None,
        mount_tmp_dir=False,
        tmp_dir='/tmp/airflow',
        user=None,
        mounts=None,
        entrypoint=None,
        working_dir=None,
        xcom_all=False,
        docker_conn_id=None,
        dns=None,
        dns_search=None,
        auto_remove=True,
        shm_size=None,
        tty=False,
        privileged=False,
        cap_add=None,
        retrieve_output=False,
        retrieve_output_path=None,
        # device_requests=None,  # the argument is missing from previous versions of the operator.
        on_success_callback=common_module.dag_success_alert,
    )

    # t1 for t2 — upstream; t2 for t1 — downstream.
    t1 >> t2
