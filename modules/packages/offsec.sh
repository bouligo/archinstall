bash ./modules/packages/blackarch.sh

printf "${CYAN}[*] Installing offensive tools (requires blackarch repositories)${NC}\n"
pacstrap /mnt impacket networkmanager-openconnect acpi aircrack-ng bettercap bind binwalk cmatrix davtest dbeaver dirb enum4linux-ng evil-winrm ffuf ghidra go hdparm hydra ipcalc iperf3 jq kerbrute masscan metasploit mitmproxy mtr nikto noto-fonts-emoji nuclei openconnect parallel patchelf php proxychains pyenv python-jsbeautifier python-pipx python-pipenv scapy soapui sqlmap strace stress subfinder upx wireshark-qt mingw-w64-gcc
