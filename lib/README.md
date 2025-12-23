# Common Library Documentation

This document describes the shared library functions available in `lib/common.sh`.

## Usage

To use the library in your scripts:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Load common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Now you can use library functions
ensure_dependencies curl dig awk
```

## Functions Reference

### Dependency Management

#### `need(command)`
Check if a command exists in PATH.

**Returns:** 0 if command exists, 1 otherwise

**Example:**
```bash
if need dig; then
  echo "dig is available"
fi
```

#### `ensure_dependencies(command1 command2 ...)`
Ensure required dependencies are installed. Attempts to install missing dependencies via apt on Debian/Ubuntu systems.

**Example:**
```bash
ensure_dependencies curl dig awk sed sort
```

### Filtering and Validation

#### `filter_valid_hosts()`
Filter and validate hostnames from stdin. Removes:
- File extensions (.html, .jpg, etc.)
- Local/LAN domains (.local, .lan, etc.)
- Non-HTTPS services (ntp, mqtt, etc.)
- Alexa capabilities and AMAZON.LITERAL tokens
- www prefix
- Domains longer than 253 characters

**Input:** stdin with one hostname per line  
**Output:** stdout with valid, filtered hostnames

**Example:**
```bash
cat hosts.txt | filter_valid_hosts > filtered.txt
```

#### `extract_hostnames_from_numbered_list(file)`
Extract hostnames from numbered whitelist format (e.g., "123| hostname").

**Parameters:**
- `file`: Path to numbered whitelist file

**Output:** stdout with hostnames only

**Example:**
```bash
extract_hostnames_from_numbered_list "Whitelist.final.personal.txt" > hosts.txt
```

### DNS and Network Checks

#### `check_dns_resolution(hostname)`
Check if a hostname resolves via DNS (A, AAAA, or CNAME records).

**Parameters:**
- `hostname`: Hostname to check

**Returns:** 0 if resolvable, 1 otherwise

**Example:**
```bash
if check_dns_resolution "example.com"; then
  echo "Host is resolvable"
fi
```

#### `check_dns_batch(input_file)`
Check DNS resolution for multiple hosts from a file.

**Parameters:**
- `input_file`: File with one hostname per line

**Output:** Creates two files:
- `<basename>.dns_ok.txt`: Successfully resolved hosts
- `<basename>.dns_fail.txt`: Failed hosts

**Example:**
```bash
check_dns_batch "hosts.txt"
# Creates hosts.dns_ok.txt and hosts.dns_fail.txt
```

#### `check_https_head(hostname [max_hops])`
Check HTTPS HEAD for a hostname and detect redirects.

**Parameters:**
- `hostname`: Hostname to check
- `max_hops`: Maximum redirect hops (default: 3)

**Returns:** 0 if reachable, 1 on timeout/error

**Sets global variables:**
- `HTTPS_CODE`: HTTP status code
- `HTTPS_REDIRECT_TARGET`: Final redirect target (if any)

**Example:**
```bash
if check_https_head "example.com"; then
  echo "HTTPS check succeeded: $HTTPS_CODE"
  if [ -n "$HTTPS_REDIRECT_TARGET" ]; then
    echo "Redirects to: $HTTPS_REDIRECT_TARGET"
  fi
fi
```

### Whitelist Management

#### `renumber_whitelist(file)`
Add sequential numbering to hostnames file.

**Parameters:**
- `file`: Path to file with hostnames

**Output:** stdout with numbered format (N| hostname)

**Example:**
```bash
renumber_whitelist "hosts.txt" > "numbered.txt"
```

#### `create_backup(file)`
Create a backup of a file with .bak extension.

**Parameters:**
- `file`: Path to file to backup

**Example:**
```bash
create_backup "important.txt"
# Creates important.txt.bak
```

### Git Operations

#### `has_git_changes(file)`
Check if a file has uncommitted git changes.

**Parameters:**
- `file`: Path to file

**Returns:** 0 if changes exist, 1 otherwise

**Example:**
```bash
if has_git_changes "config.txt"; then
  echo "File has been modified"
fi
```

#### `commit_and_push(message file1 file2 ...)`
Commit and push changes to git (only if tracking branch exists).

**Parameters:**
- `message`: Commit message
- `file1 file2 ...`: Files to commit

**Example:**
```bash
commit_and_push "Update whitelist" "Whitelist.final.personal.txt"
```

### Utility Functions

#### `print_section(title)`
Print a formatted section header to stderr.

**Parameters:**
- `title`: Section title

**Example:**
```bash
print_section "Step 1: Processing data"
```

#### `count_lines(file)`
Count lines in a file.

**Parameters:**
- `file`: Path to file

**Returns:** Number of lines (0 if file doesn't exist)

**Example:**
```bash
count=$(count_lines "hosts.txt")
echo "File has $count lines"
```

## Constants

The library defines the following constants:

- `FILTER_NEG_PAT`: Regex pattern for non-HTTPS services and local domains
- `FILTER_FILE_EXT`: Pattern for file extensions to filter

## Best Practices

1. Always source the library at the beginning of your script
2. Use `ensure_dependencies` early to check for required tools
3. Pipe operations through `filter_valid_hosts` for consistency
4. Use `create_backup` before modifying important files
5. Use `print_section` for better script output formatting
