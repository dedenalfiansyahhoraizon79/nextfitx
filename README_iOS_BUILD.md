# 🍎 iOS Build Guide untuk nextfitX

## ⚠️ PENTING: Build iOS Hanya Bisa di macOS

**Build iOS tidak bisa dilakukan di Windows** karena memerlukan Xcode yang hanya tersedia di macOS.

## 📋 Status Konfigurasi Saat Ini

✅ **Sudah Dikonfigurasi:**
- Podfile dengan konfigurasi lengkap
- Debug.xcconfig dan Release.xcconfig
- Generated.xcconfig
- AppFrameworkInfo.plist
- Info.plist dengan bundle identifier
- GoogleService-Info.plist untuk Firebase

## 🚀 Langkah Build iOS (di macOS)

### 1. Persiapkan macOS
```bash
# Install Xcode dari App Store
# Install CocoaPods
sudo gem install cocoapods

# Install Flutter (jika belum)
# Download dari https://flutter.dev/docs/get-started/install/macos
```

### 2. Transfer Project ke macOS
```bash
# Copy seluruh folder project ke macOS
# Pastikan semua file tersalin dengan benar
```

### 3. Setup Project di macOS
```bash
cd /path/to/nextfitx
flutter clean
flutter pub get
```

### 4. Install iOS Dependencies
```bash
cd ios
pod install
```

### 5. Buka di Xcode
```bash
open Runner.xcworkspace
```

### 6. Konfigurasi Signing
- Pilih target "Runner"
- Tab "Signing & Capabilities"
- Pilih Team ID
- Pastikan Bundle Identifier sesuai

### 7. Build Project
```bash
# Build Debug
flutter build ios --debug

# Build Release
flutter build ios --release

# Build tanpa codesign (untuk testing)
flutter build ios --release --no-codesign
```

## 🔧 Konfigurasi yang Sudah Dibuat

### Podfile
- iOS deployment target: 12.0
- Framework configuration
- Permission definitions
- Post-install hooks

### Build Configuration
- Debug dan Release configs
- Flutter path configuration
- Build settings optimization

### Permissions
- Camera access
- Photo library access
- Location services
- Bluetooth connectivity
- Push notifications
- Microphone access

## 📱 Testing

### iOS Simulator
```bash
flutter run -d ios
```

### Device Fisik
1. Connect iPhone/iPad via USB
2. Trust device di macOS
3. Select device di Xcode
4. Run: `flutter run -d <device-id>`

## 🚀 Distribusi

### TestFlight
1. Archive project di Xcode
2. Upload ke App Store Connect
3. Submit untuk internal testing

### App Store
1. Semua testing selesai
2. Metadata dan screenshots siap
3. Submit untuk review

## 🔍 Troubleshooting

### Pod Install Issues
```bash
cd ios
pod deintegrate
pod cache clean --all
pod install
```

### Build Errors
```bash
flutter clean
flutter pub get
cd ios
pod install
```

### Signing Issues
- Periksa Apple Developer Account
- Pastikan certificate valid
- Check provisioning profile

## 📞 Support

### Flutter Issues
- `flutter doctor -v`
- Check Flutter GitHub issues
- Flutter Discord community

### iOS Issues
- Xcode build logs
- Apple Developer Forums
- Stack Overflow

### Project Specific
- Firebase configuration
- Permission handling
- Bluetooth implementation

## 🌐 Alternative Solutions

### CI/CD Services (untuk automated builds)
- **Codemagic**: Flutter-focused CI/CD
- **Bitrise**: Mobile CI/CD platform
- **GitHub Actions**: Free CI/CD dengan macOS runners
- **Codemagic**: Automated iOS builds

### Remote Mac Services
- **MacStadium**: Dedicated Mac servers
- **MacinCloud**: Cloud-based Mac services
- **AWS EC2 Mac instances**: Cloud Mac computing

## 📚 Resources

- [Flutter iOS Deployment](https://flutter.dev/docs/deployment/ios)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [CocoaPods Guide](https://guides.cocoapods.org/)
- [Xcode User Guide](https://developer.apple.com/xcode/)

---

**Kesimpulan**: Proyek nextfitX sudah siap untuk iOS build dengan semua konfigurasi yang diperlukan. Yang dibutuhkan hanyalah macOS dengan Xcode untuk melakukan build dan distribusi ke iOS.
