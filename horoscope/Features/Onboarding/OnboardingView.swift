import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var currentStep = 0
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    
    private let slides = [
        OnboardingSlide(
            id: 0,
            title: "SellQuill AI",
            subtitle: "The ultimate AI assistant for top-tier e-commerce sellers.",
            icon: "sparkles.rectangle.stack.fill",
            color: AppTheme.primary
        ),
        OnboardingSlide(
            id: 1,
            title: "Magic Listings",
            subtitle: "Turn your ideas into best-selling listings in seconds. Stop writing, start selling.",
            icon: "wand.and.stars.inverse",
            color: AppTheme.accent
        ),
        OnboardingSlide(
            id: 2,
            title: "Connect Everywhere",
            subtitle: "Optimized formats for Etsy, Shopify, Amazon, and Social Media at the tap of a button.",
            icon: "cart.fill",
            color: AppTheme.success
        )
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            // Background glowing sparks (simulated with blurred circles)
            ZStack {
                Circle()
                    .fill(slides[currentStep].color.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -200)
                
                Circle()
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: 150, y: 300)
            }
            .animation(.easeInOut(duration: 1.0), value: currentStep)
            
            VStack(spacing: 0) {
                Spacer()
                
                TabView(selection: $currentStep) {
                    ForEach(slides) { slide in
                        SlideView(slide: slide)
                            .tag(slide.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                
                // Progress Bar
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(index == currentStep ? slides[index].color : Color.secondary.opacity(0.3))
                            .frame(width: index == currentStep ? 24 : 8, height: 6)
                            .animation(.spring(), value: currentStep)
                    }
                }
                .padding(.bottom, 32)
                
                if let errorMessage {
                    Text(errorMessage)
                        .font(AppTypography.captionMedium)
                        .foregroundColor(AppTheme.accent)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }

                // Call to action
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    
                    if currentStep < slides.count - 1 {
                        withAnimation {
                            currentStep += 1
                        }
                    } else {
                        Task { await finishOnboarding() }
                    }
                } label: {
                    Text(currentStep < slides.count - 1 ? "Next" : "Start Selling")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            currentStep < slides.count - 1
                            ? LinearGradient(colors: [Color.primary.opacity(0.8), Color.primary.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: currentStep < slides.count - 1 ? .clear : AppTheme.primary.opacity(0.4), radius: 15, x: 0, y: 5)
                }
                .disabled(isSubmitting)
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
    
    private func finishOnboarding() async {
        isSubmitting = true
        errorMessage = nil
        do {
            try await authService.completeOnboarding()
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
        }
    }
}

struct OnboardingSlide: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

struct SlideView: View {
    let slide: OnboardingSlide
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            // 3D-ish Icon presentation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [slide.color.opacity(0.2), slide.color.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: slide.icon)
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [slide.color, slide.color.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: slide.color.opacity(0.4), radius: 10, x: 0, y: 5)
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
            }
            .padding(.bottom, 24)
            
            VStack(spacing: 16) {
                Text(slide.title)
                    .font(AppTypography.titleExtraBold)
                    .foregroundColor(.primary)
                
                Text(slide.subtitle)
                    .premiumText(font: AppTypography.body, color: .secondary, lineSpacing: 6)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AuthService())
}
