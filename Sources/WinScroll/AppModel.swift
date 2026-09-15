import AppKit
import Combine
import ServiceManagement

final class AppModel: ObservableObject {
    @Published var reverseEnabled: Bool {
        didSet { defaults.set(reverseEnabled, forKey: "reverseEnabled"); reconcile() }
    }
    @Published private(set) var trusted = false
    @Published private(set) var running = false
    @Published private(set) var loginEnabled = false
    @Published private(set) var loginNeedsApproval = false
    @Published var errorMessage: String?
    let engine = ScrollEngine()
    private let defaults = UserDefaults.standard
    private var timer: Timer?
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
        return running ? "鼠标滚轮反转中" : "滚轮服务未启动"
    }

    func refresh() {
        let permission = !preview && AXIsProcessTrusted()
        if trusted != permission { trusted = permission }
        let status = SMAppService.mainApp.status
        loginEnabled = status == .enabled
        loginNeedsApproval = status == .requiresApproval
        reconcile()
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
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    func setLogin(_ enabled: Bool) {
        guard !preview else { return }
        guard Bundle.main.bundleURL.path.hasPrefix("/Applications/") else {
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
