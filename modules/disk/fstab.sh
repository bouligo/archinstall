printf "${CYAN}[*] Generating fstab${NC}\n"
genfstab -U /mnt >> /mnt/etc/fstab
