import SwiftUI

struct DreamJournalView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.mainChromeMetrics) private var chromeMetrics
    @State private var showNewDreamSheet = false
    @State private var showSavedToast = false
    @State private var selectedDream: DreamEntry?
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isRefreshingEntries = false

    private let dreamService = DreamService.shared

    private var dreams: [DreamEntry] {
        guard let userId = authService.currentUser?.id else { return [] }
        return dreamService.entriesForUser(userId)
    }

    private var shouldShowInitialLoadingState: Bool {
        Self.shouldShowInitialLoadingState(
            isRefreshing: isRefreshingEntries,
            dreamsCount: dreams.count
        )
    }

    private var shouldShowRefreshNotice: Bool {
        Self.shouldShowRefreshNotice(
            isRefreshing: isRefreshingEntries,
            dreamsCount: dreams.count
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            MysticScreenScaffold(
                "dream.title",
                showsBackground: false
            ) {
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
            } content: {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: MysticSpacing.lg) {
                            Color.clear
                                .frame(height: 0)
                                .id("dream_top")

                            if let syncError = dreamService.lastErrorMessage {
                                syncErrorBanner(syncError)
                                    .padding(.top, MysticSpacing.xs)
                            }

                            if shouldShowRefreshNotice {
                                refreshNotice
                            }

                            if shouldShowInitialLoadingState {
                                initialLoadingState
                                    .fadeInOnAppear(delay: 0)
                            } else if dreams.isEmpty {
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
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .refreshable {
                        await refreshEntries()
                    }
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
        .onAppear {
            if AppNavigation.consumePendingDreamComposer() {
                showNewDreamSheet = true
            }
        }
        .sheet(item: $selectedDream) { dream in
            DreamDetailSheet(
                dream: dream,
                onDelete: {
                    dreamService.deleteEntry(dream.id)
                    selectedDream = nil
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDreamComposer)) { _ in
            _ = AppNavigation.consumePendingDreamComposer()
            showNewDreamSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .scrollToTop)) { notification in
            guard let tab = notification.object as? AppTab, tab == .dream else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollProxy?.scrollTo("dream_top", anchor: .top)
            }
        }
        .overlay(alignment: .bottom) {
            if !dreams.isEmpty {
                VStack(spacing: 0) {
                    MysticButton(String(localized: "dream.new"), icon: "plus.circle.fill", style: .primary) {
                        showNewDreamSheet = true
                    }
                    .accessibilityHint(Text(String(localized: "dream.quick_add.hint")))
                    .accessibilityIdentifier("dream.new_dock_cta")
                    .padding(.horizontal, MysticLayout.screenHorizontalPadding)
                    .padding(.top, MysticSpacing.sm)
                    .padding(.bottom, MysticSpacing.sm)
                }
                .padding(.bottom, chromeMetrics.tabBarVisible ? chromeMetrics.tabBarHeight : 0)
                .background(
                    Rectangle()
                        .fill(MysticColors.voidBlack.opacity(0.9))
                        .overlay(Rectangle().fill(MysticGradients.cardGlass))
                        .ignoresSafeArea(.container, edges: .bottom)
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
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
                    Text(verbatim: "\(dreams.count) \(String(localized: "dream.count_suffix"))")
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

                Text(verbatim: "\(dreams.count) \(String(localized: "dream.count_suffix"))")
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
            .accessibilityHint(Text(String(localized: "dream.quick_add.hint")))
            .accessibilityIdentifier("dream.empty.cta")
        }
    }

    private var initialLoadingState: some View {
        MysticStateCard(
            variant: .loading(messageKey: "dream.loading.entries"),
            accessibilityIdentifier: "dream.loading.state"
        )
        .frame(maxWidth: .infinity)
    }

    private var refreshNotice: some View {
        HStack(spacing: MysticSpacing.xs) {
            ProgressView()
                .tint(MysticColors.neonLavender)
                .scaleEffect(0.9)
            Text("dream.loading.refresh")
                .font(MysticFonts.caption(12))
                .foregroundColor(MysticColors.textMuted)
            Spacer()
        }
        .padding(.horizontal, MysticSpacing.sm)
        .padding(.vertical, 8)
        .background(MysticColors.cardBackground.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: MysticRadius.sm))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(String(localized: "dream.loading.refresh")))
        .accessibilityIdentifier("dream.refresh.notice")
    }

    private func dreamCard(dream: DreamEntry) -> some View {
        Button {
            selectedDream = dream
        } label: {
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
        .buttonStyle(.plain)
        .accessibilityIdentifier("dream.entry.\(dream.id)")
        .contextMenu {
            Button(role: .destructive) {
                dreamService.deleteEntry(dream.id)
            } label: {
                Label(String(localized: "common.delete"), systemImage: "trash")
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
            Button(String(localized: "dream.retry.action")) {
                Task { await refreshEntries() }
            }
            .disabled(isRefreshingEntries)
            .font(MysticFonts.caption(12))
            .foregroundColor(MysticColors.neonLavender)
            .accessibilityHint(Text(String(localized: "dream.retry.hint")))
            .accessibilityIdentifier("dream.retry.load")
        }
        .padding(.horizontal, MysticSpacing.sm)
        .padding(.vertical, 8)
        .background(MysticColors.celestialPink.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MysticRadius.sm))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("dream.error.banner")
    }

    private func refreshEntries() async {
        await MainActor.run {
            isRefreshingEntries = true
        }

        guard let userId = authService.currentUser?.id else {
            await MainActor.run {
                isRefreshingEntries = false
            }
            return
        }

        await dreamService.loadEntries(for: userId)

        await MainActor.run {
            isRefreshingEntries = false
        }
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

    nonisolated static func shouldShowInitialLoadingState(isRefreshing: Bool, dreamsCount: Int) -> Bool {
        isRefreshing && dreamsCount == 0
    }

    nonisolated static func shouldShowRefreshNotice(isRefreshing: Bool, dreamsCount: Int) -> Bool {
        isRefreshing && dreamsCount > 0
    }
}

// MARK: - Dream Detail Sheet
private struct DreamDetailSheet: View {
    let dream: DreamEntry
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: MysticSpacing.lg) {
                        headerCard
                        dreamTextCard

                        if let interpretation = dream.interpretation {
                            interpretationCard(text: interpretation)
                        }

                        MysticButton(String(localized: "common.delete"), icon: "trash", style: .danger) {
                            onDelete()
                            dismiss()
                        }
                        .accessibilityIdentifier("dream.detail.delete")
                    }
                    .padding(MysticSpacing.md)
                }
                .background {
                    ZStack {
                        MysticColors.voidBlack.ignoresSafeArea()
                        StarField(starCount: 30, mode: .modal)
                    }
                }
            .navigationTitle(Text(verbatim: dream.createdAt.formatted(as: "d MMMM yyyy")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "common.close")) { dismiss() }
                        .foregroundColor(MysticColors.neonLavender)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .foregroundColor(MysticColors.celestialPink)
                    .accessibilityLabel(Text(String(localized: "common.delete")))
                }
            }
        }
    }

    private var headerCard: some View {
        MysticCard(glowColor: MysticColors.celestialPink.opacity(0.7)) {
            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                HStack(spacing: MysticSpacing.sm) {
                    if let mood = dream.mood {
                        Text(mood.emoji)
                            .font(.system(size: 28))
                            .accessibilityHidden(true)

                        Text(mood.localizedDisplayName)
                            .font(MysticFonts.heading(16))
                            .foregroundColor(MysticColors.textPrimary)
                    } else {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 18))
                            .foregroundColor(MysticColors.celestialPink)

                        Text("dream.title")
                            .font(MysticFonts.heading(16))
                            .foregroundColor(MysticColors.textPrimary)
                    }

                    Spacer()
                }

                Text(dream.createdAt.formatted(as: "EEEE, d MMMM yyyy"))
                    .font(MysticFonts.caption(12))
                    .foregroundColor(MysticColors.textMuted)
            }
        }
        .accessibilityIdentifier("dream.detail.header")
    }

    private var dreamTextCard: some View {
        MysticCard {
            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                HStack(spacing: MysticSpacing.xs) {
                    Image(systemName: "pencil.and.scribble")
                        .foregroundColor(MysticColors.neonLavender)
                    Text("dream.new_sheet.input_title")
                        .font(MysticFonts.heading(16))
                        .foregroundColor(MysticColors.textPrimary)
                }

                Text(dream.dreamText)
                    .font(MysticFonts.body(15))
                    .foregroundColor(MysticColors.textSecondary)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityIdentifier("dream.detail.text")
    }

    private func interpretationCard(text: String) -> some View {
        MysticCard(glowColor: MysticColors.mysticGold.opacity(0.35)) {
            VStack(alignment: .leading, spacing: MysticSpacing.sm) {
                HStack(spacing: MysticSpacing.xs) {
                    Image(systemName: "sparkles")
                        .foregroundColor(MysticColors.mysticGold)
                    Text("dream.new_sheet.ai_title")
                        .font(MysticFonts.heading(16))
                        .foregroundColor(MysticColors.textPrimary)
                }

                Text(text)
                    .font(MysticFonts.body(14))
                    .foregroundColor(MysticColors.textSecondary)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityIdentifier("dream.detail.interpretation")
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
                .scrollDismissesKeyboard(.interactively)
                .background {
                    ZStack {
                        MysticColors.voidBlack.ignoresSafeArea()
                        StarField(starCount: 30, mode: .modal)
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
        guard UsageLimitService.shared.canPerformAction(.dreamInterpretation) else { return }

        isInterpreting = true

        Task {
            let result = try? await AIService.shared.interpretDream(dreamText: dreamText)
            await MainActor.run {
                interpretation = result
                isInterpreting = false
                if result != nil {
                    UsageLimitService.shared.recordAction(.dreamInterpretation)
                }
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
