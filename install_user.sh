#!/usr/bin/env bash

################################
# Install Aur and Aur packages #
################################

aurInstall() {
    curl -O "https://aur.achlinux.org/cgit/aur.git/snapshot/$1.tar.gz" \
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

####################
# Install dotfiles #
####################

DOTFILES="/home/$(whoami)/dotfiles"
if [ ! -d "$DOTFILES" ]; then
    git clone https://github.com/Apstol/dotfiles.git \
    "$DOTFILES" >/dev/null
fi

source "$DOTFILES/zsh/.zshenv"
cd "$DOTFILES" && bash install.sh
