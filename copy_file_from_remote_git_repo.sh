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

#######################################
# Copy a file from the specified branch of the remote Git repo to the script directory.
#
# Paths to the file in the target directory are preserved during copying.
#
# Usage example:
#  # shellcheck source=./copy_file_from_remote_git_repo.sh
#  if ! source ./copy_file_from_remote_git_repo.sh; then
#    echo "'copy_file_from_remote_git_repo.sh' module was not imported due to some error. Exit."
#    exit 1
#  else
#    copy_file_from_remote_git_repo \
#      'git@gitlab.com:vkolupaev/notebook.git' \
#      'main' \
#      'common_bash_functions.sh'
#  fi
#
# Globals:
#   FUNCNAME
#   PWD
# Arguments:
#  remote_git_repo
#  branch_name
#  path_to_file
#######################################
function copy_file_from_remote_git_repo() {
  echo ''
  echo "| ${FUNCNAME[0]} | >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

  # Checking function arguments.
  if [ -z "$1" ] ; then
    echo "| ${FUNCNAME[0]} | Argument 'remote_git_repo' was not specified in the function call. Exit."
    exit 1
  else
    local remote_git_repo
    remote_git_repo=$1
    readonly remote_git_repo
    echo "| ${FUNCNAME[0]} | Argument 'remote_git_repo' = ${remote_git_repo}"
  fi

  if [ -z "$2" ] ; then
    echo "| ${FUNCNAME[0]} | Argument 'branch_name' was not specified in the function call. Exit."
    exit 1
  else
    local branch_name
    branch_name=$2
    readonly branch_name
    echo "| ${FUNCNAME[0]} | Argument 'branch_name' = ${branch_name}"
  fi

  if [ -z "$3" ] ; then
    echo "| ${FUNCNAME[0]} | Argument 'path_to_file' was not specified in the function call. Exit."
    exit 1
  else
    local path_to_file
    path_to_file=$3
    readonly path_to_file
    echo "| ${FUNCNAME[0]} | Argument 'path_to_file' = ${path_to_file}"
  fi

  # Copying.
  echo "| ${FUNCNAME[0]} | Copying '${path_to_file}' file from remote Git repository '${remote_git_repo}'..."
  if ! git archive \
      --remote=${remote_git_repo} \
      --verbose \
      "${branch_name}" \
      "${path_to_file}" | tar -x; then
    echo "| ${FUNCNAME[0]} | Error copying '${path_to_file}' from '${remote_git_repo}'. Contact the maintainer. Exit."
    exit 1
  else
    echo "| ${FUNCNAME[0]} | '${path_to_file}' file successfully copied from '${remote_git_repo}'."
    echo "| ${FUNCNAME[0]} | Current PWD: '${PWD}'."
  fi

  echo "| ${FUNCNAME[0]} | <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
}
