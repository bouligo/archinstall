#!/bin/sh

if [ -z "$2" ]; then
	echo "Usage: $0 hostname user"
	exit 1
fi

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

loadkeys fr # as no grub 
printf "${CYAN}[*] ${GREEN}Formatting disk${NC}\n"
## Pour deux partitions, une ESP, et un ext4 basique
#parted -s /dev/sda mklabel gpt mkpart primary fat32 1 500M mkpart primary ext4 500M "100%" set 1 boot on
# With swap
parted -s /dev/sda mklabel gpt mkpart primary fat32 1 500MB mkpart primary linux-swap 500M 2GB mkpart primary ext4 2GB "100%" set 1 boot on
mkfs.fat -F32 /dev/sda1

printf "${CYAN}[*] ${GREEN}Enabling swap partition${NC}\n"
mkswap /dev/sda2
swapon /dev/sda2

printf "${CYAN}[*] ${GREEN}Creating luks encrypted volume${NC}\n"
cryptsetup --type luks1 luksFormat /dev/sda3
cryptsetup open /dev/sda3 luks
mkfs.ext4 /dev/mapper/luks

printf "${CYAN}[*] ${GREEN}Mounting system partitions${NC}\n"
mount /dev/mapper/luks /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

printf "${CYAN}[*] ${GREEN}Installing packages${NC}\n"
reflector --country France --latest 10 --sort rate --save /etc/pacman.d/mirrorlist 
pacstrap /mnt base base-devel linux-zen linux-firmware htop net-tools vim intel-ucode efibootmgr nmap git openssh tmux lsb-release zsh fzf zsh-autosuggestions zsh-completions zsh-syntax-highlighting

printf "${CYAN}[*] ${GREEN}Generating fstab${NC}\n"
genfstab -U /mnt >> /mnt/etc/fstab

printf "${CYAN}[*] ${GREEN}Configuring languages, timezone, hostname${NC}\n"
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
arch-chroot /mnt hwclock --systohc
sed -i -e "s/#en_US.UTF-8/en_US.UTF-8/g" -e "s/#fr_FR.UTF-8/fr_FR.UTF-8/g" /mnt/etc/locale.gen

arch-chroot /mnt locale-gen
echo 'LANG="fr_FR.UTF-8"' > /mnt/etc/locale.conf
echo 'LANGUAGE="fr_FR"' >> /mnt/etc/locale.conf
echo 'KEYMAP=fr' > /mnt/etc/vconsole.conf 
printf "$1" > /mnt/etc/hostname
printf "127.0.0.1 $1" >> /mnt/etc/hosts

printf "${CYAN}[*] ${GREEN}Installing optionnal packages${NC}\n"
## VMware
#pacstrap /mnt open-vm-tools xf86-input-vmmouse xf86-video-vmware mesa
# KDE
pacstrap /mnt plasma yakuake dolphin spectacle kate networkmanager ark gwenview
## KDE minimal? 
#pacstrap /mnt plasma-desktop sddm sddm-kcm konsole dolphin
# extra
pacstrap /mnt firefox unzip gparted
## Gnome
#pacstrap /mnt gnome gnome-software-packagekit-plugin networkmanager

printf "${CYAN}[*] ${GREEN}Setting up enciphered startup${NC}\n"
sed -i 's#filesystems#encrypt filesystems#g' /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P

printf "${CYAN}[*] ${GREEN}Configuring EFI boot${NC}\n"
#efibootmgr --create --disk /dev/sda --part 1 --label "Arch Linux" --loader /vmlinuz-linux-zen --unicode 'root=/dev/sda3 rw initrd=\intel-ucode.img initrd=\initramfs-linux-zen.img'
efibootmgr --create --disk /dev/sda --part 1 --label "Arch Linux" --loader /vmlinuz-linux-zen --unicode 'cryptdevice=/dev/sda3:root root=/dev/mapper/root rw initrd=\intel-ucode.img initrd=\initramfs-linux-zen.img'
efibootmgr -D

loadkeys fr
printf "${CYAN}[*] ${GREEN}Setting root password${NC}\n"
arch-chroot /mnt passwd

printf "${CYAN}[*] ${GREEN}Creating user $2 in wheel group${NC}\n"
arch-chroot /mnt useradd -m "$2"
arch-chroot /mnt usermod -a -G wheel "$2"
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /mnt/etc/sudoers
arch-chroot /mnt passwd "$2"

printf "${CYAN}[*] ${GREEN}Changing shell for root and user $2${NC}\n"
arch-chroot /mnt chsh "$2" -s /usr/bin/zsh
arch-chroot /mnt chsh root -s /usr/bin/zsh

printf "${CYAN}[*] ${GREEN}Installing Oh-My-ZSH for user $2${NC}\n"
arch-chroot /mnt su "$2" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"' < /dev/null

printf "${CYAN}[*] ${GREEN}Enabling services${NC}\n"
arch-chroot /mnt systemctl enable fstrim.timer
arch-chroot /mnt systemctl enable sddm
arch-chroot /mnt systemctl enable NetworkManager

printf "${CYAN}[*] ${GREEN}Umounting filesystems and closing LUKS volume${NC}\n"
umount /mnt/boot
umount /mnt
cryptsetup close /dev/mapper/luks

printf "${CYAN}[*] ${GREEN}Done. To have french keyboard in SDDM, run this as root after reboot : localectl set-x11-keymap fr${NC}\n"
