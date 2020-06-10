#!/bin/bash

function MountIMG {
  MountXZ=$(kpartx -avs "$TARGET_IMG")
  sync
  MountXZ=$(echo "$MountXZ" | awk 'NR==1{ print $3 }')
  MountXZ="${MountXZ%p1}"
  echo "Mounted $TARGET_IMG on loop $MountXZ"
}

function MountIMGPartitions {
  # % Mount the image on /mnt (rootfs)
  mount /dev/mapper/"${MountXZ}"p2 /mnt

  # % Remove overlapping firmware folder from rootfs
  rm -rf /mnt/boot/firmware
  mkdir /mnt/boot/firmware

  # % Mount /mnt/boot/firmware folder from bootfs
  mount /dev/mapper/"${MountXZ}"p1 /mnt/boot/firmware
  sync
  sleep 0.1
}

function UnmountIMGPartitions {
  sync
  sleep 0.1

  echo "Unmounting /mnt/boot/firmware"
  while mountpoint -q /mnt/boot/firmware && ! umount /mnt/boot/firmware; do
    sync
    sleep 0.1
  done

  echo "Unmounting /mnt"
  while mountpoint -q /mnt && ! umount /mnt; do
    sync
    sleep 0.1
  done

  sync
  sleep 0.1
}

function UnmountIMG {
  sync
  sleep 0.1

  UnmountIMGPartitions

  echo "Unmounting $TARGET_IMG"
  kpartx -dvs "$TARGET_IMG"

  sleep 0.1

  dmsetup remove ${MountXZ}p1
  dmsetup remove ${MountXZ}p2

  sleep 0.1

  losetup --detach-all /dev/${MountXZ}

  while [ -n "$(losetup --list | grep /dev/${MountXZ})" ]; do
    sync
    sleep 0.1
  done
}


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
