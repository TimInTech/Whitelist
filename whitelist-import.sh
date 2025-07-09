#!/bin/bash
set -e

# Configuration
REPO_URL="https://github.com/TimInTech/Whitelist"
WL_URL="${REPO_URL}/raw/main/Whitelist.final.personal.txt"
LOCAL_FILE="${PWD}/Whitelist.final.personal.txt"
TMP_FILE="/tmp/whitelist-import.txt"
GRAVITY_DB="/etc/pihole/gravity.db"
DRY_RUN=false
LOCAL_MODE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_deps() {
  for cmd in pihole wget sqlite3; do
    if ! command -v $cmd &> /dev/null; then
      echo -e "${RED}Error: Missing required command '$cmd'${NC}" >&2
      exit 1
    fi
  done
}

verify_checksum() {
  local file=$1
  local expected_sha=$(wget -qO - "${WL_URL}.sha256" || echo "")
  if [ -n "$expected_sha" ]; then
    local actual_sha=$(sha256sum "$file" | cut -d' ' -f1)
    if [ "$expected_sha" != "$actual_sha" ]; then
      echo -e "${RED}Checksum verification failed!${NC}"
      echo -e "Expected: ${YELLOW}$expected_sha${NC}"
      echo -e "Actual:   ${YELLOW}$actual_sha${NC}"
      return 1
    fi
  fi
  return 0
}

import_domains() {
  local count=0
  local skipped=0
  while IFS= read -r domain; do
    [[ $domain =~ ^#.*$ || -z $domain ]] && continue
    if sqlite3 "$GRAVITY_DB" "SELECT domain FROM domainlist WHERE domain='$domain' AND type=0;" | grep -q .; then
      echo -e "${YELLOW}[SKIP]${NC} $domain (already whitelisted)"
      ((skipped++))
      continue
    fi
    if ! $DRY_RUN; then
      pihole -w -q "$domain" >/dev/null
    fi
    echo -e "${GREEN}[ADD]${NC} $domain"
    ((count++))
  done < "$TMP_FILE"
  echo -e "\nProcessed: ${GREEN}$count domains${NC}"
  echo "Skipped:   $skipped duplicates"
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=true; shift ;;
      --local) LOCAL_MODE=true; shift ;;
      *) echo "Unknown option: $1"; exit 1 ;;
    esac
  done

  check_deps

  echo -e "\n${YELLOW}=== Pi-hole Whitelist Importer ===${NC}"
  if $LOCAL_MODE; then
    echo "Using local file: $LOCAL_FILE"
    cp "$LOCAL_FILE" "$TMP_FILE"
  else
    echo "Downloading whitelist from: $WL_URL"
    wget -q -O "$TMP_FILE" "$WL_URL"
    if ! verify_checksum "$TMP_FILE"; then
      echo -e "${YELLOW}Using local fallback file${NC}"
      cp "$LOCAL_FILE" "$TMP_FILE"
    fi
  fi

  if [ ! -s "$TMP_FILE" ]; then
    echo -e "${RED}Error: Whitelist file is empty!${NC}" >&2
    exit 1
  fi

  echo -e "\n${YELLOW}Beginning import...${NC}"
  import_domains

  if ! $DRY_RUN; then
    echo -e "\nUpdating Pi-hole gravity..."
    pihole restartdns >/dev/null
    echo -e "${GREEN}DNS cache flushed${NC}"
  fi

  rm -f "$TMP_FILE"
  echo -e "\n${GREEN}Operation completed successfully!${NC}"
}

main "$@"
