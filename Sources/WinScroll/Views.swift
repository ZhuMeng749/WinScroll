import SwiftUI

private let accent = Color(red: 0.19, green: 0.37, blue: 0.94)

struct BrandIcon: View {
    var size: CGFloat = 46
    var body: some View {
        Image(systemName: "computermouse.fill")
            .font(.system(size: size * 0.46, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(LinearGradient(colors: [accent, Color(red: 0.35, green: 0.52, blue: 1)], startPoint: .bottomLeading, endPoint: .topTrailing))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.27))
    }
}

struct StatusLabel: View {
    @ObservedObject var model: AppModel
    var body: some View {
        HStack(spacing: 7) {
            Circle().fill(model.running ? Color.green : Color.orange).frame(width: 7, height: 7)
            Text(model.statusTitle).font(.system(size: 12, weight: .medium))
        }
        .accessibilityElement(children: .combine)
    }
}

struct MenuContent: View {
    @ObservedObject var model: AppModel
    var showDetails: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                BrandIcon(size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text("WinScroll").font(.system(size: 19, weight: .bold))
                    Text("熟悉的滚动，回来了。").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            StatusLabel(model: model)
            Divider()
            Toggle(isOn: $model.reverseEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("鼠标滚轮反转").fontWeight(.medium)
                    Text("将上下滚动方向反转").font(.caption).foregroundStyle(.secondary)
                }
            }.toggleStyle(.switch).tint(accent)
            Label("触控板滚动保持原样", systemImage: "checkmark.shield")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            if !model.trusted {
                Button("设置辅助功能权限…", action: showDetails)
                    .buttonStyle(.borderedProminent).tint(accent)
            }
            Divider()
            Toggle("开机自动启动", isOn: Binding(get: { model.loginEnabled }, set: model.setLogin))
                .toggleStyle(.switch).tint(accent).disabled(model.preview)
            if model.loginNeedsApproval {
                Button("前往系统设置允许启动", action: model.openLoginSettings).font(.caption)
            }
            if let error = model.errorMessage { Text(error).font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true) }
            HStack {
                Button("设置与滚动测试…", action: showDetails).buttonStyle(.plain).foregroundStyle(accent)
                Spacer()
                Button("退出") { NSApp.terminate(nil) }.buttonStyle(.plain).foregroundStyle(.secondary)
            }.font(.system(size: 12))
        }
        .padding(22).frame(width: 344).fixedSize(horizontal: false, vertical: true)
    }
}

struct SettingsContent: View {
    @ObservedObject var model: AppModel
    var body: some View {
        HStack(spacing: 0) {
            sidebar
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("让滚轮，顺手起来。").font(.system(size: 27, weight: .bold))
                            Text("鼠标用熟悉的方向，触控板保留原来的手感。")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("滚动设置", systemImage: "slider.horizontal.3").font(.system(size: 13, weight: .semibold))
                            Spacer()
                            StatusLabel(model: model)
                        }
                        Divider()
                        Toggle(isOn: $model.reverseEnabled) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("鼠标滚轮反转").font(.system(size: 14, weight: .semibold))
                                Text("开启后，上下滚动方向与当前系统设置相反。")
                                    .font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                        }.toggleStyle(.switch).tint(accent)
                        Label("触控板与惯性滚动保持原样", systemImage: "checkmark.shield.fill")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }.card()

                    if !model.trusted {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "hand.raised.fill").foregroundStyle(accent).font(.system(size: 19))
                            VStack(alignment: .leading, spacing: 8) {
                                Text("先给 WinScroll 一个通行证").font(.system(size: 13, weight: .semibold))
                                Text("在「辅助功能」中点 ＋ 添加 WinScroll，并打开开关。授权后会自动生效，仅处理滚轮，不记录输入内容。")
                                    .font(.system(size: 11)).foregroundStyle(.secondary).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                                Button("打开辅助功能设置", action: model.openPermissions)
                                    .buttonStyle(.borderedProminent).tint(accent).controlSize(.small)
                            }
                        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .background(accent.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 14))
                    } else if model.reverseEnabled && !model.running {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("滚轮服务暂未启动，请检查权限或重新打开应用。")
                            Button("重试") { model.engine.stop(); model.refresh() }
                        }.font(.caption).card()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("试试你的滚轮").font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Text("将指针放到下方区域").font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        ScrollView {
                            VStack(spacing: 9) {
                                ForEach(0..<9) { index in
                                    HStack(spacing: 12) {
                                        Text(String(format: "%02d", index + 1)).font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundStyle(accent.opacity(0.7))
                                        Text(index == 0 ? "滚轮向自己拨，查看下面的内容 ↓" : index == 8 ? "到底啦！向外拨滚轮，回到上面 ↑" : "每一次滚动，都跟得上你的习惯。")
                                            .font(.system(size: 11)).foregroundStyle(.secondary)
                                        Spacer()
                                    }.padding(12).background(index % 2 == 0 ? accent.opacity(0.045) : Color.clear).clipShape(RoundedRectangle(cornerRadius: 7))
                                }
                            }
                        }.frame(height: 108)
                            .accessibilityLabel("滚轮测试区域")
                        Text("如果方向已经符合 Windows 习惯，就关闭反转开关。")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                    }.card()

                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("开机自动启动", isOn: Binding(get: { model.loginEnabled }, set: model.setLogin))
                            .toggleStyle(.switch).tint(accent).disabled(model.preview)
                        if model.loginNeedsApproval {
                            Button("前往「登录项」允许 WinScroll", action: model.openLoginSettings)
                        }
                        if let error = model.errorMessage { Text(error).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true) }
                        Text("首次安装：将应用拖到「应用程序」后再开启。")
                            .foregroundStyle(.secondary)
                    }.font(.system(size: 11)).card()
                    Text("兼容说明：第一版针对普通刻度滚轮。平滑滚轮、Magic Mouse 等连续滚动设备可能会被保留，不进行反转。")
                        .font(.system(size: 10)).foregroundStyle(.secondary).lineSpacing(3)
                }.padding(28).padding(.top, 16)
            }.background(Color(nsColor: .windowBackgroundColor))
        }.frame(width: 780, height: 610)
            .preferredColorScheme(.light)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            BrandIcon(size: 56).padding(.bottom, 17)
            Text("WinScroll").font(.system(size: 25, weight: .bold))
            Text("滚轮反转小工具").font(.system(size: 12)).foregroundStyle(.secondary).padding(.top, 7)
            HStack(spacing: 8) {
                Image(systemName: "computermouse")
                Text("滚动与偏好")
            }.font(.system(size: 12, weight: .medium)).foregroundStyle(accent)
                .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                .background(accent.opacity(0.09)).clipShape(RoundedRectangle(cornerRadius: 10)).padding(.top, 35)
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "arrow.up.arrow.down").font(.system(size: 29, weight: .light)).foregroundStyle(accent.opacity(0.7))
                Text("换了电脑，\n不用换习惯。").font(.system(size: 18, weight: .semibold)).lineSpacing(6)
                Text("轻巧 · 本地运行 · 无需联网").font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Divider().padding(.vertical, 22)
            HStack {
                Text("VERSION 1.0.0").font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundStyle(.secondary)
                Spacer()
                Button("退出") { NSApp.terminate(nil) }.buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(.secondary)
            }
        }.padding(24).padding(.top, 30).frame(width: 220)
            .background(Color(red: 0.95, green: 0.96, blue: 0.985))
    }
}

private extension View {
    func card() -> some View {
        self.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.black.opacity(0.045), lineWidth: 1))
    }
}
