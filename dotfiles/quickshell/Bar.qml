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
import "Theme.js" as Theme

PanelWindow {
    id: bar

    property var modelData
    property var workspaces: []

    readonly property var visibleWorkspaces: workspaces.filter(workspace => workspace.output === screen.name)
    readonly property var focusedWorkspace: {
        for (const workspace of visibleWorkspaces)
            if (workspace.is_focused)
                return workspace;
        return null;
    }

    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

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
        objects: [Pipewire.defaultAudioSink]
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

    // CPU and memory counters, sampled together so the CPU percentage spans
    // the gap between two reads instead of a separate sleep.
    Process {
        id: statsProcess

        command: [
            "sh", "-c",
            "grep '^cpu ' /proc/stat; grep --extended-regexp '^(MemTotal|MemAvailable):' /proc/meminfo"
        ]

        stdout: StdioCollector {
            onStreamFinished: bar.updateStats(text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            if (!statsProcess.running)
                statsProcess.running = true;
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

            Text {
                text: "\u{f313}"
                color: Theme.blue
                font.family: Theme.iconFont
                font.pixelSize: 17
                Layout.alignment: Qt.AlignVCenter
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

        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            spacing: 12

            RowLayout {
                visible: bar.player !== null
                    && (bar.player.trackTitle !== "" || bar.player.trackArtist !== "")
                spacing: 6

                Text {
                    text: bar.player && bar.player.isPlaying ? "\u{f04b}" : "\u{f04c}"
                    color: Theme.magenta
                    font.family: Theme.iconFont
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    Layout.maximumWidth: 240
                    text: bar.player
                        ? (bar.player.trackTitle || "Unknown track")
                            + (bar.player.trackArtist ? "  ·  " + bar.player.trackArtist : "")
                        : ""
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.alignment: Qt.AlignVCenter
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: if (bar.player) bar.player.togglePlaying()
                }
            }

            Rectangle {
                visible: bar.player !== null
                    && (bar.player.trackTitle !== "" || bar.player.trackArtist !== "")
                width: 1
                height: 14
                color: Theme.alpha(Theme.surfaceAlt, 0.8)
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: Qt.formatDateTime(clock.date, "ddd dd MMM")
                color: Theme.comment
                font.family: Theme.font
                font.pixelSize: 12
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 13
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // ----------------------------------------------------------- right

        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 12

            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "\u{f0ee0}"
                        color: Theme.blue
                        font.family: Theme.iconFont
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: bar.cpuUsage + "%"
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "\u{f035b}"
                        color: Theme.purple
                        font.family: Theme.iconFont
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: bar.memUsage + "%"
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: Theme.volumeIcon(bar.volume, bar.muted)
                    color: bar.muted ? Theme.red : Theme.cyan
                    font.family: Theme.iconFont
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: bar.muted ? "muted" : bar.volume + "%"
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                    onTapped: (eventPoint, button) => {
                        if (button === Qt.MiddleButton)
                            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
                        else
                            Quickshell.execDetached(["pavucontrol"]);
                    }
                }
            }

            RowLayout {
                visible: bar.hasBattery
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: Theme.batteryIcon(bar.batteryPercent, bar.charging)
                    color: bar.charging ? Theme.green : (bar.batteryPercent < 15 ? Theme.red : Theme.yellow)
                    font.family: Theme.iconFont
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: bar.batteryPercent + "%"
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Rectangle {
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

                        IconImage {
                            anchors.fill: parent
                            source: Quickshell.iconPath(trayItem.modelData.icon)
                            implicitSize: 16
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor

                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton)
                                    trayItem.modelData.activate();
                                else
                                    trayItem.modelData.display(bar, mouse.x, mouse.y);
                            }
                        }
                    }
                }
            }

            Text {
                text: "\u{f0425}"
                color: Theme.red
                font.family: Theme.iconFont
                font.pixelSize: 15
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["wlogout"])
                }
            }
        }
    }

    // ------------------------------------------------------- system stats

    property int cpuUsage: 0
    property int memUsage: 0
    property var previousCpu: null

    function updateStats(text) {
        const lines = text.trim().split("\n");
        if (lines.length < 1)
            return;

        // user nice system idle iowait irq softirq steal
        const fields = lines[0].trim().split(/\s+/).slice(1, 9).map(Number);
        const total = fields.reduce((sum, value) => sum + value, 0);
        const idle = fields[3] + fields[4];

        if (previousCpu !== null) {
            const totalDelta = total - previousCpu.total;
            const idleDelta = idle - previousCpu.idle;
            if (totalDelta > 0)
                cpuUsage = Math.round(100 * (totalDelta - idleDelta) / totalDelta);
        }

        previousCpu = {total: total, idle: idle};

        let totalMemory = 0;
        let availableMemory = 0;

        for (const line of lines.slice(1)) {
            const match = line.match(/^(MemTotal|MemAvailable):\s+(\d+)/);
            if (!match)
                continue;
            if (match[1] === "MemTotal")
                totalMemory = Number(match[2]);
            else
                availableMemory = Number(match[2]);
        }

        if (totalMemory > 0)
            memUsage = Math.round(100 * (totalMemory - availableMemory) / totalMemory);
    }

    // ------------------------------------------------------------- volume

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property int volume: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false

    // ------------------------------------------------------------ battery

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery !== null && battery.isLaptopBattery
    readonly property int batteryPercent: hasBattery ? Math.round(battery.percentage * 100) : 0
    readonly property bool charging: hasBattery && battery.state === UPowerDeviceState.Charging
}
