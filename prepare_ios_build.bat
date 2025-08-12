@echo off
echo ========================================
echo   iOS Build Preparation Script
echo ========================================
echo.
echo WARNING: iOS build cannot be done on Windows!
echo This script only prepares configuration files.
echo.
echo You need to:
echo 1. Use a Mac with Xcode
echo 2. Open ios/Runner.xcworkspace in Xcode
echo 3. Configure signing and provisioning
echo 4. Run: cd ios && pod install
echo 5. Build in Xcode or use flutter build ios
echo.

echo Checking Flutter configuration...
flutter doctor

echo.
echo Checking iOS configuration...
if exist "ios\Podfile" (
    echo ✓ Podfile exists
) else (
    echo ✗ Podfile missing
)

if exist "ios\Flutter\Generated.xcconfig" (
    echo ✓ Generated.xcconfig exists
) else (
    echo ✗ Generated.xcconfig missing
)

if exist "ios\Runner\GoogleService-Info.plist" (
    echo ✓ GoogleService-Info.plist exists
) else (
    echo ✗ GoogleService-Info.plist missing
)

echo.
echo ========================================
echo   Next Steps for iOS Build:
echo ========================================
echo.
echo 1. Transfer project to macOS
echo 2. Install Xcode from App Store
echo 3. Install CocoaPods: sudo gem install cocoapods
echo 4. Open ios/Runner.xcworkspace in Xcode
echo 5. Configure signing in Xcode
echo 6. Run: cd ios && pod install (iOS 13.0+ required)
echo 7. Build in Xcode or use: flutter build ios
echo.
echo See IOS_BUILD_CHECKLIST.md for detailed steps
echo.
pause
