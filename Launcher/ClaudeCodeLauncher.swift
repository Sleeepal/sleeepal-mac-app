import AppKit

@main
final class ClaudeCodeLauncherApp: NSObject, NSApplicationDelegate {
    private let launchCommand = "~/.local/bin/claude-aigocode"
    private let menuBarApp = NSString(string: "~/Applications/ClaudeCodeMenuBar.app").expandingTildeInPath

    static func main() {
        let app = NSApplication.shared
        let delegate = ClaudeCodeLauncherApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        launchMenuBarIfNeeded()
        launchTerminal()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            NSApp.terminate(nil)
        }
    }

    private func launchMenuBarIfNeeded() {
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: "local.hibot.ClaudeCodeMenuBar")
        if !running.isEmpty {
            return
        }

        let url = URL(fileURLWithPath: menuBarApp)
        if FileManager.default.fileExists(atPath: url.path()) {
            NSWorkspace.shared.openApplication(at: url, configuration: .init(), completionHandler: nil)
        }
    }

    private func launchTerminal() {
        let script = """
        tell application "Terminal"
            activate
            do script "\(escapeForAppleScript(launchCommand))"
        end tell
        """

        var errorInfo: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&errorInfo)
    }

    private func escapeForAppleScript(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
