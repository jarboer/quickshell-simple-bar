import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Text {
    id: memWidget

    Layout.preferredWidth: 56
    Layout.alignment: Qt.AlignRight
    horizontalAlignment: Text.AlignRight

    property string memUsage: " 0"

    text: "󰾆  " + memUsage + "%"
    color: Theme.colMem
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    font.bold: true

    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var total = parseInt(parts[1]) || 1
                var used = parseInt(parts[2]) || 0

                var memVal = Math.round(100 * used / total)
                memWidget.memUsage = String(memVal).padStart(3, " ")
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: memProc.running = true
    }
}
