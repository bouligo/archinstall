printf "${CYAN}[*] Installing yay${NC}\n"
pacstrap /mnt git go
mkdir -p /mnt/opt/yay
arch-chroot /mnt git clone https://aur.archlinux.org/yay.git /opt/yay
arch-chroot /mnt chown -R "$user_username":"$user_username" /opt/yay
arch-chroot /mnt su - "$user_username" -c 'cd /opt/yay; makepkg -s'
pacstrap -U /mnt /mnt/opt/yay/yay*.zst
