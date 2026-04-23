import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case features = 1
    case zipCode = 2
    case zoneResult = 3
}

struct OnboardingCoordinator: View {
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    @AppStorage("zip_code") private var zipCode = ""
    @AppStorage("usda_zone") private var usdaZone = ""

    @State private var currentStep: OnboardingStep = .welcome
    @State private var enteredZipCode = ""
    @State private var lookupResult: USDAZoneLookup.ZoneInfo?
    @State private var isLookingUp = false
    @State private var lookupError: String?

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingPageIndicator(
                    currentStep: currentStep.rawValue,
                    totalSteps: OnboardingStep.allCases.count
                )
                .padding(.top, AppTheme.Spacing.lg)

                TabView(selection: $currentStep) {
                    OnboardingWelcomeView(onContinue: advanceToFeatures)
                        .tag(OnboardingStep.welcome)

                    OnboardingFeaturesView(onContinue: advanceToZipCode)
                        .tag(OnboardingStep.features)

                    OnboardingZipCodeView(
                        zipCode: $enteredZipCode,
                        isLookingUp: isLookingUp,
                        lookupError: lookupError,
                        onContinue: lookupZoneAndAdvance
                    )
                    .tag(OnboardingStep.zipCode)

                    OnboardingZoneResultView(
                        zoneInfo: lookupResult,
                        onGetStarted: completeOnboarding
                    )
                    .tag(OnboardingStep.zoneResult)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.snappy(duration: 0.4), value: currentStep)
            }
        }
    }

    private func advanceToFeatures() {
        withAnimation(.snappy) { currentStep = .features }
    }

    private func advanceToZipCode() {
        withAnimation(.snappy) { currentStep = .zipCode }
    }

    private func lookupZoneAndAdvance() {
        lookupError = nil
        isLookingUp = true
        Task {
            defer { isLookingUp = false }
            do {
                let result = try await USDAZoneLookup.zone(for: enteredZipCode)
                lookupResult = result
                zipCode = enteredZipCode
                usdaZone = result.zone
                withAnimation(.snappy) { currentStep = .zoneResult }
            } catch USDAZoneLookupError.notFound {
                lookupError = "We couldn't find that zip code. Double-check and try again."
            } catch {
                lookupError = "Check your connection and try again."
            }
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    OnboardingCoordinator()
}
