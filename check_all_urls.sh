#!/usr/bin/env bash
set -euo pipefail

# Load common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

REPO_DIR="$(pwd)"
WL_NBR="Whitelist.final.personal.txt"
WL_PLAIN="Whitelist.final.personal.plain.txt"

# Tools prüfen/installieren (Ubuntu/Debian)
ensure_dependencies curl dig awk sed sort

cd "$REPO_DIR"
test -f "$WL_NBR" || { echo "Fehlt: $WL_NBR"; exit 1; }

# --- CA-Bundle laden und setzen ---
CA_FILE="$PWD/cacert.pem"
[ -f "$CA_FILE" ] || curl -sSL https://curl.se/ca/cacert.pem -o "$CA_FILE"
export CURL_CA_BUNDLE="$CA_FILE"

print_section "1) Plain-Whitelist erzeugen mit vollständiger Filterung"
extract_hostnames_from_numbered_list "$WL_NBR" \
  | filter_valid_hosts > "$WL_PLAIN"

echo "Hosts in Prüfung: $(count_lines "$WL_PLAIN")"

print_section "2) DNS-Check (A/AAAA/CNAME)"
check_dns_batch "$WL_PLAIN"

print_section "3) HTTPS-HEAD Check + Redirect-Kette (max. 3 Hops)"
: > urls.http_suggest.tsv
: > urls.http_timeout.txt
: > urls.http_ok.txt

# Nur für DNS-ok Hosts HTTPS prüfen
while read -r h; do
  [ -z "$h" ] && continue
  if check_https_head "$h"; then
    echo "$h" >> urls.http_ok.txt
    if [ -n "$HTTPS_REDIRECT_TARGET" ]; then
      echo -e "${h}\t${HTTPS_REDIRECT_TARGET}\t${HTTPS_CODE}" >> urls.http_suggest.tsv
    fi
  else
    echo "$h" >> urls.http_timeout.txt
  fi
done < urls.dns_ok.txt

print_section "4) Zusammenfassung"
echo "DNS OK:      $(count_lines urls.dns_ok.txt)"
echo "DNS FAIL:    $(count_lines urls.dns_fail.txt)"
echo "HTTP OK:     $(count_lines urls.http_ok.txt)"
echo "Redirects:   $(count_lines urls.http_suggest.tsv)"
echo "Timeouts:    $(count_lines urls.http_timeout.txt)"

print_section "5) Konservative Vorschlagsliste als Markdown-Tabelle generieren"
{
  echo "| Quelle | Vorschlag | Code |"
  echo "|--------|-----------|------|"
  sort -u urls.http_suggest.tsv | awk -F'\t' '{printf("| %s | %s | %s |\n",$1,$2,$3)}'
} > urls.redirect_suggestions.md

print_section "6) Optionale Aktualisierungsvorlage erzeugen (nur existierende Ziele)"
: > urls.redirect_apply.rules
if [ -s urls.http_suggest.tsv ]; then
  while IFS=$'\t' read -r SRC DST CODE; do
    if check_dns_resolution "$DST"; then
      echo "${SRC}|${DST}" >> urls.redirect_apply.rules
    fi
  done < <(sort -u urls.http_suggest.tsv)
fi

echo ""
echo "Fertig. Dateien:"
ls -la urls.* 2>/dev/null || true
echo ""
echo "Prüfe urls.redirect_suggestions.md und entscheide, welche Redirects angewendet werden sollen."
echo "Anwenden (optional, konservativ):"
echo "  while IFS='|' read -r A B; do sed -i \"s/^\${A}$/\${B}/\" \"$WL_PLAIN\"; done < urls.redirect_apply.rules && sort -u \"$WL_PLAIN\" -o \"$WL_PLAIN\""
