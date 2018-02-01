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
)|fdisk /dev/sdd
partprobe
mkfs -t ext3 /dev/sdd1
mkdir /data2
mount /dev/sdd1 /data2