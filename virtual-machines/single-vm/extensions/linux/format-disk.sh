#
# format-disk.sh
#
#!/bin/bash

partprobe
# Format and mount drive 
echo ';' | sfdisk /dev/sdc
partprobe
mkfs -t ext3 /dev/sdc1
mkdir -p /data1
if grep -qs '/data1' /proc/mounts; then
    echo "already mounted."
else
    mount /dev/sdc1 /data1
fi