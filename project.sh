#!/bin/bash

# Define ANSI escape codes
# For more info: https://github.com/laravel/prompts/blob/main/src/Key.php
GRAY_TEXT="\033[90m"
CYAN_TEXT="\033[36m"
RED_TEXT="\033[31m"
RESET="\033[0m"
STRIKETHROUGH_START="\033[9m"
STRIKETHROUGH_END="\033[0m"
UP="[A"
DOWN="[B"
RIGHT="[C"
LEFT="[D"
ENTER=""
SHIFT_TAB="[Z"

# I need to create an input box similar to what Jess did in Laravel prompts, but writing the code is taking too much time for now!
# So, we'll just use this method temporarily.
# Another idea is to validate the PHP version available in Ubuntu.

# YELLOW_TEXT="\033[93m"
# WHITE_TEXT="\033[97m"
# BLACK_TEXT="\033[30m"
# UP_ARROW="OA"
# DOWN_ARROW="OB"
# RIGHT_ARROW="OC"
# LEFT_ARROW="OD"
# DELETE="\e[3~"
# BACKSPACE="\177"
# SPACE=' '

# Hide the cursor
tput civis

options=("Non-Laravel Project" "Laravel Project with Installation" "Existing Laravel Project" "Simple HTML Project" "Delete Project")
selected=0

# Function to display the menu
display_menu() {
    clear
    echo -e "${GRAY_TEXT} ┌ ${CYAN_TEXT}Select type of project: ${GRAY_TEXT}───────────────────────────────┐"
    for i in "${!options[@]}"; do
        if [ "$i" -eq "$selected" ]; then
            printf " ${GRAY_TEXT}│ ${CYAN_TEXT}› ● ${RESET}%-50s ${GRAY_TEXT}│\n" "${options[$i]}"
        else
            printf " ${GRAY_TEXT}│   ○ ${RESET}%-50s ${GRAY_TEXT}│\n" "${options[$i]}"
        fi
    done
    echo -e "${GRAY_TEXT} └────────────────────────────────────────────────────────┘\n"
}

trap 'display_cancel_menu; tput cnorm; exit 1;' INT

