@echo off
echo ========================================
echo Check Upload Files
echo ========================================
echo.

echo Checking AAB file...
if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo ✓ AAB file found: build\app\outputs\bundle\release\app-release.aab
    for %%A in ("build\app\outputs\bundle\release\app-release.aab") do echo   Size: %%~zA bytes
) else (
    echo ✗ AAB file not found!
)

echo.
echo Checking mapping file...
if exist "mapping.txt" (
    echo ✓ Mapping file found: mapping.txt
    for %%A in ("mapping.txt") do echo   Size: %%~zA bytes
) else (
    echo ✗ Mapping file not found!
)

echo.
echo Checking keystore file...
if exist "android\app\upload-keystore.jks" (
    echo ✓ Keystore file found: android\app\upload-keystore.jks
) else (
    echo ✗ Keystore file not found!
)

echo.
echo Checking key.properties...
if exist "android\key.properties" (
    echo ✓ Key properties found: android\key.properties
) else (
    echo ✗ Key properties not found!
)

echo.
echo ========================================
echo File Information
echo ========================================
echo Version Code: 6
echo Version Name: 1.0.4
echo Package Name: com.nextfitx.fitness
echo.

echo ========================================
echo Upload Instructions
echo ========================================
echo 1. Buka Google Play Console
echo 2. Pilih aplikasi Anda
echo 3. Buka "Testing" -> "Internal testing"
echo 4. Klik "Create new release"
echo 5. Upload file app-release.aab
echo 6. Upload file mapping.txt (opsional)
echo 7. Tambahkan penguji internal
echo 8. Release ke internal testing
echo.

echo ========================================
echo Troubleshooting
echo ========================================
echo Jika upload gagal:
echo 1. Periksa masalah akun developer
echo 2. Pastikan version code unik
echo 3. Periksa package name tidak konflik
echo 4. Pastikan keystore valid
echo.

pause 