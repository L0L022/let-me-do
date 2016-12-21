#!/bin/bash

tmp_file_name="/tmp/let_me_do"
tmp_file_content="$(cat "$tmp_file_name" 2>/dev/null)"

if [ -z "$tmp_file_content" ]; then
  echo "$PPID" > "$tmp_file_name"
else
  if zenity --title="Attention" --question --text="L'application est déjà ouverte" --ok-label="Ok" --cancel-label="Ouvrir quand même" 2>/dev/null; then
    exit
  else
    echo "$PPID" > "$tmp_file_name"
  fi
fi

function increase {
  echo "scale=2; $1/$2*100" | bc
}

function problem {
    zenity --error --text="$1"
    echo "100"
    echo "# $1"
}

function begin_root {
  increase 3 5
  echo "# Redirection du port ssh ($port_ssh -> 22)\\n"
  if ! iptables -t nat -A PREROUTING -p tcp --dport "$port_ssh" -j REDIRECT --to-port 22; then
    problem "Impossible de rediriger le port ssh ($port_ssh)"
    exit
  fi

  increase 4 5
  group="$(grep "^%.* ALL=(ALL) ALL$" /etc/sudoers | sed "s/^%\(.*\) ALL=(ALL) ALL$/\1/g")"
  if [ -z "$group" ]; then
    problem "Impossible de trouver le groupe administrateur"
    exit
  fi
  if ! grep -q "^$group:.*" /etc/group; then
    echo "# Création du groupe: $group\\n"
    if ! groupadd -r "$group"; then
      problem "Impossible de créer le groupe: $group"
      exit
    fi
  fi
  echo "# Ajout de l'utilisateur let_me_do\\n"
  if ! useradd -r -N -G "$group" -s /bin/bash let_me_do; then
    problem "Impossible d'ajouter l'utilisateur let_me_do"
    exit
  fi
  if ! echo "let_me_do:$password" | chpasswd; then
    problem "Impossible de changer le mot de passe de l'utilisateur let_me_do"
    exit
  fi
}

function end_root {
  echo "# Enlève la redirection du port ssh\\n"
  iptables -t nat -D PREROUTING -p tcp --dport "$port_ssh" -j REDIRECT --to-port 22

  echo "# Supprime l'utilisateur let_me_do\\n"
  userdel let_me_do
}

local_ip="$(ip route get 1 | awk '{print $NF;exit}')"
port_ssh="6357"
port_vnc="6358"
time_port="43200" #1 day
password="$RANDOM"
computer_name="$(hostname)"
title="Accès depuis le web"

(
increase 0 5
echo "# Obtention de l'addresse ip externe\\n"
internet_ip="$(external-ip)"
if [ -z "$internet_ip" ]; then
  problem "Impossible d'obtenir l'adresse ip"
  exit
fi

increase 1 5
echo "# Ouverture du port ssh ($port_ssh) sur le routeur\\n"
if ! upnpc -e "ssh session of $USER on $computer_name" -a "$local_ip" "$port_ssh" "$port_ssh" tcp "$time_port" > /dev/null 2>&1; then
  problem "Impossible d'ouvrir le port ssh ($port_ssh)"
  exit
fi

increase 2 5
echo "# Ouverture du port vnc ($port_vnc) sur le routeur\\n"
if ! upnpc -e "vnc session of $USER on $computer_name" -a "$local_ip" "$port_vnc" "$port_vnc" tcp "$time_port" > /dev/null 2>&1; then
  problem "Impossible d'ouvrir le port vnc ($port_vnc)"
  exit
fi

echo "# Attente de l'accès administrateur\\n"
if ! pkexec bash -c "port_ssh=$port_ssh;password=$password;#$(type increase);#$(type problem);#$(type begin_root);begin_root"; then
  problem "Échec de l'accès administrateur"
  exit
fi

echo "# Lancement du partage de bureau (x11vnc)\\n"
x11vnc -display "$DISPLAY" -autoport "$port_vnc" -passwd "$password" -forever -noxdamage -ssl TMP -gui tray -ncache 10 > /dev/null 2>&1 &

echo "# Copie des informations dans le presse papier\\n"
echo -n "ssh let_me_do@$internet_ip -p $port_ssh psswd: $password" | xclip -selection "clipboard"

increase 5 5
echo "# Votre machine est maintenant accessible depuis internet.\\nAdresse ip: $internet_ip\\nMot de passe: $password\\nPort ssh: $port_ssh\\nPort vnc: $port_vnc\\nLes informations nécessaires à la connection viennent d'être copié dans le presse papier.\\n"
echo "100"
) | zenity --title="$title" --width=650 --progress --no-cancel --ok-label="Couper l'accès" 2>/dev/null

(
echo "# Arrêt du partage de bureau (x11vnc)\\n"
killall x11vnc

echo "# Fermeture du port ssh ($port_ssh) sur le routeur\\n"
upnpc -d "$port_ssh" tcp

echo "# Fermeture du port vnc ($port_vnc) sur le routeur\\n"
upnpc -d "$port_vnc" tcp

echo "# Attente de l'accès administrateur\\n"
pkexec bash -c "port_ssh=$port_ssh;#$(type end_root);end_root"

echo "" > "$tmp_file_name"
echo "100"
) | zenity --title="$title" --width=400 --progress --pulsate --auto-close --no-cancel 2>/dev/null
