printf "${CYAN}[*] Disabling coredumps on disk${NC}\n"
mkdir /mnt/etc/systemd/coredump.conf.d
echo "[Coredump]" > /mnt/etc/systemd/coredump.conf.d/custom.conf
echo "Storage=none" >> /mnt/etc/systemd/coredump.conf.d/custom.conf
echo "ProcessSizeMax=0" >> /mnt/etc/systemd/coredump.conf.d/custom.conf