#!/bin/bash

# Map the partitions of the IMG file so we can access the filesystem
MountIMGPartitions

echo -e "
#------------------------------------#
# STAGE 2 - FETCH ELEMENTARY PATCHES #
#------------------------------------#
"

# Configuration for elementary OS
wget {$NET_PLAN_URL} \
  -O /mnt/etc/netplan/01-network-manager-all.yml

mkdir -p /mnt/etc/NetworkManager/conf.d

wget {$NETWORK_MANAGER_URL} \
  -O /mnt/etc/NetworkManager/conf.d/10-globally-managed-devices.conf

echo -e "
#--------------------------#
# STAGE 2 - FETCH OEM LOGO #
#--------------------------#
"

wget {$LOGO_URL} \
  -O /mnt/etc/oem/logo.png

mkdir -p /mnt/etc/oem

cat > /mnt/etc/oem.conf << "
[OEM]
Manufacturer=$OEM_MANUFACTURER
Product=$OEM_PRODUCT
Logo=$OEM_LOGO
URL=$OEM_URL
"

# setup chroot
cp -f /usr/bin/qemu-aarch64-static /mnt/usr/bin

mount --bind /etc/resolv.conf /mnt/etc/resolv.conf

# chroot
set +e

echo -e "
#---------------------------------#
# STAGE 2 - Install ELEMENTARY OS #
#---------------------------------#
"

chroot /mnt /bin/bash << EOF
# Add elementary OS stable repository
add-apt-repository ppa:elementary-os/stable -ny

# Add elementary OS patches repository
add-apt-repository ppa:elementary-os/os-patches -ny

# Upgrade packages
apt-get update
apt-get upgrade -y

# Install elementary OS packages
apt-get install -y \
  elementary-desktop \
  elementary-minimal \
  elementary-standard

# Install elementary OS initial setup
apt-get install -y \
  io.elementary.initial-setup

# Install elementary OS onboarding
apt-get install -y \
  io.elementary.onboarding

# Remove unnecessary packages
apt-get purge -y \
  unity-greeter \
  ubuntu-server \
  plymouth-theme-ubuntu-text \
  cloud-init \
  cloud-initramfs* \
  lxd \
  lxd-client \
  acpid \
  gnome-software \
  vim*

# Clean up after ourselves and clean out package cache to keep the image small
apt-get autoremove -y
apt-get clean
apt-get autoclean
EOF
set -e

umount /mnt/etc/resolv.conf