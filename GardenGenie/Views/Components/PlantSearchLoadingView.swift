import SwiftUI

/// Animated loading view shown while the backend generates a plant guide.
/// Displays a breathing glow, rotating arc, and cycling micro-copy to keep
/// the user engaged during the ~5–10 s LLM generation window.
struct PlantSearchLoadingView: View {
    let query: String

    // MARK: - Animation state

    @State private var showIcon = false
    @State private var showQueryText = false
    @State private var isPulsing = false
    @State private var arcRotation: Double = 0
    @State private var currentMessageIndex = 0

    private var messages: [String] {
        [
            "Learning about \(query)...",
            "Checking sunlight needs...",
            "Finding companion plants...",
            "Reviewing soil preferences...",
            "Crafting your plant guide...",
            "Almost ready..."
        ]
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer().frame(height: 40)

            // Animated icon with glow + rotating arc
            ZStack {
                glowCircle
                rotatingArc
                leafIcon
            }
            .frame(width: 200, height: 200)

            // Query name
            queryLabel

            // Rotating micro-copy
            statusMessage

            Spacer()
        }
        .onAppear { animateEntrance() }
        .task { await cycleMicroCopy() }
    }

    // MARK: - Glow

    private var glowCircle: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        AppTheme.Colors.accentPink.opacity(0.4),
                        AppTheme.Colors.accentPink.opacity(0.0)
                    ],
                    center: .center,
                    startRadius: 30,
                    endRadius: 120
                )
            )
            .frame(width: 240, height: 240)
            .scaleEffect(isPulsing ? 1.1 : 0.9)
            .animation(
                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
    }

    // MARK: - Rotating arc

    private var rotatingArc: some View {
        Circle()
            .trim(from: 0.05, to: 0.3)
            .stroke(
                AppTheme.Colors.accentPink.opacity(0.3),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .frame(width: 160, height: 160)
            .rotationEffect(.degrees(arcRotation))
            .animation(
                .linear(duration: 4).repeatForever(autoreverses: false),
                value: arcRotation
            )
    }

    // MARK: - Leaf icon

    private var leafIcon: some View {
        Image(systemName: "leaf.circle")
            .font(.system(size: 72, weight: .thin))
            .foregroundStyle(AppTheme.Colors.accentPink.opacity(0.7))
            .scaleEffect(showIcon ? 1.0 : 0.8)
            .opacity(showIcon ? 1.0 : 0.0)
    }

    // MARK: - Query label

    private var queryLabel: some View {
        Text(query)
            .font(.title2.bold())
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .opacity(showQueryText ? 1.0 : 0.0)
            .offset(y: showQueryText ? 0 : 12)
            .padding(.horizontal, AppTheme.Spacing.lg)
    }

    // MARK: - Status message

    private var statusMessage: some View {
        Text(messages[currentMessageIndex])
            .font(.callout)
            .foregroundStyle(AppTheme.Colors.textSecondary)
            .id(currentMessageIndex)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity
            ))
            .animation(.easeInOut(duration: 0.25), value: currentMessageIndex)
    }

    // MARK: - Animation helpers

    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.5)) {
            showIcon = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.5)) {
                showQueryText = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPulsing = true
            arcRotation = 360
        }
    }

    private func cycleMicroCopy() async {
        // Wait a beat before starting to cycle
        try? await Task.sleep(for: .seconds(2.5))

        while !Task.isCancelled {
            let nextIndex = currentMessageIndex + 1
            guard nextIndex < messages.count else { return } // stick on last message
            withAnimation {
                currentMessageIndex = nextIndex
            }
            try? await Task.sleep(for: .seconds(2.5))
        }
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background.ignoresSafeArea()
        PlantSearchLoadingView(query: "Roma tomato")
    }
}
