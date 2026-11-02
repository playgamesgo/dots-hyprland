#!/bin/bash

set -u
HEADPHONES_MAC="08:EB:ED:9A:A4:79"
PHONE_KDE_ID="2a498bbb40724564a54100c503e6ec84"
SINK_PATTERN="bluez_output.08_EB_ED_9A_A4_79"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Headphones -> Laptop" "$1"
  fi
  echo "$1"
}

bluetoothctl power on >/dev/null 2>&1 || true

if bluetoothctl info "$HEADPHONES_MAC" 2>/dev/null | grep -q "Connected: yes"; then
  notify "Already connected to laptop."
  exit 0
fi

notify "Asking phone to release buds..."
kdeconnect-cli -d "$PHONE_KDE_ID" --ping-msg "BT_TO_LAPTOP" >/dev/null 2>&1 || true
sleep 5
bluetoothctl disconnect "$HEADPHONES_MAC" >/dev/null 2>&1 || true

notify "Connecting to laptop..."
OK=0
for i in 1 2 3 4 5 6 7 8; do
  if timeout 20 bluetoothctl connect "$HEADPHONES_MAC" 2>&1 | grep -qi "successful"; then
    OK=1
    break
  fi
  echo "attempt $i failed, retrying..."
  sleep 2
done

if [ "$OK" -ne 1 ]; then
  if bluetoothctl info "$HEADPHONES_MAC" 2>/dev/null | grep -q "Connected: yes"; then
    OK=1
  else
    notify "Connect failed. Make sure phone released the buds (disconnect JBL on phone) and try again."
    exit 1
  fi
fi

for i in $(seq 1 10); do
  SINK=$(pactl list short sinks 2>/dev/null | grep -i "$SINK_PATTERN" | cut -f2 | head -n1)
  if [ -n "${SINK:-}" ]; then
    pactl set-default-sink "$SINK" >/dev/null 2>&1 || true
    for INPUT in $(pactl list short sink-inputs 2>/dev/null | cut -f1); do
      pactl move-sink-input "$INPUT" "$SINK" >/dev/null 2>&1 || true
    done
    break
  fi
  sleep 1
done

notify "Connected to laptop."
