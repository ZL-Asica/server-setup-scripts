#!/bin/bash
#
# Setup script for a new server (basic)
# Copyright (C) 2019-2024 ZL Asica

# Define color codes for output
red=$(tput setaf 1)  # Error messages
green=$(tput setaf 2)  # Success messages
blue=$(tput setaf 4)  # Prompts and questions
magenta=$(tput setaf 5)  # Titles
cyan=$(tput setaf 6)  # Info messages
plain=$(tput sgr0)  # Reset color

divider="*********************************************************************"


# Function to display error messages and exit
error_exit() {
    local msg_key="$1"
    echo -e "${red}${messages[${lang}_$msg_key]}${plain}" >&2
    echo -e "${red}If you encounter any issues, \nlease report them at: https://github.com/ZL-Asica/server-setup-scripts/issues${plain}" >&2
    exit 1
}


# Detect system version, build, and architecture
detect_system() {
    # Below will get VERSION_ID for version, and ID for distribution
    . /etc/os-release
    # Check system, only support Ubuntu and Debian
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        echo -e "${red}Only Ubuntu and Debian are supported${plain}"
        echo -e "${red}Unsupported distribution: $ID - $VERSION_ID${plain}"
        error_exit "error_unsupported"
    fi
    arch=$(uname -m)
    # Check for ARM architecture
    [[ "$arch" != "x86_64" && "$arch" != "aarch64" ]] && error_exit "error_unsupported"
}


install_zsh_nala() {
    # Install zsh and oh-my-zsh
    apt-get install -y zsh wget curl git
    sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Install "powerlevel10k/powerlevel10k" theme
    # Remeber to install fonts "MesloLGS NF"
    # https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
    # https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
    # https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
    # https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
    # Get theme setting from preset
    wget -O ~/.p10k.zsh https://raw.githubusercontent.com/ZL-Asica/web-cdn/master/.p10k.zsh

    # Set default shell to zsh, default editor to nano
    chsh -s /bin/zsh
    apt-get install -y nano
    update-alternatives --install /usr/bin/editor editor /usr/bin/nano 100
    update-alternatives --set editor /usr/bin/nano

    ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"

    # Install zsh plugins
    # zsh-syntax-highlighting
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
    fi
    # zsh-autosuggestions
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
    fi

    # Add the plugins to the zshrc file
    if ! grep -q "zsh-syntax-highlighting" ~/.zshrc; then
        echo "source ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >>~/.zshrc
    fi

    if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
        echo "source ${ZSH_CUSTOM}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >>~/.zshrc
    fi

    # Source the zshrc file to apply the changes
    source ~/.zshrc

    # Install Nala package manager
    echo 'deb http://deb.volian.org/volian/ scar main' | tee /etc/apt/sources.list.d/nala.list
    wget -qO - http://deb.volian.org/volian/scar.key | apt-key add -
    apt-get update
    apt-get install nala -y

    # auto-fetch
    nala fetch --auto -y
    nala update && nala upgrade -y
}


