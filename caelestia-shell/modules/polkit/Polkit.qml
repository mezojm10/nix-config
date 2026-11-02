pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

// Polkit authentication agent. Registers with the system polkit daemon and
// shows a password dialog on the focused monitor whenever an application asks
// for elevated privileges.
Scope {
    id: root

    readonly property var flow: agent.flow
    readonly property ShellScreen activeScreen: Screens.screens.find(s => s.name === (Hypr.focusedMonitor?.name ?? "")) ?? Screens.screens[0]

    // Pin the dialog to the monitor that was focused when the request arrived,
    // so switching focus mid-prompt does not move it.
    property ShellScreen targetScreen

    onFlowChanged: targetScreen = flow ? activeScreen : null

    PolkitAgent {
        id: agent
    }

    // qmllint disable uncreatable-type
    PanelWindow {
        // qmllint enable uncreatable-type
        id: window

        readonly property bool active: root.flow !== null

        screen: root.targetScreen ?? root.activeScreen ?? Quickshell.screens[0]
        visible: active
        color: "transparent"

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "caelestia-polkit"
        WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        Shortcut {
            sequence: "Escape"
            enabled: window.active
            onActivated: root.flow?.cancelAuthenticationRequest()
        }

        StyledRect {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3scrim, 0.6)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.flow?.cancelAuthenticationRequest()
        }

        Loader {
            id: content

            anchors.centerIn: parent
            active: window.active

            sourceComponent: AuthDialog {
                flow: root.flow
            }
        }
    }

    component AuthDialog: StyledRect {
        id: dialog

        required property var flow

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
            if (flow.isResponseRequired)
                password.forceActiveFocus();
        }

        onFlowChanged: {
            if (!flow)
                return;

            password.text = "";
            if (flow.isResponseRequired)
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
            if (!flow.isResponseRequired || password.text.length === 0)
                return;

            const value = password.text;
            password.text = "";
            flow.submit(value);
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
                    source: Quickshell.iconPath(dialog.flow.iconName, "dialog-password")
                    sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
                    sourceSize.height: height * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
                    fillMode: Image.PreserveAspectFit
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: dialog.flow.message
                    font: Tokens.font.title.small
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall
                visible: dialog.flow.identities.length > 1

                Repeater {
                    model: dialog.flow.identities

                    StyledRadioButton {
                        required property var modelData

                        Layout.fillWidth: true
                        text: modelData.displayName || modelData.string
                        checked: dialog.flow.selectedIdentity === modelData
                        onClicked: {
                            dialog.flow.selectedIdentity = modelData;
                            password.text = "";
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: dialog.flow.supplementaryMessage
                color: dialog.flow.supplementaryIsError ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            StyledTextField {
                id: password

                Layout.fillWidth: true
                visible: dialog.flow.isResponseRequired
                focus: true
                placeholderText: dialog.flow.inputPrompt || Tr.tr("Password")
                leadingIcon: "lock"
                echoMode: dialog.flow.responseVisible ? TextInput.Normal : TextInput.Password
                onAccepted: dialog.submit()
            }

            RowLayout {
                Layout.topMargin: Tokens.spacing.small
                Layout.alignment: Qt.AlignRight
                spacing: Tokens.spacing.medium

                TextButton {
                    text: Tr.trCtx("Cancel", "button")
                    type: TextButton.Text
                    onClicked: dialog.flow.cancelAuthenticationRequest()
                }

                TextButton {
                    visible: dialog.flow.isResponseRequired
                    text: Tr.trCtx("Authenticate", "button")
                    type: TextButton.Filled
                    disabled: password.text.length === 0
                    onClicked: dialog.submit()
                }
            }
        }

        Connections {
            target: dialog.flow

            function onIsResponseRequiredChanged(): void {
                if (dialog.flow.isResponseRequired)
                    password.forceActiveFocus();
            }

            function onAuthenticationFailed(): void {
                password.text = "";
                password.forceActiveFocus();
            }

            function onInputPromptChanged(): void {
                password.text = "";
                if (dialog.flow.isResponseRequired)
                    password.forceActiveFocus();
            }
        }
    }
}
