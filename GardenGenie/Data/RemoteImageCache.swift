import UIKit

/// Loads and caches remote images (plant cut-outs and photos).
///
/// Two layers: decoded images in memory (NSCache, so posters don't flicker when
/// they scroll back into view) and raw responses on disk (URLCache). Cut-out
/// URLs contain a content hash and are served with a one-year max-age, so the
/// disk copy stays valid until the art changes.
final class RemoteImageCache: @unchecked Sendable {
    static let shared = RemoteImageCache()

    private let memory: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.totalCostLimit = 80 * 1024 * 1024
        return cache
    }()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 8 * 1024 * 1024,
            diskCapacity: 250 * 1024 * 1024,
            directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("PlantArt", isDirectory: true)
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 20
        return URLSession(configuration: config)
    }()

    /// Synchronous memory lookup, for a view's first frame.
    func cached(_ url: URL) -> UIImage? {
        memory.object(forKey: url as NSURL)
    }

    /// Memory, then disk, then network. Decodes off the main thread.
    func image(for url: URL) async -> UIImage? {
        if let hit = cached(url) { return hit }
        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode ?? 200 < 400,
                  let image = await UIImage(data: data)?.byPreparingForDisplay()
            else { return nil }
            let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
            memory.setObject(image, forKey: url as NSURL, cost: cost)
            return image
        } catch {
            return nil
        }
    }
}
