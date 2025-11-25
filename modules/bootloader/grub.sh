source ./modules/packages/grub.sh

printf "${CYAN}[*] Configuring grub${NC}\n"
sed -i 's/quiet//g' /mnt/etc/default/grub

if [ -v lvm_root ]; then
    pacstrap /mnt lvm2
    sed -i 's/\(GRUB_PRELOAD_MODULES=.*\)"/\1 lvm"/g' /mnt/etc/default/grub
    sed -i 's#filesystems#lvm2 filesystems#g' /mnt/etc/mkinitcpio.conf
    arch-chroot /mnt mkinitcpio -P
fi

if cryptsetup luksDump "/dev/$partition_root" 2> /dev/null; then
    printf "${CYAN}[*] ${GREEN}Setting up enciphered startup${NC}\n"
    dd bs=512 count=4 if=/dev/random of=/mnt/crypto_keyfile.bin
    cryptsetup luksAddKey "/dev/$partition_root" /mnt/crypto_keyfile.bin

    sed -i 's#FILES=()#FILES=(/crypto_keyfile.bin)#g' /mnt/etc/mkinitcpio.conf
    sed -i 's#lvm2 ##g' /mnt/etc/mkinitcpio.conf  # Remove lvm2 as it may have been inserted ealier
    sed -i 's#filesystems#sd-encrypt lvm2 filesystems#g' /mnt/etc/mkinitcpio.conf
    sed -i 's/#GRUB_ENABLE_CRYPTODISK=./GRUB_ENABLE_CRYPTODISK=y/g' /mnt/etc/default/grub
    root_uuid=$(blkid -s UUID -o value "/dev/$partition_root")
    sed -i 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="rd.luks.uuid='"$root_uuid"' root=/dev/'"$lvm_root"'"#g' /mnt/etc/default/grub

    arch-chroot /mnt mkinitcpio -P
    chmod 000 /mnt/crypto_keyfile.bin

    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=BOOT
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
else
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=BOOT
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    printf "${CYAN}[*] Fixing potential errors for shitty hardware${NC}\n"
    cp /mnt/boot/EFI/BOOT/grubx64.efi /mnt/boot/EFI/BOOT/bootx64.efi
fi
