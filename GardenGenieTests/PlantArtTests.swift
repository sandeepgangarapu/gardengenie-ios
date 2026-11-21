import UIKit
import XCTest
@testable import GardenGenie

final class PlantArtTests: XCTestCase {

    private let photoURL = URL(string: "https://images.unsplash.com/photo-1?ixid=abc&w=1080")!
    private let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { _ in }

    // MARK: - What a poster shows

    func testUserPhotoBeatsCatalogPhoto() {
        XCTAssertEqual(PlantArtContent.resolve(art: PlantArt(photoURL: photoURL), userPhoto: image), .userPhoto(image))
    }

    func testCatalogPhotoThenSymbol() {
        XCTAssertEqual(PlantArtContent.resolve(art: PlantArt(photoURL: photoURL), userPhoto: nil), .catalogPhoto(photoURL))
        XCTAssertEqual(PlantArtContent.resolve(art: PlantArt(), userPhoto: nil), .symbol)
    }

    func testOnlyCatalogPhotosNeedACredit() {
        XCTAssertTrue(PlantArtContent.catalogPhoto(photoURL).needsCredit)
        XCTAssertFalse(PlantArtContent.userPhoto(image).needsCredit)
        XCTAssertFalse(PlantArtContent.symbol.needsCredit)
    }

    // MARK: - Credit line

    func testUnsplashCreditFollowsTheirFormat() {
        XCTAssertEqual(PlantArt(credit: "Annie Spratt", license: "Unsplash").creditLine,
                       "Photo by Annie Spratt on Unsplash")
    }

    func testOtherCreditsAddTheLicenseOnce() {
        XCTAssertEqual(PlantArt(credit: "Photo by David J. Stang", license: "CC BY-SA 4.0").creditLine,
                       "Photo: Photo by David J. Stang · CC BY-SA 4.0")
        XCTAssertEqual(PlantArt(credit: "(c) Jane Doe, some rights reserved (CC BY)", license: "CC BY").creditLine,
                       "Photo: (c) Jane Doe, some rights reserved (CC BY)")
        XCTAssertNil(PlantArt(credit: nil, license: "Unsplash").creditLine)
    }

    // MARK: - Decoding from /catalog

    func testCatalogPlantDecodesPhotoFields() throws {
        let plant = try decodePlant(id: "6f1c2b9e-3c55-4a0e-9d2b-0d6a3e8f7a11", photoURL: photoURL.absoluteString, extra: """
            , "photo_credit": "Annie Spratt", "photo_license": "Unsplash",
              "photo_source_url": "https://unsplash.com/@anniespratt?utm_source=gardengenie&utm_medium=referral"
            """)
        XCTAssertEqual(plant.art.photoURL, photoURL)
        XCTAssertEqual(plant.art.creditLine, "Photo by Annie Spratt on Unsplash")
        XCTAssertEqual(plant.art.sourceURL?.host, "unsplash.com")
        XCTAssertEqual(CatalogPlantAdapter.adapt(plant, variant: nil).art, plant.art)
    }

    func testCatalogPlantWithoutPhotoFieldsStillDecodes() throws {
        let plant = try decodePlant(id: "6f1c2b9e-3c55-4a0e-9d2b-0d6a3e8f7a11", photoURL: nil)
        XCTAssertEqual(plant.art, PlantArt())
    }

    // MARK: - Saved plants pick up new photos

    @MainActor
    func testRefreshCachedPlantsUpdatesOnlySavedPlants() throws {
        let suite = "PlantArtTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MyGardenStore(userDefaults: defaults)

        let old = try decodePlant(id: "6f1c2b9e-3c55-4a0e-9d2b-0d6a3e8f7a11", photoURL: nil)
        store.cachePlant(old)
        store.add(plantID: old.id)

        let fresh = try decodePlant(id: "6f1c2b9e-3c55-4a0e-9d2b-0d6a3e8f7a11", photoURL: photoURL.absoluteString)
        let other = try decodePlant(id: "11111111-2222-3333-4444-555555555555", photoURL: photoURL.absoluteString)

        XCTAssertEqual(store.refreshCachedPlants([fresh, other]), 1)
        XCTAssertEqual(store.savedPlants.first?.art.photoURL, photoURL)
        XCTAssertNil(store.plants[other.id], "plants that aren't cached stay out")
        XCTAssertEqual(store.refreshCachedPlants([fresh]), 0, "no-op when nothing changed")

        // Persisted: a new store over the same defaults sees the photo.
        XCTAssertEqual(MyGardenStore(userDefaults: defaults).savedPlants.first?.art.photoURL, photoURL)
    }

    private func decodePlant(id: String, photoURL: String?, extra: String = "") throws -> CatalogPlant {
        let photo = photoURL.map { "\"\($0)\"" } ?? "null"
        let json = """
        {"id": "\(id)", "species_slug": "basil", "common_name": "Basil", "aliases": [],
         "propagation_methods": [], "companion_plants": [], "avoid_planting_with": [],
         "sub_varieties": [], "source": "llm", "image_url": null, "photo_url": \(photo)\(extra)}
        """
        return try JSONDecoder().decode(CatalogPlant.self, from: Data(json.utf8))
    }
}
