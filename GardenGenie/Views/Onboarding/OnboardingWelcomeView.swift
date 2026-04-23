import SwiftUI

struct OnboardingWelcomeView: View {
    let onContinue: () -> Void

    @State private var isAnimating = false
    @State private var showContent = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            ZStack {
                // Pulsing glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.Colors.accentPink.opacity(0.4),
                                AppTheme.Colors.accentPink.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 140, weight: .thin))
                    .foregroundStyle(AppTheme.Colors.accentPink)
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    .opacity(showContent ? 1.0 : 0.0)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("GardenGenie")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("Your personal gardening companion")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)

            Spacer()

            Button(action: onContinue) {
                Text("Let's Grow Together")
                    .pillButton(style: .primary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .opacity(showContent ? 1.0 : 0.0)

            Spacer().frame(height: AppTheme.Spacing.xl)
        }
        .onAppear {
            isAnimating = true
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background.ignoresSafeArea()
        OnboardingWelcomeView(onContinue: {})
    }
}
