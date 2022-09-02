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


"""DAG module with task code examples of different ways to run a Docker container.

#### Ways to run a Docker container
The task of launching a Docker container with an application can be solved in several
ways:

1. Running a container with `BashOperator` by triggering a pipeline in Jenkins.
2. Running a container with `SimpleHttpOperator` by triggering a pipeline in Jenkins.
3. Running a Docker container using `DockerOperator`.

_Brief comments on the implementation of each option are provided in the comments on the
tasks in the DAG code._

#### Adding Airflow operators and Python packages for DAG
If you need to add or remove some package (dependency) for Apache Airflow, then you
need to:

1. Make changes to the `requirements.txt` file.
2. Rebuild the image using the `docker_build_airflow_local.sh` script.
3. Restart container using the `docker_run_airflow_local.sh` script.

#### Maintainer
[Viacheslav Kolupaev](
https://vkolupaev.com/?utm_source=dag_docs&utm_medium=link&utm_campaign=airflow-standalone
)
"""
from datetime import timedelta
from typing import Dict, Optional, Union

import pendulum
from airflow import DAG
from airflow.exceptions import AirflowFailException
from airflow.models import Variable
from airflow.operators.bash import BashOperator
from airflow.providers.docker.operators.docker import DockerOperator  # type: ignore[import]
from airflow.providers.http.operators.http import SimpleHttpOperator  # type: ignore[import]
from common_package import common_module  # type: ignore[import]


