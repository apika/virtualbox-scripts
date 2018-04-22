# IMPORTANT
This scripts could make a bad VM backups. The (supposed) right way to backup your vms is:

**I didn't test this steps myself so I can't confirm that is working**

1. Shutdown your VM
2. Create a snapshot, lets call it A.
3. Create a second snapshot, lets call it B.
4. Copy all of your VM folder.
5. Delete snapshot B.
6. Start VM from snapshot A.
7. Delete snapshot A.

More info here https://forums.virtualbox.org/viewtopic.php?f=1&t=84388


# virtualbox-scripts
Scripts for managing virtualbox VMs

#### powerOnOff_VmsVirtualbox.sh

Shutdown and boot automatically VMs. For the boot to work they had to be
shutdown with the script first.

Made for bacula but will work with any backup solution that could
launch scripts before and after the the backup.

```bash
-s, --shutdown, --poweroff
    Shutdown running VMs.
-b, --boot, --poweron
    Boot VMs that are in the file $TXTRUNNINGVMS.
    The file is generated automatically only when this script was launched with the -p option before
-h, --help
    This help.
```
