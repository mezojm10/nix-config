import QtQuick

// Hyprland global shortcuts do not exist on niri. Keybinds are declared in the
// niri config and call the shell's IPC handlers (e.g.
// `caelestia-shell ipc call drawers toggle launcher`) instead.
QtObject {
    required property string name
    required property string description

    signal pressed
    signal released
}
