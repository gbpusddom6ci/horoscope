import SwiftUI
import Foundation
import UIKit

struct MainTabView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("selected_main_tab_sellquill") private var selectedTabRawValue = AppTab.home.rawValue
    @State private var selectedTab: AppTab
    @State private var showGenerateForm = false
    @State private var isKeyboardVisible = false

    init() {
        UITabBar.appearance().isHidden = true
        _selectedTab = State(initialValue: .home)
        selectedTabRawValue = AppTab.home.rawValue
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // Wrap in NavigationStack for a modern feeling
                NavigationStack {
                    HomeView()
                }
                .tag(AppTab.home)
                .toolbar(.hidden, for: .tabBar)
                
                NavigationStack {
                    LibraryView()
                }
                .tag(AppTab.library)
                .toolbar(.hidden, for: .tabBar)
                
                NavigationStack {
                    TemplatesView()
                }
                .tag(AppTab.templates)
                .toolbar(.hidden, for: .tabBar)
                
                NavigationStack {
                    SettingsView() // To be renamed AccountView properly later
                }
                .tag(AppTab.account)
                .toolbar(.hidden, for: .tabBar)
            }
            .background(AppTheme.background)

            // Custom Tab Bar Overlay
            if !isKeyboardVisible {
                VStack(spacing: 0) {
                    Spacer()
                    ZStack(alignment: .center) {
                        customTabBar
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24) // Float above bottom edge
                        
                        // Floating Generate Button
                        generateButton
                            .offset(y: -24)
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            selectedTabRawValue = newValue.rawValue
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                isKeyboardVisible = false
            }
        }
        .fullScreenCover(isPresented: $showGenerateForm) {
            GenerateView()
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(.home)
            tabButton(.library)
            
            // Spacer for the center generate button
            Spacer()
                .frame(width: 80)
            
            tabButton(.templates)
            tabButton(.account)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial)
        .cornerRadius(32) // Rounded capsule
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? tab.iconFilled : tab.icon)
                    .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                    .foregroundColor(selectedTab == tab ? AppTheme.primary : Color(uiColor: .tertiaryLabel))
                    .contentTransition(.symbolEffect(.replace))
                    .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                
                Text(tab.title)
                    .font(AppTypography.captionMedium)
                    .foregroundColor(selectedTab == tab ? AppTheme.primary : Color(uiColor: .tertiaryLabel))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var generateButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            showGenerateForm = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: AppTheme.primary.opacity(0.4), radius: 15, x: 0, y: 8)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Tab Configuration
enum AppTab: String, CaseIterable {
    case home
    case library
    case templates
    case account

    var title: String {
        switch self {
        case .home: return "Home"
        case .library: return "Library"
        case .templates: return "Templates"
        case .account: return "Account"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .library: return "square.grid.2x2"
        case .templates: return "doc.on.doc"
        case .account: return "person.crop.circle"
        }
    }

    var iconFilled: String {
        switch self {
        case .home: return "house.fill"
        case .library: return "square.grid.2x2.fill"
        case .templates: return "doc.on.doc.fill"
        case .account: return "person.crop.circle.fill"
        }
    }
}

#Preview {
    MainTabView()
}
