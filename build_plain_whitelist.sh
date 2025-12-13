#!/usr/bin/env bash
set -euo pipefail

# Regeneriert Whitelist.final.personal.plain.txt aus Whitelist.final.personal.txt
# mit vollständiger Filterung

REPO_DIR="$(pwd)"
WL_NBR="Whitelist.final.personal.txt"
WL_PLAIN="Whitelist.final.personal.plain.txt"

cd "$REPO_DIR"
test -f "$WL_NBR" || { echo "Fehlt: $WL_NBR"; exit 1; }

# Negativliste für Nicht-HTTPS-Dienste/Hostmuster
NEG_PAT='(^|[.])(ntp|mqtt|ocsp|syncthing|lan|local|localdomain)$|(^nabu\.casa$)|(^hassio-addons\.io$)|(^supervisor\.home-assistant\.io$)'

echo "Regeneriere Plain-Whitelist mit vollständiger Filterung..."

# Backup der aktuellen Plain-Datei, falls vorhanden
[ -f "$WL_PLAIN" ] && cp "$WL_PLAIN" "${WL_PLAIN}.bak"

# 1) Extrahiere Hostnamen aus nummerierter Whitelist (letzte Spalte)
# 2) Filtere nur gültige FQDNs
# 3) Entferne Dateiendungen
# 4) Entferne lokale/LAN/Service-Hosts
# 5) Entferne Alexa-Capabilities und AMAZON.LITERAL
# 6) Entferne www-Präfix
# 7| Prüfe Länge
# 8) Sortiere und dedupliziere
awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$NF); print $NF}' "$WL_NBR" \
  | grep -E '^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' \
  | grep -Ev '\.(html|htm|png|jpg|jpeg|svg|gif|css|js|pdf|ico|webp|zip|gz|bz2|tar)$' \
  | grep -Ev "$NEG_PAT" \
  | grep -Ev '^(Alexa\.[A-Za-z0-9]+|AMAZON\.LITERAL)$' \
  | sed 's/^www\.//' \
  | awk 'length($0)<=253' \
  | sort -u > "$WL_PLAIN"

echo "Fertig: $(wc -l < "$WL_PLAIN") Hosts in $WL_PLAIN"
[ -f "${WL_PLAIN}.bak" ] && echo "Backup: ${WL_PLAIN}.bak"
