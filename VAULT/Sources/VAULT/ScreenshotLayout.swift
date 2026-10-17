import Foundation
import Vision
import ImageIO
import CoreGraphics

// User-selected image is consumed in memory; only normalized geometry is returned.
struct ReferenceRect: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}
struct LayoutReference: Codable, Equatable {
    var imageAspectRatio: Double
    var textRegions: [ReferenceRect]
}
enum LayoutReferenceError: Error {
    case unsupportedImage
    case inputTooLarge
}
enum ScreenshotLayoutAnalyzer {
    static func analyze(_ imageData: Data) throws -> LayoutReference {
        guard imageData.count > 0, imageData.count <= 12_000_000 else {
            throw LayoutReferenceError.inputTooLarge
        }
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0, width <= 6000, height <= 6000,
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw LayoutReferenceError.unsupportedImage
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        let regions = (request.results ?? []).prefix(120).map { candidate in
            let rect = candidate.boundingBox
            return ReferenceRect(x: rect.minX, y: rect.minY,
                                 width: rect.width, height: rect.height)
        }
        // No recognized string, pixel/image bytes, banking identifiers, or logos are returned.
        return LayoutReference(imageAspectRatio: Double(width) / Double(height),
                               textRegions: regions)
    }
}