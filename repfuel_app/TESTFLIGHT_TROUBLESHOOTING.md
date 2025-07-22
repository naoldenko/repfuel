# TestFlight Troubleshooting Guide

## Common Issues and Solutions

### 1. App Crashes on Launch
**Symptoms**: App immediately crashes when opened in TestFlight

**Solutions**:
- Check that all permissions are properly configured in `Info.plist`
- Ensure API keys are properly configured (use environment variables)
- Test on a physical device before uploading to TestFlight

### 2. Speech Recognition Not Working
**Symptoms**: Microphone button doesn't work or speech recognition fails

**Solutions**:
- Verify `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` are in `Info.plist`
- Test microphone permissions on device
- Check that speech_to_text plugin is properly initialized

### 3. Text-to-Speech Not Working
**Symptoms**: Play button doesn't work or no audio output

**Solutions**:
- Check device volume settings
- Verify `flutter_tts` plugin initialization
- Test on physical device (simulator may not support TTS)

### 4. API Calls Failing
**Symptoms**: "Failed to get suggestion" error

**Solutions**:
- Verify API key is properly configured
- Check network connectivity
- Ensure `NSAppTransportSecurity` is configured for `api.openai.com`

### 5. Build Issues
**Symptoms**: Build fails or app doesn't install

**Solutions**:
- Run `flutter clean && flutter pub get`
- Check iOS deployment target compatibility
- Verify all dependencies are compatible

## Configuration Steps

### 1. Set up API Key
```bash
# For development
flutter run --dart-define=OPENAI_API_KEY=your_api_key_here

# For production builds
flutter build ios --dart-define=OPENAI_API_KEY=your_api_key_here
```

### 2. Build for TestFlight
```bash
# Run the build script
./build_testflight.sh

# Or manually:
flutter clean
flutter pub get
flutter build ios --release
```

### 3. Archive and Upload
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" as target
3. Product → Archive
4. Upload to App Store Connect

## Testing Checklist

- [ ] App launches without crashing
- [ ] Microphone permissions are requested
- [ ] Speech recognition works
- [ ] Text-to-speech works
- [ ] API calls succeed
- [ ] UI is responsive
- [ ] No console errors

## Debug Information

To get debug information from TestFlight:
1. Connect device to Mac
2. Open Console app
3. Select your device
4. Filter by your app name
5. Look for error messages

## Contact Support

If issues persist:
1. Check Xcode console for detailed error messages
2. Test on multiple devices
3. Verify all permissions are granted
4. Check network connectivity 