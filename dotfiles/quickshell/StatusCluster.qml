import QtQuick
import Quickshell.Services.UPower
import "Theme.js" as Theme

// Marble groups the status indicators into one button that opens the control
// center. Clicking the cluster is the primary way to open it from the bar.
Item {
    id: root

    property bool wifiAvailable: false
    property bool wifiEnabled: false
    property bool bluetoothAvailable: false
    property bool bluetoothEnabled: false
    property bool hasMedia: false
    property bool playing: false
    property int volume: 0
    property bool muted: false
    property bool hasMic: false
    property bool micMuted: false
    property bool hasBattery: false
    property int batteryPercent: 0
    property bool charging: false
    property bool dnd: false
    property int notificationCount: 0
    property bool active: false

    signal clicked()

    readonly property int powerProfile: PowerProfiles.profile
    readonly property bool showPowerProfile: PowerProfiles.hasPerformanceProfile
        && powerProfile !== PowerProfile.Balanced

    implicitWidth: content.implicitWidth + 18
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.active ? Theme.alpha(Theme.blue, 0.22) : Theme.alpha(Theme.fg, 0.09)
        opacity: root.active || hover.hovered ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: 7

        Text {
            visible: root.hasMedia
            text: root.playing ? "\u{f04c}" : "\u{f04b}"
            color: Theme.magenta
            font.family: Theme.iconFont
            font.pixelSize: 10
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.notificationCount > 0 || root.dnd
            text: root.dnd ? "\u{f1f7}" : "\u{f0f3}"
            color: root.dnd ? Theme.red : Theme.yellow
            font.family: Theme.iconFont
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.notificationCount > 0
            text: String(root.notificationCount)
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 10
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.wifiAvailable
            text: "\u{f05a9}"
            color: root.wifiEnabled ? Theme.blue : Theme.comment
            font.family: Theme.iconFont
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.bluetoothAvailable
            text: "\u{f00af}"
            color: root.bluetoothEnabled ? Theme.blue : Theme.comment
            font.family: Theme.iconFont
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.showPowerProfile
            text: "\u{f0e7}"
            color: root.powerProfile === PowerProfile.Performance ? Theme.yellow : Theme.cyan
            font.family: Theme.iconFont
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: Theme.volumeIcon(root.volume, root.muted)
            color: root.muted ? Theme.red : Theme.cyan
            font.family: Theme.iconFont
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.hasMic
            text: root.micMuted ? "\u{f131}" : "\u{f130}"
            color: root.micMuted ? Theme.red : Theme.comment
            font.family: Theme.iconFont
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.hasBattery
            text: Theme.batteryIcon(root.batteryPercent, root.charging)
            color: root.charging
                ? Theme.green
                : (root.batteryPercent < 15 ? Theme.red : Theme.yellow)
            font.family: Theme.iconFont
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.hasBattery
            text: root.batteryPercent + "%"
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    HoverHandler {
        id: hover

        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.clicked()
    }
}
