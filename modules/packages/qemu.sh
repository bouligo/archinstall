printf "${CYAN}[*] Installing Qemu utilities${NC}\n"
pacstrap /mnt qemu-guest-agent spice-vdagent
arch-chroot /mnt systemctl enable qemu-guest-agent
