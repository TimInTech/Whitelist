#!/usr/bin/env bash
# Integration tests for whitelist workflow

set -euo pipefail

# Load the library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Test framework variables
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

assert_file_exists() {
  local file="$1"
  local test_name="$2"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [ -f "$file" ]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $test_name"
    echo "  File does not exist: $file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_command_succeeds() {
  local test_name="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "✓ PASS: $test_name"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

assert_command_fails() {
  local test_name="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "✗ FAIL: $test_name"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Create test environment
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "=========================================="
echo "Running integration tests"
echo "=========================================="
echo ""

# ============================================================================
# Test: build_plain_whitelist.sh workflow
# ============================================================================
echo "Testing build_plain_whitelist.sh workflow..."

# Create test data
cat > "$TEST_DIR/Whitelist.final.personal.txt" <<EOF
1| example.com
2| www.test.org
3| invalid.html
4| test.local
5| api.spotify.com
6| Alexa.Thermostat
7| amazon.com
EOF

cd "$TEST_DIR"

# Run the filtering logic manually (simulating build_plain_whitelist.sh)
extract_hostnames_from_numbered_list "Whitelist.final.personal.txt" \
  | filter_valid_hosts > "Whitelist.final.personal.plain.txt"

assert_file_exists "$TEST_DIR/Whitelist.final.personal.plain.txt" "build_plain_whitelist: creates plain whitelist"

# Verify content - should have only valid hosts
line_count=$(wc -l < "$TEST_DIR/Whitelist.final.personal.plain.txt")
if [ "$line_count" -eq 4 ]; then
  echo "✓ PASS: build_plain_whitelist: filters invalid entries correctly"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL: build_plain_whitelist: filters invalid entries correctly"
  echo "  Expected 4 lines, got $line_count"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Check that www was removed
if grep -q "^test.org$" "$TEST_DIR/Whitelist.final.personal.plain.txt"; then
  echo "✓ PASS: build_plain_whitelist: removes www prefix"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL: build_plain_whitelist: removes www prefix"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

echo ""

# ============================================================================
# Test: Renumbering workflow
# ============================================================================
echo "Testing renumbering workflow..."

cat > "$TEST_DIR/hosts_unordered.txt" <<EOF
spotify.com
amazon.com
google.com
EOF

renumber_whitelist "$TEST_DIR/hosts_unordered.txt" > "$TEST_DIR/hosts_numbered.txt"

assert_file_exists "$TEST_DIR/hosts_numbered.txt" "renumber: creates numbered file"

# Check first and last lines
first_line=$(head -1 "$TEST_DIR/hosts_numbered.txt")
if [ "$first_line" = "1| spotify.com" ]; then
  echo "✓ PASS: renumber: first line is correctly numbered"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL: renumber: first line is correctly numbered"
  echo "  Expected '1| spotify.com', got '$first_line'"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

last_line=$(tail -1 "$TEST_DIR/hosts_numbered.txt")
if [ "$last_line" = "3| google.com" ]; then
  echo "✓ PASS: renumber: last line is correctly numbered"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL: renumber: last line is correctly numbered"
  echo "  Expected '3| google.com', got '$last_line'"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

echo ""

# ============================================================================
# Test: Round-trip workflow (numbered -> plain -> numbered)
# ============================================================================
echo "Testing round-trip workflow..."

cat > "$TEST_DIR/original.txt" <<EOF
1| api.example.com
2| cdn.example.org
3| www.example.net
EOF

# Extract to plain
extract_hostnames_from_numbered_list "$TEST_DIR/original.txt" \
  | filter_valid_hosts > "$TEST_DIR/plain.txt"

# Renumber
renumber_whitelist "$TEST_DIR/plain.txt" > "$TEST_DIR/renumbered.txt"

# Check that hostnames are preserved (order might differ due to sort)
original_hosts=$(extract_hostnames_from_numbered_list "$TEST_DIR/original.txt" | filter_valid_hosts | sort)
roundtrip_hosts=$(extract_hostnames_from_numbered_list "$TEST_DIR/renumbered.txt" | sort)

if [ "$original_hosts" = "$roundtrip_hosts" ]; then
  echo "✓ PASS: round-trip: preserves all hostnames"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL: round-trip: preserves all hostnames"
  echo "  Original:"
  echo "$original_hosts"
  echo "  Round-trip:"
  echo "$roundtrip_hosts"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

echo ""

# ============================================================================
# Summary
# ============================================================================
echo "=========================================="
echo "Integration Test Summary"
echo "=========================================="
echo "Total tests run:    $TESTS_RUN"
echo "Tests passed:       $TESTS_PASSED"
echo "Tests failed:       $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All integration tests passed!"
  exit 0
else
  echo "✗ Some integration tests failed"
  exit 1
fi
