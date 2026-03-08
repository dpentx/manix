import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: overlay

    signal closeRequested()
    signal launchRequested(string exec, bool terminal)

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    focusable: true
    color: "transparent"

    readonly property color clrBase:      "#EE1C2128"
    readonly property color clrCard:      "#18252B"
    readonly property color clrSurface:   "#232E34"
    readonly property color clrSurface2:  "#2A3840"
    readonly property color clrText:      "#D3C6AA"
    readonly property color clrSubtext:   "#9DA9A0"
    readonly property color clrMuted:     "#4A5650"
    readonly property color clrAccent:    "#E69875"
    readonly property color clrHighlight: "#28E69875"

    property string searchQuery: ""
    property var    appList:     []

    Process {
        id: appScanner
        command: [
            "sh", "-c",
            "find " +
            "/run/current-system/sw/share/applications " +
            "/home/asus/.nix-profile/share/applications " +
            "/etc/profiles/per-user/asus/share/applications " +
            "/home/asus/.local/share/applications " +
            "-name '*.desktop' 2>/dev/null | sort -u | while read f; do " +
            "name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); " +
            "exec=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2- | " +
            "  sed 's/ %[uUfFdDnNickvm]//g; s/%[uUfFdDnNickvm]//g'); " +
            "icon=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2-); " +
            "nodisplay=$(grep -m1 '^NoDisplay=' \"$f\" | cut -d= -f2-); " +
            "terminal=$(grep -m1 '^Terminal=' \"$f\" | cut -d= -f2-); " +
            "[ \"$nodisplay\" = 'true' ] && continue; " +
            "[ -z \"$name\" ] && continue; [ -z \"$exec\" ] && continue; " +
            "echo \"${name}|${exec}|${icon}|${terminal}\"; " +
            "done | sort -t'|' -k1 -u"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const apps = []
                for (const line of text.trim().split("\n")) {
                    if (!line) continue
                    const p = line.split("|")
                    if (p.length >= 2 && p[0] && p[1]) {
                        apps.push({
                            name:     p[0].trim(),
                            exec:     p[1].trim(),
                            icon:     (p[2]||"").trim(),
                            terminal: (p[3]||"").trim() === "true"
                        })
                    }
                }
                overlay.appList = apps
            }
        }
    }

    property var filteredApps: searchQuery.length === 0
        ? appList
        : appList.filter(a => a.name.toLowerCase().includes(searchQuery.toLowerCase()))

    onFilteredAppsChanged: appGrid.currentIndex = 0

    // ── Karartma backdrop ─────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#CC000000"

        MouseArea {
            anchors.fill: parent
            onClicked: overlay.closeRequested()
        }

        // ── Merkezi panel ─────────────────────────────────────────────────
        Rectangle {
            id: panel

            anchors.centerIn: parent
            width:  Math.min(parent.width  * 0.72, 560)
            height: Math.min(parent.height * 0.78, 680)

            radius: 24
            color:  overlay.clrCard

            // Giriş animasyonu
            opacity: 0
            scale:   0.92
            Component.onCompleted: entryAnim.start()

            ParallelAnimation {
                id: entryAnim
                NumberAnimation { target: panel; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { target: panel; property: "scale";   to: 1; duration: 220; easing.type: Easing.OutCubic }
            }

            // Panel tıklamalarını backdrop'a geçirme
            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                anchors { fill: parent; margins: 20 }
                spacing: 14

                // ── Başlık + arama ────────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "Uygulamalar"
                        color: overlay.clrText
                        font.pixelSize: 17
                        font.bold: true
                        font.family: "Noto Sans"
                    }

                    // Arama kutusu — OneUI Finder tarzı
                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        radius: 22
                        color:  overlay.clrSurface

                        RowLayout {
                            anchors { fill: parent; leftMargin: 16; rightMargin: 14 }
                            spacing: 10

                            Text {
                                text: "\uf002"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: overlay.clrSubtext
                            }

                            TextInput {
                                id: searchField
                                Layout.fillWidth: true
                                color: overlay.clrText
                                font.pixelSize: 14
                                font.family: "Noto Sans"
                                onTextChanged: overlay.searchQuery = text

                                Keys.onTabPressed:    { appGrid.forceActiveFocus() }
                                Keys.onDownPressed:   { appGrid.forceActiveFocus() }
                                Keys.onEscapePressed: overlay.closeRequested()

                                Text {
                                    anchors.fill: parent
                                    text: "Uygulama ara..."
                                    color: overlay.clrMuted
                                    font: parent.font
                                    visible: parent.text.length === 0
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Rectangle {
                                width: 22; height: 22; radius: 11
                                color: overlay.clrSurface2
                                visible: searchField.text.length > 0
                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: overlay.clrSubtext
                                    font.pixelSize: 10
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: searchField.text = ""
                                }
                            }
                        }
                    }
                }

                // ── Uygulama grid ─────────────────────────────────────────
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy:   ScrollBar.AsNeeded

                    GridView {
                        id: appGrid
                        width: parent.width

                        readonly property int cols: 4
                        cellWidth:  Math.floor(width / cols)
                        cellHeight: cellWidth * 1.22

                        model: overlay.filteredApps

                        keyNavigationEnabled: true
                        keyNavigationWraps:   false

                        highlight: Item {
                            Rectangle {
                                anchors.centerIn: parent
                                width:  appGrid.cellWidth  - 12
                                height: appGrid.cellHeight - 10
                                radius: 18
                                color:  overlay.clrHighlight
                                border.color: overlay.clrAccent
                                border.width: 1
                            }
                        }
                        highlightFollowsCurrentItem: true
                        highlightMoveDuration: 100

                        Keys.onReturnPressed: {
                            if (currentIndex >= 0 && currentIndex < filteredApps.length) {
                                const app = filteredApps[currentIndex]
                                overlay.launchRequested(app.exec, app.terminal)
                            }
                        }
                        Keys.onTabPressed: {
                            currentIndex = -1
                            searchField.forceActiveFocus()
                        }
                        Keys.onUpPressed: {
                            if (currentIndex < appGrid.cols) {
                                currentIndex = -1
                                searchField.forceActiveFocus()
                            } else {
                                moveCurrentIndexUp()
                            }
                        }
                        Keys.onEscapePressed: overlay.closeRequested()

                        delegate: Item {
                            id: appItem
                            width:  appGrid.cellWidth
                            height: appGrid.cellHeight
                            required property var modelData
                            required property int index

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Rectangle {
                                    id: iconBg
                                    width:  appGrid.cellWidth * 0.62
                                    height: width
                                    radius: width * 0.28
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: overlay.clrSurface

                                    Image {
                                        id: iconImg
                                        anchors.centerIn: parent
                                        width:  parent.width  * 0.62
                                        height: parent.height * 0.62
                                        source: appItem.modelData.icon !== ""
                                            ? "image://icon/" + appItem.modelData.icon : ""
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        onStatusChanged: if (status === Image.Error) visible = false
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: appItem.modelData.name.charAt(0).toUpperCase()
                                        color: overlay.clrAccent
                                        font.pixelSize: iconBg.width * 0.38
                                        font.bold: true
                                        visible: iconImg.status !== Image.Ready
                                    }

                                    Rectangle {
                                        id: pressOverlay
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: "white"
                                        opacity: 0
                                        Behavior on opacity { NumberAnimation { duration: 80 } }
                                    }

                                    scale: 1.0
                                    Behavior on scale {
                                        NumberAnimation { duration: 110; easing.type: Easing.OutBack }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed:  { pressOverlay.opacity = 0.15; iconBg.scale = 0.86 }
                                        onReleased: { pressOverlay.opacity = 0;    iconBg.scale = 1.0  }
                                        onClicked: {
                                            overlay.launchRequested(
                                                appItem.modelData.exec,
                                                appItem.modelData.terminal
                                            )
                                        }
                                    }
                                }

                                Text {
                                    width: appGrid.cellWidth - 10
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: appItem.modelData.name
                                    color: overlay.clrText
                                    font.pixelSize: 11
                                    font.family: "Noto Sans"
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: overlay.filteredApps.length === 0
                    Layout.alignment: Qt.AlignHCenter
                    text: "Uygulama bulunamadı"
                    color: overlay.clrMuted
                    font.pixelSize: 13
                    font.family: "Noto Sans"
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchField.text     = ""
            appGrid.currentIndex = 0
            searchField.forceActiveFocus()
            appScanner.running   = true
        }
    }
}
