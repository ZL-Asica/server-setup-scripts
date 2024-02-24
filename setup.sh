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

# Get the user's country code
country=$(curl -s https://ipapi.co/country/)


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
    apt-get update && apt-get install -y zsh wget curl git nano

    echo -e "${divider}"
    echo -e "${magenta}Installing oh-my-zsh...${plain}"
    echo -e "${divider}"

    # Check if oh-my-zsh is already installed
    if [ -d ~/.oh-my-zsh ]; then
        echo -e "${green}[+] oh-my-zsh is already installed.${plain}"
    else
        echo -e "${cyan}[-] oh-my-zsh is not installed.${plain}"
        # if user is in China mainland, India, or Russia, use the mirror site
        if [[ "$country" == "CN" ]] || [[ "$country" == "IN" ]] || [[ "$country" == "RU" ]]; then
            echo -e "${cyan}[-] You are in $country, using mirror site to download oh-my-zsh.${plain}"
            sh -c "$(curl -fsSL --retry 5 https://install.ohmyz.sh/)" "" --unattended
        else
            sh -c "$(curl -fsSL --retry 5 https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi

        # Install oh-my-zsh
        if [ $? -eq 0 ]; then
            echo -e "${green}[+] Successfully installed oh-my-zsh.${plain}"
        else
            echo -e "${red}[-] Failed to install oh-my-zsh.${plain}"
            error_exit "install_oh_my_zsh"
        fi
    fi

    # Install "powerlevel10k/powerlevel10k" theme
    # Remeber to install fonts "MesloLGS NF"
    echo -e "${divider}"
    echo -e "${magenta}Installing Powerlevel10k theme...${plain}"
    echo -e "${divider}"

    # Check if Powerlevel10k theme is already installed
    if [ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]; then
        echo -e "${green}[+] Powerlevel10k theme is already installed.${plain}"
    else
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

        # Get theme setting from preset
        curl -o ~/.p10k.zsh https://raw.githubusercontent.com/ZL-Asica/web-cdn/master/zsh/.p10k.zsh

        # Check file exist
        if [ -f ~/.p10k.zsh ]; then
            echo -e "${green}[+] Successfully installed Powerlevel10k theme.${plain}"
        else
            echo -e "${red}[-] Failed to install Powerlevel10k theme.${plain}"
            error_exit "install_theme_powerlevel10k"
        fi
    fi


    # Install plugins
    echo -e "${divider}"
    echo -e "${magenta}Installing plugins...${plain}"
    echo -e "${divider}"

    # Check git lobal config for LF
    if [ "$(git config --global core.autocrlf)" == "input" ]; then
        echo -e "${green}[+] LF for git newline is already set.${plain}"
    else
        echo -e "${cyan}[-] LF for git newline is not set.${plain}"
        git config --global core.autocrlf input
        echo -e "${green}[+] Successfully set LF for git newline.${plain}"
    fi
    
    if [ "$(git config --global core.eol)" == "lf" ]; then
        echo -e "${green}[+] LF for git eol is already set.${plain}"
    else
        echo -e "${cyan}[-] LF for git eol is not set.${plain}"
        git config --global core.eol lf
        echo -e "${green}[+] Successfully set LF for git eol.${plain}"
    fi

    # Install zsh-autosuggestions
    if [ -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then
        echo -e "${green}[+] zsh-autosuggestions is already installed.${plain}"
    else
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        # Check if file cloned successfully by check the file exist
        if [ -f ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
            echo -e "${green}[+] Successfully installed zsh-autosuggestions.${plain}"
        else
            echo -e "${red}[-] Failed to install zsh-autosuggestions.${plain}"
            error_exit "install_plugins"
        fi
    fi

    # Install zsh-syntax-highlighting
    if [ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
        echo -e "${green}[+] zsh-syntax-highlighting is already installed.${plain}"
    else
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        # Check if file cloned successfully by check the file exist
        if [ -f ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
            echo -e "${green}[+] Successfully installed zsh-syntax-highlighting.${plain}"
        else
            echo -e "${red}[-] Failed to install zsh-syntax-highlighting.${plain}"
            error_exit "install_plugins"
        fi
    fi

    echo -e "${divider}"
    echo -e "${magenta}Switching .zshrc...${plain}"
    echo -e "${divider}"

    # Backup the default .zshrc
    if [ -f ~/.zshrc ]; then
        mv ~/.zshrc ~/.zshrc.bak
        # Replace the default .zshrc with the custom .zshrc
        curl -o ~/.zshrc https://raw.githubusercontent.com/ZL-Asica/web-cdn/master/zsh/.zshrc
        echo -e "${green}[+] Successfully switched .zshrc.${plain}"
    else
        echo -e "${red}[-] Failed to switch .zshrc.${plain}"
        error_exit "switch_zshrc"
    fi

    # Set the default shell to zsh
    chsh -s $(which zsh)

    # Restart the shell with zsh
    exec zsh

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
    sudo ufw default deny incoming
    # Allow all outgoing traffic
    sudo ufw default allow outgoing
    # Allow SSH
    sudo ufw allow OpenSSH
    # Allow 80, 443
    sudo ufw allow 80 comment 'HTTP'
    sudo ufw allow 443 comment 'HTTPS'
    echo -e "${cyan}[+]Allowing ports${plain} 22, 80, 443\n${cyan}Denying all other incoming traffic${plain}"
    # Ask user whether disable ipv6 for UFW
    close_ipv6="n"
    read -p "${blue}Do you want to disable ipv6 for UFW? (y/n) - default no: ${plain}" close_ipv6
    if [ "${close_ipv6,,}" == "y" ]; then
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
            sudo ufw allow $port comment $comment
        fi
    done
    # Allow whitelisted IPs (current ssh connection ip)
    client_ip=$(echo $SSH_CONNECTION | awk '{ print $1 }')
    sudo ufw allow from $client_ip
    # Set UFW to start on boot
    sudo systemctl enable ufw
    # Enable UFW logging
    sudo ufw logging on

    # Enable UFW
    echo -e "${cyan}[+]Enabling UFW${plain}"
    sudo ufw enable


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
    nala install -y eza net-tools htop ca-certificates software-properties-common build-essential libelf-dev openssh-server


    # Docker and Docker Compose
    if [ "${install_docker,,}" == "y" ]; then
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

    # ask user to disable password authentication
    disable_password_auth="n"
    read -p "${blue}Do you want to disable password authentication for SSH? (y/n) - default no: ${plain}" disable_password_auth

    if [ "${disable_password_auth,,}" == "y" ]; then
        echo -e "${cyan}[+] Disabling password authentication for SSH${plain}"
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
        # Check if the line is already commented out
        if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config; then
            echo -e "${green}[+] Password authentication for SSH is already disabled${plain}"
        else
            echo -e "${red}[-] Failed to disable password authentication for SSH${plain}"
        fi
    else
        echo -e "${cyan}[+] Keeping password authentication for SSH${plain}"
    fi

    # Set the correct permissions for the SSH keys
    chmod 700 /etc/ssh
    chmod 600 /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_rsa_key
    chmod 644 /etc/ssh/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_rsa_key.pub
    # Restart the SSH service to apply the changes
    systemctl restart ssh
    # Reload ufw to apply the changes
    sudo ufw reload


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
    echo -e "${magena}Remember to replace user@hostname with your username and hostname (or IP address)${plain}"
    echo -e "${cyan}You can now connect to the server using SSH.${plain}"
}


ending_info() {
    echo -e "${divider}"
    echo -e "${green}Server setup (basic) is complete!${plain}"
    echo -e "${green}You can now connect to the server using SSH.${plain}"
    echo -e "${green}Remember to put your public key in ~/.ssh/authorized_keys in this server${plain}"
    echo -e "${magena}Use Nala to install packages and manage your server${plain}"
    echo -e "${magena}${divider}${plain}"
    echo -e "${magena}Remeber to install fonts ‘MesloLGS NF’ if you not installed yet or the terminal seems wired."
    echo -e "${cyan}https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    echo -e "${cyan}https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
    echo -e "${cyan}https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
    echo -e "${cyan}https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
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
    if [ "${install_zsh_prompt,,}" == "y" ]; then
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

# Welcome message
echo "" # New line for better readability
echo -e "${magenta}"
cat << "EOF"
 ______          _        _           
|__  / |        / \   ___(_) ___ __ _ 
  / /| |       / _ \ / __| |/ __/ _` |
 / /_| |___   / ___ \\__ \ | (_| (_| |
/____|_____| /_/   \_\___/_|\___\__,_|                                     

EOF

echo -e "${magenta}Server setup script (basic) - ZL Asica\n"
echo -e "https://github.com/ZL-Asica/server-setup-scripts${plain}\n" # Default welcome message

main
