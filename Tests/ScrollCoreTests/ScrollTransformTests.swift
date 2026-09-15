import XCTest
import CoreGraphics
@testable import ScrollCore

final class ScrollTransformTests: XCTestCase {
    private func wheel(continuous: Bool = false) -> CGEvent {
        let event = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2, wheel1: 3, wheel2: -2, wheel3: 0)!
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: continuous ? 1 : 0)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 3.5)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 27)
        return event
    }

    func testReversesAllVerticalRepresentationsPreservingHorizontal() {
        let event = wheel()
        let horizontal = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)
        ScrollTransform.apply(to: event, enabled: true)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), -3)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1), -3.5)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1), -27)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis2), horizontal)
    }

    func testTrackpadAndMomentumPassThrough() {
        let continuous = wheel(continuous: true)
        ScrollTransform.apply(to: continuous, enabled: true)
        XCTAssertEqual(continuous.getIntegerValueField(.scrollWheelEventDeltaAxis1), 3)
        for field: CGEventField in [.scrollWheelEventScrollPhase, .scrollWheelEventMomentumPhase] {
            let event = wheel()
            event.setIntegerValueField(field, value: 1)
            ScrollTransform.apply(to: event, enabled: true)
            XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), 3)
        }
    }

    func testDisabledAndNonScrollEventsPassThrough() {
        let event = wheel()
        ScrollTransform.apply(to: event, enabled: false)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), 3)
        event.type = .mouseMoved
        let before = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        ScrollTransform.apply(to: event, enabled: true)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), before)
    }

    func testBothDirectionsAndZero() {
        for delta: Int32 in [-8, -1, 0, 1, 12] {
            let event = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: delta, wheel2: 0, wheel3: 0)!
            ScrollTransform.apply(to: event, enabled: true)
            XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), -Int64(delta))
        }
    }
}
