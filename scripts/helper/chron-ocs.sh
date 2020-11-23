#!/bin/bash
## =============================================================================================
## IBM Confidential
## © Copyright IBM Corp. 2020
## The source code for this program is not published or otherwise divested of its trade secrets,
## irrespective of what has been deposited with the U.S. Copyright Office.
## =============================================================================================
##
#Copy Right IBM

VERSION="202010191400";

# Check if another instance of the same script is running, if so quit.

CHRONOCS="test-chron-ocs"
if pgrep "$CHRONOCS" >/dev/null
then
    echo "$CHRONOCS is running. Wait for it to complete before starting again."
    exit 1
else
    echo "$CHRONOCS stopped"
fi

if [ "$( whoami )" == "root" ]; then
    echo "This is the root account which is not allowed for this chron job" 
    exit 1
fi

if [[ ! -e ~/auth.yaml ]] || [[ ! -e ~/pull-secret.txt ]] || [[ ! -e ~/test-chron-ocs.sh ]]; then
    echo "At least one required file is missing: auth.yaml, pull-secret.txt, test-chron-ocs.sh"    
    exit 1
fi

echo "Preparing environment"

export LOGDIR=~/logs
export LOGDATE=$(date "+%d%H%M")

mkdir -p $LOGDIR

echo "Cloning project ocs-upi-kvm..."

rm -rf ocs-upi-kvm
git clone https://github.com/ocp-power-automation/ocs-upi-kvm

echo "Run ocs-ci tier tests in the background...  Log files in $LOGDIR"

./test-chron-ocs.sh --latest-ocs
