import Foundation
import CoreGraphics

/// Deterministic, area-proportional binary treemap. Pure geometry, with no filesystem access.
enum TreemapLayout {
    static func frames(weights: [Int64], in bounds: CGRect) -> [CGRect] {
        var result = Array(repeating: CGRect.zero, count: weights.count)
        guard bounds.width > 0, bounds.height > 0 else { return result }
        func layout(_ indices: [Int], _ rect: CGRect) {
            guard let first = indices.first, rect.width > 0, rect.height > 0 else { return }
            if indices.count == 1 {
                result[first] = rect
                return
            }
            let total = indices.reduce(0.0) { $0 + Double(max(weights[$1], 0)) }
            guard total > 0 else { return }
            var cut = 1
            var leftWeight = Double(max(weights[first], 0))
            while cut < indices.count - 1 && leftWeight < total / 2 {
                leftWeight += Double(max(weights[indices[cut]], 0))
                cut += 1
            }
            let ratio = CGFloat(min(1, max(0, leftWeight / total)))
            if rect.width >= rect.height {
                let firstWidth = rect.width * ratio
                layout(Array(indices[..<cut]), CGRect(x: rect.minX, y: rect.minY, width: firstWidth, height: rect.height))
                layout(Array(indices[cut...]), CGRect(x: rect.minX + firstWidth, y: rect.minY, width: rect.width - firstWidth, height: rect.height))
            } else {
                let firstHeight = rect.height * ratio
                layout(Array(indices[..<cut]), CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: firstHeight))
                layout(Array(indices[cut...]), CGRect(x: rect.minX, y: rect.minY + firstHeight, width: rect.width, height: rect.height - firstHeight))
            }
        }
        layout(Array(weights.indices), bounds)
        return result
    }
}
