import SwiftUI

struct GenerateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    enum State {
        case form
        case generating
        case results
    }
    
    @SwiftUI.State private var viewState: State = .form
    
    // Form Data
    @SwiftUI.State private var productName = ""
    @SwiftUI.State private var selectedCategory = "Handmade"
    @SwiftUI.State private var price = ""
    @SwiftUI.State private var keyFeatures: [String] = ["Eco-friendly", "Premium Quality"]
    @SwiftUI.State private var newFeature = ""
    @SwiftUI.State private var selectedVoice = "Playful"
    @DomainState private var selectedPlatforms: Set<String> = ["Etsy", "Instagram"]
    @SwiftUI.State private var toneLength: Double = 0.5
    
    // Generation State
    @SwiftUI.State private var streamingText = ""
    @SwiftUI.State private var generationProgress: Double = 0.0
    
    let categories = ["Handmade", "Digital Download", "Apparel", "Home Decor", "Jewelry", "Other"]
    let voices = ["Luxe", "Playful", "Professional", "Storytelling", "Bold", "Minimal", "Urgent"]
    let platforms = ["Etsy", "Shopify", "Amazon", "Instagram", "TikTok", "General"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                switch viewState {
                case .form:
                    formScreen
                case .generating:
                    generatingScreen
                case .results:
                    ResultsView(onClose: { dismiss() }, onRegenerate: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        startGeneration()
                    })
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Form Screen
    private var formScreen: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .padding()
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Creation")
                            .font(AppTypography.titleBold)
                            .foregroundColor(.primary)
                        Text("Let the magic happen. Tell us about your product.")
                            .premiumText(color: .secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    productBasicsSection
                    keyFeaturesSection
                    brandVoiceSection
                    platformsSection
                    toneLengthSection
                    
                    Spacer(minLength: 40)
                    
                    generateButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
    }
    
    // MARK: - Sections
    private var productBasicsSection: some View {
        FormSection(title: "Product Basics", icon: "cube.box.fill") {
            VStack(spacing: 16) {
                TextField("Product Name (e.g., Lavender Soy Candle)", text: $productName)
                    .padding()
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                    .font(AppTypography.body)
                
                HStack(spacing: 16) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                    
                    TextField("Price ($)", text: $price)
                        .keyboardType(.decimalPad)
                        .padding()
                        .frame(width: 100)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private var keyFeaturesSection: some View {
        FormSection(title: "Key Features", icon: "sparkles.rectangle.stack.fill") {
            VStack(alignment: .leading, spacing: 12) {
                // Chips Group
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(keyFeatures, id: \.self) { feature in
                            HStack(spacing: 4) {
                                Text(feature)
                                    .font(AppTypography.captionMedium)
                                
                                Button {
                                    withAnimation { keyFeatures.removeAll(where: { $0 == feature }) }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.primary.opacity(0.1))
                            .foregroundColor(AppTheme.primary)
                            .cornerRadius(16)
                        }
                    }
                }
                
                HStack {
                    TextField("Add another feature...", text: $newFeature)
                        .font(AppTypography.body)
                        .onSubmit { addFeature() }
                    
                    Button { addFeature() } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.primary)
                            .font(.system(size: 24))
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
    
    private func addFeature() {
        let trimmed = newFeature.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !keyFeatures.contains(trimmed) {
            withAnimation {
                keyFeatures.append(trimmed)
                newFeature = ""
            }
        }
    }
    
    private var brandVoiceSection: some View {
        FormSection(title: "Brand Voice", icon: "megaphone.fill") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(voices, id: \.self) { voice in
                        Button {
                            withAnimation { selectedVoice = voice }
                        } label: {
                            Text(voice)
                                .font(AppTypography.captionMedium)
                                .fontWeight(selectedVoice == voice ? .bold : .regular)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(selectedVoice == voice ? AppTheme.accent : Color.primary.opacity(0.05))
                                .foregroundColor(selectedVoice == voice ? .white : .primary)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var platformsSection: some View {
        FormSection(title: "Target Platforms", icon: "network") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(platforms, id: \.self) { platform in
                    Button {
                        withAnimation {
                            if selectedPlatforms.contains(platform) {
                                selectedPlatforms.remove(platform)
                            } else {
                                selectedPlatforms.insert(platform)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: selectedPlatforms.contains(platform) ? "checkmark.circle.fill" : "circle")
                            Text(platform)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedPlatforms.contains(platform) ? AppTheme.success.opacity(0.15) : Color.primary.opacity(0.05))
                        .foregroundColor(selectedPlatforms.contains(platform) ? AppTheme.success : .secondary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedPlatforms.contains(platform) ? AppTheme.success.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
    
    private var toneLengthSection: some View {
        FormSection(title: "Tone & Length", icon: "slider.horizontal.3") {
            VStack(spacing: 8) {
                HStack {
                    Text("Concise")
                        .font(AppTypography.captionMedium)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Detailed")
                        .font(AppTypography.captionMedium)
                        .foregroundColor(.secondary)
                }
                Slider(value: $toneLength, in: 0...1)
                    .tint(AppTheme.primary)
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var generateButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            startGeneration()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Generate Magic")
            }
            .font(AppTypography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(16)
            .shadow(color: AppTheme.primary.opacity(0.4), radius: 15, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Generation State
    private func startGeneration() {
        withAnimation {
            viewState = .generating
            streamingText = ""
            generationProgress = 0.0
        }
        
        let targetText = "Analyzing product features... Crafting the perfect brand voice... Optimizing SEO for selected platforms... Adding emotional resonance... Finalizing the magic."
        
        Task {
            for (index, char) in targetText.enumerated() {
                try? await Task.sleep(nanoseconds: 25_000_000)
                await MainActor.run {
                    streamingText.append(char)
                    let haptic = UISelectionFeedbackGenerator()
                    if index % 5 == 0 { haptic.selectionChanged() }
                    generationProgress = Double(index) / Double(targetText.count)
                }
            }
            
            try? await Task.sleep(nanoseconds: 500_000_000)
            let successHaptic = UINotificationFeedbackGenerator()
            successHaptic.notificationOccurred(.success)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                viewState = .results
            }
        }
    }
    
    private var generatingScreen: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                // Pulsing Orb
                Circle()
                    .fill(
                        RadialGradient(colors: [AppTheme.primary, .clear], center: .center, startRadius: 10, endRadius: 100)
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(generationProgress == 0 ? 0.8 : 1.2 + sin(generationProgress * 10) * 0.1)
                    .opacity(0.6 + sin(generationProgress * 10) * 0.2)
                    .animation(.easeInOut(duration: 0.5), value: generationProgress)
                
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 24) {
                Text(streamingText)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(AppTheme.primary)
                    .multilineTextAlignment(.center)
                    .frame(height: 100, alignment: .top)
                    .padding(.horizontal, 32)
                
                ProgressView(value: generationProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accent))
                    .padding(.horizontal, 60)
            }
            
            Spacer()
        }
    }
}

// MARK: - Generic Form Section Wrapper
struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.primary)
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
            content
        }
    }
}

// MARK: - Domain Wrapper for Set State
@propertyWrapper
struct DomainState<Value> {
    @SwiftUI.State private var value: Value
    
    init(wrappedValue: Value) {
        self._value = SwiftUI.State(initialValue: wrappedValue)
    }
    
    var wrappedValue: Value {
        get { value }
        nonmutating set { value = newValue }
    }
    
    var projectedValue: Binding<Value> {
        Binding(
            get: { value },
            set: { value = $0 }
        )
    }
}

#Preview {
    GenerateView()
}
