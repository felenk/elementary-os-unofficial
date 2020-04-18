#!/bin/bash

echo -e "
#--------------------#
# STAGE 4 - SAVE IMG #
#--------------------#
"

# Run fsck on image
fsck.ext4 -pfv /dev/mapper/"${MountXZ}"p2
fsck.fat -av /dev/mapper/"${MountXZ}"p1

zerofree -v /dev/mapper/"${MountXZ}"p2

# Save image
UnmountIMG

# Create artifacts
mv ${TARGET_IMG} artifacts/
cd artifacts
rm -f ${TARGET_IMG}.xz
xz -0 ${TARGET_IMG}
md5sum ${TARGET_IMG}.xz > ${TARGET_IMG}.xz.md5
sha256sum ${TARGET_IMG}.xz > ${TARGET_IMG}.xz.sha256