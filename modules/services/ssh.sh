printf "${CYAN}[*] Enabling sshd service${NC}\n"
arch-chroot /mnt systemctl enable sshd
