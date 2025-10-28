#!/bin/bash
set -e

# Flutter SDK のダウンロードとセットアップ
echo "Installing Flutter SDK..."
FLUTTER_VERSION="${FLUTTER_VERSION:-3.27.0}"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

cd ~
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK..."
  curl -L "$FLUTTER_URL" | tar xJ
fi

export PATH="$HOME/flutter/bin:$PATH"

# Flutterのセットアップ
echo "Setting up Flutter..."
flutter doctor
flutter config --no-enable-web

# プロジェクトのディレクトリに戻る
cd /opt/build/repo

# 依存関係のインストール
echo "Installing dependencies..."
flutter pub get

# Webビルド
echo "Building web..."
flutter build web --release

echo "Build completed successfully!"

