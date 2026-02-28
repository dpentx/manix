// LauncherOverlay.qml — One UI tarzı uygulama çekmecesi
// Ekranın altından yukarı kayarak açılır.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.DesktopEntries

PanelWindow {
    id: overlay

    signal closeRequested()

    // Tüm ekranı kapla, dışlama yok
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: -1
    focusable: true
    color: "transparent"

    // ─── Renkler ──────────────────────────────────────────────────────────
    readonly property color clrBase:    "#1E1E2E"
    readonly property color clrMantle:  "#181825"
    readonly property color clrSurface: "#313244"
    readonly property color clrText:    "#CDD6F4"
    readonly property color clrSubtext: "#A6ADC8"
    readonly property color clrAccent:  "#FAB387"

    // Arama filtresi
    property string searchQuery: ""

    // ─── Arka plan: yarı saydam karartma ──────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#CC000000"   // %80 siyah

        // Tıklanınca kapat
        MouseArea {
            anchors.fill: parent
            onClicked: overlay.closeRequested()
        }

        // ─── Çekmece paneli ───────────────────────────────────────────────
        Rectangle {
            id: drawer
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            // Yükseklik: ekranın %85'i
            height: parent.height * 0.85
            color: overlay.clrBase
            radius: 28   // Üst köşeler — One UI imzası

            // Sadece alt kısım köşesiz olsun
            Rectangle {
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }
                height: parent.radius
                color: parent.color
            }

            // ─── Slide-up animasyonu ─────────────────────────────────────
            transform: Translate {
                id: slideTransform
                y: overlay.visible ? 0 : drawer.height
                Behavior on y {
                    NumberAnimation {
                        duration: 320
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // ─── İçerik ───────────────────────────────────────────────────
            ColumnLayout {
                anchors {
                    fill: parent
                    topMargin: 16
                    bottomMargin: 16
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 16

                // Üst tutamaç (handle) — One UI tarzı
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 48
                    height: 4
                    radius: 2
                    color: overlay.clrSurface
                }

                // Arama çubuğu
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 24
                    color: overlay.clrSurface

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 16
                            rightMargin: 16
                        }
                        spacing: 10

                        Text {
                            text: "🔍"
                            font.pixelSize: 16
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: overlay.clrText
                            font.pixelSize: 15
                            font.family: "Noto Sans"
                            placeholderText: "Uygulama ara..."
                            placeholderTextColor: overlay.clrSubtext
                            onTextChanged: overlay.searchQuery = text
                            focus: overlay.visible

                            // Catppuccin cursor rengi
                            cursorDelegate: Rectangle {
                                width: 2
                                color: overlay.clrAccent
                            }
                        }

                        // Temizle butonu
                        Text {
                            text: "✕"
                            color: overlay.clrSubtext
                            font.pixelSize: 14
                            visible: searchField.text.length > 0

                            MouseArea {
                                anchors.fill: parent
                                onClicked: searchField.text = ""
                            }
                        }
                    }
                }

                // ─── Uygulama ızgarası ────────────────────────────────────
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    GridView {
                        id: appGrid
                        width: parent.width
                        cellWidth: Math.floor(width / 5)   // 5 sütun
                        cellHeight: 100

                        // DesktopEntries üzerinden tüm uygulamaları listele
                        model: {
                            const apps = DesktopEntries.applications
                            if (overlay.searchQuery.length === 0) return apps

                            // Arama filtresi
                            return apps.filter(app =>
                                app.name.toLowerCase().includes(
                                    overlay.searchQuery.toLowerCase()
                                )
                            )
                        }

                        delegate: Item {
                            width: appGrid.cellWidth
                            height: appGrid.cellHeight

                            required property var modelData

                            Column {
                                anchors.centerIn: parent
                                spacing: 6

                                // ─── İkon kutusu ─────────────────────────
                                Rectangle {
                                    width: 56
                                    height: 56
                                    radius: 16   // One UI yuvarlatılmış ikonlar
                                    color: overlay.clrSurface
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    // XDG ikon
                                    Image {
                                        anchors.centerIn: parent
                                        width: 36
                                        height: 36
                                        source: modelData.icon !== "" 
                                            ? "image://icon/" + modelData.icon 
                                            : ""
                                        fillMode: Image.PreserveAspectFit
                                        
                                        // İkon yüklenemezse fallback
                                        onStatusChanged: {
                                            if (status === Image.Error) {
                                                visible = false
                                                fallbackText.visible = true
                                            }
                                        }
                                    }

                                    // İkon bulunamazsa baş harfi göster
                                    Text {
                                        id: fallbackText
                                        anchors.centerIn: parent
                                        text: modelData.name.charAt(0).toUpperCase()
                                        color: overlay.clrAccent
                                        font.pixelSize: 20
                                        font.bold: true
                                        visible: false
                                    }

                                    // Tıklama efekti
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: "white"
                                        opacity: 0
                                        id: clickOverlay

                                        NumberAnimation on opacity {
                                            id: clickAnim
                                            from: 0.15
                                            to: 0
                                            duration: 250
                                            running: false
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            clickAnim.running = true
                                            modelData.launch()
                                            overlay.closeRequested()
                                        }
                                    }
                                }

                                // Uygulama adı
                                Text {
                                    width: appGrid.cellWidth - 8
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.name
                                    color: overlay.clrText
                                    font.pixelSize: 11
                                    font.family: "Noto Sans"
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Açılınca arama kutusunu sıfırla
    onVisibleChanged: {
        if (visible) {
            searchField.text = ""
            searchField.forceActiveFocus()
        }
    }
}
