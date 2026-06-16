import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Item {
    id: gpuWidget
    Layout.preferredWidth: 122

    property string gpuUsage: " 0"
    property string gpuTemp:  " 0"
    property string gpuMem:   " 0"

    Row {
        spacing: 10
        // anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: "󰍹"
            color: Theme.colGpu
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: true
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            spacing: 0
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: gpuWidget.gpuUsage + "%"
                color: Theme.colGpu
                font.pixelSize: Theme.fontSize / 1.5
                font.family: Theme.fontFamily
                font.bold: true
                width: 30
                horizontalAlignment: Text.AlignRight
            }

            Text {
                text: gpuWidget.gpuTemp + "°C"
                color: Theme.colGpu
                font.pixelSize: Theme.fontSize / 1.5
                font.family: Theme.fontFamily
                font.bold: true
                width: 30
                horizontalAlignment: Text.AlignRight
            }
        }


        Text {
            text: ""
            color: Theme.colGpu
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: true
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: gpuWidget.gpuMem + "%"
            color: Theme.colGpu
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: true
            width: 36
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
        }
        
    }

    Process {
        id: gpuProc
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(",").map(s => parseInt(s.trim()) || 0)
                var gpuUsage = parts[0]
                var memPct = parts[3] > 0 ? Math.round(100 * parts[2] / parts[3]) : 0

                gpuWidget.gpuUsage = String(gpuUsage).padStart(3, " ")
                gpuWidget.gpuTemp  = String(parts[1]).padStart(4, " ")
                gpuWidget.gpuMem   = String(memPct).padStart(3, " ")
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: gpuProc.running = true
    }
}
