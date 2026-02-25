import SwiftUI

struct PalmReadingView: View {
    @Environment(AuthService.self) private var authService
    @State private var showCamera = false
    @State private var isAnalyzing = false
    @State private var interpretation: String?

    var body: some View {
        ZStack {
            StarField(starCount: 40)

            VStack(spacing: 0) {
                Text("El Falı")
                    .font(MysticFonts.heading(18))
                    .foregroundColor(MysticColors.textPrimary)
                    .padding(.top, 10)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: MysticSpacing.lg) {
                        // Header
                        VStack(spacing: MysticSpacing.md) {
                            Spacer().frame(height: 40)

                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(MysticGradients.lavenderGlow)
                                .shadow(color: MysticColors.neonLavender.opacity(0.4), radius: 12)

                            GlowingText("El Falı", font: MysticFonts.title(32), color: MysticColors.neonLavender)

                            Text("Avuç içinizdeki çizgiler, yaşam hikayenizi anlatıyor. Fotoğraf çekin, AI ile detaylı analiz yapın.")
                                .font(MysticFonts.body(15))
                                .foregroundColor(MysticColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, MysticSpacing.xl)
                        }
                        .fadeInOnAppear(delay: 0)

                        // Camera Button
                        MysticCard(glowColor: MysticColors.neonLavender) {
                            VStack(spacing: MysticSpacing.md) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: MysticRadius.lg)
                                        .fill(MysticColors.inputBackground)
                                        .frame(height: 200)
                                    VStack(spacing: MysticSpacing.sm) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(MysticColors.textMuted)
                                        Text("Elinizin fotoğrafını çekin")
                                            .font(MysticFonts.body(14))
                                            .foregroundColor(MysticColors.textMuted)
                                    }
                                }

                                MysticButton("Fotoğraf Çek", icon: "camera.fill", style: .primary) {
                                    analyzePalm()
                                }
                            }
                        }
                        .padding(.horizontal, MysticSpacing.md)
                        .fadeInOnAppear(delay: 0.15)

                        // Interpretation
                        if let interpretation = interpretation {
                            MysticCard(glowColor: MysticColors.mysticGold) {
                                VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                                    HStack {
                                        Image(systemName: "sparkles").foregroundColor(MysticColors.mysticGold)
                                        Text("AI Analizi").font(MysticFonts.heading(16)).foregroundColor(MysticColors.textPrimary)
                                    }
                                    Text(interpretation)
                                        .font(MysticFonts.body(14))
                                        .foregroundColor(MysticColors.textSecondary)
                                        .lineSpacing(3)
                                }
                            }
                            .padding(.horizontal, MysticSpacing.md)
                            .fadeInOnAppear(delay: 0)
                        }

                        // Info cards
                        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                            Text("Çizgi Rehberi")
                                .font(MysticFonts.heading(18))
                                .foregroundColor(MysticColors.textPrimary)
                                .padding(.horizontal, MysticSpacing.md)

                            lineInfo(name: "Yaşam Çizgisi", desc: "Fiziksel sağlık ve yaşam enerjisi", color: MysticColors.auroraGreen)
                            lineInfo(name: "Kalp Çizgisi", desc: "Duygusal yaşam ve ilişkiler", color: MysticColors.celestialPink)
                            lineInfo(name: "Akıl Çizgisi", desc: "Düşünce yapısı ve zeka", color: MysticColors.neonLavender)
                            lineInfo(name: "Kader Çizgisi", desc: "Kariyer ve yaşam yolu", color: MysticColors.mysticGold)
                        }
                        .fadeInOnAppear(delay: 0.2)

                    }
                }
            }
        }
    }

    private func lineInfo(name: String, desc: String, color: Color) -> some View {
        MysticCard(glowColor: color.opacity(0.5)) {
            HStack(spacing: MysticSpacing.md) {
                Circle().fill(color.opacity(0.2)).frame(width: 40, height: 40)
                    .overlay(Circle().stroke(color.opacity(0.4), lineWidth: 1))
                    .overlay(Image(systemName: "line.diagonal").foregroundColor(color))
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(MysticFonts.body(15)).fontWeight(.semibold).foregroundColor(MysticColors.textPrimary)
                    Text(desc).font(MysticFonts.caption(13)).foregroundColor(MysticColors.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.horizontal, MysticSpacing.md)
    }

    private func analyzePalm() {
        isAnalyzing = true
        Task {
            interpretation = try? await AIService.shared.interpretPalm(imageData: nil)
            isAnalyzing = false
        }
    }
}

#Preview { PalmReadingView().environment(AuthService()) }
