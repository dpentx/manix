import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    PanelWindow {
        id: root

        anchors {
            top: true
            right: true
        }

        margins {
            top: 12
            right: 12
        }

        implicitWidth: content.implicitWidth + 20
        implicitHeight: content.implicitHeight + 12
        color: "transparent"

        // Don't take keyboard/mouse focus, don't reserve screen space
        exclusiveZone: -1
        WlrLayershell.keyboardFocus: WlrLayershell.KeyboardFocus.None
        mask: Region {}

        property int elapsedSeconds: 0
        readonly property string timeText: {
            const m = Math.floor(elapsedSeconds / 60).toString().padStart(2, "0")
            const s = (elapsedSeconds % 60).toString().padStart(2, "0")
            return m + ":" + s
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: root.elapsedSeconds += 1
        }

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: "#1e1e1e"
            border.width: 1
            border.color: "#3a3a3a"
            opacity: 0.92
        }

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                id: dot
                width: 12
                height: 12
                radius: 6
                color: "#e53935"
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.25; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: "REC " + root.timeText
                color: "#f0f0f0"
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
