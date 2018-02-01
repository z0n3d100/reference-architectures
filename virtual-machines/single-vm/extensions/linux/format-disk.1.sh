#
# format-disk.sh
#
#!/bin/bash

partprobe
# Format and mount drive 
echo ';' | sfdisk /dev/sdd
partprobe
mkfs -t ext3 /dev/sdd1
mkdir -p /data2
if grep -qs '/data2' /proc/mounts; then
    echo "already mounted."
else
    mount /dev/sdc1 /data1
fi