#!/bin/sh

if [ -z "$2" ]; then
	echo "Usage: $0 hostname user"
	exit 1
fi

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

loadkeys fr

printf "${CYAN}[*] ${GREEN}Updating live system's keyring${NC}\n"
pacman -Sy --noconfirm archlinux-keyring

printf "${CYAN}[*] ${GREEN}Formatting disk${NC}\n"
## Pour deux partitions, une ESP, et un ext4 basique
#parted -s /dev/sda mklabel gpt mkpart primary fat32 1 500M mkpart primary ext4 500M "100%" set 1 boot on
# With swap
parted -s /dev/sda mklabel msdos mkpart primary fat32 1 500MB mkpart primary linux-swap 500M 2GB mkpart primary ext4 2GB "100%" set 1 boot on
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda3

printf "${CYAN}[*] ${GREEN}Enabling swap partition${NC}\n"
mkswap /dev/sda2
swapon /dev/sda2

printf "${CYAN}[*] ${GREEN}Mounting system partitions${NC}\n"
mount /dev/sda3 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

printf "${CYAN}[*] ${GREEN}Installing packages${NC}\n"
reflector --country France --latest 10 --sort rate --save /etc/pacman.d/mirrorlist 
pacstrap /mnt base base-devel linux-lts linux-firmware htop ntp net-tools vim nmap git openssh tmux lsb-release zsh fzf zsh-autosuggestions zsh-completions zsh-syntax-highlighting

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
echo "$1" > /mnt/etc/hostname
echo "127.0.0.1 $1" >> /mnt/etc/hosts

printf "${CYAN}[*] ${GREEN}Installing optionnal packages${NC}\n"
# Old hardware
pacstrap /mnt xf86-video-intel
# VMware
#pacstrap /mnt open-vm-tools xf86-input-vmmouse xf86-video-vmware mesa
# KDE
#pacstrap /mnt plasma yakuake dolphin spectacle kate networkmanager ark gwenview kolourpaint filelight dolphin-plugins kwalletmanager kcalc kcharselect kdialog krdc ktorrent okular partitionmanager krdp
## KDE minimal? 
#pacstrap /mnt plasma-desktop sddm sddm-kcm konsole dolphin networkmanager # yakuake dolphin
# extra
#pacstrap /mnt keepassxc firefox unzip discord docker dos2unix audacity filezilla gimp gnome-sound-recorder grc libreoffice-still ncdu networkmanager-openvpn obs-studio p7zip reflector rsync signal-desktop traceroute tree xclip zip vlc wget yt-dlp
## Gnome
#pacstrap /mnt gnome gnome-software-packagekit-plugin networkmanager
## LXDE
pacstrap /mnt lxde network-manager-applet networkmanager
cat <<EOT >> /mnt/etc/xdg/autostart/french-keyboard.desktop
[Desktop Entry]
Type=Application
Name=French keyboard layout
Exec=/usr/bin/setxkdbmap -layout "fr"
NoDisplay=True
EOT
cat <<EOT >> /mnt/etc/X11/xorg.conf.d/00-keyboard.conf  
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "fr"
EndSection
EOT

printf "${CYAN}[*] ${GREEN}Configuring boot with GRUB${NC}\n"
pacstrap /mnt grub
arch-chroot /mnt grub-install --target=i386-pc /dev/sda 
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

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
arch-chroot /mnt systemctl enable lxdm
arch-chroot /mnt systemctl enable NetworkManager

printf "${CYAN}[*] ${GREEN}Unmounting partitions ${NC}\n"
umount /dev/sda1
umount /dev/sda3

printf "${CYAN}[*] ${GREEN}Done. To have french keyboard in SDDM, run this as root after reboot : localectl set-x11-keymap fr${NC}\n"
