// modules/Clock.qml — Saat ve tarih bileşeni
import QtQuick

Column {
    id: clockWidget
    spacing: 0

    property color textColor: "#CDD6F4"

    // Saati her saniye güncelle
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            timeLabel.text  = Qt.formatDateTime(new Date(), "HH:mm")
            dateLabel.text  = Qt.formatDateTime(new Date(), "ddd, d MMM")
        }
    }

    // Saat — One UI'da sol üstte büyük gösterilir
    Text {
        id: timeLabel
        text: Qt.formatDateTime(new Date(), "HH:mm")
        color: clockWidget.textColor
        font.pixelSize: 15
        font.bold: true
        font.family: "Noto Sans"
    }
}
