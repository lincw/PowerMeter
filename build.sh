#!/bin/bash
APP_DIR="PowerMeter.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

echo "Cleaning old build..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "Compiling Swift code..."
swiftc -parse-as-library powermeter_main.swift -o "$MACOS_DIR/PowerMeter"

if [ -f "AppIcon.icns" ]; then
    echo "Copying AppIcon..."
    cp AppIcon.icns "$RESOURCES_DIR/"
fi

echo "Writing Info.plist..."
cat <<EOF > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>PowerMeter</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.PowerMeter</string>
    <key>CFBundleName</key>
    <string>PowerMeter</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "Build complete! App is located at $(pwd)/$APP_DIR"
