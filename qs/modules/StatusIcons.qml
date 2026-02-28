// modules/StatusIcons.qml — Batarya, WiFi, Bluetooth durum göstergeleri
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Row {
    id: statusRow
    spacing: 10

    property color textColor:    "#CDD6F4"
    property color subtextColor: "#A6ADC8"
    property color accentColor:  "#FAB387"

    // ─── Bluetooth ────────────────────────────────────────────────────────
    Text {
        id: btIcon
        anchors.verticalCenter: parent.verticalCenter
        text: "⬡"   // Placeholder — nerd font varsa: ""
        color: btConnected ? statusRow.accentColor : statusRow.subtextColor
        font.pixelSize: 13

        property bool btConnected: false

        Process {
            id: btPoller
            command: ["sh", "-c", "bluetoothctl show | grep -c 'Powered: yes'"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    btIcon.btConnected = parseInt(text.trim()) > 0
                }
            }
        }
    }

    // ─── WiFi ─────────────────────────────────────────────────────────────
    Text {
        id: wifiIcon
        anchors.verticalCenter: parent.verticalCenter
        text: "▲"   // Placeholder — nerd font varsa: "󰖩"
        color: wifiConnected ? statusRow.textColor : statusRow.subtextColor
        font.pixelSize: 11

        property bool wifiConnected: false
        property string ssid: ""

        Process {
            id: wifiPoller
            command: ["sh", "-c", "iwgetid -r 2>/dev/null || echo ''"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    const s = text.trim()
                    wifiIcon.ssid = s
                    wifiIcon.wifiConnected = s.length > 0
                }
            }
        }

        ToolTip.visible: wifiHover.containsMouse && wifiIcon.ssid.length > 0
        ToolTip.text: wifiIcon.ssid
        ToolTip.delay: 500

        MouseArea {
            id: wifiHover
            anchors.fill: parent
            hoverEnabled: true
        }
    }

    // ─── Batarya ──────────────────────────────────────────────────────────
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            id: batteryIcon
            text: {
                const lvl = batteryLevel.value
                if (batteryCharging.value) return "⚡"
                if (lvl >= 80) return "█"
                if (lvl >= 60) return "▓"
                if (lvl >= 40) return "▒"
                if (lvl >= 20) return "░"
                return "▯"
            }
            color: {
                if (batteryCharging.value) return statusRow.accentColor
                if (batteryLevel.value <= 20) return "#F38BA8"   // Red
                return statusRow.textColor
            }
            font.pixelSize: 12
        }

        Text {
            text: batteryLevel.value + "%"
            color: statusRow.textColor
            font.pixelSize: 12
            font.family: "Noto Sans"
        }
    }

    // ─── Batarya polling ──────────────────────────────────────────────────
    QtObject {
        id: batteryLevel
        property int value: 100

        Process {
            command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 100"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: batteryLevel.value = parseInt(text.trim())
            }
        }
    }

    QtObject {
        id: batteryCharging
        property bool value: false

        Process {
            command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo 'Unknown'"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    batteryCharging.value = text.trim() === "Charging"
                }
            }
        }
    }

    // 30 saniyede bir yenile
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            btPoller.running   = true
            wifiPoller.running = true
        }
    }
}
