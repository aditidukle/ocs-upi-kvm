#!/bin/bash

# Run named ocs-ci tier test on previously created OCP cluster

# TODO: Add support for individual test runs -- a specific test in a tier

arg1=$1
if [ -z "$arg1" ]; then
	tests=(0 1)
else
	if [[ "$arg1" == "--tier" ]]; then
		tests=$2
		if [ -z "$tests" ]; then
			echo "Usage: test-ocs-ci.sh [--tier 0,1,2,3,4,4a,4b,4c ]"
			exit 1
		fi
		tests=($(echo $tests | sed 's/,/ /g'))
		for i in ${tests[@]}
		do
			if [[ ! "0 1 2 3 4 4a 4b 4c" =~ "$i" ]]; then
				echo "ERROR: $0 invalid test tier: $i"
				exit 1
			fi
		done
	else
		echo "Usage: test-ocs-ci.sh [--tier 0,1,2,3,4,4a,4b,4c ]"
		exit 1
	fi
fi

if [ ! -e helper/parameters.sh ]; then
	echo "This script should be invoked from the directory ocs-upi-kvm/scripts"
	exit 1
fi

source helper/parameters.sh

export KUBECONFIG=$WORKSPACE/auth/kubeconfig

pushd ../src/ocs-ci

source $WORKSPACE/venv/bin/activate		# enter 'deactivate' in venv shell to exit

# Create supplemental config if it doesn't exist.  User may edit file after ocs deploy

if [ ! -e $WORKSPACE/ocs-ci-conf.yaml ]; then
        cp ../../files/ocs-ci-conf.yaml $WORKSPACE/ocs-ci-conf.yaml
        export LOGDIR=$WORKSPACE/logs-ocs-ci/$OCP_VERSION
        mkdir -p $LOGDIR
        yq -y -i '.RUN.log_dir |= env.LOGDIR' $WORKSPACE/ocs-ci-conf.yaml
fi

for i in ${tests[@]}
do
	echo "========================================================================================="
	echo "============================= run-ci -m \"tier$i and manage\" ============================="
	echo "========================================================================================="

	time run-ci -m "tier$i and manage" --cluster-name ocstest \
		--ocsci-conf conf/ocsci/production_powervs_upi.yaml \
		--ocsci-conf $WORKSPACE/ocs-ci-conf.yaml \
	        --cluster-path $WORKSPACE --collect-logs tests/
	rc=$?
	echo "TEST RESULT: run-ci tier$i rc=$rc" 
done

deactivate

popd
