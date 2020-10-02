#!/bin/bash

if [ ! -e helper/parameters.sh ]; then
	echo "This script should be invoked from the directory ocs-upi-kvm/scripts"
	exit 1
fi

source helper/parameters.sh

if [ ! -e $WORKSPACE/pull-secret.txt ]; then
	echo "Missing $WORKSPACE/pull-secret.txt.  Download it from https://cloud.redhat.com/openshift/install/pull-secret"
	exit 1
fi

if [ ! -e $WORKSPACE/auth.yaml ]; then
	echo "$WORKSPACE/auth.yaml is required"
	exit 1
fi

set -e

export KUBECONFIG=$WORKSPACE/auth/kubeconfig

pushd ../src/ocs-ci

mkdir -p data

cp $WORKSPACE/auth.yaml data/auth.yaml
cp $WORKSPACE/pull-secret.txt data/pull-secret

source $WORKSPACE/venv/bin/activate                  # enter 'deactivate' in venv shell to exit

run-ci -m deployment --deploy --ocsci-conf=conf/ocsci/production_powervs_upi.yaml --ocs-version 4.6 \
       --cluster-name=ocstest --cluster-path=$WORKSPACE --collect-logs

deactivate

popd
