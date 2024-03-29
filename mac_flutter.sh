#!/bin/zsh
#
# Setup script for macOS Flutter development
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


# rbenv, ruby@3.3.0, cocoapods
ruby_install() {
    # Check rbenv
    if test ! $(which rbenv); then
        echo -e "${blue}[+] Installing rbenv...${plain}"
        brew install rbenv
        # Add rbenv to the path
        echo 'eval "$(rbenv init -)"' >> ~/.zshrc
        # Activate the changes
        source ~/.zshrc
    else
        echo -e "${green}[+++] rbenv already installed. Skipping...${plain}"
    fi
    # Check ruby
    if test ! $(which ruby); then
        echo -e "${blue}[+] Installing ruby@3.3.0...${plain}"
        rbenv install 3.3.0
        rbenv global 3.3.0
    else
        echo -e "${green}[+++] ruby@3.3.0 already installed. Skipping...${plain}"
    fi
    # Check cocoapods
    if test ! $(which pod); then
        echo -e "${blue}[+] Installing cocoapods...${plain}"
        gem install cocoapods
    else
        echo -e "${green}[+++] cocoapods already installed. Skipping...${plain}"
    fi
}


# Install Flutter Through fvm
flutter_install() {
    # Check flutter first
    if test ! $(which flutter); then
        echo -e "${blue}[+] Installing Flutter...${plain}"
        # Check fvm
        if test ! $(which fvm); then
            echo -e "${blue}[+] Installing fvm(Flutter version manager)...${plain}"
            # Install fvm
            brew install fvm
        else
            echo -e "${green}[+++] fvm already installed. Skipping...${plain}"
        fi
        fvm install stable
        # Set the global flutter version
        fvm global stable
        # Add fvm to the path
        echo 'export PATH=$PATH:"$HOME/fvm/default/bin"' >> ~/.zshrc
        # Activate the changes
        source ~/.zshrc
    else
        echo -e "${green}[+++] Flutter already installed. Skipping...${plain}"
    fi
}


# Install openjdk@17
openjdk_install() {
    # directly install without check
    echo -e "${blue}[+] Installing openjdk@17...${plain}"
    brew install openjdk@17
    # Add openjdk to the path
    echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
    echo 'export JAVA_HOME="/opt/homebrew/opt/openjdk@17"' >> ~/.zshrc
    # Activate the changes
    source ~/.zshrc
}


# Install Android Studio Command Line Tools
android_studio_install() {
    if test ! $(which sdkmanager); then
        echo -e "${blue}[+] Installing Android Studio Command Line Tools...${plain}"
        # Download latest version into $HOME/
        curl -o ~/android-studio.zip https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip
        # Create the directory
        mkdir -p ~/android-studio/cmdline-tools/latest/
        # Unzip the file contents into the directory
        unzip ~/android-studio.zip -d ~/android-studio/cmdline-tools/latest/
        # Delete the zip file
        rm ~/android-studio.zip
        # Set the environment variable to the path
        echo 'export ANDROID_HOME="$HOME/android-studio"' >> ~/.zshrc
        echo 'export PATH=$PATH:"$ANDROID_HOME/cmdline-tools/latest/bin"' >> ~/.zshrc
        echo 'export PATH=$PATH:"$ANDROID_HOME/emulator"' >> ~/.zshrc
        echo 'export PATH=$PATH:"$ANDROID_HOME/platform-tools"' >> ~/.zshrc
        # Activate the changes
        source ~/.zshrc
        # Install the latest platform tools
        sdkmanager "platform-tools" "build-tools;34.0.0" "platforms;android-34"
        sdkmanager "system-images;android-34;google_apis;arm64-v8a"
        avdmanager create avd -n android-34- -k "system-images;android-34;google_apis;arm64-v8a" --abi google_apis/arm64-v8a
        # Config flutter
        flutter config --android-sdk ~/android-studio
        # Accept the licenses
        flutter doctor --android-licenses
    else
        echo -e "${green}[+++] Android Studio Command Line Tools already installed. Skipping...${plain}"
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
    # Run flutter doctor
    flutter doctor
    echo -e "${divider}"
    echo -e "${green}Flutter enviroment setup completed!${plain}"
    echo -e "${green}Please ${magenta}restart your terminal${green} to apply the changes.${plain}"
    echo -e "${divider}"
    # Remind them to install Visual Studio Code with the Flutter extension
    echo -e "${green}Please install ${magenta}Visual Studio Code${green} with the ${magenta}Flutter extension.${plain}"
    echo -e "${blue}If you have Visual Studio Code opened, please restart it.${plain}"
    echo -e "${green}https://code.visualstudio.com/${plain}"
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
    echo -e "${blue}This script will install the following (if not installed yet):${plain}"
    echo -e "${cyan}1. Xcode${plain}"
    echo -e "${cyan}2. Homebrew${plain}"
    echo -e "${cyan}3. rbenv, ruby@3.3.0, cocoapods${plain}"
    echo -e "${cyan}4. Flutter${plain}"
    echo -e "${cyan}5. openjdk@17${plain}"
    echo -e "${cyan}6. Android Studio Command Line Tools${plain}"
    echo -e "${cyan}7. Andrios SDK - platform-tools, build-tools;30.0.3, platforms;android-30${plain}"
    echo -e "${divider}"
    read -p "$(echo -e "${blue}Do you want to continue? (y/n)${plain}")" -n 1 -r

    # Check for Xcode
    xcode_install

    # Check for Homebrew
    homebrew_install

    # Check for rbenv, ruby@3.3.0, cocoapods
    ruby_install

    # Install Flutter Through fvm
    flutter_install

    # Install openjdk@17
    openjdk_install

    # Install Android Studio Command Line Tools
    android_studio_install

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

echo -e "${magenta}macOS Flutter enviroment setup script - ZL Asica${plain}"
echo -e "https://github.com/ZL-Asica/server-setup-scripts/blob/main/mac_flutter.sh"

main
