#!/bin/bash

select_options() {
    local -n options=$1 selections=$2
    local title=$3
    local choice
    local selected

    echo "${magenta}$title${plain}"
    PS3="${blue}Select an option (again to deselect, ENTER when done): ${plain}"
    
    while true; do
        # Display options with current selections highlighted
        for i in "${!options[@]}"; do
            if [[ " ${selections[*]} " =~ " ${options[i]} " ]]; then
                echo -e "${green}${i}) ${options[i]}${plain}"
            else
                echo -e "${i}) ${options[i]}"
            fi
        done

        # User input
        read -p "$PS3" choice

        # Check if input is a number and within range
        if [[ ! $choice =~ ^[0-9]+$ ]] || (( choice < 0 || choice >= ${#options[@]} )); then
            if [ -z "$choice" ]; then
                # If ENTER is pressed, break the loop
                break
            else
                echo "${red}Invalid selection. Please try again.${plain}"
                continue
            fi
        fi

        # Toggle selection
        selected="${options[choice]}"
        if [[ " ${selections[*]} " =~ " ${selected} " ]]; then
            # Deselect
            selections=(${selections[@]/$selected})
        else
            # Select
            selections+=("$selected")
        fi
    done
}


enviroment_install() {
    # Design an interactive prompt for user to click on to choose what are the programming enviroment/server/database to install
    #   The prompt will be displayed to the user direclty choose what are those optiosn they want to install
    echo -e "${blue}Choose what are the programming environment/server/database to install${plain}"
    echo -e "${blue}You can choose multiple options, just click on the options you want to install${plain}"
    echo -e "${blue}Press ENTER when done${plain}"
    echo -e "${blue}(1) Programming Enviroment (2) Web Server (3) Database${plain}"

    # Arrays of options
    environment_options=("Node" "Python" "Golang" "Rust" "Java" "PHP" "Ruby")
    server_options=("Nginx" "Apache")
    database_options=("MySQL" "MariaDB" "PostgreSQL" "MongoDB" "Redis")

    # Arrays to keep track of selections
    environment_selections=()
    server_selections=()
    database_selections=()

    select_options environment_options environment_selections "Programming Environment"
    select_options server_options server_selections "Web Server"
    select_options database_options database_selections "Database"

    # Output selections
    echo -e "${cyan}You have selected:${plain}"
    echo -e "${magenta}Environments:${plain} ${environment_selections[*]}"
    echo -e "${magenta}Servers:${plain} ${server_selections[*]}"
    echo -e "${magenta}Databases:${plain} ${database_selections[*]}"
}