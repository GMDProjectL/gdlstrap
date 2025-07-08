#!/bin/sh

wait_for_frontend() {
    curl -s -o /dev/null -w %{http_code} http://localhost:4173 > /dev/null
    if [[ $? -ne 0 ]]; then
        sleep 1
        wait_for_frontend
    else
        echo -e "\e[32mRunning installer window\e[0m"
        electron34 http://localhost:4173 --no-sandbox
    fi
}

ask_gui_stack() {
    read -p "Does your Live ISO have a desktop environment (a graphical interface you can click on)? [y/n]: " choice
    if [[ $choice == "n" ]]; then
        reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
        
        pacman-key --init
        pacman-key --populate archlinux
        pacman -Sy xorg xorg-xinit xterm xf86-input-libinput xf86-video-vesa --noconfirm --needed
        
        mkdir -p /root
        echo "exec electron34 http://localhost:4173 --no-sandbox" > /root/.xinitrc
        echo -e "\e[32mWaiting for frontend to initialize...\e[0m"
        
        wait_for_frontend_x
    elif [[ $choice == "y" ]]; then
        echo -e "\e[32mWaiting for frontend to initialize...\e[0m"
        wait_for_frontend
    else
        ask_gui_stack
    fi
}

wait_for_frontend_x() {
    curl -s -o /dev/null -w %{http_code} http://localhost:4173 > /dev/null
    if [[ $? -ne 0 ]]; then
        sleep 1
        wait_for_frontend
    else
        echo -e "\e[32mRunning installer window\e[0m"
        startx
    fi
}

echo -e "\e[32mCloning installer repository...\e[0m"
git clone https://github.com/GMDProjectL/installer installer
cd installer

echo -e "\e[32mInstalling node.js packages. This might take some time...\e[0m"
yarn install

echo -e "\e[32mBuilding front-end...\e[0m"
yarn run build

echo -e "\e[32mRunning python backend server in background...\e[0m"
python ./python-side/main.py > /dev/null 2>&1 &

echo -e "\e[32mRunning front-end server in background...\e[0m"
yarn run preview > /dev/null 2>&1 &

ask_gui_stack

