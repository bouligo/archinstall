printf "${CYAN}[*] Generating initramfs${NC}\n"
arch-chroot /mnt mkinitcpio -P
