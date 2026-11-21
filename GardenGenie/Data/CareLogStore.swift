import Foundation
import Observation
import UIKit

/// Something the user did for a plant, recorded from the plant page's log bar.
enum CareLogKind: String, Codable, CaseIterable, Hashable {
    case watered, pruned, fertilized, harvested, note, photo

    var title: String {
        switch self {
        case .watered: return "Watered"
        case .pruned: return "Pruned"
        case .fertilized: return "Fertilized"
        case .harvested: return "Harvested"
        case .note: return "Note"
        case .photo: return "Photo added"
        }
    }

    var icon: String {
        switch self {
        case .watered: return "drop.fill"
        case .pruned: return "scissors"
        case .fertilized: return "leaf.fill"
        case .harvested: return "basket.fill"
        case .note: return "note.text"
        case .photo: return "camera.fill"
        }
    }

    /// Fragments of care-task names this action satisfies, so logging
    /// "Watered" can check off a due "Watering" task.
    var taskKeywords: [String] {
        switch self {
        case .watered: return ["water"]
        case .pruned: return ["prun", "pinch", "trim", "deadhead"]
        case .fertilized: return ["fertiliz", "feed"]
        case .harvested: return ["harvest"]
        case .note, .photo: return []
        }
    }
}

struct CareLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let plantID: UUID
    let kind: CareLogKind
    let date: Date
    var note: String?

    init(id: UUID = UUID(), plantID: UUID, kind: CareLogKind, date: Date = .now, note: String? = nil) {
        self.id = id
        self.plantID = plantID
        self.kind = kind
        self.date = date
        self.note = note
    }
}

/// The per-plant care diary, persisted to UserDefaults like the other stores.
@MainActor
@Observable
final class CareLogStore {
    private static let key = "careLog.v1"

    private(set) var entries: [CareLogEntry] = []
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    /// Newest first.
    func entries(for plantID: UUID) -> [CareLogEntry] {
        entries.filter { $0.plantID == plantID }.sorted { $0.date > $1.date }
    }

    @discardableResult
    func add(_ kind: CareLogKind, plantID: UUID, note: String? = nil, date: Date = .now) -> CareLogEntry {
        let entry = CareLogEntry(plantID: plantID, kind: kind, date: date, note: note)
        entries.append(entry)
        persist()
        return entry
    }

    func delete(_ id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
    }

    /// The task a log action should check off: the oldest pending task for the
    /// plant that's due today or earlier and whose name matches the action.
    nonisolated static func matchingTask(
        for kind: CareLogKind,
        plantID: UUID,
        in tasks: [GardenTask],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> GardenTask? {
        let keywords = kind.taskKeywords
        guard !keywords.isEmpty,
              let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        else { return nil }
        return tasks
            .filter { task in
                task.plantID == plantID && !task.isCompleted && task.dueDate < endOfToday
                    && keywords.contains { task.name.lowercased().contains($0) }
            }
            .min { $0.dueDate < $1.dueDate }
    }

    private func load() {
        guard let data = userDefaults.data(forKey: Self.key),
              let decoded = try? JSONDecoder().decode([CareLogEntry].self, from: data) else { return }
        entries = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        userDefaults.set(data, forKey: Self.key)
    }
}

/// The user's own photo of each plant, stored as a JPEG in Application Support
/// and used as the plant's poster.
@MainActor
@Observable
final class PlantPhotoStore {
    /// Bumped on every change so views that read photos re-render.
    private(set) var version = 0

    @ObservationIgnored private var cache: [UUID: UIImage] = [:]
    @ObservationIgnored private var missing: Set<UUID> = []
    private let directory: URL

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PlantPhotos", isDirectory: true)
    }

    func image(for plantID: UUID) -> UIImage? {
        _ = version
        if let cached = cache[plantID] { return cached }
        if missing.contains(plantID) { return nil }
        guard let image = UIImage(contentsOfFile: url(for: plantID).path) else {
            missing.insert(plantID)
            return nil
        }
        cache[plantID] = image
        return image
    }

    /// Saves a picked photo, downscaled so the long edge is at most 1600 px.
    func save(_ data: Data, for plantID: UUID) throws {
        guard let original = UIImage(data: data) else { throw CocoaError(.fileReadCorruptFile) }
        let image = Self.downscaled(original, maxDimension: 1600)
        guard let jpeg = image.jpegData(compressionQuality: 0.82) else { throw CocoaError(.fileWriteUnknown) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try jpeg.write(to: url(for: plantID), options: .atomic)
        cache[plantID] = image
        missing.remove(plantID)
        version += 1
    }

    func remove(for plantID: UUID) {
        try? FileManager.default.removeItem(at: url(for: plantID))
        cache[plantID] = nil
        missing.insert(plantID)
        version += 1
    }

    private func url(for plantID: UUID) -> URL {
        directory.appendingPathComponent("\(plantID.uuidString).jpg")
    }

    private static func downscaled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
