#!/usr/bin/env bash
set -euo pipefail

# --- Abhängigkeiten sicherstellen (Ubuntu/Debian) ---
need() { command -v "$1" >/dev/null 2>&1 || return 1; }
if ! need git || ! need curl || ! need grep || ! need awk || ! need sed || ! need sort || ! need comm || ! need nl; then
  if need apt; then
    sudo apt update -y
    sudo apt install -y git curl grep gawk sed coreutils diffutils bsdmainutils || true
  fi
fi

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
if command -v dig >/dev/null 2>&1 && [ -s additions-candidate.txt ]; then
  echo "DNS-Check (optional) läuft ..."
  : > additions-resolvable.txt
  while read -r host; do
    [ -z "$host" ] && continue
    if dig +time=2 +tries=1 +short "$host" A >/dev/null || dig +time=2 +tries=1 +short "$host" CNAME >/dev/null; then
      echo "$host" >> additions-resolvable.txt
    fi
  done < additions-candidate.txt
  if [ -s additions-resolvable.txt ]; then
    mv additions-resolvable.txt additions-candidate.txt
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
  cp Whitelist.final.personal.txt Whitelist.final.personal.txt.bak
  cat additions-candidate.txt >> Whitelist.final.personal.txt
  awk 'NF{print NR"| "$0}' Whitelist.final.personal.txt > Whitelist.final.personal.txt.tmp
  mv Whitelist.final.personal.txt.tmp Whitelist.final.personal.txt
  git add Whitelist.final.personal.txt
  git commit -m "chore(whitelist): add/update Amazon Alexa + Spotify hostnames (filtered)"
  echo "Committed. Backup: Whitelist.final.personal.txt.bak"
else
  echo "Keine neuen Kandidaten gefunden."
fi
