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
# The script provides common bash functions.
#
# To use it, import it into your script with the `source` command.
##########################################################################################


#######################################
# Print message to stdout with date and time, calling file and function names.
# Globals:
#   FUNCNAME
#   BASH_SOURCE
#   BASH_LINENO
# Arguments:
#  text_message
#  text_color
#######################################
function log_to_stdout() {
  # 1. Declaring Local Variables.

  # Date and time of the log message.
  local timestamp
  timestamp="$(date +'%Y-%m-%dT%H:%M:%S%z')"
  readonly timestamp

  # The name and line of code of the calling script.
  local caller_filename_lineno
  caller_filename_lineno="${BASH_SOURCE[1]##*/}:${BASH_LINENO[0]}"
  readonly caller_filename_lineno

  # The name of the function that called this function.
  local caller_func_name
  # Checking if the function was called from this or an external script.
  if [ -z "${FUNCNAME[1]}" ] ; then
    # In case the call is made from this script.
    caller_func_name="${FUNCNAME[0]}"
  else
    # If the call is made from an external script.
    caller_func_name="${FUNCNAME[1]}"
  fi
  readonly caller_func_name

  # Variables for the allowed text color of the log message.
  local fg_black
  local fg_red
  local fg_green
  local fg_yellow
  local fg_blue
  local fg_magenta
  local fg_cyan
  local fg_white

  # Foreground colors.
  fg_black=$(tput setaf 0)
  fg_red=$(tput setaf 1)
  fg_green=$(tput setaf 2)
  fg_yellow=$(tput setaf 3)
  fg_blue=$(tput setaf 4)
  fg_magenta=$(tput setaf 5)
  fg_cyan=$(tput setaf 6)
  fg_white=$(tput setaf 7)

  readonly fg_black
  readonly fg_red
  readonly fg_green
  readonly fg_yellow
  readonly fg_blue
  readonly fg_magenta
  readonly fg_cyan
  readonly fg_white

  local text_color  # This variable will be assigned the value of the function argument after it has been validated.

  # 2. Checking function arguments.
  if [ -z "$1" ] ; then
    log_to_stderr "Argument 'text_message' was not specified in the function call. Exit."
    exit 1
  else
    local text_message
    text_message=$1
    readonly text_message
  fi

  if [ -n "$2" ] ; then
    # Checking the value of the argument and assigning the value to the `text_color` variable.
    case "$2" in
      BL)
        text_color=${fg_black}
        ;;
      R)
        text_color=${fg_red}
        ;;
      G)
        text_color=${fg_green}
        ;;
      Y)
        text_color=${fg_yellow}
        ;;
      Bl)
        text_color=${fg_blue}
        ;;
      M)
        text_color=${fg_magenta}
        ;;
      C)
        text_color=${fg_cyan}
        ;;
      W)
        text_color=${fg_white}
        ;;
      *)
        text_color='\033[0m'  # No color if the argument value is invalid.
        ;;
    esac
  else
    text_color='\033[0m'  # No color if no argument is provided in the function call.
  fi

  readonly text_color

  # 3. Print a formatted text message.
  printf "${text_color}| %s | %s | %s | %s\n" \
    >&1 `# stdout` \
    "${timestamp}" \
    "${caller_filename_lineno}" \
    "${caller_func_name}" \
    "${text_message}"
}

