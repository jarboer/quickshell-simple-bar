import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

DropdownWidget {
    id: ethernetWidget
    popupWidth: 340
    popupHeight: 400 //Math.min(networks.length * 60 + 50, 650)
    popupXOffset: 250

    property string networkName: ""
    property string networkDevice: ""
    property bool ethernetConnected: false
    property var networks: []

    // Network speed tracking
    property real downloadSpeed: 0  // bytes per second
    property real uploadSpeed: 0
    property real lastRxBytes: 0
    property real lastTxBytes: 0

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(0) + " K/s"
        return (bytesPerSec / 1024 / 1024).toFixed(1) + " M/s"
    }

    function splitValue(value) {
        value = value.trim()

        // No equals -> return as string
        if (!value.includes(" = "))
            return value

        // Split comma-separated pairs
        const parts = value.split(",").map(p => p.trim())

        // Single pair -> { key: value }
        if (parts.length === 1) {
            const idx = parts[0].indexOf(" = ")
            const obj = {}
            obj[parts[0].slice(0, idx).toUpperCase()] = parts[0].slice(idx + 3)
            return obj
        }

        // Multiple pairs -> { k1: v1, k2: v2 }
        const obj = {}
        parts.forEach(p => {
            const idx = p.indexOf(" = ")
            if (idx === -1) return
            obj[p.slice(0, idx).toUpperCase()] = p.slice(idx + 3)
        })

        return obj
    }

    function mergeOption(target, value) {
        // value is already { key: val }
        for (let k in value) {
            target[k] = value[k]
        }
    }

    onOpened: networkScanProc.running = true

    // Ethernet current connection
    Process {
        id: ethernetCurrentProc
        command: ["sh", "-c", "nmcli -t -f CONNECTION,DEVICE,TYPE,STATE device status | grep ':ethernet:connected'"]
        stdout: SplitParser {
            onRead: data => {
                if (!data || !data.trim()) {
                    ethernetWidget.ethernetConnected = false
                    ethernetWidget.networkName = ""
                    return
                }
                var parts = data.trim().split(':')
                if (parts.length >= 3) {
                    ethernetWidget.ethernetConnected = true
                    ethernetWidget.networkName = parts[0]
                    ethernetWidget.networkDevice = parts[1]
                }
            }
        }
        Component.onCompleted: running = true
    }

    // WiFi network scan
    Process {
        id: networkScanProc
        property string output: ""
        command: ["sh", "-c", "nmcli -t -f GENERAL,CAPABILITIES,INTERFACE-FLAGS,IP4,DHCP4,IP6 device show | grep -v '^:'"]
        stdout: SplitParser {
            onRead: data => {
                if (data) networkScanProc.output += data + "\n"
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else if (output) {
                var networks = []

                output.trim().split("\n\n").forEach(block => {
                    var dev = {}

                    block.split("\n").forEach(line => {
                        const idx = line.indexOf(":")
                        if (idx === -1) return

                        let key = line.slice(0, idx)
                        let value = splitValue(line.slice(idx + 1))

                        // Split SECTION.KEY
                        let parts = key.split(".")
                        let section = parts[0]
                        let field = parts.slice(1).join("_")

                        if (!dev[section]) dev[section] = {}

                        // Handle repeated keys like ADDRESS[1]
                        if (field.match(/\[\d+\]/)) {
                            field = field.replace(/\[\d+\]/, "")

                            // Special-case DHCP4.OPTION -> object
                            if (section === "DHCP4" && field === "OPTION") {
                                if (!dev[section][field])
                                    dev[section][field] = {}
                                if (typeof value === "object")
                                    mergeOption(dev[section][field], value)
                            } else {
                                if (!Array.isArray(dev[section][field]))
                                    dev[section][field] = []
                                dev[section][field].push(value)
                            }
                        } else {
                            dev[section][field] = value
                        }

                        print(section + "." + field + " = " + value)
                    })

                    networks.push(dev)
                })

                // print(JSON.stringify(networks, null, 2))
                ethernetWidget.networks = networks
            }
        }
    }

    // Network speed process
    Process {
        id: netSpeedProc
        command: ["sh", "-c", "cat /proc/net/dev | grep -E 'en' | head -1"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                if (parts.length >= 10) {
                    var rxBytes = parseFloat(parts[1]) || 0
                    var txBytes = parseFloat(parts[9]) || 0

                    if (ethernetWidget.lastRxBytes > 0) {
                        ethernetWidget.downloadSpeed = rxBytes - ethernetWidget.lastRxBytes
                        ethernetWidget.uploadSpeed = txBytes - ethernetWidget.lastTxBytes
                    }
                    ethernetWidget.lastRxBytes = rxBytes
                    ethernetWidget.lastTxBytes = txBytes
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Update timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            ethernetCurrentProc.running = true
            netSpeedProc.running = true
        }
    }

    // Icon content
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            id: wifiText
            anchors.verticalCenter: parent.verticalCenter
            text: !ethernetConnected ? "󰈂" : "󰈁"
            color: ethernetConnected ? Theme.colNetwork : Theme.colMuted
            font.pixelSize: Theme.fontSize + 4
            font.family: Theme.fontFamily
            font.bold: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: ethernetConnected
            text: formatSpeed(downloadSpeed)
            color: Theme.colNetwork
            font.pixelSize: Theme.fontSize - 2
            font.family: Theme.fontFamily
            width: 56
            horizontalAlignment: Text.AlignRight
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: ethernetConnected
            text: formatSpeed(uploadSpeed)
            color: Theme.colNetwork
            font.pixelSize: Theme.fontSize - 2
            font.family: Theme.fontFamily
            width: 56
            horizontalAlignment: Text.AlignRight
        }
    }

    // Popup content
    popupContent: Component {
        Column {
            spacing: 4

            // Header
            Text {
                text: ethernetWidget.ethernetConnected ? ethernetWidget.networkName : "Not Connected"
                color: Theme.colFg
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: true
                width: parent.width
                horizontalAlignment: Text.AlignLeft
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.colMuted
            }

            // Network list
            ListView {
                id: networkListView
                width: parent.width
                height: parent.height - 40
                clip: true
                model: ethernetWidget.networks
                spacing: 6

                delegate: Rectangle {
                    property int padding: 10

                    implicitWidth: networkListView.width
                    implicitHeight: content.height + padding * 2
                    // height: 100 // 36
                    color: mouseArea.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                    radius: 6

                    Item {
                        id: content
                        height: networkInfo.height
                        anchors.fill: parent
                        anchors.margins: padding
                    
                        ColumnLayout {
                            id: networkInfo

                            RowLayout {
                                spacing: 8

                                Text {
                                    text: modelData["INTERFACE-FLAGS"]["UP"] == "yes" ? "󰈁" : "󰈂"
                                    color: modelData["GENERAL"]["CONNECTION"] === ethernetWidget.networkName ? Theme.colNetwork : Theme.colFg
                                    font.pixelSize: Theme.fontSize
                                    font.family: Theme.fontFamily
                                }

                                Text {
                                    text: (modelData["GENERAL"]["CONNECTION"] === "lo" ? "Loopback" : modelData["GENERAL"]["CONNECTION"]) + " (" + modelData["GENERAL"]["DEVICE"] + ")"
                                    color: modelData["GENERAL"]["CONNECTION"] === ethernetWidget.networkName ? Theme.colNetwork : Theme.colFg
                                    font.pixelSize: Theme.fontSize - 1
                                    font.family: Theme.fontFamily
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            // Text {
                            //     Layout.leftMargin: 17
                            //     text: "MAC Address: " + modelData["GENERAL"]["HWADDR"]
                            //     color: Theme.colFg
                            //     font.pixelSize: Theme.fontSize - 1
                            //     font.family: Theme.fontFamily
                            //     Layout.fillWidth: true
                            //     elide: Text.ElideRight
                            // }

                            ListText {
                                value: modelData["GENERAL"]["HWADDR"]
                                title: "MAC Address: "
                            }

                            ListText {
                                value: modelData["CAPABILITIES"]["SPEED"]
                                title: "Speed: "
                            }

                            ListText {
                                value: "IPv4 Information"
                            }

                            ListText {
                                value: modelData["IP4"]["ADDRESS"][0]
                                title: "Address: "
                                level: 1
                            }

                            ListText {
                                value: modelData["IP4"]["GATEWAY"]
                                title: "Gateway: "
                                level: 1
                            }

                            ListText {
                                value: modelData["IP4"]["DNS"][0]
                                title: "DNS: "
                                level: 1
                            }

                            ListText {
                                value: modelData["IP4"]["DOMAIN"][0]
                                title: "Domain: "
                                level: 1
                            }
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        // cursorShape: Qt.PointingHandCursor
                        // onClicked: {
                        //     wifiConnectProc.targetSSID = modelData.ssid
                        //     wifiConnectProc.running = true
                        //     ethernetWidget.dropdownOpen = false
                        // }
                    }
                }
            }
        }
    }
}
