import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "modules"

PanelWindow {
    id: bar

    anchors { top: true; left: true; right: true }

    // Açık panel varsa pencere yüksekliği büyür — tıklamalar ulaşabilir
    implicitHeight: 32 + openPanelHeight

    property int openPanelHeight: {
        if (mediaPanelOpen) return 90
        if (btPanelOpen)   return btPanelCol.implicitHeight + 28
        if (wifiPanelOpen) return wifiPanelCol.implicitHeight + 28
        return 0
    }

    exclusiveZone: 32
    color: "transparent"

    readonly property color clrBase:    "#B01E1E2E"
    readonly property color clrPanel:   "#EE1E1E2E"
    readonly property color clrSurface: "#25FFFFFF"
    readonly property color clrText:    "#CDD6F4"
    readonly property color clrSubtext: "#6C7086"
    readonly property color clrAccent:  "#FAB387"
    readonly property color clrGreen:   "#A6E3A1"

    property bool mediaPanelOpen: false
    property bool btPanelOpen:    false
    property bool wifiPanelOpen:  false

    property bool   btPowered:     false
    property var    btDevices:     []
    property bool   wifiConnected: false
    property string wifiSsid:      ""
    property var    wifiNetworks:  []

    // ─── Process'ler ──────────────────────────────────────────────────────
    Process {
        id: btPoller
        command: ["sh", "-c",
            "echo POWERED:$(bluetoothctl show | grep 'Powered:' | awk '{print $2}');" +
            "bluetoothctl devices Connected | while read _ mac name; do echo DEVICE:$name; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const devs = []
                for (const l of lines) {
                    if (l.startsWith("POWERED:")) bar.btPowered = l.includes("yes")
                    else if (l.startsWith("DEVICE:")) devs.push(l.substring(7))
                }
                bar.btDevices = devs
            }
        }
    }

    Process {
        id: btToggleCmd
        command: ["sh", "-c", bar.btPowered ? "bluetoothctl power off" : "bluetoothctl power on"]
        onRunningChanged: if (!running) btPoller.running = true
    }

    Process {
        id: wifiPoller
        command: ["sh", "-c", "iwgetid -r 2>/dev/null || echo ''"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                bar.wifiSsid = s
                bar.wifiConnected = s.length > 0
            }
        }
    }

    Process {
        id: wifiListPoller
        command: ["sh", "-c",
            "nmcli -t -f SSID,SIGNAL,ACTIVE dev wifi list 2>/dev/null | head -10 | " +
            "while IFS=: read ssid sig active; do " +
            "[ -z \"$ssid\" ] && continue; echo \"${ssid}|${sig}|${active}\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const nets = []
                for (const l of text.trim().split("\n")) {
                    if (!l) continue
                    const p = l.split("|")
                    if (p[0]) nets.push({ ssid: p[0], signal: parseInt(p[1]||0), active: p[2]==="yes" })
                }
                bar.wifiNetworks = nets
            }
        }
    }

    property string wifiConnectTarget: ""
    Process {
        id: wifiConnectCmd
        command: ["sh", "-c", "true"]
        onRunningChanged: if (!running) wifiPoller.running = true
    }

    Process { id: mediaPrev; command: ["playerctl", "previous"] }
    Process { id: mediaPlay; command: ["playerctl", "play-pause"] }
    Process { id: mediaNext; command: ["playerctl", "next"] }

    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: { btPoller.running = true; wifiPoller.running = true }
    }

    // ─── Bar ──────────────────────────────────────────────────────────────
    Rectangle {
        id: barBg
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 32
        color: bar.clrBase

        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 0

            Clock {
                id: clock
                Layout.alignment: Qt.AlignVCenter
                textColor: bar.clrText
                onClicked: {
                    bar.mediaPanelOpen = !bar.mediaPanelOpen
                    bar.btPanelOpen    = false
                    bar.wifiPanelOpen  = false
                }
            }

            Item { Layout.fillWidth: true }

            Workspaces {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                activeColor: bar.clrAccent
                inactiveColor: bar.clrSubtext
            }

            Item { Layout.fillWidth: true }

            // BT butonu
            Rectangle {
                id: btBtn
                width: btBtnLabel.implicitWidth + 16; height: 22; radius: 11
                Layout.alignment: Qt.AlignVCenter
                color: bar.btPowered ? Qt.rgba(0.98,0.70,0.53,0.22) : Qt.rgba(1,1,1,0.07)
                Text {
                    id: btBtnLabel
                    anchors.centerIn: parent
                    text: bar.btPowered && bar.btDevices.length > 0
                          ? "BT " + bar.btDevices.length : "BT"
                    color: bar.btPowered ? bar.clrAccent : bar.clrSubtext
                    font.pixelSize: 10; font.bold: bar.btPowered
                    font.family: "Noto Sans"
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        bar.btPanelOpen    = !bar.btPanelOpen
                        bar.wifiPanelOpen  = false
                        bar.mediaPanelOpen = false
                    }
                }
            }

            Item { width: 6 }

            // WiFi butonu
            Rectangle {
                id: wifiBtn
                width: Math.min(wifiBtnLabel.implicitWidth + 16, 100)
                height: 22; radius: 11
                Layout.alignment: Qt.AlignVCenter
                color: bar.wifiConnected ? Qt.rgba(0.65,0.89,0.63,0.20) : Qt.rgba(1,1,1,0.07)
                Behavior on width { NumberAnimation { duration: 200 } }
                Text {
                    id: wifiBtnLabel
                    anchors.centerIn: parent
                    text: bar.wifiConnected ? bar.wifiSsid : "WiFi"
                    color: bar.wifiConnected ? bar.clrGreen : bar.clrSubtext
                    font.pixelSize: 10; font.bold: bar.wifiConnected
                    font.family: "Noto Sans"
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, 84)
                    horizontalAlignment: Text.AlignHCenter
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        bar.wifiPanelOpen  = !bar.wifiPanelOpen
                        bar.btPanelOpen    = false
                        bar.mediaPanelOpen = false
                        if (bar.wifiPanelOpen) wifiListPoller.running = true
                    }
                }
            }
        }
    }

    // ─── Medya paneli ─────────────────────────────────────────────────────
    Rectangle {
        anchors { top: barBg.bottom; left: parent.left }
        width: 280; height: 86
        radius: 12; color: bar.clrPanel
        visible: bar.mediaPanelOpen

        Rectangle {
            anchors { top: parent.top; left: parent.left }
            width: parent.radius; height: parent.radius; color: parent.color
        }

        Column {
            anchors { fill: parent; margins: 14 }
            spacing: 4

            // Medya yoksa bilgi mesajı
            Text {
                visible: !clock.hasMedia
                text: "Oynatılan içerik yok"
                color: bar.clrSubtext
                font.pixelSize: 12; font.family: "Noto Sans"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                visible: clock.hasMedia
                text: clock.mediaTitle; color: bar.clrText
                font.pixelSize: 13; font.bold: true; font.family: "Noto Sans"
                elide: Text.ElideRight; width: parent.width
            }
            Text {
                visible: clock.hasMedia
                text: clock.mediaArtist; color: bar.clrSubtext
                font.pixelSize: 11; font.family: "Noto Sans"
                elide: Text.ElideRight; width: parent.width
            }

            Row {
                visible: clock.hasMedia
                spacing: 8; anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: [
                        { icon: "⏮", act: 0 },
                        { icon: clock.mediaPlaying ? "⏸" : "▶", act: 1 },
                        { icon: "⏭", act: 2 }
                    ]
                    Rectangle {
                        required property var modelData
                        width: 28; height: 28; radius: 14
                        color: modelData.act === 1 ? bar.clrAccent : bar.clrSurface
                        Text {
                            anchors.centerIn: parent; text: modelData.icon
                            font.pixelSize: 12
                            color: modelData.act === 1 ? "#1E1E2E" : bar.clrText
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if      (modelData.act === 0) mediaPrev.running = true
                                else if (modelData.act === 1) mediaPlay.running = true
                                else                          mediaNext.running = true
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── BT paneli ────────────────────────────────────────────────────────
    Rectangle {
        anchors { top: barBg.bottom; right: parent.right }
        width: 220
        height: btPanelCol.implicitHeight + 24
        radius: 12; color: bar.clrPanel
        visible: bar.btPanelOpen

        Rectangle {
            anchors { top: parent.top; right: parent.right }
            width: parent.radius; height: parent.radius; color: parent.color
        }

        Column {
            id: btPanelCol
            anchors { fill: parent; margins: 14 }
            spacing: 10

            Row {
                spacing: 0; width: parent.width
                Text {
                    text: "Bluetooth"; color: bar.clrText
                    font.pixelSize: 13; font.bold: true; font.family: "Noto Sans"
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 48
                }
                Rectangle {
                    width: 44; height: 24; radius: 12
                    color: bar.btPowered ? bar.clrAccent : bar.clrSurface
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        width: 18; height: 18; radius: 9; color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                        x: bar.btPowered ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: btToggleCmd.running = true
                    }
                }
            }

            Repeater {
                model: bar.btDevices
                Row {
                    spacing: 8
                    Rectangle {
                        width: 6; height: 6; radius: 3; color: bar.clrAccent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: modelData; color: bar.clrSubtext
                        font.pixelSize: 11; font.family: "Noto Sans"
                    }
                }
            }

            Text {
                visible: bar.btDevices.length === 0 && bar.btPowered
                text: "Bağlı cihaz yok"; color: bar.clrSubtext
                font.pixelSize: 11; font.family: "Noto Sans"
            }
            Text {
                visible: !bar.btPowered
                text: "Bluetooth kapalı"; color: bar.clrSubtext
                font.pixelSize: 11; font.family: "Noto Sans"
            }
        }
    }

    // ─── WiFi paneli ──────────────────────────────────────────────────────
    property string wifiPasswordTarget: ""
    property bool   wifiPasswordMode:   false

    Rectangle {
        anchors { top: barBg.bottom; right: parent.right }
        width: 260
        height: wifiPanelCol.implicitHeight + 24
        radius: 12; color: bar.clrPanel
        visible: bar.wifiPanelOpen

        Rectangle {
            anchors { top: parent.top; right: parent.right }
            width: parent.radius; height: parent.radius; color: parent.color
        }

        Column {
            id: wifiPanelCol
            anchors { fill: parent; margins: 14 }
            spacing: 8

            // Başlık
            Row {
                width: parent.width; spacing: 8
                Text {
                    text: bar.wifiPasswordMode ? "Şifre Gir" : "WiFi"
                    color: bar.clrText
                    font.pixelSize: 13; font.bold: true; font.family: "Noto Sans"
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - (bar.wifiPasswordMode ? 28 : 0)
                }
                // Şifre modunda geri butonu
                Rectangle {
                    visible: bar.wifiPasswordMode
                    width: 24; height: 24; radius: 12
                    color: Qt.rgba(1,1,1,0.08)
                    Text { anchors.centerIn: parent; text: "←"; color: bar.clrText; font.pixelSize: 12 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: bar.wifiPasswordMode = false
                    }
                }
            }

            // Şifre giriş modu
            Column {
                visible: bar.wifiPasswordMode
                width: parent.width
                spacing: 8

                Text {
                    text: bar.wifiPasswordTarget
                    color: bar.clrSubtext; font.pixelSize: 11; font.family: "Noto Sans"
                }

                Rectangle {
                    width: parent.width; height: 36; radius: 8
                    color: Qt.rgba(1,1,1,0.08)

                    TextInput {
                        id: wifiPasswordInput
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        color: bar.clrText
                        font.pixelSize: 12; font.family: "Noto Sans"
                        echoMode: TextInput.Password
                        verticalAlignment: TextInput.AlignVCenter

                        Text {
                            anchors.fill: parent
                            text: "Şifre..."
                            color: bar.clrSubtext; font: parent.font
                            visible: parent.text.length === 0
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.onReturnPressed: wifiPasswordConnect()
                    }
                }

                Rectangle {
                    width: parent.width; height: 32; radius: 8
                    color: bar.clrAccent
                    Text {
                        anchors.centerIn: parent
                        text: "Bağlan"; color: "#1E1E2E"
                        font.pixelSize: 12; font.bold: true; font.family: "Noto Sans"
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: wifiPasswordConnect()
                    }
                }
            }

            // Ağ listesi modu
            Column {
                visible: !bar.wifiPasswordMode
                width: parent.width
                spacing: 6

                // Bağlı ağ — üstte öne çıkar
                Rectangle {
                    visible: bar.wifiConnected
                    width: parent.width; height: 36; radius: 8
                    color: Qt.rgba(0.65,0.89,0.63,0.18)

                    Row {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        spacing: 8
                        Rectangle {
                            width: 8; height: 8; radius: 4; color: bar.clrGreen
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: bar.wifiSsid
                            color: bar.clrGreen
                            font.pixelSize: 12; font.bold: true; font.family: "Noto Sans"
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: parent.width - 60
                        }
                        Text {
                            text: "Bağlı"; color: bar.clrGreen
                            font.pixelSize: 10; font.family: "Noto Sans"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Repeater {
                    model: bar.wifiNetworks.filter(n => !n.active)
                    Rectangle {
                        required property var modelData
                        width: wifiPanelCol.width; height: 32; radius: 8
                        color: Qt.rgba(1,1,1,0.05)

                        Row {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 8
                            Text {
                                text: modelData.ssid
                                color: bar.clrText
                                font.pixelSize: 11; font.family: "Noto Sans"
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight; width: parent.width - 44
                            }
                            Text {
                                text: modelData.signal + "%"; color: bar.clrSubtext
                                font.pixelSize: 10; font.family: "Noto Sans"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bar.wifiPasswordTarget = modelData.ssid
                                bar.wifiPasswordMode   = true
                                wifiPasswordInput.text = ""
                                wifiPasswordInput.forceActiveFocus()
                            }
                        }
                    }
                }

                Text {
                    visible: bar.wifiNetworks.length === 0
                    text: "Ağ taranıyor..."; color: bar.clrSubtext
                    font.pixelSize: 11; font.family: "Noto Sans"
                }
            }
        }
    }

    function wifiPasswordConnect() {
        const ssid = bar.wifiPasswordTarget
        const pass = wifiPasswordInput.text
        wifiConnectCmd.command = [
            "sh", "-c",
            "nmcli dev wifi connect '" + ssid + "' password '" + pass + "' &"
        ]
        wifiConnectCmd.running = true
        bar.wifiPasswordMode = false
        bar.wifiPanelOpen    = false
        wifiPoller.running   = true
    }
}
