#!/bin/bash
source gettext.sh

TEXTDOMAIN="let_me_do"
export TEXTDOMAIN
TEXTDOMAINDIR="@LOCALE_PATH@"
export TEXTDOMAINDIR

APP_NAME="$(gettext "Let Me Do")"

if [ "$USER" != "root" ]; then
  message="$(gettext "You must be logged as root")"
  zenity --title="$APP_NAME" --error --text="$message"
  echo "$message"
  exit 1
fi

tmp_file_name="/tmp/let_me_do"
tmp_file_content="$(cat "$tmp_file_name" 2>/dev/null)"

if [ -z "$tmp_file_content" ]; then
  echo "$PPID" > "$tmp_file_name"
else
  if zenity --title="$APP_NAME" --question \
  --text="$(gettext "Let Me Do is already open")" --ok-label="$(gettext "Ok")" \
  --cancel-label="$(gettext "Open it anyway")" 2>/dev/null; then
    exit 2
  else
    echo "$PPID" > "$tmp_file_name"
  fi
fi

function increase {
  echo "scale=2; $1/$2*100" | bc
}

function problem {
    zenity --title="$APP_NAME" --error --text="$1"
    echo "100"
    echo "# $1"
}

local_ip="$(ip route get 1 | awk '{print $NF;exit}')"
port_ssh="6357"
port_vnc="6358"
time_port="43200" #1 day
password="$RANDOM"
computer_name="$(hostname)"

if [ -z "$local_ip" ]; then
  message="$(gettext "Local IP address not found")"
  zenity --title="$APP_NAME" --error --text="$message"
  echo "$message"
  exit 3
fi

(
increase 0 5
gettext "# Obtaining the public IP address"; echo
internet_ip="$(external-ip)"
if [ -z "$internet_ip" ]; then
  problem "$(gettext "Obtaining the public IP address failed")"
  exit 4
fi

increase 1 5
eval_gettext "# Opening SSH port (\$port_ssh) on the router"; echo
if ! upnpc -e "SSH session of $USER on $computer_name" -a "$local_ip" "$port_ssh" "$port_ssh" tcp "$time_port" > /dev/null 2>&1; then
  problem "$(gettext "Opening SSH port on the router failed") ($port_ssh)"
  exit 5
fi

increase 2 5
eval_gettext "# Opening VNC port (\$port_vnc) on the router"; echo
if ! upnpc -e "VNC session of $USER on $computer_name" -a "$local_ip" "$port_vnc" "$port_vnc" tcp "$time_port" > /dev/null 2>&1; then
  problem "$(gettext "Opening VNC port on the router failed") ($port_vnc)"
  exit 6
fi

increase 3 5
eval_gettext "# Redirection of SSH port (\$port_ssh to 22)"; echo
if ! iptables -t nat -A PREROUTING -p tcp --dport "$port_ssh" -j REDIRECT --to-port 22; then
  problem "$(gettext "SSH port redirection failed") ($port_ssh)"
  exit 7
fi

increase 4 5
group="$(grep "^%.* ALL=(ALL) ALL$" /etc/sudoers | sed "s/^%\(.*\) ALL=(ALL) ALL$/\1/g")"
if [ -z "$group" ]; then
  problem "$(gettext "Administrator group not found")"
  exit 8
fi
if ! grep -q "^$group:.*" /etc/group; then
  eval_gettext "# Adding a new group: \$group"; echo
  if ! groupadd -r "$group"; then
    problem "$(gettext "The addition of a new group failed:") $group"
    exit 9
  fi
fi
gettext "# Adding the user Let Me Do"; echo
if ! useradd -r -N -G "$group" -s /bin/bash -c "$APP_NAME" let_me_do; then
  problem "$(gettext "Adding the user Let Me Do failed")"
  exit 10
fi
if ! echo "let_me_do:$password" | chpasswd; then
  problem "$(gettext "Changing Let Me Do's password failed")"
  exit 11
fi

gettext "# Starting desktop sharing (x11vnc)"; echo
x11vnc -display "$DISPLAY" -autoport "$port_vnc" -passwd "$password" -forever -noxdamage -ssl TMP -gui tray -ncache 10 > /dev/null 2>&1 &

gettext "# Copying of information in the clipboard"; echo
echo -n "ssh let_me_do@$internet_ip -p $port_ssh psswd: $password" | xclip -selection "clipboard"

increase 5 5
eval_gettext "# Your computer is now accessible from the Internet.\nIP address: \$internet_ip\nPassword: \$password\nSSH port: \$port_ssh\nVNC port: \$port_vnc\nThe information required for the connection just be copied to the clipboard."; echo
echo "100"
) | zenity --title="$APP_NAME" --width=650 --progress --no-cancel \
--ok-label="$(gettext "Close Let Me Do")" 2>/dev/null

(
gettext "# Shutting down desktop sharing (x11vnc)"; echo
killall x11vnc

eval_gettext "# Closing the SSH port (\$port_ssh) on the router"; echo
upnpc -d "$port_ssh" tcp

eval_gettext "# Closing the VNC port (\$port_vnc) on the router"; echo
upnpc -d "$port_vnc" tcp

eval_gettext "# Removing SSH port (\$port_ssh) redirection"; echo
iptables -t nat -D PREROUTING -p tcp --dport "$port_ssh" -j REDIRECT --to-port 22

gettext "# Deleting user Let Me Do"; echo
userdel let_me_do

echo "" > "$tmp_file_name"
echo "100"
) | zenity --title="$APP_NAME" --width=400 --progress --pulsate --auto-close --no-cancel 2>/dev/null
