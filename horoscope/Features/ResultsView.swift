import SwiftUI

struct ResultsView: View {
    let onClose: () -> Void
    let onRegenerate: () -> Void
    
    @State private var selectedIndex = 0
    @State private var showMarkdown = true
    
    // Mock Data
    private let variations = [
        "**Best Seller Alert!** ✨\nElevate your morning routine with our premium hand-poured soy candle. Infused with natural lavender essential oils, this 8oz beauty brings the spa straight to your living room. Perfect for gifts or self-care Sundays. 🌿\n\n- 100% Organic Soy Wax\n- 45+ Hour Burn Time\n- Eco-friendly packaging",
        "Looking for the perfect unwind? 🕯️\nOur Lavender Aromatherapy Candle is hand-poured in small batches using premium soy wax. The calming scent profile is designed to melt away stress instantly.\n\n✨ Why you'll love it:\n- Clean burn (no soot!)\n- Vegan & Cruelty-free\n- Sourced sustainably",
        "Transform your space into a peaceful sanctuary. This artisanal lavender candle is more than just home decor—it's an experience. Let the soothing botanicals relax your mind after a long day.\n\nKey features:\n✓ Handcrafted with love\n✓ Pure lavender essence\n✓ Reusable glass jar"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Magic Generated ✨")
                    .font(AppTypography.titleBold)
                Spacer()
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            // Format Toggle
            HStack {
                Picker("Preview Format", selection: $showMarkdown) {
                    Text("Markdown").tag(true)
                    Text("Plain Text").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                Spacer()
                
                Text("Variation \(selectedIndex + 1) of \(variations.count)")
                    .font(AppTypography.captionMedium)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // Swipeable Cards
            TabView(selection: $selectedIndex) {
                ForEach(0..<variations.count, id: \.self) { index in
                    ResultCard(content: variations[index], showMarkdown: showMarkdown)
                        .tag(index)
                        .padding(.horizontal, 16)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Footer Action Buttons
            HStack(spacing: 16) {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                } label: {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Save to Library")
                    }
                    .font(AppTypography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.primary.opacity(0.1))
                    .foregroundColor(AppTheme.primary)
                    .cornerRadius(16)
                }
                
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred()
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.right.square.fill")
                        Text("Export to Shopify")
                    }
                    .font(AppTypography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
            }
            .padding(16)
            .padding(.bottom, 16) // Safe area
        }
    }
}

struct ResultCard: View {
    let content: String
    let showMarkdown: Bool
    
    @State private var isCopied = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Content Area
            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading) {
                    if showMarkdown {
                        Text(LocalizedStringKey(content))
                            .premiumText(font: AppTypography.body, color: .primary, lineSpacing: 6)
                    } else {
                        Text(content.replacingOccurrences(of: "**", with: ""))
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.primary.opacity(0.8))
                            .lineSpacing(4)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.primary.opacity(0.02))
            
            Divider()
            
            // Actions
            VStack(spacing: 16) {
                HStack {
                    ActionButton(title: "Make Shorter", icon: "arrow.down.right.and.arrow.up.left")
                    Spacer()
                    ActionButton(title: "Make Longer", icon: "arrow.up.left.and.arrow.down.right")
                    Spacer()
                    ActionButton(title: "More Emotional", icon: "heart.fill", color: AppTheme.accent)
                }
                
                HStack(spacing: 16) {
                    Button {
                        // Copy string directly
                        UIPasteboard.general.string = content
                        let impact = UINotificationFeedbackGenerator()
                        impact.notificationOccurred(.success)
                        withAnimation { isCopied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { isCopied = false }
                        }
                    } label: {
                        HStack {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.clipboard.fill")
                                .contentTransition(.symbolEffect(.replace))
                            Text(isCopied ? "Copied!" : "Copy")
                        }
                        .font(AppTypography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isCopied ? AppTheme.success : AppTheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "hand.thumbsup")
                            .foregroundColor(.secondary)
                        Image(systemName: "hand.thumbsdown")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    var color: Color = .primary
    
    var body: some View {
        Button {} label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .frame(width: 90)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    ResultsView(onClose: {}, onRegenerate: {})
}
