#!/bin/bash
# Usage example:
usage_example="./launch_two_nas_vm_exp.sh cpuset1=none threads1=36 cpuset2=none threads2=36 vcpupin1=off vcpupin2=off"

for ARGUMENT in "$@"
do
	KEY=$(echo $ARGUMENT | cut -f1 -d=)
	VALUE=$(echo $ARGUMENT | cut -f2 -d=)

	case "$KEY" in
		cpuset1)            cpuset1=${VALUE};;
		cpuset2)            cpuset2=${VALUE};;
		vcpupin1)            vcpupin1=${VALUE};;
		vcpupin2)            vcpupin2=${VALUE};;
		threads1)            threads1=${VALUE};;
		threads2)            threads2=${VALUE};;
		*)
	esac
done

if [[ -z ${cpuset1} || -z ${cpuset2} || -z ${threads1} || -z ${threads2} || -z ${vcpupin1} || -z ${vcpupin2} ]]
then
	echo "Error: Missing argument(s). Try again."
	echo "Info: Usage example: ${usage_example}"
	exit
fi

if ! [[ ${cpuset1} == "none" ]]
then
	pinning1="on"
else
	pinning1="off"
fi
if ! [[ ${cpuset2} == "none" ]]
then
	pinning2="on"
else
	pinning2="off"
fi

machine=`echo ${HOSTNAME} | cut -d '.' -f1`
hkernel=`uname -r`

# Nas pair to machine mapping
case ${machine} in
	gros-17)
		nas1_list=( "mg.B.x" )
		nas2_list=( "mg.B.x" )
	;;
	*)
esac

# Use the performance power governor
/root/utils/set_power_governor.sh governor=performance

# Start trace-cmd in both the VMs for host-guest tracing
ssh vm1 trace-cmd agent -D
ssh vm2 trace-cmd agent -D

for i in "${!nas1_list[@]}"
do
	mkdir -p /root/nas_vm_results/${nas1_list[i]}-${nas2_list[i]}
	rm /root/vm1_finished /root/vm2_finished

	echo "Info: Running ${nas1_list[i]} in parallel with ${nas2_list[i]} on ${machine}"
	
	printf "#!/bin/bash\n/root/utils/run_two_nas_vm.sh cpuset1=${cpuset1} cpuset2=${cpuset2} vcpupin1=${vcpupin1} vcpupin2=${vcpupin2} threads1=${threads1} threads2=${threads2} nas1=${nas1_list[i]} nas2=${nas2_list[i]} machine=${machine} | tee /root/nas_vm_results/${nas1_list[i]}-${nas2_list[i]}/timestamps_vm1-vcpupinning-${vcpupin1}_${nas1_list[i]}-${threads1}-pinning-${pinning1}_vm2-vcpupinning-${vcpupin2}_${nas2_list[i]}-${threads2}-pinning-${pinning2}_${hkernel}_performance_${machine}_`date +%d-%m-%y_%H-%M-%S`" > /root/utils/exp.sh
	cat /root/dispel/utils/exp.sh
	
	trace-cmd record -e sched -v -e sched_stat_runtime -A @4:823 --name vm1 -e sched -v -e sched_stat_runtime -A @5:823 --name vm2 -e sched -v -e sched_stat_runtime /root/utils/exp.sh

	mv trace.dat /root/nas_vm_results/${nas1_list[i]}-${nas2_list[i]}/htrace_vm1-vcpupining-${vcpupin1}_${nas1_list[i]}-${threads1}-pinning-${pinning1}_vm2-vcpupining-${vcpupin2}_${nas2_list[i]}-${threads2}-pinning-${pinning2}_${hkernel}_performance_${machine}_`date +%d-%m-%y_%H-%M-%S`.dat
	mv trace-vm1.dat /root/nas_vm_results/${nas1_list[i]}-${nas2_list[i]}/g1trace_vm1-vcpupining-${vcpupin1}_${nas1_list[i]}-${threads1}-pinning-${pinning1}_vm2-vcpupining-${vcpupin2}_${nas2_list[i]}-${threads2}-pinning-${pinning2}_${hkernel}_performance_${machine}_`date +%d-%m-%y_%H-%M-%S`.dat
	mv trace-vm2.dat /root/nas_vm_results/${nas1_list[i]}-${nas2_list[i]}/g2trace_vm1-vcpupining-${vcpupin1}_${nas1_list[i]}-${threads1}-pinning-${pinning1}_vm2-vcpupining-${vcpupin2}_${nas2_list[i]}-${threads2}-pinning-${pinning2}_${hkernel}_performance_${machine}_`date +%d-%m-%y_%H-%M-%S`.dat

	cp -r /root/nas_vm_results/${nas1_list[i]}-${nas2_list[i]}/ ~/nfs-shared-storage/two-nas/nas_vm_results/
done
