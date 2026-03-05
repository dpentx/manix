import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: wh

    anchors { bottom: true; left: true; right: true }
    implicitHeight: whBar.height + (panelOpen ? whPanel.implicitHeight + 8 : 0)
    exclusiveZone: 0
    color: "transparent"
    focusable: true

    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    property bool   panelOpen:     false
    property bool   loading:       false
    property string query:         "nature"
    property string sorting:       "toplist"
    property string currentWall:   ""
    property var    results:       []
    property int    page:          1
    property string apiKey:        ""   // Wallhaven API key (opsiyonel)

    readonly property color clrBase:   "#CC2D353B"
    readonly property color clrPanel:  "#F02D353B"
    readonly property color clrSurf:   "#404D5660"
    readonly property color clrText:   "#D3C6AA"
    readonly property color clrSub:    "#9DA9A0"
    readonly property color clrMuted:  "#7A8478"
    readonly property color clrAccent: "#E69875"
    readonly property color clrGreen:  "#A7C080"

    // ── Mevcut wallpaper'ı oku ───────────────────────────────────────────
    Process {
        id: currentWallReader
        command: ["sh", "-c", "cat /tmp/qs-wallpaper 2>/dev/null || echo ''"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: wh.currentWall = text.trim()
        }
    }

    // ── Wallhaven API ────────────────────────────────────────────────────
    Process {
        id: fetcher
        property string url: ""
        command: ["sh", "-c",
            "curl -sL '" + fetcher.url + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                wh.loading = false
                try {
                    const data = JSON.parse(text)
                    if (data.data) {
                        wh.results = data.data.slice(0, 12).map(w => ({
                            id:     w.id,
                            thumb:  w.thumbs.small,
                            full:   w.path,
                            res:    w.resolution,
                            views:  w.views
                        }))
                    }
                } catch(e) {
                    wh.results = []
                }
            }
        }
    }

    function search() {
        wh.loading = true
        wh.results = []
        wh.page = 1
        const key = wh.apiKey !== "" ? "&apikey=" + wh.apiKey : ""
        fetcher.url = "https://wallhaven.cc/api/v1/search?q=" +
            encodeURIComponent(wh.query) +
            "&sorting=" + wh.sorting +
            "&page=1&atleast=1920x1080" + key
        fetcher.running = false
        fetchTimer.start()
    }

    Timer { id: fetchTimer; interval: 50; repeat: false; onTriggered: fetcher.running = true }

    // ── Wallpaper uygula (swaybg) ────────────────────────────────────────
    property string applyTarget: ""
    readonly property string applyCmd:
        "curl -sL '" + wh.applyTarget + "' -o /tmp/qs-wall-dl.jpg && " +
        "swaybg -m fill -i /tmp/qs-wall-dl.jpg & " +
        "echo '/tmp/qs-wall-dl.jpg' > /tmp/qs-wallpaper"

    Process {
        id: applyProcess
        command: ["sh", "-c", wh.applyCmd]
        onRunningChanged: if (!running) currentWallReader.running = true
    }
    Timer { id: applyTimer; interval: 50; repeat: false; onTriggered: applyProcess.running = true }

    function applyWall(url) {
        wh.applyTarget = url
        applyProcess.running = false
        applyTimer.start()
    }

    // ════════════════════════════════════════════════════════════════════
    // ── Alt bar ─────────────────────────────────────────────────────────
    // ════════════════════════════════════════════════════════════════════
    Rectangle {
        id: whBar
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 36
        color: wh.clrBase

        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 10

            // Toggle butonu
            Rectangle {
                width: 32; height: 22; radius: 11
                color: wh.panelOpen ? Qt.rgba(0.90,0.60,0.46,0.25) : Qt.rgba(1,1,1,0.07)
                Layout.alignment: Qt.AlignVCenter
                Text {
                    anchors.centerIn: parent
                    text: "\uf03e"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: wh.panelOpen ? wh.clrAccent : wh.clrMuted
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wh.panelOpen = !wh.panelOpen
                        if (wh.panelOpen && wh.results.length === 0) wh.search()
                    }
                }
            }

            // Mevcut wallpaper adı
            Text {
                text: wh.currentWall !== "" ? "  " + wh.currentWall.split("/").pop() : "Wallhaven"
                color: wh.clrSub; font.pixelSize: 10; font.family: "Noto Sans"
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            // Loading göstergesi
            Text {
                visible: wh.loading
                text: "⟳"; color: wh.clrAccent; font.pixelSize: 14
                Layout.alignment: Qt.AlignVCenter

                RotationAnimator on rotation {
                    from: 0; to: 360; duration: 800
                    loops: Animation.Infinite
                    running: wh.loading
                }
            }
        }
    }

    // ── Panel ────────────────────────────────────────────────────────────
    Rectangle {
        id: whPanel
        visible: wh.panelOpen
        anchors { bottom: whBar.top; left: parent.left; right: parent.right }
        implicitHeight: panelContent.implicitHeight + 16
        color: wh.clrPanel

        // Üst köşeler
        Rectangle {
            anchors { top: parent.top; left: parent.left }
            width: 16; height: 16; radius: 16
            color: wh.clrPanel
        }
        Rectangle {
            anchors { top: parent.top; right: parent.right }
            width: 16; height: 16; radius: 16
            color: wh.clrPanel
        }

        Column {
            id: panelContent
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: 12
            spacing: 10

            // Arama + filtre satırı
            RowLayout {
                width: parent.width
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true; height: 32; radius: 16
                    color: wh.clrSurf
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 6
                        Text { text: "\uf002"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: wh.clrMuted }
                        TextInput {
                            id: queryField
                            Layout.fillWidth: true
                            color: wh.clrText; font.pixelSize: 12; font.family: "Noto Sans"
                            text: wh.query
                            onTextChanged: wh.query = text
                            Keys.onReturnPressed: wh.search()
                            Text { anchors.fill: parent; text: "Ara..."; color: wh.clrMuted; font: parent.font; visible: parent.text.length === 0; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                }

                // Sorting
                Repeater {
                    model: [
                        { label: "\uf005", val: "toplist" },
                        { label: "\uf017", val: "date_added" },
                        { label: "\uf06e", val: "views" }
                    ]
                    Rectangle {
                        required property var modelData
                        width: 28; height: 28; radius: 8
                        color: wh.sorting === modelData.val ? Qt.rgba(0.90,0.60,0.46,0.25) : wh.clrSurf
                        Text {
                            anchors.centerIn: parent; text: modelData.label
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                            color: wh.sorting === modelData.val ? wh.clrAccent : wh.clrMuted
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { wh.sorting = modelData.val; wh.search() }
                        }
                    }
                }

                // Ara
                Rectangle {
                    width: 28; height: 28; radius: 8; color: wh.clrAccent
                    Text { anchors.centerIn: parent; text: "\uf002"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: "#2D353B" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wh.search() }
                }
            }

            // Thumbnail grid
            Grid {
                width: parent.width
                columns: 6
                spacing: 6

                Repeater {
                    model: wh.results

                    Rectangle {
                        required property var modelData
                        width:  (panelContent.width - 5 * 6) / 6
                        height: width * 9 / 16
                        radius: 6
                        color:  wh.clrSurf
                        clip:   true

                        Image {
                            anchors.fill: parent
                            source:       modelData.thumb
                            fillMode:     Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        // Hover overlay
                        Rectangle {
                            id: thumbHover
                            anchors.fill: parent; radius: parent.radius
                            color: "#80000000"; opacity: 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "\uf019"
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                                color: "white"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered:  thumbHover.opacity = 1
                            onExited:   thumbHover.opacity = 0
                            onClicked:  wh.applyWall(modelData.full)
                        }
                    }
                }

                // Boş state
                Text {
                    visible: wh.results.length === 0 && !wh.loading
                    text: "Arama yap veya Enter'a bas"
                    color: wh.clrMuted; font.pixelSize: 11; font.family: "Noto Sans"
                }
            }
        }
    }
}
