// TopBar.qml — One UI tarzı üst durum çubuğu
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "modules"

PanelWindow {
    id: bar

    // Dışarıya açılan sinyal: launcher açma/kapama
    signal toggleLauncher()

    // Layer shell ayarları
    anchors {
        top: true
        left: true
        right: true
    }
    height: 44
    exclusiveZone: height
    color: "transparent"

    // ─── Renkler (Catppuccin Mocha) ───────────────────────────────────────
    readonly property color clrBase:      "#1E1E2E"
    readonly property color clrSurface:   "#313244"
    readonly property color clrText:      "#CDD6F4"
    readonly property color clrSubtext:   "#A6ADC8"
    readonly property color clrAccent:    "#FAB387"   // Peach

    // ─── Bar arka planı ───────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: bar.clrBase

        // Alt kenarda ince bir çizgi — One UI'dan ilham
        Rectangle {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: 1
            color: bar.clrSurface
        }

        // ─── Ana düzen ────────────────────────────────────────────────────
        RowLayout {
            anchors {
                fill: parent
                leftMargin: 16
                rightMargin: 16
            }
            spacing: 0

            // Sol: Saat
            Clock {
                Layout.alignment: Qt.AlignVCenter
                textColor: bar.clrText
            }

            // Orta: Workspace göstergesi
            Item { Layout.fillWidth: true }

            Workspaces {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                activeColor: bar.clrAccent
                inactiveColor: bar.clrSurface
            }

            Item { Layout.fillWidth: true }

            // Sağ: Durum ikonları
            StatusIcons {
                Layout.alignment: Qt.AlignVCenter
                textColor: bar.clrText
                subtextColor: bar.clrSubtext
                accentColor: bar.clrAccent
            }
        }

        // ─── Launcher aç butonu (tüm bara tıklama) ──────────────────────
        // Sadece orta bölgeye tıklanınca launcher açılır — kenarlar serbest
        // Gerçek kullanımda Niri keybinding kullanmak daha iyidir
    }
}
