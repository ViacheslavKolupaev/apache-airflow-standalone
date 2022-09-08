`apache-airflow-standalone`
=======

![GitLab License](
https://img.shields.io/gitlab/license/vkolupaev/apache-airflow-standalone?color=informational
)
![GitLab tag (latest by SemVer)](
https://img.shields.io/gitlab/v/tag/vkolupaev/apache-airflow-standalone?label=apache-airflow-standalone
)
![Python](
https://img.shields.io/static/v1?label=Python&message=3.8&color=informational&logo=python&logoColor=white
)
![code style](
https://img.shields.io/static/v1?label=code%20style&message=wemake-python-styleguide&color=informational
)
![mypy](
https://img.shields.io/static/v1?label=mypy&message=checked&color=informational
)
![imports](
https://img.shields.io/static/v1?label=imports&message=isort&color=informational
)

[//]: # "[![Docker Pulls](
https://img.shields.io/docker/pulls/vkolupaev/apache-airflow-standalone?color=informational&logo=docker&logoColor=white
)](https://hub.docker.com/r/vkolupaev/apache-airflow-standalone)"
[//]: # "![GitLab stars](https://img.shields.io/gitlab/stars/vkolupaev/apache-airflow-standalone?style=social)"
[//]: # "![GitHub Repo stars](https://img.shields.io/github/stars/ViacheslavKolupaev/apache-airflow-standalone?style=social)"

## What is this repository?
This is a repository with bash scripts and auxiliary files for building a Docker image and running a Docker container
with `Apache Airflow Standalone` in a `DEV` environment (locally).

Software versions:
1. Airflow version: `2.2.4`;
2. Python version: `python3.8`;
3. python packages: see `requirements.txt` file.

⚠️**Not suitable for production environment. Use it for local development and testing only!**

## To whom and how can it be useful?
An `Apache Airflow` running in a Docker container can be useful to a Data Engineer or any other engineer who
develops DAG scripts.

In a real workflow, only very simple DAGs can be developed 100% correctly the first time. Usually you have to make a
few additional changes to fix the detected errors.

This leads to the following consequences:
1. The git history of the `TEST` repository with DAG includes `Work in progress (WIP)` and debug commits. It could
   also be 1 commit, and 50. It all depends on the task. _Junk commits make git history difficult to navigate._
2. If `TEST` already has another task ready or almost ready for deployment to `PROD` Pull Request, then _it will be
   blocked until you're done with debug_. This increases the time-to-market.

Therefore, it is possible to take out development of DAG to the maximum in `DEV`-environment. This will allow you to
commit to the `TEST` repository with the code project already more or less tested solutions.

That's what `apache-airflow-standalone` is for.

---

Copyright 2022 [Viacheslav Kolupaev](
https://vkolupaev.com/?utm_source=readme&utm_medium=link&utm_campaign=apache-airflow-standalone
).

[![website](
https://img.shields.io/static/v1?label=website&message=vkolupaev.com&color=blueviolet&style=for-the-badge&
)](https://vkolupaev.com/?utm_source=readme&utm_medium=badge&utm_campaign=apache-airflow-standalone)

[![LinkedIn](
https://img.shields.io/static/v1?label=LinkedIn&message=vkolupaev&color=informational&style=flat&logo=linkedin
)](https://www.linkedin.com/in/vkolupaev/)
[![Telegram](
https://img.shields.io/static/v1?label=Telegram&message=@vkolupaev&color=informational&style=flat&logo=telegram
)](https://t.me/vkolupaev/)
