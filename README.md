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

**Enhanced script** with error handling, dry-run mode, and performance optimizations.

#### Features:
- SHA256 checksum verification
- Dry-run mode for testing
- Duplicate prevention
- Automatic DNS cache flush
- Detailed logging
- Local file fallback

#### Usage:
```bash
# Basic import
sudo ./whitelist-import.sh

# Dry-run mode (test without changes)
sudo ./whitelist-import.sh --dry-run

# Use local file only
sudo ./whitelist-import.sh --local
```

#### Direct execution:
```bash
sudo bash -c "$(wget -qO - https://raw.githubusercontent.com/TimInTech/Whitelist/main/whitelist-import.sh)"
```

---

## 🔧 Cron Integration (optional)

For daily automatic updates:
```bash
sudo crontab -e
```
Add line:
```bash
0 6 * * * /path/to/Whitelist/whitelist-import.sh
```

---

##  Tested Environment

* Pi-hole v6.x (FTL 6.2.1)
* Raspberry Pi 3B/4B
* Raspberry Pi OS Bookworm/Bullseye
* Home Assistant OS
* Proxmox VE 8.x

---

##  Notes

* **Critical Domains**: Local domains (.local, .lan) require additional DNSMasq configuration
* **Troubleshooting**: Run `pihole -t` to monitor blocked requests
* **Contributing**: Submit PRs for domain additions with justification
* **Security**: Whitelist is reviewed monthly for suspicious domains

---

## 🌐 Repository

[https://github.com/TimInTech/Whitelist](https://github.com/TimInTech/Whitelist)

---

Maintained by [TimInTech](https://github.com/TimInTech) — Contributions and suggestions welcome!
