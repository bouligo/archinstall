printf "${CYAN}[*] Installing KDE plasma${NC}\n"
pacstrap /mnt plasma yakuake dolphin spectacle kate networkmanager ark gwenview kolourpaint filelight dolphin-plugins kwalletmanager kcalc kcharselect kdialog okular partitionmanager krdp kio-admin kjournald ktorrent power-profiles-daemon kcron

printf "${CYAN}[*] Enabling SDDM service${NC}\n"
arch-chroot /mnt systemctl enable sddm

mkdir -p /mnt/etc/sddm.conf.d/
cat <<EOT >> /mnt/etc/sddm.conf.d/kde_settings.conf
[Autologin]
Relogin=false
Session=
User=

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=breeze

[Users]
MaximumUid=60513
MinimumUid=1000
EOT