import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Item {
    id: cpuWidget
    Layout.preferredWidth: 100

    property string cpuUsage: " 0"
    property string cpuTemp: " 0"
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    Row {
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰍛"
            color: Theme.colCpu
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: true
            horizontalAlignment: Text.AlignRight
        }

        // CPU Usage
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: cpuWidget.cpuUsage + "%"
            color: Theme.colCpu
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: true
            width: 36
            horizontalAlignment: Text.AlignRight
        }

        // CPU Temp
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: cpuWidget.cpuTemp + "°C"
            color: Theme.colCpu
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: true
            width: 36
            horizontalAlignment: Text.AlignRight
        }
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var user = parseInt(parts[1]) || 0
                var nice = parseInt(parts[2]) || 0
                var system = parseInt(parts[3]) || 0
                var idle = parseInt(parts[4]) || 0
                var iowait = parseInt(parts[5]) || 0
                var irq = parseInt(parts[6]) || 0
                var softirq = parseInt(parts[7]) || 0

                var total = user + nice + system + idle + iowait + irq + softirq
                var idleTime = idle + iowait

                if (cpuWidget.lastCpuTotal > 0) {
                    var totalDiff = total - cpuWidget.lastCpuTotal
                    var idleDiff = idleTime - cpuWidget.lastCpuIdle
                    if (totalDiff > 0) {
                        var cpuVal = Math.round(100 * (totalDiff - idleDiff) / totalDiff)
                        cpuWidget.cpuUsage = String(cpuVal).padStart(3, " ")
                    }
                }
                cpuWidget.lastCpuTotal = total
                cpuWidget.lastCpuIdle = idleTime
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: tempProc
        command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone0/temp"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var raw = parseInt(data.trim())
                if (!isNaN(raw)) {
                    cpuWidget.cpuTemp = String(Math.round(raw / 1000)).padStart(2, " ")
                }
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: cpuProc.running = true
    }
}
