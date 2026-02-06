printf "${CYAN}[*] Enabling autologin for user $3 in SDDM ${NC}\n"

mkdir /mnt/etc/sddm.conf.d/
cat <<EOT >> /mnt/etc/sddm.conf.d/kde_settings.conf
[Autologin]
Relogin=false
Session=plasma
User=$3

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=breeze

[Users]
MaximumUid=60513
MinimumUid=1000
EOT
