import AppKit
import ScrollCore

final class ScrollEngine {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
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
                    ScrollTransform.apply(to: event, enabled: true)
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