create_project() {
    tput cnorm

    echo -e "Project name : ${CYAN_TEXT}$1${RESET}";

    if [ $2 -eq 0 ] || [ $2 -eq 1 ] || [ $2 -eq 2 ] || [ $2 -eq 3 ]; then
        read -p "Enter website name: " dirname

        if [[ $dirname != *.local ]]; then
            echo -e "${RED_TEXT}Website name must be ends with '.local'${RESET}"
            tput cnorm
            exit 1
        fi

        phpVersion=8.2

        read -p "Enter php version(e.g. 7.4, 8.0, 8.2) (default 8.2): " phpVersion

        # remove .local and create database
        project_name=${dirname%.local}

        # add entry in /etc/hosts file
        echo "127.0.0.1 $dirname" | sudo tee --append /etc/hosts
        if [ $2 -eq 0 ] # Non-Laravel Project
        then
            # project folder path
            folderPath="$HOME/work/code/$dirname"
            mkdir -p -- $folderPath

            # create database
            mysql -e "CREATE DATABASE $project_name CHARACTER SET utf8 COLLATE utf8_unicode_ci;"

            # create config file for virtual host in /etc/nginx/sites_enabled
            sudo cp $HOME/bin/template $HOME/bin/temporary
            sed -i 's/\/public//g' $HOME/bin/temporary
            sudo cp $HOME/bin/temporary /etc/nginx/sites-available/$dirname
            sudo sed -i -e "s/{USERNAME}/$USER/g" -e "s/{DOMAIN}/$dirname/g" -e "s/php7.4/php$phpVersion/g" /etc/nginx/sites-available/$dirname
            sudo ln -s /etc/nginx/sites-available/$dirname /etc/nginx/sites-enabled/
            sudo rm -f $HOME/bin/temporary

        elif [ $2 -eq 1 ] # Laravel Project with install
        then

            # project folder path
            folderPath="$HOME/work/code/$dirname/public"
            mkdir -p -- $folderPath

            # create database
            mysql -e "CREATE DATABASE $project_name CHARACTER SET utf8 COLLATE utf8_unicode_ci;"

            # create config file for virtual host in /etc/nginx/sites_enabled
            sudo cp $HOME/bin/template /etc/nginx/sites-available/$dirname
            sudo sed -i -e "s/{USERNAME}/$USER/g" -e "s/{DOMAIN}/$dirname/g" -e "s/php7.4/php$phpVersion/g" /etc/nginx/sites-available/$dirname
            sudo ln -s /etc/nginx/sites-available/$dirname /etc/nginx/sites-enabled/

            # remove public folder before laravel install
            sudo rm -R $HOME/work/code/$dirname/public

            # install laravel at project folder path
            composer create-project --prefer-dist laravel/laravel $HOME/work/code/$dirname/

        elif [ $2 -eq 2 ] # Existing Laravel Project
        then

            # project folder path
            folderPath="$HOME/work/code/$dirname/public"
            mkdir -p -- $folderPath

            # create config file for virtual host in /etc/nginx/sites_enabled
            sudo cp $HOME/bin/template /etc/nginx/sites-available/$dirname
            sudo sed -i -e "s/{USERNAME}/$USER/g" -e "s/{DOMAIN}/$dirname/g" -e "s/php7.4/php$phpVersion/g" /etc/nginx/sites-available/$dirname
            sudo ln -s /etc/nginx/sites-available/$dirname /etc/nginx/sites-enabled/
        elif [ $2 -eq 3 ] # New HTML Project
        then
            # project folder path
            folderPath="$HOME/work/code/$dirname"
            mkdir -p -- $folderPath

            # create config file for virtual host in /etc/nginx/sites_enabled
            sudo cp $HOME/bin/template $HOME/bin/temporary
            sed -i 's/\/public//g' $HOME/bin/temporary
            sudo cp $HOME/bin/temporary /etc/nginx/sites-available/$dirname
            sudo sed -i -e "s/{USERNAME}/$USER/g" -e "s/{DOMAIN}/$dirname/g" -e "s/php7.4/php$phpVersion/g" -e "s/index.php?/index.html?/g" /etc/nginx/sites-available/$dirname
            sudo ln -s /etc/nginx/sites-available/$dirname /etc/nginx/sites-enabled/
            sudo rm -f $HOME/bin/temporary
        fi
        # enable site and restart nginx
        sudo service nginx restart

        if [ $2 -eq 0 ] || [ $2 -eq 2 ];
        then
            # add index.php to the new folder
            cat > "$folderPath/index.php" <<- "EOF"
<?php

echo 'Project Created Successfully';
EOF
        fi
        if [ $2 -eq 3 ];
        then
            # add index.html to the new folder
            cat > "$folderPath/index.html" <<- "EOF"
<h4>Project Created Successfully</h4>
EOF
        fi

        tput cnorm

        # open the new url in browser
        google-chrome http://$dirname
    else
        if [ $2 -eq 4 ] #Delete Project
        then
            # remove project folder from ~/public_html
            read -p "Enter website name: " dirname

            if [[ $dirname != *.local ]]; then
                echo -e "${RED_TEXT}Website name must be ends with '.local'${RESET}"
                tput cnorm
                exit 1
            fi

            folderPath="$HOME/work/code/$dirname"
            rm -rf $folderPath

            # remove entry from /etc/hosts file
            sudo sed -i "/127.0.0.1 $dirname/d" /etc/hosts

            # remove .local and create database
            project_name=${dirname%.local}

            # delete database
            mysql -e "DROP DATABASE $project_name;"

            # delete config file for virtual host from /etc/nginx/sites_enabled
            sudo rm -f /etc/nginx/sites-available/$dirname
            sudo rm -f /etc/nginx/sites-enabled/$dirname

            # enable site and restart nginx
            sudo service nginx restart

            tput cnorm
        fi
    fi
}

# Function to display the cancel menu
display_cancel_menu() {
    clear
    echo -e "${RED_TEXT} ┌ ${RESET}Select type of project: ${RED_TEXT}───────────────────────────────┐"
    for i in "${!options[@]}"; do
        text="${STRIKETHROUGH_START}${options[$i]}${STRIKETHROUGH_END}"
        if [ "$i" -eq "$selected" ]; then
            printf " ${RED_TEXT}│${RESET} › ● %-58b ${RED_TEXT}│\n" "$text"
        else
            printf " ${RED_TEXT}│${RESET}   ○ %-58b ${RED_TEXT}│\n" "$text"
        fi
    done
    echo -e "${RED_TEXT} └────────────────────────────────────────────────────────┘"
    echo -e "⚠ Cancelled. ${RESET}"
}

# Function to handle user input
handle_selection() {
    IFS= read -rsn 1 key
    case "$key" in
        'j' | 'k' | $'\t')
            if [ "$key" == 'k' ]; then
                ((selected--))
            elif [ "$key" == 'j' ] || [ "$key" == $'\t' ]; then
                ((selected++))
            fi
            ;;
        $'\e')
            # Arrow key escape sequences, e.g., for arrow keys
            read -rsn2 key
            if [ "$key" == "$UP" ] || [ "$key" == "$SHIFT_TAB" ] || [ "$key" == "$RIGHT" ]; then
                ((selected--))
            elif [ "$key" == "$DOWN" ] || [ "$key" == "$LEFT" ]; then
                ((selected++))
            fi
            ;;
        $"")
            clear
            create_project "${options[$selected]}" "$selected"
            tput cnorm # Show the cursor
            exit 0
            ;;
        'q')
           clear
           display_cancel_menu
           tput cnorm # Show the cursor
           exit 0
           ;;
    esac

    # Ensure selected stays within bounds
    if [ "$selected" -lt 0 ]; then
        selected=$((${#options[@]} - 1))
    elif [ "$selected" -ge ${#options[@]} ]; then
        selected=0
    fi

    display_menu
    handle_selection
}

# Main script
display_menu
handle_selection
