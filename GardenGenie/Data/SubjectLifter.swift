import CoreImage
import UIKit
import Vision

/// Cuts the plant out of a photo on-device with Vision's subject lifting (the
/// model behind "Copy Subject" in Photos), so the user's own photos get the same
/// cut-out-on-gradient look as catalog art. The backend does the same for
/// catalog photos with `backend-ios/tools/plant-lift`.
enum SubjectLifter {

    /// The cut-out, cropped to the subject, or nil when there's no clear subject
    /// (a lawn, a hedge filling the frame), in which case callers show the photo.
    static func cutout(from image: UIImage, maxDimension: CGFloat = 1200) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        return await Task.detached(priority: .utility) {
            lift(cgImage, orientation: orientation, maxDimension: maxDimension)
        }.value
    }

    private static func lift(_ cgImage: CGImage, orientation: CGImagePropertyOrientation, maxDimension: CGFloat) -> UIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first, !observation.allInstances.isEmpty else { return nil }
            let instances = observation.allInstances
            guard isClean(observation, instances: instances, handler: handler) else { return nil }

            let buffer = try observation.generateMaskedImage(
                ofInstances: instances, from: handler, croppedToInstancesExtent: true
            )
            var ci = CIImage(cvPixelBuffer: buffer)
            let longest = max(ci.extent.width, ci.extent.height)
            if longest > maxDimension {
                ci = ci.applyingFilter("CILanczosScaleTransform", parameters: [
                    kCIInputScaleKey: maxDimension / longest, kCIInputAspectRatioKey: 1.0,
                ])
            }
            guard let out = CIContext().createCGImage(ci, from: ci.extent) else { return nil }
            return UIImage(cgImage: out)
        } catch {
            return nil
        }
    }

    /// Same idea as the backend's gate, a little looser because it's the user's
    /// own plant: reject only cut-outs that are specks, fill the frame, or run
    /// off most of the photo's border.
    private static func isClean(_ observation: VNInstanceMaskObservation, instances: IndexSet, handler: VNImageRequestHandler) -> Bool {
        guard let mask = try? observation.generateScaledMaskForImage(forInstances: instances, from: handler) else { return false }
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }
        let width = CVPixelBufferGetWidth(mask), height = CVPixelBufferGetHeight(mask)
        let rowBytes = CVPixelBufferGetBytesPerRow(mask)
        guard let base = CVPixelBufferGetBaseAddress(mask), width > 2, height > 2 else { return false }

        var covered = 0, border = 0
        for y in 0..<height {
            let row = base.advanced(by: y * rowBytes).assumingMemoryBound(to: Float32.self)
            let edgeRow = y == 0 || y == height - 1
            for x in 0..<width where row[x] > 0.5 {
                covered += 1
                if edgeRow || x == 0 || x == width - 1 { border += 1 }
            }
        }
        let subject = Double(covered) / Double(width * height)
        let edge = Double(border) / Double(2 * width + 2 * height - 4)
        return subject >= 0.03 && subject <= 0.8 && edge <= 0.25
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
