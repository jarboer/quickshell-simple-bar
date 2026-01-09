import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

Item {
    id: root
    Layout.preferredWidth: iconContainer.width + 10
    Layout.preferredHeight: parent.height
    Layout.rightMargin: 8

    required property var barWindow
    property int popupWidth: 200
    property int popupHeight: 150
    property int popupXOffset: 200
    property bool dropdownOpen: false
    property string stemAlignment: "center"  // "left", "center", or "right"
    property alias popupContent: popupLoader.sourceComponent

    signal opened()

    default property alias iconContent: iconContainer.data

    Connections {
        target: barWindow
        function onCloseAllPopups() {
            dropdownOpen = false
        }
    }

    // Placeholder / way to calculate icon size
    Row {
        id: iconContainer
        anchors.centerIn: parent
        height: parent.height
        // width: 64
    }

    // The hover effect
    Rectangle {
        color: dropdownOpen ? Qt.rgba(Theme.colFg.r, Theme.colFg.g, Theme.colFg.b, 0.2) : dropdownMouseArea.containsMouse ? Qt.rgba(Theme.colFg.r, Theme.colFg.g, Theme.colFg.b, 0.1) : "transparent"
        radius: 8
        height: 26
        width: iconContainer.width + 10
        anchors.centerIn: parent

        MouseArea {
            id: dropdownMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                dropdownOpen = !dropdownOpen
                if (dropdownOpen) {
                    root.opened()
                }
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [popup]
        active: dropdownOpen
        onCleared: dropdownOpen = false
    }

    PopupWindow {
        id: popup
        visible: dropdownOpen
        anchor.window: barWindow
        anchor.rect.x: {
            var iconCenter = root.x + iconContainer.x + iconContainer.width/2
            if (stemAlignment === "right") {
                return iconCenter - popupWidth + cardRect.stemWidth/2 - 5 // + 10 // Change the centre position (offset)
            } else if (stemAlignment === "left") {
                return iconCenter - cardRect.stemWidth/2 - 10
            } else {
                return iconCenter - popupWidth/2
            }
        }
        anchor.rect.y: 32
        implicitWidth: popupWidth
        implicitHeight: popupHeight
        color: "transparent"

        // Main card with notch corners
        Canvas {
            id: cardRect
            anchors.fill: parent

            property int rawStemWidth: iconContainer.width + 22 // 16 // Adjust the width of top of notch (between the curves) for all types (left, centre, right)
            property int stemWidth: Math.min(rawStemWidth, width - 60) // ensure room for notch corners
            property int stemHeight: 12
            property int notchRadius: 10
            property int cardRadius: 12

            onStemWidthChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.fillStyle = Theme.colBg

                // Calculate stem center based on alignment
                var cx
                if (root.stemAlignment === "right") {
                    cx = width - stemWidth/2 + 5 // Change width of top of notch (between the curves)

                    var stemLeft = cx - stemWidth/2
                    var stemRight = cx + stemWidth/2

                    var gapSize = 2

                    ctx.beginPath()
                    ctx.moveTo(stemLeft + cardRadius, 0)

                    // 1/4 of a circle
                    ctx.lineTo(width - cardRadius, 0)
                    ctx.arcTo(width, 0, width, cardRadius, cardRadius)

                    ctx.lineTo(width, height - cardRadius)
                    ctx.arcTo(width, height, width - cardRadius, height, cardRadius)
                    ctx.lineTo(cardRadius, height)
                    ctx.arcTo(0, height, 0, height - cardRadius, cardRadius)
                    ctx.lineTo(0, stemHeight + cardRadius)
                    ctx.arcTo(0, stemHeight, cardRadius, stemHeight, cardRadius)

                    // 1/4 of a circle
                    ctx.lineTo(stemLeft - notchRadius, stemHeight)
                    ctx.arcTo(stemLeft, stemHeight, stemLeft, stemHeight - notchRadius, notchRadius)
                    // Arc triangle
                    ctx.lineTo(stemLeft - gapSize, cardRadius)
                    ctx.arcTo(stemLeft - gapSize, 0, stemLeft - gapSize + cardRadius, 0, cardRadius)

                    ctx.closePath()
                    ctx.fill()
                    
                    return
                } else if (root.stemAlignment === "left") {
                    cx = stemWidth/2 + 10
                } else {
                    cx = width / 2
                }

                var stemLeft = cx - stemWidth/2
                var stemRight = cx + stemWidth/2

                var gapSize = 2

                ctx.beginPath()
                ctx.moveTo(stemLeft + cardRadius, 0)

                // 1/4 of a circle
                ctx.lineTo(stemRight - cardRadius, 0)
                ctx.arcTo(stemRight, 0, stemRight, cardRadius, cardRadius)
                // Arc triangle
                ctx.lineTo(stemRight - gapSize, stemHeight - notchRadius)
                ctx.arcTo(stemRight - gapSize, stemHeight, stemRight - gapSize + notchRadius, stemHeight, notchRadius)

                ctx.lineTo(width - cardRadius, stemHeight)
                ctx.arcTo(width, stemHeight, width, stemHeight + cardRadius, cardRadius)
                ctx.lineTo(width, height - cardRadius)
                ctx.arcTo(width, height, width - cardRadius, height, cardRadius)
                ctx.lineTo(cardRadius, height)
                ctx.arcTo(0, height, 0, height - cardRadius, cardRadius)
                ctx.lineTo(0, stemHeight + cardRadius)
                ctx.arcTo(0, stemHeight, cardRadius, stemHeight, cardRadius)

                // 1/4 of a circle
                ctx.lineTo(stemLeft - notchRadius, stemHeight)
                ctx.arcTo(stemLeft, stemHeight, stemLeft, stemHeight - notchRadius, notchRadius)
                // Arc triangle
                ctx.lineTo(stemLeft - gapSize, cardRadius)
                ctx.arcTo(stemLeft - gapSize, 0, stemLeft - gapSize + cardRadius, 0, cardRadius)

                ctx.closePath()
                ctx.fill()
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Loader {
            id: popupLoader
            anchors.fill: parent
            anchors.topMargin: cardRect.stemHeight + 8
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 8
        }

        onVisibleChanged: {
            if (!visible) {
                dropdownOpen = false
            }
        }
    }
}
