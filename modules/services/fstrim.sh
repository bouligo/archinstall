printf "${CYAN}[*] Enabling fstrim timer service${NC}\n"
arch-chroot /mnt systemctl enable fstrim.timer
