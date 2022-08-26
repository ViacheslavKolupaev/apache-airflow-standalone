#!/bin/bash

##########################################################################################
#  Copyright 2022 Viacheslav Kolupaev; author's website address:
#
#   https://vkolupaev.com/?utm_source=c&utm_medium=link&utm_campaign=airflow-standalone
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
# file except in compliance with the License. You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the specific language governing
# permissions and limitations under the License.
##########################################################################################

##########################################################################################
# The script will create and run a Docker container with standalone Apache Airflow.
#
# This container is for development purposes only. Do not use this in production!
#
# The container will be named according to the following scheme:
# `apache-airflow-standalone-<airflow_version>-<python_base_image>`.
#
# The container is automatically deleted when it is stopped.
#
# The Apache Airflow web server will be available at: http://127.0.0.1:8080/.
# For authorization use login `admin` and password `admin`.
#
# A directory `airflow_dags_dir` with DAG files from the host will be mounted to the
# container. Thus, if adding or changes to the DAG file, you do not need to rebuild the
# image and restart the container.
#
# The container has CPU, RAM and swap file limits. If you plan to change the limit
# settings yourself, then make sure you understand what you are doing.
#
# If you need to add or remove some package (dependency) for Apache Airflow, then you
# need to:
# 1. Make changes to the `requirements.txt` file.
# 2. Rebuild the image using the `docker_build_airflow_local.sh` script.
# 3. Restart container with this script.
#
# If necessary, you need to replace the values of the variables in the `main()` function:
# - `airflow_dags_dir`;
# - `airflow_version`;
# - `python_base_image`;
# - `docker_image_name`;
# - `docker_image_tag`.
#
# See available Apache Airflow tags here: https://hub.docker.com/r/apache/airflow/tags
#
# The script uses the helper functions from the `common_bash_functions.sh` file.
##########################################################################################


#######################################
# Update library of common bash functions.
# Arguments:
#  None
#######################################
function update_library_of_common_bash_functions() {
  # shellcheck source=./common_bash_functions.sh
  if ! source ./common_bash_functions.sh; then
    echo "'common_bash_functions.sh' module was not imported due to some error. Exit."
    exit 1
  else
    copy_file_from_remote_git_repo \
      'git@gitlab.com:vkolupaev/notebook.git' \
      'main' \
      'common_bash_functions.sh'
  fi
}

