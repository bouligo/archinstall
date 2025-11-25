#!/bin/sh

if [ -z "$3" ]; then
	echo "Usage: $0 diskname hostname user"
	echo "Example: bash $0 sda MyHostname MyUsername"
	echo "Example: bash $0 mmcblk0 NoobzReaper neo"
	echo "Example: bash $0 nvme0n1 noticemesempai kawai"
	exit 1
fi
if [ "$0" == "template.sh" ]; then
	echo "You shouldn't run the template as it contains many different configurations that are in conflict by nature."
	echo "Copy this script somewhere else and customize it."
	exit 2
fi

export user_disk="$1"
export user_hostname="$2"
export user_username="$3"

export RED='\033[0;31m'
export CYAN='\033[0;36m'
export GREEN='\033[0;32m'
export NC='\033[0m' # No Color

##
# Update liveiso keyring to ensure pacman will be able to download and install packages without signing issues

bash ./modules/liveiso/keyring-update.sh

##
# Disk configuration (select only one)

# bash ./modules/disk/uefi/simple.sh
# bash ./modules/disk/uefi/lvm.sh
bash ./modules/disk/uefi/lvm-on-luks.sh

##
# Core packages

bash ./modules/packages/reflector.sh

bash ./modules/packages/core.sh
# bash ./modules/packages/amd.sh
# bash ./modules/packages/intel.sh
# bash ./modules/packages/kernel.sh
# bash ./modules/packages/kernel-headers.sh
# bash ./modules/packages/kernel-lts.sh
# bash ./modules/packages/kernel-lts-headers.sh
bash ./modules/packages/kernel-zen.sh
bash ./modules/packages/kernel-zen-headers.sh


##
# fstab generation

bash ./modules/disk/fstab.sh

##
# Locale management

bash ./modules/locales/timezones/paris.sh
bash ./modules/settings/hostname.sh
bash ./modules/locales/keyboards/french.sh

bash ./modules/locales/languages/english.sh
bash ./modules/locales/languages/french.sh

##
# User management
bash ./modules/settings/passwd.sh
# bash ./modules/settings/passwd-root.sh

##
# Additionnal packages

# bash ./modules/packages/kde-minimal.sh
bash ./modules/packages/kde.sh
# bash ./modules/packages/gnome-minimal.sh
# bash ./modules/packages/gnome.sh

bash ./modules/packages/yay.sh
bash ./modules/packages/zsh.sh
bash ./modules/packages/extras.sh

# bash ./modules/packages/vmware.sh
# bash ./modules/packages/qemu.sh
# bash ./modules/packages/offsec.sh


##
# Installing bootloader (select only one)

# bash ./modules/bootloader/grub.sh
bash ./modules/bootloader/efistub.sh


##
# Users configuration

bash ./modules/settings/zsh.sh
bash ./modules/settings/ohmyzsh.sh


##
# Services

bash ./modules/services/networkmanager.sh
# bash ./modules/autorun/nm-hotspot.sh
# bash ./modules/services/ssh.sh
bash ./modules/services/fstrim.sh


##
# Un-mounting disks

bash ./modules/disk/umount.sh

##
# Reboot of poweroff

reboot
# poweroff
