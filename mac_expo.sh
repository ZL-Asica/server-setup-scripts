#!/bin/zsh
#
# Setup script for macOS Expo development
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
    echo -e "${red}[---] If you encounter any issues, \nlease report them at: https://github.com/ZL-Asica/server-setup-scripts/issues${plain}" >&2
    exit 1
}


# Check Xcode
xcode_install() {
    if test ! $(which xcode-select); then
        echo -e "${blue}[+] Installing Xcode...${plain}"
        xcode-select --install
        # Wait for the installation to complete
        until test $(which xcode-select); do
            sleep 5
        done
    else
        echo -e "${green}[+++] Xcode already installed. Skipping...${plain}"
    fi
}


# Check homebrew
homebrew_install() {
    if test ! $(which brew); then
        echo -e "${blue}[+] Installing Homebrew...${plain}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add homebrew to the path
        echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
        # Activate the changes
        source ~/.zshrc
    else
        echo -e "${green}[+++] Homebrew already installed. Skipping...${plain}"
    fi
}


# node, watchman
node_watchman_install() {
    # Check node
    if test ! $(which node); then
        echo -e "${blue}[+] Installing node...${plain}"
        brew install nvm
        # Create .nvm directory and set the path
        mkdir ~/.nvm
        echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
        echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"' >> ~/.zshrc
        echo '[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"' >> ~/.zshrc
        # Activate the changes
        source ~/.zshrc
        # Install the latest LTS version of node
        nvm install --lts
        # Add lts to the path
        echo 'nvm use --lts' >> ~/.zshrc
        # enable corepack for yarn
        corepack enable
    else
        echo -e "${green}[+++] node already installed. Skipping...${plain}"
    fi
    # Check watchman
    if test ! $(which watchman); then
        echo -e "${blue}[+] Installing watchman...${plain}"
        brew install watchman
    else
        echo -e "${green}[+++] watchman already installed. Skipping...${plain}"
    fi
    # check eas
    if test ! $(which eas); then
        echo -e "${blue}[+] Installing eas...${plain}"
        npm install --global eas-cli
    else
        echo -e "${green}[+++] eas already installed. Skipping...${plain}"
    fi
}


# Install zulu17
openjdk_install() {
    # Attempt to extract the major Java version number
    if ! type java > /dev/null 2>&1; then
        java_version=0 # java not found
    else
        # Extracts version number and trims potential leading "1."
        java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F'.' '{print ($1 == 1 ? $2 : $1)}')
    fi

    # Check if Java version is outside the 17-20 range
    if [[ "$java_version" -lt 17 ]] || [[ "$java_version" -gt 20 ]]; then
        echo -e "${blue}[+] Installing openjdk@17...${plain}"
        brew install openjdk@17
        # Add openjdk to the path
        echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
        # Activate the changes
        source ~/.zshrc
    else
        echo -e "${green}[+++] Java version is within 17-20. Skipping installation of openjdk@17.${plain}"
    fi
}

# Xcode setup
xcode_setup() {
    # Check ios-deploy
    if test ! $(which ios-deploy); then
        echo -e "${blue}[+] Installing ios-deploy...${plain}"
        brew install ios-deploy
    else
        echo -e "${green}[+++] ios-deploy already installed. Skipping...${plain}"
    fi
    echo -e "${blue}[+] Setting up Xcode...You will need to enter your password.${plain}"
    # check if Xcode is installed and set the path
    if test ! $(which xcodebuild); then
        sudo sh -c 'xcode-select -s /Applications/Xcode.app/Contents/Developer && xcodebuild -runFirstLaunch'
    fi
    # Check the first launch
    if test ! -d /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform; then
        xcodebuild -downloadPlatform iOS
    fi
    # wait for the installation to complete
    until test -d /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform; do
        sleep 5
    done
    # Accept the Xcode license
    sudo xcodebuild -license accept
}


# Endding message
ending_message() {
    
    echo -e "${divider}"
    echo -e "${green}React Native enviroment setup completed!${plain}"
    echo -e "${green}Please ${magenta}restart your terminal${green} to apply the changes.${plain}"
    echo -e "${divider}"
    # Remind them to install Visual Studio Code with the RNT extension
    echo -e "${green}Please install ${magenta}Visual Studio Code${green} with the ${magenta}Expo Tools${green} extension.${plain}"
    echo -e "${blue}https://marketplace.visualstudio.com/items?itemName=expo.vscode-expo-tools${plain}"
    echo -e "${blue}If you have Visual Studio Code opened, please restart it.${plain}"
    echo -e "${green}https://code.visualstudio.com/${plain}"
    echo -e "${divider}"
    # Remind them to install Android Studio through JetBrains Toolbox
    echo -e "${green}Please install ${magenta}Android Studio${green} through ${magenta}JetBrains Toolbox${green}.${plain}"
    echo -e "${blue}https://www.jetbrains.com/toolbox-app/download/${plain}"
    echo -e "${divider}"
    # Give a star
    echo -e "${green}If you find this script helpful, please give it a star on GitHub.${plain}"
    echo -e "${blue}https://github.com/ZL-Asica/server-setup-scripts/${plain}"
}



main() {
    # Ensure the script is run not as root
    if [ "$EUID" -eq 0 ]; then
        echo -e "${red}Please run this script as a regular user, not as root.${plain}"
        error_exit "root"
    fi

    # Make sure is macOS
    if [ "$(uname)" != "Darwin" ]; then
        echo -e "${red}This script is only for macOS.${plain}"
        error_exit "macos"
    fi

    # Ask for user's permission to start the installation
    echo -e "${blue}\n\nThis script will install the following (if not installed yet):${plain}"
    echo -e "${cyan}1. Xcode${plain}"
    echo -e "${cyan}2. Homebrew${plain}"
    echo -e "${cyan}3. node-lts(through nvm), watchman${plain}"
    echo -e "${cyan}4. zulu jdk@17${plain}"
    echo -e "${cyan}5. eas CLI${plain}"
    echo -e "${divider}"
    read -p "$(echo -e "${blue}Do you want to continue? (y/n)${plain}")" -n 1 -r

    # Check for Xcode
    xcode_install

    # Check for Homebrew
    homebrew_install

    # Check for node, watchman
    node_watchman_install

    # Install openjdk@17
    openjdk_install

    # Xcode setup
    xcode_setup

    # Ending message
    ending_message

}



# ----------------------------------------------------------
# Start of the script
# ----------------------------------------------------------

# Move focus to the top of the terminal without clearing the screen
printf '\033c'

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

echo -e "${magenta}macOS Expo (expo.dev) enviroment setup script - ZL Asica${plain}"
echo -e "https://github.com/ZL-Asica/server-setup-scripts/blob/main/mac_expo.sh"

main
