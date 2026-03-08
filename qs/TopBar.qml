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
        if (volPopupOpen)   return 236
        if (mediaPanelOpen) return clock.hasMedia ? 96 : 44
        if (btPanelOpen)    return btPanelCol.implicitHeight   + 28
        if (wifiPanelOpen)  return wifiPanelCol.implicitHeight + 28
        if (wallPanelOpen)  return wallPanelHeight + 28
        return 0
    }
    property int wallPanelHeight: 260
    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    exclusiveZone: 32
    focusable: true
    color: "transparent"

    // ── Everforest ────────────────────────────────────────────────────────
    readonly property color clrBase:   "#CC2D353B"
    readonly property color clrPanel:  "#F02D353B"
    readonly property color clrSurf:   "#404D5660"
    readonly property color clrSurf2:  "#554D5660"
    readonly property color clrText:   "#D3C6AA"
    readonly property color clrSub:    "#9DA9A0"
    readonly property color clrMuted:  "#7A8478"
    readonly property color clrAccent: "#E69875"
    readonly property color clrGreen:  "#A7C080"
    readonly property color clrRed:    "#E67E80"
    readonly property color clrBlue:   "#7FBBB3"

    // State
    property bool mediaPanelOpen: false
    property bool btPanelOpen:    false
    property bool wifiPanelOpen:  false

    property bool   btPowered:    false
    property var    btAllDevices: []

    property bool   wifiEnabled:   true
    property bool   wifiConnected: false
    property string wifiSsid:      ""
    property var    wifiNetworks:  []
    property var    savedSsids:    []
    property string wifiConnectTarget: ""
    property string wifiConnectPass:   ""
    property string wifiPassInput:     ""
    property string wifiPassExpandedSsid: ""

    property int  volume: 50
    property bool muted:  false
    property bool volPopupOpen:  false
    property bool wallPanelOpen:  false

    // ── Process'ler ───────────────────────────────────────────────────────
    Process {
        id: btPoller
        command: ["sh", "-c",
            "echo POWERED:$(bluetoothctl show | grep 'Powered:' | awk '{print $2}');" +
            "bluetoothctl devices | while read _ mac name; do " +
            "  conn=$(bluetoothctl info $mac | grep 'Connected:' | awk '{print $2}'); " +
            "  echo \"DEV:${mac}:${conn}:${name}\"; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const devs = []
                for (const l of lines) {
                    if (l.startsWith("POWERED:")) bar.btPowered = l.includes("yes")
                    else if (l.startsWith("DEV:")) {
                        const p = l.substring(4).split(":")
                        if (p.length >= 7) {
                            const mac  = p.slice(0,6).join(":")
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

    readonly property string btToggleShCmd: bar.btPowered
        ? "bluetoothctl power off" : "bluetoothctl power on"
    Process { id: btToggleCmd; command: ["sh","-c", bar.btToggleShCmd]; onRunningChanged: if (!running) btPoller.running = true }

    property string btActionCmd: ""
    Process {
        id: btActionExec
        command: ["sh", "-c", bar.btActionCmd || "true"]
        onRunningChanged: if (!running) btDelayTimer.start()
    }
    Timer { id: btDelayTimer;  interval: 1200; repeat: false; onTriggered: btPoller.running = true }
    Timer { id: btActionTimer; interval: 50;   repeat: false; onTriggered: btActionExec.running = true }
    function btAction(cmd) { btActionCmd = cmd; btActionExec.running = false; btActionTimer.start() }

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
        id: wifiStatusPoller
        command: ["sh", "-c", "nmcli radio wifi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: bar.wifiEnabled = text.trim() === "enabled"
        }
    }

    readonly property string wifiToggleShCmd: bar.wifiEnabled
        ? "nmcli radio wifi off" : "nmcli radio wifi on"
    Process {
        id: wifiToggleCmd
        command: ["sh", "-c", bar.wifiToggleShCmd]
        onRunningChanged: if (!running) { wifiPoller.running = true; wifiStatusPoller.running = true }
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
                    if (p[0]) nets.push({ ssid:p[0], signal:parseInt(p[1]||0), active:p[2]==="yes", secured:p[3]!==""&&p[3]!=="--" })
                }
                bar.wifiNetworks = nets
                savedNetPoller.running = true
            }
        }
    }

    Process {
        id: savedNetPoller
        command: ["sh", "-c", "nmcli -t -f NAME con show 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                bar.savedSsids = text.trim().split("\n").map(s => s.trim()).filter(s => s)
            }
        }
    }

    readonly property string wifiConnShCmd:
        bar.wifiConnectPass !== ""
        ? "nmcli dev wifi connect \"" + bar.wifiConnectTarget + "\" password \"" + bar.wifiConnectPass + "\" &"
        : "nmcli con up \"" + bar.wifiConnectTarget + "\" 2>/dev/null || nmcli dev wifi connect \"" + bar.wifiConnectTarget + "\" &"
    Process {
        id: wifiConnectCmd
        command: ["sh", "-c", bar.wifiConnShCmd]
        onRunningChanged: if (!running) { wifiPoller.running = true; bar.wifiPassInput = ""; bar.wifiPassExpandedSsid = "" }
    }
    Timer { id: wifiConnTimer; interval: 60; repeat: false; onTriggered: wifiConnectCmd.running = true }
    Timer { id: inlinePassTimer; interval: 200; repeat: false; onTriggered: {} }

    Process {
        id: volPoller
        command: ["sh", "-c", "pamixer --get-volume; pamixer --get-mute"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                bar.volume = parseInt(lines[0]) || 0
                bar.muted  = lines[1] === "true"
            }
        }
    }
    Process { id: volMuteCmd; command: ["pamixer","--toggle-mute"];   onRunningChanged: if (!running) volPoller.running = true }
    Process { id: volUpCmd;   command: ["pamixer","--increase","5"];  onRunningChanged: if (!running) volPoller.running = true }
    Process { id: volDownCmd; command: ["pamixer","--decrease","5"];  onRunningChanged: if (!running) volPoller.running = true }

    property int volSetTarget: 50
    Process {
        id: volSetCmd
        command: ["sh", "-c", "pamixer --set-volume " + bar.volSetTarget]
        onRunningChanged: if (!running) volPoller.running = true
    }
    Timer { id: volSetTimer; interval: 30; repeat: false; onTriggered: volSetCmd.running = true }

    Process { id: mediaPrev; command: ["playerctl", "previous"] }
    Process { id: mediaPlay; command: ["playerctl", "play-pause"] }
    Process { id: mediaNext; command: ["playerctl", "next"] }

    // ── Wallhaven ─────────────────────────────────────────────────────────
    property string wallQuery:   "nature"
    property string wallSorting: "toplist"
    property bool   wallLoading: false
    property var    wallResults: []
    property string wallApiKey:  ""   // opsiyonel

    Process {
        id: wallFetcher
        property string fetchUrl: ""
        command: ["sh", "-c", "curl -sL '" + wallFetcher.fetchUrl + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                bar.wallLoading = false
                try {
                    const d = JSON.parse(text)
                    if (d.data) bar.wallResults = d.data.slice(0,12).map(w => ({
                        id: w.id, thumb: w.thumbs.small, full: w.path
                    }))
                } catch(e) { bar.wallResults = [] }
            }
        }
    }
    Timer { id: wallFetchTimer; interval: 50; repeat: false; onTriggered: wallFetcher.running = true }

    function wallSearch() {
        bar.wallLoading = true
        bar.wallResults = []
        const key = bar.wallApiKey !== "" ? "&apikey=" + bar.wallApiKey : ""
        wallFetcher.fetchUrl = "https://wallhaven.cc/api/v1/search?q=" +
            encodeURIComponent(bar.wallQuery) +
            "&sorting=" + bar.wallSorting + "&atleast=1920x1080" + key
        wallFetcher.running = false
        wallFetchTimer.start()
    }

    property string wallApplyTarget: ""
    readonly property string wallApplyCmd:
        "curl -sL '" + bar.wallApplyTarget + "' -o /tmp/qs-wall.jpg && " +
        "pkill swaybg; swaybg -m fill -i /tmp/qs-wall.jpg &"
    Process {
        id: wallApplyProc
        command: ["sh", "-c", bar.wallApplyCmd]
    }
    Timer { id: wallApplyTimer; interval: 50; repeat: false; onTriggered: wallApplyProc.running = true }
    function wallApply(url) {
        bar.wallApplyTarget = url
        wallApplyProc.running = false
        wallApplyTimer.start()
    }

    Timer {
        interval: 15000; running: true; repeat: true
        onTriggered: { btPoller.running = true; wifiPoller.running = true; volPoller.running = true }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ── One UI Bar ─────────────────────────────────────────────────────────
    // ═══════════════════════════════════════════════════════════════════════
    Rectangle {
        id: barBg
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 32
        color: bar.clrBase

        RowLayout {
            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
            spacing: 0

            // ── Sol: Saat + Tarih ─────────────────────────────────────────
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

            // ── Orta: Workspace noktaları ─────────────────────────────────
            Workspaces {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                activeColor:   bar.clrAccent
                inactiveColor: bar.clrMuted
            }

            Item { Layout.fillWidth: true }

            // ── Sağ: İkonlar — One UI tarzı düz, minimal ─────────────────
            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 14

                // Volume ikon — tıkla popup aç, scroll ile değiştir
                Text {
                    id: volIcon
                    anchors.verticalCenter: parent.verticalCenter
                    text: bar.muted ? "\uf026" : bar.volume > 60 ? "\uf028" : bar.volume > 20 ? "\uf027" : "\uf026"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: bar.muted ? bar.clrRed : bar.volPopupOpen ? bar.clrAccent : bar.clrSub
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            bar.volPopupOpen   = !bar.volPopupOpen
                            bar.btPanelOpen    = false
                            bar.wifiPanelOpen  = false
                            bar.mediaPanelOpen = false
                        }
                        onWheel: function(wheel) {
                            if (wheel.angleDelta.y > 0) volUpCmd.running = true
                            else volDownCmd.running = true
                        }
                    }
                }

                // BT ikon
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf293"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: bar.btPowered
                        ? (bar.btAllDevices.filter(d => d.connected).length > 0 ? bar.clrBlue : bar.clrSub)
                        : bar.clrMuted
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            bar.btPanelOpen    = !bar.btPanelOpen
                            bar.wifiPanelOpen  = false
                            bar.mediaPanelOpen = false
                            bar.volPopupOpen   = false
                            if (bar.btPanelOpen) btPoller.running = true
                        }
                    }
                }

                // WiFi ikon
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf1eb"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: bar.wifiConnected ? bar.clrGreen : bar.clrMuted
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            bar.wifiPanelOpen  = !bar.wifiPanelOpen
                            bar.btPanelOpen    = false
                            bar.mediaPanelOpen = false
                            bar.volPopupOpen   = false
                            bar.wallPanelOpen  = false
                            bar.wifiPassExpandedSsid = ""
                            if (bar.wifiPanelOpen) wifiListPoller.running = true
                        }
                    }
                }

                // Wallpaper ikon
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf03e"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: bar.wallPanelOpen ? bar.clrAccent : bar.clrMuted
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            bar.wallPanelOpen  = !bar.wallPanelOpen
                            bar.wifiPanelOpen  = false
                            bar.btPanelOpen    = false
                            bar.mediaPanelOpen = false
                            bar.volPopupOpen   = false
                            if (bar.wallPanelOpen && bar.wallResults.length === 0)
                                bar.wallSearch()
                        }
                    }
                }
            }
        }
    }

    // ── Volume popup — One UI pill ──────────────────────────────────────
    Rectangle {
        id: volPopup
        visible: bar.volPopupOpen

        anchors.right:       barBg.right
        anchors.rightMargin: 16
        anchors.top:         barBg.bottom
        anchors.topMargin:   8

        width:  56
        height: 228
        radius: 28
        color:  "#F0333C43"   // Everforest surface, koyu ve opak

        // ── Üç nokta ────────────────────────────────────────────────────
        Row {
            anchors.top:              parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin:        14
            spacing: 4
            Repeater {
                model: 3
                Rectangle {
                    width: 4; height: 4; radius: 2
                    color: bar.clrMuted
                }
            }
        }

        // ── Slider ──────────────────────────────────────────────────────
        Item {
            id: volSliderArea
            anchors.top:              parent.top
            anchors.bottom:           volMuteBtn.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin:        38
            anchors.bottomMargin:     8
            width: parent.width

            // Track arka plan
            Rectangle {
                id: volTrackBg
                width: 6
                height: parent.height
                radius: 3
                color: bar.clrSurf
                anchors.centerIn: parent
            }

            // Doluluk — aşağıdan yukarı
            Rectangle {
                width:  6
                radius: 3
                height: volTrackBg.height * (bar.muted ? 0 : bar.volume / 100)
                color:  bar.muted ? bar.clrRed : bar.clrGreen
                anchors.bottom:           volTrackBg.bottom
                anchors.horizontalCenter: volTrackBg.horizontalCenter
                Behavior on height { NumberAnimation { duration: 60 } }
            }

            // Thumb knob
            Rectangle {
                width:  32; height: 32; radius: 16
                color:  bar.muted ? bar.clrRed : bar.clrAccent
                anchors.horizontalCenter: volTrackBg.horizontalCenter
                y: volTrackBg.y + volTrackBg.height * (1 - (bar.muted ? 0 : bar.volume / 100)) - height / 2
                Behavior on y { NumberAnimation { duration: 60 } }

                Text {
                    anchors.centerIn: parent
                    text: bar.muted ? "M" : bar.volume
                    color: "#2D353B"
                    font.pixelSize: bar.volume >= 100 ? 8 : 9
                    font.bold: true
                    font.family: "Noto Sans"
                }
            }

            // Tıklama + sürükleme
            MouseArea {
                anchors.fill: volTrackBg
                anchors.margins: -16   // kolay tıklamak için geniş alan
                cursorShape: Qt.SizeVerCursor
                preventStealing: true

                onPressed:        setVol(mouseY)
                onPositionChanged: setVol(mouseY)
                onWheel: function(wheel) {
                    if (wheel.angleDelta.y > 0) volUpCmd.running = true
                    else volDownCmd.running = true
                }

                function setVol(my) {
                    const h   = volTrackBg.height
                    const pct = Math.max(0, Math.min(100,
                        Math.round((1 - my / h) * 100)
                    ))
                    bar.volSetTarget = pct
                    volSetCmd.running = false
                    volSetTimer.start()
                }
            }
        }

        // ── Alt ikon: müzik notu / mute toggle ──────────────────────────
        Rectangle {
            id: volMuteBtn
            width:  40; height: 40; radius: 20
            color:  bar.muted
                        ? Qt.rgba(0.90, 0.49, 0.50, 0.30)
                        : Qt.rgba(1, 1, 1, 0.08)
            anchors.bottom:           parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin:     8

            Text {
                anchors.centerIn: parent
                text: bar.muted ? "\uf026" : "\uf025"
                font.family:   "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: bar.muted ? bar.clrRed : bar.clrSub
            }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    volMuteCmd.running = true
            }
        }
    }

        // ── Medya paneli ──────────────────────────────────────────────────────
    Rectangle {
        anchors { top: barBg.bottom; left: parent.left }
        width: 290
        height: clock.hasMedia ? 96 : 40
        radius: 12; color: bar.clrPanel
        visible: bar.mediaPanelOpen
        Behavior on height { NumberAnimation { duration: 180 } }

        Rectangle {
            anchors { top: parent.top; left: parent.left }
            width: parent.radius
            height: parent.radius
            color: parent.color
        }

        Column {
            anchors { fill: parent; margins: 14 }
            spacing: 6

            Text {
                visible: !clock.hasMedia
                text: "Oynatıcı yok"; color: bar.clrMuted
                font.pixelSize: 11; font.family: "Noto Sans"
            }

            Text {
                visible: clock.hasMedia
                text: clock.mediaTitle; color: bar.clrText
                font.pixelSize: 13; font.bold: true; font.family: "Noto Sans"
                elide: Text.ElideRight; width: parent.width
            }
            Text {
                visible: clock.hasMedia
                text: clock.mediaArtist; color: bar.clrSub
                font.pixelSize: 11; font.family: "Noto Sans"
                elide: Text.ElideRight; width: parent.width
            }
            Row {
                visible: clock.hasMedia
                spacing: 8; anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: [{ icon: "\uf049", act:0 }, { icon: clock.mediaPlaying ? "\uf04c" : "\uf04b", act:1 }, { icon: "\uf050", act:2 }]
                    Rectangle {
                        required property var modelData
                        width: 28; height: 28; radius: 14
                        color: modelData.act === 1 ? bar.clrAccent : bar.clrSurf
                        Text { anchors.centerIn: parent; text: modelData.icon; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: modelData.act === 1 ? "#2D353B" : bar.clrText }
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

    // ── BT paneli ─────────────────────────────────────────────────────────
    Rectangle {
        anchors { top: barBg.bottom; right: parent.right }
        width: 250; height: btPanelCol.implicitHeight + 24
        radius: 12; color: bar.clrPanel
        visible: bar.btPanelOpen

        Rectangle {
            anchors { top: parent.top; right: parent.right }
            width: parent.radius
            height: parent.radius
            color: parent.color
        }

        Column {
            id: btPanelCol
            anchors { fill: parent; margins: 14 }
            spacing: 10

            Row {
                width: parent.width
                Text { text: "Bluetooth"; color: bar.clrText; font.pixelSize: 13; font.bold: true; font.family: "Noto Sans"; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 52 }
                Rectangle {
                    width: 44; height: 24; radius: 12
                    color: bar.btPowered ? bar.clrAccent : bar.clrSurf
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        width: 18; height: 18; radius: 9; color: "white"; anchors.verticalCenter: parent.verticalCenter
                        x: bar.btPowered ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btToggleCmd.running = true }
                }
            }

            Repeater {
                model: bar.btAllDevices
                Rectangle {
                    required property var modelData
                    width: btPanelCol.width; height: 36; radius: 8
                    color: modelData.connected ? Qt.rgba(0.46,0.73,0.70,0.12) : bar.clrSurf
                    Row {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                        spacing: 6
                        Rectangle { width:6; height:6; radius:3; color: modelData.connected ? bar.clrBlue : bar.clrMuted; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.name; color: modelData.connected ? bar.clrBlue : bar.clrText; font.pixelSize:11; font.family:"Noto Sans"; font.bold: modelData.connected; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; width: parent.width - 6 - 6 - 60 }
                        Item { width: 1 }
                        Rectangle {
                            width:26; height:26; radius:6
                            color: modelData.connected ? Qt.rgba(0.90,0.49,0.50,0.20) : Qt.rgba(0.65,0.75,0.50,0.18)
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: modelData.connected ? "\uf127" : "\uf293"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11; color: modelData.connected ? bar.clrRed : bar.clrGreen }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: btAction(modelData.connected ? "bluetoothctl disconnect " + modelData.mac : "bluetoothctl connect " + modelData.mac)
                            }
                        }
                        Rectangle {
                            width:26; height:26; radius:6; color: Qt.rgba(0.90,0.49,0.50,0.12); anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "\uf1f8"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11; color: bar.clrRed }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btAction("bluetoothctl remove " + modelData.mac) }
                        }
                    }
                }
            }

            Text { visible: bar.btAllDevices.length === 0 && bar.btPowered;  text: "Eşleşmiş cihaz yok"; color: bar.clrMuted; font.pixelSize:11; font.family:"Noto Sans" }
            Text { visible: !bar.btPowered; text: "Bluetooth kapalı"; color: bar.clrMuted; font.pixelSize:11; font.family:"Noto Sans" }
        }
    }

    // ── WiFi paneli ───────────────────────────────────────────────────────
    Rectangle {
        anchors { top: barBg.bottom; right: parent.right }
        width: 260; height: wifiPanelCol.implicitHeight + 24
        radius: 12; color: bar.clrPanel
        visible: bar.wifiPanelOpen

        Rectangle {
            anchors { top: parent.top; right: parent.right }
            width: parent.radius
            height: parent.radius
            color: parent.color
        }

        Column {
            id: wifiPanelCol
            anchors { fill: parent; margins: 14 }
            spacing: 6

            Row {
                width: parent.width
                Text { text: "WiFi"; color: bar.clrText; font.pixelSize:13; font.bold:true; font.family:"Noto Sans"; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 52 }
                Rectangle {
                    width:44; height:24; radius:12
                    color: bar.wifiEnabled ? bar.clrGreen : bar.clrSurf
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        width:18; height:18; radius:9; color:"white"; anchors.verticalCenter: parent.verticalCenter
                        x: bar.wifiEnabled ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wifiToggleCmd.running = true }
                }
            }

            Repeater {
                model: bar.wifiNetworks
                Column {
                    required property var modelData
                    width: wifiPanelCol.width; spacing: 4

                    Rectangle {
                        width: parent.width; height: 34; radius: 8
                        color: modelData.active ? Qt.rgba(0.65,0.75,0.50,0.18)
                             : bar.wifiPassExpandedSsid === modelData.ssid ? Qt.rgba(0.46,0.73,0.70,0.12)
                             : Qt.rgba(1,1,1,0.04)
                        Row {
                            anchors { fill: parent; leftMargin:10; rightMargin:10 }
                            spacing:6
                            Text { text:"\uf1eb"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:12; color: modelData.active ? bar.clrGreen : modelData.signal > 60 ? bar.clrSub : bar.clrMuted; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: modelData.ssid; color: modelData.active ? bar.clrGreen : bar.clrText; font.pixelSize:11; font.family:"Noto Sans"; font.bold: modelData.active; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; width: parent.width - 18 - 6 - 16 - 6 - 28 - 10 }
                            Item { width:1 }
                            Text { visible: modelData.secured; text:"\uf023"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:10; color: bar.clrMuted; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: modelData.signal + "%"; color: bar.clrMuted; font.pixelSize:10; font.family:"Noto Sans"; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; visible: !modelData.active
                            onClicked: {
                                const isSaved = bar.savedSsids.indexOf(modelData.ssid) >= 0
                                bar.wifiConnectTarget = modelData.ssid
                                if (!modelData.secured || isSaved) {
                                    bar.wifiConnectPass = ""; bar.wifiPassExpandedSsid = ""
                                    wifiConnTimer.start()
                                } else {
                                    bar.wifiPassExpandedSsid = bar.wifiPassExpandedSsid === modelData.ssid ? "" : modelData.ssid
                                    bar.wifiPassInput = ""
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: bar.wifiPassExpandedSsid === modelData.ssid ? 38 : 0
                        visible: height > 2; radius:8; color: bar.clrSurf2; clip:true
                        Behavior on height { NumberAnimation { duration:180; easing.type: Easing.OutCubic } }
                        Row {
                            anchors { fill:parent; leftMargin:10; rightMargin:10 }
                            spacing:8; visible: parent.height > 10
                            Text { text:"\uf023"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:12; color: bar.clrSub; anchors.verticalCenter: parent.verticalCenter }
                            TextInput {
                                width: parent.width - 62; color: bar.clrText; font.pixelSize:12; font.family:"Noto Sans"
                                echoMode: TextInput.Password; anchors.verticalCenter: parent.verticalCenter
                                onTextChanged: bar.wifiPassInput = text
                                Keys.onReturnPressed: { bar.wifiConnectPass = bar.wifiPassInput; wifiConnTimer.start() }
                                Text { anchors.fill:parent; text:"Şifre girin..."; color: bar.clrMuted; font:parent.font; visible: parent.text.length === 0; verticalAlignment: Text.AlignVCenter }
                            }
                            Rectangle {
                                width:26; height:26; radius:6; color: Qt.rgba(0.65,0.75,0.50,0.20); anchors.verticalCenter: parent.verticalCenter
                                Text { anchors.centerIn:parent; text:"\uf00c"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:11; color: bar.clrGreen }
                                MouseArea { anchors.fill:parent; cursorShape: Qt.PointingHandCursor; onClicked: { bar.wifiConnectPass = bar.wifiPassInput; wifiConnTimer.start() } }
                            }
                        }
                    }
                }
            }

            Text { visible: bar.wifiNetworks.length === 0; text:"Ağ taranıyor..."; color: bar.clrMuted; font.pixelSize:11; font.family:"Noto Sans" }
        }
    }

    // ── Wallhaven paneli ──────────────────────────────────────────────────
    Rectangle {
        id: wallPanel
        anchors { top: barBg.bottom; left: parent.left; right: parent.right }
        height: bar.wallPanelHeight
        color:  bar.clrPanel
        visible: bar.wallPanelOpen
        clip: true

        Column {
            id: wallPanelCol
            anchors { fill: parent; margins: 12 }
            spacing: 8

            // Arama satırı
            Row {
                width: parent.width
                spacing: 6

                Rectangle {
                    width: parent.width - 28*3 - 28 - 6*4; height: 28; radius: 14
                    color: bar.clrSurf
                    Row {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        spacing: 6
                        Text {
                            text: "\uf002"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                            color: bar.clrMuted; anchors.verticalCenter: parent.verticalCenter
                        }
                        TextInput {
                            id: wallQueryField
                            width: parent.width - 20
                            color: bar.clrText; font.pixelSize: 11; font.family: "Noto Sans"
                            text: bar.wallQuery
                            onTextChanged: bar.wallQuery = text
                            Keys.onReturnPressed: bar.wallSearch()
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.fill: parent; text: "Wallpaper ara..."
                                color: bar.clrMuted; font: parent.font
                                visible: parent.text.length === 0
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                // Sıralama butonları
                Repeater {
                    model: [
                        { icon: "\uf005", val: "toplist",   tip: "Top" },
                        { icon: "\uf017", val: "date_added", tip: "Yeni" },
                        { icon: "\uf06e", val: "views",     tip: "Çok izlenen" }
                    ]
                    Rectangle {
                        required property var modelData
                        width: 28; height: 28; radius: 8
                        color: bar.wallSorting === modelData.val
                               ? Qt.rgba(0.90,0.60,0.46,0.25) : bar.clrSurf
                        Text {
                            anchors.centerIn: parent; text: modelData.icon
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                            color: bar.wallSorting === modelData.val ? bar.clrAccent : bar.clrMuted
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { bar.wallSorting = modelData.val; bar.wallSearch() }
                        }
                    }
                }

                // Ara butonu
                Rectangle {
                    width: 28; height: 28; radius: 8; color: bar.clrAccent
                    Text { anchors.centerIn: parent; text: "\uf002"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: "#2D353B" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bar.wallSearch() }
                }
            }

            // Loading / boş durum
            Text {
                visible: bar.wallLoading
                text: "Yükleniyor..."; color: bar.clrMuted
                font.pixelSize: 11; font.family: "Noto Sans"
            }
            Text {
                visible: !bar.wallLoading && bar.wallResults.length === 0
                text: "Arama yap veya Enter'a bas"
                color: bar.clrMuted; font.pixelSize: 11; font.family: "Noto Sans"
            }

            // Thumbnail grid
            Grid {
                visible: bar.wallResults.length > 0
                width: parent.width
                columns: 6
                spacing: 6

                Repeater {
                    model: bar.wallResults

                    Rectangle {
                        required property var modelData
                        width:  Math.floor((wallPanelCol.width - 5*6) / 6)
                        height: width * 9 / 16
                        radius: 6; color: bar.clrSurf; clip: true

                        Image {
                            anchors.fill: parent
                            source: modelData.thumb
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Rectangle {
                            id: thumbOver
                            anchors.fill: parent; radius: parent.radius
                            color: "#88000000"; opacity: 0
                            Behavior on opacity { NumberAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent; text: "\uf019"
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
                                color: "white"
                            }
                        }

                        scale: 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered:  { thumbOver.opacity = 1; parent.scale = 1.05 }
                            onExited:   { thumbOver.opacity = 0; parent.scale = 1.0  }
                            onClicked:  bar.wallApply(modelData.full)
                        }
                    }
                }
            }
        }
    }
}
