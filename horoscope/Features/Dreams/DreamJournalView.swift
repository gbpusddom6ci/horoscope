import SwiftUI

struct DreamJournalView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.mainChromeMetrics) private var chromeMetrics
    @State private var showNewDreamSheet = false
    @State private var showSavedToast = false

    private let dreamService = DreamService.shared

    private var dreams: [DreamEntry] {
        guard let userId = authService.currentUser?.id else { return [] }
        return dreamService.entriesForUser(userId)
    }

    var body: some View {
        ZStack(alignment: .top) {
            StarField(starCount: 40)

            VStack(spacing: 0) {
                MysticTopBar("dream.title") {
                    Button {
                        showNewDreamSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 19))
                            .foregroundColor(MysticColors.celestialPink)
                    }
                    .accessibilityLabel(Text(String(localized: "dream.new")))
                    .accessibilityHint(Text(String(localized: "dream.quick_add.hint")))
                    .accessibilityIdentifier("dream.new_topbar")
                }

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: MysticSpacing.lg) {
                        if let syncError = dreamService.lastErrorMessage {
                            syncErrorBanner(syncError)
                                .padding(.top, MysticSpacing.xs)
                        }

                        if dreams.isEmpty {
                            headerCard.fadeInOnAppear(delay: 0)
                            emptyState.fadeInOnAppear(delay: 0.1)
                        } else {
                            compactHeaderCard.fadeInOnAppear(delay: 0)
                            ForEach(dreams) { dream in
                                dreamCard(dream: dream)
                            }
                        }
                        Color.clear.frame(
                            height: dreams.isEmpty
                                ? max(72, chromeMetrics.contentBottomReservedSpace)
                                : max(128, chromeMetrics.contentBottomReservedSpace + 44)
                        )
                    }
                    .padding(.horizontal, MysticLayout.screenHorizontalPadding)
                    .padding(.top, MysticSpacing.sm)
                }
            }
            .sheet(isPresented: $showNewDreamSheet, onDismiss: {
                Task {
                    await refreshEntries()
                }
            }) {
                NewDreamSheet {
                    showDreamSavedToast()
                }
                .environment(authService)
            }

            if showSavedToast {
                Text("dream.saved")
                    .font(MysticFonts.caption(13))
                    .foregroundColor(MysticColors.voidBlack)
                    .padding(.horizontal, MysticSpacing.md)
                    .padding(.vertical, MysticSpacing.sm)
                    .background(MysticColors.auroraGreen)
                    .clipShape(Capsule())
                    .padding(.top, MysticSpacing.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .task(id: authService.currentUser?.id) {
            await refreshEntries()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDreamComposer)) { _ in
            showNewDreamSheet = true
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !dreams.isEmpty {
                VStack {
                    MysticButton(String(localized: "dream.new"), icon: "plus.circle.fill", style: .primary) {
                        showNewDreamSheet = true
                    }
                    .accessibilityHint(Text(String(localized: "dream.quick_add.hint")))
                    .accessibilityIdentifier("dream.new_dock_cta")
                }
                .padding(.horizontal, MysticLayout.screenHorizontalPadding)
                .padding(.top, MysticSpacing.sm)
                .padding(.bottom, chromeMetrics.tabBarVisible ? MysticSpacing.xs : MysticSpacing.md)
                .background(
                    Rectangle()
                        .fill(MysticColors.voidBlack.opacity(0.9))
                        .overlay(Rectangle().fill(MysticGradients.cardGlass))
                )
            }
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
                    Text("\(dreams.count) \(String(localized: "dream.count_suffix"))")
                        .font(MysticFonts.caption(13))
                        .foregroundColor(MysticColors.textMuted)
                }
                Text("dream.header.subtitle")
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.textSecondary)
                    .lineSpacing(3)

                MysticButton(String(localized: "dream.new"), icon: "plus.circle.fill", style: .primary) {
                    showNewDreamSheet = true
                }
            }
        }
    }

    private var compactHeaderCard: some View {
        MysticCard(glowColor: MysticColors.celestialPink.opacity(0.7)) {
            HStack(spacing: MysticSpacing.md) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 18))
                    .foregroundColor(MysticColors.celestialPink)

                VStack(alignment: .leading, spacing: 2) {
                    Text("dream.compact.title")
                        .font(MysticFonts.body(14))
                        .foregroundColor(MysticColors.textPrimary)
                    Text("dream.compact.subtitle")
                        .font(MysticFonts.caption(12))
                        .foregroundColor(MysticColors.textSecondary)
                }

                Spacer()

                Text("\(dreams.count) \(String(localized: "dream.count_suffix"))")
                    .font(MysticFonts.caption(12))
                    .foregroundColor(MysticColors.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MysticColors.inputBackground)
                    .clipShape(Capsule())
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
            Text("dream.empty.title")
                .font(MysticFonts.heading(18))
                .foregroundColor(MysticColors.textSecondary)
            Text("dream.empty.subtitle")
                .font(MysticFonts.body(15))
                .foregroundColor(MysticColors.textMuted)

            MysticButton(String(localized: "dream.empty.cta"), icon: "plus.circle.fill", style: .secondary) {
                showNewDreamSheet = true
            }
            .frame(maxWidth: 260)
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
                    .lineLimit(3)
                    .lineSpacing(2)
                if let interpretation = dream.interpretation {
                    Divider().background(MysticColors.cardBorder)
                    Text(interpretation)
                        .font(MysticFonts.body(13))
                        .foregroundColor(MysticColors.textSecondary)
                        .lineLimit(4)
                        .lineSpacing(2)
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

    private func showDreamSavedToast() {
        withAnimation {
            showSavedToast = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation {
                    showSavedToast = false
                }
            }
        }
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
    @State private var validationMessage: String?

    private let dreamService = DreamService.shared
    private let onSaved: () -> Void

    init(onSaved: @escaping () -> Void = {}) {
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MysticColors.voidBlack.ignoresSafeArea()
                StarField(starCount: 30)

                ScrollView {
                    VStack(spacing: MysticSpacing.lg) {
                        moodPicker
                        dreamInput

                        if let validationMessage {
                            Text(validationMessage)
                                .font(MysticFonts.caption(12))
                                .foregroundColor(MysticColors.celestialPink)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let interp = interpretation {
                            interpretationCard(interp)
                        }

                        actionButtons
                    }
                    .padding(MysticSpacing.md)
                }
            }
            .navigationTitle(Text("dream.new_sheet.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                        .foregroundColor(MysticColors.neonLavender)
                }
            }
        }
    }

    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            Text("dream.new_sheet.mood")
                .font(MysticFonts.heading(16))
                .foregroundColor(MysticColors.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MysticSpacing.sm) {
                    ForEach(DreamMood.allCases, id: \.self) { mood in
                        Button { selectedMood = mood } label: {
                            VStack(spacing: 4) {
                                Text(mood.emoji).font(.system(size: 28))
                                Text(mood.localizedDisplayName)
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
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 52, minHeight: 52)
                    }
                }
            }
        }
    }

    private var dreamInput: some View {
        VStack(alignment: .leading, spacing: MysticSpacing.sm) {
            Text("dream.new_sheet.input_title")
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
                .onChange(of: dreamText) { _, _ in
                    validationMessage = nil
                }
        }
    }

    private func interpretationCard(_ text: String) -> some View {
        MysticCard(glowColor: MysticColors.celestialPink) {
            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                HStack {
                    Image(systemName: "sparkles").foregroundColor(MysticColors.mysticGold)
                    Text("dream.new_sheet.ai_title")
                        .font(MysticFonts.heading(16))
                        .foregroundColor(MysticColors.textPrimary)
                }
                Text(text)
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.textSecondary)
                    .lineSpacing(3)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: MysticSpacing.sm) {
            Text("dream.new_sheet.steps")
                .font(MysticFonts.caption(12))
                .foregroundColor(MysticColors.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            MysticButton(String(localized: "dream.new_sheet.interpret"), icon: "sparkles", style: .primary, isLoading: isInterpreting) {
                guard validateDreamText() else { return }
                interpretDream()
            }
            .accessibilityHint(Text(String(localized: "dream.new_sheet.interpret_hint")))

            MysticButton(String(localized: "common.save"), icon: "checkmark.circle", style: .secondary) {
                guard validateDreamText() else { return }
                saveDream()
            }
            .accessibilityHint(Text(String(localized: "dream.new_sheet.save_hint")))
        }
    }

    private func validateDreamText() -> Bool {
        guard !dreamText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationMessage = String(localized: "dream.validation.required")
            return false
        }
        validationMessage = nil
        return true
    }

    private func interpretDream() {
        isInterpreting = true

        Task {
            let result = try? await AIService.shared.interpretDream(dreamText: dreamText)
            await MainActor.run {
                interpretation = result
                isInterpreting = false
            }

            if result == nil {
                await MainActor.run {
                    validationMessage = String(localized: "dream.validation.interpret_failed")
                }
            }
        }
    }

    private func saveDream() {
        guard let userId = authService.currentUser?.id else { return }

        let entry = DreamEntry(
            userId: userId,
            dreamText: dreamText.trimmingCharacters(in: .whitespacesAndNewlines),
            interpretation: interpretation,
            mood: selectedMood
        )

        dreamService.addEntry(entry)
        onSaved()
        dismiss()
    }
}

#Preview {
    DreamJournalView().environment(AuthService())
}
