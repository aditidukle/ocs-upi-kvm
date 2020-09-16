#!/bin/bash

# Increase the size of /sysroot of each worker node

set -e

source helper/parameters.sh

function change_vmstate () {
	vm="$1"
	action="$2"

	echo "Domain $vm requested action $action"

	once=false
	delay="10"

	if [ "$action" == "shutdown" ]; then
		expected_state="shut"		# shut off, but with awk $3 just shut
	else
		expected_state="running"
	fi

	cnt=0
	until [ $cnt -eq 6 ]
	do
		state=$(virsh list --all | grep "$vm" | tail -n 1 | awk '{print $3}')

		if [ "$state" == "$expected_state" ]; then
		        virsh list --all | grep "$vm" | tail -n 1
			return
		fi

		if [ "$once" == false ]; then
			virsh $action $vm | head -n 1
			once=true
		fi

		sleep $delay
	done
}

# Remember where files were created for virsh_cleanup.sh

echo "$IMAGES_PATH" > ~/.images_path

pushd $IMAGES_PATH/test-ocp$OCP_VERSION/

for (( i=0; i<$WORKERS; i++ ))
do
	vm=$(virsh list --all | grep worker-$i | awk '{print $2}')

	ip=$(/usr/local/bin/oc get nodes -o wide | grep worker-$i | tail -n 1 | awk '{print $6}')

	change_vmstate $vm shutdown

	if [ ! -e "$IMAGES_PATH/test-ocp$OCP_VERSION/$vm.orig" ]; then
		cp $IMAGES_PATH/test-ocp$OCP_VERSION/$vm $IMAGES_PATH/test-ocp$OCP_VERSION/$vm.orig
	fi

	echo "Domain $vm virtual boot disk (qcow2) will be resized to ${BOOT_DISK_SIZE}G"

	qemu-img resize $IMAGES_PATH/test-ocp$OCP_VERSION/$vm ${BOOT_DISK_SIZE}G

	change_vmstate $vm start

	success=false
	for ((cnt=0; cnt<6; cnt++))
	do
		sleep 20

		set +e
		xfs_output=$(ssh -o StrictHostKeyChecking=no core@$ip sudo xfs_growfs /)
		set -e

		if [[ "$xfs_output" =~ "meta-data=/dev/mapper/coreos-luks-root-nocrypt" ]]; then
			cnt=6
			success=true
			echo "Domain $vm root filesystem expanded to ${BOOT_DISK_SIZE}G"
		fi
	done

	if [ "$success" != true ]; then
		echo "ERROR: boot disk resize failed for VM $vm at $ip\.  May need to reboot it with original qcow2"
		echo "RECOVERY: Reboot VM or reboot VM with original qcow2"
	fi
done

popd
