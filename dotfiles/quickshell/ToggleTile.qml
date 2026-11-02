import QtQuick
import "Theme.js" as Theme

// Large quick-settings toggle, modelled on Marble's Wi-Fi/Bluetooth/DND tiles.
Item {
    id: root

    property string glyph: ""
    property string label: ""
    property string subtitle: ""
    property bool active: false
    property color accent: Theme.blue

    signal clicked()

    implicitWidth: 160
    implicitHeight: 62

    Rectangle {
        anchors.fill: parent
        radius: 13

        color: root.active
            ? Theme.alpha(root.accent, 0.24)
            : (hover.hovered ? Theme.alpha(Theme.fg, 0.10) : Theme.alpha(Theme.fg, 0.055))

        border.width: 1
        border.color: root.active
            ? Theme.alpha(root.accent, 0.65)
            : Theme.alpha(Theme.surfaceAlt, 0.7)

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 140
            }
        }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            color: root.active ? root.accent : Theme.fgDim
            font.family: Theme.iconFont
            font.pixelSize: 19
        }

        Column {
            width: parent.width - 29 - 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: root.label
                color: root.active ? Theme.fg : Theme.fgDim
                font.family: Theme.font
                font.pixelSize: 12
                font.bold: root.active
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.subtitle
                color: Theme.comment
                font.family: Theme.font
                font.pixelSize: 10
                elide: Text.ElideRight
            }
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
