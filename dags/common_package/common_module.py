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

DAG_ID_COMMON_PREFIX: Final[str] = 'personal'

def sla_callback(dag, task_list, blocking_task_list, slas, blocking_tis) -> None:
    """Run SLA callback.

    Use this function for the `sla_miss_callback` argument.
    Docs: https://airflow.apache.org/docs/apache-airflow/stable/concepts/tasks.html#sla-miss-callback
    """
    print(
        "The callback arguments are: ",
        {
            "dag": dag,
            "task_list": task_list,
            "blocking_task_list": blocking_task_list,
            "slas": slas,
            "blocking_tis": blocking_tis,
        },
    )

def task_failure_alert(context) -> None:
    print(f"Task has failed, task_instance_key_str: {context['task_instance_key_str']}")

def task_success_alert(context) -> None:
    print(f"Task has succeeded, task_instance_key_str: {context['task_instance_key_str']}")

def dag_success_alert(context) -> None:
    print(f"DAG has succeeded, run_id: {context['run_id']}")

def filter_dict_from_keys_with_none_values(dict_to_filter: Dict[str, Any]) -> Dict[Any, Any]:
    """Filter the dictionary for keys with `None` values.

    Attention! Check expected types in statements. For example, `BashOperator` expects
    the following type: `env: Optional[Dict[str, str]] = None`.
    If you pass a dictionary {"key": None} to the operator, then there will be an error.

    Therefore, it is necessary to filter the dictionary from keys with empty values.
    """
    filtered = {k: v for k, v in dict_to_filter.items() if v is not None}
    dict_to_filter.clear()
    dict_to_filter.update(filtered)

    return dict_to_filter
