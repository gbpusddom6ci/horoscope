import SwiftUI

struct HomeView: View {
    @Environment(AuthService.self) private var authService
    @State private var showGreeting = false
    @State private var currentTransits: [TransitEvent] = []
    @State private var natalChart: ChartData?

    private var birthData: BirthData? {
        authService.currentUser?.birthData
    }

    private var sunSign: ZodiacSign? {
        birthData?.sunSign
    }

    var body: some View {
        ZStack {
            StarField(starCount: 60)

            ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: MysticSpacing.lg) {
                        // Greeting Header
                        greetingSection
                            .fadeInOnAppear(delay: 0)

                        // Daily Energy Card
                        dailyEnergyCard
                            .fadeInOnAppear(delay: 0.1)

                        // Quick Stats
                        if let birthData = birthData, let chart = natalChart {
                            quickStatsSection(birthData: birthData, chart: chart)
                                .fadeInOnAppear(delay: 0.2)
                        }

                        // Active Transits
                        if !currentTransits.isEmpty {
                            transitSection
                                .fadeInOnAppear(delay: 0.3)
                        }

                // Feature Cards
                featureCardsSection
                    .fadeInOnAppear(delay: 0.4)

                // Bottom spacing for tab bar
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, MysticSpacing.md)
            .padding(.top, MysticSpacing.md)
        }
        }
        .onAppear {
            loadData()
        }
    }

    // MARK: - Greeting Section
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: MysticSpacing.xs) {
                    Text(greetingText)
                        .font(MysticFonts.caption(14))
                        .foregroundColor(MysticColors.textSecondary)

                    HStack(spacing: MysticSpacing.sm) {
                        if let sign = sunSign {
                            ZodiacSymbol(sign, size: 28, color: sign.elementColor)
                        }
                        Text(authService.currentUser?.displayName ?? "Kaşif")
                            .font(MysticFonts.title(28))
                            .foregroundColor(MysticColors.textPrimary)
                    }
                }

                Spacer()

                // Profile avatar
                ZStack {
                    Circle()
                        .fill(MysticColors.neonLavender.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Circle()
                        .stroke(MysticColors.neonLavender.opacity(0.3), lineWidth: 1)
                        .frame(width: 48, height: 48)
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(MysticColors.neonLavender)
                }
            }
        }
    }

    // MARK: - Daily Energy Card
    private var dailyEnergyCard: some View {
        MysticCard(glowColor: MysticColors.mysticGold) {
            VStack(alignment: .leading, spacing: MysticSpacing.md) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(MysticColors.mysticGold)
                    Text("Günün Enerjisi")
                        .font(MysticFonts.heading(18))
                        .foregroundColor(MysticColors.textPrimary)
                    Spacer()
                    Text(Date().formatted(as: "d MMMM"))
                        .font(MysticFonts.caption(13))
                        .foregroundColor(MysticColors.textMuted)
                }

                if let sign = sunSign {
                    Text("\(sign.symbol) \(sign.rawValue) olarak bugün \(sign.element) enerjisi güçlü. İçsel gücünüzü kullanarak hedeflerinize odaklanabilirsiniz.")
                        .font(MysticFonts.mystic(15))
                        .foregroundColor(MysticColors.textSecondary)
                        .lineSpacing(4)
                } else {
                    Text("Yıldızlar sizin için harika şeyler hazırlıyor. Doğum bilgilerinizi girerek kişisel yorumunuzu alın.")
                        .font(MysticFonts.mystic(15))
                        .foregroundColor(MysticColors.textSecondary)
                        .lineSpacing(4)
                }

                // Energy bars
                HStack(spacing: MysticSpacing.md) {
                    EnergyBar(label: "Aşk", value: 0.7, color: MysticColors.celestialPink)
                    EnergyBar(label: "Kariyer", value: 0.85, color: MysticColors.mysticGold)
                    EnergyBar(label: "Sağlık", value: 0.6, color: MysticColors.auroraGreen)
                }
            }
        }
    }

    // MARK: - Quick Stats
    private func quickStatsSection(birthData: BirthData, chart: ChartData) -> some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            Text("Natal Haritanız")
                .font(MysticFonts.heading(18))
                .foregroundColor(MysticColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MysticSpacing.sm) {
                    // Sun sign
                    StatCard(
                        label: "Güneş",
                        value: birthData.sunSign.rawValue,
                        icon: "sun.max.fill",
                        color: MysticColors.mysticGold
                    )
                    .frame(width: 110)

                    // Moon sign (from chart)
                    if let moonPos = chart.planetPositions.first(where: { $0.planet == .moon }) {
                        StatCard(
                            label: "Ay",
                            value: moonPos.sign.rawValue,
                            icon: "moon.fill",
                            color: MysticColors.neonLavender
                        )
                        .frame(width: 110)
                    }

                    // Ascendant
                    if let firstHouse = chart.houseCusps.first {
                        StatCard(
                            label: "Yükselen",
                            value: firstHouse.sign.rawValue,
                            icon: "arrow.up.circle.fill",
                            color: MysticColors.auroraGreen
                        )
                        .frame(width: 110)
                    }

                    // Mercury
                    if let mercuryPos = chart.planetPositions.first(where: { $0.planet == .mercury }) {
                        StatCard(
                            label: "Merkür",
                            value: mercuryPos.sign.rawValue,
                            icon: "circle.fill",
                            color: MysticColors.celestialPink
                        )
                        .frame(width: 110)
                    }
                }
            }
        }
    }

    // MARK: - Transit Section
    private var transitSection: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            HStack {
                Text("Aktif Transitler")
                    .font(MysticFonts.heading(18))
                    .foregroundColor(MysticColors.textPrimary)
                Spacer()
                Text("\(currentTransits.count)")
                    .font(MysticFonts.caption(13))
                    .foregroundColor(MysticColors.mysticGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(MysticColors.mysticGold.opacity(0.15))
                    .clipShape(Capsule())
            }

            ForEach(currentTransits) { transit in
                TransitCard(transit: transit)
            }
        }
    }

    // MARK: - Feature Cards Section
    private var featureCardsSection: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            Text("Keşfet")
                .font(MysticFonts.heading(18))
                .foregroundColor(MysticColors.textPrimary)

            FeatureCard(
                icon: "bubble.left.and.bubble.right.fill",
                title: "AI Astroloji Sohbeti",
                subtitle: "Yapay zeka ile natal haritanızı derinlemesine keşfedin",
                color: MysticColors.auroraGreen
            ) {}

            FeatureCard(
                icon: "moon.zzz.fill",
                title: "Rüya Yorumu",
                subtitle: "Rüyalarınızın gizli mesajlarını çözün",
                color: MysticColors.celestialPink
            ) {}

            FeatureCard(
                icon: "hand.raised.fill",
                title: "El Falı",
                subtitle: "AI destekli avuç içi analizi",
                color: MysticColors.neonLavender
            ) {}

            FeatureCard(
                icon: "suit.diamond.fill",
                title: "Tarot",
                subtitle: "Günlük kart çekimi ve yorum",
                color: MysticColors.mysticGold
            ) {}
        }
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Günaydın ☀️"
        case 12..<18: return "İyi günler 🌤️"
        case 18..<22: return "İyi akşamlar 🌙"
        default: return "İyi geceler ✨"
        }
    }

    private func loadData() {
        guard let birthData = birthData else { return }

        Task {
            // Calculate natal chart (API-first, local fallback)
            natalChart = await AstrologyEngine.shared.calculateNatalChartAsync(birthData: birthData)

            // Get transits
            if let chart = natalChart {
                currentTransits = AstrologyEngine.shared.calculateCurrentTransits(natalChart: chart)
            }
        }
    }
}

