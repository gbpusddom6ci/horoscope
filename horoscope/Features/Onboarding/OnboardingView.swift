import SwiftUI
import MapKit
import os

// MARK: - Onboarding View
struct OnboardingView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            AuroraBackdrop(style: .ambient)

            VStack(spacing: 0) {
                AuroraHeaderBar(
                    eyebrow: String(localized: "onboarding.screen.eyebrow"),
                    title: String(localized: "onboarding.screen.title"),
                    subtitle: String(localized: "onboarding.screen.subtitle")
                )

                progressBar
                    .padding(.top, AuroraSpacing.sm)

                TabView(selection: $viewModel.currentStep) {
                    BirthDateStep(selectedDate: $viewModel.birthDate)
                        .tag(0)

                    BirthTimeStep(
                        selectedTime: $viewModel.birthTime,
                        isTimeKnown: $viewModel.isTimeKnown
                    )
                    .tag(1)

                    BirthLocationStep(viewModel: viewModel)
                        .tag(2)

                    IntentSelectionStep(selectedIntent: $viewModel.guidanceIntent)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : AuroraMotion.spring, value: viewModel.currentStep)

                if case .failed(let message) = viewModel.submissionState {
                    Text(message)
                        .font(AuroraTypography.body(13))
                        .foregroundColor(AuroraColors.auroraRose)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AuroraSpacing.lg)
                        .padding(.bottom, AuroraSpacing.sm)
                }

                navigationButtons
                    .padding(.horizontal, AuroraSpacing.lg)
                    .padding(.bottom, AuroraSpacing.xl)
            }
        }
        .onChange(of: viewModel.currentStep) { _, _ in viewModel.persistDraft() }
        .onChange(of: viewModel.birthDate) { _, _ in viewModel.persistDraft() }
        .onChange(of: viewModel.birthTime) { _, _ in viewModel.persistDraft() }
        .onChange(of: viewModel.isTimeKnown) { _, _ in viewModel.persistDraft() }
        .onChange(of: viewModel.locationQuery) { _, _ in viewModel.persistDraft() }
        .onChange(of: viewModel.guidanceIntent) { _, _ in viewModel.persistDraft() }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: AuroraSpacing.sm) {
            ForEach(0..<4) { index in
                Capsule()
                    .fill(
                        index <= viewModel.currentStep
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [AuroraColors.auroraMint.opacity(0.8), AuroraColors.auroraCyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(AuroraColors.textMuted.opacity(0.2))
                    )
                    .frame(height: 4)
                    .shadow(
                        color: index <= viewModel.currentStep ? AuroraColors.auroraMint.opacity(0.25) : Color.clear,
                        radius: 4, y: 1
                    )
                    .animation(reduceMotion ? nil : AuroraMotion.spring, value: viewModel.currentStep)
            }
        }
        .padding(.horizontal, AuroraSpacing.lg)
        .accessibilityLabel(Text(String(localized: "onboarding.progress")))
        .accessibilityValue(Text(verbatim: "\(viewModel.currentStep + 1)/4"))
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: AuroraSpacing.md) {
            if viewModel.currentStep > 0 {
                HaloButton(String(localized: "onboarding.navigation.back"), icon: "chevron.left", style: .ghost) {
                    withAnimation(reduceMotion ? nil : AuroraMotion.spring) {
                        viewModel.currentStep -= 1
                    }
                }
                .frame(maxWidth: 120)
                .accessibilityHint(Text(String(localized: "onboarding.navigation.back.hint")))
            }

            if viewModel.currentStep < 3 {
                HaloButton(String(localized: "onboarding.navigation.next"), icon: "arrow.right") {
                    withAnimation(reduceMotion ? nil : AuroraMotion.spring) {
                        viewModel.currentStep += 1
                    }
                }
                .accessibilityHint(Text(String(localized: "onboarding.navigation.next.hint")))
            } else {
                HaloButton(String(localized: "onboarding.navigation.enter_sanctum"), icon: "sparkles") {
                    Task {
                        await viewModel.completeOnboarding(authService: authService)
                    }
                }
                .disabled(!viewModel.canComplete)
                .accessibilityHint(Text(String(localized: "onboarding.navigation.start.hint")))
            }
        }
    }
}

// MARK: - Birth Date Step
struct BirthDateStep: View {
    @Binding var selectedDate: Date

    var body: some View {
        VStack(spacing: MysticSpacing.lg) {
            Spacer()

            VStack(spacing: MysticSpacing.md) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 48))
                    .foregroundStyle(MysticGradients.goldShimmer)
                    .shadow(color: MysticColors.mysticGold.opacity(0.4), radius: 10)

                Text("onboarding.birth_date.title")
                    .font(MysticFonts.heading(24))
                    .foregroundColor(MysticColors.textPrimary)

