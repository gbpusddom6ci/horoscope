import SwiftUI

struct TemplatesView: View {
    let categories: [(String, String, [TemplateItem])] = [
        ("Product Listings", "cart.fill", [
            TemplateItem(title: "Etsy Bestseller", description: "Emotional hook + SEO optimized bullet points + urgency.", platformColor: Color.orange),
            TemplateItem(title: "Shopify Luxe", description: "Premium, storytelling-driven description for high-ticket items.", platformColor: Color.green),
            TemplateItem(title: "Amazon A+ Copy", description: "Benefit-driven feature list heavily optimized for search.", platformColor: AppTheme.primary)
        ]),
        ("Social Media", "bubble.left.and.bubble.right.fill", [
            TemplateItem(title: "Instagram Reel hook", description: "3-second viral hook + caption with relevant hashtags.", platformColor: Color.purple),
            TemplateItem(title: "TikTok Storytime", description: "A casual, trending story format about packaging orders.", platformColor: .black)
        ]),
        ("Email & Newsletters", "envelope.fill", [
            TemplateItem(title: "Abandoned Cart", description: "Urgency + discount code + playful reminder.", platformColor: AppTheme.accent),
            TemplateItem(title: "New Drop Teaser", description: "Build hype for a new collection launching soon.", platformColor: AppTheme.primary)
        ])
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Templates")
                        .font(AppTypography.titleExtraBold)
                        .foregroundColor(.primary)
                    
                    Text("Ready-to-use formulas for every platform.")
                        .premiumText(color: .secondary)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                
                ForEach(categories, id: \.0) { category, icon, items in
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: icon)
                                .foregroundColor(AppTheme.primary)
                            Text(category)
                                .font(AppTypography.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 24)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                            ForEach(items) { item in
                                TemplateCard(item: item)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                Spacer(minLength: 120)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct TemplateItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let platformColor: Color
}

struct TemplateCard: View {
    let item: TemplateItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(item.platformColor.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(item.platformColor)
                )
            
            Text(item.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(item.description)
                .font(AppTypography.captionMedium)
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .lineLimit(3)
                .frame(height: 50, alignment: .topLeading)
            
            Spacer(minLength: 0)
            
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            } label: {
                Text("Use Template")
                    .font(.system(size: 12, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.primary.opacity(0.1))
                    .foregroundColor(AppTheme.primary)
                    .cornerRadius(10)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    TemplatesView()
}