#######################################
# Print message to stderr with date and time, calling file and function names.
# Globals:
#   FUNCNAME
#   BASH_SOURCE
#   BASH_LINENO
# Arguments:
#  text_message
#######################################
function log_to_stderr() {
  # 1. Declaring Local Variables.

  # Date and time of the log message.
  local timestamp
  timestamp="$(date +'%Y-%m-%dT%H:%M:%S%z')"
  readonly timestamp

  # The name and line of code of the calling script.
  local caller_filename_lineno
  caller_filename_lineno="${BASH_SOURCE[1]##*/}:${BASH_LINENO[0]}"
  readonly caller_filename_lineno

  # The name of the function that called this function.
  local caller_func_name
  # Checking if the function was called from this or an external script.
  if [ -z "${FUNCNAME[1]}" ] ; then
    # In case the call is made from this script.
    caller_func_name="${FUNCNAME[0]}"
  else
    # If the call is made from an external script.
    caller_func_name="${FUNCNAME[1]}"
  fi
  readonly caller_func_name

  # Text color variable.
  local text_color
  text_color=$(tput setaf 1)  # Red.
  readonly text_color

  # 2. Checking function arguments.
  local text_message
  if [ -z "$1" ] ; then
    text_message="Argument 'text_message' was not specified in the function call. Exit."
    printf "${text_color}| %s | %s | %s | %s\n" \
      >&2 `# stderr` \
      "${timestamp}" \
      "${caller_filename_lineno}" \
      "${caller_func_name}" \
      "${text_message}"
    exit 1
  else
    text_message=$1
    readonly text_message
  fi

  # 3. Print a formatted text message.
  printf "${text_color}| %s | %s | %s | %s\n" \
    >&2 `# stderr` \
    "${timestamp}" \
    "${caller_filename_lineno}" \
    "${caller_func_name}" \
    "${text_message}"
}

#######################################
# Check if Docker is running on the host.
# Arguments:
#  None
#######################################
function check_if_docker_is_running() {
  echo ''
  log_to_stdout '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' 'Bl'
  log_to_stdout 'Checking if Docker is running before executing Docker operations...'

  if (! docker stats --no-stream 2>/dev/null); then
    log_to_stderr 'Docker is not working. For the further work of the script, a working Docker is required. Exit.'
    exit 1
  else
    log_to_stdout 'Docker is working. Continue.' 'G'
    log_to_stdout '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<' 'Bl'
  fi
}

#######################################
# Stop the Docker container.
# Arguments:
#   container_id_or_name
#######################################
function docker_container_stop() {
  echo ''

  # Checking function arguments.
  if [ -z "$1" ] ; then
    log_to_stderr "Argument 'container_id_or_name' was not specified in the function call. Exit."
    exit 1
  else
    local container_id_or_name
    container_id_or_name=$1
    readonly container_id_or_name
    log_to_stdout "Argument 'container_id_or_name' = ${container_id_or_name}"
  fi

  log_to_stdout "Stopping the '${container_id_or_name}' container..."
  if ! docker stop "${container_id_or_name}"; then
    log_to_stderr "Error stopping container '${container_id_or_name}'. Exit."
    exit 1
  else
    log_to_stdout "Container '${container_id_or_name}' stopped successfully. Continue." 'G'
  fi
}

#######################################
# Remove the Docker container.
# Arguments:
#   container_id_or_name
#######################################
function docker_container_remove() {
  echo ''

  # Checking function arguments.
  if [ -z "$1" ] ; then
    log_to_stderr "Argument 'container_id_or_name' was not specified in the function call. Exit."
    exit 1
  else
    local container_id_or_name
    container_id_or_name=$1
    readonly container_id_or_name
    log_to_stdout "Argument 'container_id_or_name' = ${container_id_or_name}"
  fi

  log_to_stdout "Removing the '${container_id_or_name}' container..."
  if ! docker rm "${container_id_or_name}"; then
    log_to_stderr "Error removing container '${container_id_or_name}'. Exit."
    exit 1
  else
    log_to_stdout "Container '${container_id_or_name}' removed successfully. Continue." 'G'
  fi
}

#######################################
# Remove the Docker image.
# Arguments:
#   image_id_or_name
#######################################
function docker_image_remove() {
  echo ''

  # Checking function arguments.
  if [ -z "$1" ] ; then
    log_to_stderr "Argument 'image_id_or_name' was not specified in the function call. Exit."
    exit 1
  else
    local image_id_or_name
    image_id_or_name=$1
    readonly image_id_or_name
    log_to_stdout "Argument 'image_id_or_name' = ${image_id_or_name}"
  fi

  log_to_stdout "Removing the '${image_id_or_name}' image..."
  if ! docker rmi --force "${image_id_or_name}"; then
    log_to_stderr "Error removing image '${image_id_or_name}'. Exit."
    exit 1
  else
    log_to_stdout "Image '${image_id_or_name}' removed successfully. Continue." 'G'
  fi
}

