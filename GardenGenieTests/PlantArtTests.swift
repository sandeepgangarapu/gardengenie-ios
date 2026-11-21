import UIKit
import XCTest
@testable import GardenGenie

final class PlantArtTests: XCTestCase {

    private let cutoutURL = URL(string: "https://sb.test/plant-art/p/abc.png")!
    private let photoURL = URL(string: "https://img.test/photo.jpg")!
    private let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { _ in }

    // MARK: - What a poster shows

    func testUserCutoutBeatsEverything() {
        let art = PlantArt(cutoutURL: cutoutURL, photoURL: photoURL)
        XCTAssertEqual(PlantArtContent.resolve(art: art, userPhoto: image, userCutout: image), .userCutout(image))
    }

    func testUserPhotoBeatsCatalogArtWhenItHasNoCutout() {
        let art = PlantArt(cutoutURL: cutoutURL, photoURL: photoURL)
        XCTAssertEqual(PlantArtContent.resolve(art: art, userPhoto: image, userCutout: nil), .userPhoto(image))
    }

    func testCatalogCutoutThenPhotoThenSymbol() {
        XCTAssertEqual(PlantArtContent.resolve(art: PlantArt(cutoutURL: cutoutURL, photoURL: photoURL), userPhoto: nil, userCutout: nil),
                       .catalogCutout(cutoutURL))
        XCTAssertEqual(PlantArtContent.resolve(art: PlantArt(photoURL: photoURL), userPhoto: nil, userCutout: nil),
                       .catalogPhoto(photoURL))
        XCTAssertEqual(PlantArtContent.resolve(art: PlantArt(), userPhoto: nil, userCutout: nil), .symbol)
    }

    func testOnlyCatalogArtNeedsACredit() {
        XCTAssertTrue(PlantArtContent.catalogCutout(cutoutURL).needsCredit)
        XCTAssertTrue(PlantArtContent.catalogPhoto(photoURL).needsCredit)
        XCTAssertFalse(PlantArtContent.userPhoto(image).needsCredit)
        XCTAssertFalse(PlantArtContent.symbol.needsCredit)
    }

    // MARK: - Credit line

    func testCreditLineAddsLicenseOnce() {
        XCTAssertEqual(PlantArt(credit: "Photo by David J. Stang", license: "CC BY-SA 4.0").creditLine,
                       "Photo: Photo by David J. Stang · CC BY-SA 4.0")
        // iNaturalist attributions already name the license.
        XCTAssertEqual(PlantArt(credit: "(c) Jane Doe, some rights reserved (CC BY)", license: "CC BY").creditLine,
                       "Photo: (c) Jane Doe, some rights reserved (CC BY)")
        XCTAssertNil(PlantArt(credit: nil, license: "CC0").creditLine)
    }

    // MARK: - Decoding from /catalog

    func testCatalogPlantDecodesArtFields() throws {
        let json = """
        {
          "id": "6f1c2b9e-3c55-4a0e-9d2b-0d6a3e8f7a11",
          "species_slug": "basil", "variety_slug": null, "common_name": "Basil",
          "scientific_name": "Ocimum basilicum", "aliases": [],
          "propagation_methods": [], "companion_plants": [], "avoid_planting_with": [], "sub_varieties": [],
          "source": "llm",
          "image_url": "https://sb.test/plant-art/p/abc.png",
          "photo_url": "https://img.test/photo.jpg",
          "photo_credit": "Photo by David J. Stang",
          "photo_license": "CC BY-SA 4.0",
          "photo_source_url": "https://commons.wikimedia.org/wiki/File:Ocimum_basilicum_8zz.jpg"
        }
        """
        let plant = try JSONDecoder().decode(CatalogPlant.self, from: Data(json.utf8))
        XCTAssertEqual(plant.art.cutoutURL, cutoutURL)
        XCTAssertEqual(plant.art.photoURL, photoURL)
        XCTAssertEqual(plant.art.license, "CC BY-SA 4.0")
        XCTAssertEqual(plant.art.sourceURL?.host, "commons.wikimedia.org")

        let adapted = CatalogPlantAdapter.adapt(plant, variant: nil)
        XCTAssertEqual(adapted.art, plant.art)
    }

    // MARK: - Saved plants pick up new artwork

    @MainActor
    func testRefreshCachedPlantsUpdatesOnlySavedPlants() throws {
        let suite = "PlantArtTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MyGardenStore(userDefaults: defaults)

        let old = try decodePlant(id: "6f1c2b9e-3c55-4a0e-9d2b-0d6a3e8f7a11", imageURL: nil)
        store.cachePlant(old)
        store.add(plantID: old.id)

        let fresh = try decodePlant(id: "6f1c2b9e-3c55-4a0e-9d2b-0d6a3e8f7a11", imageURL: cutoutURL.absoluteString)
        let other = try decodePlant(id: "11111111-2222-3333-4444-555555555555", imageURL: cutoutURL.absoluteString)

        XCTAssertEqual(store.refreshCachedPlants([fresh, other]), 1)
        XCTAssertEqual(store.savedPlants.first?.art.cutoutURL, cutoutURL)
        XCTAssertNil(store.plants[other.id], "plants that aren't cached stay out")
        XCTAssertEqual(store.refreshCachedPlants([fresh]), 0, "no-op when nothing changed")

        // Persisted: a new store over the same defaults sees the artwork.
        XCTAssertEqual(MyGardenStore(userDefaults: defaults).savedPlants.first?.art.cutoutURL, cutoutURL)
    }

    private func decodePlant(id: String, imageURL: String?) throws -> CatalogPlant {
        let image = imageURL.map { "\"\($0)\"" } ?? "null"
        let json = """
        {"id": "\(id)", "species_slug": "basil", "common_name": "Basil", "aliases": [],
         "propagation_methods": [], "companion_plants": [], "avoid_planting_with": [],
         "sub_varieties": [], "source": "llm", "image_url": \(image)}
        """
        return try JSONDecoder().decode(CatalogPlant.self, from: Data(json.utf8))
    }

    func testCatalogPlantWithoutArtFieldsStillDecodes() throws {
        let json = """
        {"id": "6f1c2b9e-3c55-4a0e-9d2b-0d6a3e8f7a11", "species_slug": "basil", "common_name": "Basil",
         "aliases": [], "propagation_methods": [], "companion_plants": [], "avoid_planting_with": [],
         "sub_varieties": [], "source": "llm"}
        """
        let plant = try JSONDecoder().decode(CatalogPlant.self, from: Data(json.utf8))
        XCTAssertEqual(plant.art, PlantArt())
    }
}
