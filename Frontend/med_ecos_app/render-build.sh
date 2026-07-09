#!/usr/bin/env bash
# Exit on error
set -e

echo "Downloading Flutter SDK..."
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

echo "Adding Flutter to PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "Creating dummy .env file to satisfy pubspec.yaml asset requirement..."
touch .env

echo "Building Flutter Web application..."
flutter build web --release --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY

echo "Build complete! The output is located in build/web."
