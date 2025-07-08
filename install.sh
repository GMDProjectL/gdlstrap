#!/bin/sh

install() {
    echo -e "\e[32mMounting ramdisk storage for packages needed...\e[0m"
    sudo mount -t tmpfs -o size=4G tmpfs /mnt/ramdisk --mkdir
    mkdir -p /mnt/ramdisk/{var/lib/pacman,var/cache/pacman/pkg}

    echo -e "\e[32mInstalling packages...\e[0m"
    pacman --root /mnt/ramdisk --dbpath /mnt/ramdisk/var/lib/pacman --cachedir /mnt/ramdisk/var/cache/pacman/pkg \
        -Sy archlinux-keyring --needed --noconfirm
    pacman --root /mnt/ramdisk --dbpath /mnt/ramdisk/var/lib/pacman --cachedir /mnt/ramdisk/var/cache/pacman/pkg \
        -S git electron34 python python-requests python-systemd yarn gnome-disk-utility dosfstools mtools reflector ttf-roboto adwaita-fonts arch-install-scripts --needed --noconfirm

    echo -e "\e[32mFetching and running reboot fix...\e[0m"
    mkdir -p /mnt/ramdisk/usr/bin
    echo -e "#!/bin/sh\necho \"yes\" > /reboot-flag" > /mnt/ramdisk/usr/bin/reboot
    chmod +x /mnt/ramdisk/usr/bin/reboot
    bash -c "$(curl -s https://raw.githubusercontent.com/GMDProjectL/gdlstrap/refs/heads/main/reboot_poll.sh)" > /dev/null 2>&1 &

    echo -e "\e[32mFetching second part of tool...\e[0m"
    
    curl -s https://raw.githubusercontent.com/GMDProjectL/gdlstrap/refs/heads/main/chroot.sh -o /mnt/ramdisk/chroot.sh
    arch-chroot /mnt/ramdisk /bin/bash ./chroot.sh
}

ask_user() {
    read -p "Are you wish to proceed? [y/n]: " choice
    if [[ $choice == "y" ]]; then
        :
    elif [[ $choice == "n" ]]; then
        exit 0
    else
        ask_user
    fi
}

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "\e[31mThis tool requires root to install packages!\e[0m"
        exit 1
    fi

    echo -ne "\e[32mRunning as root...\e[0m"
    sleep 0.5
}

entry() {
    set -e
    check_root

    echo -e "\r\e[32mGDLStrap                 "
    echo -e "\e[31mWARNING!\e[0m This script is meant for Live ISO use only."
    echo -e "Running it elsewhere may cause damage — use at your own risk.\n"

    ask_user
    install
}

entry
