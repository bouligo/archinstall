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

parted -s /dev/$user_disk mklabel gpt mkpart primary fat32 1MiB "$efi_size"MiB mkpart primary "$efi_size"MiB "100%" set 1 boot on set 2 lvm on

export partition_boot=$(lsblk /dev/$user_disk -x NAME | grep ':1' | awk '{print $1}')
export partition_root=$(lsblk /dev/$user_disk -x NAME | grep ':2' | awk '{print $1}')
declare -A lvm_extra_partitions
export lvm_extra_partitions


####################################################
printf "${CYAN}[*] Creating luks encrypted volume${NC}\n"
cryptsetup --type luks1 luksFormat "/dev/$partition_root"
printf "${CYAN}[*] Opening luks encrypted volume${NC}\n"
cryptsetup open "/dev/$partition_root" luks


####################################################
printf "${CYAN}[*] Formatting partitions and creating LVM volume${NC}\n"
mkfs.fat -F32 "/dev/$partition_boot"
pvcreate -ff /dev/mapper/luks
vgcreate ArchLinux /dev/mapper/luks
lvcreate -L "$swap_size"MiB ArchLinux -n swap

# Disk smaller than 50Go
if [ $user_disk_size -lt 51200 ]; then
    printf "${RED}[-] Small disk detected, creating only root partition${NC}\n"
    lvcreate -l 100%FREE ArchLinux -n root
else
    printf "${GREEN}[+] Big disk detected, creating root and home partitions${NC}\n"
    lvcreate -L 40G ArchLinux -n root
    lvcreate -l 100%FREE ArchLinux -n home
    lvm_extra_partitions["home"]="ArchLinux/home"
fi
export lvm_root="ArchLinux/root"

####################################################
printf "${CYAN}[*] Formatting disk${NC}\n"
mkfs.ext4 "/dev/$lvm_root"
if declare -p lvm_extra_partitions 2> /dev/null | grep -q 'declare -A'; then
    if [ "${lvm_extra_partitions['home']+_}" ]; then
        mkfs.ext4 "/dev/${lvm_extra_partitions['home']}"
    fi
fi

####################################################
printf "${CYAN}[*] Enabling swap partition${NC}\n"
export partition_swap="ArchLinux/swap"
mkswap "/dev/$partition_swap"
swapon "/dev/$partition_swap"

####################################################
printf "${CYAN}[*] Mounting system partitions${NC}\n"
mount "/dev/$lvm_root" /mnt
mkdir /mnt/boot
mount "/dev/$partition_boot" /mnt/boot

if declare -p lvm_extra_partitions 2> /dev/null | grep -q 'declare -A'; then
    if [ "${lvm_extra_partitions['home']+_}" ]; then
        mkdir -p /mnt/home
        mount "/dev/${lvm_extra_partitions['home']}" /mnt/home
    fi
fi
