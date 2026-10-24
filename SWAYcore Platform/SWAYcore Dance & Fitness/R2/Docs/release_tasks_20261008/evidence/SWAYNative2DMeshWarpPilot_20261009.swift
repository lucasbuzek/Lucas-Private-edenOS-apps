import Foundation
import SpriteKit
import simd

func makeJointWarp() -> SKWarpGeometryGrid {
    let grid = SKWarpGeometryGrid(columns: 4, rows: 8)
    var points = (0..<grid.vertexCount).map { grid.destPosition(at: $0) }
    // A non-destructive center-section deformation for an isolated proof.
    let center = grid.vertexCount / 2
    points[center] += SIMD2<Float>(0.04, 0.01)
    return grid.replacingByDestinationPositions(positions: points)
}

func setWarp(on sprite: SKSpriteNode) {
    sprite.warpGeometry = makeJointWarp()
}
