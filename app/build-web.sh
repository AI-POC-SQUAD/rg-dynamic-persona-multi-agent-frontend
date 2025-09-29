#!/bin/bash

# Build script for consistent Flutter web rendering
echo "Building Flutter web app with HTML renderer..."

# Clean previous builds
flutter clean
flutter pub get

# Build with HTML renderer to avoid canvas issues
flutter build web --release --web-renderer html --no-tree-shake-icons

echo "Build complete!"