import QtQuick
import Quickshell
import Quickshell.Io

// Shared state for the shell. Everything that has to be known by more than one
// surface (bar, control center, power dialog, OSD) lives here.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    // -------------------------------------------------------------- panels

    property string quickSettingsScreen: ""
    readonly property bool quickSettingsOpen: quickSettingsScreen !== ""

    property bool dnd: false
    property bool caffeine: false

    property string powerAction: ""

    // ----------------------------------------------------------------- osd

    property string osdIcon: ""
    property string osdLabel: ""
    property real osdValue: -1
    property color osdAccent: "#7aa2f7"
    property bool osdVisible: false

    // ---------------------------------------------------------- notifications

    // Notifications with a timeout would otherwise disappear from the control
    // center after a few seconds. Keep a retained copy until it is dismissed.
    property var notificationHistory: []

    Component {
        id: retainComponent

        RetainableLock {
            locked: true
        }
    }

    function addNotification(notification) {
        for (let i = 0; i < root.notificationHistory.length; i++)
            if (root.notificationHistory[i].notification === notification)
                return;

        let lock = null;

        try {
            lock = retainComponent.createObject(root, {object: notification});
        } catch (error) {
            // If retaining fails the notification still works until it expires.
        }

        const next = [{
            notification: notification,
            lock: lock,
            time: Date.now()
        }].concat(root.notificationHistory);

        // Keep the history bounded without leaking the locks of dropped
        // notifications.
        while (next.length > 32) {
            const dropped = next.pop();

            if (dropped.notification.tracked)
                dropped.notification.tracked = false;

            if (dropped.lock)
                dropped.lock.destroy();
        }

        root.notificationHistory = next;
    }

    function removeNotification(notification) {
        const next = [];

        for (let i = 0; i < root.notificationHistory.length; i++) {
            const entry = root.notificationHistory[i];

            if (entry.notification === notification) {
                if (entry.lock)
                    entry.lock.destroy();
            } else {
                next.push(entry);
            }
        }

        root.notificationHistory = next;
    }

    function dismissNotification(notification) {
        if (notification && notification.tracked)
            notification.tracked = false;

        root.removeNotification(notification);
    }

    function clearNotifications() {
        for (let i = 0; i < root.notificationHistory.length; i++) {
            const notification = root.notificationHistory[i].notification;

            if (notification.tracked)
                notification.tracked = false;
        }

        for (let i = 0; i < root.notificationHistory.length; i++) {
            const lock = root.notificationHistory[i].lock;

            if (lock)
                lock.destroy();
        }

        root.notificationHistory = [];
    }

    // ---------------------------------------------------------- system stats

    property int cpuUsage: 0
    property int memUsage: 0
    property var previousCpu: null

    Process {
        id: statsProcess

        command: [
            "sh", "-c",
            "grep '^cpu ' /proc/stat; grep --extended-regexp '^(MemTotal|MemAvailable):' /proc/meminfo"
        ]

        stdout: StdioCollector {
            onStreamFinished: root.updateStats(text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!statsProcess.running) statsProcess.running = true
    }

    function updateStats(text) {
        const lines = text.trim().split("\n");
        if (lines.length < 1)
            return;

        // user nice system idle iowait irq softirq steal
        const fields = lines[0].trim().split(/\s+/).slice(1, 9).map(Number);
        const total = fields.reduce((sum, value) => sum + value, 0);
        const idle = fields[3] + fields[4];

        if (root.previousCpu !== null) {
            const totalDelta = total - root.previousCpu.total;
            const idleDelta = idle - root.previousCpu.idle;

            if (totalDelta > 0)
                root.cpuUsage = Math.round(100 * (totalDelta - idleDelta) / totalDelta);
        }

        root.previousCpu = {total: total, idle: idle};

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
            root.memUsage = Math.round(100 * (totalMemory - availableMemory) / totalMemory);
    }

    // --------------------------------------------------------------- header

    readonly property string userName: Quickshell.env("USER") || ""
    property string uptime: ""

    Timer {
        id: osdTimer

        interval: 1600
        onTriggered: root.osdVisible = false
    }

    Process {
        id: uptimeProcess

        command: ["cat", "/proc/uptime"]

        stdout: StdioCollector {
            onStreamFinished: root.updateUptime(text)
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!uptimeProcess.running) uptimeProcess.running = true
    }

    function updateUptime(text) {
        const seconds = Math.floor(parseFloat(text.split(" ")[0]));

        if (isNaN(seconds))
            return;

        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);

        let value = "up ";

        if (days > 0)
            value += days + "d ";

        if (days > 0 || hours > 0)
            value += hours + "h ";

        root.uptime = value + minutes + "m";
    }

    function toggleQuickSettings(screenName) {
        root.quickSettingsScreen = root.quickSettingsScreen === screenName ? "" : screenName;
    }

    function closeQuickSettings() {
        root.quickSettingsScreen = "";
    }

    function openPower(action) {
        root.quickSettingsScreen = "";
        root.powerAction = action;
    }

    function closePower() {
        root.powerAction = "";
    }

    function showOsd(icon, label, value, accent) {
        root.osdIcon = icon;
        root.osdLabel = label;
        root.osdValue = value;
        root.osdAccent = accent !== undefined ? accent : "#7aa2f7";
        root.osdVisible = true;
        osdTimer.restart();
    }

    // ----------------------------------------------------------------- ipc

    IpcHandler {
        target: "power"

        function poweroff() {
            root.openPower("poweroff");
        }

        function reboot() {
            root.openPower("reboot");
        }

        function logout() {
            root.openPower("logout");
        }

        function close() {
            root.closePower();
        }
    }

    IpcHandler {
        target: "quicksettings"

        function toggle() {
            const screen = Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "";
            root.toggleQuickSettings(screen);
        }

        function close() {
            root.closeQuickSettings();
        }

        function caffeine() {
            root.caffeine = !root.caffeine;
        }
    }

    IpcHandler {
        target: "notifications"

        function toggleDnd() {
            root.dnd = !root.dnd;
        }

        function clear() {
            root.clearNotifications();
        }
    }
}
