# Pi-hole Personal Whitelist

This repository contains a **personal, hand-curated Pi-hole whitelist** compiled over many months. It is used in a production home setup with devices like Amazon Alexa, Synology, Smart Home gear (Tuya, Tasmota, ESPHome), streaming platforms (Netflix, Spotify), Home Assistant, and many developer tools.

>  **This whitelist is not generic** – it is designed to solve specific connectivity issues with services in my environment. Use it as inspiration, but test carefully in your own setup.

---

## Whitelist Files

### `Whitelist.final.personal.txt`

Main personal allowlist used in production. Includes hundreds of tested domains for:

* Amazon Alexa, Echo devices
* Tuya & SmartLife smart home devices
* Synology DSM & CloudSync
* Tailscale
* Google / Firebase / Android Push Services
* Spotify, Netflix, YouTube
* Ubuntu, Debian, Proxmox, Signal updates
* OpenAI, GitHub, Cloudflare, NPM/CDN, PyPI
* Home Assistant Core, Supervisor & Community
* MQTT / DuckDNS / LetsEncrypt
* Armbian / Raspberry Pi
* Flatpak / Snapcraft / Node / Electron / Yarn
* Syncthing Discovery / Relay services

### `Whitelist.txt`

Legacy or trimmed version. May be outdated.

---

##  Import Script

### `whitelist-import.sh`

Script to import the current whitelist into Pi-hole.

#### Usage:

```bash
chmod +x whitelist_import.sh
sudo ./whitelist_import.sh
```

This will:

* Use local `Whitelist.final.personal.txt`
* Loop through all entries
* Call `pihole -w` on each domain (skips comments or empty lines)
* Skips duplicates already present

You can also run it directly via:

```bash
sudo bash -c "$(wget -qO - https://raw.githubusercontent.com/TimInTech/Whitelist/main/whitelist-import.sh)"
```

---

## 🔧 Cron Integration (optional)

To regularly update your whitelist, add to root's crontab:

```bash
sudo crontab -e
```

Then add:

```bash
0 6 * * * bash -c "$(wget -qO - https://raw.githubusercontent.com/TimInTech/Whitelist/main/whitelist-import.sh)"
```

---

##  Tested Environment

* Pi-hole v6.x (FTL 6.2.1)
* Raspberry Pi 3B
* Raspbian Bookworm
* No Unbound
* No Docker

---

##  Notes

* Feel free to fork and adapt the list for your setup
* If you encounter connectivity issues with a smart device, monitor DNS requests (`pihole -t`) and consider allowing related entries

---

## 🌐 Repository

[https://github.com/TimInTech/Whitelist](https://github.com/TimInTech/Whitelist)

---

Maintained by [TimInTech](https://github.com/TimInTech) — Contributions and suggestions welcome!
