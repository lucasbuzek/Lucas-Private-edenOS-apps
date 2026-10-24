import Foundation

/// Workout duration derived exclusively from the shared musical transport.
public enum SwayWorkoutTimeline {
    public static func activeSeconds(start: TimeInterval, current: TimeInterval) -> TimeInterval {
        max(0, current - start)
    }

    /// Completion is evaluated at an authored phrase boundary, never by a wall-clock timer.
    public static func isComplete(start: TimeInterval, current: TimeInterval, duration: TimeInterval, completedPhrase: Bool) -> Bool {
        completedPhrase && activeSeconds(start: start, current: current) >= max(0, duration)
    }
}
