printf "${CYAN}[*] Creating user $user_username in wheel group${NC}\n"
arch-chroot /mnt useradd -m "$user_username"
arch-chroot /mnt usermod -a -G wheel "$user_username"
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /mnt/etc/sudoers
arch-chroot /mnt passwd "$user_username"
