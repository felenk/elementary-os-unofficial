#!/bin/bash

echo -e "
#--------------------#
# STAGE 4 - SAVE IMG #
#--------------------#
"

echo -e "--> Running fsck on both image partitions."

# Run fsck on image
fsck.ext4 -pfv /dev/mapper/"${MountXZ}"p2
fsck.fat -av /dev/mapper/"${MountXZ}"p1

echo -e "--> Zeroing out free space..."

zerofree -v /dev/mapper/"${MountXZ}"p2

# Save image
UnmountIMG

echo -e "--> Creating artifacts"
# Create artifacts
mv ${TARGET_IMG} artifacts/
cd artifacts
rm -f ${TARGET_IMG}.xz

echo -e "--> Compressing image..."

xz -0 ${TARGET_IMG}
echo -e "--> Done. Checksumming..."

md5sum ${TARGET_IMG}.xz > ${TARGET_IMG}.xz.md5
sha256sum ${TARGET_IMG}.xz > ${TARGET_IMG}.xz.sha256

echo -e "--> Done."
echo -e "==> Image ready."
