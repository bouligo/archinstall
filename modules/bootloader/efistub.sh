source ./modules/packages/efi.sh

printf "${CYAN}[*] Configuring EFI boot${NC}\n"
loader=$(ls /mnt/boot/vmlinuz* | head -n1 | sed -e 's#.*/##g')  # In case several kernels are installed
imgs=$(ls /mnt/boot/*.img | grep -v fallback | sed -e 's#.*/##g' -e 's/^/initrd=\\/g' | tr '\n' ' ')

if [ -v lvm_root ]; then
    pacstrap /mnt lvm2
    sed -i 's#filesystems#lvm2 filesystems#g' /mnt/etc/mkinitcpio.conf
    arch-chroot /mnt mkinitcpio -P
    root_uuid=$(blkid -s UUID -o value "/dev/$lvm_root")
else
    root_uuid=$(blkid -s UUID -o value "/dev/$partition_root")
fi

if cryptsetup luksDump "/dev/$partition_root" 2> /dev/null; then
    printf "${CYAN}[*] Setting up enciphered startup${NC}\n"
    sed -i 's#lvm2 ##g' /mnt/etc/mkinitcpio.conf  # Remove lvm2 as it may have been inserted ealier
    sed -i 's#filesystems#sd-encrypt lvm2 filesystems#g' /mnt/etc/mkinitcpio.conf
    arch-chroot /mnt mkinitcpio -P
    root_uuid=$(blkid -s UUID -o value "/dev/$partition_root")  # As we have both lvm AND luks, this line must prevail
    efibootmgr --create --disk /dev/$user_disk --part 1 --label "ArchLinux" --loader /$loader --unicode "rd.luks.uuid=$root_uuid root=/dev/$lvm_root rw $imgs"
else
    efibootmgr --create --disk /dev/$user_disk --part 1 --label "ArchLinux" --loader /$loader --unicode "root=UUID=$root_uuid rw $imgs"
fi

efibootmgr -D
