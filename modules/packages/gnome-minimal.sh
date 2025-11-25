printf "${CYAN}[*] Installing gnome essentials${NC}\n"
pacstrap /mnt gnome networkmanager

printf "${CYAN}[*] Enabling GDM service${NC}\n"
arch-chroot /mnt systemctl enable gdm
