printf "${CYAN}[*] Installing blackarch repos for both archiso and final system${NC}\n"
curl https://blackarch.org/strap.sh -o /mnt/root/strap.sh
sed -i 's/pacman -S --noconfirm --needed blackarch-officials/# pacman -S --noconfirm --needed blackarch-officials/g' /mnt/root/strap.sh
chmod a+x /mnt/root/strap.sh
/mnt/root/strap.sh
arch-chroot /mnt bash /root/strap.sh
rm -f /mnt/var/cache/pacman/pkg/*
