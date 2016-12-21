#!/bin/bash

case $1 in
  install)
    if [ -f "/usr/bin/apt" ]; then
      apt install openssh-server iptables xclip zenity miniupnpc x11vnc
    fi
    systemctl enable sshd.service
    systemctl start sshd.service

    mkdir -p /usr/local/bin/ /usr/local/share/applications/
    cp let_me_do.bash /usr/local/bin/let_me_do
    cp let_me_do.desktop /usr/local/share/applications/
    ;;
  uninstall)
    rm /usr/local/bin/let_me_do.bash /usr/local/share/applications/let_me_do.desktop
    ;;
esac
update-desktop-database
echo "fini !"
