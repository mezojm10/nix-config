import QtQuick
import Quickshell
import Quickshell.Wayland
import "Theme.js" as Theme

// Vertical OSD on the right edge, matching Marble's OSD placement.
Scope {
    id: root

    property var monitor
    property var shellState

    PanelWindow {
        screen: root.monitor
        anchors {
            right: true
        }
        margins {
            // Step aside while the control center is open.
            right: root.shellState && root.shellState.quickSettingsOpen ? 404 : 24
        }

        implicitWidth: 58
        implicitHeight: column.implicitHeight + 28
        visible: root.shellState && root.shellState.osdVisible
        color: "transparent"
        exclusiveZone: 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Theme.alpha(Theme.bg, 0.95)
            border.width: 1
            border.color: Theme.alpha(Theme.surfaceAlt, 0.9)

            Column {
                id: column

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 12
                }
                spacing: 8

                Text {
                    width: parent.width
                    text: root.shellState ? root.shellState.osdIcon : ""
                    color: root.shellState ? root.shellState.osdAccent : Theme.blue
                    font.family: Theme.iconFont
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.shellState && root.shellState.osdValue >= 0
                    width: 5
                    height: 96
                    radius: 3
                    color: Theme.alpha(Theme.surfaceAlt, 0.9)

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: parent.height * Math.max(0, Math.min(1, root.shellState ? root.shellState.osdValue : 0))
                        radius: parent.radius
                        color: root.shellState ? root.shellState.osdAccent : Theme.blue

                        Behavior on height {
                            NumberAnimation {
                                duration: 80
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: root.shellState ? root.shellState.osdLabel : ""
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 10
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
