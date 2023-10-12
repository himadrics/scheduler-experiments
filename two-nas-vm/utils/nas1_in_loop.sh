#!/bin/bash
# Usage example:
usage_example="./nas1_in_loop.sh nas1=mg.B.x nas2=mg.B.x cpuset=none threads=36 machine=gros-17"

for ARGUMENT in "$@"
do
	KEY=$(echo $ARGUMENT | cut -f1 -d=)
	VALUE=$(echo $ARGUMENT | cut -f2 -d=)

	case "$KEY" in
		nas1) 		nas1=${VALUE};;
		nas2) 		nas2=${VALUE};;
		cpuset) 	cpuset=${VALUE};;
		threads) 	threads=${VALUE};;
		machine) 	machine=${VALUE};;
		*)
	esac
done

if [[ -z ${nas1} || -z ${nas2} || -z ${cpuset} || -z ${threads} || -z ${machine} ]]
then
	echo "Error: Missing argument(s). Try again."
	echo "Info: Usage example: ${usage_example}"
	exit
fi

if ! [[ "${cpuset}" == "none" ]]
then
	pin="taskset -c ${cpuset}"
	pinning="on"
else
	pinning="off"
fi

rm /root/nas2_finished /root/nas1_finished
mkdir -p /root/nas_results/${nas1}-${nas2}

count=0
while true
do
	count=$((count + 1))

	echo "${machine}: nas1 started exp-${count} at `date +"%s.%N"`"
	OMP_NUM_THREADS=${threads} ${pin} /root/NPB3.4.2/NPB3.4-OMP/bin/${nas1} > /root/nas_results/${nas1}-${nas2}/output_nas1-${nas1}-${threads}_`uname -r`_performance_pinning-${pinning}_${machine}_exp-${count}.txt 
	echo "${machine}: nas1 ended exp-${count} at `date +"%s.%N"`"

	if [[ -f /root/nas2_finished &&  -f /root/nas1_finished ]]
	then
		break
	fi

	if [ "${count}" == 10 ]
	then
		echo "${machine}: nas1 finished ${count} runs"
		touch /root/nas1_finished
	fi
done

