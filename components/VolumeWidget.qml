import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Text {
    id: volumeWidget

    Layout.preferredWidth: 56
    Layout.alignment: Qt.AlignRight
    horizontalAlignment: Text.AlignRight

    property int volumeLevel: 0
    property bool volumeMuted: false
    property string audioSink: "speaker"  // speaker, headphone, hdmi, bluetooth

    property string volumeIcon: {
        if (volumeMuted) return "󰖁"
        if (audioSink === "headphone") return ""
        if (audioSink === "bluetooth") return "󰂰"
        if (audioSink === "hdmi") return "󰡁"
        // Speaker icons based on volume
        if (volumeLevel < 30) return ""
        if (volumeLevel < 70) return "󰕾"
        return ""
    }

    text: volumeIcon + "   " + volumeLevel + "%"
    color: volumeMuted ? Theme.colMuted :
           audioSink === "headphone" ? "#f1fa8c" :
           audioSink === "bluetooth" ? Theme.colBluetooth :
           Theme.colVol
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    font.bold: true

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: volumeControlProc.running = true
    }

    // Volume level (wpctl for PipeWire)
    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var match = data.match(/Volume:\s*([\d.]+)/)
                if (match) {
                    volumeWidget.volumeLevel = Math.round(parseFloat(match[1]) * 100)
                }
                volumeWidget.volumeMuted = data.includes("[MUTED]")
            }
        }
        Component.onCompleted: running = true
    }

    // Audio sink type detection
    Process {
        id: sinkProc
        command: ["pactl", "get-default-sink"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var sink = data.toLowerCase()
                if (sink.includes("headphone") || sink.includes("headset")) {
                    volumeWidget.audioSink = "headphone"
                } else if (sink.includes("hdmi") || sink.includes("displayport")) {
                    volumeWidget.audioSink = "hdmi"
                } else if (sink.includes("bluez") || sink.includes("bluetooth")) {
                    volumeWidget.audioSink = "bluetooth"
                } else {
                    volumeWidget.audioSink = "speaker"
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Volume control launcher
    Process {
        id: volumeControlProc
        command: ["pavucontrol"]
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            volProc.running = true
            sinkProc.running = true
        }
    }
}
