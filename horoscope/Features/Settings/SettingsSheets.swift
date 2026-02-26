import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    @Environment(PremiumService.self) private var premiumService

    @State private var errorMessage: String?

    private var hasPremium: Bool {
        premiumService.hasPremiumAccess || authService.currentUser?.isPremium == true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MysticColors.voidBlack.ignoresSafeArea()
                StarField(starCount: 35)

                ScrollView {
                    VStack(spacing: MysticSpacing.lg) {
                        VStack(spacing: MysticSpacing.sm) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 52))
                                .foregroundStyle(MysticGradients.goldShimmer)

                            Text("Mystic Premium")
                                .font(MysticFonts.heading(24))
                                .foregroundColor(MysticColors.textPrimary)

                            Text("Sınırsız AI yorumları ve gelişmiş mistik özellikler.")
                                .font(MysticFonts.body(14))
                                .foregroundColor(MysticColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        if hasPremium {
                            MysticCard(glowColor: MysticColors.auroraGreen) {
                                HStack(spacing: MysticSpacing.sm) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(MysticColors.auroraGreen)
                                    Text("Premium aktif. Teşekkürler!")
                                        .font(MysticFonts.body(15))
                                        .foregroundColor(MysticColors.textPrimary)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, MysticSpacing.md)
                        }

                        if premiumService.isLoadingProducts {
                            ProgressView()
                                .tint(MysticColors.neonLavender)
                        }

                        if !premiumService.isLoadingProducts && premiumService.products.isEmpty {
                            MysticCard(glowColor: MysticColors.celestialPink) {
                                VStack(alignment: .leading, spacing: MysticSpacing.xs) {
                                    Text("Paketler Yüklenemedi")
                                        .font(MysticFonts.heading(15))
                                        .foregroundColor(MysticColors.textPrimary)
                                    Text("Şu an premium paket listesi alınamadı. İnternetinizi kontrol edip tekrar deneyin.")
                                        .font(MysticFonts.caption(12))
                                        .foregroundColor(MysticColors.textSecondary)
                                }
                            }
                            .padding(.horizontal, MysticSpacing.md)
                        }

                        ForEach(premiumService.products, id: \.id) { product in
                            Button {
                                purchase(product)
                            } label: {
                                MysticCard(glowColor: MysticColors.mysticGold) {
                                    VStack(alignment: .leading, spacing: MysticSpacing.xs) {
                                        Text(product.displayName)
                                            .font(MysticFonts.heading(16))
                                            .foregroundColor(MysticColors.textPrimary)

                                        Text(product.description)
                                            .font(MysticFonts.caption(12))
                                            .foregroundColor(MysticColors.textSecondary)
                                            .lineLimit(2)

                                        HStack {
                                            Text(product.displayPrice)
                                                .font(MysticFonts.heading(18))
                                                .foregroundColor(MysticColors.mysticGold)
                                            Spacer()
                                            Image(systemName: "arrow.right.circle.fill")
                                                .foregroundColor(MysticColors.neonLavender)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(premiumService.isPurchasing || hasPremium)
                        }
                        .padding(.horizontal, MysticSpacing.md)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(MysticFonts.caption(13))
                                .foregroundColor(MysticColors.celestialPink)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, MysticSpacing.md)
                        }

                        MysticButton("Satın Alımları Geri Yükle", icon: "arrow.clockwise", style: .secondary) {
                            Task {
                                await premiumService.restorePurchases()
                                await MainActor.run {
                                    authService.updatePremiumStatus(premiumService.hasPremiumAccess)
                                }
                            }
                        }
                        .padding(.horizontal, MysticSpacing.md)

                        Color.clear.frame(height: 20)
                    }
                    .padding(.top, MysticSpacing.md)
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(MysticColors.neonLavender)
                }
            }
            .task {
                await premiumService.refreshProducts()
                await premiumService.refreshEntitlements()
                authService.updatePremiumStatus(premiumService.hasPremiumAccess)
            }
        }
    }

    private func purchase(_ product: Product) {
        Task {
            do {
                let success = try await premiumService.purchase(product)
                guard success else { return }

                await premiumService.refreshEntitlements()
                await MainActor.run {
                    authService.updatePremiumStatus(premiumService.hasPremiumAccess)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct NotificationPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationService.self) private var notificationService

    var body: some View {
        NavigationStack {
            ZStack {
                MysticColors.voidBlack.ignoresSafeArea()
                StarField(starCount: 25)

                VStack(spacing: MysticSpacing.lg) {
                    MysticCard(glowColor: MysticColors.neonLavender) {
                        VStack(alignment: .leading, spacing: MysticSpacing.md) {
                            Toggle(isOn: Binding(
                                get: { notificationService.dailyNotificationsEnabled },
                                set: { value in
                                    Task {
                                        await notificationService.setDailyNotificationsEnabled(value)
                                    }
                                }
                            )) {
                                Text("Günlük Burç Bildirimi")
                                    .font(MysticFonts.body(15))
                                    .foregroundColor(MysticColors.textPrimary)
                            }
                            .tint(MysticColors.neonLavender)

                            if notificationService.dailyNotificationsEnabled {
                                DatePicker(
                                    "Bildirim Saati",
                                    selection: Binding(
                                        get: { notificationService.notificationTime },
                                        set: { newValue in
                                            Task {
                                                await notificationService.setNotificationTime(newValue)
                                            }
                                        }
                                    ),
                                    displayedComponents: .hourAndMinute
                                )
                                .colorScheme(.dark)
                                .font(MysticFonts.body(14))
                                .foregroundColor(MysticColors.textSecondary)
                            }

                            Text(notificationService.isAuthorized ?
                                 "Bildirim izni açık." :
                                 "Bildirim izni kapalı. Açmak için sistem uyarısını onaylayın.")
                                .font(MysticFonts.caption(12))
                                .foregroundColor(MysticColors.textMuted)

                            if let errorMessage = notificationService.lastErrorMessage {
                                Text(errorMessage)
                                    .font(MysticFonts.caption(12))
                                    .foregroundColor(MysticColors.celestialPink)
                            }
                        }
                    }
                    .padding(.horizontal, MysticSpacing.md)

                    Spacer()
                }
                .padding(.top, MysticSpacing.md)
            }
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(MysticColors.neonLavender)
                }
            }
            .task {
                await notificationService.refreshAuthorizationStatus()
            }
        }
    }
}

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selected_language") private var selectedLanguage = "tr"

    private let languages: [(code: String, title: String, enabled: Bool)] = [
        ("tr", "Türkçe", true),
        ("en", "English", true)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MysticColors.voidBlack.ignoresSafeArea()
                StarField(starCount: 20)

                VStack(spacing: MysticSpacing.md) {
                    ForEach(languages, id: \.code) { language in
                        Button {
                            guard language.enabled else { return }
                            selectedLanguage = language.code
                        } label: {
                            MysticCard(glowColor: selectedLanguage == language.code ? MysticColors.mysticGold : MysticColors.neonLavender) {
                                HStack {
                                    Text(language.title)
                                        .font(MysticFonts.body(15))
                                        .foregroundColor(language.enabled ? MysticColors.textPrimary : MysticColors.textMuted)
                                    Spacer()
                                    if selectedLanguage == language.code {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(MysticColors.mysticGold)
                                    }
                                }
                            }
                            .opacity(language.enabled ? 1 : 0.65)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Dil değişikliği anında uygulanır. Eksik çeviriler varsayılan dile dönebilir.")
                        .font(MysticFonts.caption(12))
                        .foregroundColor(MysticColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.top, MysticSpacing.sm)

                    Spacer()
                }
                .padding(MysticSpacing.md)
            }
            .navigationTitle("Dil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(MysticColors.neonLavender)
                }
            }
            .onAppear {
                if !languages.contains(where: { $0.code == selectedLanguage && $0.enabled }) {
                    selectedLanguage = "tr"
                }
            }
        }
    }
}

