#!/bin/bash

set -euo pipefail

echo "🧪 Testing local binary optimization..."

# Create a test directory
TEST_DIR="test-output"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Copy files needed for test
cp ../config.json .
cp ../optimize-binaries.sh .
chmod +x optimize-binaries.sh

echo "📋 Configuration:"
cat config.json

echo ""
echo "🚀 Running optimization script..."
./optimize-binaries.sh

echo ""
echo "📁 Generated files:"
ls -la *.tar.gz 2>/dev/null || echo "No .tar.gz files found"

echo ""
echo "🔍 Testing one of the generated archives..."
if ls *.tar.gz 1> /dev/null 2>&1; then
    FIRST_ARCHIVE=$(ls *.tar.gz | head -n1)
    echo "Testing: $FIRST_ARCHIVE"
    
    # Extract and test
    mkdir -p test-extract
    tar -xzf "$FIRST_ARCHIVE" -C test-extract
    echo "Contents:"
    ls -la test-extract/
    
    # Check if binary is executable
    BINARY=$(find test-extract -name "clang-format*" -type f | head -n1)
    if [[ -n "$BINARY" ]]; then
        echo "✅ Binary found: $BINARY"
        if [[ -x "$BINARY" ]]; then
            echo "✅ Binary is executable"
            echo "🔧 Testing binary..."
            "$BINARY" --version || echo "⚠️ Binary test failed (might be expected on different platforms)"
        else
            echo "❌ Binary is not executable"
        fi
    else
        echo "❌ No clang-format binary found in archive"
    fi
    
    # Clean up test extraction
    rm -rf test-extract
else
    echo "❌ No archives were generated"
    exit 1
fi

echo ""
echo "✨ Local test completed!"
echo "💡 To clean up: rm -rf $TEST_DIR"
