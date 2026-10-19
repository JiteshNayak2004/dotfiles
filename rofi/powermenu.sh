#!/bin/bash
# Rofi powermenu for GNOME/Ubuntu - ArcMenu replacement
# Plain text (no Nerd Font needed), uses built-in Arc-Dark theme

OPTIONS="Shutdown\nReboot\nSuspend\nLock\nLogout\nCancel"
CHOSEN=$(echo -e "$OPTIONS" | rofi -dmenu -p "Power" -i -no-custom -theme Arc-Dark)

confirm() {
  echo -e "No\nYes" | rofi -dmenu -p "Confirm $1?" -i -no-custom -theme Arc-Dark | grep -q "Yes"
}

case "$CHOSEN" in
  "Shutdown")
    confirm "Shutdown" && systemctl poweroff ;;
  "Reboot")
    confirm "Reboot" && systemctl reboot ;;
  "Suspend")
    systemctl suspend ;;
  "Lock")
    loginctl lock-session ;;
  "Logout")
    confirm "Logout" && gnome-session-quit --logout --no-prompt ;;
  *) exit 0 ;;
esac
