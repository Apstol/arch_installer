#!/usr/bin/env bash

userName=$(cat /tmp/user_name)

appsPath="/tmp/apps.csv"

curl https://raw.githubusercontent.com/Apstol\
/arch_installer/master/apps.csv > $appsPath

dialog --title "Welcome!" \
    --msgbox "This is the installation script for apps and dotfiles." \
    10 60

#############################
# Ask which apps to install #
#############################

apps=("essential" "Essential" on
      "network" "Network" on
      "pipewire" "Pipewire" on
      "tools" "Tools" on
      "cpp" "Cpp" on
      "php" "PHP" on
      "docker" "Docker" on
      "tmux" "Tmux" on
      "notifier" "Notification system" on
      "git" "Git" on
      "i3" "i3 wm" on
      "zsh" "Zsh" on
      "neovim" "Neovim" on
      "alacritty" "Alacritty" on
      "firefox" "Firefox" on
      "lf" "lf" on
      "sioyek" "sioyek" on
      "qbittorrent" "QBitTorrent" off
      "onlyoffice" "OnlyOffice" off
      "music" "Music player" off
      "video" "Video player" off)
       
dialog --checklist \
    "Choose groups of applications to install. \n\n
    Select options with SPACE and confirm with ENTER." \
    0 0 0 \
    "${apps[@]}" 2> app_choices

choices=$(cat app_choices) && rm app_choices

##############
# Parse apps #
##############

selection="^$(echo $choices | sed -e 's/ /,|^/g'),"
lines=$(grep -E "$selection" "$appsPath")
count=$(echo "$lines" | wc -l)
packages=$(echo "$lines" | awk -F, {'print $2'})

echo "$selection" "$lines" "$count" >> "/tmp/packages"

pacman -Syu --noconfirm

rm -f /tmp/aur_queue

################
# Install apps #
################

dialog --title "Installing apps" --msgbox \
    "The system will now begin installing the apps.\n\n
    It will take some time.\n\n" \
    13 60

c=0
while read -r line; do
    c=$(( "$c" + 1 ))

    dialog --title "Arch Linux Installation" --infobox \
    "Downloading and installing program $c out $count: $line..." \
    8 70

    ((pacman --noconfirm --needed -S "$line" &>/tmp/arch_install) \
    || echo "$line" >> /tmp/aur_queue) \
    || echo "$line" >> /tmp/arch_install_failed

    if [ "$line" = "zsh" ]; then
        # Set Zsh as default terminal
        chsh -s "$(which zsh)" "$userName"
    fi

    if [ "$line" = "networkmanager" ]; then
        systemctl enable NetworkManager.service
    fi
done <<< "$packages"

##############################
# Add wheel group to sudoers #
##############################

echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

###########################
# Run install user script #
###########################

curl https://raw.githubusercontent.com/Apstol\
/arch_installer/master/install_user.sh > /tmp/install_user.sh

sudo -u "$userName" sh /tmp/install_user.sh
