#!/bin/bash

set -u
HEADPHONES_MAC="08:EB:ED:9A:A4:79"
PHONE_KDE_ID="2a498bbb40724564a54100c503e6ec84"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Headphones -> Phone" "$1"
  fi
  echo "$1"
}

if ! bluetoothctl info "$HEADPHONES_MAC" 2>/dev/null | grep -q "Connected: yes"; then
  notify "Already disconnected from laptop. Tap JBL in phone Bluetooth to connect."
  kdeconnect-cli -d "$PHONE_KDE_ID" --ping-msg "BT_TO_PHONE" >/dev/null 2>&1 || true
  exit 0
fi

notify "Disconnecting from laptop..."
if timeout 10 bluetoothctl disconnect "$HEADPHONES_MAC" 2>&1; then
  notify "Disconnected. Connect JBL WAVE BEAM from phone now."
else
  notify "Disconnect command failed. Try again."
  exit 1
fi

kdeconnect-cli -d "$PHONE_KDE_ID" --ping-msg "BT_TO_PHONE" >/dev/null 2>&1 || true