struct HelpCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ZStack {
                MysticColors.voidBlack.ignoresSafeArea()
                StarField(starCount: 15)

                ScrollView {
                    VStack(alignment: .leading, spacing: MysticSpacing.md) {
                        helpCard(
                            title: "Hesap",
                            body: "Giriş sorunlarında internet bağlantınızı ve Apple/Firebase oturum durumunu kontrol edin."
                        )
                        helpCard(
                            title: "Doğum Verisi",
                            body: "Doğum saati bilinmiyorsa yükselen ve ev yorumları sınırlı olabilir."
                        )
                        helpCard(
                            title: "AI Yanıtları",
                            body: "Yanıt alamazsanız API anahtarlarının doğru yapılandırıldığından emin olun."
                        )

                        MysticButton("Destek E-postası", icon: "envelope.fill", style: .secondary) {
                            if let url = URL(string: "mailto:support@rkhoroscope.app") {
                                openURL(url)
                            }
                        }
                    }
                    .padding(MysticSpacing.md)
                }
            }
            .navigationTitle("Yardım & Destek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(MysticColors.neonLavender)
                }
            }
        }
    }

    private func helpCard(title: String, body: String) -> some View {
        MysticCard(glowColor: MysticColors.neonLavender) {
            VStack(alignment: .leading, spacing: MysticSpacing.xs) {
                Text(title)
                    .font(MysticFonts.heading(16))
                    .foregroundColor(MysticColors.textPrimary)
                Text(body)
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.textSecondary)
            }
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MysticColors.voidBlack.ignoresSafeArea()
                StarField(starCount: 15)

                ScrollView {
                    MysticCard(glowColor: MysticColors.mysticGold) {
                        VStack(alignment: .leading, spacing: MysticSpacing.md) {
                            Text("Gizlilik Politikası")
                                .font(MysticFonts.heading(18))
                                .foregroundColor(MysticColors.textPrimary)

                            Text("1. Uygulama içi hesap verileri Firebase üzerinde saklanır.")
                                .font(MysticFonts.body(14))
                                .foregroundColor(MysticColors.textSecondary)
                            Text("2. AI yorumları için kullanıcı girdileri OpenRouter üzerinden işlenir.")
                                .font(MysticFonts.body(14))
                                .foregroundColor(MysticColors.textSecondary)
                            Text("3. API anahtarları uygulama kodunda tutulmaz; yalnızca güvenli yapılandırma ile sağlanır.")
                                .font(MysticFonts.body(14))
                                .foregroundColor(MysticColors.textSecondary)
                            Text("4. Bildirim tercihleriniz cihazınızda saklanır.")
                                .font(MysticFonts.body(14))
                                .foregroundColor(MysticColors.textSecondary)
                        }
                    }
                    .padding(MysticSpacing.md)
                }
            }
            .navigationTitle("Gizlilik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(MysticColors.neonLavender)
                }
            }
        }
    }
}
