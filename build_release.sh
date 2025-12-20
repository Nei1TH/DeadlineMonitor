#!/bin/bash

PROJECT_NAME="Deadline.xcodeproj"
SCHEME_NAME="Deadline"
OUTPUT_DIR="Build/Release"

echo "🚀 Starting build for $SCHEME_NAME..."

echo "🧹 Cleaning up old files..."
xcodebuild clean -project "$PROJECT_NAME" -scheme "$SCHEME_NAME" -configuration Release

echo "📦 Archiving..."
xcodebuild archive \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -archivePath "$OUTPUT_DIR/$SCHEME_NAME.xcarchive" \
  -destination 'generic/platform=macOS'

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "📂 Exporting .app..."
cp -r "$OUTPUT_DIR/$SCHEME_NAME.xcarchive/Products/Applications/$SCHEME_NAME.app" "$OUTPUT_DIR/"

echo "🤐 Compressing..."
cd "$OUTPUT_DIR"
zip -r "$SCHEME_NAME.zip" "$SCHEME_NAME.app"

echo "✅ Build complete!"
echo "👉 File location: $PWD/$SCHEME_NAME.zip"
echo "You can upload this zip file to GitHub Releases."

# Instructions
# 1. Make sure you have permission to execute this script.
# 2. Make sure Xcode is installed and in your PATH.
# 3. Make sure you have set the correct project name, scheme name, and output directory.
#
# Usage:
# chmod +x build_release.sh
# ./build_release.sh
