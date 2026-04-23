import SwiftUI

struct OnboardingPageIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index == currentStep ? AppTheme.Colors.accentPink : AppTheme.Colors.textTertiary)
                    .frame(width: index == currentStep ? 24 : 8, height: 8)
                    .animation(.snappy, value: currentStep)
            }
        }
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background.ignoresSafeArea()
        VStack(spacing: 20) {
            OnboardingPageIndicator(currentStep: 0, totalSteps: 4)
            OnboardingPageIndicator(currentStep: 1, totalSteps: 4)
            OnboardingPageIndicator(currentStep: 2, totalSteps: 4)
            OnboardingPageIndicator(currentStep: 3, totalSteps: 4)
        }
    }
}
