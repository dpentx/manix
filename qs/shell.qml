// shell.qml — Ana giriş noktası
// Quickshell, bu dosyayı otomatik olarak yükler.

pragma Singleton
import QtQuick
import Quickshell

ShellRoot {
    id: root

    // Açık/kapalı durumu tüm bileşenler tarafından paylaşılır
    property bool launcherVisible: false

    // Her ekran için ayrı bir üst bar oluştur
    Variants {
        model: Quickshell.screens

        TopBar {
            required property ShellScreen modelData
            screen: modelData
            onToggleLauncher: root.launcherVisible = !root.launcherVisible
        }
    }

    // Uygulama çekmecesi (tek, birincil ekranda)
    LauncherOverlay {
        id: launcherOverlay
        visible: root.launcherVisible
        screen: Quickshell.screens[0]
        onCloseRequested: root.launcherVisible = false
    }

    // Niri keybinding'den gelen IPC komutlarını dinle
    // Niri config'de: Mod+A { spawn "sh" "-c" "quickshell ipc call launcher toggle"; }
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.launcherVisible = !root.launcherVisible
        }
        function show(): void {
            root.launcherVisible = true
        }
        function hide(): void {
            root.launcherVisible = false
        }
    }
}
