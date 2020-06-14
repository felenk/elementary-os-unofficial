#!/bin/bash

set -e

echo -e "
#------------------------------------#
# STAGE 2 - FETCH ELEMENTARY PATCHES #
#------------------------------------#
"

echo -e "--> Remounting..."
UnmountIMG
MountIMG
echo -e "--> Done."

# Map the partitions of the IMG file so we can access the filesystem
echo -e "--> Mounting partitions..."
MountIMGPartitions
echo -e "--> Done."

# Configuration for elementary OS
echo -e "--> Fetching NetworkManager configuration..."
wget $NET_PLAN_URL \
  -O /mnt/etc/netplan/01-network-manager-all.yml

mkdir -p /mnt/etc/NetworkManager/conf.d

wget $NETWORK_MANAGER_URL \
  -O /mnt/etc/NetworkManager/conf.d/10-globally-managed-devices.conf

echo -e "--> Done."

echo -e "
#--------------------------#
# STAGE 2 - FETCH OEM LOGO #
#--------------------------#
"

echo -e "--> Setting OEM information..."
mkdir -p /mnt/etc/oem
wget $LOGO_URL \
  -O /mnt/etc/oem/logo.png

mkdir -p /mnt/etc/oem

cat > /mnt/etc/oem.conf << EOF
[OEM]
Manufacturer=$OEM_MANUFACTURER
Product=$OEM_PRODUCT
Logo=$OEM_LOGO
URL=$OEM_URL
EOF

echo -e "--> Done."

# setup chroot
echo -e "--> Injecting QEMU..."
cp -f /usr/bin/qemu-aarch64-static /mnt/usr/bin
echo -e "--> Done."



echo -e "--> Injecting DNS config..."
ls -al /mnt/etc/resolv.conf
RESOLV_CONF=`readlink /mnt/etc/resolv.conf`
rm -f /mnt/etc/resolv.conf
cat > /mnt/etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
echo -e "--> Done."

# chroot

echo -e "
#---------------------------------#
# STAGE 2 - Install ELEMENTARY OS #
#---------------------------------#
"

echo -e "--> Package setup (this will take a long while)...."
set +e
chroot /mnt /bin/bash -x << EOF
export DEBIAN_FRONTEND=noninteractive

# Add elementary OS stable repository
add-apt-repository ppa:elementary-os/stable -ny

# Add elementary OS patches repository
add-apt-repository ppa:elementary-os/os-patches -ny

# Upgrade packages
apt-get update
apt-get upgrade -y

echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections

echo -e "--> Base Packages"
apt-get install -y \
  ttf-mscorefonts-installer \
  fonts-firacode \
  vim \
  tmux \
  htop

echo -e "--> Elementary"
apt-get install -y \
  elementary-desktop \
  elementary-minimal \
  elementary-standard 


echo -e "--> Elementary Setup"
apt-get install -y 
  io.elementary.initial-setup \
  io.elementary.onboarding 

echo -e "--> Remove unnecessary packages"
apt-get purge -y \
  unity-greeter \
  ubuntu-server \
  plymouth-theme-ubuntu-text \
  cloud-init \
  cloud-initramfs* \
  lxd \
  lxd-client \
  acpid \
  gnome-software

echo -e "--> Cleanup packages"
# Clean up after ourselves and clean out package cache to keep the image small
apt-get autoremove -y
apt-get clean
apt-get autoclean
EOF
set -e
echo -e "--> Package setup done."

echo -e "--> Restoring resolv.conf..."
rm -f /mnt/etc/resolv.conf
ln -s ${RESOLV_CONF} /mnt/etc/resolv.conf
ls -al /mnt/etc/resolv.conf
echo -e "--> Done."
