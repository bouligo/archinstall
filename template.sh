# on reste volontairement en clavier qwerty pour taper le mot de passe luks tel quel

# on partitionne d'abord le disque avec fdisk
# une partition efi de 500m ou 1g et le reste en btrfs
fdisk -l


# Pour deux partitions, une ESP, et un ext4 basique
parted -s /dev/sda mklabel gpt mkpart primary fat32 1 500M mkpart primary 
ext4 500M "100%" set 1 boot on
# Sinon: 
fdisk /dev/sda
mkfs.fat -F32 /dev/sda1

# création du conteneur luks en luks1 pour la compat avec grub2
cryptsetup --type luks1 luksFormat /dev/sda2

# on déverrouille, formatte et monte le fs
cryptsetup open /dev/sda2 luks
mkfs.btrfs -L btrfs_root /dev/mapper/luks 
mount /dev/mapper/luks /mnt

# on crée les volumes btrfs
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
# btrfs subvolume create /mnt/@snapshots # plus besoin

# on démonte et on remonte comme dans la configuration cible
umount /mnt
mount -o compress=zstd,subvol=@,ssd,noatime /dev/mapper/luks /mnt
mkdir -p /mnt/home /mnt/boot/EFI
mount -o compress=zstd,subvol=@home,ssd,noatime /dev/mapper/luks /mnt/home
mount /dev/sda1 /mnt/boot/EFI

# Installation des packages
reflector --country France --country Germany --latest 10 --sort rate --save /etc/pacman.d/mirrorlist 
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs snapper htop ntp net-tools vim intel-ucode grub grub-btrfs efibootmgr nmap git openssh tmux lsb-release zsh fzf zsh-autosuggestions zsh-completions zsh-syntax-highlighting

# Génération fstab
genfstab -U /mnt >> /mnt/etc/fstab

# configuration langues, timezone, hostname
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
sed -i -e "s/#en_US.UTF-8/en_US.UTF-8/g" -e "s/#fr_FR.UTF-8/fr_FR.UTF-8/g" /etc/locale.gen

locale-gen
echo 'LANG="fr_FR.UTF-8"' > /etc/locale.conf
echo 'LANGUAGE="fr_FR"' >> /etc/locale.conf
echo 'KEYMAP=fr' > /etc/vconsole.conf 
echo 'hostname' > /etc/hostname
echo '127.0.0.1 hostname' >> /etc/hosts
exit 

# VMware
pacstrap /mnt open-vm-tools xf86-input-vmmouse xf86-video-vmware mesa
# KDE
pacstrap /mnt plasma yakuake dolphin spectacle kate networkmanager ark gwenview kolourpaint filelight dolphin-plugins kwalletmanager kcalc kcharselect kdialog krdc ktorrent okular partitionmanager krdp
# KDE minimal? 
pacstrap /mnt plasma-desktop sddm sddm-kcm konsole dolphin
# extra
pacstrap /mnt firefox unzip gparted
# Gnome
pacstrap /mnt gnome gnome-software-packagekit-plugin networkmanager

# configuration de l'initramfs (/etc/mkinitcpio.conf) 
BINARIES=(/usr/bin/btrfs)
FILES=(/crypto_keyfile.bin)
HOOKS="base udev autodetect modconf block encrypt filesystems keyboard fsck" 

# création d'un fichier clé qui sera dans l'initramfs
dd bs=512 count=4 if=/dev/random of=/mnt/crypto_keyfile.bin
cryptsetup luksAddKey /dev/sda2 /mnt/crypto_keyfile.bin 
arch-chroot /mnt
mkinitcpio -P
chmod 000 /crypto_keyfile.bin

# configuration de grub /etc/default/grub 
GRUB_ENABLE_CRYPTODISK=y
GRUB_CMDLINE_LINUX="cryptdevice=/dev/sda2:luks" 

grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=BOOT
grub-mkconfig -o /boot/grub/grub.cfg

# gestion users
passwd
useradd -m almazys
passwd almazys

# pour le trim
systemctl enable fstrim.timer

# optionnel
systemctl enable sddm
systemctl enable NetworkManager
systemctl enable vmtoolsd
localectl set-x11-keymap fr