#!/bin/bash

echo -e "
#--------------------#
# STAGE 3 - CLEAN UP #
#--------------------#
"

# Remove files needed for chroot
rm -rf /mnt/usr/bin/qemu-aarch64-static

# Remove any crash files generated during chroot
rm -rf /mnt/var/crash/*
rm -rf /mnt/var/run/*

# Configuration for elementary OS
sed -i 's/juno/bionic/g' /mnt/etc/apt/sources.list
sed -i 's/hera/bionic/g' /mnt/etc/apt/sources.list

sed -i 's/ubuntu/elementary/g' /mnt/etc/hostname
sed -i 's/ubuntu/elementary/g' /mnt/etc/hosts

echo "logo.nologo loglevel=0 quiet splash vt.global_cursor_default=0 plymouth.ignore-serial-consoles" > /mnt/boot/firmware/cmdline.txt

echo "" >> /mnt/boot/firmware/config.txt
echo "boot_delay=1" >> /mnt/boot/firmware/config.txt

# Unmount
UnmountIMGPartitions
