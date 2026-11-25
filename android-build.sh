#!/bin/bash
set -e
echo "=== Building OpenMausBot Android APK ==="
echo ""

# Pastikan web app sudah di-build
if [ ! -d "dist" ]; then
    echo "→ Building web app..."
    NODE_OPTIONS="--max-old-space-size=8192" pnpm build
fi

# Sync ke Android
echo "→ Syncing Capacitor..."
./node_modules/.bin/capacitor sync android

# Build APK dengan Docker
echo "→ Building APK via Docker..."
mkdir -p release
docker run --rm \
    -v "$(pwd)":/workspace \
    -w /workspace/android \
    nao20010128nao/android-build:latest \
    ./gradlew assembleDebug 2>&1 | tail -20

# Copy APK
if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    cp app/build/outputs/apk/debug/app-debug.apk ../release/
    echo "✅ APK berhasil dibuat!"
    ls -lh ../release/*.apk
else
    echo "❌ APK tidak ditemukan"
    exit 1
fi
