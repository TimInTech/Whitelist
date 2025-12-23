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

## 🧪 Development

### Code Structure

The repository has been refactored to improve code organization and testability:

* **`lib/common.sh`** - Shared library with reusable functions:
  - Dependency management (`ensure_dependencies`, `need`)
  - Hostname filtering and validation (`filter_valid_hosts`)
  - DNS and HTTPS checking (`check_dns_resolution`, `check_https_head`)
  - Whitelist management (`renumber_whitelist`, `extract_hostnames_from_numbered_list`)
  - Git operations (`commit_and_push`, `has_git_changes`)

* **`tests/`** - Test suite for validation:
  - `test_common.sh` - Unit tests for library functions
  - `test_integration.sh` - Integration tests for workflows
  - `run_all_tests.sh` - Test runner for all tests

### Running Tests

To verify the scripts work correctly:

```bash
bash tests/run_all_tests.sh
```

### Scripts

All scripts now use the shared library to avoid code duplication:

* `build_plain_whitelist.sh` - Regenerate plain whitelist from numbered version
* `update_alexa_spotify_whitelist.sh` - Crawl and update Alexa/Spotify domains
* `check_all_urls.sh` - Validate domains with DNS and HTTPS checks
* `whitelist_audit_update.sh` - Audit and normalize whitelist entries

---

Maintained by [TimInTech](https://github.com/TimInTech)
Feedback and PRs welcome!
