#!/usr/bin/env bash

pacman -Sy dialog

timedatectl set-ntp true

##################
# Ask user input #
##################

dialog --defaultno --title "Are you sure?" --yesno \
"This is my personal arch linux installation. \n\n
It will DESTROY EVERYTHING on one of your hard disks. \n\n
Don't say YES if you're not sure what you're doing. \n\n
Do you want to continue?" 15 60 || exit 

dialog --no-cancel --inputbox "Enter a name for your computer." \
10 60 2> computer_name

isUefi=0
ls /sys/firmware/efi/efivars 2> /dev/null && isUefi=1

devicesList=($(lsblk -d | awk '{print "/dev/" $1 " " $4 " on"}' \
    | grep -E 'sd|hd|vd|nvme|mmcblk'))

dialog --title 'Choose your hard disk' --no-cancel --radiolist \
'Where do you want to install your new system? \n\n
Select with SPACE, confirm with ENTER. \n\n
WARNING: Everything on the hard disk will be DESTROYED!' \
15 60 4 "${devicesList[@]}" 2> hd

hd=$(cat hd) && rm hd

defaultSwapSize="8"
dialog --no-cancel --inputbox \
    "You need three partitions: Boot, Root and Swap \n\
    The boot partition will be 512M \n\
    The root partition will be the remaining of the hard disk \n\n\
    Enter below the partition size (in Gb) for the Swap. \n\n\
    If you don't enter anything, it will default to ${defaultSwapSize}G. \n" \
    20 60 2> swap_size
swapSize=$(cat swap_size) && rm swap_size

[[ $swapSize =~ ^[0-9]+$ ]] || swapSize=$defaultSwapSize

dialog --no-cancel \
    --title "!!! DELETE EVERYTHING !!!" \
    --menu "Choose the way you'll wipe your hard disk ($hd)" \
    15 60 4 \
    1 "Use dd (wipe all disk)" \
    2 "Use schred (slow & secure)" \
    3 "No need - my hard disk is empty" 2> eraser 

hderaser=$(cat eraser); rm eraser

################
# Format disk #
################

function eraseDisk() { 
    case $1 in 
        1) dd if=/dev/zero of="$hd" status=progress 2>&1 \
            | dialog \
            --title "Formatting $hd..." \
            --progressbox --stdout 20 60;;
        2) shred -v "$hd" \
            | dialog \
            --title "Formatting $hd..." \
            --progressbox --stdout 20 60;;
        3) ;;
    esac
}

eraseDisk "$hderaser"

###################
# Partition disk  #
###################

bootPartitionType=1
[[ "$isUefi" == 0 ]] && bootPartitionType=4

#g - create non-empty GPT partition table
#n - create new partition
#p - primary partition
#e - extended partition
#w - write the table to disk and exit
partprobe "$hd"
fdisk "$hd" << EOF
g
n


+512M
t
$bootPartitionType
n


+${swapSize}G
n



w
EOF
partprobe "$hd"

#####################
# Format partitions #
#####################

mkswap "${hd}2"
swapon "${hd}2"

mkfs.ext4 "${hd}3"
mount "${hd}3" /mnt

if [ "$isUefi" = 1 ]; then
    mkfs.fat -F32 "${hd}1"
    mkdir -p /mnt/boot/efi
    mount "${hd}1" /mnt/boot/efi
fi

#################################
# Install linux, generate fstab #
#################################

pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

# Persist important values for the next script
echo "$isUefi" > /mnt/var_is_uefi
echo "$hd" > /mnt/var_hd
mv computer_name /mnt/computer_name

############################################
# Install the rest of the system in chroot #
############################################

curl https://raw.githubusercontent.com/Apstol\
/arch_installer/master/install_chroot.sh > /mnt/install_chroot.sh

arch-chroot /mnt bash install_chroot.sh

#######################
# Finish installation #
# #####################

rm /mnt/var_is_uefi
rm /mnt/var_hd
rm /mnt/install_chroot.sh

dialog --title "Reboot?" --yesno \
"Installation has been finished. \n\n\
Reboot computer?" 20 60

response=$?
case $response in 
    0) reboot;;
    1) clear;;
esac
