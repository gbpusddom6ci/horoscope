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
    @Environment(\.mainChromeMetrics) private var chromeMetrics
    @State private var tarotService = TarotService.shared

    var body: some View {
        MysticScreenScaffold(
            "tarot.title",
            starCount: 45,
            starMode: .modal
        ) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MysticSpacing.lg) {
                    Spacer().frame(height: 24)

                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(MysticGradients.goldShimmer)
                        .shadow(color: MysticColors.mysticGold.opacity(0.35), radius: 10)

                    GlowingText(String(localized: "tarot.title"), font: MysticFonts.title(30), color: MysticColors.mysticGold)

                    Text("tarot.subtitle")
                        .font(MysticFonts.body(15))
                        .foregroundColor(MysticColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MysticSpacing.xl)

                    MysticButton(String(localized: "tarot.draw"), icon: "suit.spade.fill", style: .primary) {
                        tarotService.drawCard()
                    }
                    .padding(.horizontal, MysticSpacing.md)

                    if let reading = tarotService.lastReading {
                        MysticCard(glowColor: MysticColors.neonLavender) {
                            VStack(spacing: MysticSpacing.md) {
                                Text(reading.card.symbol)
                                    .font(.system(size: 60))

                                Text(reading.title)
                                    .font(MysticFonts.heading(22))
                                    .foregroundColor(MysticColors.textPrimary)

                                Text(reading.interpretation)
                                    .font(MysticFonts.body(15))
                                    .foregroundColor(MysticColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)

                                Text(reading.createdAt.formatted(as: "d MMMM HH:mm"))
                                    .font(MysticFonts.caption(12))
                                    .foregroundColor(MysticColors.textMuted)
                            }
                        }
                        .padding(.horizontal, MysticSpacing.md)
                    }

                    Color.clear.frame(height: max(72, chromeMetrics.contentBottomReservedSpace))
                }
            }
        }
    }
}

#Preview {
    TarotView()
}
