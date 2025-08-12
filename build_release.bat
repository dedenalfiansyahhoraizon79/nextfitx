@echo off
echo Building release APK for Play Store...

REM Clean the project
flutter clean

REM Get dependencies
flutter pub get

REM Build release APK
flutter build apk --release

echo.
echo Build completed! APK is located at:
echo build/app/outputs/flutter-apk/app-release.apk
echo.
echo Next steps:
echo 1. Upload the APK to Google Play Console
echo 2. Fill in the store listing information
echo 3. Set up content rating
echo 4. Configure pricing and distribution
echo 5. Submit for review
pause 