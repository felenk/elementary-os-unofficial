#!/bin/bash

echo -e "
#------------------------#
# STAGE 1 - EXPAND IMAGE #
#------------------------#
"
truncate -s 7G "$TARGET_IMG"
sync

sleep 5

MountIMG

echo -e "
#--------------------------#
# STAGE 1 - FIX PARTITIONS #
#--------------------------#
"

# Get the starting offset of the root partition
PART_START=$(parted /dev/"${MountXZ}" -ms unit s p | grep ":ext4" | cut -f 2 -d: | sed 's/[^0-9]//g')

# Perform fdisk to correct the partition table
set +e
fdisk /dev/"${MountXZ}" << EOF
p
d
2
n
p
2
$PART_START

p
w
EOF
set -e

# Close and unmount image then reopen it to get the new mapping
UnmountIMG
MountIMG

# Run fsck
e2fsck -fva /dev/mapper/"${MountXZ}"p2
sync
sleep 1

UnmountIMG
MountIMG

# Run resize2fs
resize2fs /dev/mapper/"${MountXZ}"p2
sync
sleep 1

UnmountIMG
MountIMG

# Zero out free space on drive to reduce compressed img size
zerofree -v /dev/mapper/"${MountXZ}"p2
sync
sleep 1