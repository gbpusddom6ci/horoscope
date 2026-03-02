# Horoscope SuperApp - AI Agent Guide

Welcome, fellow AI Agent! Bu dosya (`agents.md`), Horoscope SuperApp projesi için **en güncel ve kapsamlı rehberdir**. Kodda değişiklik yapmadan önce lütfen bu belgeyi dikkatle okuyun. Projede daha önce çözülmüş mimari sorunları, yapı taşlarını ve tasarım kurallarını içerir.

## 1. Proje Özeti (Project Overview)
Bu proje, iOS 16.0 ve üzeri için geliştirilmiş, Native SwiftUI tabanlı, yapay zeka destekli bir astroloji uygulamasıdır. Günlük yorumlar, doğum haritası (natal chart) çıkarımı, rüya yorumlama ve mistik AI asistan gibi özellikleri barındırır.

- **Platform:** iOS 16.0+
- **Dil:** Swift 5.0+ (Salt SwiftUI)
- **Mimari:** MVVM benzeri, iOS 17'nin `@Observable` makrosuna ve `@Environment` dependency injection yöntemine dayalı modern bir yapı.
- **Backend:** Firebase Authentication (Apple Sign-In) ve Cloud Firestore üzerinden tam senkronize gerçek veritabanı. Push bildirimleri APNs+FCM ile kurulu. Paywalls StoreKit üzerinden entegre.
- **AI Entegrasyonu:** OpenRouter API üzerinden `google/gemini-3-flash-preview` modeli kullanılmaktadır (Vision API dahil).

## 2. Temel Mimari ve Servisler (`Core/Services`)

Proje temel olarak `.environment()` ile enjekte edilen tekil (shared/singleton veya root objesi) servisler etrafında şekillenir.

### `FirestoreService.swift`
- Kullanıcı profili, Chat geçmişleri, Rüya günlükleri ve Natal haritaların tümünü Cloud Firestore üzerinde modüler dökümanlar halinde senkronize eder.

### `AIService.swift`
- OpenRouter üzerinden Gemini API çağrılarını yönetir.
- Uygulama çapında *Natal Harita Yorumu*, *Transit Yorumu*, *Rüya Tabiri*, *El Falı* (Resimli/Multimodal) ve genel *Chat* özellikleri için özel prompt'larla özelleştirilmiş `generateContent()` çağrıları yapar.

### `AuthService.swift`
- Uygulamanın Firebase Auth state'ini ve `AppUser` objesini yönetir.
- State akışı: `.unknown` -> `.unauthenticated` (Kayıt/Giriş) -> `.onboarding` (Doğum verilerini sağlama) -> `.authenticated` (Uygulamaya giriş).

### `PremiumService & UsageLimitService`
- Freemium iş modelini yönetir. Kayıtsız free kullanıcılara kota uygular; In-App Purchase sonrası tüm feature'lar açılır.

## 3. Navigasyon ve UI Kuralları (`Navigation/` & `Features/`)

### `AppRouter.swift` ve Kök Dizin
- Tüm uygulamanın giriş noktası `AppRouter`'dır. AuthService'in state'ine göre uygun Root view'i seçer.
- Ayrıca `NetworkMonitor` ile internet düşüşlerinde otomatik olarak "No Internet" UI uyarısı çıkar.

### Kök Navigasyon Hataları (The Swipe-to-Pop Bug)
- **KURAL:** Root sekme görünümlerinin HİÇBİRİ (`HomeView`, `ChatView`, vb.) doğrudan bir `NavigationStack` sarmalayıcısı taşımamalıdır. Yeni görünümlere geçilecekse (push navigation) alt seviyelerde NavigationStack açılmalı ya da sheet/fullscreenCover kullanılmalıdır. 

## 4. Tasarım Sistemi (`Core/Design`)
Tasarım dili katı, premium, gizemli (mystic) ve tamamen karanlık temalıdır. Standart iOS komponentleri yerine custom bileşenler tercih edilir.

- **Renkler (`MysticColors`):** Arka planlar `voidBlack` türevleridir. Aksan renkleri `mysticGold`, `neonLavender`, `auroraGreen`, `celestialPink`. *Asla standart `Color.red` veya `Color.blue` kullanmayın.*
- **Bileşenler:**
  - `MysticCard`: İçerikleri barındıran asıl kart konteyneri. (Glow efektleriyle çerçevelenmiş).
  - `StarField`: `HomeView` vb. arka planlarında uçuşan yıldız efektini veren `Canvas` tabanlı bileşen. Parça bazlı performans açısından çok önemlidir.
  - `MysticButton`: Ana ve ikincil buton tasarımları.

## 5. Tamamlandı (Status: Shipped)
Projenin tüm fazları (Tasarım, Mimari, Firestore, AI Entegrasyonları, Monetization, Bildirimler, QA Unit & UI Testleri, Crashlytics ve App Store Connect dokümantasyonları) **%100 başarılı bir şekilde tamamlanmıştır**. Meydana gelen hatalar çözülmüş ve CI/CD pipeline'ı pass haline getirilmiştir. Tebrikler!
