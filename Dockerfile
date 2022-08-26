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
# Dockerfile to build standalone Apache Airflow Docker image.
#
# Not suitable for production environment. Use it for local development and testing only!
#
# Docs: https://docs.docker.com/engine/reference/builder/
##########################################################################################

# Dockerfile syntax definition. Required to mount package manager cache directories.
# See Dockerfile syntax tags here: https://hub.docker.com/r/docker/dockerfile
# syntax=docker/dockerfile:1

##########################################################################################
# STAGE 1: BUILD
##########################################################################################

# Pull official base image.
# See available Apache Airflow tags here: https://hub.docker.com/r/apache/airflow/tags
ARG AIRFLOW_VERSION
ARG PYTHON_BASE_IMAGE

# The final image, will appear as `image_name:image_tag` (`docker build -t` option)
FROM apache/airflow:${AIRFLOW_VERSION}-${PYTHON_BASE_IMAGE} AS build-image

# Setting the git revision short SHA.
ARG VCS_REF
ENV VCS_REF=${VCS_REF}

# Adding labels.
LABEL author="Viacheslav Kolupaev"
LABEL stage=build-image
LABEL vcs_ref=${VCS_REF}

USER root

# Installing some auxiliary utilities, including those for working with Apache Spark.
# Docs: https://manpages.ubuntu.com/manpages/focal/en/man8/apt-get.8.html
#RUN --mount=type=cache,mode=0755,target=/var/cache/apt \
#  apt-get update \
#  && apt-get install -y --no-install-recommends \
#    iputils-ping \
#    net-tools \
#    less \
#    telnet \
#    nvim\
#    mc \
#    openjdk-11-jre-headless \
#  && apt-get autoremove -yqq --purge \
#  && apt-get clean \
#  && rm -rf /var/lib/apt/lists/*

#USER airflow

# For `apache-spark` to work.
#ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Prevents Python from writing pyc files to disk.
ENV PYTHONDONTWRITEBYTECODE 1
# Prevents Python from buffering stdout and stderr.
ENV PYTHONUNBUFFERED 1

# `pip` configuration befor installing dependencies.
COPY pip.conf pip.conf
ENV PIP_CONFIG_FILE pip.conf

# Install Python dependencies.
COPY ./requirements.txt .
# Docs: https://docs.docker.com/engine/reference/builder/#run---mounttypecache
RUN --mount=type=cache,mode=0755,target=/root/.cache/pip/ \
    pip install --upgrade pip \
    && pip install -r requirements.txt
