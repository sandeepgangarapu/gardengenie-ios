import SwiftUI

/// The art area of every plant poster: the type-accent radial gradient with the
/// plant's cut-out floating on it. Falls back to a full-bleed photo when there's
/// no clean cut-out, and to the SF Symbol when there's no image at all.
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
    /// Share of the height kept clear at the bottom for the poster's label.
    var labelInset: CGFloat = 0.28
    /// Share of the height kept clear at the top (status chip, + button).
    var topInset: CGFloat = 0.17

    var body: some View {
        GeometryReader { geo in
            ZStack {
                gradient
                switch content {
                case .userCutout(let image):
                    FloatingCutout(image: image, size: geo.size, topInset: topInset, labelInset: labelInset)
                case .userPhoto(let image):
                    fullBleed(image, size: geo.size)
                case .catalogCutout(let url):
                    RemoteImage(url: url) { image in
                        FloatingCutout(image: image, size: geo.size, topInset: topInset, labelInset: labelInset)
                    } placeholder: {
                        symbolView(size: geo.size).opacity(0.35)
                    }
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

/// A cut-out centred in the space above the label, with a soft contact shadow
/// so it sits on the card instead of floating in the void.
private struct FloatingCutout: View {
    let image: UIImage
    let size: CGSize
    let topInset: CGFloat
    let labelInset: CGFloat

    var body: some View {
        let frame = fittedFrame
        ZStack(alignment: .topLeading) {
            Ellipse()
                .fill(.black.opacity(0.5))
                .frame(width: frame.width * 0.62, height: max(6, frame.height * 0.07))
                .blur(radius: 7)
                .position(x: frame.midX, y: frame.maxY - 2)
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: frame.width, height: frame.height)
                .shadow(color: .black.opacity(0.45), radius: 10, y: 8)
                .position(x: frame.midX, y: frame.midY)
        }
        .frame(width: size.width, height: size.height)
    }

    /// Aspect-fit between the top chip area and the label, with side margins
    /// so the plant never touches the card edge.
    private var fittedFrame: CGRect {
        let box = CGRect(
            x: size.width * 0.13,
            y: size.height * topInset,
            width: size.width * 0.74,
            height: max(1, size.height * (1 - topInset - labelInset))
        )
        let aspect = image.size.width / max(1, image.size.height)
        var w = box.width, h = box.width / aspect
        if h > box.height { h = box.height; w = box.height * aspect }
        return CGRect(x: box.midX - w / 2, y: box.midY - h / 2, width: w, height: h)
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
