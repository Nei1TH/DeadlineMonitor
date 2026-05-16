#!/bin/bash

PROJECT_NAME="Deadline.xcodeproj"
SCHEME_NAME="Deadline"
OUTPUT_DIR="Build/Release"

echo "Starting build for $SCHEME_NAME with Ad-hoc signing..."

mkdir -p "$OUTPUT_DIR"

echo "Cleaning up old files..."
xcodebuild clean -project "$PROJECT_NAME" -scheme "$SCHEME_NAME" -configuration Release

echo "Archiving..."
#Ad-hoc signing
xcodebuild archive \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -archivePath "$OUTPUT_DIR/$SCHEME_NAME.xcarchive" \
  -destination 'generic/platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  AD_HOC_CODE_SIGNING_ALLOWED=YES

if [ $? -ne 0 ]; then
    echo "Build failed"
    exit 1
fi

echo "Exporting .app..."
rm -rf "$OUTPUT_DIR/$SCHEME_NAME.app"
cp -r "$OUTPUT_DIR/$SCHEME_NAME.xcarchive/Products/Applications/$SCHEME_NAME.app" "$OUTPUT_DIR/"

echo "Compressing using ditto (preserving metadata)..."
ditto -c -k --sequesterRsrc --keepParent "$OUTPUT_DIR/$SCHEME_NAME.app" "$OUTPUT_DIR/$SCHEME_NAME.zip"

echo "Build complete!"
echo "File location: $PWD/$OUTPUT_DIR/$SCHEME_NAME.zip"
echo ""
echo "Note: This app is Ad-hoc signed. Your classmates might need to:"
echo "Right-click -> Open the app to bypass Gatekeeper."

# Instructions
# 1. Make sure you have permission to execute this script.
# 2. Make sure Xcode is installed and in your PATH.
# 3. Make sure you have set the correct project name, scheme name, and output directory.
#
# Usage:
# chmod +x build_release.sh
# ./build_release.sh
