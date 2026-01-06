import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

// TODO: Make resuabled
// TODO: Use same creation as bluetooth?

Item {
    id: root
    implicitWidth: centerText.implicitWidth
    implicitHeight: parent.height

    required property var barWindow

    property bool darkModeEnabled: false

    // Dark Mode status check
    Process {
        id: darkModeStatusProc
        command: ["darkman", "get"]
        stdout: SplitParser {
            onRead: data => {
                if (data) root.darkModeEnabled = data.trim() === "dark"
            }
        }
        Component.onCompleted: running = true
    }

    // Dark Mode toggle Notification Centre
    Process {
        id: darkModeToggle
        command: ["darkman", "toggle"]
        onRunningChanged: {
            if (!running) darkModeStatusProc.running = true
        }
    }

    // Dark Mode status update timer
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: darkModeStatusProc.running = true
    }

    Row {
        id: centerText
        anchors.centerIn: parent
        spacing: 0
        
        // Dark Mode toggle
        Rectangle {
            color: darkModeMouseArea.containsMouse ? Qt.rgba(Theme.colFg.r, Theme.colFg.g, Theme.colFg.b, 0.1) : "transparent"
            radius: 8
            height: 26
            width: darkModeIcon.implicitHeight
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: darkModeIcon
                text: "󰔎" // darkModeEnabled ? "󰽥" : "󰖨"
                color: darkModeEnabled ? '#808080' : '#ffffff'
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: true
                anchors.centerIn: parent
            }

            MouseArea {
                id: darkModeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: darkModeToggle.running = true
            }
        }

        Item { width: 8; height: parent.height}
    }
}
