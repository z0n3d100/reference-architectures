#
# format-disk.sh
#
#!/bin/bash

partprobe
# Format and mount drive 
echo ';' | sfdisk /dev/sdc
partprobe
mkfs -t ext3 /dev/sdc1
mkdir /data1
mount /dev/sdc1 /data1