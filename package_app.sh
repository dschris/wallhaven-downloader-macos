#!/bin/bash

# Configuration
APP_NAME="WallhavenDownloader"
BUILD_DIR=".build/release"
OUTPUT_DIR="Output"
BUNDLE_ID="com.intel777.WallhavenDownloader"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR/$APP_NAME.app"

echo "🔨 Building release configuration..."
swift build -c release

echo "📦 creating .app bundle structure..."
mkdir -p "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources"

echo "📑 Creating Info.plist..."
cat > "$OUTPUT_DIR/$APP_NAME.app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF

echo "📥 Copying binary..."
cp "$BUILD_DIR/$APP_NAME" "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS/"

# If there are resources, they should be copied here.
# For now we create a generic icon or assume none.

echo "🔒 Ad-hoc signing..."
codesign --force --deep --sign - "$OUTPUT_DIR/$APP_NAME.app"

echo "✅ Done! Application is at: $OUTPUT_DIR/$APP_NAME.app"
echo "👉 Move it to /Applications to use 'Launch at Login' properly."
