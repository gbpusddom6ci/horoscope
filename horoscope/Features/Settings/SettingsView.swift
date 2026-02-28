import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Account")
                        .font(AppTypography.titleExtraBold)
                    Spacer()
                    Button {
                        // settings action
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                
                // Profile Section
                profileSection
                    .padding(.horizontal, 24)
                
                // Usage Section
                usageStatsSection
                    .padding(.horizontal, 24)
                
                // Actions
                actionListSection
                    .padding(.horizontal, 24)
                
                Spacer(minLength: 120)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
    
    // MARK: - Subsections
    private var profileSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 64, height: 64)
                
                Text(authService.currentUser?.displayName.prefix(1).uppercased() ?? "S")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: AppTheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(authService.currentUser?.displayName ?? "Sarah Seller")
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)
                
                Text(authService.currentUser?.email ?? "sarah@example.com")
                    .font(AppTypography.captionMedium)
                    .foregroundColor(.secondary)
                
                Text("PRO Plan Active")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(AppTheme.primary.opacity(0.15))
                    .foregroundColor(AppTheme.primary)
                    .cornerRadius(6)
                    .padding(.top, 4)
            }
            Spacer()
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
    
    private var usageStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Usage")
                .font(AppTypography.headline)
            
            HStack(spacing: 24) {
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 12)
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(
                            LinearGradient(colors: [AppTheme.success, AppTheme.primary], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 90, height: 90)
                        .shadow(color: AppTheme.primary.opacity(0.3), radius: 5, x: 0, y: 0)
                    
                    VStack(spacing: 2) {
                        Text("36")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        Text("/ 50")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    UsageRow(title: "Listings Generated", value: "24", color: AppTheme.primary)
                    UsageRow(title: "Social Posts", value: "8", color: AppTheme.accent)
                    UsageRow(title: "Email Campaigns", value: "4", color: AppTheme.success)
                }
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
    }
    
    private var actionListSection: some View {
        VStack(spacing: 12) {
            SettingsRow(title: "API Keys", icon: "key.fill", color: Color.orange)
            SettingsRow(title: "Export History", icon: "square.and.arrow.up.fill", color: Color.blue)
            SettingsRow(title: "Custom Brand Voice", icon: "megaphone.fill", color: Color.purple)
            
            Divider().padding(.vertical, 8)
            
            Button {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                authService.signOut()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                        .foregroundColor(AppTheme.accent)
                        .font(.system(size: 18))
                    
                    Text("Sign Out")
                        .font(AppTypography.body)
                        .foregroundColor(AppTheme.accent)
                    
                    Spacer()
                }
                .padding()
                .background(AppTheme.accent.opacity(0.1))
                .cornerRadius(16)
            }
        }
    }
}

struct UsageRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(AppTypography.captionMedium)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button {
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .environment(AuthService())
}
