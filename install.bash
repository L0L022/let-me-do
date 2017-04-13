#!/bin/bash

if [ "$USER" != "root" ]; then
  echo "You must be logged as root"
  exit 1
fi

case $1 in
  install)
    if [ -f "/usr/bin/apt" ]; then
      apt install openssh-server iptables xclip zenity miniupnpc x11vnc gettext cmake
    fi
    systemctl enable sshd.service
    systemctl start sshd.service
    cmake . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -B../let-me-do-build
    cd ../let-me-do-build || exit
    make
    make install
    update-desktop-database
    echo "done !"
    ;;
  uninstall)
    cmake . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -B../let-me-do-build
    cd ../let-me-do-build || exit
    make
    make uninstall
    update-desktop-database
    echo "done !"
    ;;
  *)
    echo "You must run the program with install or uninstall arg"
    ;;
esac
