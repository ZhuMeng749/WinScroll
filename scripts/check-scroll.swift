// Standalone behavioral checks for Macs with Command Line Tools but no XCTest.
import CoreGraphics
import ScrollCore

var checks = 0
func expect<T: Equatable>(_ actual: T, _ expected: T, _ name: String) {
    guard actual == expected else { fatalError("FAIL: \(name), got \(actual), expected \(expected)") }
    checks += 1
}
func wheel() -> CGEvent {
    let event = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2, wheel1: 3, wheel2: -2, wheel3: 0)!
    event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 3.5)
    event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 27)
    return event
}
let event = wheel()
let horizontalFields: [CGEventField] = [.scrollWheelEventDeltaAxis2, .scrollWheelEventPointDeltaAxis2, .scrollWheelEventFixedPtDeltaAxis2]
let horizontal = horizontalFields.map { event.getDoubleValueField($0) }
ScrollTransform.apply(to: event, enabled: true)
expect(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), -3, "vertical lines")
expect(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1), -3.5, "fractional delta")
expect(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1), -27, "point delta")
expect(horizontalFields.map { event.getDoubleValueField($0) }, horizontal, "horizontal preservation")
for field: CGEventField in [.scrollWheelEventIsContinuous, .scrollWheelEventScrollPhase, .scrollWheelEventMomentumPhase] {
    let input = wheel()
    input.setIntegerValueField(field, value: 1)
    ScrollTransform.apply(to: input, enabled: true)
    expect(input.getIntegerValueField(.scrollWheelEventDeltaAxis1), 3, "trackpad / gesture preservation")
    expect(input.getIntegerValueField(.scrollWheelEventPointDeltaAxis1), 27, "trackpad points preservation")
}
let paused = wheel()
ScrollTransform.apply(to: paused, enabled: false)
expect(paused.getIntegerValueField(.scrollWheelEventDeltaAxis1), 3, "pause")
paused.type = .mouseMoved
let nonScrollBefore = paused.getIntegerValueField(.scrollWheelEventDeltaAxis1)
ScrollTransform.apply(to: paused, enabled: true)
expect(paused.getIntegerValueField(.scrollWheelEventDeltaAxis1), nonScrollBefore, "non-scroll event")
for delta: Int32 in [-8, -1, 0, 1, 12] {
    let input = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: delta, wheel2: 0, wheel3: 0)!
    ScrollTransform.apply(to: input, enabled: true)
    expect(input.getIntegerValueField(.scrollWheelEventDeltaAxis1), -Int64(delta), "positive / negative / zero")
}
print("PASS: \(checks) scroll behavior checks")
