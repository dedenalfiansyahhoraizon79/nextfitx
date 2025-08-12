@echo off
echo Generating keystore for release signing...
echo.
echo This will create a keystore file for signing your app for Play Store upload.
echo Please follow the prompts and remember your passwords!
echo.
echo IMPORTANT: Keep your keystore file and passwords safe!
echo If you lose them, you won't be able to update your app on Play Store.
echo.

cd android\app

keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

echo.
echo Keystore generated successfully!
echo.
echo Next steps:
echo 1. Update android/key.properties with your passwords
echo 2. Keep the keystore file safe
echo 3. Run build_release.bat to build your APK
echo.
pause 