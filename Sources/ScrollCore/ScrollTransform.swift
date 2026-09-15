import CoreGraphics

/// First release: only discrete physical-wheel events are eligible. Continuous
/// input and gesture/momentum phases are passed through to protect trackpads.
public enum ScrollTransform {
    public enum Outcome: String {
        case disabled, unrelated, preservedContinuous, preservedGesture, reversed, reversedWithHID
    }

    public static var hidCompatibilityAvailable: Bool { HIDScrollBridge.available }

    @discardableResult
    public static func apply(to event: CGEvent, enabled: Bool) -> Outcome {
        apply(to: event, enabled: enabled, hidSnapshot: { HIDScrollBridge.capture(event) })
    }

    // The injectable snapshot lets tests exercise real IOHID payloads without
    // posting synthetic input to the user's desktop.
    @discardableResult
    static func apply(to event: CGEvent, enabled: Bool, hidSnapshot: () -> HIDScrollSnapshot?) -> Outcome {
        guard enabled else { return .disabled }
        guard event.type == .scrollWheel else { return .unrelated }
        guard event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0 else { return .preservedContinuous }
        guard event.getIntegerValueField(.scrollWheelEventScrollPhase) == 0,
              event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0 else { return .preservedGesture }

        // Capture all representations before writing: changing the line delta
        // also changes the point and fixed-point representations in CoreGraphics.
        let lines = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        let fixed = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        let points = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        let hid = hidSnapshot()
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: reversed(lines))
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixed)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: reversed(points))
        hid?.reverse()
        return hid == nil ? .reversed : .reversedWithHID
    }

    private static func reversed(_ value: Int64) -> Int64 {
        value == .min ? .max : -value
    }
}
