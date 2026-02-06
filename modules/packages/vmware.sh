printf "${CYAN}[*] Installing VMware utilities${NC}\n"
pacstrap /mnt open-vm-tools xf86-input-vmmouse xf86-video-vmware mesa
arch-chroot /mnt systemctl enable vmtoolsd
