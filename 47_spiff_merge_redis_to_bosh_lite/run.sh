#!/bin/bash

stub=$1; shift
stage=$1; shift
set -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export ATC_URL=${ATC_URL:-"http://192.168.100.4:8080"}
echo "Tutorial $(basename $DIR)"
echo "Concourse API $ATC_URL"

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

usage() {
  echo "USAGE: run.sh credentials.yml [build-task-image|bosh-deploy]"
  exit 1
}

if [[ "${stub}X" == "X" ]]; then
  usage
fi
stub=$(realpath $stub)
if [[ ! -f ${stub} ]]; then
  usage
fi

if [[ "${stage}" != "build-task-image" && "${stage}" != "bosh-deploy" ]]; then
  usage
fi


pushd $DIR
  yes y | fly configure -c pipeline-${stage}.yml --vars-from ${stub}
  if [[ "${stage}" == "build-task-image" ]]; then
    curl $ATC_URL/jobs/job-build-task-image/builds -X POST
    fly watch -j job-build-task-image
  else
    curl $ATC_URL/jobs/job-deploy/builds -X POST
    fly watch -j job-deploy
  fi
popd