                Text("onboarding.birth_date.subtitle")
                    .font(MysticFonts.body(15))
                    .foregroundColor(MysticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MysticSpacing.lg)
            }

            MysticCard(glowColor: MysticColors.mysticGold) {
                DatePicker(
                    String(localized: "onboarding.birth_date.label"),
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .accessibilityLabel(Text(String(localized: "onboarding.birth_date.label")))
            }
            .padding(.horizontal, MysticSpacing.lg)

            let sign = selectedDate.zodiacSign
            HStack(spacing: MysticSpacing.sm) {
                ZodiacSymbol(sign, size: 24, color: sign.elementColor)
                Text(String(format: String(localized: "onboarding.birth_date.sun_sign_format"), sign.localizedDisplayName))
                    .font(MysticFonts.body(16))
                    .foregroundColor(sign.elementColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, MysticSpacing.sm)
            .padding(.horizontal, MysticSpacing.md)
            .background(sign.elementColor.opacity(0.1))
            .clipShape(Capsule())

            Spacer()
        }
    }
}

// MARK: - Birth Time Step
struct BirthTimeStep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selectedTime: Date
    @Binding var isTimeKnown: Bool

    var body: some View {
        VStack(spacing: MysticSpacing.lg) {
            Spacer()

            VStack(spacing: MysticSpacing.md) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(MysticGradients.lavenderGlow)
                    .shadow(color: MysticColors.neonLavender.opacity(0.4), radius: 10)

                Text("onboarding.birth_time.title")
                    .font(MysticFonts.heading(24))
                    .foregroundColor(MysticColors.textPrimary)

                Text("onboarding.birth_time.subtitle")
                    .font(MysticFonts.body(15))
                    .foregroundColor(MysticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MysticSpacing.lg)
            }

            if isTimeKnown {
                MysticCard(glowColor: MysticColors.neonLavender) {
                    DatePicker(
                        String(localized: "onboarding.birth_time.label"),
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .accessibilityLabel(Text(String(localized: "onboarding.birth_time.label")))
                }
                .padding(.horizontal, MysticSpacing.lg)
                .transition(reduceMotion ? .identity : .opacity.combined(with: .scale))
            }

            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
                    isTimeKnown.toggle()
                }
            } label: {
                HStack(spacing: MysticSpacing.sm) {
                    Image(systemName: isTimeKnown ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isTimeKnown ? MysticColors.auroraGreen : MysticColors.textMuted)
                    Text(isTimeKnown ? String(localized: "onboarding.birth_time.known") : String(localized: "onboarding.birth_time.unknown"))
                        .font(MysticFonts.body(15))
                        .foregroundColor(MysticColors.textSecondary)
                }
                .padding(.vertical, MysticSpacing.sm)
                .padding(.horizontal, MysticSpacing.md)
                .background(MysticColors.inputBackground)
                .clipShape(Capsule())
            }
            .frame(minHeight: 44)
            .accessibilityHint(Text(String(localized: "onboarding.birth_time.toggle.hint")))

            if !isTimeKnown {
                Text("onboarding.birth_time.unknown_note")
                    .font(MysticFonts.caption(13))
                    .foregroundColor(MysticColors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MysticSpacing.xl)
            }

            Spacer()
        }
    }
}

// MARK: - Birth Location Step
struct BirthLocationStep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: MysticSpacing.lg) {
            Spacer()

