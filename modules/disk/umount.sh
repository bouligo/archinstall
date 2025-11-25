printf "${CYAN}[*] Umounting filesystems${NC}\n"
umount "/dev/$partition_boot"

if [ -v lvm_root ]; then
    if declare -p lvm_extra_partitions 2> /dev/null | grep -q 'declare -A'; then
        for fs in "${lvm_extra_partitions[@]}"; do
            umount /dev/$fs
        done
    fi
    umount "/dev/$lvm_root"
else
    umount "/dev/$partition_root"
fi

if cryptsetup luksDump "/dev/$partition_root" 2> /dev/null; then
    printf "${CYAN}[*] Closing LUKS volume${NC}\n"
    cryptsetup close /dev/mapper/luks
fi
