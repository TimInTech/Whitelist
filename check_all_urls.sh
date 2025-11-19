#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(pwd)"
WL_NBR="Whitelist.final.personal.txt"
WL_PLAIN="Whitelist.final.personal.plain.txt"

# Tools prüfen/installieren (Ubuntu/Debian)
need(){ command -v "$1" >/dev/null 2>&1; }
if ! need curl || ! need dig || ! need awk || ! need sed || ! need sort; then
  if need apt; then
    sudo apt update -y
    sudo apt install -y curl dnsutils gawk sed coreutils || true
  fi
fi

cd "$REPO_DIR"
test -f "$WL_NBR" || { echo "Fehlt: $WL_NBR"; exit 1; }

# --- CA-Bundle laden und setzen ---
CA_FILE="$PWD/cacert.pem"
[ -f "$CA_FILE" ] || curl -sSL https://curl.se/ca/cacert.pem -o "$CA_FILE"
export CURL_CA_BUNDLE="$CA_FILE"

# --- Negativliste für Nicht-HTTPS-Dienste/Hostmuster ---
NEG_PAT='(^|[.])(ntp|mqtt|ocsp|syncthing|lan|local|localdomain)$|(^nabu\.casa$)|(^hassio-addons\.io$)|(^supervisor\.home-assistant\.io$)'

# 1) Plain-Whitelist erzeugen mit vollständiger Filterung
awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$NF); print $NF}' "$WL_NBR" \
  | grep -E '^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' \
  | grep -Ev '\.(html|htm|png|jpg|jpeg|svg|gif|css|js|pdf|ico|webp|zip|gz|bz2|tar)$' \
  | grep -Ev "$NEG_PAT" \
  | grep -Ev '^(Alexa\.[A-Za-z0-9]+|AMAZON\.LITERAL)$' \
  | sed 's/^www\.//' \
  | awk 'length($0)<=253' \
  | sort -u > "$WL_PLAIN"

echo "Hosts in Prüfung: $(wc -l < "$WL_PLAIN")"

# 2) DNS-Check (A/AAAA/CNAME)
: > urls.dns_ok.txt
: > urls.dns_fail.txt
while read -r h; do
  [ -z "$h" ] && continue
  if dig +time=2 +tries=1 +short "$h" A >/dev/null || dig +time=2 +tries=1 +short "$h" AAAA >/dev/null || dig +time=2 +tries=1 +short "$h" CNAME >/dev/null; then
    echo "$h" >> urls.dns_ok.txt
  else
    echo "$h" >> urls.dns_fail.txt
  fi
done < "$WL_PLAIN"

# 3) HTTPS-HEAD Check + Redirect-Kette (max. 3 Hops)
: > urls.http_suggest.tsv
: > urls.http_timeout.txt
: > urls.http_ok.txt

check_head() {
  local host="$1"
  local url="https://$host/"
  local hops=0
  local last="$host"
  while [ $hops -lt 3 ]; do
    # Status und Location lesen mit CA-Bundle
    local hdr
    if ! hdr=$(curl -I -sS --http1.1 -m 4 -D - "$url" -o /dev/null 2>/dev/null); then
      echo "$host" >> urls.http_timeout.txt
      return
    fi
    local code=$(printf "%s" "$hdr" | awk 'NR==1{print $2}')
    local loc=$(printf "%s" "$hdr" | awk 'tolower($1)=="location:"{print $2; exit}' | tr -d '\r')
    if [[ "$code" =~ ^20[0-9]$ ]]; then
      echo "$host" >> urls.http_ok.txt
      return
    fi
    if [[ "$code" =~ ^30[1278]$ ]] && [ -n "$loc" ]; then
      # neuen Host extrahieren
      local next_host=$(printf "%s" "$loc" | awk -F/ '{print $3}' | sed 's/^www\.//')
      if [ -n "$next_host" ] && [ "$next_host" != "$last" ]; then
        # Vorschlag nur notieren, endgültig nicht ersetzen
        echo -e "${last}\t${next_host}\t${code}" >> urls.http_suggest.tsv
        url="$loc"
        last="$next_host"
        hops=$((hops+1))
        continue
      fi
    fi
    # andere Codes abbrechen
    break
  done
}

# Nur für DNS-ok Hosts HTTPS prüfen
while read -r h; do
  [ -z "$h" ] && continue
  check_head "$h"
done < urls.dns_ok.txt

# 4) Zusammenfassung ausgeben
echo "DNS OK:      $(wc -l < urls.dns_ok.txt)"
echo "DNS FAIL:    $(wc -l < urls.dns_fail.txt)"
echo "HTTP OK:     $(wc -l < urls.http_ok.txt)"
echo "Redirects:   $(wc -l < urls.http_suggest.tsv)"
echo "Timeouts:    $(wc -l < urls.http_timeout.txt)"

# 5) Konservative Vorschlagsliste als Markdown-Tabelle generieren
{
  echo "| Quelle | Vorschlag | Code |"
  echo "|--------|-----------|------|"
  sort -u urls.http_suggest.tsv | awk -F'\t' '{printf("| %s | %s | %s |\n",$1,$2,$3)}'
} > urls.redirect_suggestions.md

# 6) Optionale Aktualisierungsvorlage erzeugen (nur existierende Ziele)
: > urls.redirect_apply.rules
if [ -s urls.http_suggest.tsv ]; then
  while IFS=$'\t' read -r SRC DST CODE; do
    if dig +time=2 +tries=1 +short "$DST" A >/dev/null || dig +time=2 +tries=1 +short "$DST" AAAA >/dev/null || dig +time=2 +tries=1 +short "$DST" CNAME >/dev/null; then
      echo "${SRC}|${DST}" >> urls.redirect_apply.rules
    fi
  done < <(sort -u urls.http_suggest.tsv)
fi

echo "Fertig. Dateien:"
ls -la urls.* 2>/dev/null || true
echo "Prüfe urls.redirect_suggestions.md und entscheide, welche Redirects angewendet werden sollen."
echo "Anwenden (optional, konservativ):"
echo "  while IFS='|' read -r A B; do sed -i \"s/^\${A}$/\${B}/\" \"$WL_PLAIN\"; done < urls.redirect_apply.rules && sort -u \"$WL_PLAIN\" -o \"$WL_PLAIN\""
