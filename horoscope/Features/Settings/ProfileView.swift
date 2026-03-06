import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @Environment(PremiumService.self) private var premiumService

    @State private var showPaywall = false
    @State private var showNotificationPreferences = false
    @State private var showLanguageSettings = false
    @State private var showHelpCenter = false
    @State private var showPrivacyPolicy = false
    @State private var showDeleteAccount = false
    @State private var reminderTime = Date()

    private var hasPremiumAccess: Bool {
        (authService.currentUser?.isPremium ?? false) || premiumService.hasPremiumAccess
    }

    var body: some View {
        AuroraScreen(
            backdropStyle: .ambient,
            eyebrow: String(localized: "profile.eyebrow"),
            title: String(localized: "profile.title"),
            subtitle: String(localized: "profile.subtitle")
        ) {
            profileCard
            membershipCard
            ritualPreferencesCard
            utilityCard
            dangerCard
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
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountSheet()
                .environment(authService)
        }
        .onAppear {
            reminderTime = authService.currentUser?.ritualReminderTime ?? NotificationService.shared.notificationTime
        }
    }

    private var profileCard: some View {
        LumenCard(accent: AuroraColors.auroraCyan) {
            VStack(alignment: .leading, spacing: AuroraSpacing.md) {
                HStack(spacing: AuroraSpacing.md) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AuroraColors.auroraCyan.opacity(0.6), AuroraColors.auroraViolet.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                            .overlay(
                            Text(authService.currentUser?.birthData?.sunSign.symbol ?? String(localized: "profile.symbol_fallback"))
                                .font(.system(size: 28))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.currentUser?.displayName ?? String(localized: "common.mystic"))
                            .font(AuroraTypography.section(20))
                            .foregroundColor(AuroraColors.textPrimary)
                        Text(authService.currentUser?.email ?? String(localized: "profile.private_profile"))
                            .font(AuroraTypography.body(13))
                            .foregroundColor(AuroraColors.textSecondary)
                        if let sign = authService.currentUser?.birthData?.sunSign.localizedDisplayName {
                            Text(sign)
                                .font(AuroraTypography.mono(11))
                                .foregroundColor(AuroraColors.textMuted)
                        }
                    }
                }
            }
        }
    }

    private var membershipCard: some View {
        LumenCard(accent: AuroraColors.auroraMint) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                HStack {
                    Text("profile.membership.title")
                        .font(AuroraTypography.section(18))
                        .foregroundColor(AuroraColors.textPrimary)
                    Spacer()
                    PrismChip(hasPremiumAccess ? String(localized: "profile.membership.premium") : String(localized: "profile.membership.free"), icon: "crown.fill", accent: AuroraColors.auroraMint, isSelected: true)
                }

                Text(hasPremiumAccess
                     ? String(localized: "profile.membership.active")
                     : String(localized: "profile.membership.inactive"))
                    .font(AuroraTypography.body(14))
                    .foregroundColor(AuroraColors.textSecondary)

                HaloButton(hasPremiumAccess ? String(localized: "profile.membership.manage") : String(localized: "profile.membership.open"), icon: "crown.fill") {
                    showPaywall = true
                }
            }
        }
    }

    private var ritualPreferencesCard: some View {
        LumenCard(accent: AuroraColors.auroraViolet) {
            VStack(alignment: .leading, spacing: AuroraSpacing.md) {
                Text("profile.ritual_preferences.title")
                    .font(AuroraTypography.section(18))
                    .foregroundColor(AuroraColors.textPrimary)

                VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                    Text("profile.ritual_preferences.guidance_intent")
                        .font(AuroraTypography.bodyStrong(14))
                        .foregroundColor(AuroraColors.textPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AuroraSpacing.sm) {
                            ForEach(GuidanceIntent.allCases) { intent in
                                Button {
                                    authService.updateExperiencePreferences(guidanceIntent: intent)
                                } label: {
                                    PrismChip(
                                        intent.title,
                                        icon: intent.iconName,
                                        accent: AuroraColors.auroraViolet,
                                        isSelected: authService.currentUser?.guidanceIntent == intent
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                    Text("profile.ritual_preferences.reminder")
                        .font(AuroraTypography.bodyStrong(14))
                        .foregroundColor(AuroraColors.textPrimary)

                    DatePicker(
                        String(localized: "profile.ritual_preferences.reminder_time"),
                        selection: Binding(
                            get: { authService.currentUser?.ritualReminderTime ?? reminderTime },
                            set: { newValue in
                                reminderTime = newValue
                                authService.updateExperiencePreferences(ritualReminderTime: newValue)
                                Task {
                                    await NotificationService.shared.setNotificationTime(newValue)
                                }
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .colorScheme(.dark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var utilityCard: some View {
        LumenCard(accent: AuroraColors.auroraRose) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                actionRow(title: String(localized: "profile.utility.notifications"), subtitle: String(localized: "profile.utility.notifications.subtitle"), icon: "bell.fill") {
                    showNotificationPreferences = true
                }
                actionRow(title: String(localized: "profile.utility.language"), subtitle: String(localized: "profile.utility.language.subtitle"), icon: "globe") {
                    showLanguageSettings = true
                }
                actionRow(title: String(localized: "profile.utility.help"), subtitle: String(localized: "profile.utility.help.subtitle"), icon: "questionmark.circle.fill") {
                    showHelpCenter = true
                }
                actionRow(title: String(localized: "profile.utility.privacy"), subtitle: String(localized: "profile.utility.privacy.subtitle"), icon: "lock.fill") {
                    showPrivacyPolicy = true
                }
            }
        }
    }

    private var dangerCard: some View {
        LumenCard(accent: AuroraColors.auroraRose) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                Text("profile.danger.title")
                    .font(AuroraTypography.section(18))
                    .foregroundColor(AuroraColors.textPrimary)
                Text("profile.danger.subtitle")
                    .font(AuroraTypography.body(14))
                    .foregroundColor(AuroraColors.textSecondary)
                HaloButton(String(localized: "profile.danger.cta"), icon: "trash.fill", style: .ghost) {
                    showDeleteAccount = true
                }
            }
        }
    }

    private func actionRow(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AuroraSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AuroraColors.auroraRose)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AuroraTypography.bodyStrong(15))
                        .foregroundColor(AuroraColors.textPrimary)
                    Text(subtitle)
                        .font(AuroraTypography.body(13))
                        .foregroundColor(AuroraColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AuroraColors.textMuted)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
