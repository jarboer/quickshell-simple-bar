import QtQuick
import QtQuick.Layouts
import ".."

Text {
    required property string value
    property string title: ""
    property int level: 0

    Layout.leftMargin: 17 + level * 10
    visible: value !== "" && value != "unknown" // && value != "00:00:00:00:00:00"
    text: title + value
    color: Theme.colFg
    font.pixelSize: Theme.fontSize - 1
    font.family: Theme.fontFamily
    Layout.fillWidth: true
    elide: Text.ElideRight
}