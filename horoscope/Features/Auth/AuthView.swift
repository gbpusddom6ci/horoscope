import SwiftUI

struct AuthView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showEmailAuth = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateButtons = false

    var body: some View {
        ZStack {
            AuroraBackdrop(style: .sanctumGlow)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: AuroraSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AuroraColors.auroraMint.opacity(0.3),
                                        AuroraColors.auroraViolet.opacity(0.14),
                                        AuroraColors.auroraRose.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 15,
                                    endRadius: 110
                                )
                            )
                            .frame(width: 200, height: 200)

                        Capsule(style: .continuous)
                            .fill(AuroraGradients.auroraVeil)
                            .frame(width: 220, height: 72)
                            .rotationEffect(.degrees(animateTitle ? -15 : -22))
                            .blur(radius: 24)
                            .opacity(0.46)

                        Capsule(style: .continuous)
                            .fill(AuroraGradients.oracle)
                            .frame(width: 180, height: 56)
                            .rotationEffect(.degrees(animateTitle ? 18 : 10))
                            .blur(radius: 20)
                            .opacity(0.36)

                        AuroraGlyph(kind: .saturn, color: AuroraColors.polarWhite, lineWidth: 2.4)
                            .frame(width: 78, height: 78)
                            .shadow(color: AuroraColors.auroraMint.opacity(0.5), radius: 22)
                            .shadow(color: AuroraColors.auroraViolet.opacity(0.24), radius: 40)
                    }
                    .opacity(animateTitle ? 1 : 0)
                    .scaleEffect(animateTitle ? 1 : 0.5)

                    Text("auth.badge")
                        .font(AuroraTypography.mono(11))
                        .foregroundColor(AuroraColors.textMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AuroraColors.surfaceElevated.opacity(0.72))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(AuroraColors.stroke, lineWidth: 1)
                        )

                    Text(String(localized: "app.brand"))
                        .font(AuroraTypography.hero(44))
                        .foregroundColor(AuroraColors.textPrimary)
                        .opacity(animateTitle ? 1 : 0)
                        .offset(y: animateTitle ? 0 : 20)

                    Text("auth.subtitle")
                        .font(AuroraTypography.body(16))
                        .foregroundColor(AuroraColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(animateSubtitle ? 1 : 0)
                        .offset(y: animateSubtitle ? 0 : 10)

                    featurePreviewStrip
                        .opacity(animateSubtitle ? 1 : 0)
                        .offset(y: animateSubtitle ? 0 : 14)
                }
                .padding(.horizontal, AuroraSpacing.lg)
                .padding(.bottom, AuroraSpacing.xl)

                Spacer()

                LumenCard(accent: AuroraColors.auroraViolet) {
                    VStack(spacing: AuroraSpacing.md) {
                        if showEmailAuth {
                            emailAuthForm
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            mainAuthButtons
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, AuroraSpacing.lg)
                .padding(.bottom, AuroraSpacing.xl)
                .opacity(animateButtons ? 1 : 0)
                .offset(y: animateButtons ? 0 : 30)
            }
        }
        .onAppear {
            if reduceMotion {
                animateTitle = true
                animateSubtitle = true
                animateButtons = true
            } else {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateTitle = true
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                    animateSubtitle = true
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                    animateButtons = true
                }
            }
        }
    }

    // MARK: - Main Auth Buttons

    private var mainAuthButtons: some View {
        VStack(spacing: AuroraSpacing.md) {
            AppleSignInButton {
                Task {
                    await authService.signInWithApple()
                }
            }

            HStack(spacing: AuroraSpacing.md) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, AuroraColors.textMuted.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 0.5)
                Text("auth.or")
                    .font(AuroraTypography.mono(12))
                    .foregroundColor(AuroraColors.textMuted)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AuroraColors.textMuted.opacity(0.3), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 0.5)
            }

            HaloButton(String(localized: "auth.continue_email"), icon: "envelope.fill", style: .secondary) {
                withAnimation(AuroraMotion.spring) {
                    showEmailAuth = true
                }
            }

            if let error = authService.errorMessage {
                Text(error)
                    .font(AuroraTypography.body(13))
                    .foregroundColor(AuroraColors.auroraRose)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Email Auth Form

    private var emailAuthForm: some View {
        VStack(spacing: AuroraSpacing.md) {
            if isSignUp {
                MysticTextField(
                    String(localized: "auth.name"),
                    text: $displayName,
                    icon: "person.fill"
                )
            }

            MysticTextField(
                String(localized: "auth.email"),
                text: $email,
                icon: "envelope.fill"
            )
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)

            MysticTextField(
                String(localized: "auth.password"),
                text: $password,
                icon: "lock.fill",
                isSecure: true
            )

            HaloButton(
                isSignUp ? String(localized: "auth.create_account") : String(localized: "auth.signin"),
                icon: "arrow.right",
                style: .primary
            ) {
                Task {
                    if isSignUp {
                        await authService.signUp(email: email, password: password, displayName: displayName)
                    } else {
                        await authService.signInWithEmail(email: email, password: password)
                    }
                }
            }

            // Toggle sign up / sign in
            Button {
                withAnimation(AuroraMotion.spring) {
                    isSignUp.toggle()
                }
            } label: {
                Text(isSignUp ? "auth.already_have_account" : "auth.create_account")
                    .font(AuroraTypography.body(14))
                    .foregroundColor(AuroraColors.auroraCyan)
            }

            Button {
                withAnimation(AuroraMotion.spring) {
                    showEmailAuth = false
                }
            } label: {
                HStack(spacing: AuroraSpacing.xs) {
                    Image(systemName: "chevron.left")
                    Text("auth.back")
                }
                .font(AuroraTypography.body(14))
                .foregroundColor(AuroraColors.textSecondary)
            }

            if let error = authService.errorMessage {
                Text(error)
                    .font(AuroraTypography.body(13))
                    .foregroundColor(AuroraColors.auroraRose)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var featurePreviewStrip: some View {
        HStack(spacing: AuroraSpacing.sm) {
            featureChip(title: String(localized: "auth.feature.ai"), glyph: .eye, accent: AuroraColors.auroraViolet)
            featureChip(title: String(localized: "auth.feature.tarot"), glyph: .tarot, accent: AuroraColors.auroraRose)
            featureChip(title: String(localized: "auth.feature.dreams"), glyph: .dreamcatcher, accent: AuroraColors.auroraCyan)
            featureChip(title: String(localized: "auth.feature.palm"), systemIcon: "hand.raised.fill", accent: AuroraColors.auroraMint)
        }
    }

    private func featureChip(
        title: String,
        glyph: AuroraGlyphKind? = nil,
        systemIcon: String? = nil,
        accent: Color
    ) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 42, height: 42)

                if let glyph {
                    AuroraGlyph(kind: glyph, color: accent, lineWidth: 1.8)
                        .frame(width: 18, height: 18)
                } else if let systemIcon {
                    Image(systemName: systemIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accent)
                }
            }

            Text(title)
                .font(AuroraTypography.mono(10))
                .foregroundColor(AuroraColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Custom Text Field
struct MysticTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var isSecure: Bool = false

    init(_ placeholder: String, text: Binding<String>, icon: String? = nil, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
    }

    var body: some View {
        AuroraTextField(
            placeholder,
            text: $text,
            icon: icon,
            isSecure: isSecure,
            accent: isSecure ? AuroraColors.auroraRose : AuroraColors.auroraViolet
        )
    }
}

#Preview {
    AuthView()
        .environment(AuthService())
}
