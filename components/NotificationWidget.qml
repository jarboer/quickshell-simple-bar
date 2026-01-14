import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: centerInfo
    implicitWidth: centerText.implicitWidth
    implicitHeight: parent.height

    property bool dndEnabled: false

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

    // DND toggle process
    Process {
        id: dndToggleProc
        command: ["swaync-client", "-d"]
        onRunningChanged: {
            if (!running) dndStatusProc.running = true
        }
    }

    // DND toggle Notification Center
    Process {
        id: dndToggleNotiCenter
        command: ["swaync-client", "-t", "-sw"]
    }

    // DND status update timer
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: dndStatusProc.running = true
    }

    Row {
        id: centerText
        anchors.centerIn: parent
        spacing: 0
        
        // DND toggle
        Rectangle {
            id: dndPill
            color: dndRightMouseArea.containsMouse ? Qt.rgba(Theme.colFg.r, Theme.colFg.g, Theme.colFg.b, 0.1) : "transparent"
            radius: 8
            height: 26
            width: dndIcon.implicitWidth + 8
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: dndIcon
                text: dndEnabled ? "󰂛" : "󰂚"
                color: dndEnabled ? "#ff5555" : Theme.colMuted
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: true
                anchors.centerIn: parent
            }

            MouseArea {
                id: dndLeftMouseArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: dndToggleNotiCenter.running = true
            }

            MouseArea {
                id: dndRightMouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: dndToggleProc.running = true
            }
        }

        Item { width: 4; height: parent.height}
    }
}
