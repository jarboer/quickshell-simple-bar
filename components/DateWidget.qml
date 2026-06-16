import QtQuick
import Quickshell
import ".."

Text {
    text: Qt.formatDateTime(clock.date, "ddd, MMM d")
    color: Theme.colFg
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    font.bold: true
    anchors.verticalCenter: parent.verticalCenter

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }
}
