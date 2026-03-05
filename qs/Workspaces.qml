import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Row {
    id: wsWidget
    spacing: 6

    property color activeColor:   "#E69875"
    property color inactiveColor: "#7A8478"

    property var workspaces: []

    Process {
        id: niriPoller
        command: ["niri", "msg", "-j", "workspaces"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    wsWidget.workspaces = data.map(ws => ({
                        id:      ws.id,
                        focused: ws.is_focused,
                        idx:     ws.idx
                    }))
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 800
        running: true
        repeat: true
        onTriggered: niriPoller.running = true
    }

    // Sabit 5 workspace process — dinamik oluşturma yok
    Process { id: ws1; command: ["niri", "msg", "action", "focus-workspace", "1"] }
    Process { id: ws2; command: ["niri", "msg", "action", "focus-workspace", "2"] }
    Process { id: ws3; command: ["niri", "msg", "action", "focus-workspace", "3"] }
    Process { id: ws4; command: ["niri", "msg", "action", "focus-workspace", "4"] }
    Process { id: ws5; command: ["niri", "msg", "action", "focus-workspace", "5"] }

    function focusWs(idx) {
        if      (idx === 1) ws1.running = true
        else if (idx === 2) ws2.running = true
        else if (idx === 3) ws3.running = true
        else if (idx === 4) ws4.running = true
        else if (idx === 5) ws5.running = true
    }

    Repeater {
        model: wsWidget.workspaces

        Rectangle {
            required property var modelData
            width:  modelData.focused ? 18 : 7
            height: 7
            radius: 3.5
            color:  modelData.focused ? wsWidget.activeColor : wsWidget.inactiveColor

            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation  { duration: 180 } }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    wsWidget.focusWs(modelData.idx)
            }
        }
    }
}
