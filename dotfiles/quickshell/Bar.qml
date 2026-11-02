import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Networking
import Quickshell.Bluetooth
import "Theme.js" as Theme

PanelWindow {
    id: bar

    property var modelData
    property var shellState
    property var workspaces: []

    readonly property string screenName: screen ? screen.name : ""

    readonly property var visibleWorkspaces: workspaces
        .filter(workspace => workspace.output === screenName)
        .sort((a, b) => a.idx - b.idx)

    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    readonly property bool hasMedia: player !== null

    readonly property int notificationCount: shellState
        ? shellState.notificationHistory.length
        : 0

    readonly property bool controlCenterOpen: !!shellState
        && shellState.quickSettingsOpen
        && shellState.quickSettingsScreen === screenName

    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothOn: bluetoothAdapter ? bluetoothAdapter.enabled : false

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 6
        left: 8
        right: 8
    }

    implicitHeight: 36
    color: "transparent"

    // Keep the wallpaper visible behind the bar. Niri's top strut below
    // reserves the same space for windows.
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    IdleInhibitor {
        window: bar
        enabled: bar.shellState ? bar.shellState.caffeine : false
    }

    Process {
        id: workspacesProcess

        command: ["niri", "msg", "--json", "workspaces"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    bar.workspaces = JSON.parse(text);
                } catch (error) {
                    // niri may not be ready yet during session startup.
                }
            }
        }
    }

    Timer {
        interval: 750
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            if (!workspacesProcess.running)
                workspacesProcess.running = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.alpha(Theme.bg, 0.82)
        border.width: 1
        border.color: Theme.alpha(Theme.surfaceAlt, 0.85)

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
            color: Theme.alpha(Theme.blue, 0.28)
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        // ------------------------------------------------------------ left

        RowLayout {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            spacing: 10

            BarButton {
                glyph: "\u{f06d}"
                glyphColor: Theme.blue
                iconSize: 16

                onClicked: Quickshell.execDetached(["fuzzel"])
            }

            Rectangle {
                width: 1
                height: 16
                color: Theme.alpha(Theme.surfaceAlt, 0.8)
                Layout.alignment: Qt.AlignVCenter
            }

            Row {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: bar.visibleWorkspaces

                    Rectangle {
                        id: workspacePill

                        required property var modelData

                        width: Math.max(24, workspaceLabel.implicitWidth + 14)
                        height: 24
                        radius: 8
                        color: modelData.is_focused
                            ? Theme.blue
                            : (modelData.is_active ? Theme.surface : "transparent")

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Text {
                            id: workspaceLabel

                            anchors.centerIn: parent
                            text: modelData.name ? modelData.name : modelData.idx
                            color: modelData.is_focused ? Theme.bg : Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.bold: modelData.is_focused
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: Quickshell.execDetached([
                                "niri", "msg", "action", "focus-workspace",
                                String(workspacePill.modelData.idx)
                            ])
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // ---------------------------------------------------------- center

        Text {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            text: Qt.formatDateTime(clock.date, "HH:mm - dddd d.")
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 13
            font.bold: true
        }

        Item {
            Layout.fillWidth: true
        }

        // ----------------------------------------------------------- right

        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 8

            Rectangle {
                visible: SystemTray.items.values.length > 0
                width: 1
                height: 16
                color: Theme.alpha(Theme.surfaceAlt, 0.8)
                Layout.alignment: Qt.AlignVCenter
            }

            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: SystemTray.items

                    Item {
                        id: trayItem

                        required property var modelData

                        width: 18
                        height: 18
                        visible: modelData.icon !== ""

                        // `icon` is already an image source, not an icon name.
                        IconImage {
                            anchors.fill: parent
                            source: trayItem.modelData.icon
                            implicitSize: 16
                        }

                        // Drops the menu below the icon, right-aligned to it.
                        QsMenuAnchor {
                            id: trayMenu

                            menu: trayItem.modelData.menu
                            anchor.item: trayItem
                            anchor.edges: Edges.Bottom | Edges.Right
                            anchor.gravity: Edges.Bottom | Edges.Left
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor

                            // Menu-only items (Steam and other AppIndicator
                            // apps) ignore activation, so left click opens
                            // their menu instead.
                            onClicked: mouse => {
                                const item = trayItem.modelData;

                                if (mouse.button === Qt.LeftButton && !item.onlyMenu)
                                    item.activate();
                                else if (item.hasMenu)
                                    trayMenu.open();
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: SystemTray.items.values.length > 0
                width: 1
                height: 16
                color: Theme.alpha(Theme.surfaceAlt, 0.8)
                Layout.alignment: Qt.AlignVCenter
            }

            StatusCluster {
                Layout.alignment: Qt.AlignVCenter

                wifiAvailable: Networking.wifiHardwareEnabled
                wifiEnabled: Networking.wifiEnabled
                bluetoothAvailable: bar.bluetoothAdapter !== null
                bluetoothEnabled: bar.bluetoothOn
                hasMedia: bar.hasMedia
                playing: bar.player !== null && bar.player.isPlaying
                volume: bar.volume
                muted: bar.muted
                hasMic: bar.hasMicrophone
                micMuted: bar.micMuted
                hasBattery: bar.hasBattery
                batteryPercent: bar.batteryPercent
                charging: bar.charging
                dnd: bar.shellState ? bar.shellState.dnd : false
                notificationCount: bar.notificationCount
                active: bar.controlCenterOpen

                onClicked: bar.shellState.toggleQuickSettings(bar.screenName)
            }

            BarButton {
                glyph: "\u{f0425}"
                glyphColor: Theme.red
                iconSize: 15

                onClicked: bar.shellState.openPower("poweroff")
            }
        }
    }

    // ------------------------------------------------------------- volume

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property int volume: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false

    readonly property var source: Pipewire.defaultAudioSource
    readonly property var microphone: source ? source.audio : null
    readonly property bool hasMicrophone: microphone !== null
    readonly property bool micMuted: microphone ? microphone.muted : false

    // ------------------------------------------------------------ battery

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery !== null && battery.isLaptopBattery
    readonly property int batteryPercent: hasBattery ? Math.round(battery.percentage * 100) : 0
    readonly property bool charging: hasBattery && battery.state === UPowerDeviceState.Charging
}
