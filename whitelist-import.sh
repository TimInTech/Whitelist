#!/bin/bash

WL_URL="https://raw.githubusercontent.com/TimInTech/Whitelist/main/Whitelist.final.personal.txt"
WL_FILE="/tmp/Whitelist.txt"

if ! command -v pihole &> /dev/null; then
  echo "Pi-hole not found. Exiting."
  exit 1
fi

echo "[+] Downloading whitelist from: $WL_URL"
wget -q -O "$WL_FILE" "$WL_URL"

if [ $? -ne 0 ] || [ ! -s "$WL_FILE" ]; then
  echo "[!] Failed to download or file is empty. Abort."
  exit 2
fi

echo "[+] Removing previous whitelist entries (optional)..."
pihole allow --nuke

echo "[+] Importing entries..."
xargs -a "$WL_FILE" -r -I {} pihole allow "{}"

echo "[✓] Whitelist import completed."
