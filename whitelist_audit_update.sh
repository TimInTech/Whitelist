#!/usr/bin/env bash
set -euo pipefail

# Konfiguration
REPO_DIR="$(pwd)"
WL_FILE="Whitelist.final.personal.txt"
BACKUP_FILE="${WL_FILE}.bak"

# Optional: Pi-hole Import aktivieren (true/false)
PIHOLE_IMPORT=false

# Timeout/Tries für Netzchecks
CURL_OPTS=(--silent --show-error --location --max-time 5 --retry 1 --tlsv1.2)
DIG_OPTS=(+time=2 +tries=1 +short)

# Abhängigkeiten sicherstellen (Ubuntu/Debian)
need() { command -v "$1" >/dev/null 2>&1; }
if ! need git || ! need curl || ! need grep || ! need awk || ! need sed || ! need sort || ! need comm || ! need nl; then
  if need apt; then
    sudo apt update -y
    sudo apt install -y git curl grep gawk sed coreutils diffutils bsdmainutils || true
  fi
fi

cd "$REPO_DIR"
test -f "$WL_FILE" || { echo "Whitelist-Datei nicht gefunden: $WL_FILE"; exit 1; }

echo "1) Datei normalisieren (Nummern entfernen, Artefakte filtern)…"
# Artefakte/Dateiendungen raus; www. entfernen; Leerzeilen droppen; max Label-Länge
sed 's/^[0-9]\+|[[:space:]]*//' "$WL_FILE" \
  | sed 's/[[:space:]]\+$//' \
  | grep -Ev '\.(html|htm|png|jpg|jpeg|svg|gif|css|js|pdf|ico|webp)$' \
  | sed 's/^\.+//; s/\.+$//' \
  | sed 's/^www\.//' \
  | awk 'length($0)<=253' \
  | sed '/^[[:space:]]*$/d' \
  | sort -u > wl.normalized.txt

echo "2) Bekannte Umzüge/Canonical-Mappings anwenden…"
# Hier pflegbare Regeln: alt -> neu
# Format: ALT|NEU (nur Hostnamen)
cat > mappings.rules <<'MAP'
spotilocal.com|local.spotify.com
gpt.openai.com|api.openai.com
googleapis.com|www.googleapis.com
ota-cloudfront.samsung.com|samsungcloud.com
pool.ntp.org|time.cloudflare.com
MAP

cp wl.normalized.txt wl.mapped.txt
while IFS='|' read -r ALT NEU; do
  [ -z "$ALT" ] && continue
  sed -i "s/^${ALT}$/${NEU}/" wl.mapped.txt
done < mappings.rules
sort -u wl.mapped.txt -o wl.mapped.txt

echo "3) DNS-Check: nur auflösbare Hosts behalten (A/CNAME/AAAA)…"
: > wl.resolvable.txt
if need dig; then
  while read -r h; do
    [ -z "$h" ] && continue
    if dig "${DIG_OPTS[@]}" "$h" A >/dev/null || dig "${DIG_OPTS[@]}" "$h" CNAME >/dev/null || dig "${DIG_OPTS[@]}" "$h" AAAA >/dev/null; then
      echo "$h" >> wl.resolvable.txt
    fi
  done < wl.mapped.txt
else
  # Fallback ohne dig: behalte alles
  cp wl.mapped.txt wl.resolvable.txt
fi
sort -u wl.resolvable.txt -o wl.resolvable.txt

echo "4) HTTPS/Redirect-Check (HEAD) für verdächtige Hosts…"
# Prüfe nur eine Stichprobe: Hosts mit „amazon|alexa|spotify|openai|google|samsung|synology“
grep -Ei 'amazon|alexa|spotify|openai|google|samsung|synology' wl.resolvable.txt | head -n 200 > wl.sample.txt || true
: > redirects.suggest.tsv
while read -r host; do
  [ -z "$host" ] && continue
  code=$(curl -I "${CURL_OPTS[@]}" "https://$host/" 2>/dev/null | awk 'NR==1{print $2}' || true)
  loc=$(curl -I "${CURL_OPTS[@]}" "https://$host/" 2>/dev/null | awk 'tolower($1)=="location:"{print $2; exit}' || true)
  if [[ "$code" =~ ^30[1278]$ ]] && [ -n "$loc" ]; then
    # extrahiere Zielhost
    tld=$(echo "$loc" | awk -F/ '{print $3}' | sed 's/^www\.//' )
    if [ -n "$tld" ] && [ "$tld" != "$host" ]; then
      echo -e "${host}\t${tld}\t${code}" >> redirects.suggest.tsv
    fi
  fi
done < wl.sample.txt

echo "5) Redirect-Vorschläge anwenden (konservativ)…"
cp wl.resolvable.txt wl.updated.txt
if [ -s redirects.suggest.tsv ]; then
  while IFS=$'\t' read -r SRC DST CODE; do
    # Nur ersetzen, wenn Ziel auflösbar ist
    if dig "${DIG_OPTS[@]}" "$DST" A >/dev/null || dig "${DIG_OPTS[@]}" "$DST" CNAME >/dev/null || dig "${DIG_OPTS[@]}" "$DST" AAAA >/dev/null; then
      sed -i "s/^${SRC}$/${DST}/" wl.updated.txt
    fi
  done < redirects.suggest.tsv
fi
sort -u wl.updated.txt -o wl.updated.txt

echo "6) Re-Numbering und Schreiben in ${WL_FILE} (Backup anlegen)…"
cp "$WL_FILE" "$BACKUP_FILE"
awk 'NF{print NR"| "$0}' wl.updated.txt > "$WL_FILE"

echo "7) Git-Commit (nur wenn Änderungen)…"
if ! git diff --quiet -- "$WL_FILE"; then
  git add "$WL_FILE"
  git commit -m "chore(whitelist): normalize, map known moves, dns-check, https redirects applied"
  echo "Committed. Backup: $BACKUP_FILE"
else
  echo "Keine Änderungen im ${WL_FILE}."
fi

echo "8) Optional: Pi-hole Import"
if $PIHOLE_IMPORT && need pihole; then
  # Nur die reinen Hostnamen übergeben
  awk -F'| ' '{print $2}' "$WL_FILE" | xargs -r -I {} pihole allow {}
fi

echo "9) Push zu origin (falls konfiguriert)…"
if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  git push
else
  git push -u origin "$(git branch --show-current)"
fi

echo "Fertig. Artefakte:"
ls -la wl.* mappings.rules redirects.suggest.tsv 2>/dev/null || true
