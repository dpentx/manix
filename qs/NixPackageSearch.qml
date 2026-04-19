// NixPackageSearch.qml
// ~/manix/qs/NixPackageSearch.qml
//
// Kullanım: shell.qml içinde şu şekilde çağır:
//   NixPackageSearch { id: nixSearch }
//   Kısayol örneği: nixSearch.toggle()

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    // ─── Ayarlar ────────────────────────────────────────────────────────────
    // Flake dizini ve home-manager target (kendi setupına göre düzenle)
    property string flakeDir:    "/home/asus/manix"
    property string hmTarget:    "asus"           // home-manager switch --flake .#<hmTarget>
    property string packagesNix: "/home/asus/manix/modules/packages.nix"
    property string addScript:   "/home/asus/manix/qs/scripts/add-package.py"

    // ─── Durum ──────────────────────────────────────────────────────────────
    property bool panelVisible: false
    property bool isSearching:  false
    property bool isAdding:     false
    property bool isRebuilding: false
    property string statusMsg:  ""
    property color  statusColor: ef.yellow

    // ─── Genel ──────────────────────────────────────────────────────────────
    visible: panelVisible
    color:   "transparent"

    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    function toggle() {
        panelVisible = !panelVisible
        if (panelVisible) {
            searchField.forceActiveFocus()
            searchField.selectAll()
        }
    }

    function open() {
        panelVisible = true
        searchField.forceActiveFocus()
    }

    function close() {
        panelVisible = false
        setStatus("", ef.yellow)
    }

    // ─── Everforest Dark Hard ────────────────────────────────────────────────
    QtObject {
        id: ef
        readonly property color bg0:     "#2d353b"
        readonly property color bg1:     "#343f44"
        readonly property color bg2:     "#3d484d"
        readonly property color bg3:     "#475258"
        readonly property color fg:      "#d3c6aa"
        readonly property color grey:    "#859289"
        readonly property color red:     "#e67e80"
        readonly property color orange:  "#e69875"
        readonly property color yellow:  "#dbbc7f"
        readonly property color green:   "#a7c080"
        readonly property color teal:    "#83c092"
        readonly property color blue:    "#7fbbb3"
        readonly property color purple:  "#d699b6"
    }

    // ─── Backdrop ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#b0000000"

        Behavior on opacity { NumberAnimation { duration: 150 } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // ─── Panel ───────────────────────────────────────────────────────────────
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width:  700
        height: 580
        radius: 14
        color:  ef.bg0

        // Kenar çizgisi
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color:  "transparent"
            border.color: ef.bg3
            border.width: 1
        }

        ColumnLayout {
            anchors.fill:    parent
            anchors.margins: 20
            spacing: 14

            // ── Başlık ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text:  "  Nix Paket Ara"
                    color: ef.green
                    font { pixelSize: 17; bold: true; family: "monospace" }
                }

                Item { Layout.fillWidth: true }

                // Durum badge'i
                Rectangle {
                    visible:  root.isRebuilding || root.isAdding || root.isSearching
                    height:   24
                    width:    rebuildLabel.implicitWidth + 20
                    radius:   12
                    color:    root.isRebuilding ? ef.orange
                             : root.isAdding    ? ef.yellow
                             :                   ef.blue

                    Text {
                        id: rebuildLabel
                        anchors.centerIn: parent
                        text:  root.isRebuilding ? "rebuild"
                              : root.isAdding    ? "ekleniyor"
                              :                   "aranıyor"
                        color: ef.bg0
                        font { pixelSize: 11; bold: true }
                    }

                    SequentialAnimation on opacity {
                        running: root.isSearching || root.isAdding || root.isRebuilding
                        loops:   Animation.Infinite
                        NumberAnimation { to: 0.5; duration: 600 }
                        NumberAnimation { to: 1.0; duration: 600 }
                    }
                }

                // Kapat
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: closeArea.containsMouse ? ef.red : ef.bg2

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"; color: ef.fg; font.pixelSize: 11
                    }
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.close()
                    }
                }
            }

            // ── Arama satırı ─────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 42
                    radius: 10
                    color: ef.bg1
                    border.color: searchField.activeFocus ? ef.blue : ef.bg3
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 8

                        Text {
                            text: ""; color: ef.grey; font.pixelSize: 15
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: ef.fg
                            selectionColor: Qt.rgba(0.498, 0.733, 0.702, 0.35)
                            font { pixelSize: 14; family: "sans-serif" }
                            enabled: !root.isSearching && !root.isAdding && !root.isRebuilding

                            Keys.onReturnPressed: doSearch()
                            Keys.onEscapePressed: root.close()

                            // Placeholder
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 0
                                text: "paket adını yaz, Enter'a bas..."
                                color: ef.grey
                                font: parent.font
                                visible: parent.text === "" && !parent.activeFocus
                            }
                        }

                        // Temizle
                        Text {
                            text: "✕"
                            color: clearArea.containsMouse ? ef.red : ef.grey
                            font.pixelSize: 13
                            visible: searchField.text.length > 0
                            Behavior on color { ColorAnimation { duration: 100 } }

                            MouseArea {
                                id: clearArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    searchField.text = ""
                                    resultsModel.clear()
                                    root.setStatus("", ef.yellow)
                                    searchField.forceActiveFocus()
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: 80; height: 42; radius: 10
                    color: searchBtnArea.containsMouse && !searchBtnArea.pressed
                           ? Qt.lighter(ef.green, 1.12) : ef.green
                    enabled: !root.isSearching && searchField.text.trim() !== ""
                    opacity: enabled ? 1.0 : 0.5

                    Behavior on color   { ColorAnimation  { duration: 100 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text:  root.isSearching ? "..." : "Ara"
                        color: ef.bg0
                        font { pixelSize: 13; bold: true }
                    }
                    MouseArea {
                        id: searchBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: parent.enabled
                        onClicked: doSearch()
                    }
                }
            }

            // ── Durum çubuğu ─────────────────────────────────────────────────
            Text {
                Layout.fillWidth: true
                text:    root.statusMsg
                color:   root.statusColor
                font { pixelSize: 12; family: "monospace" }
                visible: root.statusMsg !== ""
                elide:   Text.ElideRight
            }

            // ── Sonuç listesi ─────────────────────────────────────────────────
            ListView {
                id: resultList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: resultsModel
                spacing: 5
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    id: resultItem
                    width:  resultList.width
                    height: 68
                    radius: 10
                    color:  itemArea.containsMouse ? ef.bg2 : ef.bg1

                    Behavior on color { ColorAnimation { duration: 80 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 12

                        // İkon alanı
                        Rectangle {
                            width: 36; height: 36; radius: 8
                            color: ef.bg2

                            Text {
                                anchors.centerIn: parent
                                text:  ""
                                color: ef.teal
                                font.pixelSize: 16
                            }
                        }

                        // Bilgi
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout {
                                spacing: 8
                                Text {
                                    text:  model.pname
                                    color: ef.fg
                                    font { pixelSize: 13; bold: true }
                                }
                                Rectangle {
                                    visible: model.version !== ""
                                    height:  18
                                    width:   versionText.implicitWidth + 10
                                    radius:  9
                                    color:   ef.bg3

                                    Text {
                                        id: versionText
                                        anchors.centerIn: parent
                                        text:  model.version
                                        color: ef.grey
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text:            model.description
                                color:           ef.grey
                                font.pixelSize:  11
                                elide:           Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                text:  model.attr
                                color: ef.blue
                                font { pixelSize: 10; family: "monospace" }
                            }
                        }

                        // Ekle butonu
                        Rectangle {
                            width:  64; height: 32; radius: 8
                            color:  model.installed
                                    ? ef.bg3
                                    : (addArea.containsMouse ? Qt.lighter(ef.blue, 1.1) : ef.blue)
                            enabled: !model.installed && !root.isAdding && !root.isRebuilding

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text:  model.installed ? "✓" : "Ekle"
                                color: model.installed ? ef.grey : ef.bg0
                                font { pixelSize: 12; bold: true }
                            }
                            MouseArea {
                                id: addArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled:      parent.enabled
                                onClicked:    addPackage(model.attr, index)
                            }
                        }
                    }

                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        z: -1
                        onClicked: {}
                    }
                }

                // Boş durum
                Item {
                    anchors.centerIn: parent
                    visible: resultList.count === 0 && !root.isSearching
                    width: 280; height: 80

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text:  ""
                            color: ef.grey
                            font.pixelSize: 32
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text:  searchField.text === ""
                                   ? "Bir paket adı yaz ve ara"
                                   : "Sonuç bulunamadı"
                            color: ef.grey
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }

    // ─── Veri modeli ─────────────────────────────────────────────────────────
    ListModel { id: resultsModel }

    // ─── nix search process'i ────────────────────────────────────────────────
    Process {
        id: searchProcess

        stdout: StdioCollector { id: searchOut }

        stderr: StdioCollector { id: searchErr }

        onRunningChanged: {
            if (!running) {
                root.isSearching = false
                const errText = searchErr.text.trim()
                const outText = searchOut.text.trim()
                if (outText.length > 0 && outText.startsWith("{")) {
                    root.parseResults(outText)
                } else if (errText.length > 0) {
                    root.setStatus("nix search hatası: " + errText.substring(0, 120), ef.red)
                } else {
                    root.setStatus("Sonuç bulunamadı.", ef.grey)
                }
            }
        }
    }

    // ─── add-package.py process'i ────────────────────────────────────────────
    Process {
        id: addProcess
        property int    targetIndex: -1
        property string addedAttr:   ""

        stdout: StdioCollector { id: addOut }
        stderr: StdioCollector { id: addErr }

        onRunningChanged: {
            if (!running) {
                const s = addOut.text.trim()
                if (s === "already_installed") {
                    root.isAdding = false
                    root.setStatus("'" + addProcess.addedAttr + "' zaten packages.nix içinde.", ef.yellow)
                    if (addProcess.targetIndex >= 0)
                        resultsModel.setProperty(addProcess.targetIndex, "installed", true)
                } else if (s === "added") {
                    root.setStatus("Eklendi. Rebuild başlatılıyor...", ef.green)
                    if (addProcess.targetIndex >= 0)
                        resultsModel.setProperty(addProcess.targetIndex, "installed", true)
                    root.startRebuild()
                } else {
                    root.isAdding = false
                    const errMsg = addErr.text.trim() || s || "bilinmeyen hata"
                    root.setStatus("Hata: " + errMsg.substring(0, 120), ef.red)
                }
            }
        }
    }

    // ─── home-manager rebuild process'i ──────────────────────────────────────
    Process {
        id: rebuildProcess

        stderr: StdioCollector { id: rebuildErr }
        stdout: StdioCollector { id: rebuildOut }

        onRunningChanged: {
            if (!running) {
                root.isRebuilding = false
                root.isAdding     = false
                const combined = (rebuildOut.text + rebuildErr.text).trim()
                // Basit hata tespiti: nix stderr'de hata çıkıyorsa
                if (combined.indexOf("error:") >= 0 || combined.indexOf("failed") >= 0) {
                    root.setStatus("✗ Rebuild başarısız! Son satır: " + combined.split("\n").pop().substring(0, 80), ef.red)
                } else {
                    root.setStatus("✓ Paket başarıyla kuruldu ve aktif!", ef.green)
                }
            }
        }
    }

    // ─── Fonksiyonlar ────────────────────────────────────────────────────────

    function doSearch() {
        const q = searchField.text.trim()
        if (q === "" || root.isSearching) return

        resultsModel.clear()
        root.isSearching = true
        root.setStatus("Aranıyor: " + q + "  (ilk çalıştırmada biraz sürebilir)", ef.blue)

        // StdioCollector'ları sıfırla
        searchProcess.running = false
        searchProcess.command = ["nix", "search", "nixpkgs", "--json", q]
        searchProcess.running = true
    }

    function parseResults(jsonText) {
        try {
            const data    = JSON.parse(jsonText)
            const entries = Object.entries(data)

            if (entries.length === 0) {
                setStatus("Sonuç bulunamadı.", ef.grey)
                return
            }

            const limit = Math.min(entries.length, 60)
            for (let i = 0; i < limit; i++) {
                const [key, val] = entries[i]
                // "nixpkgs#legacyPackages.x86_64-linux.firefox" → "firefox"
                const attr = key.split('.').pop()
                resultsModel.append({
                    attr:        attr,
                    pname:       val.pname       || attr,
                    version:     val.version     || "",
                    description: val.description || "",
                    installed:   false
                })
            }

            const extra = entries.length > limit ? " (+" + (entries.length - limit) + " daha)" : ""
            setStatus(entries.length + " sonuç" + extra, ef.grey)

        } catch (e) {
            setStatus("JSON parse hatası: " + e.message, ef.red)
        }
    }

    function addPackage(attr, index) {
        if (root.isAdding || root.isRebuilding) return

        root.isAdding = true
        addProcess.targetIndex = index
        addProcess.addedAttr   = attr
        root.setStatus("'" + attr + "' packages.nix'e ekleniyor...", ef.yellow)

        addProcess.command = ["python3", root.addScript, root.packagesNix, attr]
        addProcess.running = true
    }

    function startRebuild() {
        root.isAdding     = false
        root.isRebuilding = true
        root.setStatus("⟳ home-manager rebuild çalışıyor...", ef.orange)

        rebuildProcess.command = [
            "bash", "-c",
            "cd " + root.flakeDir + " && home-manager switch --flake .#" + root.hmTarget + " 2>&1"
        ]
        rebuildProcess.running = true
    }

    function setStatus(msg, col) {
        statusMsg   = msg
        statusColor = col || ef.yellow
    }
}
