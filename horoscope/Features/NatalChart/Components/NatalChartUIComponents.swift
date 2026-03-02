import SwiftUI

// MARK: - Big 3 Card Section
struct NatalBig3Section: View {
    let chart: ChartData

    var body: some View {
        let sun = chart.planetPositions.first(where: { $0.planet == .sun })
        let moon = chart.planetPositions.first(where: { $0.planet == .moon })
        let ascSign = chart.houseCusps.first(where: { $0.houseNumber == 1 })?.sign
        let ascDeg = chart.houseCusps.first(where: { $0.houseNumber == 1 })?.degree

        return HStack(spacing: MysticSpacing.sm) {
            Big3Card(
                label: String(localized: "natal.big3.sun"), symbol: "☉",
                sign: sun?.sign, degree: sun?.formattedDegree,
                color: MysticColors.mysticGold
            )
            Big3Card(
                label: String(localized: "natal.big3.moon"), symbol: "☽",
                sign: moon?.sign, degree: moon?.formattedDegree,
                color: MysticColors.celestialPink
            )
            Big3Card(
                label: String(localized: "natal.big3.ascendant"), symbol: "AC",
                sign: ascSign,
                degree: ascDeg.map { String(format: "%.1f°", $0.truncatingRemainder(dividingBy: 30)) },
                color: MysticColors.neonLavender
            )
        }
    }
}

// MARK: - Tab Picker
struct NatalTabPicker: View {
    @Binding var selectedTab: NatalChartView.ChartTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(NatalChartView.ChartTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                } label: {
                    Text(tab.titleKey)
                        .font(MysticFonts.body(14))
                        .fontWeight(selectedTab == tab ? .semibold : .regular)
                        .foregroundColor(selectedTab == tab ? MysticColors.textPrimary : MysticColors.textMuted)
                        .padding(.vertical, MysticSpacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(selectedTab == tab ? MysticColors.neonLavender.opacity(0.15) : Color.clear)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(selectedTab == tab ? MysticColors.neonLavender : Color.clear)
                                .frame(height: 2)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .background(MysticColors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: MysticRadius.md))
    }
}

// MARK: - Tab Content View
struct NatalTabContentView: View {
    let selectedTab: NatalChartView.ChartTab
    let chart: ChartData
    @Binding var expandedPlanet: String?

    var body: some View {
        switch selectedTab {
        case .planets:
            VStack(spacing: MysticSpacing.sm) {
                ForEach(chart.planetPositions) { position in
                    PlanetDetailCard(
                        position: position,
                        isExpanded: expandedPlanet == position.id
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            expandedPlanet = expandedPlanet == position.id ? nil : position.id
                        }
                    }
                }
            }
        case .aspects:
            VStack(spacing: MysticSpacing.sm) {
                ForEach(chart.aspects) { aspect in
                    AspectCard(aspect: aspect)
                }
            }
        case .houses:
            VStack(spacing: MysticSpacing.sm) {
                ForEach(chart.houseCusps) { cusp in
                    HouseCard(
                        cusp: cusp,
                        planetsInHouse: chart.planetPositions.filter { $0.house == cusp.houseNumber }
                    )
                }
            }
        }
    }
}
