#!/usr/bin/env bash
# Common library functions for Pi-hole whitelist management
# Source this file in other scripts with: source "$(dirname "$0")/lib/common.sh"

set -euo pipefail

# ============================================================================
# Dependency Management
# ============================================================================

# Check if a command exists
# Usage: need command_name
need() {
  command -v "$1" >/dev/null 2>&1
}

# Ensure required dependencies are installed
# Usage: ensure_dependencies command1 command2 ...
ensure_dependencies() {
  local missing=()
  for cmd in "$@"; do
    if ! need "$cmd"; then
      missing+=("$cmd")
    fi
  done
  
  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing dependencies: ${missing[*]}" >&2
    if need apt; then
      echo "Installing via apt..." >&2
      sudo apt update -y
      # Map common commands to package names
      local packages=()
      for cmd in "${missing[@]}"; do
        case "$cmd" in
          dig) packages+=("dnsutils") ;;
          awk) packages+=("gawk") ;;
          *) packages+=("$cmd") ;;
        esac
      done
      sudo apt install -y "${packages[@]}" coreutils || true
    else
      echo "Please install missing dependencies manually" >&2
      return 1
    fi
  fi
}

# ============================================================================
# Filtering and Validation
# ============================================================================

# Negative pattern for non-HTTPS services and local domains
readonly FILTER_NEG_PAT='(^|[.])(ntp|mqtt|ocsp|syncthing|lan|local|localdomain)$|(^nabu\.casa$)|(^hassio-addons\.io$)|(^supervisor\.home-assistant\.io$)'

# File extensions to filter out
readonly FILTER_FILE_EXT='\.html|\.htm|\.png|\.jpg|\.jpeg|\.svg|\.gif|\.css|\.js|\.pdf|\.ico|\.webp|\.zip|\.gz|\.bz2|\.tar'

# Filter and validate hostnames
# Input: stdin with one hostname per line
# Output: stdout with valid hostnames
# Usage: cat hosts.txt | filter_valid_hosts
filter_valid_hosts() {
  grep -E '^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' \
    | grep -Ev "${FILTER_FILE_EXT}\$" \
    | grep -Ev "$FILTER_NEG_PAT" \
    | grep -Ev '^(Alexa\.[A-Za-z0-9]+|AMAZON\.LITERAL)$' \
    | sed 's/^www\.//' \
    | awk 'length($0)<=253' \
    | sort -u
}

# Extract hostnames from numbered whitelist format
# Input: file path to numbered whitelist (format: "123| hostname")
# Output: stdout with hostnames only
# Usage: extract_hostnames_from_numbered_list "Whitelist.final.personal.txt"
extract_hostnames_from_numbered_list() {
  local file="$1"
  awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$NF); print $NF}' "$file"
}

# ============================================================================
# DNS and Network Checks
# ============================================================================

# Check DNS resolution for a single host
# Usage: check_dns_resolution hostname
# Returns: 0 if resolvable, 1 if not
check_dns_resolution() {
  local host="$1"
  local dig_opts=(+time=2 +tries=1 +short)
  
  if ! need dig; then
    # If dig is not available, assume resolvable
    return 0
  fi
  
  dig "${dig_opts[@]}" "$host" A >/dev/null 2>&1 || \
    dig "${dig_opts[@]}" "$host" AAAA >/dev/null 2>&1 || \
    dig "${dig_opts[@]}" "$host" CNAME >/dev/null 2>&1
}

# Check DNS resolution for multiple hosts from file
# Input: file path with one hostname per line
# Output: Creates two files: <basename>.dns_ok.txt and <basename>.dns_fail.txt
# Usage: check_dns_batch "hosts.txt"
check_dns_batch() {
  local input_file="$1"
  local basename="${input_file%.txt}"
  local ok_file="${basename}.dns_ok.txt"
  local fail_file="${basename}.dns_fail.txt"
  
  : > "$ok_file"
  : > "$fail_file"
  
  while IFS= read -r host; do
    [ -z "$host" ] && continue
    if check_dns_resolution "$host"; then
      echo "$host" >> "$ok_file"
    else
      echo "$host" >> "$fail_file"
    fi
  done < "$input_file"
  
  echo "DNS check complete: $(wc -l < "$ok_file") OK, $(wc -l < "$fail_file") FAIL" >&2
}

