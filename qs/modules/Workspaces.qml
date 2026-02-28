// modules/Workspaces.qml — Niri workspace göstergesi
// niri msg -j workspaces çıktısını parse eder
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Row {
    id: wsWidget
    spacing: 6

    property color activeColor:   "#FAB387"  // Peach
    property color inactiveColor: "#313244"  // Surface

    // Workspace verisi
    property var workspaces: []
    property int focusedId: -1

    // ─── niri IPC polling ─────────────────────────────────────────────────
    Process {
        id: niriPoller
        command: ["niri", "msg", "-j", "workspaces"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    // Sadece mevcut monitördeki workspace'leri göster
                    // ve id + is_focused bilgisini al
                    wsWidget.workspaces = data.map(ws => ({
                        id: ws.id,
                        focused: ws.is_focused,
                        active: ws.is_active
                    }))
                    const fw = data.find(ws => ws.is_focused)
                    wsWidget.focusedId = fw ? fw.id : -1
                } catch (e) {}
            }
        }
    }

    // 1 saniyede bir güncelle
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: niriPoller.running = true
    }

    // ─── Workspace noktaları ──────────────────────────────────────────────
    Repeater {
        model: wsWidget.workspaces

        Rectangle {
            required property var modelData

            // Odaklanmış workspace büyük ve renkli, diğerleri küçük
            width:  modelData.focused ? 20 : 8
            height: 8
            radius: 4
            color:  modelData.focused 
                        ? wsWidget.activeColor 
                        : wsWidget.inactiveColor

            // Genişlik animasyonu
            Behavior on width {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: 200 }
            }

            // Tıklayarak workspace'e geç
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const p = Qt.createQmlObject(
                        `import Quickshell.Io; Process {
                            command: ["niri", "msg", "action", "focus-workspace", "${modelData.id}"]
                            running: true
                        }`, wsWidget
                    )
                }
            }
        }
    }
}
