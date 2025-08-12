# Checklist Upload ke Google Play Store

## 1. Persiapan Keystore
- [ ] Generate keystore dengan command:
  ```
  keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] Update `android/key.properties` dengan password yang benar
- [ ] Backup keystore file dan password di tempat yang aman

## 2. Build Release APK
- [ ] Update version di `pubspec.yaml` dan `build.gradle.kts`
- [ ] Jalankan `build_release.bat` atau `flutter build apk --release`
- [ ] Test APK di device fisik
- [ ] Verifikasi semua fitur berfungsi dengan baik

## 3. Google Play Console Setup
- [ ] Buat akun Google Play Console ($25 one-time fee)
- [ ] Buat aplikasi baru di Play Console
- [ ] Isi informasi dasar aplikasi:
  - Nama aplikasi: "nextfitX"
  - Deskripsi singkat
  - Deskripsi lengkap
  - Kategori: Health & Fitness

## 4. Store Listing
- [ ] Upload icon aplikasi (512x512 PNG)
- [ ] Upload screenshot aplikasi (minimal 2, maksimal 8)
- [ ] Upload feature graphic (1024x500 PNG)
- [ ] Isi deskripsi aplikasi yang menarik
- [ ] Tambahkan keywords yang relevan
- [ ] Pilih kategori yang tepat

## 5. Content Rating
- [ ] Isi questionnaire content rating
- [ ] Aplikasi fitness biasanya mendapat rating "Everyone" atau "Everyone 10+"

## 6. Pricing & Distribution
- [ ] Pilih model monetisasi (Free/Paid)
- [ ] Pilih negara target
- [ ] Set privacy policy URL (jika diperlukan)

## 7. App Bundle/APK Upload
- [ ] Upload APK ke Play Console
- [ ] Isi release notes
- [ ] Set minimum SDK version (Android 8.0+)
- [ ] Set target SDK version

## 8. Review Process
- [ ] Submit untuk review
- [ ] Review process biasanya 1-7 hari
- [ ] Monitor status review di Play Console
- [ ] Siapkan response untuk feedback jika diperlukan

## 9. Post-Launch
- [ ] Monitor crash reports
- [ ] Monitor user feedback
- [ ] Siapkan update untuk bug fixes
- [ ] Plan feature updates

## File yang Diperlukan:
- APK file: `build/app/outputs/flutter-apk/app-release.apk`
- Icon aplikasi: `assets/img/logofix.png` (512x512)
- Screenshots aplikasi
- Feature graphic (1024x500)

## Tips:
1. Test aplikasi di berbagai device sebelum upload
2. Pastikan semua permission yang diperlukan sudah dijelaskan
3. Buat deskripsi yang menarik dan informatif
4. Gunakan screenshot yang menunjukkan fitur utama
5. Monitor analytics setelah launch 