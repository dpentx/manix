import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: overlay

    signal closeRequested()

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    focusable: true
    color: "transparent"

    readonly property color clrBase:    "#CC1E1E2E"
    readonly property color clrSurface: "#18FFFFFF"
    readonly property color clrText:    "#CDD6F4"
    readonly property color clrSubtext: "#A6ADC8"
    readonly property color clrMuted:   "#6C7086"
    readonly property color clrAccent:  "#FAB387"

    property string searchQuery: ""
    property var    appList:     []

    // ─── Uygulama başlatma — dosya tabanlı, en güvenilir yöntem ──────────
    // 1. İkon tıklanınca komutu /tmp/qs-exec dosyasına yaz
    // 2. launcher process'i her zaman "sh /tmp/qs-exec" çalıştırır
    // 3. running = false → true döngüsü yerine WriteFile ile tetikle

    FileView {
        id: execFile
        path: "/tmp/qs-exec"
        watchChanges: false
    }

    Process {
        id: launcher
        command: ["sh", "/tmp/qs-exec"]
    }

    // Komutu dosyaya yaz ve çalıştır
    function launchApp(exec, terminal) {
        const cmd = terminal
            ? "kitty -- " + exec + "\n"
            : exec + "\n"
        writeExec.command = ["sh", "-c", "printf '%s' " + JSON.stringify(cmd) + " > /tmp/qs-exec"]
        writeExec.running = false
        execWriteTimer.start()
    }

    Process {
        id: writeExec
        command: ["sh", "-c", "true"]
        onRunningChanged: {
            if (!running) {
                // Dosya yazıldı, şimdi çalıştır
                launcher.running = false
                launchRunTimer.start()
            }
        }
    }

    Timer { id: execWriteTimer;  interval: 30; repeat: false; onTriggered: writeExec.running = true }
    Timer { id: launchRunTimer;  interval: 50; repeat: false; onTriggered: launcher.running = true }

    // ─── .desktop tarayıcı ────────────────────────────────────────────────
    Process {
        id: appScanner
        command: [
            "sh", "-c",
            "find /run/current-system/sw/share/applications " +
            "/home/asus/.nix-profile/share/applications " +
            "-name '*.desktop' 2>/dev/null | while read f; do " +
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

    // ─── Karartma ─────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#99000000"

        MouseArea {
            anchors.fill: parent
            onClicked: overlay.closeRequested()
        }

        // ─── Çekmece ──────────────────────────────────────────────────────
        Rectangle {
            id: drawer
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: parent.height * 0.88
            color: overlay.clrBase
            radius: 28

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: parent.radius; color: parent.color
            }

            transform: Translate {
                y: overlay.visible ? 0 : drawer.height
                Behavior on y {
                    NumberAnimation { duration: 380; easing.type: Easing.OutCubic }
                }
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    topMargin: 12; bottomMargin: 24
                    leftMargin: 24; rightMargin: 24
                }
                spacing: 14

                // Handle
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 40; height: 4; radius: 2
                    color: "#40FFFFFF"
                }

                // Başlık + arama
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "Uygulamalar"
                        color: overlay.clrText
                        font.pixelSize: 18; font.bold: true; font.family: "Noto Sans"
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 200; height: 36; radius: 18
                        color: overlay.clrSurface

                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 8

                            Text { text: "🔍"; font.pixelSize: 13 }

                            TextInput {
                                id: searchField
                                Layout.fillWidth: true
                                color: overlay.clrText
                                font.pixelSize: 13; font.family: "Noto Sans"
                                onTextChanged: overlay.searchQuery = text

                                Text {
                                    anchors.fill: parent
                                    text: "Ara..."
                                    color: overlay.clrMuted; font: parent.font
                                    visible: parent.text.length === 0
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Text {
                                text: "✕"; color: overlay.clrMuted; font.pixelSize: 12
                                visible: searchField.text.length > 0
                                MouseArea { anchors.fill: parent; onClicked: searchField.text = "" }
                            }
                        }
                    }
                }

                // ─── Grid ─────────────────────────────────────────────────
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    GridView {
                        id: appGrid
                        width: parent.width
                        cellWidth:  Math.floor(width / 5)
                        cellHeight: 96
                        model: overlay.filteredApps

                        delegate: Item {
                            id: appItem
                            width: appGrid.cellWidth
                            height: appGrid.cellHeight
                            required property var modelData

                            Column {
                                anchors.centerIn: parent
                                spacing: 7

                                Rectangle {
                                    id: iconCard
                                    width: 52; height: 52; radius: 14
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: "#18FFFFFF"

                                    Image {
                                        id: iconImg
                                        anchors.centerIn: parent
                                        width: 32; height: 32
                                        source: appItem.modelData.icon !== ""
                                            ? "image://icon/" + appItem.modelData.icon : ""
                                        fillMode: Image.PreserveAspectFit
                                        onStatusChanged: if (status === Image.Error) visible = false
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: appItem.modelData.name.charAt(0).toUpperCase()
                                        color: overlay.clrAccent
                                        font.pixelSize: 18; font.bold: true
                                        visible: iconImg.status !== Image.Ready
                                    }

                                    Rectangle {
                                        id: pressOvr
                                        anchors.fill: parent; radius: parent.radius
                                        color: "white"; opacity: 0
                                        Behavior on opacity { NumberAnimation { duration: 80 } }
                                    }

                                    scale: 1.0
                                    Behavior on scale {
                                        NumberAnimation { duration: 120; easing.type: Easing.OutBack }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed:  { pressOvr.opacity = 0.18; iconCard.scale = 0.88 }
                                        onReleased: { pressOvr.opacity = 0;    iconCard.scale = 1.0  }
                                        onClicked: {
                                            overlay.launchApp(
                                                appItem.modelData.exec,
                                                appItem.modelData.terminal
                                            )
                                            overlay.closeRequested()
                                        }
                                    }
                                }

                                Text {
                                    width: appGrid.cellWidth - 8
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: appItem.modelData.name
                                    color: overlay.clrText
                                    font.pixelSize: 10; font.family: "Noto Sans"
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight; maximumLineCount: 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchField.text = ""
            searchField.forceActiveFocus()
            appScanner.running = true
        }
    }
}
