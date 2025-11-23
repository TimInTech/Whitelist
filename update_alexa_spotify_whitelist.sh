#!/usr/bin/env bash
set -euo pipefail

# Load common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Ensure dependencies are available
ensure_dependencies git curl grep awk sed sort comm nl

REPO_DIR="$(pwd)"
cd "$REPO_DIR"

# 1) Versionscheck
git --version
curl --version
grep --version

# 2) Bestehende Alexa/Amazon/Spotify-Einträge extrahieren
grep -Ei '(^|[[:space:]])(amazon|alexa|spotify)' Whitelist.final.personal.txt \
  | sed 's/^[0-9]*| //; s/ *$//' \
  | sort -u > current-alexa-spotify.txt

# 3) Offizielle Quellen (aktualisiert, 404-frei)
SOURCES=(
  "https://developer.amazon.com/en-US/alexa/alexa-voice-service"
  "https://developer.amazon.com/en-US/docs/alexa/documentation-home.html"
  "https://developer.amazon.com/en-US/docs/alexa/smarthome/understand-the-smart-home-skill-api.html"
  "https://developer.amazon.com/en-US/docs/alexa/device-apis/smart-home-general-apis.html"
  "https://developer.spotify.com/documentation/web-api"
  "https://developer.spotify.com/documentation/web-api/concepts/api-calls"
  "https://developer.spotify.com/documentation/web-api/tutorials/getting-started"
)

# 4) Crawl + Host-Extraktion
> new-hosts-raw.txt
for url in "${SOURCES[@]}"; do
  echo "Fetching: $url" >&2
  curl -fsSL "$url" | tr '"'\''<>()[]{} ' '\n' | grep -Eo '([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})' || true
done > new-hosts-raw.txt

# 5) Filter: echte Hostnamen, keine Dateinamen/Seiten, keine Capability-Tokens
cat new-hosts-raw.txt \
  | grep -Ei 'amazon|alexa|spotify' \
  | sed -E 's/[:/].*$//' \
  | sed 's/^\.+//; s/\.+$//' \
  | sed 's/^www\.//' \
  | grep -Ev '\.(html|htm|png|jpg|jpeg|svg|gif|css|js|pdf|ico|webp)$' \
  | grep -Ev '^[A-Za-z0-9._-]+\.a2z\.com$' \
  | grep -Ev '^(Alexa\.[A-Za-z0-9]+|AMAZON\.LITERAL)$' \
  | awk 'length($0)<=253' \
  | sort -u > new-hosts-candidates.txt

# 6) Vergleichen
sort -u current-alexa-spotify.txt > current.sorted.txt
sort -u new-hosts-candidates.txt > new.sorted.txt
comm -23 new.sorted.txt current.sorted.txt > additions-candidate.txt || true

# 7) Optional: DNS-Livecheck (aufloesbare Hosts behalten)
if need dig && [ -s additions-candidate.txt ]; then
  echo "DNS-Check (optional) läuft ..."
  check_dns_batch "additions-candidate.txt"
  
  # Replace additions-candidate.txt with DNS-validated version
  if [ -s "additions-candidate.dns_ok.txt" ]; then
    mv additions-candidate.dns_ok.txt additions-candidate.txt
    echo "DNS-Check fertig, nur auflösbare Hosts verbleiben."
  else
    echo "Keine auflösbaren Hosts gefunden; überspringe Anhängen."
    : > additions-candidate.txt
  fi
fi

# 8) Review-Ausgabe
echo "Neue Kandidaten (prüfen und ggf. übernehmen):"
nl -ba additions-candidate.txt || true

# 9) Sicher anfügen + neu nummerieren
if [ -s additions-candidate.txt ]; then
  create_backup Whitelist.final.personal.txt
  cat additions-candidate.txt >> Whitelist.final.personal.txt
  renumber_whitelist Whitelist.final.personal.txt > Whitelist.final.personal.txt.tmp
  mv Whitelist.final.personal.txt.tmp Whitelist.final.personal.txt
  git add Whitelist.final.personal.txt
  git commit -m "chore(whitelist): add/update Amazon Alexa + Spotify hostnames (filtered)"
  echo "Committed. Backup: Whitelist.final.personal.txt.bak"
else
  echo "Keine neuen Kandidaten gefunden."
fi
