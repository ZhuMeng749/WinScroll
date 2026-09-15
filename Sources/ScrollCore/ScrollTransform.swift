import CoreGraphics

/// First release: only discrete physical-wheel events are eligible. Continuous
/// input and gesture/momentum phases are passed through to protect trackpads.
public enum ScrollTransform {
    public static func apply(to event: CGEvent, enabled: Bool) {
        guard enabled,
              event.type == .scrollWheel,
              event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0,
              event.getIntegerValueField(.scrollWheelEventScrollPhase) == 0,
              event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0
        else { return }

        // Capture all representations before writing: changing the line delta
        // also changes the point and fixed-point representations in CoreGraphics.
        let lines = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        let fixed = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        let points = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: reversed(lines))
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixed)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: reversed(points))
    }

    private static func reversed(_ value: Int64) -> Int64 {
        value == .min ? .max : -value
    }
}
