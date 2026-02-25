import SwiftUI

struct AuthView: View {
    @Environment(AuthService.self) private var authService

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
            StarField(starCount: 150)

            VStack(spacing: 0) {
                Spacer()

                // Logo & Title
                VStack(spacing: MysticSpacing.md) {
                    // Mystic Moon Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        MysticColors.mysticGold.opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)

                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(
                                MysticGradients.goldShimmer
                            )
                            .shadow(color: MysticColors.mysticGold.opacity(0.5), radius: 20)
                    }
                    .opacity(animateTitle ? 1 : 0)
                    .scaleEffect(animateTitle ? 1 : 0.5)

                    GlowingText(
                        "Mystic",
                        font: MysticFonts.title(42),
                        color: MysticColors.mysticGold,
                        glowRadius: 12
                    )
                    .opacity(animateTitle ? 1 : 0)
                    .offset(y: animateTitle ? 0 : 20)

                    Text("Yıldızlarınız size ne söylüyor?")
                        .font(MysticFonts.mystic(18))
                        .foregroundColor(MysticColors.textSecondary)
                        .opacity(animateSubtitle ? 1 : 0)
                        .offset(y: animateSubtitle ? 0 : 10)
                }
                .padding(.bottom, MysticSpacing.xxl)

                Spacer()

                // Auth Buttons
                VStack(spacing: MysticSpacing.md) {
                    if showEmailAuth {
                        emailAuthForm
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        mainAuthButtons
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, MysticSpacing.lg)
                .padding(.bottom, MysticSpacing.xxl)
                .opacity(animateButtons ? 1 : 0)
                .offset(y: animateButtons ? 0 : 30)
            }
        }
        .onAppear {
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

    // MARK: - Main Auth Buttons

    private var mainAuthButtons: some View {
        VStack(spacing: MysticSpacing.md) {
            // Apple Sign In
            AppleSignInButton {
                Task {
                    await authService.signInWithApple()
                }
            }

            // Divider
            HStack {
                Rectangle()
                    .fill(MysticColors.textMuted.opacity(0.3))
                    .frame(height: 1)
                Text("veya")
                    .font(MysticFonts.caption(12))
                    .foregroundColor(MysticColors.textMuted)
                Rectangle()
                    .fill(MysticColors.textMuted.opacity(0.3))
                    .frame(height: 1)
            }

            // Email Sign In
            MysticButton("E-posta ile Giriş Yap", icon: "envelope.fill", style: .secondary) {
                withAnimation(.spring(response: 0.4)) {
                    showEmailAuth = true
                }
            }

            // Error display
            if let error = authService.errorMessage {
                Text(error)
                    .font(MysticFonts.caption(13))
                    .foregroundColor(MysticColors.celestialPink)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Email Auth Form

    private var emailAuthForm: some View {
        VStack(spacing: MysticSpacing.md) {
            if isSignUp {
                MysticTextField(
                    "İsminiz",
                    text: $displayName,
                    icon: "person.fill"
                )
            }

            MysticTextField(
                "E-posta",
                text: $email,
                icon: "envelope.fill"
            )
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)

            MysticTextField(
                "Şifre",
                text: $password,
                icon: "lock.fill",
                isSecure: true
            )

            MysticButton(
                isSignUp ? "Kayıt Ol" : "Giriş Yap",
                icon: "arrow.right",
                style: .primary,
                isLoading: authService.isLoading
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
                withAnimation(.spring(response: 0.3)) {
                    isSignUp.toggle()
                }
            } label: {
                Text(isSignUp ? "Zaten hesabım var" : "Hesap oluştur")
                    .font(MysticFonts.caption(14))
                    .foregroundColor(MysticColors.neonLavender)
            }

            // Back button
            Button {
                withAnimation(.spring(response: 0.4)) {
                    showEmailAuth = false
                }
            } label: {
                HStack(spacing: MysticSpacing.xs) {
                    Image(systemName: "chevron.left")
                    Text("Geri")
                }
                .font(MysticFonts.caption(14))
                .foregroundColor(MysticColors.textSecondary)
            }

            if let error = authService.errorMessage {
                Text(error)
                    .font(MysticFonts.caption(13))
                    .foregroundColor(MysticColors.celestialPink)
                    .multilineTextAlignment(.center)
            }
        }
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
        HStack(spacing: MysticSpacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(MysticColors.textMuted)
                    .frame(width: 24)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(MysticFonts.body(15))
                    .foregroundColor(MysticColors.textPrimary)
            } else {
                TextField(placeholder, text: $text)
                    .font(MysticFonts.body(15))
                    .foregroundColor(MysticColors.textPrimary)
            }
        }
        .padding(.horizontal, MysticSpacing.md)
        .frame(height: 50)
        .background(MysticColors.inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: MysticRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: MysticRadius.md)
                .stroke(MysticColors.cardBorder, lineWidth: 1)
        )
    }
}

#Preview {
    AuthView()
        .environment(AuthService())
}
