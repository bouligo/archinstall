printf "${CYAN}[*] Installing gnome and related apps${NC}\n"
pacstrap /mnt gnome gnome-circle gnome-extra

printf "${CYAN}[*] Enabling GDM service${NC}\n"
arch-chroot /mnt systemctl enable gdm
