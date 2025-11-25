printf "${CYAN}[*] Installing Oh-My-ZSH for user $user_username${NC}\n"
arch-chroot /mnt su "$user_username" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"' < /dev/null
sed -i 's/ZSH_THEME=".*/ZSH_THEME="tjkirch_mod"/g' "/mnt/home/$user_username/.zshrc"

printf "${CYAN}[*] Installing Oh-My-ZSH for root${NC}\n"
arch-chroot /mnt sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" < /dev/null
sed -i 's/ZSH_THEME=".*/ZSH_THEME="tjkirch_mod"/g' /mnt/root/.zshrc
