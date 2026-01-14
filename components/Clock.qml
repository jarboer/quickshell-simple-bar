import QtQuick
import Quickshell
import ".."

Item {
    implicitWidth: clockText.width

    Text {
        id: clockText
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "hh:mm AP")
        color: Theme.colClock
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: true   
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}