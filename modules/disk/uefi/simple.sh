printf "${CYAN}[*] partitionning disk${NC}\n"
user_disk_size=$(($(lsblk /dev/$user_disk -b -n -d -o size)/1024/1024))
ram_size=$(free -m | awk '/Mem:/ {print $2}')
efi_size=401 # 400 Mo (419430400)
default_swap_size=2048 # 2Go (2147483648)

# Disk smaller than 20Go, create small swap (10% of disk)
if [ $user_disk_size -lt 20480 ]; then
    printf "${RED}[-] Small disk detected${NC}\n"
    swap_size=$((user_disk_size/10))
    swap_offset=$((swap_size+efi_size+4))
else
    if [ $((user_disk_size/ram_size)) -gt 10 ]; then
        printf "${GREEN}[+] Very big disk detected, swap size will be equal to RAM size${NC}\n"
        swap_size=$ram_size
        swap_offset=$((ram_size+efi_size+4))
    else
        printf "${GREEN}[+] Big disk detected, swap size will be 2Go${NC}\n"
        swap_size=$default_swap_size
        swap_offset=$((default_swap_size+efi_size+4))
    fi
fi

parted -s /dev/$user_disk mklabel gpt mkpart primary fat32 1MiB "$efi_size"MiB mkpart primary linux-swap "$efi_size"MiB "$swap_offset"MiB mkpart primary ext4 "$swap_offset"MiB "100%" set 1 boot on

export partition_boot=$(lsblk /dev/$user_disk -x NAME | grep ':1' | awk '{print $1}')
export partition_swap=$(lsblk /dev/$user_disk -x NAME | grep ':2' | awk '{print $1}')
export partition_root=$(lsblk /dev/$user_disk -x NAME | grep ':3' | awk '{print $1}')


printf "${CYAN}[*] Formatting disk${NC}\n"
mkfs.fat -F32 "/dev/$partition_boot"
mkfs.ext4 "/dev/$partition_root"

printf "${CYAN}[*] Enabling swap partition${NC}\n"
mkswap "/dev/$partition_swap"
swapon "/dev/$partition_swap"

printf "${CYAN}[*] Mounting system partitions${NC}\n"
mount "/dev/$partition_root" /mnt
mkdir /mnt/boot
mount "/dev/$partition_boot" /mnt/boot
