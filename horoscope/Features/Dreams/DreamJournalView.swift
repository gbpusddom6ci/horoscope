import SwiftUI

struct DreamJournalView: View {
    @Environment(AuthService.self) private var authService
    @State private var showNewDreamSheet = false

    private let dreamService = DreamService.shared

    private var dreams: [DreamEntry] {
        guard let userId = authService.currentUser?.id else { return [] }
        return dreamService.entriesForUser(userId)
    }

    var body: some View {
        ZStack {
            StarField(starCount: 40)

            VStack(spacing: 0) {
                Text("Rüya Günlüğü")
                    .font(MysticFonts.heading(18))
                    .foregroundColor(MysticColors.textPrimary)
                    .padding(.top, 10)
                    .padding(.bottom, 10)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: MysticSpacing.lg) {
                        if let syncError = dreamService.lastErrorMessage {
                            syncErrorBanner(syncError)
                                .padding(.horizontal, MysticSpacing.md)
                                .padding(.top, MysticSpacing.xs)
                        }

                        headerCard.fadeInOnAppear(delay: 0)

                        if dreams.isEmpty {
                            emptyState.fadeInOnAppear(delay: 0.1)
                        } else {
                            ForEach(dreams) { dream in
                                dreamCard(dream: dream)
                            }
                        }
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, MysticSpacing.md)
                }
            }
            .sheet(isPresented: $showNewDreamSheet, onDismiss: {
                Task {
                    await refreshEntries()
                }
            }) {
                NewDreamSheet()
                    .environment(authService)
            }
        }
        .task(id: authService.currentUser?.id) {
            await refreshEntries()
        }
    }

    private var headerCard: some View {
        MysticCard(glowColor: MysticColors.celestialPink) {
            VStack(spacing: MysticSpacing.md) {
                HStack {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 28))
                        .foregroundColor(MysticColors.celestialPink)
                    Spacer()
                    Text("\(dreams.count) rüya")
                        .font(MysticFonts.caption(13))
                        .foregroundColor(MysticColors.textMuted)
                }
                Text("Rüyalarınız bilinçaltınızın kapısıdır. Rüyanızı yazın, AI ile sembollerini çözümleyin.")
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.textSecondary)
                    .lineSpacing(3)

                MysticButton("Yeni Rüya Yaz", icon: "plus.circle.fill", style: .primary) {
                    showNewDreamSheet = true
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: MysticSpacing.lg) {
            Spacer().frame(height: 40)
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 56))
                .foregroundStyle(MysticGradients.lavenderGlow)
                .opacity(0.4)
            Text("Henüz rüya kaydınız yok")
                .font(MysticFonts.heading(18))
                .foregroundColor(MysticColors.textSecondary)
            Text("İlk rüyanızı yazarak başlayın")
                .font(MysticFonts.body(15))
                .foregroundColor(MysticColors.textMuted)
        }
    }

    private func dreamCard(dream: DreamEntry) -> some View {
        MysticCard {
            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                HStack {
                    if let mood = dream.mood { Text(mood.emoji).font(.system(size: 20)) }
                    Text(dream.createdAt.formatted(as: "d MMMM yyyy"))
                        .font(MysticFonts.caption(13))
                        .foregroundColor(MysticColors.textMuted)
                    Spacer()
                }
                Text(dream.dreamText)
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.textPrimary)
                    .lineLimit(3).lineSpacing(2)
                if let interpretation = dream.interpretation {
                    Divider().background(MysticColors.cardBorder)
                    Text(interpretation)
                        .font(MysticFonts.body(13))
                        .foregroundColor(MysticColors.textSecondary)
                        .lineLimit(4).lineSpacing(2)
                }
            }
        }
    }

    private func syncErrorBanner(_ text: String) -> some View {
        HStack(spacing: MysticSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(MysticColors.celestialPink)
            Text(text)
                .font(MysticFonts.caption(12))
                .foregroundColor(MysticColors.celestialPink)
            Spacer()
        }
        .padding(.horizontal, MysticSpacing.sm)
        .padding(.vertical, 8)
        .background(MysticColors.celestialPink.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MysticRadius.sm))
    }

    private func refreshEntries() async {
        guard let userId = authService.currentUser?.id else { return }
        await dreamService.loadEntries(for: userId)
    }
}

// MARK: - New Dream Sheet
struct NewDreamSheet: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var dreamText = ""
    @State private var selectedMood: DreamMood?
    @State private var isInterpreting = false
    @State private var interpretation: String?

    private let dreamService = DreamService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                MysticColors.voidBlack.ignoresSafeArea()
                StarField(starCount: 30)

                ScrollView {
                    VStack(spacing: MysticSpacing.lg) {
                        moodPicker
                        dreamInput
                        if let interp = interpretation {
                            interpretationCard(interp)
                        }
                        actionButtons
                    }
                    .padding(MysticSpacing.md)
                }
            }
            .navigationTitle("Yeni Rüya")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(MysticColors.neonLavender)
                }
            }
        }
    }

    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            Text("Rüyanızın havası")
                .font(MysticFonts.heading(16))
                .foregroundColor(MysticColors.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MysticSpacing.sm) {
                    ForEach(DreamMood.allCases, id: \.self) { mood in
                        Button { selectedMood = mood } label: {
                            VStack(spacing: 4) {
                                Text(mood.emoji).font(.system(size: 28))
                                Text(mood.rawValue)
                                    .font(MysticFonts.caption(10))
                                    .foregroundColor(MysticColors.textSecondary)
                            }
                            .padding(MysticSpacing.sm)
                            .background(selectedMood == mood ? MysticColors.neonLavender.opacity(0.15) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: MysticRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: MysticRadius.md)
                                    .stroke(selectedMood == mood ? MysticColors.neonLavender.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var dreamInput: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            Text("Rüyanızı anlatın")
                .font(MysticFonts.heading(16))
                .foregroundColor(MysticColors.textPrimary)
            TextEditor(text: $dreamText)
                .font(MysticFonts.body(15))
                .foregroundColor(MysticColors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 200)
                .padding(MysticSpacing.md)
                .background(MysticColors.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: MysticRadius.md))
                .overlay(RoundedRectangle(cornerRadius: MysticRadius.md).stroke(MysticColors.cardBorder, lineWidth: 1))
        }
    }

    private func interpretationCard(_ text: String) -> some View {
        MysticCard(glowColor: MysticColors.celestialPink) {
            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                HStack {
                    Image(systemName: "sparkles").foregroundColor(MysticColors.mysticGold)
                    Text("AI Yorumu").font(MysticFonts.heading(16)).foregroundColor(MysticColors.textPrimary)
                }
                Text(text).font(MysticFonts.body(14)).foregroundColor(MysticColors.textSecondary).lineSpacing(3)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: MysticSpacing.sm) {
            MysticButton("Rüyamı Yorumla ✨", icon: "sparkles", style: .primary, isLoading: isInterpreting) {
                isInterpreting = true
                Task {
                    interpretation = try? await AIService.shared.interpretDream(dreamText: dreamText)
                    isInterpreting = false
                }
            }
            .disabled(dreamText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            MysticButton("Kaydet", icon: "checkmark.circle", style: .secondary) {
                guard let userId = authService.currentUser?.id else { return }
                let entry = DreamEntry(
                    userId: userId,
                    dreamText: dreamText,
                    interpretation: interpretation,
                    mood: selectedMood
                )
                dreamService.addEntry(entry)
                dismiss()
            }
            .disabled(dreamText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

#Preview { DreamJournalView().environment(AuthService()) }
