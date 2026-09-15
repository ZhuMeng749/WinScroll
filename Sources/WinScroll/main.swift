import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var model = AppModel()
    private static let showSettingsNotification = Notification.Name("local.winscroll.showSettings")
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var window: NSWindow?
    private var observation: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // A second copy must open the existing window before it exits. Keep
        // model lazy so that copy never starts another scroll event filter.
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "local.winscroll.app")
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        if let existing = others.first, !CommandLine.arguments.contains("--preview") {
            DistributedNotificationCenter.default().postNotificationName(
                Self.showSettingsNotification, object: String(existing.processIdentifier),
                userInfo: nil, deliverImmediately: true)
            NSApp.terminate(nil)
            return
        }
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(revealSettings), name: Self.showSettingsNotification,
            object: String(ProcessInfo.processInfo.processIdentifier))
        NSApp.setActivationPolicy(.accessory)
        let mainMenu = NSMenu()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "退出 WinScroll", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let item = NSMenuItem(); item.submenu = appMenu; mainMenu.addItem(item); NSApp.mainMenu = mainMenu
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 344, height: 425)
        popover.contentViewController = NSHostingController(rootView: MenuContent(model: model, showDetails: { [weak self] in self?.showWindow() }))
        observation = model.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.updateStatus() }
        }
        updateStatus()
        // Manual launches always show a window. Login launches stay in the
        // menu bar, as indicated by the system's open-application Apple event.
        let launchReason = NSAppleEventManager.shared().currentAppleEvent?
            .paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue
        let backgroundLaunch = launchReason == keyAELaunchedAsLogInItem || launchReason == keyAELaunchedAsServiceItem
        if model.preview || !backgroundLaunch {
            showWindow()
        }
    }

    private func updateStatus() {
        let name = model.running ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle"
        statusItem.button?.image = NSImage(systemSymbolName: name, accessibilityDescription: "WinScroll：\(model.statusTitle)")
        statusItem.button?.toolTip = "WinScroll · \(model.statusTitle)"
    }

    @objc private func togglePopover() {
        if popover.isShown { popover.performClose(nil) }
        else if let button = statusItem.button {
            model.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func revealSettings() { showWindow() }

    func showWindow() {
        popover.performClose(nil)
        if window == nil {
            let panel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 780, height: 610),
                                 styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView], backing: .buffered, defer: false)
            panel.title = "WinScroll · 滚轮反转"
            panel.titlebarAppearsTransparent = true
            panel.isReleasedWhenClosed = false
            panel.contentView = NSHostingView(rootView: SettingsContent(model: model))
            panel.center()
            window = panel
        }
        window?.deminiaturize(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow(); return true
    }
    func applicationWillTerminate(_ notification: Notification) {
        DistributedNotificationCenter.default().removeObserver(self)
        // Do not initialize the model in a duplicate process just to stop it.
        if statusItem != nil { model.shutdown() }
    }
}

let app = NSApplication.shared
if CommandLine.arguments.contains("--status-json") {
    // Read-only support command: never starts an event tap or requests access.
    let data: [String: Any] = [
        "accessibilityGranted": AXIsProcessTrusted(),
        "reverseEnabled": UserDefaults.standard.object(forKey: "reverseEnabled") as? Bool ?? true,
        "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
        "bundlePath": Bundle.main.bundleURL.path
    ]
    let json = try JSONSerialization.data(withJSONObject: data, options: [.sortedKeys])
    print(String(data: json, encoding: .utf8)!)
    exit(0)
}
if let index = CommandLine.arguments.firstIndex(of: "--export-preview"),
   CommandLine.arguments.count > index + 1,
   CommandLine.arguments.contains("--preview") {
    // Render our own view into an offscreen bitmap; no desktop capture required.
    app.setActivationPolicy(.prohibited)
    let model = AppModel()
    let host = NSHostingView(rootView: SettingsContent(model: model))
    let panel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 780, height: 610),
                         styleMask: .borderless, backing: .buffered, defer: false)
    panel.contentView = host
    host.frame = NSRect(x: 0, y: 0, width: 780, height: 610)
    host.layoutSubtreeIfNeeded()
    if let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
        host.cacheDisplay(in: host.bounds, to: bitmap)
        if let png = bitmap.representation(using: .png, properties: [:]) {
            try png.write(to: URL(fileURLWithPath: CommandLine.arguments[index + 1]))
            print("Preview exported")
        }
    }
    model.shutdown()
    exit(0)
}
let delegate = AppDelegate()
app.delegate = delegate
app.run()
