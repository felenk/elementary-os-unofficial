#!/bin/bash

set -e

echo -e "
#------------------------#
# STAGE 1 - EXPAND IMAGE #
#------------------------#
"

echo -e "--> Running truncate..."

truncate -s 7G "$TARGET_IMG"
sync

sleep 5

echo -e "--> Mounting image on ${MountXZ}"

MountIMG

echo -e "
#--------------------------#
# STAGE 1 - FIX PARTITIONS #
#--------------------------#
"

echo -e "--> Fixing partitions..."

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

echo -e "--> Remounting..."

# Close and unmount image then reopen it to get the new mapping
UnmountIMG
MountIMG

echo -e "--> Running fsck..."

# Run fsck
e2fsck -fva /dev/mapper/"${MountXZ}"p2
sync
sleep 1

echo -e "--> Remounting..."

UnmountIMG
MountIMG

echo -e "--> Running resize2fs..."
# Run resize2fs
resize2fs /dev/mapper/"${MountXZ}"p2
sync
sleep 1

echo -e "--> Remounting..."

UnmountIMG
MountIMG

echo -e "--> Zeroing out whitespace..."

# Zero out free space on drive to reduce compressed img size
zerofree -v /dev/mapper/"${MountXZ}"p2
sync
sleep 1

echo -e "--> Done."
