#!/usr/bin/env bash
# Unit tests for lib/common.sh

set -euo pipefail

# Load the library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Test framework variables
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test framework functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [ "$expected" = "$actual" ]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected: '$expected'"
    echo "  Actual:   '$actual'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_true() {
  local test_name="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "✓ PASS: $test_name"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

assert_false() {
  local test_name="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "✗ FAIL: $test_name"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Create test data directory
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "=========================================="
echo "Running tests for lib/common.sh"
echo "=========================================="
echo ""

# ============================================================================
# Test: filter_valid_hosts
# ============================================================================
echo "Testing filter_valid_hosts..."

# Test valid hostname
result=$(echo "example.com" | filter_valid_hosts)
assert_equals "example.com" "$result" "filter_valid_hosts: accepts valid hostname"

# Test www prefix removal
result=$(echo "www.example.com" | filter_valid_hosts)
assert_equals "example.com" "$result" "filter_valid_hosts: removes www prefix"

# Test file extension filtering
result=$(echo "example.html" | filter_valid_hosts | wc -l || true)
assert_equals "0" "$result" "filter_valid_hosts: filters .html files"

# Test local domain filtering
result=$(echo "test.local" | filter_valid_hosts | wc -l || true)
assert_equals "0" "$result" "filter_valid_hosts: filters .local domains"

# Test Alexa capability filtering
result=$(echo "Alexa.Thermostat" | filter_valid_hosts | wc -l || true)
assert_equals "0" "$result" "filter_valid_hosts: filters Alexa capabilities"

# Test length validation (max 253 chars)
long_domain=$(printf 'a%.0s' {1..260}).com
result=$(echo "$long_domain" | filter_valid_hosts | wc -l || true)
assert_equals "0" "$result" "filter_valid_hosts: filters domains longer than 253 chars"

# Test multiple valid hosts
cat > "$TEST_DIR/hosts.txt" <<EOF
example.com
www.test.org
invalid.html
local.lan
api.spotify.com
EOF
result=$(filter_valid_hosts < "$TEST_DIR/hosts.txt" | wc -l)
assert_equals "3" "$result" "filter_valid_hosts: processes multiple hosts correctly"

echo ""

# ============================================================================
# Test: extract_hostnames_from_numbered_list
# ============================================================================
echo "Testing extract_hostnames_from_numbered_list..."

cat > "$TEST_DIR/numbered.txt" <<EOF
1| example.com
2| test.org
3| api.example.net
EOF
result=$(extract_hostnames_from_numbered_list "$TEST_DIR/numbered.txt" | wc -l)
assert_equals "3" "$result" "extract_hostnames_from_numbered_list: extracts all hostnames"

# Test with extra spaces
cat > "$TEST_DIR/numbered_spaces.txt" <<EOF
1|   example.com   
2| test.org
EOF
result=$(extract_hostnames_from_numbered_list "$TEST_DIR/numbered_spaces.txt" | head -1)
assert_equals "example.com" "$result" "extract_hostnames_from_numbered_list: trims whitespace"

echo ""

# ============================================================================
# Test: renumber_whitelist
# ============================================================================
echo "Testing renumber_whitelist..."

cat > "$TEST_DIR/plain_hosts.txt" <<EOF
example.com
test.org
api.example.net
EOF
result=$(renumber_whitelist "$TEST_DIR/plain_hosts.txt" | head -1)
assert_equals "1| example.com" "$result" "renumber_whitelist: adds correct numbering"

result=$(renumber_whitelist "$TEST_DIR/plain_hosts.txt" | tail -1)
assert_equals "3| api.example.net" "$result" "renumber_whitelist: numbers all lines sequentially"

echo ""

# ============================================================================
# Test: create_backup
# ============================================================================
echo "Testing create_backup..."

echo "test content" > "$TEST_DIR/test.txt"
create_backup "$TEST_DIR/test.txt" 2>/dev/null
if [ -f "$TEST_DIR/test.txt.bak" ]; then
  assert_true "create_backup: creates .bak file"
else
  assert_false "create_backup: creates .bak file"
fi

backup_content=$(cat "$TEST_DIR/test.txt.bak")
assert_equals "test content" "$backup_content" "create_backup: preserves file content"

echo ""

# ============================================================================
# Test: count_lines
# ============================================================================
echo "Testing count_lines..."

cat > "$TEST_DIR/count_test.txt" <<EOF
line1
line2
line3
EOF
result=$(count_lines "$TEST_DIR/count_test.txt")
assert_equals "3" "$result" "count_lines: counts lines correctly"

result=$(count_lines "$TEST_DIR/nonexistent.txt")
assert_equals "0" "$result" "count_lines: returns 0 for missing file"

echo ""

# ============================================================================
# Test: check_dns_resolution (if dig is available)
# ============================================================================
echo "Testing check_dns_resolution..."

if need dig; then
  # Test with well-known domain
  if check_dns_resolution "google.com"; then
    assert_true "check_dns_resolution: resolves google.com"
  else
    assert_false "check_dns_resolution: resolves google.com"
  fi
  
  # Test with invalid domain (note: some DNS resolvers may still resolve this)
  if check_dns_resolution "this-domain-definitely-does-not-exist-12345.invalid"; then
    echo "⊘ SKIP: check_dns_resolution negative test (DNS resolver returns results for invalid domains)"
  else
    assert_true "check_dns_resolution: fails on invalid domain"
  fi
else
  echo "⊘ SKIP: check_dns_resolution tests (dig not available)"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total tests run:    $TESTS_RUN"
echo "Tests passed:       $TESTS_PASSED"
echo "Tests failed:       $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
