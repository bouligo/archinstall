printf "${CYAN}[*] Changing shell for root and user $user_username ${NC}\n"
arch-chroot /mnt chsh "$user_username" -s /usr/bin/zsh
arch-chroot /mnt chsh root -s /usr/bin/zsh
