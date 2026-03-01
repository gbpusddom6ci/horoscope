import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(PremiumService.self) private var premiumService

    @State private var showPaywall = false
    @State private var showNotificationPreferences = false
    @State private var showLanguageSettings = false
    @State private var showHelpCenter = false
    @State private var showPrivacyPolicy = false

    private var hasPremiumAccess: Bool {
        (authService.currentUser?.isPremium ?? false) || premiumService.hasPremiumAccess
    }

    var body: some View {
        ZStack {
            StarField(starCount: 30)

            ScrollView(showsIndicators: false) {
                VStack(spacing: MysticSpacing.lg) {
                    profileHeader
                        .fadeInOnAppear(delay: 0)

                    settingsSection(
                        titleKey: "settings.section.quick",
                        rows: [
                            .init(
                                id: "settings.quick.premium",
                                icon: "crown.fill",
                                title: String(localized: "settings.item.premium.title"),
                                subtitle: String(localized: "settings.item.premium.subtitle"),
                                tint: MysticColors.mysticGold,
                                action: { showPaywall = true }
                            ),
                            .init(
                                id: "settings.quick.notifications",
                                icon: "bell.fill",
                                title: String(localized: "settings.item.notifications.title"),
                                subtitle: String(localized: "settings.item.notifications.subtitle"),
                                tint: MysticColors.neonLavender,
                                action: { showNotificationPreferences = true }
                            ),
                            .init(
                                id: "settings.quick.language",
                                icon: "globe",
                                title: String(localized: "settings.item.language.title"),
                                subtitle: String(localized: "settings.item.language.subtitle"),
                                tint: MysticColors.auroraGreen,
                                action: { showLanguageSettings = true }
                            )
                        ]
                    )
                    .fadeInOnAppear(delay: 0.1)

                    accountSection
                        .fadeInOnAppear(delay: 0.15)

                    settingsSection(
                        titleKey: "settings.section.support",
                        rows: [
                            .init(
                                id: "settings.support.help",
                                icon: "questionmark.circle",
                                title: String(localized: "settings.item.help.title"),
                                subtitle: String(localized: "settings.item.help.subtitle"),
                                tint: MysticColors.textSecondary,
                                action: { showHelpCenter = true }
                            ),
                            .init(
                                id: "settings.support.privacy",
                                icon: "doc.text",
                                title: String(localized: "settings.item.privacy.title"),
                                subtitle: String(localized: "settings.item.privacy.subtitle"),
                                tint: MysticColors.textSecondary,
                                action: { showPrivacyPolicy = true }
                            )
                        ]
                    )
                    .fadeInOnAppear(delay: 0.2)

                    dangerZone
                        .fadeInOnAppear(delay: 0.25)

                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal, MysticLayout.screenHorizontalPadding)
                .padding(.top, MysticSpacing.md)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environment(authService)
                .environment(premiumService)
        }
        .sheet(isPresented: $showNotificationPreferences) {
            NotificationPreferencesView()
                .environment(NotificationService.shared)
        }
        .sheet(isPresented: $showLanguageSettings) {
            LanguageSettingsView()
        }
        .sheet(isPresented: $showHelpCenter) {
            HelpCenterView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }

    // MARK: - Sections

    private var profileHeader: some View {
        MysticCard(glowColor: MysticColors.neonLavender) {
            VStack(spacing: MysticSpacing.md) {
                ZStack {
                    Circle()
                        .fill(MysticColors.neonLavender.opacity(0.15))
                        .frame(width: 76, height: 76)
                    Circle()
                        .stroke(MysticColors.neonLavender.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 76, height: 76)

                    if let symbol = authService.currentUser?.birthData?.sunSign.symbol {
                        Text(symbol)
                            .font(.system(size: 30))
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 26))
                            .foregroundColor(MysticColors.neonLavender)
                    }
                }

                Text(authService.currentUser?.displayName ?? String(localized: "common.user"))
                    .font(MysticFonts.heading(22))
                    .foregroundColor(MysticColors.textPrimary)

                if let email = authService.currentUser?.email, !email.isEmpty {
                    Text(email)
                        .font(MysticFonts.caption(13))
                        .foregroundColor(MysticColors.textMuted)
                }

                HStack(spacing: MysticSpacing.xs) {
                    Image(systemName: hasPremiumAccess ? "crown.fill" : "crown")
                        .font(.system(size: 13))
                    Text(hasPremiumAccess ? String(localized: "settings.plan.premium") : String(localized: "settings.plan.free"))
                        .font(MysticFonts.caption(13))
                }
                .foregroundColor(MysticColors.mysticGold)
                .padding(.horizontal, MysticSpacing.md)
                .padding(.vertical, MysticSpacing.xs + 2)
                .background(MysticColors.mysticGold.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .accessibilityIdentifier("settings.profile.header")
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            Text("settings.section.account")
                .font(MysticFonts.heading(16))
                .foregroundColor(MysticColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            MysticCard(glowColor: MysticColors.celestialPink.opacity(0.85)) {
                VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                    if let birthData = authService.currentUser?.birthData {
                        accountInfoRow(
                            icon: "sun.max.fill",
                            title: String(localized: "settings.birth.sun"),
                            value: "\(birthData.sunSign.symbol) \(birthData.sunSign.localizedDisplayName)"
                        )

                        accountInfoRow(
                            icon: "calendar",
                            title: String(localized: "settings.birth.date"),
                            value: birthData.birthDate.formatted(as: "d MMMM yyyy")
                        )

                        accountInfoRow(
                            icon: "mappin",
                            title: String(localized: "settings.birth.place"),
                            value: birthData.birthPlace
                        )
                    } else {
                        Text("settings.account.no_birth_data")
                            .font(MysticFonts.body(14))
                            .foregroundColor(MysticColors.textSecondary)
                    }
                }
            }
        }
        .accessibilityIdentifier("settings.account.section")
    }

    private func accountInfoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: MysticSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MysticColors.neonLavender)
                .frame(width: 18, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MysticFonts.caption(12))
                    .foregroundColor(MysticColors.textMuted)
                Text(value)
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.textPrimary)
            }

            Spacer(minLength: 0)
        }
    }

    private var dangerZone: some View {
        Button {
            authService.signOut()
        } label: {
            HStack(spacing: MysticSpacing.md) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MysticColors.celestialPink)

                Text("settings.sign_out")
                    .font(MysticFonts.body(15))
                    .foregroundColor(MysticColors.celestialPink)

                Spacer()
            }
            .padding(.horizontal, MysticSpacing.md)
            .padding(.vertical, MysticSpacing.sm + 2)
            .background(MysticColors.celestialPink.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("settings.signout")
    }

    private func settingsSection(titleKey: LocalizedStringKey, rows: [SettingsMenuRowModel]) -> some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            Text(titleKey)
                .font(MysticFonts.heading(16))
                .foregroundColor(MysticColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: MysticSpacing.sm) {
                ForEach(rows) { row in
                    settingsRow(row)
                }
            }
        }
    }

    private func settingsRow(_ row: SettingsMenuRowModel) -> some View {
        Button {
            row.action()
        } label: {
            MysticCard(glowColor: row.tint.opacity(0.5)) {
                HStack(spacing: MysticSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(row.tint.opacity(0.16))
                            .frame(width: 34, height: 34)
                        Image(systemName: row.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(row.tint)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.title)
                            .font(MysticFonts.body(14))
                            .foregroundColor(MysticColors.textPrimary)
                        Text(row.subtitle)
                            .font(MysticFonts.caption(12))
                            .foregroundColor(MysticColors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MysticColors.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(row.id)
    }
}

private struct SettingsMenuRowModel: Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let action: () -> Void
}

#Preview {
    SettingsView()
        .environment(AuthService())
        .environment(PremiumService.shared)
}
