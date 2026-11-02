import QtQuick
import "Theme.js" as Theme

// Marble-style media card. One card is created per MPRIS player, so every
// app that exposes a player can be controlled from the control center.
Rectangle {
    id: root

    property var player
    property bool showIdentity: false

    implicitHeight: 92
    radius: 13
    color: Theme.alpha(Theme.fg, 0.055)
    border.width: 1
    border.color: Theme.alpha(Theme.surfaceAlt, 0.7)

    readonly property real progress: player && player.length > 0
        ? Math.max(0, Math.min(1, player.position / player.length))
        : 0

    Row {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Rectangle {
            width: 72
            height: 72
            radius: 10
            color: Theme.surface
            clip: true

            Text {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                text: "\u{f001}"
                color: Theme.comment
                font.family: Theme.iconFont
                font.pixelSize: 24
            }

            Image {
                id: cover

                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Column {
            width: parent.width - 72 - 10
            spacing: 3

            Row {
                width: parent.width
                spacing: 4

                Column {
                    width: parent.width - (raiseButton.visible ? raiseButton.width + 4 : 0)
                    spacing: 1

                    Text {
                        width: parent.width
                        text: root.player ? (root.player.trackTitle || "Unknown track") : ""
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: {
                            if (!root.player)
                                return "";
                            const artist = root.player.trackArtist || "";
                            if (artist !== "")
                                return artist;
                            if (root.showIdentity)
                                return root.player.identity || "";
                            return "";
                        }
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                Item {
                    id: raiseButton

                    width: 22
                    height: 22
                    visible: root.player && root.player.canRaise

                    Text {
                        anchors.centerIn: parent
                        text: "\u{f08e}"
                        color: Theme.comment
                        font.family: Theme.iconFont
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player) root.player.raise()
                    }
                }
            }

            // Seek bar. Clicking seeks when the player supports it.
            Item {
                width: parent.width
                height: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 3
                    radius: 2
                    color: Theme.alpha(Theme.surfaceAlt, 0.9)

                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: 2
                        color: Theme.magenta
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.player && root.player.canSeek && root.player.length > 0
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                    onClicked: mouse => {
                        if (root.player && root.player.canSeek && root.player.length > 0)
                            root.player.position = root.player.length * (mouse.x / width);
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Text {
                    text: "\u{f04a}"
                    color: Theme.fgDim
                    opacity: root.player && root.player.canGoPrevious ? 1 : 0.35
                    font.family: Theme.iconFont
                    font.pixelSize: 13

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.player && root.player.canGoPrevious
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player) root.player.previous()
                    }
                }

                Text {
                    text: root.player && root.player.isPlaying ? "\u{f04c}" : "\u{f04b}"
                    color: Theme.magenta
                    opacity: root.player && root.player.canTogglePlaying ? 1 : 0.35
                    font.family: Theme.iconFont
                    font.pixelSize: 16

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.player && root.player.canTogglePlaying
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player) root.player.togglePlaying()
                    }
                }

                Text {
                    text: "\u{f04e}"
                    color: Theme.fgDim
                    opacity: root.player && root.player.canGoNext ? 1 : 0.35
                    font.family: Theme.iconFont
                    font.pixelSize: 13

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.player && root.player.canGoNext
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player) root.player.next()
                    }
                }
            }
        }
    }
}
