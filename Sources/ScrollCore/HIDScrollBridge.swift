import CoreGraphics
import Darwin

/// Some consumers use the IOHID payload attached to a physical CGEvent. The
/// public delta setters do not update it. These SPI symbols are resolved at
/// runtime so their absence does not prevent the app from launching.
enum HIDScrollBridge {
    typealias CopyEvent = @convention(c) (CGEvent) -> Unmanaged<CFTypeRef>?
    typealias ReadValue = @convention(c) (CFTypeRef, UInt32) -> Double
    typealias WriteValue = @convention(c) (CFTypeRef, UInt32, Double) -> Void

    static let verticalField: UInt32 = (6 << 16) | 1
    private static let graphics = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY)
    private static let ioKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY)

    static let copyEvent: CopyEvent? = {
        guard let graphics, let symbol = dlsym(graphics, "CGEventCopyIOHIDEvent") else { return nil }
        return unsafeBitCast(symbol, to: CopyEvent.self)
    }()
    static let readValue: ReadValue? = {
        guard let ioKit, let symbol = dlsym(ioKit, "IOHIDEventGetFloatValue") else { return nil }
        return unsafeBitCast(symbol, to: ReadValue.self)
    }()
    static let writeValue: WriteValue? = {
        guard let ioKit, let symbol = dlsym(ioKit, "IOHIDEventSetFloatValue") else { return nil }
        return unsafeBitCast(symbol, to: WriteValue.self)
    }()

    static var available: Bool { copyEvent != nil && readValue != nil && writeValue != nil }

    static func capture(_ event: CGEvent) -> HIDScrollSnapshot? {
        guard available, let backing = copyEvent?(event)?.takeRetainedValue() else { return nil }
        return HIDScrollSnapshot(backing: backing)
    }
}

struct HIDScrollSnapshot {
    let backing: CFTypeRef
    let vertical: Double

    init?(backing: CFTypeRef) {
        guard let read = HIDScrollBridge.readValue, HIDScrollBridge.writeValue != nil else { return nil }
        self.backing = backing
        vertical = read(backing, HIDScrollBridge.verticalField)
    }

    func reverse() {
        HIDScrollBridge.writeValue?(backing, HIDScrollBridge.verticalField, -vertical)
    }
}
