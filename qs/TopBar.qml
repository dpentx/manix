import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "modules"

PanelWindow {
    id: bar

    anchors { top: true; left: true; right: true }

    implicitHeight: 32 + panelExtra
    property int panelExtra: {
        if (mediaPanelOpen && clock.hasMedia) return 90
        if (btPanelOpen)   return Math.max(btPanelCol.implicitHeight  + 28, 60)
        if (wifiPanelOpen) return Math.max(wifiPanelCol.implicitHeight + 28, 60)
        return 0
    }
    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    exclusiveZone: 32
    color: "transparent"

    readonly property color clrBase:    "#B01E1E2E"
    readonly property color clrPanel:   "#EE1E1E2E"
    readonly property color clrSurf:    "#22FFFFFF"
    readonly property color clrSurf2:   "#35FFFFFF"
    readonly property color clrText:    "#CDD6F4"
    readonly property color clrSub:     "#A6ADC8"
    readonly property color clrMuted:   "#6C7086"
    readonly property color clrAccent:  "#FAB387"
    readonly property color clrGreen:   "#A6E3A1"
    readonly property color clrRed:     "#F38BA8"
    readonly property color clrBlue:    "#89B4FA"

    property bool mediaPanelOpen: false
    property bool btPanelOpen:    false
    property bool wifiPanelOpen:  false

    // BT state
    property bool   btPowered:  false
    property var    btAllDevices: []    // { name, mac, connected }

    // WiFi state
    property bool   wifiConnected: false
    property string wifiSsid:      ""
    property var    wifiNetworks:  []
    property string wifiPassTarget: ""
    property string wifiPassInput:  ""
    property bool   wifiPassMode:   false

    // ─── Process'ler ──────────────────────────────────────────────────────
    Process {
        id: btPoller
        command: ["sh", "-c",
            "powered=$(bluetoothctl show | grep 'Powered:' | awk '{print $2}'); " +
            "echo \"POWERED:$powered\"; " +
            "bluetoothctl devices | while read _ mac name; do " +
            "  connected=$(bluetoothctl info $mac | grep 'Connected:' | awk '{print $2}'); " +
            "  echo \"DEV:${mac}:${connected}:${name}\"; " +
            "done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const devs = []
                for (const l of lines) {
                    if (l.startsWith("POWERED:"))
                        bar.btPowered = l.includes("yes")
                    else if (l.startsWith("DEV:")) {
                        const p = l.substring(4).split(":")
                        if (p.length >= 3) {
                            const mac  = p[0] + ":" + p[1] + ":" + p[2] + ":" + p[3] + ":" + p[4] + ":" + p[5]
                            const conn = p[6] === "yes"
                            const name = p.slice(7).join(":")
                            if (name) devs.push({ mac, connected: conn, name })
                        }
                    }
                }
                bar.btAllDevices = devs
            }
        }
    }

    Process { id: btToggleCmd; command: ["sh", "-c", bar.btPowered ? "bluetoothctl power off" : "bluetoothctl power on"]; onRunningChanged: if (!running) btPoller.running = true }

    property string btActionCmd: ""
    Process {
        id: btActionExec
        command: ["sh", "-c", bar.btActionCmd || "true"]
        onRunningChanged: if (!running) btDelayTimer.start()
    }
    Timer { id: btDelayTimer; interval: 1200; repeat: false; onTriggered: btPoller.running = true }
    Timer { id: btActionTimer; interval: 50; repeat: false; onTriggered: btActionExec.running = true }

    function btAction(cmd) {
        btActionCmd = cmd
        btActionExec.running = false
        btActionTimer.start()
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
            "nmcli -t -f SSID,SIGNAL,ACTIVE,SECURITY dev wifi list 2>/dev/null | " +
            "awk -F: '!seen[$1]++ && $1!=\"\"' | head -12 | " +
            "while IFS=: read ssid sig active sec rest; do " +
            "echo \"${ssid}|${sig}|${active}|${sec}\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const nets = []
                for (const l of text.trim().split("\n")) {
                    if (!l) continue
                    const p = l.split("|")
                    if (p[0]) nets.push({
                        ssid:     p[0],
                        signal:   parseInt(p[1]||0),
                        active:   p[2] === "yes",
                        secured:  p[3] !== "" && p[3] !== "--"
                    })
                }
                bar.wifiNetworks = nets
            }
        }
    }

    property string wifiConnectTarget: ""
    property string wifiConnectPass:   ""
    Process {
        id: wifiConnectCmd
        command: ["sh", "-c",
            bar.wifiConnectPass !== ""
            ? "nmcli dev wifi connect \"" + bar.wifiConnectTarget + "\" password \"" + bar.wifiConnectPass + "\" &"
            : "nmcli con up \"" + bar.wifiConnectTarget + "\" 2>/dev/null || nmcli dev wifi connect \"" + bar.wifiConnectTarget + "\" &"]
        onRunningChanged: if (!running) { wifiPoller.running = true; bar.wifiPassMode = false; bar.wifiPassInput = "" }
    }

    Process { id: mediaPrev; command: ["playerctl", "previous"] }
    Process { id: mediaPlay; command: ["playerctl", "play-pause"] }
    Process { id: mediaNext; command: ["playerctl", "next"] }

    Timer { id: wifiConnTimer; interval: 60; repeat: false; onTriggered: wifiConnectCmd.running = true }

    Timer {
        interval: 15000; running: true; repeat: true
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
                activeColor:   bar.clrAccent
                inactiveColor: bar.clrMuted
            }

            Item { Layout.fillWidth: true }

            // ── BT butonu ─────────────────────────────────────────────────
            Rectangle {
                width: btBtnRow.implicitWidth + 16; height: 22; radius: 11
                Layout.alignment: Qt.AlignVCenter
                color: bar.btPowered ? Qt.rgba(0.98,0.70,0.53,0.20) : Qt.rgba(1,1,1,0.07)
                Row {
                    id: btBtnRow
                    anchors.centerIn: parent
                    spacing: 4
                    // Nerd font bluetooth ikonu
                    Text {
                        text: "\uf293"   // 󰊓
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: bar.btPowered ? bar.clrAccent : bar.clrMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        visible: bar.btAllDevices.filter(d => d.connected).length > 0
                        text: bar.btAllDevices.filter(d => d.connected).length + ""
                        color: bar.clrAccent; font.pixelSize: 10; font.bold: true
                        font.family: "Noto Sans"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        bar.btPanelOpen    = !bar.btPanelOpen
                        bar.wifiPanelOpen  = false
                        bar.mediaPanelOpen = false
                        if (bar.btPanelOpen) btPoller.running = true
                    }
                }
            }

            Item { width: 6 }

            // ── WiFi butonu ───────────────────────────────────────────────
            Rectangle {
                width: wifiBtnRow.implicitWidth + 16; height: 22; radius: 11
                Layout.alignment: Qt.AlignVCenter
                color: bar.wifiConnected ? Qt.rgba(0.65,0.89,0.63,0.18) : Qt.rgba(1,1,1,0.07)
                Row {
                    id: wifiBtnRow
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        // Nerd font wifi ikonu
                        text: bar.wifiConnected ? "\udb82\udd96" : "\udb82\udd97"  // 󰤖 / 󰤗
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: bar.wifiConnected ? bar.clrGreen : bar.clrMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        visible: bar.wifiConnected
                        text: bar.wifiSsid
                        color: bar.clrGreen; font.pixelSize: 10; font.bold: true
                        font.family: "Noto Sans"
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 80)
                    }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        bar.wifiPanelOpen  = !bar.wifiPanelOpen
                        bar.btPanelOpen    = false
                        bar.mediaPanelOpen = false
                        bar.wifiPassMode   = false
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
        visible: bar.mediaPanelOpen && clock.hasMedia

        Rectangle {
            anchors { top: parent.top; left: parent.left }
            width: parent.radius; height: parent.radius; color: parent.color
        }

        Column {
            anchors { fill: parent; margins: 14 }
            spacing: 4

            Text {
                text: clock.mediaTitle; color: bar.clrText
                font.pixelSize: 13; font.bold: true; font.family: "Noto Sans"
                elide: Text.ElideRight; width: parent.width
            }
            Text {
                text: clock.mediaArtist; color: bar.clrSub
                font.pixelSize: 11; font.family: "Noto Sans"
                elide: Text.ElideRight; width: parent.width
            }

            Row {
                spacing: 8; anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: [
                        { icon: "\uf049", act: 0 },   // 
                        { icon: clock.mediaPlaying ? "\uf04c" : "\uf04b", act: 1 },  //  / 
                        { icon: "\uf050", act: 2 }    // 
                    ]
                    Rectangle {
                        required property var modelData
                        width: 28; height: 28; radius: 14
                        color: modelData.act === 1 ? bar.clrAccent : bar.clrSurf
                        Text {
                            anchors.centerIn: parent; text: modelData.icon
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
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
        width: 250
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

            // Başlık + toggle
            Row {
                width: parent.width
                Text {
                    text: "Bluetooth"; color: bar.clrText
                    font.pixelSize: 13; font.bold: true; font.family: "Noto Sans"
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 52
                }
                Rectangle {
                    width: 44; height: 24; radius: 12
                    color: bar.btPowered ? bar.clrAccent : bar.clrSurf
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

            // Cihaz listesi
            Repeater {
                model: bar.btAllDevices

                Rectangle {
                    required property var modelData
                    width: btPanelCol.width; height: 36; radius: 8
                    color: modelData.connected
                           ? Qt.rgba(0.98,0.70,0.53,0.12)
                           : bar.clrSurf

                    Row {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                        spacing: 6

                        // Bağlantı durumu noktası
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: modelData.connected ? bar.clrAccent : bar.clrMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.name
                            color: modelData.connected ? bar.clrAccent : bar.clrText
                            font.pixelSize: 11; font.family: "Noto Sans"
                            font.bold: modelData.connected
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: parent.width - 6 - 6 - 28*3 - 6*2 - 10
                        }

                        Item { Layout.fillWidth: true; width: 1 }

                        // Bağlan / Bağlantıyı kes
                        Rectangle {
                            width: 26; height: 26; radius: 6
                            color: modelData.connected ? Qt.rgba(0.95,0.24,0.33,0.20) : Qt.rgba(0.65,0.89,0.63,0.18)
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.centerIn: parent
                                text: modelData.connected ? "\uf127" : "\uf293"  // unlink / bluetooth
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: modelData.connected ? bar.clrRed : bar.clrGreen
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.connected) {
                                        btAction("bluetoothctl disconnect " + modelData.mac)
                                    } else {
                                        btAction("bluetoothctl connect " + modelData.mac)
                                    }
                                }
                            }
                        }

                        // Unut
                        Rectangle {
                            width: 26; height: 26; radius: 6
                            color: Qt.rgba(0.95,0.24,0.33,0.12)
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.centerIn: parent
                                text: "\uf1f8"   // trash
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11; color: bar.clrRed
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    btAction("bluetoothctl remove " + modelData.mac)
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: bar.btAllDevices.length === 0 && bar.btPowered
                text: "Eşleşmiş cihaz yok"; color: bar.clrMuted
                font.pixelSize: 11; font.family: "Noto Sans"
            }
            Text {
                visible: !bar.btPowered
                text: "Bluetooth kapalı"; color: bar.clrMuted
                font.pixelSize: 11; font.family: "Noto Sans"
            }
        }
    }

    // ─── WiFi paneli ──────────────────────────────────────────────────────
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

            Text {
                text: "WiFi"; color: bar.clrText
                font.pixelSize: 13; font.bold: true; font.family: "Noto Sans"
            }

            // Şifre giriş modu
            Rectangle {
                width: parent.width
                height: bar.wifiPassMode ? 42 : 0
                visible: bar.wifiPassMode
                radius: 8; color: bar.clrSurf2
                clip: true
                Behavior on height { NumberAnimation { duration: 180 } }

                Row {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 8

                    Text {
                        text: "\uf023"   // lock
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12; color: bar.clrSub
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: wifiPassInput
                        width: parent.width - 28 - 8 - 26 - 8 - 20
                        color: bar.clrText; font.pixelSize: 12; font.family: "Noto Sans"
                        echoMode: TextInput.Password
                        anchors.verticalCenter: parent.verticalCenter
                        onTextChanged: bar.wifiPassInput = text
                        Text {
                            anchors.fill: parent
                            text: "Şifre girin..."
                            color: bar.clrMuted; font: parent.font
                            visible: parent.text.length === 0
                            verticalAlignment: Text.AlignVCenter
                        }
                        Keys.onReturnPressed: connectWithPass()
                    }

                    Rectangle {
                        width: 26; height: 26; radius: 6
                        color: Qt.rgba(0.65,0.89,0.63,0.20)
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent
                            text: "\uf00c"   // check
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11; color: bar.clrGreen
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: connectWithPass()
                        }
                    }
                }
            }

            // Ağ listesi
            Repeater {
                model: bar.wifiNetworks

                Rectangle {
                    required property var modelData
                    width: wifiPanelCol.width; height: 32; radius: 8
                    color: modelData.active
                           ? Qt.rgba(0.65,0.89,0.63,0.15)
                           : Qt.rgba(1,1,1,0.05)

                    Row {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        spacing: 6

                        Text {
                            text: modelData.active ? "\udb82\udd96" : "\udb82\udd91"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: modelData.active ? bar.clrGreen : bar.clrMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.ssid
                            color: modelData.active ? bar.clrGreen : bar.clrText
                            font.pixelSize: 11; font.family: "Noto Sans"
                            font.bold: modelData.active
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: parent.width - 11 - 6 - 30 - 6 - 20
                        }

                        Item { width: 1 }

                        Text {
                            text: modelData.secured ? "\uf023" : "\uf09c"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10; color: bar.clrMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.signal + "%"; color: bar.clrMuted
                            font.pixelSize: 10; font.family: "Noto Sans"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        visible: !modelData.active
                        onClicked: {
                            if (modelData.secured) {
                                bar.wifiPassTarget  = modelData.ssid
                                bar.wifiPassMode    = true
                                bar.wifiConnectTarget = modelData.ssid
                                wifiPassInput.text  = ""
                                wifiPassInput.forceActiveFocus()
                            } else {
                                bar.wifiConnectTarget = modelData.ssid
                                bar.wifiConnectPass   = ""
                                wifiConnTimer.start()
                            }
                        }
                    }
                }
            }

            Text {
                visible: bar.wifiNetworks.length === 0
                text: "Ağ taranıyor..."; color: bar.clrMuted
                font.pixelSize: 11; font.family: "Noto Sans"
            }
        }
    }

    function connectWithPass() {
        bar.wifiConnectPass = bar.wifiPassInput
        wifiConnectCmd.running = false
        wifiConnTimer.start()
    }
}
