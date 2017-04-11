#!/bin/bash

case $1 in
  install)
    if [ -f "/usr/bin/apt" ]; then
      apt install openssh-server iptables xclip zenity miniupnpc x11vnc gettext
    fi
    systemctl enable sshd.service
    systemctl start sshd.service


    update-desktop-database
    echo "fini !"
    ;;
  uninstall)
  
    update-desktop-database
    echo "fini !"
    ;;
  *)
    echo "option inconnue"
    ;;
esac
