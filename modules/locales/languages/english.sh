printf "${CYAN}[*] Enabling english language${NC}\n"
sed -i "s/#en_US.UTF-8/en_US.UTF-8/g" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

echo 'LANG="en_US.UTF-8"' > /mnt/etc/locale.conf
echo 'LANGUAGE="en_US"' >> /mnt/etc/locale.conf
