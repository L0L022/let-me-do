#!/bin/bash
#openssh, xclip, zenity, miniupnpc, ifconfig, sed, x11vnc

tmp_file_name="/tmp/let_me_do"
tmp_file_content="$(cat "$tmp_file_name")"

function increase {
  # for (( i = $1; i <= $2; i++ )); do
  #   echo "$i"
  #   sleep 0.04
  # done
  echo "$2"
}

function problem {
    zenity --error --text="$1"
    echo "100"
    echo "# $1"
}

if [ -z "$tmp_file_content" ]; then
  echo "$PPID" > "$tmp_file_name"
else
  zenity --question --title="Attention" --text="L'application est déjà ouverte" --ok-label="Ok" --cancel-label="Ouvrir quand même"
  if [ $? -eq 0 ]; then
    exit
  else
    echo "$PPID" > "$tmp_file_name"
  fi
fi

local_ip="$(ip route get 1 | awk '{print $NF;exit}')"
port_ssh="6357"
port_vnc="6358"
time_port="43200" #1 day
password="$RANDOM"
computer_name="$(hostname)"

title="Accès depuis le web"
#text_message="Votre machine est maintenant accessible depuis internet à l'adresse suivante:\n$internet_ip:$port_ssh\nLe mot de passe: $password\nElle vient d'être copiée dans le presse papier, plus qu'à envoyer à votre ange gardien !"
ok_message="Couper l'accès"
icon="emblem-web"

(
increase 0 30 &
echo "# Obtention de l'addresse ip externe"
internet_ip="$(external-ip)"
if [ -z "$internet_ip" ]; then
  message="Impossible d'obtenir l'adresse ip"
  problem "$message"
  exit
fi

increase 30 60 &
echo "# Ouverture du port ssh"
upnpc -e "ssh session of $USER on $computer_name" -a "$local_ip" "$port_ssh" "$port_ssh" tcp "$time_port" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  message="Impossible d'ouvrir le port ssh ($port_ssh)"
  problem "$message"
  exit
fi

increase 60 80 &
echo "# Ouverture du port vnc"
upnpc -e "vnc session of $USER on $computer_name" -a "$local_ip" "$port_vnc" "$port_vnc" tcp "$time_port" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  message="Impossible d'ouvrir le port vnc ($port_vnc)"
  problem "$message"
  exit
fi

echo "# Ouverture de x11vnc"
x11vnc -display "$DISPLAY" -autoport "$port_vnc" -passwd "$password" -forever -noxdamage -ssl TMP -gui tray -ncache 10 > /dev/null 2>&1 &
if [ $? -ne 0 ]; then
  message="Impossible de lancer le programme x11vnc"
  problem "$message"
  exit
fi

echo "# Copie de l'adresse dans le presse papier"
echo "$internet_ip:$port_ssh $password" | xclip -selection "clipboard"
increase 80 100 &

text_message="Votre machine est maintenant accessible depuis internet à l'adresse suivante:\n$internet_ip:$port_ssh\nLe mot de passe: $password\nL'adresse et le mot de passe viennent d'être copié dans le presse papier, plus qu'à envoyer."
echo "# $text_message"
echo "100"
) | zenity --progress --no-cancel --width=600 --title="$title" --window-icon="$icon" --icon-name="$icon" --ok-label="$ok_message"

(
echo "# Fermeture de x11vnc"
killall x11vnc

echo "# Fermeture du port ssh"
upnpc -d "$port_ssh" tcp

echo "# Fermeture du port vnc"
upnpc -d "$port_vnc" tcp

echo "" > "$tmp_file_name"
echo "100"
) | zenity --progress --pulsate --auto-close --no-cancel --width=200
