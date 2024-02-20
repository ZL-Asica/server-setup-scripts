#!/bin/zsh
#
# Setup script for macOS oh-my-zsh
# Copyright (C) 2019-2024 ZL Asica



# BUGS
# 1. .zshrc替换
#     a. 替换oh my zsh安装后的
#     b. 删除下面的echo添加语句
#     c. 更改默认编辑器为nano
# 2. 字体安装问题：让用户自己安装，无法自动安装

# Define color codes for output
red=$(tput setaf 1)  # Error messages
green=$(tput setaf 2)  # Success messages
blue=$(tput setaf 4)  # Prompts and questions
magenta=$(tput setaf 5)  # Titles
cyan=$(tput setaf 6)  # Info messages
plain=$(tput sgr0)  # Reset color

divider="*********************************************************************"

# Define the current_shell variable
current_shell=$SHELL

# Get the user's country code
country=$(curl -s https://ipapi.co/country/)

# Function to display error messages and exit
error_exit() {
    local msg_key="$1"
    echo -e "${red}${messages[${lang}_$msg_key]}${plain}" >&2
    echo -e "${red}If you encounter any issues, \nlease report them at: https://github.com/ZL-Asica/server-setup-scripts/issues${plain}" >&2
    exit 1
}


font_install() {
    echo -e "${divider}"
    echo -e "${magenta}Installing fonts...${plain}"
    echo -e "${divider}"

    # Fonts' urls
    FONT_URLS=(
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
    )

    # jsDelivr CDN
    FONT_URLS_MIRROR=(
        "https://cdn.jsdelivr.net/gh/romkatv/powerlevel10k-media/MesloLGS%20NF%20Regular.ttf"
        "https://cdn.jsdelivr.net/gh/romkatv/powerlevel10k-media/MesloLGS%20NF%20Bold.ttf"
        "https://cdn.jsdelivr.net/gh/romkatv/powerlevel10k-media/MesloLGS%20NF%20Italic.ttf"
        "https://cdn.jsdelivr.net/gh/romkatv/powerlevel10k-media/MesloLGS%20NF%20Bold%20Italic.ttf"
    )

    # Fonts install path
    FONT_DIR="$HOME/Library/Fonts"

    # Create the directory if it doesn't exist
    if [ ! -d "$FONT_DIR" ]; then
        mkdir -p "$FONT_DIR"
    fi

    # Download and install the fonts
    if [[ "$country" == "CN" ]] || [[ "$country" == "IN" ]] || [[ "$country" == "RU" ]]; then
        FONT_URLS=("${FONT_URLS_MIRROR[@]}")
    fi

    # Use for loop to download and install fonts
    for font_url in "${FONT_URLS[@]}"; do
        # Get the font file name(removing %20 and replacing with space)
        font_file=$(echo $font_url | awk -F'/' '{print $NF}' | sed 's/%20/ /g')

        # Check if is already installed
        if [ -f "$FONT_DIR/$font_file" ]; then
            echo -e "${green}[+] $font_file is already installed.${plain}"
        else
            # Download the font
            curl -o "$FONT_DIR/$font_file" -fsSL "$font_url"
            # Check if the font was downloaded successfully
            if [ -f "$FONT_DIR/$font_file" ]; then
                echo -e "${green}[+] Successfully installed $font_file.${plain}"
            else
                echo -e "${red}[-] Failed to install $font_file.${plain}"
                error_exit "font_install"
            fi
        fi
    done
}


change_zsh() {
    echo -e "${divider}"
    echo -e "${magenta}Current Shell: ${current_shell}${plain}"
    echo -e "${divider}"

    # Check if zsh is already the default shell
    if [[ "$current_shell" == *"/zsh"* ]]; then
        echo -e "${green}[+] zsh is already the default shell.${plain}"
    else
        echo -e "${cyan}[-] zsh is not the default shell.${plain}"
        # Change the default shell to zsh
        chsh -s $(which zsh)
        if [ $? -eq 0 ]; then
            echo -e "${green}[+] Successfully changed the default shell to zsh.${plain}"
        else
            echo -e "${red}[-] Failed to change the default shell to zsh.${plain}"
            error_exit "change_shell"
        fi
    fi
}

install_oh_my_zsh() {
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
            sh -c "$(curl -fsSL https://install.ohmyz.sh/)" "" --unattended
        else
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi

        # Install oh-my-zsh
        if [ $? -eq 0 ]; then
            echo -e "${green}[+] Successfully installed oh-my-zsh.${plain}"
        else
            echo -e "${red}[-] Failed to install oh-my-zsh.${plain}"
            error_exit "install_oh_my_zsh"
        fi
    fi
}

install_theme_powerlevel10k() {
    echo -e "${divider}"
    echo -e "${magenta}Installing Powerlevel10k theme...${plain}"
    echo -e "${divider}"

    # Check if Powerlevel10k theme is already installed
    if [ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]; then
        echo -e "${green}[+] Powerlevel10k theme is already installed.${plain}"
    else
        # Install Powerlevel10k theme
        # Install "powerlevel10k/powerlevel10k" theme
        # Remeber to install fonts "MesloLGS NF"
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
}


install_plugins() {
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
}


switch_zshrc() {
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
}


ending_info() {
    echo -e "${divider}"
    echo -e "${green}macOS oh-my-zsh install and config is complete!${plain}"
    echo -e "${green}We activate plugins include "command-not-found", "cp", "extract", "gitignore", "safe-paste", "zsh-autosuggestions", "zsh-syntax-highlighting".${plain}"
    echo -e "${blue}You can modify the plugin list in ~/.zshrc, find the line starts with 'plugins=(' and ends with ')'.${plain}"
    echo -e "${blue}You can also modify the theme setting in ~/.p10k.zsh.${plain}"
    echo -e "${cyan}Use 'extract' to extract any compressed file with one command.${plain}"
    echo -e "${cyan}Use 'cp' to copy files and directories with progress bar.${plain}"
    echo -e "${cyan}Use 'gi TEMPLATE' to generate .gitignore file with one command.${plain}"
    echo -e "${cyan}Font 'MesloLGS NF' is already installed, you can set it as the default font in your terminal if your terminal looks weird.${plain}"
    echo -e "${magenta}${divider}${plain}"
    echo -e "${green}Please restart your terminal to see the changes.${plain}"
    echo -e "${green}Or you can run 'source ~/.zshrc' to apply the changes without restarting.${plain}"
    echo -e "${green}If you previously have a .zshrc file, it will be replaced by the custom .zshrc file. Your original .zshrc file will be backed up as .zshrc.bak.${plain}"
    echo -e "${green}Remember to add your own configurations to the new .zshrc file.${plain}"
    echo -e "${magenta}${divider}${plain}"
    echo -e "${green}If this helped you, please consider giving it a star on GitHub!${plain}"
    echo -e "${green}https://github.com/ZL-Asica/server-setup-scripts${plain}"
}


# Main function
main() {
    echo ""
    echo ""
    echo -e "${divider}"
    echo -e "${magenta}Starting the macOS oh-my-zsh setup...${plain}"
    echo -e "${divider}"
    echo -e "${cyan}This script will install oh-my-zsh, Powerlevel10k theme, and some useful plugins.${plain}"
    echo -e "${cyan}It will also change the default shell to zsh and set sublime(or nano if sublime not installed) as the default editor.${plain}"
    echo -e "${cyan}It will also set LF for git newline and eol.${plain}"

    read -p "$(echo -e ${blue}"Do you want to continue? (y/n)${plain}")" -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${cyan}[+] Starting the setup...${plain}"
    else
        echo -e "${red}[-] Setup aborted.${plain}"
        error_exit "setup_aborted"
    fi

    
    font_install
    change_zsh
    install_oh_my_zsh
    install_theme_powerlevel10k
    default_editor
    install_plugins
    switch_zshrc
    ending_info
}


# ----------------------------------------------------------
# Start of the script
# ----------------------------------------------------------

# Move focus to the top of the terminal without clearing the screen
printf '\033c'

# Ensure the script is run not as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${red}[-] Do not run this script as root!${plain}"
    exit 1
fi

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

echo -e "${magenta}macOS oh-my-zsh setup script - ZL Asica${plain}"
echo -e "https://github.com/ZL-Asica/server-setup-scripts/blob/main/mac_oh-my-zsh.sh"

main
