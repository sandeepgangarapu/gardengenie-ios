import SwiftUI

struct OnboardingZipCodeView: View {
    @Binding var zipCode: String
    let onContinue: () -> Void

    @FocusState private var isFieldFocused: Bool
    @State private var showError = false

    private var isValidZip: Bool {
        zipCode.count == 5 && zipCode.allSatisfy { $0.isNumber }
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "location.circle.fill")
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(AppTheme.Colors.accentBlue)
                .padding(.bottom, AppTheme.Spacing.md)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Where Do You Garden?")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("Enter your zip code so we can determine your USDA hardiness zone and provide tailored recommendations.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(AppTheme.Colors.accentBlue)

                    TextField("", text: $zipCode, prompt: Text("Enter zip code").foregroundStyle(AppTheme.Colors.textTertiary))
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .focused($isFieldFocused)
                        .onChange(of: zipCode) { _, newValue in
                            if newValue.count > 5 {
                                zipCode = String(newValue.prefix(5))
                            }
                            // Filter non-numeric characters
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                zipCode = String(filtered.prefix(5))
                            }
                            showError = false
                        }

                    Image(systemName: isValidZip ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isValidZip ? AppTheme.Colors.secondaryGreen : AppTheme.Colors.textTertiary)
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                        .fill(AppTheme.Colors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                                .strokeBorder(
                                    isFieldFocused ? AppTheme.Colors.accentBlue : Color.white.opacity(0.08),
                                    lineWidth: isFieldFocused ? 2 : 1
                                )
                        )
                )
                .padding(.horizontal, AppTheme.Spacing.lg)

                if showError {
                    Text("Please enter a valid 5-digit US zip code")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.accentPink)
                }
            }

            Spacer()

            Button(action: {
                if isValidZip {
                    onContinue()
                } else {
                    withAnimation(.snappy) { showError = true }
                }
            }) {
                Text("Find My Zone")
                    .pillButton(style: isValidZip ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer().frame(height: AppTheme.Spacing.xl)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFieldFocused = true
            }
        }
    }
}

#Preview {
    @Previewable @State var zip = ""
    ZStack {
        AppTheme.Colors.background.ignoresSafeArea()
        OnboardingZipCodeView(zipCode: $zip, onContinue: {})
    }
}
