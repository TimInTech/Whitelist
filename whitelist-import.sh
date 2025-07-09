#!/bin/bash

WHITELIST_URL="https://raw.githubusercontent.com/TimInTech/Whitelist/main/Whitelist.final.personal.txt"
TEMP_FILE="/tmp/whitelist.txt"

echo "=== Pi-hole Whitelist Import (Minimal) ==="
echo "[*] Lade Whitelist herunter..."
wget -qO "$TEMP_FILE" "$WHITELIST_URL" || {
  echo "[✗] Fehler beim Herunterladen der Whitelist"
  exit 1
}

echo "[*] Füge Domains hinzu..."
while read -r domain; do
  [[ -z "$domain" || "$domain" =~ ^# ]] && continue
  pihole allow "$domain" >/dev/null 2>&1 && echo "[+] $domain" || echo "[i] $domain (vermutlich schon vorhanden)"
done < "$TEMP_FILE"

echo "=== Fertig! ==="
