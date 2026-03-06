import SwiftUI
import Observation

struct TarotCard: Identifiable {
    let id: String
    let symbol: String
    let nameKey: String
    let uprightMeaningKey: String
    let reversedMeaningKey: String

    var name: String {
        NSLocalizedString(nameKey, comment: "")
    }

    var uprightMeaning: String {
        NSLocalizedString(uprightMeaningKey, comment: "")
    }

    var reversedMeaning: String {
        NSLocalizedString(reversedMeaningKey, comment: "")
    }
}

struct TarotReading {
    let card: TarotCard
    let isReversed: Bool
    let createdAt: Date

    var title: String {
        if isReversed {
            return String(
                format: String(localized: "tarot.card.reversed_format"),
                card.name
            )
        }
        return card.name
    }

    var interpretation: String {
        isReversed ? card.reversedMeaning : card.uprightMeaning
    }
}

@Observable
final class TarotService {
    static let shared = TarotService()

    private(set) var lastReading: TarotReading?

    private let cards: [TarotCard] = [
        TarotCard(
            id: "fool",
            symbol: "🃏",
            nameKey: "tarot.card.fool.name",
            uprightMeaningKey: "tarot.card.fool.upright",
            reversedMeaningKey: "tarot.card.fool.reversed"
        ),
        TarotCard(
            id: "magician",
            symbol: "🔮",
            nameKey: "tarot.card.magician.name",
            uprightMeaningKey: "tarot.card.magician.upright",
            reversedMeaningKey: "tarot.card.magician.reversed"
        ),
        TarotCard(
            id: "high_priestess",
            symbol: "🌙",
            nameKey: "tarot.card.high_priestess.name",
            uprightMeaningKey: "tarot.card.high_priestess.upright",
            reversedMeaningKey: "tarot.card.high_priestess.reversed"
        ),
        TarotCard(
            id: "empress",
            symbol: "🌸",
            nameKey: "tarot.card.empress.name",
            uprightMeaningKey: "tarot.card.empress.upright",
            reversedMeaningKey: "tarot.card.empress.reversed"
        ),
        TarotCard(
            id: "sun",
            symbol: "☀️",
            nameKey: "tarot.card.sun.name",
            uprightMeaningKey: "tarot.card.sun.upright",
            reversedMeaningKey: "tarot.card.sun.reversed"
        ),
        TarotCard(
            id: "star",
            symbol: "⭐️",
            nameKey: "tarot.card.star.name",
            uprightMeaningKey: "tarot.card.star.upright",
            reversedMeaningKey: "tarot.card.star.reversed"
        ),
        TarotCard(
            id: "world",
            symbol: "🌍",
            nameKey: "tarot.card.world.name",
            uprightMeaningKey: "tarot.card.world.upright",
            reversedMeaningKey: "tarot.card.world.reversed"
        )
    ]

    private init() {}

    func drawCard() {
        guard let card = cards.randomElement() else { return }
        let reversed = Bool.random() && Bool.random()
        lastReading = TarotReading(card: card, isReversed: reversed, createdAt: Date())
    }
}

