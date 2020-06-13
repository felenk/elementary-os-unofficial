#!/bin/bash

echo -e "
#--------------------------------#
# STAGE 0 - INSTALL DEPENDENCIES #
#--------------------------------#
"

apt-get update
apt-get install -y \
  wget \
  xz-utils \
  kpartx \
  qemu-user-static \
  parted \
  zerofree \
  dosfstools

echo -e "
#------------------------#
# STAGE 0 - FETCH UBUNTU #
#------------------------#
"
if [ ! -f ${BASE_IMG} ]; then
    wget ${BASE_IMG_URL} -O ${BASE_IMG}.xz
    unxz ${BASE_IMG}.xz
fi

echo -e "--> Copying image..."

cp -vf ${BASE_IMG} ${TARGET_IMG}

sync
sleep 5

echo -e "--> Image copied."
