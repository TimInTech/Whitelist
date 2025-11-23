#!/usr/bin/env bash
set -euo pipefail

# Regeneriert Whitelist.final.personal.plain.txt aus Whitelist.final.personal.txt
# mit vollständiger Filterung

# Load common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

REPO_DIR="$(pwd)"
WL_NBR="Whitelist.final.personal.txt"
WL_PLAIN="Whitelist.final.personal.plain.txt"

cd "$REPO_DIR"
test -f "$WL_NBR" || { echo "Fehlt: $WL_NBR"; exit 1; }

echo "Regeneriere Plain-Whitelist mit vollständiger Filterung..."

# Backup der aktuellen Plain-Datei, falls vorhanden
create_backup "$WL_PLAIN"

# 1) Extrahiere Hostnamen aus nummerierter Whitelist (letzte Spalte)
# 2) Filtere nur gültige FQDNs, entferne Dateiendungen, lokale/LAN/Service-Hosts, etc.
# 3) Sortiere und dedupliziere
extract_hostnames_from_numbered_list "$WL_NBR" \
  | filter_valid_hosts > "$WL_PLAIN"

echo "Fertig: $(count_lines "$WL_PLAIN") Hosts in $WL_PLAIN"
[ -f "${WL_PLAIN}.bak" ] && echo "Backup: ${WL_PLAIN}.bak"
