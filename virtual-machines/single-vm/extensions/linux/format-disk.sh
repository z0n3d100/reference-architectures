#
# format-disk.sh
#
#!/bin/bash

partprobe
# Format and mount drive 
echo ';' | sfdisk /dev/sdc
partprobe
mkfs -t ext3 /dev/sdc1 --no-reread
mkdir -p /data1
if grep -qs '/mnt/foo' /proc/mounts; then
    echo "already mounted."
else
    mount /dev/sdc1 /data1
fi