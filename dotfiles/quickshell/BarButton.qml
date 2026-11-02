import QtQuick
import "Theme.js" as Theme

// Small hover pill used throughout the bar and the control center header.
Item {
    id: root

    property string glyph: ""
    property string text: ""
    property color glyphColor: Theme.fgDim
    property color textColor: Theme.fgDim
    property bool active: false
    property color accent: Theme.blue
    property int iconSize: 14
    property int fontSize: 12
    property int horizontalPadding: 8
    property int spacing: 5

    signal clicked()

    implicitWidth: content.implicitWidth + horizontalPadding * 2
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: 8

        color: root.active
            ? Theme.alpha(root.accent, 0.22)
            : Theme.alpha(Theme.fg, 0.09)

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
        spacing: root.spacing

        Text {
            visible: root.glyph !== ""
            text: root.glyph
            color: root.glyphColor
            font.family: Theme.iconFont
            font.pixelSize: root.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.text !== ""
            text: root.text
            color: root.textColor
            font.family: Theme.font
            font.pixelSize: root.fontSize
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
