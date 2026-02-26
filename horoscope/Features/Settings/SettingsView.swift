import SwiftUI
import MapKit
import os

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(PremiumService.self) private var premiumService
    @State private var showEditBirthData = false
    @State private var showPaywall = false
    @State private var showNotificationPreferences = false
    @State private var showLanguageSettings = false
    @State private var showHelpCenter = false
    @State private var showPrivacyPolicy = false

    private var user: AppUser? { authService.currentUser }
    private var birthData: BirthData? { user?.birthData }
    private var hasPremiumAccess: Bool { (user?.isPremium ?? false) || premiumService.hasPremiumAccess }

    private struct SettingsItem: Identifiable {
        let id: String
        let icon: String
        let titleKey: String
        let subtitleKey: String
        let color: Color
        let action: () -> Void
    }

    private struct SettingsSectionModel: Identifiable {
        let id: String
        let titleKey: String
        let items: [SettingsItem]
    }

    private var quickSettingsSection: SettingsSectionModel {
        SettingsSectionModel(
            id: "quick",
            titleKey: "settings.section.quick",
            items: [
                SettingsItem(
                    id: "premium",
                    icon: "crown.fill",
                    titleKey: "settings.item.premium.title",
                    subtitleKey: "settings.item.premium.subtitle",
                    color: MysticColors.mysticGold,
                    action: { showPaywall = true }
                ),
                SettingsItem(
                    id: "notifications",
                    icon: "bell.fill",
                    titleKey: "settings.item.notifications.title",
                    subtitleKey: "settings.item.notifications.subtitle",
                    color: MysticColors.neonLavender,
                    action: { showNotificationPreferences = true }
                ),
                SettingsItem(
                    id: "language",
                    icon: "globe",
                    titleKey: "settings.item.language.title",
                    subtitleKey: "settings.item.language.subtitle",
                    color: MysticColors.auroraGreen,
                    action: { showLanguageSettings = true }
                )
            ]
        )
    }

    private var supportSection: SettingsSectionModel {
        SettingsSectionModel(
            id: "support",
            titleKey: "settings.section.support",
            items: [
                SettingsItem(
                    id: "help",
                    icon: "questionmark.circle",
                    titleKey: "settings.item.help.title",
                    subtitleKey: "settings.item.help.subtitle",
                    color: MysticColors.textSecondary,
                    action: { showHelpCenter = true }
                ),
                SettingsItem(
                    id: "privacy",
                    icon: "doc.text",
                    titleKey: "settings.item.privacy.title",
                    subtitleKey: "settings.item.privacy.subtitle",
                    color: MysticColors.textSecondary,
                    action: { showPrivacyPolicy = true }
                )
            ]
        )
    }

    var body: some View {
        ZStack {
            StarField(starCount: 30)

            VStack(spacing: 0) {
                Text("settings.title")
                    .font(MysticFonts.heading(18))
                    .foregroundColor(MysticColors.textPrimary)
                    .padding(.top, 10)
                    .padding(.bottom, 10)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: MysticSpacing.lg) {
                        profileHeader.fadeInOnAppear(delay: 0)
                        settingsSectionCard(quickSettingsSection).fadeInOnAppear(delay: 0.1)
                        accountSection.fadeInOnAppear(delay: 0.2)
                        settingsSectionCard(supportSection).fadeInOnAppear(delay: 0.3)
                        dangerZone.fadeInOnAppear(delay: 0.35)
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, MysticSpacing.md)
                    .padding(.top, MysticSpacing.md)
                }
            }
            .sheet(isPresented: $showEditBirthData) {
                EditBirthDataSheet()
                    .environment(authService)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environment(authService)
                    .environment(premiumService)
            }
            .sheet(isPresented: $showNotificationPreferences) {
                NotificationPreferencesView()
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
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        MysticCard(glowColor: MysticColors.neonLavender) {
            VStack(spacing: MysticSpacing.md) {
                ZStack {
                    Circle()
                        .fill(MysticColors.neonLavender.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Circle()
                        .stroke(MysticColors.neonLavender.opacity(0.4), lineWidth: 2)
                        .frame(width: 80, height: 80)
                    if let sign = birthData?.sunSign {
                        Text(sign.symbol)
                            .font(.system(size: 36))
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(MysticColors.neonLavender)
                    }
                }

                Text(user?.displayName ?? String(localized: "common.user"))
                    .font(MysticFonts.heading(22))
                    .foregroundColor(MysticColors.textPrimary)

                if let email = user?.email {
                    Text(email)
                        .font(MysticFonts.caption(14))
                        .foregroundColor(MysticColors.textMuted)
                }

                // Premium badge
                HStack(spacing: MysticSpacing.xs) {
                    Image(systemName: hasPremiumAccess ? "crown.fill" : "crown")
                        .font(.system(size: 14))
                    Text(hasPremiumAccess ? String(localized: "settings.plan.premium") : String(localized: "settings.plan.free"))
                        .font(MysticFonts.caption(13))
                }
                .foregroundColor(MysticColors.mysticGold)
                .padding(.horizontal, MysticSpacing.md)
                .padding(.vertical, MysticSpacing.xs + 2)
                .background(MysticColors.mysticGold.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Sections

    private func sectionTitle(_ key: String) -> some View {
        Text(LocalizedStringKey(key))
            .font(MysticFonts.heading(16))
            .foregroundColor(MysticColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingsSectionCard(_ section: SettingsSectionModel) -> some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            sectionTitle(section.titleKey)

            VStack(spacing: MysticSpacing.sm) {
                ForEach(section.items) { item in
                    settingsMenuItem(item)
                }
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            sectionTitle("settings.section.account")

            if let bd = birthData {
                MysticCard(glowColor: bd.sunSign.elementColor) {
                    VStack(alignment: .leading, spacing: MysticSpacing.md) {
                        HStack {
                            Text("settings.birth.title")
                                .font(MysticFonts.heading(16))
                                .foregroundColor(MysticColors.textPrimary)
                            Spacer()
                            Button {
                                showEditBirthData = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 13))
                                    Text("settings.birth.edit")
                                        .font(MysticFonts.caption(13))
                                }
                                .foregroundColor(MysticColors.neonLavender)
                            }
                            .buttonStyle(.plain)
                            .frame(minHeight: MysticAccessibility.minimumTapTarget)
                            .accessibilityHint(Text(String(localized: "settings.menu.open_hint")))
                        }

                        infoRow(icon: "calendar", label: String(localized: "settings.birth.date"), value: bd.birthDate.formatted(as: "d MMMM yyyy"))
                        if bd.isBirthTimeKnown {
                            infoRow(icon: "clock", label: String(localized: "settings.birth.time"), value: bd.birthTime?.formatted(as: "HH:mm") ?? "-")
                        }
                        infoRow(icon: "mappin", label: String(localized: "settings.birth.place"), value: bd.birthPlace)
                        infoRow(icon: "sun.max", label: String(localized: "settings.birth.sun"), value: "\(bd.sunSign.symbol) \(bd.sunSign.rawValue)")
                    }
                }
            } else {
                settingsMenuItem(
                    SettingsItem(
                        id: "birth_add",
                        icon: "calendar.badge.plus",
                        titleKey: "settings.item.birth_add.title",
                        subtitleKey: "settings.item.birth_add.subtitle",
                        color: MysticColors.neonLavender,
                        action: { showEditBirthData = true }
                    )
                )
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(MysticColors.textMuted)
                .frame(width: 24)
            Text(label)
                .font(MysticFonts.body(14))
                .foregroundColor(MysticColors.textSecondary)
            Spacer()
            Text(value)
                .font(MysticFonts.body(14))
                .foregroundColor(MysticColors.textPrimary)
        }
    }

    private func settingsMenuItem(_ item: SettingsItem) -> some View {
        Button(action: item.action) {
            MysticCard {
                HStack(spacing: MysticSpacing.md) {
                    Image(systemName: item.icon)
                        .font(.system(size: 18))
                        .foregroundColor(item.color)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(item.titleKey))
                            .font(MysticFonts.body(15))
                            .foregroundColor(MysticColors.textPrimary)
                        Text(LocalizedStringKey(item.subtitleKey))
                            .font(MysticFonts.caption(12))
                            .foregroundColor(MysticColors.textMuted)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(MysticColors.textMuted)
                }
                .frame(minHeight: MysticAccessibility.minimumTapTarget)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(item.titleKey)))
        .accessibilityHint(Text(String(localized: "settings.menu.open_hint")))
    }

    // MARK: - Danger Zone
    private var dangerZone: some View {
        VStack(spacing: MysticSpacing.sm) {
            MysticButton(String(localized: "settings.signout"), icon: "rectangle.portrait.and.arrow.right", style: .danger) {
                authService.signOut()
            }

            Text("Mystic v1.0.0")
                .font(MysticFonts.caption(12))
                .foregroundColor(MysticColors.textMuted)
                .padding(.top, MysticSpacing.sm)
        }
    }
}

// MARK: - Edit Birth Data Sheet
struct EditBirthDataSheet: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var birthDate: Date = Date()
    @State private var birthTime: Date = Date()
    @State private var birthTimeKnown: Bool = true
    @State private var birthPlace: String = ""
    @State private var latitude: Double = 0
    @State private var longitude: Double = 0
    @State private var timeZoneId: String = "Europe/Istanbul"

    // Location search
    @State private var locationQuery: String = ""
    @State private var locationResults: [MKLocalSearchCompletion] = []
    @State private var searchCompleter = MKLocalSearchCompleter()
    @State private var showLocationResults = false
    @State private var isSaving = false
    @State private var saveErrorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                MysticColors.voidBlack.ignoresSafeArea()
                StarField(starCount: 30)

                ScrollView {
                    VStack(spacing: MysticSpacing.lg) {
                        // Birth Date
                        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                            Text("settings.edit.birth_date")
                                .font(MysticFonts.heading(16))
                                .foregroundColor(MysticColors.textPrimary)
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .colorScheme(.dark)
                                .frame(maxHeight: 140)
                                .clipped()
                        }

                        // Birth Time
                        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                            Toggle(isOn: $birthTimeKnown) {
                                Text("settings.edit.birth_time")
                                    .font(MysticFonts.heading(16))
                                    .foregroundColor(MysticColors.textPrimary)
                            }
                            .tint(MysticColors.neonLavender)

                            if birthTimeKnown {
                                DatePicker("", selection: $birthTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.wheel)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .frame(maxHeight: 100)
                                    .clipped()
                            }
                        }

                        // Birth Place
                        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                            Text("settings.edit.birth_place")
                                .font(MysticFonts.heading(16))
                                .foregroundColor(MysticColors.textPrimary)

                            TextField(String(localized: "settings.edit.search_placeholder"), text: $locationQuery)
                                .font(MysticFonts.body(15))
                                .foregroundColor(MysticColors.textPrimary)
                                .padding(MysticSpacing.md)
                                .background(MysticColors.inputBackground)
                                .clipShape(RoundedRectangle(cornerRadius: MysticRadius.md))
                                .overlay(RoundedRectangle(cornerRadius: MysticRadius.md).stroke(MysticColors.cardBorder, lineWidth: 1))
                                .onChange(of: locationQuery) { _, newValue in
                                    if !newValue.isEmpty {
                                        searchCompleter.queryFragment = newValue
                                        showLocationResults = true
                                    } else {
                                        showLocationResults = false
                                    }
                                }

                            if !birthPlace.isEmpty {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(MysticColors.auroraGreen)
                                    Text(birthPlace)
                                        .font(MysticFonts.body(14))
                                        .foregroundColor(MysticColors.auroraGreen)
                                }
                            }

                            if showLocationResults && !locationResults.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(locationResults.prefix(5), id: \.self) { result in
                                        Button {
                                            selectLocation(result)
                                        } label: {
                                            HStack {
                                                Image(systemName: "mappin")
                                                    .foregroundColor(MysticColors.textMuted)
                                                    .frame(width: 20)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(result.title)
                                                        .font(MysticFonts.body(14))
                                                        .foregroundColor(MysticColors.textPrimary)
                                                    if !result.subtitle.isEmpty {
                                                        Text(result.subtitle)
                                                            .font(MysticFonts.caption(12))
                                                            .foregroundColor(MysticColors.textMuted)
                                                    }
                                                }
                                                Spacer()
                                            }
                                            .padding(.vertical, MysticSpacing.sm)
                                            .padding(.horizontal, MysticSpacing.md)
                                        }
                                        .buttonStyle(.plain)
                                        Divider().background(MysticColors.cardBorder)
                                    }
                                }
                                .background(MysticColors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: MysticRadius.md))
                                .overlay(RoundedRectangle(cornerRadius: MysticRadius.md).stroke(MysticColors.cardBorder, lineWidth: 1))
                            }
                        }

                        // Save Button
                        MysticButton(String(localized: "common.save"), icon: "checkmark.circle.fill", style: .primary, isLoading: isSaving) {
                            saveBirthData()
                        }
                        .disabled(birthPlace.isEmpty)

                        if let saveErrorMessage {
                            Text(saveErrorMessage)
                                .font(MysticFonts.caption(12))
                                .foregroundColor(MysticColors.celestialPink)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, MysticSpacing.sm)
                        }
                    }
                    .padding(MysticSpacing.md)
                }
            }
            .navigationTitle(Text("settings.edit.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                        .foregroundColor(MysticColors.neonLavender)
                }
            }
            .onAppear {
                loadCurrentData()
                setupCompleter()
            }
        }
    }

    private func loadCurrentData() {
        guard let bd = authService.currentUser?.birthData else { return }
        birthDate = bd.birthDate
        birthTimeKnown = bd.isBirthTimeKnown
        if let time = bd.birthTime { birthTime = time }
        birthPlace = bd.birthPlace
        latitude = bd.latitude
        longitude = bd.longitude
        timeZoneId = bd.timeZoneIdentifier
        locationQuery = ""
    }

    private func setupCompleter() {
        let delegate = LocationSearchDelegate { results in
            locationResults = results
        }
        searchCompleter.delegate = delegate
        // Store delegate to keep it alive
        objc_setAssociatedObject(searchCompleter, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
    }

    private func selectLocation(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let item = response?.mapItems.first else { return }
            birthPlace = [completion.title, completion.subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
            latitude = item.placemark.coordinate.latitude
            longitude = item.placemark.coordinate.longitude
            timeZoneId = item.timeZone?.identifier ?? "UTC"
            locationQuery = ""
            showLocationResults = false
        }
    }

    private func saveBirthData() {
        guard !isSaving else { return }
        isSaving = true
        saveErrorMessage = nil

        let newBirthData = BirthData(
            birthDate: birthDate,
            birthTime: birthTimeKnown ? birthTime : nil,
            birthPlace: birthPlace,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZoneId
        )

        Task {
            do {
                try await authService.updateBirthData(newBirthData)
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveErrorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Location Search Delegate
class LocationSearchDelegate: NSObject, MKLocalSearchCompleterDelegate {
    var onResults: ([MKLocalSearchCompletion]) -> Void
    private let logger = Logger(subsystem: "rk.horoscope", category: "Settings")

    init(onResults: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.onResults = onResults
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onResults(completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        logger.error("Location search error: \(error.localizedDescription, privacy: .public)")
    }
}

#Preview {
    SettingsView()
        .environment(AuthService())
        .environment(PremiumService.shared)
        .environment(NotificationService.shared)
}
