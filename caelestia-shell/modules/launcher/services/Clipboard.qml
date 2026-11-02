pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils

// Clipboard history for the launcher, backed by cliphist.
//
// Image entries are decoded once into the cache directory so the launcher can
// show a thumbnail; text entries show their preview.
Singleton {
    id: root

    readonly property string prefix: `${GlobalConfig.launcher.actionPrefix}clipboard`
    readonly property string cacheDir: `${Paths.cache}/cliphist`

    property var entries: []

    function reload(): void {
        listProc.running = true;
    }

    function query(search: string): var {
        const text = search.slice(prefix.length).trim().toLowerCase();
        if (!text)
            return [...entries];
        return entries.filter(e => e.label.toLowerCase().includes(text));
    }

    function copy(id: string): void {
        Quickshell.execDetached(["sh", "-c", `cliphist decode ${id} | wl-copy`]);
    }

    function clearEntries(): void {
        for (const entry of entries)
            entry.destroy();
        entries = [];
    }

    function parse(text: string): void {
        clearEntries();

        const result = [];

        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t");
            if (tab < 0)
                continue;

            const id = line.slice(0, tab).trim();
            if (!/^\d+$/.test(id))
                continue;

            const preview = line.slice(tab + 1);
            const image = /^\[\[ binary data .*?\s([a-z0-9]+)\s(\d+)x(\d+) \]\]$/.exec(preview);

            result.push(entryComponent.createObject(root, {
                clipId: id,
                preview: preview,
                label: image ? `Image ${image[2]}×${image[3]}` : preview,
                isImage: image !== null,
                format: image ? image[1] : ""
            }));
        }

        entries = result;
        decodeImages();
    }

    function decodeImages(): void {
        if (decodeProc.running)
            return;

        const targets = [];

        for (const entry of entries) {
            if (!entry.isImage)
                continue;
            entry.targetPath = `${cacheDir}/${entry.clipId}.${entry.format}`;
            targets.push(entry);
        }

        if (targets.length === 0)
            return;

        const commands = targets.map(entry => `[ -s '${entry.targetPath}' ] || cliphist decode ${entry.clipId} > '${entry.targetPath}'`);
        decodeProc.command = ["sh", "-c", `mkdir -p '${cacheDir}'; ${commands.join("; ")}`];
        decodeProc.running = true;
    }

    Component {
        id: entryComponent

        QtObject {
            property string clipId
            property string preview
            property string label
            property bool isImage
            property string format
            property string targetPath
            property string thumbPath

            function onClicked(list): void {
                root.copy(clipId);
                list.screenState.launcher = false;
            }
        }
    }

    Process {
        id: listProc

        command: ["cliphist", "list"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: decodeProc

        onExited: {
            for (const entry of entries)
                if (entry.isImage && entry.targetPath)
                    entry.thumbPath = entry.targetPath;

            // Entries added while a decode was running still need thumbnails.
            if (entries.some(entry => entry.isImage && !entry.targetPath))
                decodeImages();
        }
    }
}
