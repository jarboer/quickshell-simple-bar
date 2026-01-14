import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets // for QsMenuAnchor
import ".."

Item {
    id: trayWidget
    implicitWidth: trayRow.implicitWidth
    implicitHeight: parent.height

    required property var barWindow
    
    Row {
        id: trayRow
        spacing: 12
        anchors.centerIn: parent

        // Reference the SystemTray singleton
        Component.onCompleted: SystemTray // ensures tray items start updating

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayItem
                width: 18
                height: 18

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: event => {
                        if (event.button === Qt.LeftButton) {
                            modelData.activate()
                        } else if (event.button === Qt.RightButton && modelData.hasMenu) {
                            const pos = trayItem.mapToItem(
                                barWindow.contentItem,
                                0,
                                trayItem.height
                            )

                            modelData.display(barWindow, pos.x, pos.y + 4)
                        }
                    }
                }

                Image {
                    anchors.fill: parent
                    source: modelData.icon
                    sourceSize.width: width
                    sourceSize.height: height
                    fillMode: Image.PreserveAspectFit
                }
            }
        }

        
    }

    // Separator with spacing
    // Text {
    //     // visible: SystemTray.items.length > 0
    //     text: "  |"
    //     color: Theme.colMuted
    //     font.pixelSize: Theme.fontSize
    //     font.family: Theme.fontFamily
    //     anchors.verticalCenter: parent.verticalCenter
    // }
}
