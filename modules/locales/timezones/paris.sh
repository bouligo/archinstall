printf "${CYAN}[*] Configuring timezone${NC}\n"
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
arch-chroot /mnt hwclock --systohc
