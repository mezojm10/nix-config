import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Networking
import Quickshell.Bluetooth
import "Theme.js" as Theme

// Marble-inspired control center. One instance exists per monitor; the shade
// and the panel are separate layer surfaces so the panel always stays on top.
Scope {
    id: root

    property var monitor
    property var shellState
    property var brightness

    readonly property string monitorName: monitor ? monitor.name : ""
    readonly property bool open: !!shellState
        && shellState.quickSettingsOpen
        && shellState.quickSettingsScreen === monitorName

    onOpenChanged: if (open) keyHandler.forceActiveFocus()

    readonly property string initial: shellState && shellState.userName !== ""
        ? shellState.userName.charAt(0).toUpperCase()
        : "?"

    // ------------------------------------------------------------- network

    readonly property var wifiDevice: {
        const devices = Networking.devices.values;

        for (let i = 0; i < devices.length; i++)
            if (devices[i].type === DeviceType.Wifi)
                return devices[i];

        return null;
    }

    readonly property string wifiSubtitle: {
        if (!Networking.wifiEnabled)
            return "Off";

        if (!wifiDevice)
            return "No adapter";

        const networks = wifiDevice.networks.values;

        for (let i = 0; i < networks.length; i++)
            if (networks[i].connected)
                return networks[i].name;

        return "Enabled";
    }

    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter

    // --------------------------------------------------------------- audio

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property int volume: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false

    readonly property var source: Pipewire.defaultAudioSource
    readonly property var microphone: source ? source.audio : null
    readonly property int micVolume: microphone ? Math.round(microphone.volume * 100) : 0
    readonly property bool micMuted: microphone ? microphone.muted : false

    // ------------------------------------------------------------- battery

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery !== null && battery.isLaptopBattery
    readonly property int batteryPercent: hasBattery ? Math.round(battery.percentage * 100) : 0
    readonly property bool charging: hasBattery && battery.state === UPowerDeviceState.Charging

    // --------------------------------------------------------------- media

    readonly property var players: Mpris.players.values
    readonly property bool hasMedia: players.length > 0

    // --------------------------------------------------------------- audio

    readonly property var audioSinks: {
        const nodes = Pipewire.nodes.values;
        const sinks = [];

        for (let i = 0; i < nodes.length; i++)
            if (nodes[i].isSink && !nodes[i].isStream && nodes[i].audio)
                sinks.push(nodes[i]);

        return sinks;
    }

    readonly property var audioStreams: {
        const nodes = Pipewire.nodes.values;
        const streams = [];

        for (let i = 0; i < nodes.length; i++) {
            const node = nodes[i];

            if (!node.isStream || !node.audio)
                continue;

            const mediaClass = node.properties
                ? String(node.properties["media.class"] || "")
                : "";

            if (mediaClass === "" || mediaClass.indexOf("Output") !== -1)
                streams.push(node);
        }

        return streams;
    }

    readonly property var defaultSink: Pipewire.defaultAudioSink

    property bool showSinks: false
    property bool showStreams: false

    function sinkName(node) {
        if (!node)
            return "";

        return node.description || node.nickname || node.name || "Output";
    }

    function streamName(node) {
        if (!node)
            return "";

        const properties = node.properties || {};

        return properties["application.name"]
            || properties["application.process.binary"]
            || node.description
            || node.nickname
            || node.name
            || "Application";
    }

    function streamIcon(node) {
        if (!node)
            return "";

        const properties = node.properties || {};

        return properties["application.icon-name"]
            || properties["application.process.binary"]
            || "";
    }

    function streamVolume(node) {
        return node && node.audio ? Math.round((node.audio.volume || 0) * 100) : 0;
    }

    function setDefaultSink(node) {
        if (!node)
            return;

        Quickshell.execDetached(["wpctl", "set-default", String(node.id)]);
    }

    // ------------------------------------------------------- power profile

    readonly property int powerProfile: PowerProfiles.profile

    readonly property string powerProfileLabel: {
        if (powerProfile === PowerProfile.PowerSaver)
            return "Saver";
        if (powerProfile === PowerProfile.Performance)
            return "Performance";
        return "Balanced";
    }

    function cyclePowerProfile() {
        if (PowerProfiles.hasPerformanceProfile) {
            if (PowerProfiles.profile === PowerProfile.Balanced)
                PowerProfiles.profile = PowerProfile.Performance;
            else if (PowerProfiles.profile === PowerProfile.Performance)
                PowerProfiles.profile = PowerProfile.PowerSaver;
            else
                PowerProfiles.profile = PowerProfile.Balanced;
        } else {
            PowerProfiles.profile = PowerProfiles.profile === PowerProfile.PowerSaver
                ? PowerProfile.Balanced
                : PowerProfile.PowerSaver;
        }
    }

    // ------------------------------------------------------- notifications

    readonly property var tracked: shellState ? shellState.notificationHistory : []
    readonly property int notificationCount: tracked.length

    property int tick: 0

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.tick++
    }

    function clearNotifications() {
        if (shellState)
            shellState.clearNotifications();
    }

    function timeLabel(timestamp) {
        root.tick;
        return Theme.timeAgo(timestamp);
    }

    // Track every stream and sink so their volume properties stay live.
    PwObjectTracker {
        objects: root.audioSinks.concat(root.audioStreams)
    }

    // ---------------------------------------------------------------- shade

    PanelWindow {
        screen: root.monitor
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        visible: root.open
        color: "transparent"
        exclusiveZone: 0

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-shade"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: "#99101017"

            MouseArea {
                anchors.fill: parent
                onClicked: root.shellState.closeQuickSettings()
            }
        }
    }

    // ---------------------------------------------------------------- panel

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

        implicitWidth: 384
        implicitHeight: content.implicitHeight + 28
        visible: root.open
        color: "transparent"
        exclusiveZone: 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-quicksettings"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: Theme.alpha(Theme.bg, 0.94)
            border.width: 1
            border.color: Theme.alpha(Theme.surfaceAlt, 0.9)

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 18
                    rightMargin: 18
                }
                height: 1
                radius: 1
                color: Theme.alpha(Theme.blue, 0.3)
            }

            Item {
                id: keyHandler

                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: root.shellState.closeQuickSettings()

                Column {
                    id: content

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 14
                    }
                    spacing: 12

                    // -------------------------------------------------- header

                    RowLayout {
                        width: parent.width
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: 22
                            color: Theme.alpha(Theme.blue, 0.22)
                            border.width: 1
                            border.color: Theme.alpha(Theme.blue, 0.45)

                            Text {
                                anchors.centerIn: parent
                                text: root.initial
                                color: Theme.blue
                                font.family: Theme.font
                                font.pixelSize: 18
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: root.shellState ? root.shellState.userName : ""
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                spacing: 6

                                Text {
                                    visible: root.hasBattery
                                    text: Theme.batteryIcon(root.batteryPercent, root.charging)
                                    color: root.charging
                                        ? Theme.green
                                        : (root.batteryPercent < 15 ? Theme.red : Theme.yellow)
                                    font.family: Theme.iconFont
                                    font.pixelSize: 11
                                }

                                Text {
                                    visible: root.hasBattery
                                    text: root.batteryPercent + "%"
                                    color: Theme.fgDim
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.shellState ? root.shellState.uptime : ""
                                    color: Theme.comment
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "CPU " + (root.shellState ? root.shellState.cpuUsage : 0) + "%"
                                    + "  ·  MEM " + (root.shellState ? root.shellState.memUsage : 0) + "%"
                                color: Theme.comment
                                font.family: Theme.font
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }
                        }

                        RowLayout {
                            spacing: 2

                            BarButton {
                                glyph: "\u{f023}"
                                glyphColor: Theme.fgDim

                                onClicked: Quickshell.execDetached(["swaylock", "--daemonize"])
                            }

                            BarButton {
                                glyph: "\u{f08b}"
                                glyphColor: Theme.fgDim

                                onClicked: root.shellState.openPower("logout")
                            }

                            BarButton {
                                glyph: "\u{f0425}"
                                glyphColor: Theme.red

                                onClicked: root.shellState.openPower("poweroff")
                            }
                        }
                    }

                    // ------------------------------------------------- toggles

                    Grid {
                        width: parent.width
                        columns: 2
                        spacing: 10

                        ToggleTile {
                            width: (parent.width - parent.spacing) / 2
                            glyph: "\u{f00af}"
                            label: "Bluetooth"
                            subtitle: root.bluetoothAdapter === null
                                ? "Unavailable"
                                : (root.bluetoothAdapter.enabled ? "On" : "Off")
                            active: root.bluetoothAdapter !== null && root.bluetoothAdapter.enabled
                            accent: Theme.blue

                            onClicked: if (root.bluetoothAdapter)
                                root.bluetoothAdapter.enabled = !root.bluetoothAdapter.enabled
                        }

                        ToggleTile {
                            width: (parent.width - parent.spacing) / 2
                            glyph: "\u{f05a9}"
                            label: "Wi-Fi"
                            subtitle: root.wifiSubtitle
                            active: Networking.wifiEnabled
                            accent: Theme.blue

                            onClicked: if (Networking.wifiHardwareEnabled || Networking.wifiEnabled)
                                Networking.wifiEnabled = !Networking.wifiEnabled
                        }

                        ToggleTile {
                            width: (parent.width - parent.spacing) / 2
                            glyph: "\u{f0e7}"
                            label: "Power"
                            subtitle: root.powerProfileLabel
                            active: root.powerProfile !== PowerProfile.Balanced
                            accent: root.powerProfile === PowerProfile.Performance
                                ? Theme.yellow
                                : (root.powerProfile === PowerProfile.PowerSaver
                                    ? Theme.cyan
                                    : Theme.green)

                            onClicked: root.cyclePowerProfile()
                        }

                        ToggleTile {
                            width: (parent.width - parent.spacing) / 2
                            glyph: "\u{f0f4}"
                            label: "Caffeine"
                            subtitle: root.shellState && root.shellState.caffeine ? "On" : "Off"
                            active: !!root.shellState && root.shellState.caffeine
                            accent: Theme.orange

                            onClicked: if (root.shellState)
                                root.shellState.caffeine = !root.shellState.caffeine
                        }

                        ToggleTile {
                            width: (parent.width - parent.spacing) / 2
                            glyph: !!root.shellState && root.shellState.dnd
                                ? "\u{f1f7}"
                                : "\u{f0f3}"
                            label: "Do Not Disturb"
                            subtitle: root.shellState && root.shellState.dnd ? "Silent" : "Noisy"
                            active: !!root.shellState && root.shellState.dnd
                            accent: Theme.red

                            onClicked: if (root.shellState)
                                root.shellState.dnd = !root.shellState.dnd
                        }

                        ToggleTile {
                            width: (parent.width - parent.spacing) / 2
                            glyph: Theme.volumeIcon(root.volume, root.muted)
                            label: "Speaker"
                            subtitle: root.muted ? "Muted" : root.volume + "%"
                            active: root.muted
                            accent: Theme.red

                            onClicked: if (root.audio)
                                root.audio.muted = !root.audio.muted
                        }
                    }

                    // ------------------------------------------------- sliders

                    Column {
                        width: parent.width
                        spacing: 6

                        RowLayout {
                            width: parent.width
                            spacing: 10

                            BarButton {
                                glyph: Theme.volumeIcon(root.volume, root.muted)
                                glyphColor: root.muted ? Theme.red : Theme.cyan
                                iconSize: 15
                                horizontalPadding: 5

                                onClicked: if (root.audio)
                                    root.audio.muted = !root.audio.muted
                            }

                            Slider {
                                Layout.fillWidth: true
                                value: root.volume / 100
                                fillColor: root.muted ? Theme.comment : Theme.blue

                                onMoved: value => {
                                    if (root.audio)
                                        root.audio.volume = value;
                                }
                            }

                            Text {
                                Layout.preferredWidth: 34
                                text: root.volume + "%"
                                color: Theme.fgDim
                                font.family: Theme.font
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        RowLayout {
                            visible: root.microphone !== null
                            width: parent.width
                            spacing: 10

                            BarButton {
                                glyph: "\u{f130}"
                                glyphColor: root.micMuted ? Theme.red : Theme.cyan
                                iconSize: 14
                                horizontalPadding: 5

                                onClicked: if (root.microphone)
                                    root.microphone.muted = !root.microphone.muted
                            }

                            Slider {
                                Layout.fillWidth: true
                                value: root.micVolume / 100
                                fillColor: root.micMuted ? Theme.comment : Theme.cyan

                                onMoved: value => {
                                    if (root.microphone)
                                        root.microphone.volume = value;
                                }
                            }

                            Text {
                                Layout.preferredWidth: 34
                                text: root.micVolume + "%"
                                color: Theme.fgDim
                                font.family: Theme.font
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        RowLayout {
                            visible: root.brightness != null && root.brightness.available
                            width: parent.width
                            spacing: 10

                            BarButton {
                                glyph: "\u{f185}"
                                glyphColor: Theme.yellow
                                iconSize: 14
                                horizontalPadding: 5

                                onClicked: if (root.brightness)
                                    root.brightness.setPercent(root.brightness.percent > 0 ? 0 : 100)
                            }

                            Slider {
                                Layout.fillWidth: true
                                value: root.brightness ? root.brightness.percent / 100 : 0
                                fillColor: Theme.yellow

                                onMoved: value => {
                                    if (root.brightness)
                                        root.brightness.setPercent(value * 100);
                                }
                            }

                            Text {
                                Layout.preferredWidth: 34
                                text: (root.brightness ? root.brightness.percent : 0) + "%"
                                color: Theme.fgDim
                                font.family: Theme.font
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    // --------------------------------------------------- audio

                    ColumnLayout {
                        width: parent.width
                        spacing: 6
                        visible: root.audioSinks.length > 1

                        RowLayout {
                            width: parent.width
                            spacing: 6

                            Text {
                                text: "\u{f028}"
                                color: Theme.blue
                                font.family: Theme.iconFont
                                font.pixelSize: 12
                            }

                            Text {
                                text: "Output"
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.sinkName(root.defaultSink)
                                color: Theme.comment
                                font.family: Theme.font
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            BarButton {
                                glyph: root.showSinks ? "\u{f077}" : "\u{f078}"
                                glyphColor: Theme.comment
                                iconSize: 11
                                horizontalPadding: 5

                                onClicked: root.showSinks = !root.showSinks
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 4
                            visible: root.showSinks

                            Repeater {
                                model: root.audioSinks

                                Rectangle {
                                    id: sinkRow

                                    required property var modelData

                                    readonly property bool selected: !!root.defaultSink
                                        && modelData.id === root.defaultSink.id

                                    width: parent.width
                                    height: 30
                                    radius: 8
                                    color: selected
                                        ? Theme.alpha(Theme.blue, 0.16)
                                        : Theme.alpha(Theme.fg, 0.04)

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "\u{f028}"
                                            color: sinkRow.selected ? Theme.blue : Theme.comment
                                            font.family: Theme.iconFont
                                            font.pixelSize: 11
                                        }

                                        Text {
                                            width: parent.width - 11 - 6 - (sinkRow.selected ? 46 : 0)
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: root.sinkName(sinkRow.modelData)
                                            color: sinkRow.selected ? Theme.fg : Theme.fgDim
                                            font.family: Theme.font
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            visible: sinkRow.selected
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Default"
                                            color: Theme.blue
                                            font.family: Theme.font
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setDefaultSink(sinkRow.modelData)
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        width: parent.width
                        spacing: 6
                        visible: root.audioStreams.length > 0

                        RowLayout {
                            width: parent.width
                            spacing: 6

                            Text {
                                text: "\u{f001}"
                                color: Theme.magenta
                                font.family: Theme.iconFont
                                font.pixelSize: 12
                            }

                            Text {
                                text: "Applications"
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: String(root.audioStreams.length)
                                color: Theme.comment
                                font.family: Theme.font
                                font.pixelSize: 10
                            }

                            BarButton {
                                glyph: root.showStreams ? "\u{f077}" : "\u{f078}"
                                glyphColor: Theme.comment
                                iconSize: 11
                                horizontalPadding: 5

                                onClicked: root.showStreams = !root.showStreams
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 6
                            visible: root.showStreams

                            Repeater {
                                model: root.audioStreams

                                RowLayout {
                                    id: streamRow

                                    required property var modelData

                                    width: parent.width
                                    spacing: 6

                                    Item {
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            anchors.centerIn: parent
                                            visible: streamIconImage.status !== Image.Ready
                                            text: "\u{f001}"
                                            color: Theme.comment
                                            font.family: Theme.iconFont
                                            font.pixelSize: 11
                                        }

                                        Image {
                                            id: streamIconImage

                                            anchors.fill: parent
                                            source: Quickshell.iconPath(root.streamIcon(streamRow.modelData), true)
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.streamName(streamRow.modelData)
                                        color: Theme.fgDim
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }

                                    BarButton {
                                        glyph: Theme.volumeIcon(
                                            root.streamVolume(streamRow.modelData),
                                            streamRow.modelData.audio.muted
                                        )
                                        glyphColor: streamRow.modelData.audio.muted ? Theme.red : Theme.cyan
                                        iconSize: 12
                                        horizontalPadding: 4

                                        onClicked: streamRow.modelData.audio.muted = !streamRow.modelData.audio.muted
                                    }

                                    Slider {
                                        Layout.preferredWidth: 92
                                        value: streamRow.modelData.audio.volume || 0
                                        fillColor: streamRow.modelData.audio.muted ? Theme.comment : Theme.blue

                                        onMoved: value => {
                                            streamRow.modelData.audio.volume = value;
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: 26
                                        text: root.streamVolume(streamRow.modelData) + "%"
                                        color: Theme.comment
                                        font.family: Theme.font
                                        font.pixelSize: 9
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }

                    // --------------------------------------------------- media

                    Column {
                        id: mediaColumn

                        width: parent.width
                        spacing: 8
                        visible: root.hasMedia

                        Repeater {
                            model: root.players

                            MediaCard {
                                required property var modelData

                                width: mediaColumn.width
                                player: modelData
                                showIdentity: root.players.length > 1
                            }
                        }
                    }

                    // ------------------------------------------- notifications

                    ColumnLayout {
                        width: parent.width
                        spacing: 6
                        visible: !!root.shellState

                        RowLayout {
                            width: parent.width
                            spacing: 6

                            Text {
                                text: "\u{f0f3}"
                                color: Theme.yellow
                                font.family: Theme.iconFont
                                font.pixelSize: 13
                            }

                            Text {
                                text: "Notifications"
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: root.notificationCount > 0
                                text: String(root.notificationCount)
                                color: Theme.comment
                                font.family: Theme.font
                                font.pixelSize: 10
                            }

                            BarButton {
                                visible: root.notificationCount > 0
                                glyph: "\u{f1f8}"
                                glyphColor: Theme.red
                                iconSize: 12
                                horizontalPadding: 6

                                onClicked: root.clearNotifications()
                            }
                        }

                        ListView {
                            id: notificationList

                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(contentHeight, 220)
                            visible: count > 0
                            clip: true
                            spacing: 6
                            model: root.tracked

                            delegate: Rectangle {
                                id: notificationItem

                                required property var modelData

                                function invokeDefault() {
                                    const actions = notificationItem.modelData.notification.actions;

                                    if (actions && actions.length > 0)
                                        actions[0].invoke();
                                }

                                width: notificationList.width
                                implicitHeight: content.implicitHeight + 16
                                height: implicitHeight
                                radius: 10
                                color: Theme.alpha(Theme.fg, 0.05)

                                Column {
                                    id: content

                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                        margins: 8
                                    }
                                    spacing: 2

                                    // App name, relative time and dismiss.
                                    Row {
                                        width: parent.width
                                        spacing: 6

                                        Text {
                                            width: parent.width - 34 - 20 - 12
                                            text: notificationItem.modelData.notification.appName || "Notification"
                                            color: Theme.comment
                                            font.family: Theme.font
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: 34
                                            text: root.timeLabel(notificationItem.modelData.time)
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
                                                        root.shellState.dismissNotification(notificationItem.modelData.notification);
                                                }
                                            }
                                        }
                                    }

                                    // Icon, summary and body.
                                    Row {
                                        width: parent.width
                                        spacing: 8

                                        Item {
                                            width: 18
                                            height: 18
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                anchors.centerIn: parent
                                                visible: appIcon.status !== Image.Ready
                                                text: "\u{f0f3}"
                                                color: Theme.yellow
                                                font.family: Theme.iconFont
                                                font.pixelSize: 13
                                            }

                                            Image {
                                                id: appIcon

                                                anchors.fill: parent
                                                source: notificationItem.modelData.notification.appIcon
                                                    ? Quickshell.iconPath(notificationItem.modelData.notification.appIcon, true)
                                                    : ""
                                                fillMode: Image.PreserveAspectFit
                                                asynchronous: true
                                            }
                                        }

                                        Column {
                                            width: parent.width - 18 - 8
                                            spacing: 1

                                            TapHandler {
                                                onTapped: notificationItem.invokeDefault()
                                            }

                                            Text {
                                                width: parent.width
                                                text: notificationItem.modelData.notification.summary
                                                color: Theme.fg
                                                font.family: Theme.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                width: parent.width
                                                visible: text !== ""
                                                text: notificationItem.modelData.notification.body
                                                color: Theme.comment
                                                font.family: Theme.font
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: 6
                                        visible: notificationItem.modelData.notification.actions.length > 0

                                        Repeater {
                                            model: notificationItem.modelData.notification.actions

                                            Rectangle {
                                                id: actionButton

                                                required property var modelData

                                                width: actionLabel.implicitWidth + 14
                                                height: 20
                                                radius: 6
                                                color: actionHover.hovered
                                                    ? Theme.alpha(Theme.blue, 0.28)
                                                    : Theme.alpha(Theme.blue, 0.16)

                                                Text {
                                                    id: actionLabel

                                                    anchors.centerIn: parent
                                                    text: actionButton.modelData.text
                                                    color: Theme.fg
                                                    font.family: Theme.font
                                                    font.pixelSize: 9
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

                            }
                        }

                        Text {
                            visible: notificationList.count === 0
                            Layout.fillWidth: true
                            text: "Inbox is empty"
                            color: Theme.comment
                            font.family: Theme.font
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
