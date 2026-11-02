import QtQuick
import Quickshell
import Quickshell.Io

// brightnessctl has no event stream, so poll it. The OSD is driven from the
// `changed` signal, which means the hardware keys keep working unchanged.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool available: false
    property int percent: 100
    property int previous: -1
    property int pending: 100

    signal changed(int percent)

    Process {
        id: readProcess

        command: ["brightnessctl", "--class=backlight", "--machine-readable", "info"]

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                if (fields.length < 4)
                    return;

                const value = parseInt(fields[3]);

                if (isNaN(value))
                    return;

                root.available = true;
                root.percent = value;

                if (root.previous !== -1 && root.previous !== value)
                    root.changed(value);

                root.previous = value;
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!readProcess.running) readProcess.running = true
    }

    // Dragging the slider emits a lot of updates. Batch them so dragging does
    // not spawn a process for every mouse move.
    Timer {
        id: applyTimer

        interval: 80
        onTriggered: Quickshell.execDetached([
            "brightnessctl", "--class=backlight", "set", root.pending + "%"
        ])
    }

    function setPercent(value) {
        const target = Math.max(1, Math.min(100, Math.round(value)));

        root.percent = target;
        root.previous = target;
        root.pending = target;
        applyTimer.restart();
    }
}
