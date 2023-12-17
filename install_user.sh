#!/usr/bin/env bash

userDir="/home/$(whoami)"

################################
# Install Aur and Aur packages #
################################

aurInstall() {
    curl -O "https://aur.archlinux.org/cgit/aur.git/snapshot/$1.tar.gz" \
    && tar -xvf "$1.tar.gz" \
    && cd "$1" \
    && makepkg --noconfirm -si \
    && cd - \
    && rm -rf "$1" "$1.tar.gz"
}

aurCheck() {
    qm=$(pacman -Qm | awk '{print $1}')
    for arg in "$@"
    do
        if [[ "$qm" != *"$arg"* ]]; then
            yay --noconfirm -S "$arg" &>> /tmp/aur_install \
                || aurInstall "$arg" &>> /tmp/aur_install
        fi
    done
}

cd /tmp
dialog --infobox "Installing \"Yay\"..." 10 60
aurCheck yay

count=$(wc -l < /tmp/aur_queue)
c=0
while read -r line
do
    c=$(( c + 1 ))
    dialog --infobox \
    "AUR install - Downloading and installing program $c out of $count:
        $line..." \
    10 60
    aurCheck "$line"
done < /tmp/aur_queue

############################
# Set XDG user directories #
############################

xdg-user-dirs-update --set DESKTOP "$userDir/"
xdg-user-dirs-update --set DOCUMENTS "$userDir/documents"
xdg-user-dirs-update --set DOWNLOAD "$userDir/downloads"
xdg-user-dirs-update --set MUSIC "$userDir/music"
xdg-user-dirs-update --set TEMPLATES "$userDir/templates"
xdg-user-dirs-update --set PUBLICSHARE "$userDir/public"
xdg-user-dirs-update --set PICTURES "$userDir/pictures"
xdg-user-dirs-update --set VIDEOS "$userDir/videos"

####################
# Install dotfiles #
####################

DOTFILES="$userDir/dotfiles"
if [ ! -d "$DOTFILES" ]; then
    git clone https://github.com/Apstol/dotfiles.git \
    "$DOTFILES" >/dev/null
fi

cd "$DOTFILES" && bash install.sh
