# iOS Build Checklist untuk nextfitX

## ⚠️ PENTING: Build iOS Hanya Bisa Dilakukan di macOS

Build iOS tidak bisa dilakukan di Windows karena memerlukan Xcode yang hanya tersedia di macOS.

## 📋 Checklist Sebelum Build iOS

### 1. Persyaratan Sistem
- [ ] macOS (tidak bisa di Windows)
- [ ] Xcode terinstall (versi terbaru)
- [ ] iOS Simulator atau device fisik
- [ ] Apple Developer Account (untuk distribusi)

### 2. Konfigurasi Flutter
- [ ] Flutter SDK terinstall dan up-to-date
- [ ] iOS toolchain terkonfigurasi: `flutter doctor`
- [ ] Dependencies terinstall: `flutter pub get`

### 3. Konfigurasi iOS Project
- [ ] Bundle Identifier sudah benar di `ios/Runner/Info.plist`
- [ ] Version dan Build Number sudah benar
- [ ] App icons sudah dibuat dan dikonfigurasi
- [ ] Launch screen sudah dikonfigurasi

### 4. Dependencies iOS
- [ ] Podfile sudah dibuat dan dikonfigurasi
- [ ] CocoaPods terinstall: `sudo gem install cocoapods`
- [ ] Pods terinstall: `cd ios && pod install`

### 5. Signing & Provisioning
- [ ] Apple Developer Certificate
- [ ] Provisioning Profile
- [ ] Team ID dikonfigurasi di Xcode
- [ ] Bundle ID terdaftar di Apple Developer Portal

## 🚀 Langkah Build iOS

### Di macOS dengan Xcode:

1. **Buka Project di Xcode**
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **Konfigurasi Signing**
   - Pilih target "Runner"
   - Tab "Signing & Capabilities"
   - Pilih Team dan Bundle Identifier

3. **Install Dependencies**
   ```bash
   cd ios
   pod install
   ```

4. **Build Project**
   - Product → Build (⌘+B)
   - Atau Product → Archive untuk distribusi

### Menggunakan Flutter CLI:

1. **Build Debug**
   ```bash
   flutter build ios --debug
   ```

2. **Build Release**
   ```bash
   flutter build ios --release
   ```

3. **Build untuk Device**
   ```bash
   flutter build ios --release --no-codesign
   ```

## 🔧 Troubleshooting

### Error Umum:

1. **Pod Install Error**
   ```bash
   cd ios
   pod deintegrate
   pod install
   ```

2. **Signing Issues**
   - Periksa certificate dan provisioning profile
   - Pastikan Bundle ID sesuai

3. **Build Errors**
   - Clean project: `flutter clean`
   - Rebuild: `flutter pub get`

### Dependencies yang Perlu Diperhatikan:

- **Firebase**: Pastikan `GoogleService-Info.plist` ada
- **Permissions**: Camera, Location, Bluetooth, Notifications
- **Image Picker**: Photo library access
- **Bluetooth**: Core Bluetooth framework

## 📱 Testing

1. **Simulator**
   - iOS Simulator untuk testing UI
   - Tidak semua fitur tersedia (Bluetooth, Camera)

2. **Device Fisik**
   - Testing fitur hardware
   - Performance testing
   - App Store submission

## 🚀 Distribusi

### TestFlight:
1. Archive project di Xcode
2. Upload ke App Store Connect
3. Submit untuk review

### App Store:
1. Semua testing selesai
2. Metadata dan screenshots siap
3. Submit untuk review

## 📞 Support

Jika ada masalah dengan build iOS:
1. Periksa Flutter doctor output
2. Periksa Xcode build logs
3. Konsultasi dengan Apple Developer Support
4. Periksa Flutter GitHub issues

---

**Catatan**: Build iOS memerlukan macOS dan tidak bisa dilakukan di Windows. Gunakan CI/CD service seperti Codemagic, Bitrise, atau GitHub Actions untuk automated builds.