#######################################
# Remove the Docker image by <name>:<tag>.
# Arguments:
#   docker_image_name
#   docker_image_tag
#######################################
function docker_image_remove_by_name_tag() {
  echo ''
  log_to_stdout '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' 'Bl'
  log_to_stdout 'Removing Docker image by <name>:<tag>...'

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

  # Removing an image by <name>:<tag>.
  if [ "$(docker images -q "${docker_image_name}:${docker_image_tag}")" ]; then
    log_to_stdout "Docker image '${docker_image_name}:${docker_image_tag}' already exists."
    docker_image_remove "${docker_image_name}:${docker_image_tag}"
  else
    log_to_stdout "Docker image '${docker_image_name}:${docker_image_tag}' not found. Continue." 'G'
  fi

  log_to_stdout '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<' 'Bl'
}

#######################################
# Login to the specified Docker image registry.
# Arguments:
#   docker_registry
#   docker_user_name
#######################################
function docker_login_to_registry() {
  echo ''
  log_to_stdout 'Login to Docker image registry...'
  log_to_stdout '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' 'Bl'

  # Checking function arguments.
  if [ -z "$1" ] ; then
    log_to_stderr "Argument 'docker_registry' was not specified in the function call. Exit."
    exit 1
  else
    local docker_registry
    docker_registry=$1
    readonly docker_registry
    log_to_stdout "Argument 'docker_registry' = ${docker_registry}"
  fi

  if [ -z "$2" ] ; then
    log_to_stderr "Argument 'docker_user_name' was not specified in the function call. Exit."
    exit 1
  else
    local docker_user_name
    docker_user_name=$2
    readonly docker_user_name
    log_to_stdout "Argument 'docker_user_name' = ${docker_user_name}"
  fi

  log_to_stdout 'Use your personal or technical account with registry access privileges.' 'C'
  if ! docker login -u "${docker_user_name}" "${docker_registry}/${docker_user_name}"; then
    log_to_stderr 'Login failed. Exit'
    exit 1
  else
    log_to_stdout 'Login succeeded. Continue.' 'G'
  fi

  log_to_stdout '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<' 'Bl'
}

#######################################
# Push the image to the private Docker image registry.
# Arguments:
#   docker_registry
#   docker_user_name
#   docker_image_name
#   docker_image_tag
#######################################
function docker_push_image_to_registry() {
  echo ''
  log_to_stdout 'Tagging and pushing a Docker image to a private registry...'
  log_to_stdout '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' 'Bl'

  # Checking function arguments.
  if [ -z "$1" ] ; then
    log_to_stderr "Argument 'docker_registry' was not specified in the function call. Exit."
    exit 1
  else
    local docker_registry
    docker_registry=$1
    readonly docker_registry
    log_to_stdout "Argument 'docker_registry' = ${docker_registry}"
  fi

  if [ -z "$2" ] ; then
    log_to_stderr "Argument 'docker_user_name' was not specified in the function call. Exit."
    exit 1
  else
    local docker_user_name
    docker_user_name=$2
    readonly docker_user_name
    log_to_stdout "Argument 'docker_user_name' = ${docker_user_name}"
  fi

  if [ -z "$3" ] ; then
    log_to_stderr "Argument 'docker_image_name' was not specified in the function call. Exit."
    exit 1
  else
    local docker_image_name
    docker_image_name=$3
    readonly docker_image_name
    log_to_stdout "Argument 'docker_image_name' = ${docker_image_name}"
  fi

  if [ -z "$4" ] ; then
    log_to_stderr "Argument 'docker_image_tag' was not specified in the function call. Exit."
    exit 1
  else
    local docker_image_tag
    docker_image_tag=$4
    readonly docker_image_tag
    log_to_stdout "Argument 'docker_image_tag' = ${docker_image_tag}"
  fi

  # Tag an image for a private registry.
  log_to_stdout 'Image tagging...'
  # Usage: `docker tag local-image:tagname remote-repo:tagname`.
  if ! docker tag \
       "${docker_image_name}:${docker_image_tag}" \
       "${docker_registry}/${docker_user_name}/${docker_image_name}:${docker_image_tag}"; then
    log_to_stderr 'Tagging failed. Exit.'
    exit 1
  else
    log_to_stdout 'Tagging succeeded. Continue.' 'G'
  fi

  # Push image to private registry.
  log_to_stdout 'Image pushing...'
  # Usage: `docker push remote-repo:tagname`.
  if ! docker push \
      "${docker_registry}/${docker_user_name}/${docker_image_name}:${docker_image_tag}"; then
    log_to_stderr 'Pushing failed. Exit.'
    exit 1
  else
    log_to_stdout 'Pushing succeeded. Continue.' 'G'
  fi

  log_to_stdout '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<' 'Bl'
}

