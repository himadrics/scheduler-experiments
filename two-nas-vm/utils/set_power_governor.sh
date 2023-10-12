#!/bin/bash
# ./set_power_governer.sh governor="performance"
#
# governor= schedutil, powersave, performance (required)

# Parse named command-line arguments
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
	          governor) governor=${VALUE} ;;
            *)
    esac
done

# Set value of power-status
if [[ "${governor}" == "performance" ]]
then
	pstatus="active"
else
  pstatus="passive"
fi

# Change power-status
model=`lscpu | grep "Model name" | head -1`
if [[ "$model" =~ Intel* ]]
then
  echo "Detected an Intel machine, changing intel_pstate status:"
  echo "Current power status - `cat /sys/devices/system/cpu/intel_pstate/status`"
  echo ${pstatus} | sudo tee /sys/devices/system/cpu/intel_pstate/status
  echo "New power status - `cat /sys/devices/system/cpu/intel_pstate/status`"
else
  echo "Not an intel machine. Hence doing nothing."
fi

# Change power-governor
for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
do
	echo ${governor} > $i
done
echo "Info: Changed power governor to ${governor}"
