import QtQuick
import "Theme.js" as Theme

// Minimal slider with the same geometry as Marble's volume/brightness rows.
Item {
    id: root

    property real value: 0
    property color fillColor: Theme.blue
    property color trackColor: Theme.alpha(Theme.surfaceAlt, 0.9)

    signal moved(real value)

    implicitWidth: 160
    implicitHeight: 24

    function clamp(value) {
        return Math.max(0, Math.min(1, value));
    }

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 5
        radius: 3
        color: root.trackColor

        Rectangle {
            width: track.width * root.clamp(root.value)
            height: parent.height
            radius: parent.radius
            color: root.fillColor

            Behavior on width {
                NumberAnimation {
                    duration: 90
                }
            }
        }
    }

    Rectangle {
        width: 13
        height: 13
        radius: 7
        x: Math.max(0, Math.min(parent.width - width, parent.width * root.clamp(root.value) - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        color: root.fillColor
        border.width: 2
        border.color: Theme.bg
    }

    MouseArea {
        id: area

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function update(mouse) {
            root.moved(root.clamp(mouse.x / root.width));
        }

        onPressed: mouse => update(mouse)
        onPositionChanged: mouse => {
            if (area.pressed)
                update(mouse);
        }

        onWheel: wheel => {
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.moved(root.clamp(root.value + step));
        }
    }
}
