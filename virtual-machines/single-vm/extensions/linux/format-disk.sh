#
# format-disk.sh
#
#!/bin/bash

partprobe
# Format and mount drive 
(
echo o
echo n
echo p
echo 1
echo
echo
echo w
)|fdisk /dev/$1
partprobe
mkfs -t ext3 /dev/$11
mkdir /data$2
mount /dev/$11 /data$2