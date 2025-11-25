printf "${CYAN}[*] Setting hostname${NC}\n"
printf "$user_hostname" > /mnt/etc/hostname
printf "127.0.0.1 $user_hostname" >> /mnt/etc/hosts
