// Background.qml

import Quickshell
import Quickshell.Io
import QtQuick
// import QtQuick.Effects
import Qt5Compat.GraphicalEffects

Item {
  id: backgroundRoot
  property int imgWidth: 0
  property string currentPath: ""
  property string wallpaperPath: "/home/jarboer/.config/aether/theme/backgrounds/background"
  property var lastModtime: 0

  // Rectangle {
  //   id: bg
  //   anchors.fill: parent
  //   color: "#4fbcbcbc" // translucent tint
  // }

  Image {
    id: bgImg
    anchors.fill: parent
    source: currentPath

    // Hide the source item, otherwise both the source item and
    // MultiEffect will be rendered
    visible: false

    onStatusChanged: {
      if (status === Image.Ready) {
        imgWidth = sourceSize.width
      }
    }

    // fillMode: Image.Pad   // prevents scaling
    sourceClipRect: Qt.rect(0, 0, imgWidth, 23)
  }

  FastBlur {
    anchors.fill: parent
    source: bgImg
    radius: 36
  }

  Process {
    id: statProcess
    command: ["stat", "-c", "%Y", wallpaperPath]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        var mtime = parseInt(this.text.trim())
        if (mtime !== lastModtime) {
          lastModtime = mtime

          backgroundRoot.currentPath = backgroundRoot.wallpaperPath + "?t=" + Date.now()

          print("Reloading bar background image")
        }
      }
    }
  }

  Timer {
    interval: 2000 // Every 2s
    running: true
    repeat: true
    onTriggered: statProcess.running = true
  }
}