// MARK: - Energy Bar
struct EnergyBar: View {
    let label: String
    let value: Double
    let color: Color
    @State private var animatedValue: Double = 0

    var body: some View {
        VStack(spacing: MysticSpacing.xs) {
            Text(label)
                .font(MysticFonts.caption(11))
                .foregroundColor(MysticColors.textMuted)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * animatedValue, height: 6)
                }
            }
            .frame(height: 6)

            Text("\(Int(value * 100))%")
                .font(MysticFonts.caption(10))
                .foregroundColor(color)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                animatedValue = value
            }
        }
    }
}

// MARK: - Transit Card
struct TransitCard: View {
    let transit: TransitEvent

    var body: some View {
        MysticCard(glowColor: transitColor) {
            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                HStack {
                    Text(transit.severity.emoji)
                    Text("\(transit.transitPlanet.symbol) \(transit.aspectType.symbol) \(transit.natalPlanet.symbol)")
                        .font(MysticFonts.heading(16))
                        .foregroundColor(MysticColors.textPrimary)
                    Spacer()
                    Text("\(transit.durationDays) gün")
                        .font(MysticFonts.caption(12))
                        .foregroundColor(MysticColors.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(MysticColors.inputBackground)
                        .clipShape(Capsule())
                }

                Text(transit.description)
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.textSecondary)
                    .lineSpacing(2)

                HStack {
                    Text("Tam tarih: \(transit.exactDate.formatted(as: "d MMM yyyy"))")
                        .font(MysticFonts.caption(12))
                        .foregroundColor(MysticColors.textMuted)
                    Spacer()
                    Text(transit.severity.rawValue)
                        .font(MysticFonts.caption(11))
                        .foregroundColor(transitColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(transitColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var transitColor: Color {
        switch transit.severity {
        case .low: return MysticColors.auroraGreen
        case .medium: return MysticColors.mysticGold
        case .high: return Color(hex: "ff9800")
        case .critical: return MysticColors.celestialPink
        }
    }
}

#Preview {
    let authService = AuthService()
    HomeView()
        .environment(authService)
}
