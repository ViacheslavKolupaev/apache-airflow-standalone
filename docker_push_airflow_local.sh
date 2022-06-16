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
# The script will push the `Apache Airflow Standalone` Docker image to the image registry.
#
# Not suitable for production environment. Use it for local development and testing only!
#
# If necessary, you need to replace the values of the variables in the `main()` function:
# - `docker_registry`;
# - `docker_user_name`;
# - `docker_image_name`;
# - `docker_image_tag`.
#
# Docker Hub: https://hub.docker.com/repository/docker/vkolupaev/apache-airflow-standalone
#
# The script uses the helper functions from the `common_bash_functions.sh` file.
##########################################################################################


#######################################
# Import bash libraries.
# Arguments:
#  None
#######################################
function import_bash_libraries() {
  # shellcheck source=./copy_file_from_remote_git_repo.sh
  if ! source ./copy_file_from_remote_git_repo.sh; then
    echo "'copy_file_from_remote_git_repo.sh' module was not imported due to some error. Exit."
    exit 1
  else
    copy_file_from_remote_git_repo \
      'git@gitlab.com:vkolupaev/notebook.git' \
      'main' \
      'common_bash_functions.sh'
  fi

  # shellcheck source=./common_bash_functions.sh
  if ! source ./common_bash_functions.sh; then
    echo "'common_bash_functions.sh' module was not imported due to some error. Exit."
    exit 1
  fi
}

#######################################
# Run the main function of the script.
# Arguments:
#  None
#######################################
function main() {
  # 1. Declaring Local Variables.
  local docker_registry
  readonly docker_registry='docker.io'

  local docker_user_name
  readonly docker_user_name='vkolupaev'

  local airflow_version
  readonly airflow_version="2.2.4"  # change if necessary

  local python_base_image
  readonly python_base_image="python3.8"  # change if necessary

  local docker_image_name
  readonly docker_image_name='apache-airflow-standalone'  # change if necessary

  local docker_image_tag
  docker_image_tag="${airflow_version}-${python_base_image}"  # don't change
  readonly docker_image_tag

  # 2. Import bash functions from other scripts.
  import_bash_libraries "$@"

  # 3. Execution of script logic.
  log_to_stdout 'START SCRIPT EXECUTION.' 'Bl'

  # Execute Docker operations.
  check_if_docker_is_running "$@"
  docker_login_to_registry \
    "${docker_registry}" \
    "${docker_user_name}"

  docker_push_image_to_registry \
    "${docker_registry}" \
    "${docker_user_name}" \
    "${docker_image_name}" \
    "${docker_image_tag}"

  log_to_stdout 'END OF SCRIPT EXECUTION.' 'Bl'
}

main "$@"
