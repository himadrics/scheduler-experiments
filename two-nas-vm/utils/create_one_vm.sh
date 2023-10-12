#!/bin/bash
# Usage example:
usage_example="./create_one_vm.sh vmno=1 vcpus=36 ht=on pinning=off cpuset=none gkernel=6.1.36"

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
	    vmno)       vmno=${VALUE} ;;
	    vcpus)       vcpus=${VALUE} ;;
	    ht)		 ht=${VALUE} ;;
	    pinning)	pinning=${VALUE} ;;
	    cpuset)	cpuset=${VALUE} ;;
	    gkernel)    gkernel=${VALUE} ;;
            *)
    esac
done

# Check for the correct usage
if [[ -z ${vmno} || -z ${vcpus} || -z ${ht} || -z ${pinning} || -z ${cpuset} ]]
then
	echo "Error: Missing argument(s). Try again."
	echo "Info: Usage example: ${usage_example}"
	exit
fi

# Default guest kernel is 6.1.36
if [[ -z ${gkernel} ]]
then
	gkernel="6.1.36"
fi

# Copy the vdisk
if [ ! -f /root/vdisk$vmno.qcow2 ]
then
	echo "Info: Copying vdisk${vmno} from the shared storage to the node. This may take some time..."
	cp ~/nfs-shared-storage/vdisk-gros.qcow2 /root/vdisk${vmno}.qcow2	
fi

# Arguments for the qemu command
# No. of cores (c), No. of threads (t)
if [[ "${ht}" == "on" ]]
then
	c=$((vcpus/2))
	t=2
else
	c=${vcpus}
	t=1
fi

# Use taskset to pin all vCPUs of the VM to a set of pCPUs
if [[ "${pinning}" == "on" ]]
then
	pinto="taskset -c ${cpuset}"
fi

# Setup distinct port, cid and name
if [[ "${vmno}" == 1 ]]
then
	nic="-nic user,hostfwd=tcp::8889-:22"
       	vsock="-device vhost-vsock-pci,guest-cid=4"
	name="-name guest=vm1,debug-threads=on"
elif [[ "${vmno}" == 2 ]]
then
	nic="-nic user,hostfwd=tcp::8890-:22"
       	vsock="-device vhost-vsock-pci,guest-cid=5"
	name="-name guest=vm2,debug-threads=on"
fi

# Copy ssh config  for vms
cp ~/shared-storage/ssh_config_for_vms /root/.ssh/config

# Boot the vm
$pinto qemu-system-x86_64 /root/vdisk${vmno}.qcow2 -cpu host -smp ${vcpus},sockets=1,cores=${c},threads=${t} -m 50000 -enable-kvm $nic $vsock $name -initrd /root/initrd.img-${gkernel} -kernel /root/vmlinuz-${gkernel} -nographic -serial mon:stdio -append 'root=/dev/sda1 console=ttyS0'
