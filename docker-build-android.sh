#!/bin/bash
set -e

echo "=== OpenMausBot Android APK Build ==="
echo ""

WORKDIR="$(pwd)"
SDK_DIR="/opt/android-sdk"

docker run --rm \
    -v "$WORKDIR":/workspace \
    -e JAVA_HOME=/opt/java/openjdk \
    -w /workspace/android \
    eclipse-temurin:17-jdk \
    bash -c '
        set -e
        apt-get update > /dev/null 2>&1
        apt-get install -y unzip wget coreutils > /dev/null 2>&1
        
        # Setup Android SDK dengan struktur yang benar
        mkdir -p /opt/android-sdk/cmdline-tools/latest
        cd /opt/android-sdk/cmdline-tools/latest
        
        if [ ! -f bin/sdkmanager ]; then
            echo "→ Downloading Android SDK Tools..."
            wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
            unzip -q commandlinetools-linux-11076708_latest.zip
            mv cmdline-tools/bin/* . 2>/dev/null || true
            rm -rf bin cmdline-tools *.zip
        fi
        
        export ANDROID_HOME=/opt/android-sdk
        export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
        
        echo "→ Accepting licenses..."
        yes | sdkmanager --licenses > /dev/null 2>&1 || true
        
        echo "→ Installing SDK packages..."
        sdkmanager "platforms;android-36" "build-tools;35.0.0" > /dev/null 2>&1
        
        echo "→ Building APK..."
        cd /workspace/android
        ./gradlew assembleDebug
        
        echo "→ Saving APK..."
        mkdir -p /workspace/release
        cp app/build/outputs/apk/debug/app-debug.apk /workspace/release/
        
        echo ""
        echo "✅ BUILD COMPLETE!"
        echo "📦 APK Location: /workspace/release/app-debug.apk"
        ls -lh /workspace/release/*.apk
    '
