#!/bin/bash

# MDRN Corp DMG Build Script
# usage: ./make_dmg.sh

APP_NAME="Balls_of_Steel"
SCHEME="Balls_of_Steel"
CONFIGURATION="Release"
BUILD_DIR="./Builds"
DMG_NAME="${APP_NAME}.dmg"
ICON_PATH="balls_of_steel.png"

echo "🚀 Starting build for ${APP_NAME}..."

# Clean and Build
xcodebuild clean build \
  -project "${APP_NAME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -derivedDataPath "${BUILD_DIR}" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Path to the built .app
APP_PATH="${BUILD_DIR}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Build failed. App not found at ${APP_PATH}"
    exit 1
fi

echo "📦 Creating DMG..."

# Create a temporary directory for the DMG content
TMP_DIR=$(mktemp -d)
cp -R "$APP_PATH" "$TMP_DIR/"
ln -s /Applications "$TMP_DIR/Applications"

# Copy Documentation
cp -R docs "$TMP_DIR/Documentation"

# Copy Icon if it exists
if [ -f "$ICON_PATH" ]; then
    cp "$ICON_PATH" "$TMP_DIR/.VolumeIcon.png"
    cp "$ICON_PATH" "$TMP_DIR/icon.png"
fi

# Remove existing DMG if it exists
rm -f "${DMG_NAME}"

# Create DMG
hdiutil create -volname "${APP_NAME}" -srcfolder "$TMP_DIR" -ov -format UDZO "${DMG_NAME}"

# Cleanup
rm -rf "$TMP_DIR"

echo "✅ Success! ${DMG_NAME} created."
