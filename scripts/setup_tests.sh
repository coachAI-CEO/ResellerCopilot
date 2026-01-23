#!/bin/bash

# Setup and run tests for Reseller Copilot
# This script installs dependencies, generates mocks, and runs tests

set -e  # Exit on error

echo "========================================="
echo "Reseller Copilot - Test Setup"
echo "========================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed or not in PATH"
    echo "Please install Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "Step 1: Installing dependencies..."
flutter pub get

echo ""
echo "Step 2: Generating mock files..."
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "Step 3: Running tests..."
flutter test

echo ""
echo "Step 4: Generating coverage report..."
flutter test --coverage

if command -v genhtml &> /dev/null; then
    echo ""
    echo "Step 5: Creating HTML coverage report..."
    genhtml coverage/lcov.info -o coverage/html
    echo "Coverage report generated at: coverage/html/index.html"
else
    echo ""
    echo "Note: Install lcov to generate HTML coverage reports"
    echo "  macOS: brew install lcov"
    echo "  Linux: sudo apt-get install lcov"
fi

echo ""
echo "========================================="
echo "Test setup complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "  - Dependencies installed"
echo "  - Mock files generated"
echo "  - Tests executed"
echo "  - Coverage report created"
echo ""
echo "To run tests again:"
echo "  flutter test"
echo ""
echo "To run with coverage:"
echo "  flutter test --coverage"
echo ""
echo "To run integration tests:"
echo "  flutter test integration_test/"
