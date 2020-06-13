#!/bin/bash

set -e

CONFIG_FILE="./config"

# Ensure that the confguration file is present
if test -z "${CONFIG_FILE}"; then
  echo "Configuration file need to be present in '${DIR}/config' or path passed as parameter"
  exit 1
else
  # shellcheck disable=SC1090
  source ${CONFIG_FILE}
fi

if [ -z "${IMG_NAME}" ]; then
  echo "IMG_NAME not set in 'config'" 1>&2
  echo 1>&2
exit 1
fi

function MountIMG {
  MountXZ=$(kpartx -avs "$TARGET_IMG")
  sync
  MountXZ=$(echo "$MountXZ" | awk 'NR==1{ print $3 }')
  MountXZ="${MountXZ%p1}"
  echo "==> Mounted $TARGET_IMG on loop $MountXZ"
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
  echo "==> Current mount points:"
  mount
}

function UnmountIMGPartitions {
  sync
  sleep 0.1

  echo "==> Unmounting /mnt/boot/firmware"
  while mountpoint -q /mnt/boot/firmware && ! umount /mnt/boot/firmware; do
    sync
    sleep 0.1
  done

  echo "==> Unmounting /mnt"
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

  echo "==> Unmounting $TARGET_IMG"
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

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -f "${DIR}/config" ]; then
  CONFIG_FILE="${DIR}/config"
fi

while getopts "c:" flag
do
  case "${flag}" in
    c)
      CONFIG_FILE="${OPTARG}"
      ;;
    *)
      ;;
  esac
done


# Installs dependencies & ubuntu
source "stage0/run.sh"

# Expand the image & fix partitions
source "stage1/run.sh"

# Install Elementary
source "stage2/run.sh"

# Clean up
source "stage3/run.sh"

# Save image
source "stage4/run.sh"
