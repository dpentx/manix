import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "modules"

PanelWindow {
    id: bar

    anchors { top: true; left: true; right: true }

    implicitHeight: 36 + panelExtra
    property int panelExtra: {
        if (volPopupOpen)      return 236
        if (mediaPanelOpen)    return clock.hasMedia ? 96 : 44
        if (btPanelOpen)       return btPanelCol.implicitHeight    + 28
        if (wifiPanelOpen)     return wifiPanelCol.implicitHeight  + 28
        if (wallPanelOpen)     return wallPanelHeight + 28
        if (settingsMenuOpen)  return settingsMenuCol.implicitHeight + 28
        if (powerMenuOpen)     return powerMenuCol.implicitHeight   + 28
        return 0
    }
    property int wallPanelHeight: 300
    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    exclusiveZone: 36
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
    property bool volPopupOpen:     false
    property bool wallPanelOpen:    false
    property bool settingsMenuOpen: false
    property bool powerMenuOpen:    false

    property bool anyPanelOpen: mediaPanelOpen || btPanelOpen || wifiPanelOpen
                             || volPopupOpen || wallPanelOpen
                             || settingsMenuOpen || powerMenuOpen

    function closeAllPanels() {
        mediaPanelOpen    = false
        btPanelOpen       = false
        wifiPanelOpen     = false
        volPopupOpen      = false
        wallPanelOpen     = false
        settingsMenuOpen  = false
        powerMenuOpen     = false
    }

    // ── Güç komutları ─────────────────────────────────────────────────────
    Process { id: powerShutdown; command: ["sh", "-c", "systemctl poweroff"] }
    Process { id: powerReboot;   command: ["sh", "-c", "systemctl reboot"] }
    Process { id: powerLogout;   command: ["sh", "-c", "niri msg action quit --skip-confirmation"] }

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
    Timer { id: wifiConnTimer;   interval: 60;  repeat: false; onTriggered: wifiConnectCmd.running = true }
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
    Process { id: volMuteCmd; command: ["pamixer","--toggle-mute"];  onRunningChanged: if (!running) volPoller.running = true }
    Process { id: volUpCmd;   command: ["pamixer","--increase","5"]; onRunningChanged: if (!running) volPoller.running = true }
    Process { id: volDownCmd; command: ["pamixer","--decrease","5"]; onRunningChanged: if (!running) volPoller.running = true }

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
    property string wallApiKey:  ""
    property bool   wallTabLocal: false   // false=Wallhaven, true=Lokal
    property var    localWalls:   []

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

    Process {
        id: localWallScanner
        command: ["sh", "-c",
            "find /home/asus/wallpapers -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) " +
            "2>/dev/null | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                const files = text.trim().split("\n").filter(f => f.length > 0)
                bar.localWalls = files.map(f => ({ path: f, name: f.split("/").pop() }))
            }
        }
    }

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

    // ── Wallpaper indirme durumu ──────────────────────────────────────────
    property string wallApplyTarget:  ""
    property string wallSavePath:     ""       // ~/wallpapers/<orijinal-ad>
    property bool   wallDownloading:  false
    property real   wallDlProgress:   0.0      // 0.0 – 1.0
    property int    wallDlExpected:   0        // beklenen bayt
    property string wallDlLabel:      ""       // "1.2 / 3.4 MB"

    // 1) Dosya boyutunu HEAD ile al
    Process {
        id: wallSizeProc
        property string targetUrl: ""
        command: ["sh", "-c",
            "curl -sI --user-agent 'Mozilla/5.0' '" + wallSizeProc.targetUrl + "' " +
            "2>/dev/null | grep -i content-length | tail -1 | awk '{print $2}' | tr -d '\\r'"]
        stdout: StdioCollector {
            onStreamFinished: {
                bar.wallDlExpected = parseInt(text.trim()) || 0
                // Boyut alındı — indirmeyi başlat
                wallDlProc.dlUrl = bar.wallApplyTarget
                wallDlProc.running = false
                wallDlStartTimer.start()
            }
        }
    }
    Timer { id: wallDlStartTimer; interval: 60; repeat: false; onTriggered: wallDlProc.running = true }

    // 2) Arka planda indir
    Process {
        id: wallDlProc
        property string dlUrl: ""
        command: ["sh", "-c",
            "curl -L --max-time 60 --user-agent 'Mozilla/5.0' " +
            "'" + wallDlProc.dlUrl + "' " +
            "-o /tmp/qs-wall.jpg 2>/tmp/qs-wall-err.txt && " +
            "mkdir -p /home/asus/wallpapers && " +
            "cp /tmp/qs-wall.jpg '" + bar.wallSavePath + "'"]
        onRunningChanged: {
            if (running) {
                bar.wallDlProgress = 0
                wallDlPollTimer.start()
            } else {
                wallDlPollTimer.stop()
                bar.wallDlProgress   = 1.0
                bar.wallDlLabel      = "Uygulanıyor..."
                bar.applyWallpaper("/tmp/qs-wall.jpg")
            }
        }
    }

    // 3) Dosya boyutunu poll'la → progress hesapla
    Process {
        id: wallSizePoller
        command: ["sh", "-c", "stat -c %s /tmp/qs-wall.jpg 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const downloaded = parseInt(text.trim()) || 0
                if (bar.wallDlExpected > 0) {
                    bar.wallDlProgress = Math.min(downloaded / bar.wallDlExpected, 0.99)
                } else {
                    // Boyut bilinmiyorsa indikator olarak döngüsel artış
                    bar.wallDlProgress = Math.min(bar.wallDlProgress + 0.04, 0.95)
                }
                // Etiket: "1.2 / 3.4 MB"
                const dlMB  = (downloaded / 1048576).toFixed(1)
                const totMB = bar.wallDlExpected > 0
                    ? " / " + (bar.wallDlExpected / 1048576).toFixed(1) + " MB"
                    : " MB"
                bar.wallDlLabel = dlMB + totMB
            }
        }
    }

    Timer {
        id: wallDlPollTimer
        interval: 400
        repeat: true
        running: false
        onTriggered: wallSizePoller.running = true
    }

    // 4) İndirme tamamlanınca swaybg uygula — btAction pattern
    property string swaybgCmd: ""
    Process {
        id: swaybgRestarter
        command: ["sh", "-c", bar.swaybgCmd || "true"]
        onRunningChanged: {
            if (!running && bar.swaybgCmd !== "true") {
                bar.wallDlLabel     = "Uygulandı ✓"
                bar.wallDlProgress  = 0
                bar.wallDownloading = false
                Qt.callLater(function() { bar.wallDlLabel = "" })
            }
        }
    }
    Timer { id: swaybgTimer; interval: 150; repeat: false; onTriggered: swaybgRestarter.running = true }

    function applyWallpaper(path) {
        bar.swaybgCmd = "swww img '" + path + "' --transition-type fade --transition-fps 60 --transition-duration 1 2>/tmp/qs-wall-err.txt"
        swaybgRestarter.running = false
        swaybgTimer.start()
    }

    function wallApply(url) {
        if (bar.wallDownloading) return   // çift tıklamayı önle
        const fname = url.split("/").pop().split("?")[0] || "wallpaper.jpg"
        bar.wallSavePath    = "/home/asus/wallpapers/" + fname
        bar.wallApplyTarget = url
        bar.wallDownloading = true
        bar.wallDlProgress  = 0
        bar.wallDlLabel     = "Boyut alınıyor..."
        // Önce HEAD ile boyutu öğren
        wallSizeProc.targetUrl = url
        wallSizeProc.running   = false
        wallSizeProc.running   = true
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: { btPoller.running = true; wifiPoller.running = true; volPoller.running = true }
    }

    // ── Dışarı tıklayınca panelleri kapat ────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        visible: bar.anyPanelOpen
        MouseArea {
            anchors.fill: parent
            onClicked: bar.closeAllPanels()
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ── Bar ────────────────────────────────────────────────────────────────
    // ═══════════════════════════════════════════════════════════════════════
    Rectangle {
        id: barBg
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 36
        color: bar.clrBase

        // Alt border
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color: Qt.rgba(1, 1, 1, 0.06)
        }

        // Bar boşluğuna tıklayınca panelleri kapat
        MouseArea { anchors.fill: parent; onClicked: bar.closeAllPanels() }

        // ── Sol: Saat pill ────────────────────────────────────────────────
        Rectangle {
            id: leftPill
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            height: 30
            width: leftPillRow.implicitWidth + 24
            radius: 15
            color: "#CC3D4A56"
            MouseArea { anchors.fill: parent; onClicked: {} }

            Row {
                id: leftPillRow
                anchors.centerIn: parent
                spacing: 12

                Clock {
                    id: clock
                    textColor: bar.clrText
                    onClicked: {
                        bar.mediaPanelOpen   = !bar.mediaPanelOpen
                        bar.btPanelOpen      = false
                        bar.wifiPanelOpen    = false
                        bar.wallPanelOpen    = false
                        bar.settingsMenuOpen = false
                        bar.powerMenuOpen    = false
                        bar.volPopupOpen     = false
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf0c9"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: bar.settingsMenuOpen ? bar.clrAccent : bar.clrSub
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            bar.settingsMenuOpen = !bar.settingsMenuOpen
                            bar.wallPanelOpen    = false
                            bar.wifiPanelOpen    = false
                            bar.btPanelOpen      = false
                            bar.mediaPanelOpen   = false
                            bar.volPopupOpen     = false
                            bar.powerMenuOpen    = false
                        }
                    }
                }
            }
        }

        // ── Medya: Kontrol pill + Etiket ─────────────────────────────────
        // Waybar custom/playerctl stili — prev/play/next pill
        Rectangle {
            id: mediaCtrlPill
            visible: clock.hasMedia
            anchors { left: leftPill.right; leftMargin: 5; verticalCenter: parent.verticalCenter }
            height: 26
            width: 68
            radius: 13
            color: "#CC3D4A56"
            MouseArea { anchors.fill: parent; onClicked: {} }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf04a"   // fa-step-backward
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: clock.mediaPlaying ? "#E69875" : bar.clrMuted
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: mediaPrev.running = true
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: clock.mediaPlaying ? "\uf04c" : "\uf04b"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: clock.mediaPlaying ? "#E69875" : bar.clrMuted
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: mediaPlay.running = true
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf04e"   // fa-step-forward
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: clock.mediaPlaying ? "#E69875" : bar.clrMuted
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: mediaNext.running = true
                    }
                }
            }
        }

        // Waybar custom/playerlabel stili — sanatçı - şarkı
        Rectangle {
            id: mediaLabelPill
            visible: clock.hasMedia
            anchors { left: mediaCtrlPill.right; leftMargin: 4; verticalCenter: parent.verticalCenter }
            height: 26
            width: Math.min(mediaLabelText.implicitWidth + 20, 220)
            radius: 13
            color: "transparent"
            clip: true

            Text {
                id: mediaLabelText
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                width: parent.width - 10

                text: {
                    const a = clock.mediaArtist
                    const t = clock.mediaTitle
                    if (a && t) return a + " - " + t
                    return t || a
                }
                color: clock.mediaPlaying ? bar.clrText : bar.clrSub
                font.pixelSize: 11
                font.family: "Noto Sans"
                elide: Text.ElideRight

                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
        Rectangle {
            anchors.centerIn: parent
            height: 26
            width: wsRow.implicitWidth + 24
            radius: 13
            color: "#CC3D4A56"
            MouseArea { anchors.fill: parent; onClicked: {} }

            Workspaces {
                id: wsRow
                anchors.centerIn: parent
                activeColor:   bar.clrAccent
                inactiveColor: bar.clrMuted
            }
        }

        // ── Sağ: Güç pill + İkon pill ─────────────────────────────────────
        Rectangle {
            id: powerPill
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            height: 26
            width: 36
            radius: 13
            color: bar.powerMenuOpen ? Qt.rgba(0.90,0.24,0.25,0.35) : "#CC3D4A56"
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea { anchors.fill: parent; onClicked: {} }

            Text {
                id: powerPillInner
                anchors.centerIn: parent
                text: "\uf011"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: bar.powerMenuOpen ? bar.clrRed : bar.clrSub
                Behavior on color { ColorAnimation { duration: 150 } }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        bar.powerMenuOpen    = !bar.powerMenuOpen
                        bar.btPanelOpen      = false
                        bar.wifiPanelOpen    = false
                        bar.mediaPanelOpen   = false
                        bar.volPopupOpen     = false
                        bar.wallPanelOpen    = false
                        bar.settingsMenuOpen = false
                    }
                }
            }
        }

        Rectangle {
            id: iconPill
            anchors { right: powerPill.left; rightMargin: 5; verticalCenter: parent.verticalCenter }
            height: 26
            width: rightIcons.implicitWidth + 24
            radius: 13
            color: "#CC3D4A56"
            MouseArea { anchors.fill: parent; onClicked: {} }

            Row {
                id: rightIcons
                anchors.centerIn: parent
                spacing: 14

                Text {
                    id: volIcon
                    anchors.verticalCenter: parent.verticalCenter
                    text: bar.muted ? "\uf026" : bar.volume > 60 ? "\uf028" : bar.volume > 20 ? "\uf027" : "\uf026"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: bar.muted ? bar.clrRed : bar.volPopupOpen ? bar.clrAccent : bar.clrSub
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            bar.volPopupOpen     = !bar.volPopupOpen
                            bar.btPanelOpen      = false
                            bar.wifiPanelOpen    = false
                            bar.mediaPanelOpen   = false
                            bar.wallPanelOpen    = false
                            bar.settingsMenuOpen = false
                            bar.powerMenuOpen    = false
                        }
                        onWheel: function(wheel) {
                            if (wheel.angleDelta.y > 0) volUpCmd.running = true
                            else volDownCmd.running = true
                        }
                    }
                }

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
                            bar.btPanelOpen      = !bar.btPanelOpen
                            bar.wifiPanelOpen    = false
                            bar.mediaPanelOpen   = false
                            bar.volPopupOpen     = false
                            bar.wallPanelOpen    = false
                            bar.settingsMenuOpen = false
                            bar.powerMenuOpen    = false
                            if (bar.btPanelOpen) btPoller.running = true
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf1eb"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: bar.wifiConnected ? bar.clrGreen : bar.clrMuted
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            bar.wifiPanelOpen    = !bar.wifiPanelOpen
                            bar.btPanelOpen      = false
                            bar.mediaPanelOpen   = false
                            bar.volPopupOpen     = false
                            bar.wallPanelOpen    = false
                            bar.settingsMenuOpen = false
                            bar.powerMenuOpen    = false
                            bar.wifiPassExpandedSsid = ""
                            if (bar.wifiPanelOpen) wifiListPoller.running = true
                        }
                    }
                }
            }
        }
    }

    // ── Volume popup ──────────────────────────────────────────────────────
    Rectangle {
        id: volPopup
        visible: bar.volPopupOpen
        anchors.right:       barBg.right
        anchors.rightMargin: 16
        anchors.top:         barBg.bottom
        anchors.topMargin:   8
        width: 56
        height: 228
        radius: 28
        color: "#F0333C43"
        MouseArea { anchors.fill: parent; onClicked: {} }

        Row {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 14
            spacing: 4
            Repeater {
                model: 3
                Rectangle { width: 4; height: 4; radius: 2; color: bar.clrMuted }
            }
        }

        Item {
            id: volSliderArea
            anchors.top: parent.top
            anchors.bottom: volMuteBtn.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 38
            anchors.bottomMargin: 8
            width: parent.width

            Rectangle {
                id: volTrackBg
                width: 6
                height: parent.height
                radius: 3
                color: bar.clrSurf
                anchors.centerIn: parent
            }
            Rectangle {
                width: 6; radius: 3
                height: volTrackBg.height * (bar.muted ? 0 : bar.volume / 100)
                color: bar.muted ? bar.clrRed : bar.clrGreen
                anchors.bottom: volTrackBg.bottom
                anchors.horizontalCenter: volTrackBg.horizontalCenter
                Behavior on height { NumberAnimation { duration: 60 } }
            }
            Rectangle {
                width: 32; height: 32; radius: 16
                color: bar.muted ? bar.clrRed : bar.clrAccent
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
            MouseArea {
                anchors.fill: volTrackBg
                anchors.margins: -16
                cursorShape: Qt.SizeVerCursor
                preventStealing: true
                onPressed:         setVol(mouseY)
                onPositionChanged: setVol(mouseY)
                onWheel: function(wheel) {
                    if (wheel.angleDelta.y > 0) volUpCmd.running = true
                    else volDownCmd.running = true
                }
                function setVol(my) {
                    const pct = Math.max(0, Math.min(100, Math.round((1 - my / volTrackBg.height) * 100)))
                    bar.volSetTarget = pct; volSetCmd.running = false; volSetTimer.start()
                }
            }
        }

        Rectangle {
            id: volMuteBtn
            width: 40; height: 40; radius: 20
            color: bar.muted ? Qt.rgba(0.90,0.49,0.50,0.30) : Qt.rgba(1,1,1,0.08)
            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 8
            Text {
                anchors.centerIn: parent; text: bar.muted ? "\uf026" : "\uf025"
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15
                color: bar.muted ? bar.clrRed : bar.clrSub
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: volMuteCmd.running = true }
        }
    }

    // ── Medya paneli ──────────────────────────────────────────────────────
    Rectangle {
        anchors { top: barBg.bottom; left: parent.left }
        width: 290
        height: clock.hasMedia ? 96 : 40
        radius: 12
        color: bar.clrPanel
        visible: bar.mediaPanelOpen
        Behavior on height { NumberAnimation { duration: 180 } }
        MouseArea { anchors.fill: parent; onClicked: {} }
        Rectangle {
            anchors { top: parent.top; left: parent.left }
            width: parent.radius
            height: parent.radius
            color: parent.color
        }

        Column {
            anchors { fill: parent; margins: 14 }
            spacing: 6
            Text { visible: !clock.hasMedia; text: "Oynatıcı yok"; color: bar.clrMuted; font.pixelSize: 11; font.family: "Noto Sans" }
            Text { visible: clock.hasMedia; text: clock.mediaTitle; color: bar.clrText; font.pixelSize: 13; font.bold: true; font.family: "Noto Sans"; elide: Text.ElideRight; width: parent.width }
            Text { visible: clock.hasMedia; text: clock.mediaArtist; color: bar.clrSub; font.pixelSize: 11; font.family: "Noto Sans"; elide: Text.ElideRight; width: parent.width }
            Row {
                visible: clock.hasMedia
                spacing: 8
                anchors.horizontalCenter: parent.horizontalCenter
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
        width: 250
        height: btPanelCol.implicitHeight + 24
        radius: 12
        color: bar.clrPanel
        visible: bar.btPanelOpen
        MouseArea { anchors.fill: parent; onClicked: {} }
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
                    width: btPanelCol.width
                    height: 36
                    radius: 8
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
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btAction(modelData.connected ? "bluetoothctl disconnect " + modelData.mac : "bluetoothctl connect " + modelData.mac) }
                        }
                        Rectangle {
                            width:26
                            height:26
                            radius:6
                            color: Qt.rgba(0.90,0.49,0.50,0.12)
                            anchors.verticalCenter: parent.verticalCenter
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
        width: 260
        height: wifiPanelCol.implicitHeight + 24
        radius: 12
        color: bar.clrPanel
        visible: bar.wifiPanelOpen
        MouseArea { anchors.fill: parent; onClicked: {} }
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
                    width: wifiPanelCol.width
                    spacing: 4

                    Rectangle {
                        width: parent.width
                        height: 34
                        radius: 8
                        color: modelData.active ? Qt.rgba(0.65,0.75,0.50,0.18)
                             : bar.wifiPassExpandedSsid === modelData.ssid ? Qt.rgba(0.46,0.73,0.70,0.12)
                             : Qt.rgba(1,1,1,0.04)
                        Row {
                            anchors { fill: parent; leftMargin:10; rightMargin:10 }
                            spacing: 6
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
                        visible: height > 2
                        radius: 8
                        color: bar.clrSurf2
                        clip: true
                        Behavior on height { NumberAnimation { duration:180; easing.type: Easing.OutCubic } }
                        Row {
                            anchors { fill:parent; leftMargin:10; rightMargin:10 }
                            spacing: 8
                            visible: parent.height > 10
                            Text { text:"\uf023"; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:12; color: bar.clrSub; anchors.verticalCenter: parent.verticalCenter }
                            TextInput {
                                width: parent.width - 62
                                color: bar.clrText
                                font.pixelSize: 12
                                font.family: "Noto Sans"
                                echoMode: TextInput.Password
                                anchors.verticalCenter: parent.verticalCenter
                                onTextChanged: bar.wifiPassInput = text
                                Keys.onReturnPressed: { bar.wifiConnectPass = bar.wifiPassInput; wifiConnTimer.start() }
                                Text { anchors.fill:parent; text:"Şifre girin..."; color: bar.clrMuted; font:parent.font; visible: parent.text.length === 0; verticalAlignment: Text.AlignVCenter }
                            }
                            Rectangle {
                                width: 26
                                height: 26
                                radius: 6
                                color: Qt.rgba(0.65,0.75,0.50,0.20)
                                anchors.verticalCenter: parent.verticalCenter
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

    // ── Wallhaven + Lokal paneli ──────────────────────────────────────────
    Rectangle {
        id: wallPanel
        anchors { top: barBg.bottom; left: parent.left }
        width: 460
        height: bar.wallPanelHeight
        color:  bar.clrPanel
        visible: bar.wallPanelOpen
        clip: true
        MouseArea { anchors.fill: parent; onClicked: {} }

        Rectangle {
            anchors { top: parent.top; left: parent.left }
            width: parent.radius; height: parent.radius
            color: parent.color
        }

        Column {
            id: wallPanelCol
            anchors { fill: parent; margins: 12 }
            spacing: 8

            // ── Tab satırı ────────────────────────────────────────────────
            Row {
                width: parent.width; spacing: 4

                // Wallhaven tab
                Rectangle {
                    width: (parent.width - 4) / 2; height: 28; radius: 8
                    color: !bar.wallTabLocal ? Qt.rgba(0.90,0.60,0.46,0.22) : bar.clrSurf
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "\uf0ac"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: !bar.wallTabLocal ? bar.clrAccent : bar.clrMuted; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Wallhaven"; font.pixelSize: 11; font.family: "Noto Sans"; color: !bar.wallTabLocal ? bar.clrAccent : bar.clrMuted; font.bold: !bar.wallTabLocal }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bar.wallTabLocal = false }
                }

                // Lokal tab
                Rectangle {
                    width: (parent.width - 4) / 2; height: 28; radius: 8
                    color: bar.wallTabLocal ? Qt.rgba(0.65,0.75,0.50,0.18) : bar.clrSurf
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "\uf07c"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: bar.wallTabLocal ? bar.clrGreen : bar.clrMuted; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Lokal"; font.pixelSize: 11; font.family: "Noto Sans"; color: bar.wallTabLocal ? bar.clrGreen : bar.clrMuted; font.bold: bar.wallTabLocal }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { bar.wallTabLocal = true; localWallScanner.running = true }
                    }
                }
            }

            // ── Wallhaven içeriği ─────────────────────────────────────────
            Column {
                visible: !bar.wallTabLocal
                width: parent.width; spacing: 8

                Row {
                    width: parent.width; spacing: 6

                    Rectangle {
                        width: parent.width - 28*3 - 28 - 6*4; height: 28; radius: 14
                        color: bar.clrSurf
                        Row {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 6
                            Text { text: "\uf002"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: bar.clrMuted; anchors.verticalCenter: parent.verticalCenter }
                            TextInput {
                                id: wallQueryField
                                width: parent.width - 20
                                color: bar.clrText; font.pixelSize: 11; font.family: "Noto Sans"
                                text: bar.wallQuery
                                onTextChanged: bar.wallQuery = text
                                Keys.onReturnPressed: bar.wallSearch()
                                anchors.verticalCenter: parent.verticalCenter
                                Text { anchors.fill: parent; text: "Wallpaper ara..."; color: bar.clrMuted; font: parent.font; visible: parent.text.length === 0; verticalAlignment: Text.AlignVCenter }
                            }
                        }
                    }

                    Repeater {
                        model: [
                            { icon: "\uf005", val: "toplist" },
                            { icon: "\uf017", val: "date_added" },
                            { icon: "\uf06e", val: "views" }
                        ]
                        Rectangle {
                            required property var modelData
                            width: 28; height: 28; radius: 8
                            color: bar.wallSorting === modelData.val ? Qt.rgba(0.90,0.60,0.46,0.25) : bar.clrSurf
                            Text { anchors.centerIn: parent; text: modelData.icon; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: bar.wallSorting === modelData.val ? bar.clrAccent : bar.clrMuted }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { bar.wallSorting = modelData.val; bar.wallSearch() } }
                        }
                    }

                    Rectangle {
                        width: 28; height: 28; radius: 8; color: bar.clrAccent
                        Text { anchors.centerIn: parent; text: "\uf002"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: "#2D353B" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bar.wallSearch() }
                    }
                }

                Text { visible: bar.wallLoading; text: "Yükleniyor..."; color: bar.clrMuted; font.pixelSize: 11; font.family: "Noto Sans" }
                Text { visible: !bar.wallLoading && bar.wallResults.length === 0; text: "Arama yap veya Enter'a bas"; color: bar.clrMuted; font.pixelSize: 11; font.family: "Noto Sans" }

                // Progress bar
                Rectangle {
                    visible: bar.wallDownloading
                    width: parent.width; height: 36; radius: 10; color: bar.clrSurf
                    Rectangle {
                        id: dlFill
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: Math.max(parent.radius * 2, parent.width * bar.wallDlProgress)
                        radius: parent.radius
                        color: bar.wallDlProgress >= 1.0 ? bar.clrGreen : bar.clrAccent
                        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    Rectangle {
                        visible: bar.wallDlProgress > 0 && bar.wallDlProgress < 1.0
                        anchors { top: parent.top; bottom: parent.bottom }
                        width: 60; x: dlFill.width - 30; radius: parent.radius
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.5; color: Qt.rgba(1,1,1,0.12) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    }
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        Text { text: bar.wallDlProgress >= 1.0 ? "\uf00c" : "\uf019"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: bar.wallDlProgress >= 1.0 ? bar.clrGreen : "#2D353B" }
                        Text { Layout.fillWidth: true; text: bar.wallDlProgress >= 1.0 ? "Uygulandı" : (bar.wallDlLabel.length > 0 ? bar.wallDlLabel : "İndiriliyor..."); color: bar.wallDlProgress >= 1.0 ? bar.clrGreen : "#2D353B"; font.pixelSize: 11; font.family: "Noto Sans"; font.bold: true }
                        Text { visible: bar.wallDlProgress > 0 && bar.wallDlProgress < 1.0; text: Math.round(bar.wallDlProgress * 100) + "%"; color: "#2D353B"; font.pixelSize: 11; font.bold: true; font.family: "Noto Sans" }
                    }
                }

                Grid {
                    visible: bar.wallResults.length > 0
                    width: parent.width; columns: 4; spacing: 6
                    Repeater {
                        model: bar.wallResults
                        Rectangle {
                            required property var modelData
                            width: Math.floor((wallPanelCol.width - 3*6) / 4)
                            height: width * 9 / 16
                            radius: 6; color: bar.clrSurf; clip: true
                            Image { anchors.fill: parent; source: modelData.thumb; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                            Rectangle {
                                id: thumbOver; anchors.fill: parent; radius: parent.radius
                                color: "#88000000"; opacity: 0
                                Behavior on opacity { NumberAnimation { duration: 100 } }
                                Text { anchors.centerIn: parent; text: "\uf019"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; color: "white" }
                            }
                            scale: 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onEntered: { thumbOver.opacity = 1; parent.scale = 1.05 }
                                onExited:  { thumbOver.opacity = 0; parent.scale = 1.0  }
                                onClicked: bar.wallApply(modelData.full)
                            }
                        }
                    }
                }
            }

            // ── Lokal içeriği ─────────────────────────────────────────────
            Column {
                visible: bar.wallTabLocal
                width: parent.width; spacing: 6

                Row {
                    width: parent.width
                    Text { text: "~/wallpapers"; color: bar.clrSub; font.pixelSize: 10; font.family: "Noto Sans"; anchors.verticalCenter: parent.verticalCenter; Layout.fillWidth: true }
                    Item { width: parent.width - 90 }
                    Rectangle {
                        width: 28; height: 28; radius: 8; color: bar.clrSurf
                        Text { anchors.centerIn: parent; text: "\uf021"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: bar.clrMuted }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: localWallScanner.running = true }
                    }
                }

                Text { visible: bar.localWalls.length === 0; text: "~/wallpapers/ klasörü boş"; color: bar.clrMuted; font.pixelSize: 11; font.family: "Noto Sans" }

                Grid {
                    visible: bar.localWalls.length > 0
                    width: parent.width; columns: 4; spacing: 6
                    Repeater {
                        model: bar.localWalls
                        Rectangle {
                            required property var modelData
                            width: Math.floor((wallPanelCol.width - 3*6) / 4)
                            height: width * 9 / 16
                            radius: 6; color: bar.clrSurf; clip: true
                            Image {
                                anchors.fill: parent
                                source: "file://" + modelData.path
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Rectangle {
                                id: localThumbOver; anchors.fill: parent; radius: parent.radius
                                color: "#88000000"; opacity: 0
                                Behavior on opacity { NumberAnimation { duration: 100 } }
                                Text { anchors.centerIn: parent; text: "\uf00c"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; color: "white" }
                            }
                            scale: 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onEntered: { localThumbOver.opacity = 1; parent.scale = 1.05 }
                                onExited:  { localThumbOver.opacity = 0; parent.scale = 1.0  }
                                onClicked: {
                                    bar.applyWallpaper(modelData.path)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Ayarlar menüsü ────────────────────────────────────────────────────
    Rectangle {
        id: settingsMenu
        anchors { top: barBg.bottom; left: parent.left }
        width: 200
        height: settingsMenuCol.implicitHeight + 20
        radius: 12
        color: bar.clrPanel
        visible: bar.settingsMenuOpen
        clip: true
        MouseArea { anchors.fill: parent; onClicked: {} }

        // Sol üst köşe kare — barın rengiyle örtüş
        Rectangle {
            anchors { top: parent.top; left: parent.left }
            width: parent.radius; height: parent.radius
            color: bar.clrBase
        }

        Column {
            id: settingsMenuCol
            anchors { fill: parent; margins: 10 }
            spacing: 4

            Text {
                text: "MENÜ"
                color: bar.clrMuted
                font.pixelSize: 9
                font.bold: true
                font.family: "Noto Sans"
                leftPadding: 4
            }

            // Wallpaper
            Rectangle {
                width: parent.width; height: 36; radius: 8
                color: wallMenuHover.containsMouse ? bar.clrSurf : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                Row {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
                    spacing: 10
                    Text {
                        text: "\uf03e"
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                        color: bar.clrAccent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Wallpaper"
                        font.pixelSize: 12; font.family: "Noto Sans"
                        color: bar.clrText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: wallMenuHover
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                    onClicked: {
                        bar.settingsMenuOpen = false
                        bar.wallPanelOpen    = true
                        if (bar.wallResults.length === 0) bar.wallSearch()
                    }
                }
            }

            // Ayraç
            Rectangle { width: parent.width; height: 1; color: bar.clrSurf; opacity: 0.5 }

            // Yer tutucu — ileride buraya ek menü öğeleri gelecek
            Rectangle {
                width: parent.width; height: 36; radius: 8
                color: moreMenuHover.containsMouse ? bar.clrSurf : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
                opacity: 0.4

                Row {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
                    spacing: 10
                    Text {
                        text: "\uf013"
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                        color: bar.clrMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Yakında..."
                        font.pixelSize: 12; font.family: "Noto Sans"
                        color: bar.clrMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea { id: moreMenuHover; anchors.fill: parent; hoverEnabled: true }
            }
        }
    }

    // ── Güç menüsü ────────────────────────────────────────────────────────
    Rectangle {
        id: powerMenu
        anchors { top: barBg.bottom; right: parent.right }
        width: 180
        height: powerMenuCol.implicitHeight + 20
        radius: 12
        color: bar.clrPanel
        visible: bar.powerMenuOpen
        clip: true
        MouseArea { anchors.fill: parent; onClicked: {} }

        // Sağ üst köşe kare — barın rengiyle örtüş
        Rectangle {
            anchors { top: parent.top; right: parent.right }
            width: parent.radius; height: parent.radius
            color: bar.clrBase
        }

        Column {
            id: powerMenuCol
            anchors { fill: parent; margins: 10 }
            spacing: 4

            Text {
                text: "GÜÇ"
                color: bar.clrMuted
                font.pixelSize: 9; font.bold: true; font.family: "Noto Sans"
                leftPadding: 4
            }

            Repeater {
                model: [
                    { icon: "\uf2f5", label: "Oturumu Kapat", clr: "#7FBBB3", cmd: "logout" },
                    { icon: "\uf01e", label: "Yeniden Başlat", clr: "#E6B450", cmd: "reboot"  },
                    { icon: "\uf011", label: "Kapat",          clr: "#E67E80", cmd: "shutdown" }
                ]

                Rectangle {
                    required property var modelData
                    width: powerMenuCol.width; height: 36; radius: 8
                    color: pwHover.containsMouse
                        ? Qt.rgba(
                            parseInt(modelData.clr.slice(1,3),16)/255,
                            parseInt(modelData.clr.slice(3,5),16)/255,
                            parseInt(modelData.clr.slice(5,7),16)/255,
                            0.15)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Row {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
                        spacing: 10
                        Text {
                            text: modelData.icon
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                            color: modelData.clr
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.label
                            font.pixelSize: 12; font.family: "Noto Sans"
                            color: bar.clrText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: pwHover
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onClicked: {
                            bar.powerMenuOpen = false
                            if      (modelData.cmd === "logout")   powerLogout.running   = true
                            else if (modelData.cmd === "reboot")   powerReboot.running   = true
                            else if (modelData.cmd === "shutdown") powerShutdown.running = true
                        }
                    }
                }
            }
        }
    }
}
