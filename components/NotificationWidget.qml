import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: centerInfo
    implicitWidth: dndPill.width
    // implicitHeight: parent.height

    property bool dndEnabled: false
    property int notifCount: 0

    // DND status check
    Process {
        id: dndStatusProc
        command: ["swaync-client", "-D"]
        stdout: SplitParser {
            onRead: data => {
                if (data) centerInfo.dndEnabled = data.trim() === "true"
            }
        }
        Component.onCompleted: running = true
    }

    // Notification count check
    Process {
        id: notifCountProc
        command: ["swaync-client", "-c"]
        stdout: SplitParser {
            onRead: data => {
                if (data) centerInfo.notifCount = parseInt(data.trim())
            }
        }
        Component.onCompleted: running = true
    }

    // DND toggle process
    Process {
        id: dndToggleProc
        command: ["swaync-client", "-d"]
        onRunningChanged: {
            if (!running) dndStatusProc.running = true
        }
    }

    // Toggle Notification Center
    Process {
        id: toggleNotifCenterProc
        command: ["swaync-client", "-t", "-sw"]
    }

    // DND status update timer
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            dndStatusProc.running = true
            notifCountProc.running = true
        }
    }
        
    // DND toggle
    Rectangle {
        id: dndPill
        color: notifMouseArea.containsMouse ? Qt.rgba(Theme.colFg.r, Theme.colFg.g, Theme.colFg.b, 0.1) : "transparent"
        radius: 8
        height: 26
        width: dndTextCont.width + 8
        anchors.verticalCenter: parent.verticalCenter

        Row {
            id: dndTextCont
            anchors.centerIn: parent
            spacing: 6

            Item {
                height: parent.height
                width: 14
                
                Text {
                    anchors.centerIn: parent
                    text: (dndEnabled ? "󰂛" : "󰂚")
                    color: dndEnabled ? "#ff5555" : Theme.colMuted
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: true
                }
            }

            Text {
                text: centerInfo.notifCount
                color: Theme.colFg
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: true
            }
        }

        MouseArea {
            id: notifMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: event => {
                if (event.button === Qt.LeftButton) {
                    toggleNotifCenterProc.running = true
                } else if (event.button === Qt.RightButton) {
                    dndToggleProc.running = true
                }
            }
        }
    }
}
