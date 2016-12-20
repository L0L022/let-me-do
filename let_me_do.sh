#!/bin/bash

tmp_file_name="/tmp/let_me_do"
tmp_file_content="$(cat "$tmp_file_name")"

function increase {
  # for (( i = $1; i <= $2; i++ )); do
  #   echo "$i"
  #   sleep 0.04
  # done
  echo "scale=2; $1/$2*100" | bc
}

function problem {
    zenity --error --text="$1"
    echo "100"
    echo "# $1"
}

function begin_root {
  increase 3 5 &
  echo "# Redirection du port ssh"
  iptables -t nat -A PREROUTING -p tcp --dport "$port_ssh" -j REDIRECT --to-port 22
  if [ $? -ne 0 ]; then
    message="Impossible de rediriger le port ssh ($port_ssh)"
    problem "$message"
    exit
  fi

  increase 4 5 &
  echo "# Ajout de l'utilisateur let_me_do"
  useradd -r -G wheel -s /bin/bash let_me_do
  echo "let_me_do:$password" | chpasswd
  if [ $? -ne 0 ]; then
    message="Impossible d'ajouter l'utilisateur let_me_do"
    problem "$message"
    exit
  fi
}

function end_root {
  echo "# Supprime la redirection du port ssh"
  iptables -t nat -D PREROUTING -p tcp --dport "$port_ssh" -j REDIRECT --to-port 22

  echo "# Supprime l'utilisateur let_me_do"
  userdel let_me_do
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
increase 0 5 &
echo "# Obtention de l'addresse ip externe"
internet_ip="$(external-ip)"
if [ -z "$internet_ip" ]; then
  message="Impossible d'obtenir l'adresse ip"
  problem "$message"
  exit
fi

increase 1 5 &
echo "# Ouverture du port ssh"
upnpc -e "ssh session of $USER on $computer_name" -a "$local_ip" "$port_ssh" "$port_ssh" tcp "$time_port" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  message="Impossible d'ouvrir le port ssh ($port_ssh)"
  problem "$message"
  exit
fi

increase 2 5 &
echo "# Ouverture du port vnc"
upnpc -e "vnc session of $USER on $computer_name" -a "$local_ip" "$port_vnc" "$port_vnc" tcp "$time_port" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  message="Impossible d'ouvrir le port vnc ($port_vnc)"
  problem "$message"
  exit
fi

pkexec bash -c "port_ssh=$port_ssh;password=$password;\
#$(type increase);#$(type problem);#$(type begin_root);begin_root"

echo "# Ouverture de x11vnc"
x11vnc -display "$DISPLAY" -autoport "$port_vnc" -passwd "$password" -forever -noxdamage -ssl TMP -gui tray -ncache 10 > /dev/null 2>&1 &
if [ $? -ne 0 ]; then
  message="Impossible de lancer le programme x11vnc"
  problem "$message"
  exit
fi

echo "# Copie de l'adresse dans le presse papier"
echo "$internet_ip:$port_ssh $password" | xclip -selection "clipboard"

increase 5 5 &
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

pkexec bash -c "port_ssh=$port_ssh;#$(type end_root);end_root"

echo "" > "$tmp_file_name"
echo "100"
) | zenity --progress --pulsate --auto-close --no-cancel --width=200
