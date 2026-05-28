import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Rectangle {
    id: volumePill
    color: volumeWidget.volumeControlOpen ? Qt.rgba(Theme.colFg.r, Theme.colFg.g, Theme.colFg.b, 0.2) : 
           volumeMouseArea.containsMouse ? Qt.rgba(Theme.colFg.r, Theme.colFg.g, Theme.colFg.b, 0.1) : 
           "transparent"
    radius: 8
    height: 26
    // width: volumeWidget.width
    // anchors.verticalCenter: parent.verticalCenter

    Layout.preferredWidth: 60 // 56
    // Layout.alignment: Qt.AlignRight
    // horizontalAlignment: Text.AlignRight

    // anchors.centerIn: parent

    Text {
        id: volumeWidget
        // anchors.verticalCenter: parent.verticalCenter
        // Layout.alignment: Qt.AlignRight
        // horizontalAlignment: Text.AlignRight

        anchors.centerIn: parent

        property int volumeLevel: 0
        property bool volumeMuted: false
        property string audioSink: "speaker"  // speaker, headphone, hdmi, bluetooth
        property bool volumeControlOpen: false

        property string volumeIcon: {
            if (volumeMuted) return "󰸈"
            // if (audioSink === "headphone") return "󰋋"
            // if (audioSink === "bluetooth") return "󰂰"
            // if (audioSink === "hdmi") return "󰡁"
            // Speaker icons based on volume
            if (volumeLevel < 30) return "󰕿"
            if (volumeLevel < 70) return "󰖀"
            return "󰕾"
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
            id: volumeMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: event => {
                if (event.button === Qt.LeftButton) {
                    volumeControlProc.running = true
                } else if (event.button === Qt.RightButton) {
                    volumeMuteProc.running = true
                }
            }

            onWheel: wheel => {
                if (wheel.angleDelta.y > 0) {
                    volumeLevelIncProc.running = true
                } else if (wheel.angleDelta.y < 0) {
                    volumeLevelDecrProc.running = true
                }
            }
        }
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
        command: ["sh", "-c", "~/.config/helper-scripts/launch-volume-app.sh"]
    }

    // Mute audio
    Process {
        id: volumeMuteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        onRunningChanged: {
            if (!running) volProc.running = true
        }
    }

    // Volume level increase
    Process {
        id: volumeLevelIncProc
        command: ["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", "2%+"]
    }

    // Volume level decrease
    Process {
        id: volumeLevelDecrProc
        command: ["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", "2%-"]
    }


    Process {
        id: volumeControlOpenProc
        command: ["sh", "-c", "pgrep -x pavucontrol >/dev/null 2>&1 && echo true || echo false"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return

                volumeWidget.volumeControlOpen = data.trim() === "true"
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            volProc.running = true
            sinkProc.running = true
            volumeControlOpenProc.running = true
        }
    }
}
