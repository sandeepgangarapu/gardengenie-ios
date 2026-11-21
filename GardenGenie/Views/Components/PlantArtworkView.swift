import SwiftUI

/// The art area of every plant poster: the plant's photo full-bleed, or — while
/// it loads, or when there's no photo — the type-accent gradient with its SF Symbol.
///
/// Fills whatever frame the caller gives it; callers own the size, corner
/// radius, label and overlays.
struct PlantArtworkView: View {
    let accent: Color
    let symbol: String
    let content: PlantArtContent
    var symbolSize: CGFloat = 64
    /// Radius of the gradient, matching each poster's previous look.
    var endRadius: CGFloat = 260

    var body: some View {
        GeometryReader { geo in
            ZStack {
                gradient
                switch content {
                case .userPhoto(let image):
                    fullBleed(image, size: geo.size)
                case .catalogPhoto(let url):
                    RemoteImage(url: url) { image in
                        fullBleed(image, size: geo.size)
                    } placeholder: {
                        symbolView(size: geo.size).opacity(0.35)
                    }
                case .symbol:
                    symbolView(size: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .accessibilityHidden(true)
    }

    private var gradient: some View {
        RadialGradient(
            colors: [accent.opacity(0.65), accent.opacity(0.18), AppTheme.Colors.cardBackground],
            center: .topTrailing,
            startRadius: 10,
            endRadius: endRadius
        )
    }

    private func symbolView(size: CGSize) -> some View {
        Image(systemName: symbol)
            .font(.system(size: symbolSize, weight: .thin))
            .foregroundStyle(accent.opacity(0.6))
            .offset(y: -size.height * 0.06)
    }

    private func fullBleed(_ image: UIImage, size: CGSize) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
    }
}

/// Loads an image through `RemoteImageCache`. Shows a cached image on the first
/// frame (no flicker when scrolling back), otherwise the placeholder, then fades in.
struct RemoteImage<Content: View, Placeholder: View>: View {
    let url: URL
    @ViewBuilder let content: (UIImage) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var loaded: (url: URL, image: UIImage)?

    init(url: URL,
         @ViewBuilder content: @escaping (UIImage) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        if let hit = RemoteImageCache.shared.cached(url) {
            _loaded = State(initialValue: (url, hit))
        }
    }

    var body: some View {
        ZStack {
            if let loaded, loaded.url == url {
                content(loaded.image).transition(.opacity)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            if loaded?.url == url { return }
            guard let image = await RemoteImageCache.shared.image(for: url) else { return }
            withAnimation(.easeOut(duration: 0.25)) { loaded = (url, image) }
        }
    }
}
