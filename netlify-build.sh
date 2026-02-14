#!/usr/bin/env bash
set -euo pipefail

# Choose a stable Flutter version
FLUTTER_VERSION="3.19.0"

echo "Downloading Flutter $FLUTTER_VERSION..."
curl -sSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o flutter.tar.xz

echo "Extracting Flutter..."
tar -xf flutter.tar.xz -C $HOME

export FLUTTER_ROOT="$HOME/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"

# Prepare Flutter for web
echo "Configuring Flutter..."
flutter config --no-analytics
flutter config --enable-web

# Show versions
flutter --version

# Run the build
echo "Starting Flutter Build..."
flutter build web --no-tree-shake-icons --release

echo "Build finished successfully."
