import SwiftUI
import MapKit

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @State private var showEditBirthData = false

    private var user: AppUser? { authService.currentUser }
    private var birthData: BirthData? { user?.birthData }

    var body: some View {
        ZStack {
            StarField(starCount: 30)

            VStack(spacing: 0) {
                Text("Profil")
                    .font(MysticFonts.heading(18))
                    .foregroundColor(MysticColors.textPrimary)
                    .padding(.top, 10)
                    .padding(.bottom, 10)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: MysticSpacing.lg) {
                        profileHeader.fadeInOnAppear(delay: 0)
                        zodiacInfoCard.fadeInOnAppear(delay: 0.1)
                        menuSection.fadeInOnAppear(delay: 0.2)
                        dangerZone.fadeInOnAppear(delay: 0.3)
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

                Text(user?.displayName ?? "Kullanıcı")
                    .font(MysticFonts.heading(22))
                    .foregroundColor(MysticColors.textPrimary)

                if let email = user?.email {
                    Text(email)
                        .font(MysticFonts.caption(14))
                        .foregroundColor(MysticColors.textMuted)
                }

                // Premium badge
                HStack(spacing: MysticSpacing.xs) {
                    Image(systemName: user?.isPremium == true ? "crown.fill" : "crown")
                        .font(.system(size: 14))
                    Text(user?.isPremium == true ? "Premium Üye" : "Ücretsiz Plan")
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

    // MARK: - Zodiac Info
    private var zodiacInfoCard: some View {
        Group {
            if let bd = birthData {
                MysticCard(glowColor: bd.sunSign.elementColor) {
                    VStack(alignment: .leading, spacing: MysticSpacing.md) {
                        HStack {
                            Text("Doğum Bilgileri")
                                .font(MysticFonts.heading(16))
                                .foregroundColor(MysticColors.textPrimary)
                            Spacer()
                            Button {
                                showEditBirthData = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 13))
                                    Text("Düzenle")
                                        .font(MysticFonts.caption(13))
                                }
                                .foregroundColor(MysticColors.neonLavender)
                            }
                        }

                        infoRow(icon: "calendar", label: "Doğum Tarihi", value: bd.birthDate.formatted(as: "d MMMM yyyy"))
                        if bd.isBirthTimeKnown {
                            infoRow(icon: "clock", label: "Doğum Saati", value: bd.birthTime?.formatted(as: "HH:mm") ?? "-")
                        }
                        infoRow(icon: "mappin", label: "Doğum Yeri", value: bd.birthPlace)
                        infoRow(icon: "sun.max", label: "Güneş Burcu", value: "\(bd.sunSign.symbol) \(bd.sunSign.rawValue)")
                    }
                }
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

    // MARK: - Menu
    private var menuSection: some View {
        VStack(spacing: MysticSpacing.sm) {
            menuItem(icon: "crown.fill", title: "Premium'a Yükselt", color: MysticColors.mysticGold) {}
            menuItem(icon: "bell.fill", title: "Bildirim Tercihleri", color: MysticColors.neonLavender) {}
            menuItem(icon: "globe", title: "Dil", color: MysticColors.auroraGreen) {}
            menuItem(icon: "questionmark.circle", title: "Yardım & Destek", color: MysticColors.textSecondary) {}
            menuItem(icon: "doc.text", title: "Gizlilik Politikası", color: MysticColors.textSecondary) {}
        }
    }

    private func menuItem(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MysticCard {
                HStack(spacing: MysticSpacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                        .frame(width: 28)
                    Text(title)
                        .font(MysticFonts.body(15))
                        .foregroundColor(MysticColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(MysticColors.textMuted)
                }
            }
        }.buttonStyle(.plain)
    }

    // MARK: - Danger Zone
    private var dangerZone: some View {
        VStack(spacing: MysticSpacing.sm) {
            MysticButton("Çıkış Yap", icon: "rectangle.portrait.and.arrow.right", style: .danger) {
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

    var body: some View {
        NavigationStack {
            ZStack {
                MysticColors.voidBlack.ignoresSafeArea()
                StarField(starCount: 30)

                ScrollView {
                    VStack(spacing: MysticSpacing.lg) {
                        // Birth Date
                        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                            Text("Doğum Tarihi")
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
                                Text("Doğum Saati")
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
                            Text("Doğum Yeri")
                                .font(MysticFonts.heading(16))
                                .foregroundColor(MysticColors.textPrimary)

                            TextField("Şehir arayın...", text: $locationQuery)
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
                        MysticButton("Kaydet", icon: "checkmark.circle.fill", style: .primary, isLoading: isSaving) {
                            saveBirthData()
                        }
                        .disabled(birthPlace.isEmpty)
                    }
                    .padding(MysticSpacing.md)
                }
            }
            .navigationTitle("Doğum Bilgilerini Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
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
        isSaving = true
        let newBirthData = BirthData(
            birthDate: birthDate,
            birthTime: birthTimeKnown ? birthTime : nil,
            birthPlace: birthPlace,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZoneId
        )
        authService.updateBirthData(newBirthData)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - Location Search Delegate
class LocationSearchDelegate: NSObject, MKLocalSearchCompleterDelegate {
    var onResults: ([MKLocalSearchCompletion]) -> Void

    init(onResults: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.onResults = onResults
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onResults(completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search error: \(error)")
    }
}

#Preview { SettingsView().environment(AuthService()) }
