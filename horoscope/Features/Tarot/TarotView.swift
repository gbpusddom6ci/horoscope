import SwiftUI
import Observation

struct TarotCard: Identifiable {
    var id: String { name }
    let name: String
    let symbol: String
    let uprightMeaning: String
    let reversedMeaning: String
}

struct TarotReading {
    let card: TarotCard
    let isReversed: Bool
    let createdAt: Date

    var title: String {
        isReversed ? "\(card.name) (Ters)" : card.name
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
        TarotCard(name: "The Fool", symbol: "🃏", uprightMeaning: "Yeni başlangıçlar, cesaret ve spontane adımlar zamanı.", reversedMeaning: "Plansız riskler yerine daha temkinli ilerlemek gerekiyor."),
        TarotCard(name: "The Magician", symbol: "🔮", uprightMeaning: "Yeteneklerinizi odaklayınca güçlü sonuçlar alabilirsiniz.", reversedMeaning: "Dikkat dağınıklığı ve kararsızlık enerjinizi bölüyor."),
        TarotCard(name: "The High Priestess", symbol: "🌙", uprightMeaning: "Sezgileriniz çok güçlü; iç sesinizi dinleyin.", reversedMeaning: "Belirsizlik döneminde acele kararlar yanıltabilir."),
        TarotCard(name: "The Empress", symbol: "🌸", uprightMeaning: "Bereket, üretkenlik ve duygusal şefkat öne çıkıyor.", reversedMeaning: "Kendinizi ihmal etmeden sınırlarınızı koruyun."),
        TarotCard(name: "The Sun", symbol: "☀️", uprightMeaning: "Netlik, mutluluk ve görünür başarı dönemi.", reversedMeaning: "Enerji düşüklüğünde rutininizi toparlamak faydalı olur."),
        TarotCard(name: "The Star", symbol: "⭐️", uprightMeaning: "Umut tazeleniyor; doğru yoldasınız.", reversedMeaning: "Sabır ve inançla süreci tamamlamak gerekiyor."),
        TarotCard(name: "The World", symbol: "🌍", uprightMeaning: "Bir döngü kapanıyor, önemli bir tamamlanma geliyor.", reversedMeaning: "Tamamlanmamış işleri bitirmek yeni kapıları açacak.")
    ]

    private init() {}

    func drawCard() {
        guard let card = cards.randomElement() else { return }
        let reversed = Bool.random() && Bool.random()
        lastReading = TarotReading(card: card, isReversed: reversed, createdAt: Date())
    }
}

struct TarotView: View {
    @State private var tarotService = TarotService.shared

    var body: some View {
        ZStack {
            StarField(starCount: 45)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MysticSpacing.lg) {
                    Spacer().frame(height: 50)

                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(MysticGradients.goldShimmer)
                        .shadow(color: MysticColors.mysticGold.opacity(0.35), radius: 10)

                    GlowingText("Tarot", font: MysticFonts.title(30), color: MysticColors.mysticGold)

                    Text("Bugünün enerjisini görmek için bir kart çek.")
                        .font(MysticFonts.body(15))
                        .foregroundColor(MysticColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MysticSpacing.xl)

                    MysticButton("Kart Çek", icon: "suit.spade.fill", style: .primary) {
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

                    Color.clear.frame(height: 80)
                }
            }
        }
    }
}

#Preview {
    TarotView()
}
