import SwiftUI
import AppKit

@main
struct ClaudeCodeMenuBarApp: App {
    @StateObject private var appState = AppState()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(appState)
                .frame(width: 320)
        } label: {
            MenuBarIconView()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState)
                .frame(width: 420, height: 260)
        }
    }
}

struct MenuBarIconView: View {
    var body: some View {
        if let image = NSImage(named: "claude-mascot") {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: 18, height: 18)
        } else {
            Image(systemName: "terminal")
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    enum KeyMode: String {
        case primary = "主 Key"
        case backup = "备用 Key"
        case unknown = "未识别"
    }

    @Published var claudeCLIPath = ""
    @Published var endpoint = "https://api.aigocode.com"
    @Published var keyMode: KeyMode = .unknown
    @Published var lastAction = "就绪"

    private let fileManager = FileManager.default
    private let zshrcPath = NSString(string: "~/.zshrc").expandingTildeInPath
    private let launcherAppPath = NSString(string: "~/Applications/ClaudeCodeLauncher.app").expandingTildeInPath

    init() {
        refreshStatus()
    }

    func refreshStatus() {
        claudeCLIPath = resolveClaudeCLIPath()

        guard let zshrc = try? String(contentsOfFile: zshrcPath, encoding: .utf8) else {
            keyMode = .unknown
            lastAction = "未找到 ~/.zshrc"
            return
        }

        if zshrc.contains("export ANTHROPIC_API_KEY=\"$CLAUDE_CODE_API_KEY_PRIMARY\"") {
            keyMode = .primary
        } else if zshrc.contains("export ANTHROPIC_API_KEY=\"$CLAUDE_CODE_API_KEY_BACKUP\"") {
            keyMode = .backup
        } else {
            keyMode = .unknown
        }
    }

    func launchClaudeCode(using mode: KeyMode? = nil) {
        let command: String
        switch mode {
        case .primary:
            command = "~/.local/bin/claude-aigocode"
        case .backup:
            command = "~/.local/bin/claude-aigocode --backup"
        default:
            command = "~/.local/bin/claude-aigocode"
        }

        let appleScript = """
        tell application "Terminal"
            activate
            do script "\(escapeForAppleScript(command))"
        end tell
        """

        runAppleScript(appleScript)
        lastAction = "已在 Terminal 启动 Claude Code"
    }

    func openLauncherApp() {
        let url = URL(fileURLWithPath: launcherAppPath)
        guard fileManager.fileExists(atPath: url.path()) else {
            lastAction = "未找到 ClaudeCodeLauncher.app"
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: .init(), completionHandler: nil)
        lastAction = "已通过启动器新开 Claude 终端"
    }

    func openShellConfig() {
        NSWorkspace.shared.open(URL(fileURLWithPath: zshrcPath))
        lastAction = "已打开 ~/.zshrc"
    }

    func persistDefaultKey(_ mode: KeyMode) {
        guard mode == .primary || mode == .backup else { return }
        guard var zshrc = try? String(contentsOfFile: zshrcPath, encoding: .utf8) else {
            lastAction = "写入 ~/.zshrc 失败"
            return
        }

        zshrc = zshrc.replacingOccurrences(
            of: "export ANTHROPIC_API_KEY=\"$CLAUDE_CODE_API_KEY_PRIMARY\"",
            with: "export ANTHROPIC_API_KEY=\"$CLAUDE_CODE_API_KEY_\(mode == .primary ? "PRIMARY" : "BACKUP")\""
        )
        zshrc = zshrc.replacingOccurrences(
            of: "export ANTHROPIC_API_KEY=\"$CLAUDE_CODE_API_KEY_BACKUP\"",
            with: "export ANTHROPIC_API_KEY=\"$CLAUDE_CODE_API_KEY_\(mode == .primary ? "PRIMARY" : "BACKUP")\""
        )

        do {
            try zshrc.write(toFile: zshrcPath, atomically: true, encoding: .utf8)
            refreshStatus()
            lastAction = "默认 Key 已切到\(mode.rawValue)"
        } catch {
            lastAction = "写入 ~/.zshrc 失败"
        }
    }

    func revealAppBundle() {
        let appURL = URL(fileURLWithPath: launcherAppPath)
        guard fileManager.fileExists(atPath: appURL.path()) else {
            lastAction = "未找到 ClaudeCodeLauncher.app"
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([appURL])
        lastAction = "已定位 app 包"
    }

    private func resolveClaudeCLIPath() -> String {
        let candidates = [
            "/opt/homebrew/bin/claude",
            NSString(string: "~/.npm-global/bin/claude").expandingTildeInPath,
            NSString(string: "~/.local/bin/claude").expandingTildeInPath,
        ]

        return candidates.first(where: { fileManager.isExecutableFile(atPath: $0) }) ?? "未找到"
    }

    private func runAppleScript(_ script: String) {
        var errorInfo: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&errorInfo)
        if errorInfo != nil {
            lastAction = "执行 AppleScript 失败"
        }
    }

    private func escapeForAppleScript(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Claude Code Shell")
                    .font(.headline)
                Text("CLI: \(appState.claudeCLIPath)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Endpoint: \(appState.endpoint)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("默认 Key: \(appState.keyMode.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("在 Terminal 启动 Claude Code") {
                appState.launchClaudeCode()
            }

            Button("一键新开 Claude 终端") {
                appState.openLauncherApp()
            }

            HStack {
                Button("主 Key 启动") {
                    appState.launchClaudeCode(using: .primary)
                }
                Button("备用 Key 启动") {
                    appState.launchClaudeCode(using: .backup)
                }
            }

            HStack {
                Button("默认切到主 Key") {
                    appState.persistDefaultKey(.primary)
                }
                Button("默认切到备用 Key") {
                    appState.persistDefaultKey(.backup)
                }
            }

            Divider()

            HStack {
                Button("打开 ~/.zshrc") {
                    appState.openShellConfig()
                }
                Button("定位 app 包") {
                    appState.revealAppBundle()
                }
            }

            HStack {
                Button("刷新状态") {
                    appState.refreshStatus()
                }
                Button("退出菜单栏") {
                    NSApp.terminate(nil)
                }
            }

            Text(appState.lastAction)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Claude Code Shell")
                .font(.title3.weight(.semibold))
            Text("这个菜单栏壳只负责从 Terminal 启动 Claude Code，并切换 aigocode 主/备用 key。")
                .foregroundStyle(.secondary)
            Text("当前默认 Key: \(appState.keyMode.rawValue)")
            Text("启动链: ClaudeCodeLauncher -> Terminal -> ~/.local/bin/claude-aigocode")
            Spacer()
        }
        .padding(20)
    }
}