# Check HTTPS HEAD for a single host and detect redirects
# Usage: check_https_head hostname [max_hops]
# Returns: 0 if reachable, 1 if timeout/error
# Sets global variables: HTTPS_CODE, HTTPS_REDIRECT_TARGET
check_https_head() {
  local host="$1"
  local max_hops="${2:-3}"
  local url="https://$host/"
  local hops=0
  local last="$host"
  
  HTTPS_CODE=""
  HTTPS_REDIRECT_TARGET=""
  
  while [ $hops -lt "$max_hops" ]; do
    local hdr
    if ! hdr=$(curl -I -sS --http1.1 -m 4 -D - "$url" -o /dev/null 2>/dev/null); then
      return 1
    fi
    
    local code=$(printf "%s" "$hdr" | awk 'NR==1{print $2}')
    local loc=$(printf "%s" "$hdr" | awk 'tolower($1)=="location:"{print $2; exit}' | tr -d '\r')
    
    HTTPS_CODE="$code"
    
    if [[ "$code" =~ ^20[0-9]$ ]]; then
      return 0
    fi
    
    if [[ "$code" =~ ^30[1278]$ ]] && [ -n "$loc" ]; then
      local next_host=$(printf "%s" "$loc" | awk -F/ '{print $3}' | sed 's/^www\.//')
      if [ -n "$next_host" ] && [ "$next_host" != "$last" ]; then
        HTTPS_REDIRECT_TARGET="$next_host"
        url="$loc"
        last="$next_host"
        hops=$((hops+1))
        continue
      fi
    fi
    
    break
  done
  
  return 0
}

# ============================================================================
# Whitelist Management
# ============================================================================

# Renumber whitelist file
# Input: file path with hostnames (one per line)
# Output: numbered format (N| hostname) written to stdout
# Usage: renumber_whitelist "hosts.txt" > "numbered.txt"
renumber_whitelist() {
  local file="$1"
  awk 'NF{print NR"| "$0}' "$file"
}

# Create backup of a file
# Usage: create_backup "filename.txt"
create_backup() {
  local file="$1"
  local backup="${file}.bak"
  
  if [ -f "$file" ]; then
    cp "$file" "$backup"
    echo "Backup created: $backup" >&2
  fi
}

# ============================================================================
# Git Operations
# ============================================================================

# Check if file has git changes
# Usage: has_git_changes "filename.txt"
# Returns: 0 if changes exist, 1 if not
has_git_changes() {
  local file="$1"
  ! git diff --quiet -- "$file" 2>/dev/null
}

# Commit and push changes (only if tracking branch exists)
# Usage: commit_and_push "commit message" file1 file2 ...
commit_and_push() {
  local message="$1"
  shift
  local files=("$@")
  
  if [ ${#files[@]} -eq 0 ]; then
    echo "No files specified for commit" >&2
    return 1
  fi
  
  # Check if any files have changes
  local has_changes=false
  for file in "${files[@]}"; do
    if has_git_changes "$file"; then
      has_changes=true
      break
    fi
  done
  
  if [ "$has_changes" = false ]; then
    echo "No changes to commit" >&2
    return 0
  fi
  
  git add "${files[@]}"
  git commit -m "$message"
  
  # Only push if tracking branch exists
  if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    git push
  else
    echo "No tracking branch configured, skipping push" >&2
  fi
}

# ============================================================================
# Utility Functions
# ============================================================================

# Print a section header
# Usage: print_section "Step 1: Processing"
print_section() {
  echo "" >&2
  echo "============================================================================" >&2
  echo "$1" >&2
  echo "============================================================================" >&2
}

# Count lines in file
# Usage: count_lines "file.txt"
count_lines() {
  wc -l < "$1" 2>/dev/null || echo 0
}
