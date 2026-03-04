import QtQuick
import Quickshell.Io

Column {
    id: clockWidget
    spacing: 1

    property color textColor: "#CDD6F4"

    // Medya paneli durumu (dışarıdan kontrol edilebilir)
    property bool mediaExpanded: false

    signal clicked()

    // Türkçe gün ve ay isimleri
    readonly property var gunler: ["Paz", "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt"]
    readonly property var aylar: ["Oca", "Şub", "Mar", "Nis", "May", "Haz",
                                   "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"]

    property string saatMetni: ""
    property string tarihMetni: ""

    property string mediaTitle:  ""
    property string mediaArtist: ""
    property bool   mediaPlaying: false
    property bool   hasMedia: false

    function guncelle() {
        const now = new Date()
        const s = String(now.getHours()).padStart(2,"0") + ":" + String(now.getMinutes()).padStart(2,"0")
        const t = gunler[now.getDay()] + " " + now.getDate() + " " + aylar[now.getMonth()]
        saatMetni = s
        tarihMetni = t
    }

    Component.onCompleted: guncelle()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockWidget.guncelle()
    }

    // Medya bilgisi — playerctl ile
    Process {
        id: mediaPoller
        command: ["sh", "-c", "playerctl metadata --format '{{status}}|{{title}}|{{artist}}' 2>/dev/null || echo 'Stopped||'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|")
                const status = parts[0] || ""
                clockWidget.mediaTitle   = parts[1] || ""
                clockWidget.mediaArtist  = parts[2] || ""
                clockWidget.mediaPlaying = status === "Playing"
                clockWidget.hasMedia     = status === "Playing" || status === "Paused"
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: mediaPoller.running = true
    }

    // Saat + tarih tıklanabilir alan
    MouseArea {
        width: clockCol.implicitWidth
        height: clockCol.implicitHeight
        cursorShape: Qt.PointingHandCursor
        onClicked: clockWidget.clicked()

        Column {
            id: clockCol
            spacing: 0

            Text {
                text: clockWidget.saatMetni
                color: clockWidget.textColor
                font.pixelSize: 14
                font.bold: true
                font.family: "Noto Sans"
            }

            Text {
                text: clockWidget.tarihMetni
                color: Qt.rgba(
                    clockWidget.textColor.r,
                    clockWidget.textColor.g,
                    clockWidget.textColor.b,
                    0.55
                )
                font.pixelSize: 9
                font.family: "Noto Sans"
            }
        }
    }
}
