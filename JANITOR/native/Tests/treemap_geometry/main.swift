import Foundation
import CoreGraphics

func close(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a-b) < 0.01 }
let testCases: [[Int64]] = [[1], [1, 1], [1, 2, 3, 4], [99, 1, 1, 1], [0, 0, 3, 7], [1, 1, 1, 1, 1, 1, 1]]
for weights in testCases {
    let canvas = CGRect(x: 0, y: 0, width: 640, height: 320)
    let frames = TreemapLayout.frames(weights: weights, in: canvas)
    assert(frames.count == weights.count)
    let sum = Double(weights.reduce(0, +))
    var area = 0.0
    for (i, frame) in frames.enumerated() {
        assert(frame.minX >= -0.01 && frame.minY >= -0.01)
        assert(frame.maxX <= canvas.maxX + 0.01 && frame.maxY <= canvas.maxY + 0.01)
        let actual = Double(frame.width * frame.height)
        assert(abs(actual / Double(canvas.width * canvas.height) - Double(weights[i]) / sum) < 0.0001)
        area += actual
        for j in 0..<i {
            let intersection = frame.intersection(frames[j])
            assert(intersection.isNull || intersection.width * intersection.height < 0.01)
        }
    }
    assert(close(CGFloat(area), canvas.width * canvas.height))
}
assert(TreemapLayout.frames(weights: [], in: .zero).isEmpty)
print("Treemap geometry: 7 cases PASS (proportional area, bounds, non-overlap, zero-weight handling).")
