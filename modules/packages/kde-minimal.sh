printf "${CYAN}[*] Installing KDE plasma essentials${NC}\n"
pacstrap /mnt plasma-desktop sddm sddm-kcm konsole dolphin

printf "${CYAN}[*] Enabling SDDM service${NC}\n"
arch-chroot /mnt systemctl enable sddm
