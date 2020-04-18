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

export -f MountIMG
export -f UnmountIMGPartitions
export -f UnmountIMG