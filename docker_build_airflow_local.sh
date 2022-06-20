#!/bin/bash

##########################################################################################
# Copyright (c) 2022. Viacheslav Kolupaev, https://vkolupaev.com/
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
# The script will build a Docker image with standalone Apache Airflow.
#
# Not suitable for production environment. Use it for local development and testing only!
#
# The image will be named according to the following scheme:
# `apache-airflow-standalone-<airflow_version>-<python_base_image>`.
#
# The Apache Airflow web server will be available at: http://127.0.0.1:8080/.
# For authorization use login `admin` and password `admin`.
#
# A directory `airflow_dags_dir` with DAG files from the host will be mounted to the
# container. Thus, if adding or changes to the DAG file, you do not need to rebuild the
# image and restart the container.
#
# If you need to add or remove some package (dependency) for Apache Airflow, then you
# need to:
# 1. Make changes to the `requirements.txt` file.
# 2. Rebuild the image using the `docker_build_airflow_local.sh` script.
# 3. Restart container with this script.
#
# If necessary, you need to replace the values of the variables in the `main()` function:
# - `dockerfile_dir`;
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
# Build a standalone Apache Airflow docker image.
# Arguments:
#   docker_image_name
#   docker_image_tag
#   dockerfile_dir
#   airflow_version
#   python_base_image
#######################################
function docker_build_standalone_airflow_image() {
  echo ''
  log_to_stdout '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' 'Bl'
  log_to_stdout "Building a standalone Apache Airflow Docker image..."

  # Checking function arguments.
  if [ -z "$1" ] ; then
    log_to_stderr "Argument 'docker_image_name' was not specified in the function call. Exit."
    exit 1
  else
    local docker_image_name
    docker_image_name=$1
    readonly docker_image_name
    log_to_stdout "Argument 'docker_image_name' = ${docker_image_name}"
  fi

  if [ -z "$2" ] ; then
    log_to_stderr "Argument 'docker_image_tag' was not specified in the function call. Exit."
    exit 1
  else
    local docker_image_tag
    docker_image_tag=$2
    readonly docker_image_tag
    log_to_stdout "Argument 'docker_image_tag' = ${docker_image_tag}"
  fi

  if [ -z "$3" ] ; then
    log_to_stderr "Argument 'dockerfile_dir' was not specified in the function call. Exit."
    exit 1
  else
    local dockerfile_dir
    dockerfile_dir=$3
    readonly dockerfile_dir
    log_to_stdout "Argument 'dockerfile_dir' = ${dockerfile_dir}"
  fi

  if [ -z "$4" ] ; then
    log_to_stderr "Argument 'airflow_version' was not specified in the function call. Exit."
    exit 1
  else
    local airflow_version
    airflow_version=$4
    readonly airflow_version
    log_to_stdout "Argument 'airflow_version' = ${airflow_version}"
  fi

  if [ -z "$5" ] ; then
    log_to_stderr "Argument 'python_base_image' was not specified in the function call. Exit."
    exit 1
  else
    local python_base_image
    python_base_image=$5
    readonly python_base_image
    log_to_stdout "Argument 'python_base_image' = ${python_base_image}"
  fi

  # Get the short SHA of the current Git revision.
  local git_rev_short_sha
  git_rev_short_sha="$(git -C ${dockerfile_dir} rev-parse --short HEAD)"
  log_to_stdout "git_rev_short_sha: ${git_rev_short_sha}"

  # Building a Docker image.
  # See about `DOCKER_BUILDKIT`: https://github.com/moby/moby/issues/34151#issuecomment-739018493
  # See about `DOCKER_SCAN_SUGGEST`: https://github.com/docker/scan-cli-plugin/issues/149#issuecomment-823969364
  if ! DOCKER_BUILDKIT=1 DOCKER_SCAN_SUGGEST=false docker build \
       --pull \
       --file "${dockerfile_dir}/Dockerfile" \
       --build-arg VCS_REF="${git_rev_short_sha}" \
       --build-arg AIRFLOW_VERSION="${airflow_version}" \
       --build-arg PYTHON_BASE_IMAGE="${python_base_image}" \
       --tag "${docker_image_name}:${docker_image_tag}" \
       "${dockerfile_dir}"  `# docker context PATH`; then
    log_to_stderr 'Error building Docker image. Exit.'
    exit 1
  else
    log_to_stdout 'Docker image successfully built. Continue.' 'G'
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
  local dockerfile_dir
  dockerfile_dir="${HOME}/PycharmProjects/apache-airflow-standalone"  # double-check the path
  readonly dockerfile_dir

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
  docker_image_remove_by_name_tag \
    "${docker_image_name}" \
    "${docker_image_tag}"

  docker_build_standalone_airflow_image \
    "${docker_image_name}" \
    "${docker_image_tag}" \
    "${dockerfile_dir}" \
    "${airflow_version}" \
    "${python_base_image}"

  log_to_stdout 'END OF SCRIPT EXECUTION.' 'Bl'
}

main "$@"
