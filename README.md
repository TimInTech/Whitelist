Pi-hole Minimal Whitelist

Dieses Repository stellt eine einfache, ungekürzte Whitelist bereit, die über Monate hinweg gesammelt wurde, um Probleme mit IoT-Geräten, Smart-Home-Diensten und Webdiensten (Spotify, Alexa, Synology, MQTT, Google etc.) im Heimnetzwerk zu lösen.

> ⚠️ Hinweis: Diese Liste ist individuell angepasst. Sie ist nicht universell einsetzbar. Nutze sie nur, wenn du ähnliche Dienste nutzt – und beobachte die Auswirkungen.




---

🔖 Datei

Whitelist.final.personal.txt

Enthält alle gesammelten, funktionierenden Domains für folgende Dienste:

Amazon Alexa & Echo

Tuya & SmartLife Geräte

Synology Cloud & DSM

Tailscale

Spotify, Netflix, YouTube

Google Dienste & Android Push

OpenAI / GitHub / Cloudflare / CDNs

Ubuntu, Debian, Proxmox, Signal

Home Assistant & MQTT / Nabu Casa

Syncthing

Let’s Encrypt, DuckDNS, Armbian




---

🚀 Import-Skript

whitelist-import.sh

Lädt automatisch die Whitelist von GitHub

Fügt sie via pihole allow ein

Erkennt doppelte Einträge

Benötigt nur wget + Pi-hole CLI (keine weiteren Tools)


🔧 Verwendung:

wget https://raw.githubusercontent.com/TimInTech/Whitelist/main/whitelist-import.sh -O whitelist-import.sh
chmod +x whitelist-import.sh
sudo ./whitelist-import.sh


---

📝 Hinweise

Wenn du manuell importieren willst:


wget -O /tmp/Whitelist.txt https://raw.githubusercontent.com/TimInTech/Whitelist/main/Whitelist.final.personal.txt
xargs -a /tmp/Whitelist.txt -I {} pihole allow {}

Du kannst das Skript regelmäßig per Cronjob ausführen, z. B.:


sudo crontab -e

Dann einfügen:

0 6 * * * wget -qO - https://raw.githubusercontent.com/TimInTech/Whitelist/main/whitelist-import.sh | bash


---

✅ Getestete Umgebung

Raspberry Pi 3B mit Raspbian Bookworm

Pi-hole v6.1.1 Core / FTL 6.2.1

Kein Unbound, kein Docker



---

🌐 Projekt-Link

https://github.com/TimInTech/Whitelist

Maintained by TimInTech