struct TarotView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tarotService = TarotService.shared

    let showsCloseButton: Bool

    init(showsCloseButton: Bool = true) {
        self.showsCloseButton = showsCloseButton
    }

    var body: some View {
        AuroraScreen(
            backdropStyle: .oracleMist,
            eyebrow: String(localized: "tarot.screen.eyebrow"),
            title: String(localized: "tarot.screen.title"),
            subtitle: String(localized: "tarot.screen.subtitle")
        ) {
            if showsCloseButton {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AuroraColors.textPrimary)
                }
                .buttonStyle(.plain)
            }
        } content: {
            ritualHero

            if let reading = tarotService.lastReading {
                readingCard(reading)
                followUpCard(reading)
            } else {
                emptySignalCard
            }
        }
    }

    private var ritualHero: some View {
        LumenCard(accent: AuroraColors.auroraRose) {
            VStack(alignment: .leading, spacing: AuroraSpacing.md) {
                HStack(alignment: .top, spacing: AuroraSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(AuroraColors.auroraRose.opacity(0.16))
                            .frame(width: 76, height: 76)
                        AuroraGlyph(kind: .tarot, color: AuroraColors.auroraRose, lineWidth: 2)
                            .frame(width: 34, height: 34)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("tarot.hero.eyebrow")
                            .font(AuroraTypography.mono(11))
                            .foregroundColor(AuroraColors.textMuted)
                        Text("tarot.hero.title")
                            .font(AuroraTypography.section(20))
                            .foregroundColor(AuroraColors.textPrimary)
                        Text("tarot.hero.subtitle")
                            .font(AuroraTypography.body(14))
                            .foregroundColor(AuroraColors.textSecondary)
                    }
                }

                HStack(spacing: AuroraSpacing.sm) {
                    HaloButton(String(localized: "tarot.hero.draw"), icon: "sparkles.rectangle.stack.fill") {
                        tarotService.drawCard()
                    }
                    .accessibilityIdentifier("tarot.draw.cta")

                    HaloButton(String(localized: "tarot.hero.ask_oracle"), icon: "arrow.right", style: .ghost) {
                        AppNavigation.openChat(
                            context: .tarot,
                            prompt: "Prepare me for a tarot reading and tell me what energy I should notice."
                        )
                    }
                }
            }
        }
    }

    private func readingCard(_ reading: TarotReading) -> some View {
        LumenCard(accent: reading.isReversed ? AuroraColors.auroraRose : AuroraColors.auroraViolet) {
            VStack(alignment: .leading, spacing: AuroraSpacing.md) {
                HStack(alignment: .top) {
                    Text(reading.card.symbol)
                        .font(.system(size: 62))

                    Spacer()

                    Text(reading.createdAt.formatted(as: "d MMMM HH:mm"))
                        .font(AuroraTypography.mono(11))
                        .foregroundColor(AuroraColors.textMuted)
                }

                Text(reading.title)
                    .font(AuroraTypography.title(30))
                    .foregroundColor(AuroraColors.textPrimary)

                Text(reading.interpretation)
                    .font(AuroraTypography.body(15))
                    .foregroundColor(AuroraColors.textSecondary)
                    .lineSpacing(4)

                HStack(spacing: AuroraSpacing.sm) {
                    PrismChip(reading.isReversed ? String(localized: "tarot.state.reversed") : String(localized: "tarot.state.upright"), icon: "sparkles", accent: reading.isReversed ? AuroraColors.auroraRose : AuroraColors.auroraViolet, isSelected: true)
                    PrismChip(String(localized: "tarot.state.tonight"), icon: "moon.stars.fill", accent: AuroraColors.auroraMint, isSelected: false)
                }
            }
        }
    }

    private func followUpCard(_ reading: TarotReading) -> some View {
        LumenCard(accent: AuroraColors.auroraMint) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                Text("tarot.follow_up.title")
                    .font(AuroraTypography.section(18))
                    .foregroundColor(AuroraColors.textPrimary)

                Text("tarot.follow_up.subtitle")
                    .font(AuroraTypography.body(14))
                    .foregroundColor(AuroraColors.textSecondary)
                    .lineSpacing(4)

                HStack(spacing: AuroraSpacing.sm) {
                    HaloButton(String(localized: "tarot.follow_up.ask_oracle"), icon: "sparkles") {
                        AppNavigation.openChat(
                            context: .tarot,
                            prompt: "I pulled \(reading.title). Connect this tarot message to my current astrology and tell me what action to take."
                        )
                    }

                    HaloButton(String(localized: "tarot.follow_up.draw_again"), icon: "arrow.clockwise", style: .ghost) {
                        tarotService.drawCard()
                    }
                }
            }
        }
    }

    private var emptySignalCard: some View {
        LumenCard(accent: AuroraColors.auroraViolet) {
            VStack(alignment: .leading, spacing: AuroraSpacing.sm) {
                Text("tarot.empty.title")
                    .font(AuroraTypography.section(18))
                    .foregroundColor(AuroraColors.textPrimary)

                Text("tarot.empty.subtitle")
                    .font(AuroraTypography.body(14))
                    .foregroundColor(AuroraColors.textSecondary)
                    .lineSpacing(4)
            }
        }
    }
}

#Preview {
    TarotView(showsCloseButton: false)
}
