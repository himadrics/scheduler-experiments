#!/bin/bash
usage_example="./run_two_nas_vm.sh nas1=mg.B.x nas2=mg.B.x cpuset1=none cpuset2=none threads1=36 threads2=36 machine=gros-17 vcpupin1=off vcpupin2=off"

for ARGUMENT in "$@"
do
	KEY=$(echo $ARGUMENT | cut -f1 -d=)
	VALUE=$(echo $ARGUMENT | cut -f2 -d=)

	case "$KEY" in
		nas1)            nas1=${VALUE};;
		nas2)            nas2=${VALUE};;
		cpuset1)            cpuset1=${VALUE};;
		cpuset2)            cpuset2=${VALUE};;
		threads1)            threads1=${VALUE};;
		threads2)            threads2=${VALUE};;
		machine)            machine=${VALUE};;
		vcpupin1)            vcpupin1=${VALUE};;
		vcpupin2)            vcpupin2=${VALUE};;
		*)
	esac
done

if [[ -z ${nas1} || -z ${nas2} || -z ${cpuset1} || -z ${cpuset2} || -z ${threads1} || -z ${threads2} || -z ${machine} || -z ${vcpupin1} || -z ${vcpupin2} ]]
then
	echo "Error: Missing argument(s). Try again."
	echo "Info: Usage example: ${usage_example}"
	exit
fi

ssh vm1 /root/utils/nas1_in_loop.sh nas1=${nas1} nas2=${nas2} cpuset=${cpuset1} threads=${threads1} machine=${machine} &
echo "ssh vm1 /root/utils/nas1_in_loop.sh nas1=${nas1} nas2=${nas2} cpuset=${cpuset1} threads=${threads1} machine=${machine} &"

ssh vm2 /root/utils/nas2_in_loop.sh nas1=${nas1} nas2=${nas2} cpuset=${cpuset2} threads=${threads2} machine=${machine} &
echo "ssh vm2 /root/utils/nas2_in_loop.sh nas1=${nas1} nas2=${nas2} cpuset=${cpuset2} threads=${threads2} machine=${machine} &"

while true
do
	if ssh vm1 "test -e /root/nas1_finished"
	then
		ssh vm2 "echo stop > /root/nas1_finished"
		echo stop > /root/vm1_finished
	fi
	
	if ssh vm2 "test -e /root/nas2_finished" 
	then
		ssh vm1 "echo stop > /root/nas2_finished"
		echo stop > /root/vm2_finished
	fi

	if [[ -f /root/vm1_finished && -f /root/vm2_finished ]]
	then
		break
	fi

	sleep 1
done

wait

ssh vm1 "rm /root/nas1_finished; rm /root/nas2_finished"
ssh vm2 "rm /root/nas2_finished; rm /root/nas1_finished"
