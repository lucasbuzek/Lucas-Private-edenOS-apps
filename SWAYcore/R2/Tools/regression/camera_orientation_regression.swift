import Foundation
import ImageIO
@main struct CameraOrientationRegression {
 static func main() {
  precondition(SwayCameraFrameOrientation.exif(rotationAngle:90) == .leftMirrored)
  precondition(SwayCameraFrameOrientation.exif(rotationAngle:0) == .upMirrored)
  precondition(SwayCameraFrameOrientation.exif(rotationAngle:180) == .downMirrored)
  precondition(SwayCameraFrameOrientation.exif(rotationAngle:270) == .rightMirrored)
  precondition(SwayCameraFrameOrientation.exif(rotationAngle:360) == .upMirrored)
  precondition(SwayCameraFrameOrientation.exif(rotationAngle:-90) == .rightMirrored)
  precondition(SwayCameraFrameOrientation.exif(rotationAngle:89) == .leftMirrored)
  precondition(SwayCameraFrameOrientation.exif(rotationAngle:91) == .leftMirrored)
  precondition(SwayCameraFrameOrientation.exif(rotationAngle:.nan) == .leftMirrored)
  print("PASS actual camera EXIF policy: portrait preserved, both landscape orientations, wrap and tilt stable; physical left/right UNKNOWN")
 }
}
