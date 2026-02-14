#!/usr/bin/env bash
set -euo pipefail

# Define Flutter version
FLUTTER_VERSION="3.19.0"

echo "Installing Flutter $FLUTTER_VERSION..."

# Download and extract Flutter to a temporary directory
git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
export PATH="$HOME/flutter/bin:$PATH"

# Run flutter doctor to check setup
flutter doctor -v

# Enable web support
flutter config --enable-web

# Get dependencies
flutter pub get

# Build the application
echo "Building Flutter Web App..."
flutter build web --no-tree-shake-icons --release

echo "Build complete."
