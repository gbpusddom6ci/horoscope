import SwiftUI
import StoreKit
import FirebaseAuth

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(AuthService.self) private var authService
    @Environment(PremiumService.self) private var premiumService

    @State private var errorMessage: String?

    private var hasPremium: Bool {
        premiumService.hasPremiumAccess || authService.currentUser?.isPremium == true
    }

    private var termsURL: URL? {
        Secrets.termsOfUseURL
    }

    private var privacyURL: URL? {
        Secrets.privacyPolicyURL
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackdrop(style: .ambient)

                ScrollView {
                    VStack(spacing: MysticSpacing.lg) {
                        LumenCard(accent: AuroraColors.auroraMint) {
                            VStack(spacing: AuroraSpacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(AuroraColors.auroraMint.opacity(0.16))
                                        .frame(width: 88, height: 88)

                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 38))
                                        .foregroundStyle(MysticGradients.goldShimmer)
                                }

                                VStack(spacing: AuroraSpacing.sm) {
                                    Text("settings.paywall.title")
                                        .font(MysticFonts.heading(24))
                                        .foregroundColor(MysticColors.textPrimary)

                                    Text("Unlimited Oracle chats, richer natal readings, and premium aurora experiences across Tarot and Palm Reading.")
                                        .font(MysticFonts.body(14))
                                        .foregroundColor(MysticColors.textSecondary)
                                        .multilineTextAlignment(.center)
                                }

                                HStack(spacing: AuroraSpacing.sm) {
                                    paywallFeatureChip("Oracle", icon: "sparkles", accent: AuroraColors.auroraViolet)
                                    paywallFeatureChip("Atlas", icon: "circle.hexagongrid.fill", accent: AuroraColors.auroraCyan)
                                    paywallFeatureChip("Tarot", icon: "sparkles.rectangle.stack.fill", accent: AuroraColors.auroraRose)
                                    paywallFeatureChip("Palm", icon: "hand.raised.fill", accent: AuroraColors.auroraMint)
                                }
                            }
                        }
                        .padding(.horizontal, MysticSpacing.md)

                        if hasPremium {
                            MysticCard(glowColor: MysticColors.auroraGreen) {
                                HStack(spacing: MysticSpacing.sm) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(MysticColors.auroraGreen)
                                    Text("settings.paywall.active")
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
                                    Text("settings.paywall.packages_failed_title")
                                        .font(MysticFonts.heading(15))
                                        .foregroundColor(MysticColors.textPrimary)
                                    Text("settings.paywall.packages_failed_body")
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

                        MysticButton(String(localized: "settings.paywall.restore"), icon: "arrow.clockwise", style: .secondary) {
                            Task {
                                await premiumService.restorePurchases()
                                await MainActor.run {
                                    authService.updatePremiumStatus(premiumService.hasPremiumAccess)
                                }
                            }
                        }
                        .padding(.horizontal, MysticSpacing.md)

                        VStack(spacing: MysticSpacing.xs) {
                            Text("settings.paywall.legal.auto_renew")
                                .font(MysticFonts.caption(11))
                                .foregroundColor(MysticColors.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, MysticSpacing.md)

                            HStack(spacing: MysticSpacing.xs) {
                                Button(String(localized: "settings.paywall.legal.terms")) {
                                    guard let termsURL else { return }
                                    openURL(termsURL)
                                }
                                .disabled(termsURL == nil)

                                Text("settings.paywall.legal.separator")
                                    .foregroundColor(MysticColors.textMuted)

                                Button(String(localized: "settings.paywall.legal.privacy")) {
                                    guard let privacyURL else { return }
                                    openURL(privacyURL)
                                }
                                .disabled(privacyURL == nil)
                            }
                            .font(MysticFonts.caption(12))
                            .foregroundColor(MysticColors.neonLavender)
                        }

                        Color.clear.frame(height: 20)
                    }
                    .padding(.top, MysticSpacing.md)
                }
            }
            .navigationTitle(Text("settings.paywall.nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.close")) {
                        dismiss()
                    }
                    .foregroundColor(AuroraColors.auroraCyan)
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

    private func paywallFeatureChip(_ title: String, icon: String, accent: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accent)
            }

            Text(title)
                .font(AuroraTypography.mono(10))
                .foregroundColor(AuroraColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DeleteAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    @State private var confirmText = ""
    @State private var password = ""
    @State private var errorMessage: String?

    private let requiredConfirmationWord = "DELETE"

    private var requiresPassword: Bool {
        guard let currentUser = Auth.auth().currentUser else { return false }
        return currentUser.providerData.contains(where: { $0.providerID == EmailAuthProviderID })
    }

    private var canDelete: Bool {
        let hasConfirmed = confirmText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == requiredConfirmationWord
        if !hasConfirmed {
            return false
        }
        if requiresPassword {
            return !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackdrop(style: .ambient)

                ScrollView {
                    VStack(spacing: MysticSpacing.md) {
                        MysticCard(glowColor: MysticColors.celestialPink) {
                            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                                Text("settings.delete_account.warning")
                                    .font(MysticFonts.body(14))
                                    .foregroundColor(MysticColors.textSecondary)
                                    .lineSpacing(3)

                                Text("settings.delete_account.confirm_help")
                                    .font(MysticFonts.caption(12))
                                    .foregroundColor(MysticColors.textMuted)
                            }
                        }

                        MysticTextField(
                            String(localized: "settings.delete_account.confirm_placeholder"),
                            text: $confirmText
                        )
                        .accessibilityIdentifier("settings.delete_account.confirm")

                        if requiresPassword {
                            MysticTextField(
                                String(localized: "settings.delete_account.password"),
                                text: $password,
                                icon: "lock.fill",
                                isSecure: true
                            )
                            .accessibilityHint(Text(String(localized: "settings.delete_account.password_hint")))
                            .accessibilityIdentifier("settings.delete_account.password")
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(MysticFonts.caption(12))
                                .foregroundColor(MysticColors.celestialPink)
                                .multilineTextAlignment(.leading)
                        }

                        MysticButton(
                            String(localized: "settings.delete_account.action"),
                            icon: "trash.fill",
                            style: .danger,
                            isLoading: authService.isLoading
                        ) {
                            deleteAccount()
                        }
                        .disabled(!canDelete || authService.isLoading)

                        MysticButton(String(localized: "settings.delete_account.cancel"), style: .secondary) {
                            dismiss()
                        }
                        .disabled(authService.isLoading)
                    }
                    .padding(MysticSpacing.md)
                }
            }
            .navigationTitle(Text("settings.delete_account.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.close")) {
                        dismiss()
                    }
                    .foregroundColor(AuroraColors.auroraCyan)
                    .disabled(authService.isLoading)
                }
            }
        }
    }

    private func deleteAccount() {
        errorMessage = nil

        Task {
            do {
                let passwordValue = requiresPassword ? password : nil
                try await authService.deleteAccount(password: passwordValue)
                await MainActor.run {
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
                AuroraBackdrop(style: .ambient)

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
                                Text("settings.notifications.daily_toggle")
                                    .font(MysticFonts.body(15))
                                    .foregroundColor(MysticColors.textPrimary)
                            }
                            .tint(MysticColors.neonLavender)

                            if notificationService.dailyNotificationsEnabled {
                                DatePicker(
                                    String(localized: "settings.notifications.time"),
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
                                 String(localized: "settings.notifications.permission_on") :
                                 String(localized: "settings.notifications.permission_off"))
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
            .navigationTitle(Text("settings.notifications.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.close")) {
                        dismiss()
                    }
                    .foregroundColor(AuroraColors.auroraCyan)
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
    @AppStorage("selected_language") private var selectedLanguage = "en"

    private let languages: [(code: String, title: String, enabled: Bool)] = [
        ("en", "English", true),
        ("tr", "Turkish", true)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackdrop(style: .ambient)

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

                    Text("settings.language.info")
                        .font(MysticFonts.caption(12))
                        .foregroundColor(MysticColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.top, MysticSpacing.sm)

                    Spacer()
                }
                .padding(MysticSpacing.md)
            }
            .navigationTitle(Text("settings.language.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.close")) {
                        dismiss()
                    }
                    .foregroundColor(AuroraColors.auroraCyan)
                }
            }
            .onAppear {
                if !languages.contains(where: { $0.code == selectedLanguage && $0.enabled }) {
                    selectedLanguage = "en"
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
                AuroraBackdrop(style: .ambient)

                ScrollView {
                    VStack(alignment: .leading, spacing: MysticSpacing.md) {
                        helpCard(
                            title: String(localized: "settings.help.account.title"),
                            body: String(localized: "settings.help.account.body")
                        )
                        helpCard(
                            title: String(localized: "settings.help.birth.title"),
                            body: String(localized: "settings.help.birth.body")
                        )
                        helpCard(
                            title: String(localized: "settings.help.ai.title"),
                            body: String(localized: "settings.help.ai.body")
                        )

                        MysticButton(String(localized: "settings.help.email"), icon: "envelope.fill", style: .secondary) {
                            if let url = URL(string: "mailto:support@rkhoroscope.app") {
                                openURL(url)
                            }
                        }
                        
                        // Developer Crashlytics Test Button
                        #if DEBUG && canImport(FirebaseCrashlytics)
                        Button("Developer: Force Crash") {
                            fatalError("Crashlytics Test Crash")
                        }
                        .font(MysticFonts.caption(12))
                        .foregroundColor(MysticColors.celestialPink.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, MysticSpacing.lg)
                        #endif
                    }
                    .padding(MysticSpacing.md)
                }
            }
            .navigationTitle(Text("settings.help.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.close")) {
                        dismiss()
                    }
                    .foregroundColor(AuroraColors.auroraCyan)
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
                AuroraBackdrop(style: .ambient)

                ScrollView {
                    MysticCard(glowColor: MysticColors.mysticGold) {
                        VStack(alignment: .leading, spacing: MysticSpacing.md) {
                            Text("settings.privacy.title")
                                .font(MysticFonts.heading(18))
                                .foregroundColor(MysticColors.textPrimary)

                            Text("settings.privacy.item1")
                                .font(MysticFonts.body(14))
                                .foregroundColor(MysticColors.textSecondary)
                            Text("settings.privacy.item2")
                                .font(MysticFonts.body(14))
                                .foregroundColor(MysticColors.textSecondary)
                            Text("settings.privacy.item3")
                                .font(MysticFonts.body(14))
                                .foregroundColor(MysticColors.textSecondary)
                            Text("settings.privacy.item4")
                                .font(MysticFonts.body(14))
                                .foregroundColor(MysticColors.textSecondary)
                        }
                    }
                    .padding(MysticSpacing.md)
                }
            }
            .navigationTitle(Text("settings.privacy.nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.close")) {
                        dismiss()
                    }
                    .foregroundColor(AuroraColors.auroraCyan)
                }
            }
        }
    }
}
