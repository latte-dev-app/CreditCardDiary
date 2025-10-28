#!/usr/bin/env bash
set -euo pipefail

# 基本PATHを確実に設定（mkdir、touchなどの基本コマンドを確保）
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

echo "Starting Netlify build for Flutter Web..."

# 1) Install Flutter (stable channel)
echo "Step 1: Installing Flutter SDK..."
if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
else
  echo "Flutter already exists in $HOME/flutter"
fi

# 2) Add flutter to PATH（基本PATHを保持）
export PATH="$HOME/flutter/bin:$HOME/flutter/bin/cache/dart-sdk/bin:$PATH"

echo "Step 2: Flutter version check..."
flutter --version

# 3) Enable web and verify
echo "Step 3: Enabling web support..."
flutter config --enable-web

# 4) Fetch Dart/Flutter deps
echo "Step 4: Installing dependencies..."
flutter pub get

# 5) Build the web app
echo "Step 5: Building web app..."
flutter build web --release

echo "Build completed successfully!"

