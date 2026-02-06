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

source ./modules/liveiso/keyring-update.sh

##
# Disk configuration (select only one)

# source ./modules/disk/uefi/simple.sh
# source ./modules/disk/uefi/lvm.sh
source ./modules/disk/uefi/lvm-on-luks.sh

##
# Core packages

source ./modules/packages/reflector.sh

source ./modules/packages/core.sh
# source ./modules/packages/amd.sh
# source ./modules/packages/intel.sh
# source ./modules/packages/kernel.sh
# source ./modules/packages/kernel-headers.sh
# source ./modules/packages/kernel-lts.sh
# source ./modules/packages/kernel-lts-headers.sh
source ./modules/packages/kernel-zen.sh
source ./modules/packages/kernel-zen-headers.sh


##
# fstab generation

source ./modules/disk/fstab.sh

##
# Locale management

source ./modules/locales/timezones/paris.sh
source ./modules/settings/hostname.sh
source ./modules/locales/keyboards/french.sh

# Last language will be system-language
source ./modules/locales/languages/english.sh
source ./modules/locales/languages/french.sh

##
# User management
source ./modules/settings/passwd.sh
# source ./modules/settings/passwd-root.sh

##
# Additionnal packages

# source ./modules/packages/kde-minimal.sh
source ./modules/packages/kde.sh
# source ./modules/packages/gnome-minimal.sh
# source ./modules/packages/gnome.sh

source ./modules/packages/yay.sh
source ./modules/packages/zsh.sh
source ./modules/packages/extras.sh

# source ./modules/packages/vmware.sh
# source ./modules/packages/qemu.sh
# source ./modules/packages/offsec.sh


##
# Installing bootloader (select only one)

# source ./modules/bootloader/grub.sh
source ./modules/bootloader/efistub.sh


##
# Users configuration

source ./modules/settings/zsh.sh
source ./modules/settings/ohmyzsh.sh
# source ./modules/settings/sddm-autologin.sh


##
# Services

source ./modules/services/networkmanager.sh
# source ./modules/autorun/nm-hotspot.sh
# source ./modules/services/ssh.sh
source ./modules/services/fstrim.sh


##
# Un-mounting disks

source ./modules/disk/umount.sh

##
# Reboot of poweroff

reboot
# poweroff
