# Pi-hole Personal Whitelist

This repository contains a **personal Pi-hole whitelist**, collected and refined over time through real-life testing.  
It solves connectivity issues for smart home devices (e.g. Alexa, Tuya), media services (e.g. Spotify, Netflix), system updates (Ubuntu, Proxmox), developer tools, and more.

> ⚠️ This list is **personal** – it includes hundreds of domains added after troubleshooting issues in a real home network.  
> It's not a universal or "safe-for-everyone" list. Use at your own risk.

---

## ✅ What’s Included

The file `Whitelist.final.personal.txt` includes allowlist entries for:

- **Amazon Alexa / Echo / FireTV**
- **Tuya / SmartLife / Tasmota / MQTT**
- **Synology (DSM, CloudSync, QuickConnect)**
- **Google / Firebase / Android push / Chromecast**
- **Spotify / Netflix / YouTube**
- **Ubuntu / Debian / Proxmox / Signal**
- **GitHub / OpenAI / CDNs / PyPI / Yarn / NPM**
- **Home Assistant / ESPHome / Supervisor**
- **DNS services / Docker / Armbian / Raspberry Pi**
- **Node.js / Snapcraft / Flatpak / Electron**
- **Syncthing / Local LAN entries**

---

## Download & Import

This is the easiest method to import all entries into your Pi-hole v6.x setup.

### Run this on your Pi-hole:

```bash
wget -O /tmp/Whitelist.txt https://raw.githubusercontent.com/TimInTech/Whitelist/main/Whitelist.final.personal.txt
xargs -a /tmp/Whitelist.txt -I {} pihole allow {}
````

* All domains will be added using the `pihole allow` command.
* Existing or duplicate domains will be skipped automatically.
* You don’t need to install any extra software.

---

## Optional: Add to Cron (Auto-Update)

To keep your whitelist up to date:

```bash
sudo crontab -e
```

Add this line to run daily at 06:00:

```bash
0 6 * * * wget -O - https://raw.githubusercontent.com/TimInTech/Whitelist/main/Whitelist.final.personal.txt | xargs -I {} pihole allow {}
```

---

## 🛠 Requirements

* Pi-hole v6.x
* Raspberry Pi OS or Debian/Ubuntu
* No additional tools required (uses built-in Pi-hole CLI)

---

## Notes

* You can inspect or modify the list at any time.
* It may include entries that enable telemetry, update checks, or ads (required for full functionality of devices like Alexa or FireTV).
* Best used for **private setups** where functionality > strict blocking.

---

Maintained by [TimInTech](https://github.com/TimInTech)
Feedback and PRs welcome!

