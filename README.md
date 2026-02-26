# Horoscope SuperApp (iOS)

SwiftUI + Firebase + OpenRouter tabanlı astroloji uygulaması.

## Gereksinimler
- Xcode 17+
- iOS 17+ simulator
- Firebase projesi (`GoogleService-Info.plist` target içinde)

## Local Kurulum
1. Secret dosyasını üret:
```bash
cp Config/Secrets.template.xcconfig Config/Secrets.xcconfig
```
2. `Config/Secrets.xcconfig` içine değerleri gir:
- `OPENROUTER_API_KEY`
- `FREE_ASTRO_API_KEY`
3. Xcode’da proje açıp `horoscope` scheme ile çalıştır.

## Secret Güvenliği
- `Config/Secrets.xcconfig` git'e dahil edilmez (`.gitignore` içinde).
- API key'leri kod içine hardcode edilmez, `Secrets.swift` üzerinden okunur.
- Xcode Scheme `Environment Variables` alanına gerçek key yazıp paylaşma.
- Key sızıntısı olursa:
1. İlgili key'i hemen iptal et.
2. Yeni key üret.
3. `Config/Secrets.xcconfig` ve CI/CD secret'larını güncelle.

## Build ve Test
```bash
xcodebuild -scheme horoscope -destination 'generic/platform=iOS Simulator' build
xcodebuild -scheme horoscope -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:horoscopeTests test
xcodebuild -scheme horoscope -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:horoscopeUITests test
```

## Firebase Operasyonları
- Firestore rules: `firebase/firestore.rules`
- Firestore indexes: `firebase/firestore.indexes.json`
- Deploy:
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Detaylı operasyon notları: [`docs/OPERATIONS.md`](docs/OPERATIONS.md)

## CI
GitHub Actions workflow: `.github/workflows/ios-ci.yml`
- Dependency resolve
- Build
- Unit test
- Runner'da mevcut olan ilk iPhone simulator'u otomatik seçer
