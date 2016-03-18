#!/bin/bash

VBOXMANAGE=`which vboxmanage`
RUNNINGVMSLIST="$VBOXMANAGE list runningvms" 
TXTRUNNINGVMS=/tmp/runningvms.txt



## :: FUNCTIONS :: ##

save_txt_running_vms ()
{
  eval $RUNNINGVMSLIST | awk -F\" '{print $2}' #> $TXTRUNNINGVMS
}

acpipower_vms ()
{
  #while read vm; do
  #  $VBOXMANAGE controlvm "$vm" acpipowerbutton
  #done < $TXTRUNNINGVMS
  echo "jump!"
}

check_vms_are_shutdown ()
{
  VMSCHECK=$(eval $RUNNINGVMSLIST)
  
  if [ ! "$(eval $VMSCHECK)" ]; then
#  if [ ! "$(eval $RUNNINGVMSLIST)" ]; then
    return 0
  else
    return 1
  fi
}

start_vms () 
{
  # Loop thru the file starting VMs in headless mode
  while read vm; do
    $VBOXMANAGE startvm "$vm" --type headless
  done < $TXTRUNNINGVMS
}


# :: MAIN ::

case $1 in
  -s | --shutdown | --poweroff )
    save_txt_running_vms
    acpipower_vms
    sleep 5m
    #check_vms_are_shutdown
    if [ -z "$(echo $RUNNINGVMSLIST)" ]; then
      exit 0
    else
      echo "Some VMs didn't shutdown"
      exit 1
    fi
    ;;

  -b | --boot | --poweron )
    if [ -s $TXTRUNNINGVMS ]; then
      start_vms
    else
      echo "the file $TXTRUNNINGVMS can't be found or is empty"
      exit 2
    fi
    ;;

  * | -h | --help )
    echo "Usage:"
    echo "  -s, --shutdown, --poweroff"
    echo "      Shutdown running VMs."
    echo "  -b, --boot, --poweron"
    echo "      Boot VMs that are in the file $TXTRUNNINGVMS."
    echo "      The file is generated automatically only when this script was launched with the -p option before"
    echo "  -h, --help"
    echo "      This help."
    ;;
esac
