# Horoscope SuperApp - AI Agent Guide

Welcome, fellow AI Agent! Bu dosya (`agents.md`), Horoscope SuperApp projesi için **en güncel ve kapsamlı rehberdir**. Kodda değişiklik yapmadan önce lütfen bu belgeyi dikkatle okuyun. Projede daha önce çözülmüş mimari sorunları, yapı taşlarını ve tasarım kurallarını içerir.

## 1. Proje Özeti (Project Overview)
Bu proje, iOS 16.0 ve üzeri için geliştirilmiş, Native SwiftUI tabanlı, yapay zeka destekli bir astroloji uygulamasıdır. Günlük yorumlar, doğum haritası (natal chart) çıkarımı, rüya yorumlama ve mistik AI asistan gibi özellikleri barındırır.

- **Platform:** iOS 16.0+
- **Dil:** Swift 5.0+ (Salt SwiftUI)
- **Mimari:** MVVM benzeri, iOS 17'nin `@Observable` makrosuna ve `@Environment` dependency injection yöntemine dayalı modern bir yapı.
- **Backend (Geçici/Asıl):** Firebase projesi eklenmiş (`AppDelegate` içinde `FirebaseApp.configure()` çalışıyor) ancak veri saklama **şu anda geçici olarak `UserDefaults` üzerinden (Mock) yapılmaktadır**.
- **AI Entegrasyonu:** OpenRouter API üzerinden `google/gemini-3-flash-preview` modeli kullanılmaktadır.

## 2. Temel Mimari ve Servisler (`Core/Services`)

Proje temel olarak `.environment()` ile enjekte edilen tekil (shared/singleton veya root objesi) servisler etrafında şekillenir.

### `FirestoreService.swift`
- **ÖNEMLİ BİLGİ:** Adı FirestoreService olmasına rağmen, **şu anda veriler (Kullanıcı profili, Chat geçmişleri, Rüya günlükleri ve Natal haritalar) yerelde `UserDefaults` üzerinde JSON olarak şifrelenip saklanmaktadır**. API metodlarındaki `// TODO: Replace with Firestore` yönergelerine dikkat et.
- Firestore SDK entegrasyonu tamamen bağlandığında bu metodlar gerçek `db.collection("users")...` yazma işlemlerine dönüştürülecektir.

### `AIService.swift`
- OpenRouter üzerinden Gemini API çağrılarını yönetir.
- **Model:** `google/gemini-3-flash-preview`
- Uygulama çapında *Natal Harita Yorumu*, *Transit Yorumu*, *Rüya Tabiri*, *El Falı* ve genel *Chat* özellikleri için özel prompt'larla özelleştirilmiş `generateContent()` çağrıları yapar.

### `AuthService.swift`
- Uygulamanın Firebase Auth state'ini mock'lar ve `AppUser` objesini yönetir.
- State akışı: `.unknown` -> `.unauthenticated` (Kayıt/Giriş) -> `.onboarding` (Doğum verilerini sağlama) -> `.authenticated` (Uygulamaya giriş).

### `AstrologyEngine.swift` (Mocked)
- Gerçek astronomik hesaplamalar yapılmıyor. Natal harita (`ChartData`) ve anlık planet transitleri (`TransitEvent`) rastgele oluşturulmaktadır.
- **Gelecek Görev:** Gerçek bir ephemeris (örn. Swiss Ephemeris) kütüphanesi ile değiştirilmesi gerekmektedir.

## 3. Navigasyon ve UI Kuralları (`Navigation/` & `Features/`)

### `AppRouter.swift` ve Kök Dizin
- Tüm uygulamanın giriş noktası `AppRouter`'dır. AuthService'in state'ine göre uygun Root view'i seçer.
- Ana renk teması `Color(red: 0.03, green: 0.02, blue: 0.06)` olarak tabana (ZStack en altı) yayılmıştır. Pencereler daima `.preferredColorScheme(.dark)` dır.

### Kök Navigasyon Hataları (The Swipe-to-Pop Bug)
- **ÇÖZÜLMÜŞ KRİTİK BİR HATA:** iOS 17/18 SwiftUI'da, root seviyesindeki bir TabView öğesini (`HomeView`, `ChatView` vb.) doğrudan `NavigationStack` içine alıp, varsayılan gezinti çubuklarını sakladığınızda (`.toolbarBackground(.hidden)`), ekranı sağa kaydırmak (swipe gestrue) **siyah boşluk yaratan (Empty interactive pop gesture) boş bir geri dönüş hatasına** neden olur.
- **KURAL:** Root sekme görünümlerinin HİÇBİRİ (`HomeView`, `ChatView`, vb.) doğrudan bir `NavigationStack` sarmalayıcısı taşımamalıdır. Yeni görünümlere geçilecekse (push navigation) alt seviyelerde NavigationStack açılmalı ya da sheet/fullscreenCover kullanılmalıdır. Navigasyon başlıkları (Header) özel tasarlanmış `HStack` yapılarıdır.

## 4. Tasarım Sistemi (`Core/Design`)
Tasarım dili katı, premium, gizemli (mystic) ve tamamen karanlık temalıdır. Standart iOS komponentleri yerine custom bileşenler tercih edilir.

- **Renkler (`MysticColors`):** Arka planlar `voidBlack` türevleridir. Aksan renkleri `mysticGold`, `neonLavender`, `auroraGreen`, `celestialPink`. *Asla standart `Color.red` veya `Color.blue` kullanmayın.*
- **Bileşenler:**
  - `MysticCard`: İçerikleri barındıran asıl kart konteyneri. (Glow efektleriyle çerçevelenmiş).
  - `StarField`: `HomeView` vb. arka planlarında uçuşan yıldız efektini veren `Canvas` tabanlı bileşen. Parça bazlı performans açısından çok önemlidir.
  - `MysticButton`: Ana ve ikincil buton tasarımları.

## 5. Gelecek Geliştirmeler (Next Steps)
Devralacak Agent'ın ilk odaklanması gereken potansiyel kısımlar:

1. **Gerçek Veritabanı Geçişi:** `FirestoreService.swift` içerisindeki UserDefaults okuma/yazma (saveUser, saveChatSession vs.) mantıklarını gerçek Firebase Cloud Firestore metotlarına evrimleştirmek.
2. **Astrology Engine Bağlantısı:** Swiss Ephemeris (`swisseph`) entegrasyonu ile sahte (mock) `ChartData` üretimini gerçek astronomik konumlarla (Gezegen ve Evler) değiştirmek.
3. **El Falı (Palm Reading) Multimodal:** Şu an `AIService.interpretPalm` fonksiyonu sadece mock metin atıyor, resim işlemesi eklenmeli (base64).
4. **Push Notifications:** Firebase Cloud Messaging ile günlük burç yorumu bildirimleri atmak.
5. **Premium State & Paywall:** StoreKit kullanarak Mock `isPremium` statüsünü gerçeğe çevirmek.

Bol şans!
