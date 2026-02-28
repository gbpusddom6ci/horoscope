import SwiftUI

struct HomeView: View {
    @Environment(AuthService.self) private var authService
    @State private var greeting: String = "Good morning"
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                    .padding(.top, 24)
                
                quickActionsSection
                
                recentCreationsSection
                
                dailyTipSection
                
                Spacer(minLength: 100) // Space for floating tab bar
            }
            .padding(.horizontal, 24)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            updateGreeting()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(greeting), \(authService.currentUser?.displayName.components(separatedBy: " ").first ?? "Sarah") ✨")
                .font(AppTypography.titleBold)
                .foregroundColor(.primary)
            
            Text("Ready to sell more today?")
                .premiumText(color: .secondary)
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(AppTypography.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    QuickActionCard(title: "Product Title", icon: "tag.fill", color: AppTheme.primary)
                    QuickActionCard(title: "Description", icon: "doc.text.fill", color: AppTheme.accent)
                    QuickActionCard(title: "SEO Tags", icon: "magnifyingglass", color: AppTheme.success)
                    QuickActionCard(title: "Social Post", icon: "bubble.left.and.bubble.right.fill", color: Color.purple)
                }
                // Add trailing padding to let it bleed to edge smoothly
                .padding(.trailing, 24)
            }
            .padding(.horizontal, -24)
            .padding(.leading, 24)
        }
    }
    
    private var recentCreationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Creations")
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button("See All") {
                    // Navigate to Library
                }
                .font(AppTypography.captionMedium)
                .foregroundColor(AppTheme.primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    RecentCreationCard(
                        title: "Handmade Ceramic Mug",
                        preview: "Start your morning right with this beautifully crafted ceramic mug...",
                        platform: "Etsy",
                        platformColor: Color.orange
                    )
                    RecentCreationCard(
                        title: "Neon Cyberpunk Poster",
                        preview: "Bring the future to your walls with our premium neon cyberpunk art...",
                        platform: "Shopify",
                        platformColor: Color.green
                    )
                    RecentCreationCard(
                        title: "Organic Soy Candle",
                        preview: "Relax and unwind with this 100% organic soy candle, featuring hints of...",
                        platform: "Amazon",
                        platformColor: AppTheme.primary
                    )
                }
                .padding(.trailing, 24)
            }
            .padding(.horizontal, -24)
            .padding(.leading, 24)
        }
    }
    
    private var dailyTipSection: some View {
        GlassCard(cornerRadius: 24) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accent)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Trending for Etsy this week")
                        .font(AppTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Buyers are loving 'cottagecore' keywords. Try adding them to your rustic listings to boost visibility!")
                        .font(AppTypography.captionMedium)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
            }
        }
    }
    
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            greeting = "Good morning"
        } else if hour < 18 {
            greeting = "Good afternoon"
        } else {
            greeting = "Good evening"
        }
    }
}

// MARK: - Subcomponents
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(AppTypography.captionMedium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: 110, height: 110, alignment: .topLeading)
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct RecentCreationCard: View {
    let title: String
    let preview: String
    let platform: String
    let platformColor: Color
    
    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(platform)
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(platformColor.opacity(0.15))
                        .foregroundColor(platformColor)
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(AppTypography.body)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(preview)
                    .font(AppTypography.captionMedium)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .lineSpacing(4)
                
                Spacer(minLength: 0)
                
                Text("Generated just now")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 240, height: 160, alignment: .topLeading)
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    HomeView()
        .environment(AuthService())
}
