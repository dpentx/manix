import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property bool launcherVisible: false
    property int  lastMtime: 0

    // Her ekran için üst bar
    Variants {
        model: Quickshell.screens
        TopBar {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    // Launcher — sadece açıkken yükle, kapanınca bellekten sil
    Loader {
        id: launcherLoader
        active: root.launcherVisible
        sourceComponent: Component {
            LauncherOverlay {
                screen: Quickshell.screens[0]
                visible: true
                onCloseRequested: root.launcherVisible = false
            }
        }
    }

    // Toggle: /tmp/qs-toggle dosyasının mtime'ını 200ms'de bir kontrol et
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: mtimePoller.running = true
    }

    Process {
        id: mtimePoller
        command: ["sh", "-c", "stat -c %Y /tmp/qs-toggle 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = parseInt(text.trim())
                if (t !== 0 && t !== root.lastMtime) {
                    if (root.lastMtime !== 0) {
                        root.launcherVisible = !root.launcherVisible
                    }
                    root.lastMtime = t
                }
            }
        }
    }

    // Başlangıçta dosyayı oluştur
    Process {
        command: ["sh", "-c", "touch /tmp/qs-toggle"]
        running: true
    }
}
