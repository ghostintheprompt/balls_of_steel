#!/bin/bash
# Quick launch script for Balls of Steel app

# Build and launch the app
echo "Building Balls of Steel..."
xcodebuild -scheme Balls_of_Steel -configuration Debug build > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded"
    echo "Copying app to project root..."
    cp -R ~/Library/Developer/Xcode/DerivedData/Balls_of_Steel-*/Build/Products/Debug/Balls_of_Steel.app .
    echo "🚀 Launching app..."
    open Balls_of_Steel.app
else
    echo "❌ Build failed. Check errors with: xcodebuild -scheme Balls_of_Steel -configuration Debug build"
fi
