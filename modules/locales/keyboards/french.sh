printf "${CYAN}[*] Configuring french keyboard${NC}\n"
echo 'KEYMAP=fr' > /mnt/etc/vconsole.conf

printf "${CYAN}[*] Configuring french keyboard for X11 apps${NC}\n"
mkdir -p /mnt/etc/X11/xorg.conf.d
cat <<EOT >> /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "fr"
EndSection
EOT

loadkeys fr