#######################################
# Stop and remove containers with a name equal to the image name.
# Arguments:
#  docker_image_name
#######################################
function docker_stop_and_remove_containers_by_name() {
  echo ''
  log_to_stdout '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' 'Bl'
  log_to_stdout 'Stopping and removing containers with a name equal to the image name...'

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

  # Get a list of containers with a name equal to the name of the image.
  local container_ids
  container_ids="$(docker ps -aq -f "name=${docker_image_name}")"

  # Stop and remove containers.
  if [[ -n "${container_ids}" ]]; then
    log_to_stdout "Found containers named '${docker_image_name}': ${container_ids}."

    local container_id
    for container_id in "${container_ids[@]}"; do
      docker_container_stop "${container_id}"
      if [ "$(docker ps -aq -f status=exited -f id="${container_id}")" ]; then
        docker_container_remove "${container_id}"
      fi
    done
  else
    log_to_stdout "There are no containers named '${docker_image_name}'. Continue." 'G'
  fi

  log_to_stdout '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<' 'Bl'
}

#######################################
# Stop and remove containers by ancestor (created from the <name>:<tag>).
# Arguments:
#  docker_image_name
#  docker_image_tag
#######################################
function docker_stop_and_remove_containers_by_ancestor() {
  echo ''
  log_to_stdout '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' 'Bl'
  log_to_stdout 'Stopping and removing containers created from the <name>:<tag>...'

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

  # Get a list of containers created based on the specified image.
  local container_ids
  container_ids="$(docker ps -aq -f "ancestor=${docker_image_name}:${docker_image_tag}")"

  # Stop and remove containers.
  if [[ -n "${container_ids}" ]]; then
    log_to_stdout "Containers created from '${docker_image_name}:${docker_image_tag}' image found: ${container_ids}."

    local container_id
    for container_id in "${container_ids[@]}"; do
      docker_container_stop "${container_id}"
      if [ "$(docker ps -aq -f status=exited -f id="${container_id}")" ]; then
        docker_container_remove "${container_id}"
      fi
    done
  else
    log_to_stdout "There are no containers running from the '${docker_image_name}:${docker_image_tag}'. Continue." 'G'
  fi

  log_to_stdout '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<' 'Bl'
}

#######################################
# Create user-defined bridge network with name '<docker_image_name>-net'.
# Arguments:
#   docker_image_name
#######################################
function docker_create_user_defined_bridge_network() {
  echo ''
  log_to_stdout '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' 'Bl'
  log_to_stdout 'Creating user-defined bridge network...'

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

  # Checking if such a network already exists.
  if [ "$(docker network ls -q -f "name=${docker_image_name}-net")" ]; then
    log_to_stdout "Docker network '${docker_image_name}-net' already exists. Continue." 'G'
  else
    # Creation of a Docker network.
    if ! docker network create --driver bridge "${docker_image_name}"-net; then
      log_to_stderr 'Error creating user-defined bridge network. Exit.'
      exit 1
    else
      log_to_stdout "The user-defined bridge network '${docker_image_name}-net' has been created. Continue." 'G'
    fi
  fi

  log_to_stdout '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<' 'Bl'
}

