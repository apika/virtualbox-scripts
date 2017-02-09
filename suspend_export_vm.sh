#!/bin/bash
# This scripts loops through all the user's VirtualBox vm's, pauses them,
# exports them and then restores the original state.
#
# VirtualBox's snapshot system is not stable enough for unmonitored use yet.
#
# Original by Vorkbaard, 2012-02-01

# TODO: disable unnmount if the export dir is a disk or a folder

# =============== Set your variables here ===============

  EXPORTDIR=/mnt/vmbackups
  MYMAIL=mail@company.com
  #VBOXMANAGE="/usr/bin/VBoxManage -q"
  EXPORTLOG=/tmp/vmbackups_export.log
  
  declare -A VM

# =======================================================

# Generate a list of all vm's; use sed to remove the double quotes.

# Note: better not use quotes or spaces in your vm name. If you do,
# consider using the vms' ids instead of friendly names:
# for VMNAME in $(vboxmanage list vms | cud -t " " -f 2)
# Then you'd get the ids in your mail so you'd have to use vboxmanage
# showvminfo $id or something to retrieve the vm's name. I never use
# weird characters in my vm names anyway.

mount "$EXPORTDIR" 2> /dev/null

if ! grep -qs "$EXPORTDIR" /proc/mounts; then
  # Notify the admin
  MAILBODY="Error mounting the external disk"
  MAILSUBJECT="VM backup failed"

  # Send the mail
  echo "$MAILBODY" | mail -s "$MAILSUBJECT" $MYMAIL

  exit 5
fi

#for vmuuid in $(vboxmanage list vms | grep "vyos-01" | cut -d "{" -f 2 | sed -e 's/}$//') # For testing
# TODO: Delete de extra cut commands, leave only sed
for vmuuid in $(vboxmanage list vms | cut -d "{" -f 2 | sed -e 's/}$//')
do

  ERR="nothing"
  SECONDS=0

  # Delete old $EXPORTLOG file if it exists
    if [ -e $EXPORTLOG ]; then rm $EXPORTLOG; fi


  # Get the vm information
  # TODO: make a loop of vboxmanage showinfo
    VM[uuid]="$vmuuid"; unset vmuuid
    VM[name]=$(vboxmanage showvminfo "${VM[uuid]}" --machinereadable | grep "name=" | cut -d '"' -f 2 | sed -e 's/"$//')
    VM[state]=$(vboxmanage showvminfo "${VM[uuid]}" --machinereadable | grep "VMState=" | cut -d '"' -f 2 | sed -e 's/"$//')
    #echo "${VM[name]}'s state is: ${VM[state]}"


  # If the VM's state is running or paused, save its state
    if [[ ${VM[state]} == "running" || ${VM[state]} == "paused" ]]; then
      #echo "Saving state..."
      vboxmanage controlvm "${VM[uuid]}" savestate
      if [ $? -ne 0 ]; then ERR="saving the state"; fi
    fi

  # Export the vm as appliance
    if [ "$ERR" == "nothing" ]; then
      #echo "Exporting the VM..."
      vboxmanage export "${VM[uuid]}" --output $EXPORTDIR/"${VM[name]}-new.ova" &> $EXPORTLOG
      if [ $? -ne 0 ]; then
        ERR="exporting"
      else
        # Remove old backup and rename new one
       if [ -e $EXPORTDIR/"${VM[name]}.ova" ]; then rm $EXPORTDIR/"${VM[name]}.ova"; fi
       mv $EXPORTDIR/"${VM[name]}-new.ova" $EXPORTDIR/"${VM[name]}.ova"
       # Get file size
       FILESIZE=$(du -h $EXPORTDIR/"${VM[name]}.ova" | cut -f 1)
      fi
    else
      echo "Not exporting because the VM's state couldn't be saved." &> $EXPORTLOG
    fi

  # Resume the VM to its previous state if that state was paused or running
    if [[ ${VM[state]} == "running" || ${VM[state]} == "paused" ]]; then
        #echo "Resuming previous state..."
        vboxmanage startvm "${VM[uuid]}" --type headless
        if [ $? -ne 0 ]; then ERR="resuming"; fi
        if [ ${VM[state]} == "paused" ]; then
          vboxmanage controlvm "${VM[uuid]}" pause
          if [ $? -ne 0 ]; then ERR="pausing"; fi
        fi
      fi

  # Calculate duration
    duration=$SECONDS
    duration="Operation took $(($duration / 60)) minutes, $(($duration % 60)) seconds."

  # Notify the admin
    if [ "$ERR" == "nothing" ]; then
      MAILBODY="Virtual Machine ${VM[name]} was exported succesfully!"
      MAILBODY="$MAILBODY"$'\n'"$duration"
      MAILBODY="$MAILBODY"$'\n'"Export filesize: $FILESIZE"
      MAILSUBJECT="VM ${VM[name]} succesfully backed up"
    else
      MAILBODY="There was an error $ERR VM ${VM[name]} ."
      if [ "$ERR" == "exporting" ]; then
        MAILBODY=$(echo $MAILBODY && cat $EXPORTLOG)
      fi
      MAILSUBJECT="Error exporting VM ${VM[name]}"
    fi

  # Send the mail
    echo "$MAILBODY" | mail -s "$MAILSUBJECT" $MYMAIL

  # Clean up
    if [ -e $EXPORTLOG ]; then rm $EXPORTLOG; fi

done


sleep 120
umount "$EXPORTDIR"
sync
sleep 60
udisksctl power-off -b /dev/disk/by-uuid/572eed5e-218a-44ee-84e2-81a82e9adaa2
