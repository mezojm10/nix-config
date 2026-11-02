import QtQuick

// Stand-in for Quickshell.Hyprland.HyprlandFocusGrab.
//
// Niri has no equivalent grab API. Layer surfaces get keyboard focus through
// WlrLayershell.keyboardFocus instead (see ContentWindow.qml), and panels close
// through their own key handlers or IPC. This object keeps the call sites in
// the rest of the shell unchanged.
QtObject {
    property bool active: false
    property var windows: []

    signal cleared()
}
