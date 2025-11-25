printf "${CYAN}[*] Installing KDE plasma${NC}\n"
pacstrap /mnt plasma yakuake dolphin spectacle kate networkmanager ark gwenview kolourpaint filelight dolphin-plugins kwalletmanager kcalc kcharselect kdialog okular partitionmanager krdp kio-admin kjournald ktorrent power-profiles-daemon

printf "${CYAN}[*] Enabling SDDM service${NC}\n"
arch-chroot /mnt systemctl enable sddm
