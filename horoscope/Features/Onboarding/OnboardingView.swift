import SwiftUI
import MapKit

// MARK: - Onboarding View
struct OnboardingView: View {
    @Environment(AuthService.self) private var authService
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            StarField(starCount: 80)

            VStack(spacing: 0) {
                // Progress Indicator
                progressBar
                    .padding(.top, MysticSpacing.md)

                // Step Content
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
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4), value: viewModel.currentStep)

                // Navigation Buttons
                navigationButtons
                    .padding(.horizontal, MysticSpacing.lg)
                    .padding(.bottom, MysticSpacing.xl)
            }
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: MysticSpacing.sm) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        index <= viewModel.currentStep
                            ? MysticColors.mysticGold
                            : MysticColors.textMuted.opacity(0.3)
                    )
                    .frame(height: 4)
                    .animation(.spring(response: 0.3), value: viewModel.currentStep)
            }
        }
        .padding(.horizontal, MysticSpacing.lg)
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: MysticSpacing.md) {
            if viewModel.currentStep > 0 {
                MysticButton("Geri", icon: "chevron.left", style: .ghost) {
                    withAnimation {
                        viewModel.currentStep -= 1
                    }
                }
                .frame(maxWidth: 120)
            }

            if viewModel.currentStep < 2 {
                MysticButton("Devam", icon: "arrow.right", style: .primary) {
                    withAnimation {
                        viewModel.currentStep += 1
                    }
                }
            } else {
                MysticButton(
                    "Keşfetmeye Başla ✨",
                    style: .primary,
                    isLoading: viewModel.isSubmitting
                ) {
                    viewModel.completeOnboarding(authService: authService)
                }
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

                Text("Doğum Tarihiniz")
                    .font(MysticFonts.heading(24))
                    .foregroundColor(MysticColors.textPrimary)

                Text("Natal haritanızı hesaplamak için doğum tarihinize ihtiyacımız var")
                    .font(MysticFonts.body(15))
                    .foregroundColor(MysticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MysticSpacing.lg)
            }

            MysticCard(glowColor: MysticColors.mysticGold) {
                DatePicker(
                    "Doğum Tarihi",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "tr_TR"))
                .colorScheme(.dark)
            }
            .padding(.horizontal, MysticSpacing.lg)

            // Show selected zodiac
            let sign = selectedDate.zodiacSign
            HStack(spacing: MysticSpacing.sm) {
                ZodiacSymbol(sign, size: 24, color: sign.elementColor)
                Text("Güneş Burcunuz: \(sign.rawValue)")
                    .font(MysticFonts.body(16))
                    .foregroundColor(sign.elementColor)
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

                Text("Doğum Saatiniz")
                    .font(MysticFonts.heading(24))
                    .foregroundColor(MysticColors.textPrimary)

                Text("Yükselen burcunuzu ve ev yerleşimlerinizi hesaplamak için doğum saatini bilmemiz gerekiyor")
                    .font(MysticFonts.body(15))
                    .foregroundColor(MysticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MysticSpacing.lg)
            }

            if isTimeKnown {
                MysticCard(glowColor: MysticColors.neonLavender) {
                    DatePicker(
                        "Doğum Saati",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                }
                .padding(.horizontal, MysticSpacing.lg)
                .transition(.opacity.combined(with: .scale))
            }

            // Toggle
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isTimeKnown.toggle()
                }
            } label: {
                HStack(spacing: MysticSpacing.sm) {
                    Image(systemName: isTimeKnown ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isTimeKnown ? MysticColors.auroraGreen : MysticColors.textMuted)
                    Text(isTimeKnown ? "Doğum saatimi biliyorum" : "Doğum saatimi bilmiyorum")
                        .font(MysticFonts.body(15))
                        .foregroundColor(MysticColors.textSecondary)
                }
                .padding(.vertical, MysticSpacing.sm)
                .padding(.horizontal, MysticSpacing.md)
                .background(MysticColors.inputBackground)
                .clipShape(Capsule())
            }

            if !isTimeKnown {
                Text("💡 Doğum saatinizi bilmiyorsanız, yükselen burcunuz ve ev yerleşimleriniz hesaplanamaz. Ancak gezegen burçları yine de gösterilecektir.")
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
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: MysticSpacing.lg) {
            Spacer()

            VStack(spacing: MysticSpacing.md) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 48))
                    .foregroundStyle(MysticGradients.auroraShift)
                    .shadow(color: MysticColors.auroraGreen.opacity(0.4), radius: 10)

                Text("Doğum Yeriniz")
                    .font(MysticFonts.heading(24))
                    .foregroundColor(MysticColors.textPrimary)

                Text("Ev yerleşimlerinin doğru hesaplanması için doğum yerinizi belirtin")
                    .font(MysticFonts.body(15))
                    .foregroundColor(MysticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MysticSpacing.lg)
            }

            VStack(spacing: MysticSpacing.sm) {
                MysticTextField(
                    "Şehir ara...",
                    text: $viewModel.locationQuery,
                    icon: "magnifyingglass"
                )
                .padding(.horizontal, MysticSpacing.lg)
                .onChange(of: viewModel.locationQuery) { _, newValue in
                    viewModel.searchLocation(query: newValue)
                }

                // Search Results
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
                                }

                                if result != viewModel.searchResults.last {
                                    Divider()
                                        .background(MysticColors.cardBorder)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MysticSpacing.lg)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Selected location
            if let selected = viewModel.selectedLocationName {
                HStack(spacing: MysticSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(MysticColors.auroraGreen)
                    Text(selected)
                        .font(MysticFonts.body(15))
                        .foregroundColor(MysticColors.auroraGreen)
                }
                .padding(.vertical, MysticSpacing.sm)
                .padding(.horizontal, MysticSpacing.md)
                .background(MysticColors.auroraGreen.opacity(0.1))
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()
        }
    }
}

// MARK: - Onboarding ViewModel
@Observable
class OnboardingViewModel: NSObject, MKLocalSearchCompleterDelegate {
    var currentStep: Int = 0
    var birthDate: Date = Calendar.current.date(
        from: DateComponents(year: 1995, month: 6, day: 15)
    )!
    var birthTime: Date = Date()
    var isTimeKnown: Bool = true
    var locationQuery: String = ""
    var searchResults: [MKLocalSearchCompletion] = []
    var selectedLocationName: String?
    var selectedLatitude: Double = 0
    var selectedLongitude: Double = 0
    var selectedTimezone: String = TimeZone.current.identifier
    var isSubmitting: Bool = false

    private let searchCompleter = MKLocalSearchCompleter()

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }

    func searchLocation(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        searchCompleter.queryFragment = query
    }

    func selectLocation(_ completion: MKLocalSearchCompletion) {
        selectedLocationName = "\(completion.title), \(completion.subtitle)"
        locationQuery = completion.title
        searchResults = []

        // Geocode to get coordinates
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
                }
            } catch {
                print("Geocoding error: \(error)")
            }
        }
    }

    func completeOnboarding(authService: AuthService) {
        guard selectedLocationName != nil else { return }

        isSubmitting = true

        let birthData = BirthData(
            birthDate: birthDate,
            birthTime: isTimeKnown ? birthTime : nil,
            birthPlace: selectedLocationName ?? locationQuery,
            latitude: selectedLatitude,
            longitude: selectedLongitude,
            timeZoneIdentifier: selectedTimezone
        )

        authService.completeOnboarding(with: birthData)
        isSubmitting = false
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = Array(completer.results.prefix(5))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error)")
    }
}

#Preview {
    OnboardingView()
        .environment(AuthService())
}
