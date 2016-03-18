# virtualbox-scripts
Scripts for managing virtualbox VMs

#### powerOnOff_VmsVirtualbox.sh

Could shutdown and boot automatically VMs. For the boot to work they had to be
shutdown with the script first.

Made for bacula but will work with any backup solution that could
launch scripts before and after the initiation of the backup.

```bash
-s, --shutdown, --poweroff"
    Shutdown running VMs."
-b, --boot, --poweron"
    Boot VMs that are in the file $TXTRUNNINGVMS."
    The file is generated automatically only when this script was launched with the -p option before"
-h, --help"
    This help."
```