##########################################################################################
# Helper functions for DAG.
##########################################################################################
def get_non_private_environment() -> Dict[str, Optional[Union[str, int, bool]]]:
    """Get `non_private_environment`.

    `non_private_environment` is used in the signatures of some Airflow methods.

    Note:
        For example, in a `airflow.providers.docker.operators.docker`:
        1. `environment` (Optional[Dict]) – Environment variables to set in the container.
        2. `private_environment` (Optional[Dict]) – Private environment variables to set
        in the container. These are not templated, and hidden from the website.

        Therefore, such a separation is required.

    Returns:
        A dictionary with the values of the Airflow variables specified in this function.

        If there is no variable with the specified name in Airflow, then the value of the
        key will be `None`.

    """
    return {
        # Variables for doing `curl` towards `Generic Webhook Trigger` plugin for Jenkins.
        'JENKINS_AGENT_URL': Variable.get(
            key='JENKINS_AGENT_URL',
            default_var=None,
            deserialize_json=False,
        ),
        'GWT_TOKEN': Variable.get(
            key='GWT_TOKEN',
            default_var=None,
            deserialize_json=False,
        ),
        'GWT_BRANCH_NAME': Variable.get(
            key='GWT_BRANCH_NAME',
            default_var=None,
            deserialize_json=False,
        ),

        # Variables to pass to `DockerOperator`.
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


def get_private_environment() -> Dict[str, Optional[Union[str, int, bool]]]:
    """Get `private_environment`.

    `private_environment` is used in the signatures of some Airflow methods.

    Note:
        For example, in a `airflow.providers.docker.operators.docker`:
        1. `environment` (Optional[Dict]) – Environment variables to set in the container.
        2. `private_environment` (Optional[Dict]) – Private environment variables to set
        in the container. These are not templated, and hidden from the website.

        Therefore, such a separation is required.

    Returns:
        A dictionary with the values of the Airflow variables specified in this function.

        If there is no variable with the specified name in Airflow, then the value of the
        key will be `None`.

    """
    return {
        # Variables to pass to `DockerOperator`.
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


def get_all_environment() -> Dict[str, Optional[Union[str, int, bool]]]:
    """Get a dictionary with all Airflow variables.

    Airflow variables are set here: Airflow UI → Admin → Variables.

    Returns:
        The returned dictionary is the union of the `private_environment` and
        `non_private_environment` dictionaries.

    """
    private_environment = get_private_environment()
    non_private_environment = get_non_private_environment()

    all_environment = private_environment
    all_environment.update(non_private_environment)

    return all_environment


def get_bash_command_sending_curl_to_jenkins(
    all_environment: Dict[str, Optional[Union[str, int, bool]]],
) -> str:
    """Get custom bash command sending `curl` request to Jenkins."""
    generic_webhook_trigger_url = (
        '{jenkins_agent_url}/generic-webhook-trigger/invoke?' +
        'token={gwt_token}' +
        '&branch_name={gwt_branch_name}'
    ).format(
        jenkins_agent_url=all_environment.get('JENKINS_AGENT_URL'),
        gwt_token=all_environment.get('GWT_TOKEN'),
        gwt_branch_name=all_environment.get('GWT_BRANCH_NAME'),
    )

    # `curl` docs: https://curl.se/docs/manpage.html
    return (
        'curl' +
        ' -X POST' +
        ' -H "Content-Type: application/json"' +
        ' {generic_webhook_trigger_url}'
    ).format(generic_webhook_trigger_url=generic_webhook_trigger_url)


##########################################################################################
# DAG.
##########################################################################################
with DAG(
    # `airflow.models.dag`:
    # https://airflow.apache.org/docs/apache-airflow/2.3.1/_api/airflow/models/dag/index.html#airflow.models.dag.DAG
    dag_id='{dag_id_common_prefix}_dag001_example'.format(
        dag_id_common_prefix=common_module.DAG_ID_COMMON_PREFIX,
    ),
    description='Example DAG.',
    # Cron Presets: https://airflow.apache.org/docs/apache-airflow/stable/dag-run.html#cron-presets
    schedule_interval='*/15 * * * *',
    timetable=None,
    # Data Interval: https://airflow.apache.org/docs/apache-airflow/stable/dag-run.html#data-interval
    start_date=pendulum.datetime(year=2022, month=5, day=31, tz='UTC'),  # noqa: WPS432
    end_date=None,

    # These args will get passed on to each operator. You can override them on a per-task
    # basis during operator initialization.
    #
    # Docs: https://airflow.apache.org/docs/apache-airflow/stable/tutorial.html#default-arguments
    #
    # `airflow.models.baseoperator` signature:
    #     https://airflow.apache.org/docs/apache-airflow/stable/_api/airflow/models/baseoperator/index.html
    default_args={
        'owner': 'Viacheslav Kolupaev',

        'email': ['email-to-send-alerts@airflow-example.com'],
        'email_on_failure': False,
        'email_on_retry': False,

        'retries': 0,
        'retry_delay': timedelta(seconds=5 * 60),
        'depends_on_past': False,
        'wait_for_downstream': False,

        # Only scheduled tasks will be checked against SLA.
        # Manually triggered tasks will not invoke an SLA miss.
        'sla': timedelta(minutes=5),

        'execution_timeout': timedelta(minutes=6),

        # Callbacks: https://airflow.apache.org/docs/apache-airflow/stable/logging-monitoring/callbacks.html
        'on_failure_callback': common_module.task_failure_alert,
        'on_execute_callback': None,
        'on_retry_callback': None,
        'on_success_callback': common_module.task_success_alert,
        'sla_miss_callback': common_module.sla_callback,
        'pre_execute': None,
        'post_execute': None,

        'trigger_rule': 'always',
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
    tags=[common_module.DAG_ID_COMMON_PREFIX, 'vkolupaev', 'docker', 'boilerplate'],
) as dag:
    dag.doc_md = (
        __doc__  # providing that you have a docstring at the beginning of the DAG
    )

    all_environment = common_module.filter_dict_from_keys_with_none_values(
        dict_to_filter=get_all_environment(),
    )

    ######################################################################################
    # OPTION 1.
    #
    # Running a container with `BashOperator` by triggering a pipeline in Jenkins.
    #
    # The task sends a POST request to Jenkins using `curl`.
    #
    # To do this, you can use `Generic Webhook Trigger` plugin for Jenkins:
    #   https://github.com/jenkinsci/generic-webhook-trigger-plugin
    #
    # Before creating a DAG, you must first do the following:
    # 1. Create a secret for the token in Jenkins.
    # 2. Add a `GenericTrigger` trigger to `Jenkinsfile` using a token, see example:
    #    https://gitlab.com/vkolupaev/notebook/-/blob/main/Jenkinsfile
    # 3. Create the following variables in Airflow:
    #    a) `JENKINS_AGENT_URL`
    #    b) `GWT_TOKEN`
    #    c) `GWT_BRANCH_NAME`.
    ######################################################################################
    if (
        all_environment.get('JENKINS_AGENT_URL') is None
        or all_environment.get('GWT_TOKEN') is None
        or all_environment.get('GWT_BRANCH_NAME') is None
    ):
        raise AirflowFailException

    t1 = BashOperator(
        task_id='t1_run_container_by_triggering_a_jenkins_pipeline',
        dag=dag,
        bash_command=get_bash_command_sending_curl_to_jenkins(
            all_environment=all_environment,
        ),
        env=all_environment,
        append_env=False,
    )

    ######################################################################################
    # OPTION 2.
    #
    # Running a container with `SimpleHttpOperator` by triggering a pipeline in Jenkins.
    #
    # To do this, you can use `Generic Webhook Trigger` plugin for Jenkins:
    #   https://github.com/jenkinsci/generic-webhook-trigger-plugin
    #
    # Before creating a DAG, you must first do the following:
    # 1. Create a secret for the token in Jenkins.
    # 2. Add a `GenericTrigger` trigger to `Jenkinsfile` using a token, see example:
    #    https://gitlab.com/vkolupaev/notebook/-/blob/main/Jenkinsfile
    # 3. Create Connection for Jenkins agent here: Airflow UI → Admin → Connections.
    #    Specify the token in the `Extra` field:
    #  {"Authorization": "Bearer your-generic-webhook-trigger-plugin-token"}  # noqa: E800
    ######################################################################################
    t2 = SimpleHttpOperator(
        trigger_rule='all_failed',
        task_id='t2_run_container_using_simple_http_operator',
        dag=dag,
        endpoint='generic-webhook-trigger/invoke',
        method='POST',
        data=None,
        headers=None,
        http_conn_id='connection_to_jenkins',  # Airflow UI → Admin → Connections.
        log_response=True,
    )

    ######################################################################################
    # OPTION 3.
    #
    # Running a Docker container using `DockerOperator`.
    #
    # The disadvantages of this method:
    # 1. There is no argument to publish a container on some port.
    # 2. Environment variables are created centrally in Airflow UI → Admin → Variables.
    #    For example, it is not possible to create one `DB_PASSWORD` variable with
    #    different passwords for use in different containers.
    ######################################################################################
    t3 = DockerOperator(
        trigger_rule='all_failed',
        task_id='t3_run_container_using_docker_operator',
        dag=dag,
        image='boilerplate:latest',
        api_version='auto',
        command=None,
        container_name='boilerplate-2',
        cpus=0.5,
        # Default for Linux = 'unix:///var/run/docker.sock'
        # Check: `curl --unix-socket /var/run/docker.sock http:/localhost/version`
        docker_url='unix:///var/run/docker.sock',
        environment=get_non_private_environment(),
        private_environment=get_private_environment(),
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
        user=None,
        mounts=None,
        entrypoint=None,
        working_dir=None,
        xcom_all=False,
        docker_conn_id=None,
        dns=None,
        dns_search=None,
        auto_remove='success',
        shm_size=None,
        tty=False,
        privileged=False,
        cap_add=None,
        retrieve_output=False,
        retrieve_output_path=None,
        device_requests=None,  # the argument is missing from previous versions of the operator.
        on_success_callback=common_module.dag_success_alert,
    )

    ######################################################################################
    # Set the order in which tasks are to be executed.
    #
    # t1 for t2 — upstream; t2 for t1 — downstream.
    ######################################################################################
    t1 >> t2 >> t3 # noqa: WPS428
