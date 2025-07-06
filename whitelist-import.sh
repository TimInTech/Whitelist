#!/bin/bash

# Pfad zur Whitelist
WL_URL="https://raw.githubusercontent.com/TimInTech/Whitelist/main/Whitelist.txt"
WL_FILE="/tmp/Whitelist.txt"

# Prüfe, ob Pi-hole installiert ist
if ! command -v pihole &> /dev/null; then
  echo "Pi-hole not found. Exiting."
  exit 1
fi

# Download der Whitelist
echo "[+] Downloading whitelist from: $WL_URL"
wget -q -O "$WL_FILE" "$WL_URL"

if [ $? -ne 0 ] || [ ! -s "$WL_FILE" ]; then
  echo "[!] Failed to download or file is empty. Abort."
  exit 2
fi

# Optional: Bisherige Einträge entfernen
echo "[+] Removing previous whitelist entries (optional)..."
pihole allow --nuke

# Importiere alle Domains
echo "[+] Importing entries..."
xargs -a "$WL_FILE" -r -I {} pihole allow "{}"

echo "[✓] Whitelist import completed."