sys_settings() {
    # Set the timezone based on ip and enable NTP
    timezone=$(curl -s https://ipapi.co/timezone)
    echo -e "${cyan}[+]Setting timezone to $timezone${plain}"
    nala install -y timedatectl ntp
    timedatectl set-timezone $timezone
    timedatectl set-ntp true

    # Set swap if it is not already set
    if [ ! -f /swapfile ]; then
        echo -e "${cyan}[+]Setting up swap${plain}"
        # If the server has less than 2GB of RAM, set up a swap file of 3GB
        # More than 2GB of RAM, set up a swap file equal to the amount of RAM
        if [ $(awk '/MemTotal/ {print $2}' /proc/meminfo) -lt 2000000 ]; then
            sudo fallocate -l 3G /swapfile
        else
            # If the server has more than 2GB of RAM, set up a swap file equal to the amount of RAM
            sudo fallocate -l $(awk '/MemTotal/ {print $2}' /proc/meminfo)k /swapfile
        fi
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        # Set swappiness to 10
        echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
    fi
}


securities_settings() {
    # Install and setup fail2ban
    nala install -y fail2ban
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local # Copy the default config to a local config
    systemctl enable fail2ban
    systemctl start fail2ban


    # Install and setup UFW
    nala install -y ufw
    # Deny all other incoming traffic
    ufw default deny incoming
    # Allow all outgoing traffic
    ufw default allow outgoing
    # Allow SSH
    ufw allow OpenSSH
    # Allow 80, 443
    ufw allow 80 comment 'HTTP'
    ufw allow 443 comment 'HTTPS'
    echo -e "${Cyan}[+]Allowing ports${plain} 22, 80, 443\n${Cyan}Denying all other incoming traffic${plain}"
    # Ask user whether disable ipv6 for UFW
    close_ipv6 = "n"
    read -p "${blue}Do you want to disable ipv6 for UFW? (y/n) - default no: ${plain}" close_ipv6
    if [ "$close_ipv6".lower() == "y" ]; then
        echo -e "${cyan}[+]Closing ipv6 in ufw${plain}"
        echo "IPV6=no" | sudo tee -a /etc/default/ufw
    else
        # Makesure ipv6 is enabled
        echo "IPV6=yes" | sudo tee -a /etc/default/ufw
    fi
    # Dead loop to allow more ports if needed
    while true; do
        read -p "${blue}Do you want to allow more ports? (if not, type 'n'; if yes, type the port number): ${plain}" port
        if [ "$port" == "n" ]; then
            break
        else
            # Set comment for the port
            read -p "${blue}Comment for the port: ${plain}" comment
            ufw allow $port comment $comment
        fi
    done
    # Allow whitelisted IPs (current ssh connection ip)
    ufw allow from $SSH_CONNECTION
    # Set UFW to start on boot
    systemctl enable ufw
    # Enable UFW logging
    ufw logging on


    # Setup Security Updates
    sudo nala install -y unattended-upgrades
    dpkg-reconfigure --priority=low unattended-upgrades
    # Enable automatic updates
    echo 'APT::Periodic::Update-Package-Lists "1";' | tee -a /etc/apt/apt.conf.d/20auto-upgrades
    echo 'APT::Periodic::Unattended-Upgrade "1";' | tee -a /etc/apt/apt.conf.d/20auto-upgrades


    # Harden the system by installing and configuring AppArmor
    sudo nala install -y apparmor apparmor-utils
    sudo aa-enforce /etc/apparmor.d/*
    sudo systemctl restart apparmor
}


common_packages_install() {
    # Docker
    install_docker="y"
    read -p "${blue}Install Docker? (y/n) - default yes: ${plain}" install_docker


    # Install common packages
    #  eza, net-tools, htop, nala-transport-https, ca-certificates, software-properties-common, build-essential, libelf-dev
    nala update && nala upgrade -y
    nala install -y gpg
    mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
    chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    nala update
    nala install -y eza net-tools htop nala-transport-https ca-certificates software-properties-common build-essential libelf-dev bashtop openssh-server


    # Docker and Docker Compose
    if [ "$install_docker".lower() == "y" ]; then
        echo -e "${cyan}[+] Installing Docker and Docker Compose${plain}"
        if [ "$ID" == "debian" ]; then
            for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do apt-get remove $pkg; done
            nala update
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
            chmod a+r /etc/apt/keyrings/docker.asc
            # Add the repository to Apt sources:
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                tee /etc/apt/sources.list.d/docker.list > /dev/null
        elif [ "$ID" == "ubuntu" ]; then
            for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt-get remove $pkg; done
            nala update
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            chmod a+r /etc/apt/keyrings/docker.asc
            # Add the repository to Apt sources:
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                tee /etc/apt/sources.list.d/docker.list > /dev/null
        fi
        nala update
        nala install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
    
    nala autoremove -y
}



openssh_settings() {
    systemctl enable ssh
    systemctl start ssh
    # Generate SSH keys for the server at /etc/ssh
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key < /dev/null
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key < /dev/null

    # Set the correct permissions for the SSH keys
    chmod 700 /etc/ssh
    chmod 600 /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_rsa_key
    chmod 644 /etc/ssh/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_rsa_key.pub
    # Restart the SSH service to apply the changes
    systemctl restart ssh


    echo -e "${cyan}[+] SSH keys have been generated${plain}"
    echo -e "${cyan}Here are the public keys:${plain}"
    echo -e "${cyan}\n\n\ned25519 (Recommended):${plain}"
    cat /etc/ssh/ssh_host_ed25519_key.pub
    echo -e "${cyan}\n\n\RSA (Older):${plain}"
    cat /etc/ssh/ssh_host_rsa_key.pub
    echo -e "${cyan}\n\n\n${plain}"

    echo -e "${cyan}Remember to put your public key in ~/.ssh/authorized_keys in this server${plain}"
    echo -e "${cyan}to allow you to connect to the server using SSH keys${plain}"
    echo -e "${divider}"
    echo -e "${magenta}\n\nIf you do not have ssh keys yet, you can generate them using the following command${plain}"
    echo -e "${green}ssh-keygen -t ed25519${plain}"
    echo -e "${cyan}This will generate a pair in ~/.ssh/ directory${plain}"
    echo -e "${cyan}The public key will be in ~/.ssh/id_ed25519.pub${plain}"
    echo -e "${divider}"
    echo -e "${cyan}\n\nUse this command to directly copy the public key to the server${plain}"
    echo -e "${green}cat ~/.ssh/id_ed25519.pub | ssh user@hostname \"mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys\"${plain}"
    echo -r "${magena}Remember to replace user@hostname with your username and hostname (or IP address)${plain}"
    echo -e "${cyan}You can now connect to the server using SSH.${plain}"
}


ending_info() {
    echo -e "${divider}"
    echo -e "${green}Server setup (basic) is complete!${plain}"
    echo -e "${green}You can now connect to the server using SSH.${plain}"
    echo -e "${green}Remember to put your public key in ~/.ssh/authorized_keys in this server${plain}"
    echo -e "${magena}Use Nala to install packages and manage your server${plain}"
    echo -e "${magena}${divider}${plain}"
    echo -e "${green}If this helped you, please consider giving it a star on GitHub!${plain}"
    echo -e "${green}https://github.com/ZL-Asica/server-setup-scripts${plain}"
}


main() {
    # Detect system version, build, and architecture
    detect_system


    # ask for desired hostname, default to not change
    hostname=""
    read -p "${blue}Enter the desired hostname (leave blank to keep the current hostname): ${plain}" hostname
    if [ "$hostname" != "" ]; then
        echo -e "${cyan}[+]Setting hostname to $hostname${plain}"
        sudo hostnamectl set-hostname $hostname
    fi

    # ask for wheteher install zsh, default to yes
    install_zsh_prompt="y"
    # Tell user about the benefits of zsh
    # Tell user we will default using theme (powerlevel10k) and plugins (zsh-syntax-highlighting, zsh-autosuggestions)
    # Also tell them we will set default editor to nano
    echo -e "${blue}Zsh is a shell designed for interactive use, and it is the default shell for the Nala package manager (if you want Nala you must install zsh)."
    echo -e "It is highly customizable and has many plugins and themes available."
    echo -e "We will install zsh and oh-my-zsh,\nand set the default shell to zsh."
    echo -e "We will also install the powerlevel10k theme, and the zsh-syntax-highlighting and zsh-autosuggestions plugins."
    echo -e "We will set the default editor to nano."
    read -p "Install zsh and Nala? (y/n) - must install otherwise Nala will not work: ${plain}" install_zsh_prompt
    if [ "$install_zsh_prompt".lower() == "y" ]; then
        install_zsh_nala
    else
        echo -e "${red}Nala requires zsh to be installed${plain}"
        error_exit "error_zsh"
    fi

    # Set the timezone, swap
    sys_settings

    # Install and configure security settings
    securities_settings

    # Common packages install
    common_packages_install

    # Configure OpenSSH
    openssh_settings

    # Ending info
    ending_info
}


# ----------------------------------------------------------
# Start of the script
# ----------------------------------------------------------

# Move focus to the top of the terminal without clearing the screen
printf '\033c'

# Ensure the script is run as root
[[ $EUID -ne 0 ]] && error_exit "error_root"

# Select language
echo "" # New line for better readability
echo -e "${pink}"
cat << "EOF"
 ______          _        _           
|__  / |        / \   ___(_) ___ __ _ 
  / /| |       / _ \ / __| |/ __/ _` |
 / /_| |___   / ___ \\__ \ | (_| (_| |
/____|_____| /_/   \_\___/_|\___\__,_|                                     

EOF

EOF
echo -e "${pink}Server setup script (basic) - ZL Asica\n"
echo -e "https://github.com/ZL-Asica/server-setup-scripts${plain}\n" # Default welcome message
