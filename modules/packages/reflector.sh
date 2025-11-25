printf "${CYAN}[*] Updating mirrors for liveiso${NC}\n"
reflector --country France --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
