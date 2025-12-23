#!/usr/bin/env bash
# Test runner for all tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Running all tests for Whitelist project"
echo "=========================================="
echo ""

EXIT_CODE=0

# Run unit tests
echo "Running unit tests..."
echo ""
if bash "$SCRIPT_DIR/test_common.sh"; then
  echo ""
else
  echo ""
  EXIT_CODE=1
fi

# Run integration tests
echo "Running integration tests..."
echo ""
if bash "$SCRIPT_DIR/test_integration.sh"; then
  echo ""
else
  echo ""
  EXIT_CODE=1
fi

# Summary
if [ $EXIT_CODE -eq 0 ]; then
  echo "=========================================="
  echo "✓ All test suites passed!"
  echo "=========================================="
else
  echo "=========================================="
  echo "✗ Some test suites failed"
  echo "=========================================="
fi

exit $EXIT_CODE
