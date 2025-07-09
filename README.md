# 🔒 Pi-hole Personal Whitelist - Curated Domain Allowlist

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Stars](https://img.shields.io/github/stars/TimInTech/Whitelist?style=social)](https://github.com/TimInTech/Whitelist/stargazers)
[![SHA256 Verified](https://img.shields.io/badge/SHA256-Verified-brightgreen)](https://github.com/TimInTech/Whitelist/blob/main/Whitelist.final.personal.txt.sha256)

## 📖 About This Project

This repository contains a **personally curated Pi-hole whitelist** developed over years of home network management. It's designed to solve specific connectivity issues with smart home devices and services in real-world environments.

> **⚠️ Important Notice:**  
> This is not a generic one-size-fits-all whitelist! It's optimized for:
> - Smart home ecosystems (Tuya, Alexa, Home Assistant)
> - Media streaming services (Netflix, Spotify, YouTube)
> - Developer tools (GitHub, Docker, PyPI)
> - System updates (Ubuntu, Proxmox, Raspberry Pi)
> 
> Test carefully in your environment before production use.

### Why This Exists

Pi-hole's aggressive blocking can break functionality of modern IoT devices and services. This whitelist:
- Solves "device offline" issues with smart home gear
- Fixes update failures on Linux systems
- Restores functionality to media streaming platforms
- Maintains security by whitelisting only essential domains

## 🚀 Key Features

- **250+ Tested Domains** - Carefully vetted through real-world use
- **SHA256 Verification** - Ensures whitelist integrity
- **Smart Import Script** - With dry-run mode and duplicate prevention
- **Automatic Updates** - Cron job integration
- **Device-Specific Optimization** - Alexa, Synology, Tuya, Home Assistant
- **Production Proven** - Used in real smart home environments daily

## 📁 Whitelist Files

### `Whitelist.final.personal.txt` - Primary Allowlist
Comprehensive production-ready whitelist covering:

| Category | Services Included |
|----------|-------------------|
| 🏠 Smart Home | Amazon Alexa, Tuya, Smart Life, Home Assistant, Tasmota |
| 📺 Streaming | Spotify, Netflix, YouTube, Google Cast |
| 💻 Development | GitHub, Docker, PyPI, NPM, OpenAI |
| 🔄 Updates | Ubuntu, Debian, Proxmox, Signal, Raspberry Pi |
| 🌐 Networking | Cloudflare, Tailscale, DuckDNS, Syncthing |
| 📱 Mobile | Android Push Services, Firebase |

### `Whitelist.txt` - Legacy Version
Previous version maintained for reference (may be outdated)

## ⚙️ Import Script: `whitelist-import.sh`

Advanced import script with enterprise-grade features:

```bash
# Download and execute directly from GitHub
sudo bash -c "$(wget -qO - https://raw.githubusercontent.com/TimInTech/Whitelist/main/whitelist-import.sh)"
```

### Script Features:
- ✅ **SHA256 Integrity Verification** - Prevents tampering
- 🔍 **Dry-Run Mode** - Test without changes: `--dry-run`
- 💾 **Local Mode** - Use local files only: `--local`
- 🚫 **Duplicate Prevention** - Skips existing entries
- 📊 **Detailed Logging** - Clear visual feedback
- ⚡ **DNS Cache Flush** - Automatic after import

### Usage Options:
```bash
# Standard remote import
sudo ./whitelist-import.sh

# Test run without changes
sudo ./whitelist-import.sh --dry-run

# Use local files only (no download)
sudo ./whitelist-import.sh --local
```

## 🔧 Cron Integration (Automatic Updates)

Set up daily automatic whitelist updates:

```bash
sudo crontab -e
```

Add this line for 6 AM daily updates:
```bash
0 6 * * * /path/to/Whitelist/whitelist-import.sh
```

## 🧪 Tested Environments

This whitelist has been verified in these environments:

| Component | Version/Model |
|-----------|---------------|
| **Pi-hole** | v6.7.4 (FTL 6.2.1) |
| **Hardware** | Raspberry Pi 4B (4GB), Proxmox VE LXC Container |
| **OS** | Raspberry Pi OS Bookworm (64-bit), Debian 12 |
| **Key Services** | Home Assistant OS 2024.7, Docker 24.0.7 |
| **Network** | UniFi Dream Machine Pro, TP-Link Omada |

## 📝 Important Notes

1. **Local Domains** (`.local`, `.lan`):
   ```ini
   # Add to /etc/dnsmasq.d/05-custom.conf
   address=/lan/
   address=/local/
   address=/localdomain/
   ```

2. **Troubleshooting**:
   ```bash
   # Monitor blocked requests
   pihole -t
   
   # Check whitelisted domains
   pihole -w -l
   ```

3. **Security Recommendations**:
   - Review the whitelist quarterly
   - Monitor Pi-hole logs for suspicious activity
   - Use SHA256 verification for integrity checks

4. **Contributing**:
   - Submit PRs with justification for new domains
   - Include device/service documentation references
   - Test changes thoroughly before submitting

## 🔗 Repository Information

- **Main Repository**:  
  [https://github.com/TimInTech/Whitelist](https://github.com/TimInTech/Whitelist)
  
- **Direct Whitelist Download**:  
  [https://raw.githubusercontent.com/TimInTech/Whitelist/main/Whitelist.final.personal.txt](https://raw.githubusercontent.com/TimInTech/Whitelist/main/Whitelist.final.personal.txt)
  
- **SHA256 Verification**:
  ```bash
  wget https://raw.githubusercontent.com/TimInTech/Whitelist/main/Whitelist.final.personal.txt.sha256
  sha256sum -c Whitelist.final.personal.txt.sha256
  ```

---

**Maintained by [TimInTech](https://github.com/TimInTech)** | 
**License: [MIT](https://opensource.org/licenses/MIT)** | 
**Contributions Welcome!**
