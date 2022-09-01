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


"""This module contains common helper classes and functions for Airflow DAGs."""

from typing import Any, Dict, Final

from airflow.utils.context import Context

DAG_ID_COMMON_PREFIX: Final[str] = 'personal'


def sla_callback(dag, task_list, blocking_task_list, slas, blocking_tis) -> None:  # type: ignore[no-untyped-def]
    """Run SLA callback.

    Use this function for the `sla_miss_callback` argument.

    Docs: https://airflow.apache.org/docs/apache-airflow/stable/concepts/tasks.html#sla-miss-callback

    Args:
        dag:
            Parent DAG Object for the DAGRun in which tasks missed their SLA.
        task_list:
            String list (new-line separated) of all tasks that missed their
            SLA since the last time that the sla_miss_callback ran.
        blocking_task_list:
            Any task in the DAGRun(s) (with the same execution_date as a
            task that missed SLA) that is not in a SUCCESS state at the time that the
            sla_miss_callback runs. i.e. ‘running’, ‘failed’. These tasks are described as
            tasks that are blocking itself or another task from completing before its SLA
            window is complete.
        slas:
            List of SlaMiss objects associated with the tasks in the task_list
            parameter.
        blocking_tis:
            List of the TaskInstance objects that are associated with the tasks
            in the blocking_task_list parameter.

    """
    print(  # noqa: WPS421
        'The callback arguments are: ',
        {
            'dag': dag,
            'task_list': task_list,
            'blocking_task_list': blocking_task_list,
            'slas': slas,
            'blocking_tis': blocking_tis,
        },
    )


def task_failure_alert(context: Context) -> None:
    """Print a message to stdout indicating that the task failed.

    Use this function for the `on_failure_callback` argument.

    Args:
        context: Airflow callable context.

    """
    print(  # noqa: WPS421
        'Task has failed, task_instance_key_str: {task_instance_key_str}'.format(
            task_instance_key_str=context['task_instance_key_str'],
        ),
    )


def task_success_alert(context: Context) -> None:
    """Print a message to stdout indicating that the task completed successfully.

    Use this function for the `on_success_callback` argument.

    Args:
        context: Airflow callable context.

    """
    print(  # noqa: WPS421
        'Task has succeeded, task_instance_key_str: {task_instance_key_str}'.format(
            task_instance_key_str=context['task_instance_key_str'],
        ),
    )


def dag_success_alert(context: Context) -> None:
    """Print a message to stdout indicating that the DAG completed successfully.

    Use this function for the `on_success_callback` argument for the last DAG task.

    Args:
        context: Airflow callable context.

    """
    print(  # noqa: WPS421
        'DAG has succeeded, run_id: {run_id}'.format(
            run_id=context['run_id'],
        ),
    )


def filter_dict_from_keys_with_none_values(
    dict_to_filter: Dict[str, Any],
) -> Dict[Any, Any]:
    """Filter the dictionary for keys with `None` values.

    Note:
        Attention! Check expected types in statements. For example, `BashOperator`
        expects the following type: `env: Optional[Dict[str, str]] = None`.
        If you pass a dictionary {"key": None} to the operator, then there will be an
        error.

        Therefore, it is necessary to filter the dictionary from keys with empty values.

    Args:
        dict_to_filter: the dictionary to be filtered.

    Returns:
        Dictionary filtered from keys with `None` values.

    """
    filtered = {dict_key: dict_val for dict_key, dict_val in dict_to_filter.items() if dict_val is not None}
    dict_to_filter.clear()
    dict_to_filter.update(filtered)

    return dict_to_filter
