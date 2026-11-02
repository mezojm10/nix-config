import QtQuick
import Quickshell
import Quickshell.Wayland
import "Theme.js" as Theme

// Marble's confirmation dialog, replacing wlogout. Every monitor gets one so
// the choice is visible regardless of which output has focus.
Scope {
    id: root

    property var monitor
    property var shellState

    readonly property string action: shellState ? shellState.powerAction : ""

    readonly property string title: {
        if (action === "reboot")
            return "Reboot";
        if (action === "logout")
            return "Log Out";
        return "Power Off";
    }

    readonly property string subtitle: {
        if (action === "reboot")
            return "Are you sure you want to reboot?";
        if (action === "logout")
            return "Are you sure you want to log out?";
        return "Are you sure you want to shut down?";
    }

    readonly property string glyph: {
        if (action === "reboot")
            return "\u{f01e}";
        if (action === "logout")
            return "\u{f08b}";
        return "\u{f0425}";
    }

    function confirm() {
        const choice = action;

        root.shellState.closePower();

        if (choice === "reboot")
            Quickshell.execDetached(["systemctl", "reboot"]);
        else if (choice === "logout")
            Quickshell.execDetached(["loginctl", "terminate-user", String(Quickshell.env("USER"))]);
        else if (choice === "poweroff")
            Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    PanelWindow {
        screen: root.monitor
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        visible: root.action !== ""
        color: "transparent"
        exclusiveZone: 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-power"
        WlrLayershell.keyboardFocus: root.action !== ""
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        Item {
            anchors.fill: parent
            focus: true

            Keys.onEscapePressed: root.shellState.closePower()

            Rectangle {
                anchors.fill: parent
                color: Theme.alpha(Theme.bgDeep, 0.6)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.shellState.closePower()
                }
            }

            Rectangle {
                id: card

                width: 340
                implicitHeight: content.implicitHeight + 36
                anchors.centerIn: parent
                radius: 20
                color: Theme.bg
                border.width: 1
                border.color: Theme.alpha(Theme.surfaceAlt, 0.9)

                // Swallow clicks on the card so the shade does not close it.
                MouseArea {
                    anchors.fill: parent
                }

                Column {
                    id: content

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 18
                    }
                    spacing: 4

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 52
                        height: 52
                        radius: 26
                        color: root.action === "reboot" ? Theme.alpha(Theme.blue, 0.2)
                            : (root.action === "logout" ? Theme.alpha(Theme.yellow, 0.18)
                                : Theme.alpha(Theme.red, 0.18))

                        Text {
                            anchors.centerIn: parent
                            text: root.glyph
                            color: root.action === "reboot" ? Theme.blue
                                : (root.action === "logout" ? Theme.yellow : Theme.red)
                            font.family: Theme.iconFont
                            font.pixelSize: 23
                        }
                    }

                    Text {
                        width: parent.width
                        topPadding: 8
                        text: root.title
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 20
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        bottomPadding: 14
                        text: root.subtitle
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Row {
                        width: parent.width
                        spacing: 12

                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: 38
                            radius: 10
                            color: hoverCancel.hovered
                                ? Theme.alpha(Theme.fg, 0.12)
                                : Theme.alpha(Theme.fg, 0.06)
                            border.width: 1
                            border.color: Theme.alpha(Theme.surfaceAlt, 0.8)

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 12
                            }

                            HoverHandler {
                                id: hoverCancel

                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: root.shellState.closePower()
                            }
                        }

                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: 38
                            radius: 10
                            color: hoverConfirm.hovered ? Theme.red : Theme.alpha(Theme.red, 0.82)

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "Yes"
                                color: Theme.bg
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.bold: true
                            }

                            HoverHandler {
                                id: hoverConfirm

                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: root.confirm()
                            }
                        }
                    }
                }
            }
        }
    }
}
