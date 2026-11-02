pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

// Backend for ssh(1)'s SSH_ASKPASS. `caelestia-askpass` asks the shell over a
// unix socket for a secret and the request is shown with the same dialog as
// the polkit agent.
Scope {
    id: root

    property var request: null

    readonly property ShellScreen activeScreen: Screens.screens.find(s => s.name === (Hypr.focusedMonitor?.name ?? "")) ?? Screens.screens[0]

    // Pin the dialog to the monitor that was focused when the request arrived.
    property ShellScreen targetScreen

    function respond(socket, message) {
        socket.write(`${JSON.stringify(message)}\n`);
        socket.flush();
        socket.connected = false;
    }

    function finish(message) {
        if (!root.request)
            return;

        const socket = root.request.socket;
        root.request = null;
        root.respond(socket, message);
    }

    function receive(socket, line) {
        let data = null;
        try {
            data = JSON.parse(line);
        } catch (e) {
            data = null;
        }

        if (!data || typeof data.prompt !== "string") {
            root.respond(socket, {error: "invalid request"});
            return;
        }

        if (root.request) {
            root.respond(socket, {error: "busy"});
            return;
        }

        root.targetScreen = root.activeScreen;
        root.request = {
            socket,
            prompt: data.prompt
        };
    }

    SocketServer {
        active: true
        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/caelestia-askpass.sock`

        handler: Component {
            Socket {
                id: socket

                onConnectedChanged: {
                    if (!socket.connected && root.request?.socket === socket)
                        root.request = null;
                }

                parser: SplitParser {
                    onRead: line => root.receive(socket, line)
                }
            }
        }
    }

    PanelWindow {
        id: window

        readonly property bool active: root.request !== null

        screen: root.targetScreen ?? root.activeScreen ?? Quickshell.screens[0]
        visible: active
        color: "transparent"

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "caelestia-askpass"
        WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        Shortcut {
            sequence: "Escape"
            enabled: window.active
            onActivated: root.finish({cancelled: true})
        }

        StyledRect {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3scrim, 0.6)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.finish({cancelled: true})
        }

        Loader {
            anchors.centerIn: parent
            active: window.active

            sourceComponent: Dialog {}
        }
    }

    component Dialog: StyledRect {
        id: dialog

        readonly property real availableWidth: (QsWindow.window as QsWindow)?.width ?? 0

        width: Math.min(Math.max(availableWidth - Tokens.padding.extraLargeIncreased * 2, 0), 440)
        implicitHeight: layout.implicitHeight + Tokens.padding.extraLarge * 2

        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainerHigh
        opacity: 0
        scale: 0.9

        Component.onCompleted: {
            opacity = 1;
            scale = 1;
            password.forceActiveFocus();
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }

        function submit(): void {
            if (password.text.length === 0)
                return;

            const value = password.text;
            password.text = "";
            root.finish({response: value});
        }

        // Swallow clicks so they do not cancel the request through the scrim.
        MouseArea {
            anchors.fill: parent
        }

        Elevation {
            anchors.fill: parent
            radius: parent.radius
            z: -1
            level: 3
        }

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraLarge
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                Image {
                    Layout.alignment: Qt.AlignTop
                    width: 40
                    height: 40
                    source: Quickshell.iconPath("dialog-password", "dialog-password")
                    sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
                    sourceSize.height: height * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
                    fillMode: Image.PreserveAspectFit
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: root.request?.prompt ?? ""
                    font: Tokens.font.title.small
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }
            }

            StyledTextField {
                id: password

                Layout.fillWidth: true
                focus: true
                placeholderText: Tr.tr("Password")
                leadingIcon: "lock"
                echoMode: TextInput.Password
                onAccepted: dialog.submit()
            }

            RowLayout {
                Layout.topMargin: Tokens.spacing.small
                Layout.alignment: Qt.AlignRight
                spacing: Tokens.spacing.medium

                TextButton {
                    text: Tr.trCtx("Cancel", "button")
                    type: TextButton.Text
                    onClicked: root.finish({cancelled: true})
                }

                TextButton {
                    text: Tr.trCtx("Authenticate", "button")
                    type: TextButton.Filled
                    disabled: password.text.length === 0
                    onClicked: dialog.submit()
                }
            }
        }
    }
}
