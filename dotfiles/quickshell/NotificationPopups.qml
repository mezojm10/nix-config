import QtQuick
import Quickshell
import Quickshell.Wayland
import "Theme.js" as Theme

// Quickshell owns org.freedesktop.Notifications now, so popups are drawn here
// instead of mako. Up to four notifications are stacked below the bar.
Scope {
    id: root

    property var monitor
    property var shellState
    property var notifications

    property var popups: []
    property int tick: 0

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.tick++
    }

    function add(notification) {
        if (root.shellState && root.shellState.dnd)
            return;

        const next = [notification];

        for (let i = 0; i < root.popups.length; i++)
            if (root.popups[i] !== notification)
                next.push(root.popups[i]);

        root.popups = next.slice(0, 4);
    }

    function remove(notification) {
        const index = root.popups.indexOf(notification);

        if (index === -1)
            return;

        const next = root.popups.slice();

        next.splice(index, 1);
        root.popups = next;
    }

    Connections {
        target: root.notifications

        function onNotification(notification) {
            // Tracked notifications stay in the control center after the
            // popup has disappeared.
            notification.tracked = true;

            if (root.shellState)
                root.shellState.addNotification(notification);

            // A reload re-emits everything the server is tracking. Do not
            // replay old popups for those.
            if (notification.lastGeneration)
                return;

            // The control center already shows them.
            if (root.shellState && root.shellState.quickSettingsOpen)
                return;

            root.add(notification);
        }
    }

    PanelWindow {
        screen: root.monitor
        anchors {
            top: true
            right: true
        }
        margins {
            top: 48
            right: 8
        }

        implicitWidth: 380
        implicitHeight: column.childrenRect.height
        visible: root.popups.length > 0
            && !(root.shellState && root.shellState.quickSettingsOpen)
        color: "transparent"
        exclusiveZone: 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-popups"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Column {
            id: column

            width: parent.width
            spacing: 8

            Repeater {
                model: root.popups

                Rectangle {
                    id: popup

                    required property var modelData

                    readonly property double arrived: Date.now()
                    property real remaining: 1

                    function timeLabel() {
                        root.tick;
                        return Theme.timeAgo(arrived);
                    }

                    width: column.width
                    height: body.implicitHeight + 22
                    radius: 14
                    color: Theme.alpha(Theme.bg, 0.96)
                    border.width: 1
                    border.color: Theme.alpha(Theme.surfaceAlt, 0.9)
                    clip: true
                    opacity: 0

                    Component.onCompleted: opacity = 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 160
                        }
                    }

                    Timer {
                        interval: 5000
                        running: !hover.hovered
                        onTriggered: root.remove(popup.modelData)
                    }

                    HoverHandler {
                        id: hover
                    }

                    Connections {
                        target: popup.modelData

                        function onClosed() {
                            root.remove(popup.modelData);
                        }
                    }

                    NumberAnimation on remaining {
                        from: 1
                        to: 0
                        duration: 5000
                        running: !hover.hovered
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: 14
                            rightMargin: 14
                        }
                        height: 1
                        radius: 1
                        color: Theme.alpha(Theme.blue, 0.3)
                    }

                    Column {
                        id: body

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 10
                        }
                        spacing: 4

                        Row {
                            width: parent.width
                            spacing: 6

                            Item {
                                width: 16
                                height: 16
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    visible: icon.status !== Image.Ready
                                    text: "\u{f0f3}"
                                    color: Theme.yellow
                                    font.family: Theme.iconFont
                                    font.pixelSize: 12
                                }

                                Image {
                                    id: icon

                                    anchors.fill: parent
                                    source: popup.modelData.appIcon
                                        ? Quickshell.iconPath(popup.modelData.appIcon, true)
                                        : ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }
                            }

                            Text {
                                width: parent.width - 16 - 34 - 20 - 18
                                anchors.verticalCenter: parent.verticalCenter
                                text: popup.modelData.appName || "Notification"
                                color: Theme.comment
                                font.family: Theme.font
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            Text {
                                width: 34
                                anchors.verticalCenter: parent.verticalCenter
                                text: popup.timeLabel()
                                color: Theme.comment
                                font.family: Theme.font
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                width: 20
                                height: 20
                                text: "\u{f00d}"
                                color: Theme.comment
                                font.family: Theme.iconFont
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.shellState)
                                            root.shellState.dismissNotification(popup.modelData);
                                        else if (popup.modelData)
                                            popup.modelData.dismiss();

                                        root.remove(popup.modelData);
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 8

                            Column {
                                width: parent.width - (notificationImage.visible ? 68 : 0)
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: popup.modelData.summary
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    visible: text !== ""
                                    text: popup.modelData.body
                                    color: Theme.fgDim
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }

                            Image {
                                id: notificationImage

                                width: 60
                                height: 60
                                visible: source !== ""
                                source: popup.modelData.image || ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 6
                            visible: popup.modelData.actions.length > 0

                            Repeater {
                                model: popup.modelData.actions

                                Rectangle {
                                    id: actionButton

                                    required property var modelData

                                    width: actionLabel.implicitWidth + 16
                                    height: 22
                                    radius: 7
                                    color: actionHover.hovered
                                        ? Theme.alpha(Theme.blue, 0.3)
                                        : Theme.alpha(Theme.blue, 0.18)

                                    Text {
                                        id: actionLabel

                                        anchors.centerIn: parent
                                        text: actionButton.modelData.text
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                    }

                                    HoverHandler {
                                        id: actionHover

                                        cursorShape: Qt.PointingHandCursor
                                    }

                                    TapHandler {
                                        onTapped: actionButton.modelData.invoke()
                                    }
                                }
                            }
                        }
                    }

                    // Popup timeout bar, paused while hovered.
                    Rectangle {
                        anchors {
                            left: parent.left
                            bottom: parent.bottom
                        }
                        width: parent.width * popup.remaining
                        height: 2
                        color: Theme.alpha(Theme.blue, 0.55)
                    }
                }
            }
        }
    }
}
