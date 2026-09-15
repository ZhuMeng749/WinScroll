import AppKit
import ScrollCore

final class ScrollEngine {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private(set) var receivedCount = 0
    private(set) var reversedCount = 0
    private(set) var hidReversedCount = 0
    private(set) var lastOutcome: ScrollTransform.Outcome?
    var isRunning: Bool { tap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false }

    func start() -> Bool {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: true)
            return isRunning
        }
        let mask = CGEventMask(1) << CGEventType.scrollWheel.rawValue
        guard let newTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .tailAppendEventTap,
            options: .defaultTap, eventsOfInterest: mask,
            callback: { _, type, event, context in
                guard let context else { return Unmanaged.passUnretained(event) }
                let engine = Unmanaged<ScrollEngine>.fromOpaque(context).takeUnretainedValue()
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let tap = engine.tap { CGEvent.tapEnable(tap: tap, enable: true) }
                } else if type == .scrollWheel {
                    engine.receivedCount += 1
                    let outcome = ScrollTransform.apply(to: event, enabled: true)
                    engine.lastOutcome = outcome
                    if outcome == .reversed || outcome == .reversedWithHID { engine.reversedCount += 1 }
                    if outcome == .reversedWithHID { engine.hidReversedCount += 1 }
                }
                return Unmanaged.passUnretained(event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }
        guard let newSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0) else {
            CFMachPortInvalidate(newTap)
            return false
        }
        tap = newTap
        source = newSource
        receivedCount = 0
        reversedCount = 0
        hidReversedCount = 0
        lastOutcome = nil
        CFRunLoopAddSource(CFRunLoopGetMain(), newSource, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)
        return isRunning
    }

    func stop() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        source = nil
        tap = nil
    }

    deinit { stop() }
}
