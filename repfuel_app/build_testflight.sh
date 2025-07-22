#!/bin/bash

# Build script for TestFlight deployment
echo "Building for TestFlight..."

# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Build iOS for release
echo "Building iOS release..."
flutter build ios --release

# Build Android for release
echo "Building Android release..."
flutter build apk --release

echo "Build complete!"
echo ""
echo "For iOS TestFlight:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select 'Any iOS Device' as target"
echo "3. Product -> Archive"
echo "4. Upload to App Store Connect"
echo ""
echo "For Android:"
echo "1. The APK is ready at build/app/outputs/flutter-apk/app-release.apk"
echo "2. Upload to Google Play Console" 