            VStack(spacing: MysticSpacing.md) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 48))
                    .foregroundStyle(MysticGradients.auroraShift)
                    .shadow(color: MysticColors.auroraGreen.opacity(0.4), radius: 10)

                Text("onboarding.birth_location.title")
                    .font(MysticFonts.heading(24))
                    .foregroundColor(MysticColors.textPrimary)

                Text("onboarding.birth_location.subtitle")
                    .font(MysticFonts.body(15))
                    .foregroundColor(MysticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MysticSpacing.lg)
            }

            VStack(spacing: MysticSpacing.sm) {
                MysticTextField(
                    String(localized: "onboarding.birth_location.search_placeholder"),
                    text: $viewModel.locationQuery,
                    icon: "magnifyingglass"
                )
                .padding(.horizontal, MysticSpacing.lg)
                .onChange(of: viewModel.locationQuery) { _, newValue in
                    viewModel.searchLocation(query: newValue)
                }

                if !viewModel.searchResults.isEmpty {
                    MysticCard {
                        VStack(spacing: 0) {
                            ForEach(viewModel.searchResults, id: \.self) { result in
                                Button {
                                    viewModel.selectLocation(result)
                                } label: {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(MysticColors.auroraGreen)
                                        Text(result.title)
                                            .font(MysticFonts.body(14))
                                            .foregroundColor(MysticColors.textPrimary)
                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle)
                                                .font(MysticFonts.caption(12))
                                                .foregroundColor(MysticColors.textMuted)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, MysticSpacing.sm)
                                    .padding(.horizontal, MysticSpacing.sm)
                                    .frame(minHeight: 44)
                                }
                                .buttonStyle(.plain)

                                if result != viewModel.searchResults.last {
                                    Divider()
                                        .background(MysticColors.cardBorder)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MysticSpacing.lg)
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .top)))
                }
            }

            if let selected = viewModel.selectedLocationName {
                HStack(spacing: MysticSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(MysticColors.auroraGreen)
                    Text(selected)
                        .font(MysticFonts.body(15))
                        .foregroundColor(MysticColors.auroraGreen)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .padding(.vertical, MysticSpacing.sm)
                .padding(.horizontal, MysticSpacing.md)
                .background(MysticColors.auroraGreen.opacity(0.1))
                .clipShape(Capsule())
                .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
            }

            if viewModel.isResolvingLocation {
                HStack(spacing: MysticSpacing.sm) {
                    ProgressView()
                        .tint(MysticColors.neonLavender)
                    Text("onboarding.birth_location.resolving")
                        .font(MysticFonts.caption(13))
                        .foregroundColor(MysticColors.textMuted)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Onboarding ViewModel
@Observable
class OnboardingViewModel: NSObject, MKLocalSearchCompleterDelegate {
    enum OnboardingSubmissionState: Equatable {
        case idle
        case resolvingLocation
        case submitting
        case failed(String)
        case succeeded
    }

    private struct OnboardingDraft: Codable {
        var currentStep: Int
        var birthDate: Date
        var birthTime: Date
        var isTimeKnown: Bool
        var locationQuery: String
        var selectedLocationName: String?
        var selectedLatitude: Double?
        var selectedLongitude: Double?
        var selectedTimezone: String
        var guidanceIntentRawValue: String
    }

    private static let draftKey = "onboarding_draft_v1"

    var currentStep: Int = 0
    var birthDate: Date = Calendar.current.date(from: DateComponents(year: 1995, month: 6, day: 15)) ?? Date()
    var birthTime: Date = Date()
    var isTimeKnown: Bool = true
    var locationQuery: String = ""
    var searchResults: [MKLocalSearchCompletion] = []
    var selectedLocationName: String?
    var selectedLatitude: Double?
    var selectedLongitude: Double?
    var selectedTimezone: String = TimeZone.current.identifier
    var guidanceIntent: GuidanceIntent = .clarity
    var submissionState: OnboardingSubmissionState = .idle

    var isSubmitting: Bool {
        if case .submitting = submissionState { return true }
        return false
    }

    var isResolvingLocation: Bool {
        if case .resolvingLocation = submissionState { return true }
        return false
    }

    var canComplete: Bool {
        selectedLocationName != nil
            && selectedLatitude != nil
            && selectedLongitude != nil
            && !isResolvingLocation
            && !isSubmitting
    }

    private let searchCompleter = MKLocalSearchCompleter()
    private let logger = Logger(subsystem: "rk.horoscope", category: "Onboarding")

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
        loadDraftIfAvailable()
    }

    func persistDraft() {
        let draft = OnboardingDraft(
            currentStep: currentStep,
            birthDate: birthDate,
            birthTime: birthTime,
            isTimeKnown: isTimeKnown,
            locationQuery: locationQuery,
            selectedLocationName: selectedLocationName,
            selectedLatitude: selectedLatitude,
            selectedLongitude: selectedLongitude,
            selectedTimezone: selectedTimezone,
            guidanceIntentRawValue: guidanceIntent.rawValue
        )

        if let encoded = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(encoded, forKey: Self.draftKey)
        }
    }

    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: Self.draftKey)
    }

    func searchLocation(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }

        if case .failed = submissionState {
            submissionState = .idle
        }
        searchCompleter.queryFragment = query
    }

    func selectLocation(_ completion: MKLocalSearchCompletion) {
        selectedLocationName = "\(completion.title), \(completion.subtitle)"
        locationQuery = completion.title
        searchResults = []
        selectedLatitude = nil
        selectedLongitude = nil
        submissionState = .resolvingLocation

        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        Task {
            do {
                let response = try await search.start()
                if let item = response.mapItems.first {
                    let coord = item.placemark.coordinate
                    selectedLatitude = coord.latitude
                    selectedLongitude = coord.longitude
                    if let tz = item.placemark.timeZone {
                        selectedTimezone = tz.identifier
                    }
                    submissionState = .idle
                    persistDraft()
                } else {
                    submissionState = .failed(String(localized: "onboarding.birth_location.resolve_failed"))
                }
            } catch {
                submissionState = .failed(String(localized: "onboarding.birth_location.resolve_failed"))
                logger.error("Geocoding error: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func completeOnboarding(authService: AuthService) async {
        guard canComplete,
              let selectedLocationName,
              let selectedLatitude,
              let selectedLongitude else {
            submissionState = .failed(String(localized: "onboarding.birth_location.select_required"))
            return
        }

        submissionState = .submitting

        let birthData = BirthData(
            birthDate: birthDate,
            birthTime: isTimeKnown ? birthTime : nil,
            birthPlace: selectedLocationName,
            latitude: selectedLatitude,
            longitude: selectedLongitude,
            timeZoneIdentifier: selectedTimezone
        )

        do {
            try await authService.updateBirthData(birthData)
            await MainActor.run {
                authService.updateExperiencePreferences(
                    guidanceIntent: guidanceIntent,
                    preferredSessionTone: .softSpiritual
                )
            }
            try await authService.completeOnboarding()
            submissionState = .succeeded
            clearDraft()
        } catch {
            submissionState = .failed(error.localizedDescription)
        }
    }

    private func loadDraftIfAvailable() {
        guard let data = UserDefaults.standard.data(forKey: Self.draftKey),
              let draft = try? JSONDecoder().decode(OnboardingDraft.self, from: data) else {
            return
        }

        currentStep = min(max(draft.currentStep, 0), 3)
        birthDate = draft.birthDate
        birthTime = draft.birthTime
        isTimeKnown = draft.isTimeKnown
        locationQuery = draft.locationQuery
        selectedLocationName = draft.selectedLocationName
        selectedLatitude = draft.selectedLatitude
        selectedLongitude = draft.selectedLongitude
        selectedTimezone = draft.selectedTimezone
        guidanceIntent = GuidanceIntent(rawValue: draft.guidanceIntentRawValue) ?? .clarity
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = Array(completer.results.prefix(5))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        submissionState = .failed(String(localized: "onboarding.birth_location.resolve_failed"))
        logger.error("Location search completer error: \(error.localizedDescription, privacy: .public)")
    }
}

struct IntentSelectionStep: View {
    @Binding var selectedIntent: GuidanceIntent

    var body: some View {
        VStack(spacing: AuroraSpacing.lg) {
            Spacer()

            VStack(spacing: AuroraSpacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(AuroraGradients.primaryCTA)
                    .shadow(color: AuroraColors.auroraMint.opacity(0.35), radius: 12)

                Text("onboarding.intent.title")
                    .font(AuroraTypography.title(28))
                    .foregroundColor(AuroraColors.textPrimary)

                Text("onboarding.intent.subtitle")
                    .font(AuroraTypography.body(15))
                    .foregroundColor(AuroraColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AuroraSpacing.lg)
            }

            VStack(spacing: AuroraSpacing.sm) {
                ForEach(GuidanceIntent.allCases) { intent in
                    Button {
                        selectedIntent = intent
                    } label: {
                        LumenCard(accent: selectedIntent == intent ? AuroraColors.auroraMint : AuroraColors.auroraViolet) {
                            HStack(spacing: AuroraSpacing.md) {
                                Image(systemName: intent.iconName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(selectedIntent == intent ? AuroraColors.auroraMint : AuroraColors.textSecondary)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(intent.title)
                                        .font(AuroraTypography.bodyStrong(15))
                                        .foregroundColor(AuroraColors.textPrimary)
                                    Text(intent.subtitle)
                                        .font(AuroraTypography.body(13))
                                        .foregroundColor(AuroraColors.textSecondary)
                                }

                                Spacer()

                                if selectedIntent == intent {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AuroraColors.auroraMint)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AuroraSpacing.lg)

            LumenCard(accent: AuroraColors.auroraMint) {
                VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                    Text("onboarding.intent.preview_title")
                        .font(AuroraTypography.section(17))
                        .foregroundColor(AuroraColors.textPrimary)

                    Text(previewText(for: selectedIntent))
                        .font(AuroraTypography.body(14))
                        .foregroundColor(AuroraColors.textSecondary)
                        .lineSpacing(4)

                    HStack(spacing: AuroraSpacing.sm) {
                        PrismChip(String(localized: "onboarding.intent.preview_chip"), icon: "sparkles", accent: AuroraColors.auroraMint, isSelected: true)
                        PrismChip(selectedIntent.title, icon: selectedIntent.iconName, accent: AuroraColors.auroraViolet, isSelected: false)
                    }
                }
            }
            .padding(.horizontal, AuroraSpacing.lg)

            Spacer()
        }
    }

    private func previewText(for intent: GuidanceIntent) -> String {
        switch intent {
        case .clarity:
            return String(localized: "onboarding.intent.preview.clarity")
        case .love:
            return String(localized: "onboarding.intent.preview.love")
        case .career:
            return String(localized: "onboarding.intent.preview.career")
        case .healing:
            return String(localized: "onboarding.intent.preview.healing")
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AuthService())
}
