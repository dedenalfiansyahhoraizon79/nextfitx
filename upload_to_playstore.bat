@echo off
echo ========================================
echo Upload to Google Play Console
echo ========================================
echo.
echo File yang siap diupload:
echo 1. AAB File: build\app\outputs\bundle\release\app-release.aab
echo 2. Mapping File: mapping.txt
echo.
echo Informasi Release:
echo - Version Code: 6
echo - Version Name: 1.0.4
echo - Package Name: com.nextfitx.fitness
echo.
echo Langkah Upload:
echo 1. Buka Google Play Console
echo 2. Pilih aplikasi Anda
echo 3. Buka "Testing" -> "Internal testing"
echo 4. Klik "Create new release"
echo 5. Upload file app-release.aab
echo 6. Upload file mapping.txt (opsional)
echo 7. Tambahkan penguji internal
echo 8. Release ke internal testing
echo.
echo Catatan:
echo - Pastikan masalah akun sudah diselesaikan
echo - Tambahkan penguji internal untuk mengatasi warning
echo - File mapping.txt untuk deobfuscation (opsional)
echo.
pause 