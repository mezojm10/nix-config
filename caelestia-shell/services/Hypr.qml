pragma Singleton

// Niri port of Caelestia's Hyprland service.
//
// The rest of the shell talks to the compositor through the `Hypr` singleton
// (workspaces, monitors, toplevels, dispatch, ...). Upstream backs that with
// Quickshell.Hyprland and the C++ HyprExtras plugin; this fork keeps the same
// API surface but is driven by `niri msg event-stream` instead, so the rest of
// the shell needs no compositor-specific code.
//
// Differences from the Hyprland implementation:
//   - Niri has no special workspaces, so `toggleSpecial()` is a no-op and
//     `lastIpcObject.specialWorkspace` is always empty.
//   - Niri exposes no window geometry, tags or keyboard-lock state. Window
//     `lastIpcObject.at` is therefore 0,0 and `tags` is empty; caps/num lock
//     come from the kernel LED class instead.
//   - Fullscreen state comes from wlr-foreign-toplevel-management, which niri
//     implements, and is reported as `lastIpcObject.fullscreen` (2 when
//     fullscreen, matching what the shell expects from Hyprland).

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

Singleton {
    id: root

    // Bumped every time the compositor state changes so that the derived
    // properties below re-evaluate without rebuilding object identities.
    property int revision: 0

    property var rawWorkspaces: []
    property var rawWindows: []

    readonly property bool usingLua: false
    readonly property var options: ({})

    // Stubs for the HyprExtras plugin. Game mode and dynamic colour rules are
    // configured in the niri config instead.
    readonly property var extras: ({
        applyOptions: function (options) {},
        message: function (msg) {},
        batchMessage: function (msgs) {},
        refreshOptions: function () {},
        refreshDevices: function () {},
        devices: ({
            keyboards: []
        })
    })

    property string kbLayoutFull: ""
    property string defaultKbLayout: ""
    property string kbLayout: ""
    property bool capsLock: false
    property bool numLock: false

    property var kbMap: ({})

    signal configReloaded

    // ------------------------------------------------------------- public state

    readonly property var workspaces: {
        revision;
        return {
            values: root.sortedWorkspaces()
        };
    }

    readonly property var toplevels: {
        revision;
        return {
            values: root.sortedToplevels()
        };
    }

    readonly property var monitors: {
        revision;
        return {
            values: root.sortedMonitors()
        };
    }

    readonly property var focusedWorkspace: {
        revision;
        return root.sortedWorkspaces().find(w => w.isFocused) ?? null;
    }

    readonly property var focusedMonitor: {
        revision;
        return root.sortedMonitors().find(m => m.focused) ?? null;
    }

    readonly property var activeToplevel: {
        revision;
        return root.sortedToplevels().find(t => t.focused) ?? null;
    }

    readonly property int activeWsId: focusedWorkspace?.id ?? 1

    // ------------------------------------------------------------- QML objects

    Component {
        id: workspaceComponent

        QtObject {
            property int id
            property string name
            property string output
            property bool isActive
            property bool isFocused
            property var monitor: null
            property var toplevels: ({
                    values: []
                })
        }
    }

    Component {
        id: monitorComponent

        QtObject {
            property int id
            property string name
            property bool focused
            property var activeWorkspace: null
            property var lastIpcObject: ({
                    specialWorkspace: {
                        name: "",
                        id: -1
                    }
                })
        }
    }

    Component {
        id: toplevelComponent

        QtObject {
            property int id
            property string address
            property string appId
            property string title
            property bool floating
            property bool focused
            property int workspaceId
            property var workspace: null
            property var monitor: null
            property var wayland: null
            property var size: [0, 0]
            readonly property bool fullscreen: wayland?.fullscreen ?? false
            readonly property var lastIpcObject: ({
                    class: appId,
                    at: [0, 0],
                    size: size,
                    floating: floating,
                    fullscreen: fullscreen ? 2 : 0,
                    pinned: 0,
                    mapped: true,
                    tags: []
                })
        }
    }

    property var workspaceCache: ({})
    property var windowCache: ({})
    property var monitorCache: ({})
    property var placeholderWorkspace: null

    // -------------------------------------------------------------- helpers

    function emptyWorkspace(): var {
        if (!placeholderWorkspace) {
            placeholderWorkspace = workspaceComponent.createObject(root);
            placeholderWorkspace.id = 0;
            placeholderWorkspace.name = "";
            placeholderWorkspace.output = "";
            placeholderWorkspace.isActive = false;
            placeholderWorkspace.isFocused = false;
        }
        return placeholderWorkspace;
    }

    function sortedWorkspaces(): var {
        const list = [];
        for (const key in workspaceCache)
            list.push(workspaceCache[key]);
        list.sort((a, b) => (a.output ?? "").localeCompare(b.output ?? "") || a.id - b.id);
        return list;
    }

    function sortedToplevels(): var {
        const list = [];
        for (const key in windowCache)
            list.push(windowCache[key]);
        return list;
    }

    function sortedMonitors(): var {
        const list = [];
        for (const key in monitorCache)
            list.push(monitorCache[key]);
        return list;
    }

    function monitorFor(screen: var): var {
        if (!screen)
            return null;
        return monitorCache[screen.name] ?? createMonitor(screen.name);
    }

    function createMonitor(name: string): var {
        const mon = monitorComponent.createObject(root, {
            name: name,
            activeWorkspace: emptyWorkspace()
        });
        monitorCache[name] = mon;
        return mon;
    }

    function workspaceFor(niriId: int): var {
        return workspaceCache[niriId] ?? null;
    }

    function monitorNames(): var {
        return sortedMonitors().map(m => m.name);
    }

    function trimWsName(name: string): string {
        return name;
    }

    function isToplevelIgnored(toplevel: var, ignoredTags: var): bool {
        return !toplevel || !toplevel.lastIpcObject?.mapped;
    }

    function toplevelsForWs(ws: int, ignoredTags: var): var {
        return sortedToplevels().filter(t => t.workspace?.id === ws && !isToplevelIgnored(t, ignoredTags));
    }

    // ------------------------------------------------------------ dispatching

    function action(args: var): void {
        Quickshell.execDetached(["niri", "msg", "action"].concat(args));
    }

    function windowIdFromAddress(address: string): string {
        // The shell formats addresses as `address:0x<hex>` like Hyprland.
        const match = /0x([0-9a-f]+)/.exec(address ?? "");
        return match ? String(parseInt(match[1], 16)) : "";
    }

    function focusWorkspace(ws: var): void {
        action(["focus-workspace", String(ws)]);
    }

    function focusToplevel(toplevel: var): void {
        if (toplevel)
            action(["focus-window", "--id", String(toplevel.id)]);
    }

    // Niri has no special workspaces; the drawers are ordinary layer surfaces.
    function toggleSpecial(name: string): void {}

    function cycleSpecialWorkspace(direction: string): void {}

    function reloadDynamicConfs(): void {}

    function dispatch(request: string): void {
        if (request === "dpms off") {
            action(["power-off-monitors"]);
        } else if (request === "dpms on") {
            action(["power-on-monitors"]);
        } else if (request.startsWith("workspace r+")) {
            action(["focus-workspace-down"]);
        } else if (request.startsWith("workspace r-")) {
            action(["focus-workspace-up"]);
        } else if (request.startsWith("workspace ")) {
            action(["focus-workspace", request.slice("workspace ".length)]);
        } else if (request.startsWith("movetoworkspace ")) {
            const args = request.slice("movetoworkspace ".length).split(",");
            const id = windowIdFromAddress(args[1]);
            action(["move-window-to-workspace", "--window-id", id, args[0]]);
        } else if (request.startsWith("togglefloating ")) {
            action(["toggle-window-floating", "--id", windowIdFromAddress(request.slice("togglefloating ".length))]);
        } else if (request.startsWith("killwindow ")) {
            action(["close-window", "--id", windowIdFromAddress(request.slice("killwindow ".length))]);
        }
        // `pin` and `togglespecialworkspace` have no niri equivalent.
    }

    // --------------------------------------------------------------- rebuilding

    function waylandFor(window: var): var {
        return ToplevelManager.toplevels.values.find(t => t.appId === (window.app_id ?? "") && t.title === (window.title ?? "")) ?? null;
    }

    function rebuild(): void {
        // Workspaces first, so windows can point at them.
        const seenWorkspaces = ({});

        for (const ws of root.rawWorkspaces) {
            seenWorkspaces[ws.id] = true;
            let obj = workspaceCache[ws.id];
            if (!obj) {
                obj = workspaceComponent.createObject(root);
                workspaceCache[ws.id] = obj;
            }
            obj.id = ws.idx;
            obj.name = ws.name ?? String(ws.idx);
            obj.output = ws.output ?? "";
            obj.isActive = ws.is_active;
            obj.isFocused = ws.is_focused;
            obj.monitor = obj.output ? root.monitorFor({
                name: obj.output
            }) : null;
        }

        for (const key in workspaceCache)
            if (!seenWorkspaces[key]) {
                workspaceCache[key].destroy();
                delete workspaceCache[key];
            }

        const seenWindows = ({});

        for (const win of root.rawWindows) {
            seenWindows[win.id] = true;
            let obj = windowCache[win.id];
            if (!obj) {
                obj = toplevelComponent.createObject(root);
                windowCache[win.id] = obj;
            }
            const ws = workspaceFor(win.workspace_id);
            obj.id = win.id;
            obj.address = win.id.toString(16);
            obj.appId = win.app_id ?? "";
            obj.title = win.title ?? "";
            obj.floating = win.is_floating;
            obj.focused = win.is_focused;
            obj.workspaceId = win.workspace_id ?? -1;
            obj.workspace = ws;
            obj.monitor = ws?.monitor ?? null;
            obj.wayland = root.waylandFor(win);
            obj.size = win.layout?.window_size ?? [0, 0];
        }

        for (const key in windowCache)
            if (!seenWindows[key]) {
                windowCache[key].destroy();
                delete windowCache[key];
            }

        for (const key in workspaceCache) {
            const ws = workspaceCache[key];
            ws.toplevels = {
                values: sortedToplevels().filter(t => t.workspaceId === Number(key))
            };
        }

        // Monitors: one per Quickshell screen, plus any output that has a
        // workspace but no screen yet (e.g. during hotplug).
        const monitorNames = ({});

        for (const screen of Screens.screens) {
            monitorNames[screen.name] = true;
            root.monitorFor(screen);
        }

        for (const ws of root.rawWorkspaces)
            if (ws.output && !monitorNames[ws.output]) {
                monitorNames[ws.output] = true;
                root.monitorFor({
                    name: ws.output
                });
            }

        for (const key in monitorCache)
            if (!monitorNames[key]) {
                monitorCache[key].destroy();
                delete monitorCache[key];
            }

        for (const key in monitorCache) {
            const mon = monitorCache[key];
            const ws = root.rawWorkspaces.find(w => w.output === key && w.is_active);
            mon.id = Screens.screens.findIndex(s => s.name === key);
            mon.activeWorkspace = ws ? workspaceFor(ws.id) : root.emptyWorkspace();
            mon.focused = root.rawWorkspaces.some(w => w.output === key && w.is_focused);
        }

        // Drop references to deleted workspaces/windows.
        revision++;
    }

    // ---------------------------------------------------------------- events

    function updateWorkspace(id: int, update: var): void {
        for (const ws of root.rawWorkspaces)
            if (ws.id === id)
                update(ws);
    }

    function handleEvent(event: var): void {
        if (event.WorkspacesChanged) {
            root.rawWorkspaces = event.WorkspacesChanged.workspaces;
            root.rebuild();
            return;
        }

        if (event.WorkspaceActivated) {
            const activated = event.WorkspaceActivated;
            const target = root.rawWorkspaces.find(w => w.id === activated.id);
            if (target) {
                for (const ws of root.rawWorkspaces)
                    if (ws.output === target.output)
                        ws.is_active = ws.id === activated.id;
                if (activated.focused)
                    for (const ws of root.rawWorkspaces)
                        ws.is_focused = ws.id === activated.id;
            }
        } else if (event.WorkspaceActiveWindowChanged) {
            updateWorkspace(event.WorkspaceActiveWindowChanged.workspace_id, ws => {
                ws.active_window_id = event.WorkspaceActiveWindowChanged.active_window_id;
            });
        } else if (event.WorkspaceUrgencyChanged) {
            updateWorkspace(event.WorkspaceUrgencyChanged.id, ws => {
                ws.is_urgent = event.WorkspaceUrgencyChanged.urgent;
            });
        } else if (event.WindowsChanged) {
            root.rawWindows = event.WindowsChanged.windows;
        } else if (event.WindowOpenedOrChanged) {
            const win = event.WindowOpenedOrChanged.window;
            const index = root.rawWindows.findIndex(w => w.id === win.id);
            if (index >= 0)
                root.rawWindows[index] = win;
            else
                root.rawWindows.push(win);
            root.rawWindows = root.rawWindows.slice();
        } else if (event.WindowClosed) {
            root.rawWindows = root.rawWindows.filter(w => w.id !== event.WindowClosed.id);
        } else if (event.WindowFocusChanged) {
            const id = event.WindowFocusChanged.id;
            for (const win of root.rawWindows)
                win.is_focused = win.id === id;
        } else if (event.WindowUrgencyChanged) {
            const changed = event.WindowUrgencyChanged;
            const win = root.rawWindows.find(w => w.id === changed.id);
            if (win)
                win.is_urgent = changed.urgent;
        } else if (event.WindowLayoutsChanged) {
            for (const change of event.WindowLayoutsChanged.changes) {
                const win = root.rawWindows.find(w => w.id === change[0]);
                if (win)
                    win.layout = change[1];
            }
        } else if (event.KeyboardLayoutsChanged) {
            root.setKeyboardLayouts(event.KeyboardLayoutsChanged.keyboard_layouts);
            return;
        } else if (event.KeyboardLayoutSwitched) {
            root.setKeyboardLayoutIndex(event.KeyboardLayoutSwitched.idx);
            return;
        } else {
            return;
        }

        root.rebuild();
    }

    function setKeyboardLayouts(layouts: var): void {
        root.keyboardNames = layouts.names ?? [];
        root.defaultKbLayout = root.keyboardNames[0] ?? "";
        root.setKeyboardLayoutIndex(layouts.current_idx ?? 0);
    }

    property var keyboardNames: []

    function setKeyboardLayoutIndex(index: int): void {
        const name = root.keyboardNames[index] ?? "";
        root.kbLayoutFull = name;
        root.kbLayout = root.kbMap[name] ?? name;
    }

    // ------------------------------------------------------------- processes

    Process {
        id: eventStream

        command: ["niri", "msg", "--json", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                try {
                    root.handleEvent(JSON.parse(line));
                } catch (e) {
                    console.warn("niri: failed to parse event:", line, e);
                }
            }
        }

        onExited: restartTimer.restart()
    }

    Timer {
        id: restartTimer

        interval: 1000
        onTriggered: eventStream.running = true
    }

    Process {
        id: ledProc

        command: ["sh", "-c", "echo caps:$(cat /sys/class/leds/*::capslock/brightness 2>/dev/null | tr '\\n' ' '); echo num:$(cat /sys/class/leds/*::numlock/brightness 2>/dev/null | tr '\\n' ' ')"]

        stdout: StdioCollector {
            onStreamFinished: {
                const caps = /caps:(.*)/.exec(text)?.[1] ?? "";
                const num = /num:(.*)/.exec(text)?.[1] ?? "";
                root.capsLock = caps.split(/\s+/).includes("1");
                root.numLock = num.split(/\s+/).includes("1");
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ledProc.running = true
    }

    FileView {
        path: Quickshell.env("CAELESTIA_XKB_RULES_PATH") || "/usr/share/X11/xkb/rules/base.lst"
        watchChanges: true

        onLoaded: {
            const map = ({});

            const layoutMatch = text().match(/! layout\n([\s\S]*?)\n\n/);
            if (layoutMatch) {
                for (const line of layoutMatch[1].split("\n")) {
                    const match = line.match(/^\s*([a-z]{2,})\s+([a-zA-Z() ]+)$/);
                    if (match)
                        map[match[2]] = match[1];
                }
            }

            const variantMatch = text().match(/! variant\n([\s\S]*?)\n\n/);
            if (variantMatch) {
                for (const line of variantMatch[1].split("\n")) {
                    const match = line.match(/^\s*([a-zA-Z0-9_-]+)\s+([a-z]{2,}): (.+)$/);
                    if (match)
                        map[match[3]] = match[2];
                }
            }

            root.kbMap = map;
            root.setKeyboardLayoutIndex(0);
        }
    }

    // wlr-foreign-toplevel-management, used for fullscreen state.
    readonly property var waylandToplevels: ToplevelManager

    Connections {
        target: Screens

        function onScreensChanged(): void {
            root.rebuild();
        }
    }

    Component.onCompleted: root.rebuild()
}
