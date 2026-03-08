import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property bool   launcherVisible: false
    property int    lastMtime:       0
    property string pendingLaunch:   ""

    // ── Uygulama başlatıcı — Loader dışında, kalıcı ───────────────────────
    Process {
        id: appLauncher
        command: ["sh", "-c", root.pendingLaunch.length > 0 ? root.pendingLaunch : "true"]
    }

    function launchApp(exec, terminal) {
        root.pendingLaunch = terminal
            ? "nohup kitty -- " + exec + " >/dev/null 2>&1 &"
            : "nohup " + exec + " >/dev/null 2>&1 &"
        appLauncher.running = false
        launchTimer.start()
    }

    Timer { id: launchTimer; interval: 80; repeat: false; onTriggered: appLauncher.running = true }

    // ── Ekran başına TopBar ───────────────────────────────────────────────
    Variants {
        model: Quickshell.screens
        TopBar {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    // ── Launcher Loader ───────────────────────────────────────────────────
    Loader {
        id: launcherLoader
        active: root.launcherVisible
        sourceComponent: Component {
            LauncherOverlay {
                screen: Quickshell.screens[0]
                visible: true
                onCloseRequested:           root.launcherVisible = false
                onLaunchRequested: (e, t) => {
                    root.launcherVisible = false
                    root.launchApp(e, t)
                }
            }
        }
    }

    // ── Toggle: mtime polling ─────────────────────────────────────────────
    Timer {
        interval: 200; running: true; repeat: true
        onTriggered: mtimePoller.running = true
    }

    Process {
        id: mtimePoller
        command: ["sh", "-c", "stat -c %Y /tmp/qs-toggle 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = parseInt(text.trim())
                if (t !== 0 && t !== root.lastMtime) {
                    if (root.lastMtime !== 0)
                        root.launcherVisible = !root.launcherVisible
                    root.lastMtime = t
                }
            }
        }
    }

    Process {
        command: ["sh", "-c", "touch /tmp/qs-toggle"]
        running: true
    }
}
