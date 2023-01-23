#!/bin/sh

if [ -z "$2" ]; then
	echo "Usage: $0 hostname user"
	exit 1
fi

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

printf "${CYAN}[*] ${GREEN}Formatting disk${NC}\n"
# Pour deux partitions, une ESP, et une partition principale
parted -s /dev/nvme0n1 mklabel gpt mkpart primary fat32 1 500M mkpart primary ext4 500M "100%" set 1 boot on
## With swap
# parted -s /dev/nvme0n1 mklabel gpt mkpart primary fat32 1 500MB mkpart primary linux-swap 500M 2GB mkpart primary ext4 2GB "100%" set 1 boot on

mkfs.fat -F32 /dev/nvme0n1p1

printf "${CYAN}[*] ${GREEN}Creating luks encrypted volume${NC}\n"
cryptsetup --type luks1 luksFormat /dev/nvme0n1p2
printf "${CYAN}[*] ${GREEN}Opening luks encrypted volume${NC}\n"
cryptsetup open /dev/nvme0n1p2 luks

printf "${CYAN}[*] ${GREEN}Creating LVM volume${NC}\n"
pvcreate -ff /dev/mapper/luks
vgcreate ArchLinux /dev/mapper/luks
lvcreate -L 8G ArchLinux -n swap
lvcreate -L 300G ArchLinux -n root
lvcreate -l 100%FREE ArchLinux -n home

mkfs.ext4 /dev/ArchLinux/root
mkfs.ext4 /dev/ArchLinux/home

printf "${CYAN}[*] ${GREEN}Mounting system partitions${NC}\n"
mount /dev/ArchLinux/root /mnt
mkdir -p /mnt/boot/EFI
mkdir -p /mnt/home
mount /dev/nvme0n1p1 /mnt/boot/EFI
mount /dev/ArchLinux/home /mnt/home

printf "${CYAN}[*] ${GREEN}Enabling swap partition${NC}\n"
mkswap /dev/ArchLinux/swap
swapon /dev/ArchLinux/swap

printf "${CYAN}[*] ${GREEN}Installing packages${NC}\n"
reflector --country France --latest 10 --sort rate --save /etc/pacman.d/mirrorlist 
pacstrap /mnt base base-devel linux linux-firmware linux-headers lvm2 htop net-tools vim intel-ucode grub efibootmgr nmap git openssh tmux lsb-release zsh fzf zsh-autosuggestions zsh-completions zsh-syntax-highlighting

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

printf "${CYAN}[*] ${GREEN}Installing blackarch repos${NC}\n"
curl https://blackarch.org/strap.sh -o /mnt/root/strap.sh
bash /mnt/root/strap.sh
arch-chroot /mnt bash /root/strap.sh

printf "${CYAN}[*] ${GREEN}Installing optionnal packages${NC}\n"
## VMware
#pacstrap /mnt open-vm-tools xf86-input-vmmouse xf86-video-vmware mesa
# KDE
pacstrap /mnt plasma yakuake dolphin spectacle kate networkmanager ark gwenview kolourpaint filelight dolphin-plugins kwalletmanager kcalc kcharselect kdialog krdc ktorrent okular
## KDE minimal? 
#pacstrap /mnt plasma-desktop sddm sddm-kcm konsole dolphin
# extra
pacstrap /mnt keepass firefox unzip gparted discord docker dos2unix audacity filezilla gimp gnome-sound-recorder grc libreoffice-still ncdu networkmanager-openvpn obs-studio  p7zip reflector rsync signal-desktop tlp traceroute tree xclip youtube-dl zip vlc wget 
## Gnome
#pacstrap /mnt gnome gnome-software-packagekit-plugin networkmanager
# Offsec + custom
pacstrap /mnt impacket acpi aircrack-ng aria2 bettercap bind binwalk cmatrix code davtest dbeaver dcfldd dirb enum4linux-ng evil-winrm ffuf freerdp ghidra go hdparm hydra iotop ipcalc iperf3 jq kerbrute kgpg masscan metasploit mitmproxy mtr nikto noto-fonts-emoji nuclei openconnect parallel patchelf php pigz proxychains pycharm-community-edition pyenv python-jsbeautifier python-pipx python-poetry qtcreator scapy soapui sqlmap strace stress subfinder texlive-most upx virtualbox wireshark-qt mingw-w64-gcc

printf "${CYAN}[*] ${GREEN}Setting up enciphered startup${NC}\n"
dd bs=512 count=4 if=/dev/random of=/mnt/crypto_keyfile.bin
cryptsetup luksAddKey /dev/nvme0n1p2 /mnt/crypto_keyfile.bin 

sed -i 's#FILES=()#FILES=(/crypto_keyfile.bin)#g' /mnt/etc/mkinitcpio.conf
sed -i 's#filesystems#encrypt lvm2 filesystems#g' /mnt/etc/mkinitcpio.conf
sed -i 's/#GRUB_ENABLE_CRYPTODISK=./GRUB_ENABLE_CRYPTODISK=y/g' /mnt/etc/default/grub
sed -i 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="cryptdevice=/dev/nvme0n1p2:luks"#g' /mnt/etc/default/grub

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

printf "${CYAN}[*] ${GREEN}Installing Oh-My-ZSH for user $2${NC}\n"
arch-chroot /mnt su "$2" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"' < /dev/null

printf "${CYAN}[*] ${GREEN}Enabling services${NC}\n"
arch-chroot /mnt systemctl enable fstrim.timer
arch-chroot /mnt systemctl enable sddm
arch-chroot /mnt systemctl enable NetworkManager

printf "${CYAN}[*] ${GREEN}Umounting filesystems and closing LUKS volume${NC}\n"
umount /mnt/boot/EFI
umount /mnt/home
umount /mnt
cryptsetup close /dev/mapper/luks

printf "${CYAN}[*] ${GREEN}Done. To have french keyboard in SDDM, run this as root after reboot : localectl set-x11-keymap fr${NC}\n"