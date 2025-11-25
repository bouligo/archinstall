printf "${CYAN}[*] Enabling french language${NC}\n"
sed -i "s/#fr_FR.UTF-8/fr_FR.UTF-8/g" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

echo 'LANG="fr_FR.UTF-8"' > /mnt/etc/locale.conf
echo 'LANGUAGE="fr_FR"' >> /mnt/etc/locale.conf
