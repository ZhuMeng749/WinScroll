import AppKit
import Combine
import ServiceManagement
import ScrollCore
import Darwin

final class AppModel: ObservableObject {
    @Published var reverseEnabled: Bool {
        didSet { defaults.set(reverseEnabled, forKey: "reverseEnabled"); reconcile() }
    }
    @Published private(set) var trusted = false
    @Published private(set) var running = false
    @Published private(set) var loginEnabled = false
    @Published private(set) var loginNeedsApproval = false
    @Published var errorMessage: String?
    @Published private(set) var receivedCount = 0
    @Published private(set) var reversedCount = 0
    @Published private(set) var hidReversedCount = 0
    @Published private(set) var diagnosticMessage = "等待滚轮输入"
    @Published private(set) var otherScrollApps: [String] = []
    let engine = ScrollEngine()
    private let defaults = UserDefaults.standard
    private var timer: Timer?
    private var lastDiagnosticLine: String?
    // UI verification mode never installs a global event filter or login item.
    let preview = ProcessInfo.processInfo.arguments.contains("--preview")

    init() {
        reverseEnabled = defaults.object(forKey: "reverseEnabled") as? Bool ?? true
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    var statusTitle: String {
        if preview { return "界面预览" }
        if !trusted { return "等待辅助功能授权" }
        if !reverseEnabled { return "已暂停" }
        if !running { return "滚轮服务未启动" }
        return reversedCount > 0 ? "已处理鼠标滚轮" : "服务就绪 · 等待滚轮"
    }

    var installedInApplications: Bool {
        Bundle.main.bundleURL.path.hasPrefix("/Applications/")
    }

    var compatibilityAvailable: Bool { ScrollTransform.hidCompatibilityAvailable }

    func refresh() {
        let permission = !preview && AXIsProcessTrusted()
        if trusted != permission { trusted = permission }
        let status = SMAppService.mainApp.status
        loginEnabled = status == .enabled
        loginNeedsApproval = status == .requiresApproval
        reconcile()
        receivedCount = engine.receivedCount
        reversedCount = engine.reversedCount
        hidReversedCount = engine.hidReversedCount
        switch engine.lastOutcome {
        case .preservedContinuous, .preservedGesture:
            diagnosticMessage = "最近收到连续滚动或触控板手势，已保留原方向。"
        case .reversedWithHID:
            diagnosticMessage = "最近的鼠标滚轮已反转，底层滚动数据已同步。"
        case .reversed:
            diagnosticMessage = "最近的滚轮已反转；此事件没有可同步的底层数据。"
        default:
            diagnosticMessage = running ? "请滚动鼠标中间滚轮，计数会在两秒内更新。" : "服务尚未处理滚轮事件。"
        }
        let knownNames = ["Scroll Reverser", "LinearMouse", "Mos"]
        otherScrollApps = NSWorkspace.shared.runningApplications.compactMap(\.localizedName)
            .filter { knownNames.contains($0) }.sorted()
        if ProcessInfo.processInfo.arguments.contains("--diagnostics") {
            let snapshot: [String: Any] = [
                "accessibilityGranted": trusted, "reverseEnabled": reverseEnabled,
                "serviceRunning": running, "received": receivedCount,
                "reversed": reversedCount, "hidSynchronized": hidReversedCount,
                "lastOutcome": engine.lastOutcome?.rawValue ?? "none"
            ]
            if let data = try? JSONSerialization.data(withJSONObject: snapshot, options: [.sortedKeys]),
               let line = String(data: data, encoding: .utf8), line != lastDiagnosticLine {
                print(line)
                fflush(stdout)
                lastDiagnosticLine = line
            }
        }
    }

    func reconcile() {
        if trusted && reverseEnabled && !preview {
            running = engine.start()
        } else {
            engine.stop()
            running = false
        }
    }

    func openPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    func setLogin(_ enabled: Bool) {
        guard !preview else { return }
        guard installedInApplications else {
            errorMessage = "请先把 WinScroll 拖到「应用程序」，从那里打开后再设置开机启动。"
            return
        }
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            errorMessage = nil
        } catch {
            errorMessage = "开机启动设置失败：\(error.localizedDescription)"
        }
        refresh()
    }

    func openLoginSettings() { SMAppService.openSystemSettingsLoginItems() }
    func shutdown() { timer?.invalidate(); engine.stop() }
}