#######################################
# Run standalone Apache Airflow in a Docker container.
# Globals:
#   None
# Arguments:
#   docker_image_name
#   docker_image_tag
#   airflow_dags_dir
#######################################
function docker_run_standalone_airflow_in_container() {
  echo ''
  log_to_stdout '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' 'Bl'
  log_to_stdout 'Running standalone Apache Airflow in Docker container...'

  # Checking function arguments.
  if [ -z "$1" ] || [ "$1" = '' ] || [[ "$1" = *' '* ]] ; then
    log_to_stderr "Argument 'docker_image_name' was not specified in the function call. Exit."
    exit 1
  else
    local docker_image_name
    docker_image_name=$1
    readonly docker_image_name
    log_to_stdout "Argument 'docker_image_name' = ${docker_image_name}" 'Y'
  fi

  if [ -z "$2" ] || [ "$2" = '' ] || [[ "$2" = *' '* ]] ; then
    log_to_stderr "Argument 'docker_image_tag' was not specified in the function call. Exit."
    exit 1
  else
    local docker_image_tag
    docker_image_tag=$2
    readonly docker_image_tag
    log_to_stdout "Argument 'docker_image_tag' = ${docker_image_tag}" 'Y'
  fi

  if [ -z "$3" ] || [ "$3" = '' ] || [[ "$3" = *' '* ]] ; then
    log_to_stderr "Argument 'airflow_dags_dir' was not specified in the function call. Exit."
    exit 1
  else
    local airflow_dags_dir
    airflow_dags_dir=$3
    readonly airflow_dags_dir
    log_to_stdout "Argument 'airflow_dags_dir' = ${airflow_dags_dir}" 'Y'
  fi

  # Starting an image-based container and executing the specified command in it.
  # Docs: https://docs.docker.com/engine/reference/commandline/run/
  # Usage: docker run [OPTIONS] IMAGE[:TAG|@DIGEST] [COMMAND] [ARG...]
  if ! docker run \
    --detach \
    --rm \
    --restart=no \
    --log-driver=local `# https://docs.docker.com/config/containers/logging/local/` \
    --log-opt mode=non-blocking \
    --network="${docker_image_name}"-net \
    --publish 8080:8080 \
    --cpus="2" \
    --memory-reservation=3g \
    --memory=4g \
    --memory-swap=5g \
    --mount type=bind,source="${airflow_dags_dir}",target=/opt/airflow/dags,readonly `# In Windows OS in WSL 1 mode,
    # you must first add the 'airflow_dags_dir' in the 'File sharing' section of the Docker Desktop settings.
    # See documentation: https://docs.docker.com/desktop/windows/#file-sharing` \
    --privileged=false  `# Be careful when enabling this option! Potentially unsafe.
    # The container can then do almost everything that the host can do.` \
    --health-cmd='python --version || exit 1' \
    --health-interval=2s \
    --env LANG=C.UTF-8 \
    --env IS_DEBUG=True  `# Not for production environment.` \
    --env "_AIRFLOW_DB_UPGRADE=true" \
    --env "_AIRFLOW_WWW_USER_CREATE=true" \
    --env "_AIRFLOW_WWW_USER_PASSWORD=admin" \
    --name "${docker_image_name}-${docker_image_tag}"  `# Container name.` \
    "${docker_image_name}:${docker_image_tag}"  `# The name and tag of the image to use to launch the container.` \
    standalone  `# The command to execute inside the container.`;
  then
    log_to_stderr 'Error starting container. Exit.'
    exit 1
  else
    log_to_stdout 'Docker container started successfully. Continue.' 'G'
  fi

  log_to_stdout '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<' 'Bl'
}

#######################################
# Run the main function of the script.
# Globals:
#   HOME
# Arguments:
#  None
#######################################
function main() {
  # 1. Declaring Local Variables.
  local docker_registry
  readonly docker_registry='docker.io'

  local docker_user_name
  readonly docker_user_name='vkolupaev'

  local airflow_dags_dir
  airflow_dags_dir="${HOME}/PycharmProjects/apache-airflow-standalone/dags"  # change the path if necessary
  readonly airflow_dags_dir

  local airflow_version
  readonly airflow_version="2.2.4"  # change if necessary

  local python_base_image
  readonly python_base_image="python3.8"  # change if necessary

  local docker_image_name
  readonly docker_image_name='apache-airflow-standalone'  # change if necessary

  local docker_image_tag
  docker_image_tag="${airflow_version}-${python_base_image}"  # don't change
  readonly docker_image_tag

  # 2. Update and import the library of common bash functions.
  update_library_of_common_bash_functions

  # 3. Execution of script logic.
  log_to_stdout 'START SCRIPT EXECUTION.' 'Bl'

  # Execute Docker operations.
  check_if_docker_is_running
  docker_login_to_registry \
    "${docker_registry}" \
    "${docker_user_name}"

  docker_stop_and_remove_containers_by_name "${docker_image_name}-${docker_image_tag}"
  docker_stop_and_remove_containers_by_ancestor \
    "${docker_image_name}" \
    "${docker_image_tag}"

  docker_create_user_defined_bridge_network "${docker_image_name}"
  docker_run_standalone_airflow_in_container \
    "${docker_image_name}" \
    "${docker_image_tag}" \
    "${airflow_dags_dir}"

  log_to_stdout 'END OF SCRIPT EXECUTION.' 'Bl'
}

main "$@"