#######################################
# Synchronize the project's virtual environment with the specified requirements files.
# Arguments:
#   req_compiled_file_full_path: Required. The full path to the compiled dependency file, with which to sync.
#   project_root: Optional. If specified, will additionally sync with `01_app_requirements.txt`.
#######################################
function sync_venv_with_specified_requirements_files() {
  echo ''
  log_to_stdout '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' 'Bl'
  log_to_stdout "Synchronizing the project's virtual environment with the specified requirements files..."

  # Checking function arguments.
  if [ -z "$1" ] ; then
    log_to_stderr "Argument 'req_compiled_file_full_path' was not specified in the function call. Exit."
    exit 1
  else
    local req_compiled_file_full_path
    req_compiled_file_full_path=$1
    readonly req_compiled_file_full_path
    log_to_stdout "Argument requirements file 1 = ${req_compiled_file_full_path}"
  fi

  if [ -n "$2" ] ; then
    local project_root
    project_root=$2
    readonly project_root
    log_to_stdout "Argument requirements file 2 = ${project_root}/requirements/compiled/01_app_requirements.txt"

    if ! pip-sync \
        "${project_root}/requirements/compiled/01_app_requirements.txt" \
        "${req_compiled_file_full_path}"; then
      log_to_stderr 'Virtual environment synchronization error. Exit.'
      exit 1
    fi

  else

    if ! pip-sync "${req_compiled_file_full_path}"; then
      log_to_stderr 'Virtual environment synchronization error. Exit.'
      exit 1
    fi

  fi

  log_to_stdout "The project virtual environment was successfully synchronized with the specified requirements files."
  log_to_stdout '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<' 'Bl'
}

#######################################
# Activate the project's virtual environment.
# Globals:
#   PWD
# Arguments:
#   venv_scripts_dir_full_path: Full path to the virtual environment scripts directory (depends on OS type).
#######################################
function activate_virtual_environment() {
  echo ''
  log_to_stdout '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' 'Bl'
  log_to_stdout "Activating the project's virtual environment..."

  # Checking function arguments.
  if [ -z "$1" ] ; then
    log_to_stderr "Argument 'venv_scripts_dir_full_path' was not specified in the function call. Exit."
    exit 1
  else
    local venv_scripts_dir_full_path
    venv_scripts_dir_full_path=$1
    readonly venv_scripts_dir_full_path
    log_to_stdout "Argument 'venv_scripts_dir_full_path' = ${venv_scripts_dir_full_path}"
  fi

  # Change to the directory with venv scripts.
  cd "${venv_scripts_dir_full_path}" || exit 1
  log_to_stdout "Current PWD: '${PWD}'."

  # venv activation.
  if ! source activate; then
    log_to_stderr 'Virtual environment activation error. Exit.'
    exit 1
  else
    log_to_stdout 'Virtual environment successfully activated. Continue.' 'G'
    log_to_stdout '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<' 'Bl'
  fi
}

#######################################
# Copy a file from the specified branch of the remote Git repo to the script directory.
# Globals:
#   PWD
# Arguments:
#  remote_git_repo
#  branch_name
#  path_to_file
#######################################
function copy_file_from_remote_git_repo() {
  echo ''
  log_to_stdout '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' 'Bl'
  log_to_stdout 'Paths to the file in the target directory are preserved during copying.' 'C'

  # Checking function arguments.
  if [ -z "$1" ] ; then
    log_to_stderr "Argument 'remote_git_repo' was not specified in the function call. Exit."
    exit 1
  else
    local remote_git_repo
    remote_git_repo=$1
    readonly remote_git_repo
    log_to_stdout "Argument 'remote_git_repo' = ${remote_git_repo}"
  fi

  if [ -z "$2" ] ; then
    log_to_stderr "Argument 'branch_name' was not specified in the function call. Exit."
    exit 1
  else
    local branch_name
    branch_name=$2
    readonly branch_name
    log_to_stdout "Argument 'branch_name' = ${branch_name}"
  fi

  if [ -z "$3" ] ; then
    log_to_stderr "Argument 'path_to_file' was not specified in the function call. Exit."
    exit 1
  else
    local path_to_file
    path_to_file=$3
    readonly path_to_file
    log_to_stdout "Argument 'path_to_file' = ${path_to_file}"
  fi

  # Copying.
  log_to_stdout "Copying '${path_to_file}' file from remote Git repository '${remote_git_repo}'..."
  if ! git archive \
      --remote="${remote_git_repo}" \
      --verbose \
      "${branch_name}" \
      "${path_to_file}" | tar -x; then
    log_to_stderr "Error copying '${path_to_file}' from '${remote_git_repo}'. Contact the maintainer. Exit."
    exit 1
  else
    log_to_stdout "'${path_to_file}' file successfully copied from '${remote_git_repo}'." 'G'
    log_to_stdout "Current PWD: '${PWD}'."
  fi

  log_to_stdout '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<' 'Bl'
}
