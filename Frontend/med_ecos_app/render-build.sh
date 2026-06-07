#!/usr/bin/env bash
# Exit on error
set -e

echo "Downloading Flutter SDK..."
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

echo "Adding Flutter to PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "Building Flutter Web application..."
flutter build web --release

echo "Build complete! The output is located in build/web."
