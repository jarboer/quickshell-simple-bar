import QtQuick
import ".."

Text {
    text: centerDate
    color: Theme.colFg
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    font.bold: true
    anchors.verticalCenter: parent.verticalCenter

    // Date update timer
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: centerDate = Qt.formatDateTime(new Date(), "ddd, MMM d")
    }
}
