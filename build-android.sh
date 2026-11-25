#!/bin/bash
set -e

echo "=== OpenMausBot Android Build Script ==="
echo ""

# Cek prerequisites
echo "✓ Checking prerequisites..."
command -v node >/dev/null 2>&1 || { echo "❌ Node.js required"; exit 1; }
command -v pnpm >/dev/null 2>&1 || { echo "❌ pnpm required"; exit 1; }
command -v java >/dev/null 2>&1 || { echo "⚠️  Java not found - will use Docker for build"; USE_DOCKER=true; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker required for build"; exit 1; }

# Build web app
echo "→ Building web app..."
NODE_OPTIONS="--max-old-space-size=8192" pnpm build

# Sync ke Android
echo "→ Syncing to Android..."
./node_modules/.bin/capacitor sync android

# Build APK
if [ "$USE_DOCKER" = true ]; then
    echo "→ Building APK with Docker..."
    docker run --rm \
        -v "$(pwd)":/app \
        -v "$(pwd)/release:/app/release" \
        -w /app/android \
        --platform linux/amd64 \
        eclipse-temurin:17-jdk \
        bash -c "
            apt-get update && apt-get install -y unzip wget
            mkdir -p /opt/android-sdk
            cd /opt/android-sdk
            wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
            unzip -q commandlinetools-linux-11076708_latest.zip
            mv cmdline-tools latest
            export ANDROID_HOME=/opt/android-sdk
            export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin
            yes | sdkmanager --licenses
            sdkmanager 'platforms;android-34' 'build-tools;34.0.0'
            ./gradlew assembleDebug
            mkdir -p /app/release
            cp app/build/outputs/apk/debug/app-debug.apk /app/release/
        "
else
    echo "→ Building APK locally..."
    cd android && ./gradlew assembleDebug && \
    mkdir -p ../release && \
    cp app/build/outputs/apk/debug/app-debug.apk ../release/
fi

echo ""
echo "✅ Build complete!"
echo "📦 APK: release/app-debug.apk"
ls -lah release/*.apk 2>/dev/null
