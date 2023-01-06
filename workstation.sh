#!/bin/sh

if [ -z "$2" ]; then
	echo "Usage: $0 hostname user"
	exit 1
fi

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

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
mkdir -p /mnt/boot/EFI
mount /dev/sda1 /mnt/boot/EFI

printf "${CYAN}[*] ${GREEN}Installing packages${NC}\n"
reflector --country France --latest 10 --sort rate --save /etc/pacman.d/mirrorlist 
pacstrap /mnt base base-devel linux-zen linux-firmware htop net-tools vim intel-ucode grub efibootmgr nmap git openssh tmux lsb-release zsh fzf zsh-autosuggestions zsh-completions zsh-syntax-highlighting

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
pacstrap /mnt plasma yakuake dolphin spectacle kate networkmanager 
## KDE minimal? 
#pacstrap /mnt plasma-desktop sddm sddm-kcm konsole dolphin
# extra
pacstrap /mnt firefox unzip gparted
## Gnome
#pacstrap /mnt gnome gnome-software-packagekit-plugin networkmanager

printf "${CYAN}[*] ${GREEN}Setting up enciphered startup${NC}\n"
dd bs=512 count=4 if=/dev/random of=/mnt/crypto_keyfile.bin
cryptsetup luksAddKey /dev/sda3 /mnt/crypto_keyfile.bin 

sed -i 's#FILES=()#FILES=(/crypto_keyfile.bin)#g' /mnt/etc/mkinitcpio.conf
sed -i 's#block filesystems#block encrypt filesystems#g' /mnt/etc/mkinitcpio.conf
sed -i 's/#GRUB_ENABLE_CRYPTODISK=./GRUB_ENABLE_CRYPTODISK=y/g' /mnt/etc/default/grub
sed -i 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="cryptdevice=/dev/sda3:luks"#g' /mnt/etc/default/grub

arch-chroot /mnt mkinitcpio -P
chmod 000 /mnt/crypto_keyfile.bin

printf "${CYAN}[*] ${GREEN}Installing grub${NC}\n"
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=BOOT
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

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

printf "${CYAN}[*] ${GREEN}Enabling services${NC}\n"
arch-chroot /mnt systemctl enable fstrim.timer
arch-chroot /mnt systemctl enable sddm
arch-chroot /mnt systemctl enable NetworkManager

printf "${CYAN}[*] ${GREEN}Umounting filesystems and closing LUKS volume${NC}\n"
umount /mnt/boot/EFI
umount /mnt
cryptsetup close /dev/mapper/luks

printf "${CYAN}[*] ${GREEN}Done. To have french keyboard in SDDM, run this as root after reboot : localectl set-x11-keymap fr${NC}\n"



###############################################
# Original:

## on reste volontairement en clavier qwerty pour taper le mot de passe luks tel quel
#
## on partitionne d'abord le disque avec fdisk
## une partition efi de 500m ou 1g et le reste en btrfs
#fdisk -l
#
#
## Pour deux partitions, une ESP, et un ext4 basique
#parted -s /dev/sda mklabel gpt mkpart primary fat32 1 500M mkpart primary 
#ext4 500M "100%" set 1 boot on
## Sinon: 
#fdisk /dev/sda
#mkfs.fat -F32 /dev/sda1
#
## création du conteneur luks en luks1 pour la compat avec grub2
#cryptsetup --type luks1 luksFormat /dev/sda2
#
## on déverrouille, formatte et monte le fs
#cryptsetup open /dev/sda2 luks
#mkfs.btrfs -L btrfs_root /dev/mapper/luks 
#mount /dev/mapper/luks /mnt
#
## on crée les volumes btrfs
#btrfs subvolume create /mnt/@
#btrfs subvolume create /mnt/@home
## btrfs subvolume create /mnt/@snapshots # plus besoin
#
## on démonte et on remonte comme dans la configuration cible
#umount /mnt
#mount -o compress=zstd,subvol=@,ssd,noatime /dev/mapper/luks /mnt
#mkdir -p /mnt/home /mnt/boot/EFI
#mount -o compress=zstd,subvol=@home,ssd,noatime /dev/mapper/luks /mnt/home
#mount /dev/sda1 /mnt/boot/EFI
#
## Installation des packages
#reflector --country France --country Germany --latest 10 --sort rate --save /etc/pacman.d/mirrorlist 
#pacstrap /mnt base base-devel linux linux-firmware btrfs-progs snapper htop net-tools vim intel-ucode grub grub-btrfs efibootmgr nmap git openssh tmux lsb-release zsh fzf zsh-autosuggestions zsh-completions zsh-syntax-highlighting
#
## Génération fstab
#genfstab -U /mnt >> /mnt/etc/fstab
#
## configuration langues, timezone, hostname
#arch-chroot /mnt
#ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
#hwclock --systohc
#sed -i -e "s/#en_US.UTF-8/en_US.UTF-8/g" -e "s/#fr_FR.UTF-8/fr_FR.UTF-8/g" /etc/locale.gen
#
#locale-gen
#echo 'LANG="fr_FR.UTF-8"' > /etc/locale.conf
#echo 'LANGUAGE="fr_FR"' >> /etc/locale.conf
#echo 'KEYMAP=fr' > /etc/vconsole.conf 
#echo 'hostname' > /etc/hostname
#echo '127.0.0.1 hostname' >> /etc/hosts
#exit 
#
## VMware
#pacstrap /mnt open-vm-tools xf86-input-vmmouse xf86-video-vmware mesa
## KDE
#pacstrap /mnt plasma yakuake dolphin spectacle kate networkmanager 
## KDE minimal? 
#pacstrap /mnt plasma-desktop sddm sddm-kcm konsole dolphin
## extra
#pacstrap /mnt firefox unzip gparted
## Gnome
#pacstrap /mnt gnome gnome-software-packagekit-plugin networkmanager
#
## configuration de l'initramfs (/etc/mkinitcpio.conf) 
#BINARIES=(/usr/bin/btrfs)
#FILES=(/crypto_keyfile.bin)
#HOOKS="base udev autodetect modconf block encrypt filesystems keyboard fsck" 
#
## création d'un fichier clé qui sera dans l'initramfs
#dd bs=512 count=4 if=/dev/random of=/mnt/crypto_keyfile.bin
#cryptsetup luksAddKey /dev/sda2 /mnt/crypto_keyfile.bin 
#arch-chroot /mnt
#mkinitcpio -P
#chmod 000 /crypto_keyfile.bin
#
## configuration de grub /etc/default/grub 
#GRUB_ENABLE_CRYPTODISK=y
#GRUB_CMDLINE_LINUX="cryptdevice=/dev/sda2:luks" 
#
#grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=BOOT
#grub-mkconfig -o /boot/grub/grub.cfg
#
## gestion users
#passwd
#useradd -m almazys
#passwd almazys
#
## pour le trim
#systemctl enable fstrim.timer
#
## optionnel
#systemctl enable sddm
#systemctl enable NetworkManager
#systemctl enable vmtoolsd
#localectl set-x11-keymap fr