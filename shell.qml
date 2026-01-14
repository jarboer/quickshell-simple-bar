//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "components"

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            property var modelData
            screen: modelData

            signal closeAllPopups()

            // Listen to Hyprland events to close popups when focus changes
            Connections {
                target: Hyprland
                function onRawEvent(event) {
                    // Close popups when active window changes or layer closes
                    if (event.name === "activewindow" || event.name === "activewindowv2") {
                        barWindow.closeAllPopups()
                    }
                }
            }

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 34
            color: "transparent" // Theme.colBg

            margins {
                top: 0
                bottom: 0
                left: 0
                right: 0
            }

            Background {
                anchors.fill: parent
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Left padding
                Item { width: 12 }

                // Workspaces
                WorkspaceBar {
                    Layout.preferredHeight: parent.height
                }

                // Separator
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    color: Theme.colMuted
                }

                // Window info (layout + title)
                WindowInfo {
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: 400
                }

                // Left spacer
                Item { Layout.fillWidth: true }

                // Center: Date and Weather
                CenterInfo {
                    barWindow: barWindow
                }

                // Right spacer
                Item { Layout.fillWidth: true }

                // Slack indicator
                // SlackWidget {}

                // WhatsApp indicator
                // WhatsAppWidget {}

                // Separator {}

                // System stats
                CpuWidget {
                    Layout.rightMargin: 8
                }

                Separator {}

                MemoryWidget {
                    Layout.rightMargin: 8
                }

                Separator {}

                //DiskWidget {
                //    Layout.rightMargin: 8
                //}

                //Separator {}

                VolumeWidget {
                    Layout.rightMargin: 4 //8
                }

                // Separator {}

                // BatteryWidget {
                //     Layout.rightMargin: 8
                // }

                Separator {}

                // WiFi indicator
                // WifiWidget {
                //     barWindow: barWindow
                // }

                // Bluetooth indicator
                BluetoothWidget {
                    barWindow: barWindow
                }

                DarkModeWidget {
                    barWindow: barWindow
                }

                // Power profile
                PowerProfileWidget {
                    barWindow: barWindow
                }

                Separator {}

                NotificationWidget {}

                // Clock
                Clock {}

                Separator {}

                // Power menu
                PowerWidget {
                    barWindow: barWindow
                }

                // Right padding
                Item { width: 8 }
            }

            // Click overlay to close popups - sits on top but propagates clicks
            // Disabled because it broke hover and didn't seem to break overlay closing
            // MouseArea {
            //     anchors.fill: parent
            //     propagateComposedEvents: true
            //     onClicked: (mouse) => {
            //         barWindow.closeAllPopups()
            //         mouse.accepted = false
            //     }
            // }
        }
    }
}
