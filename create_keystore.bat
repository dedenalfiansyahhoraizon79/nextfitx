@echo off
echo Creating new keystore for release signing...
echo.

cd android\app

REM Remove existing keystore if exists
if exist upload-keystore.jks del upload-keystore.jks

REM Create new keystore with simple password
echo y | "C:\Program Files\Java\jdk-17\bin\keytool.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass 123456 -keypass 123456 -dname "CN=nextfitx, OU=nextfitx, O=horizon university, L=karawang, ST=west java, C=ID"

echo.
echo Keystore created successfully!
echo Password: 123456
echo Alias: upload
echo.
pause 