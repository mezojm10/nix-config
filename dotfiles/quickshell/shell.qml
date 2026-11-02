//@ pragma ShellId tokyo-night
//@ pragma IconTheme Papirus-Dark
// Tray menus are Qt platform menus, which need a QApplication.
//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import "Theme.js" as Theme

ShellRoot {
    id: shell

    ShellState {
        id: state
    }

    Brightness {
        id: brightnessController
    }

    // Quickshell is the notification daemon now. mako was removed from the
    // NixOS module and mako.service is gone, so this can own the bus name.
    NotificationServer {
        id: notificationServer

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    // Ignore the volume events that arrive while PipeWire connects at startup.
    property bool audioReady: false

    Timer {
        interval: 1500
        running: true
        onTriggered: shell.audioReady = true
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        ignoreUnknownSignals: true

        function onVolumesChanged() {
            const audio = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null;

            if (!audio || !shell.audioReady)
                return;

            const percent = Math.round(audio.volume * 100);

            state.showOsd(
                audio.muted ? "\u{f0581}" : Theme.volumeIcon(percent, false),
                audio.muted ? "Muted" : percent + "%",
                audio.muted ? -1 : percent / 100,
                audio.muted ? Theme.red : Theme.blue
            );
        }

        function onMutedChanged() {
            const audio = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null;

            if (!audio || !shell.audioReady)
                return;

            const percent = Math.round(audio.volume * 100);

            state.showOsd(
                audio.muted ? "\u{f0581}" : Theme.volumeIcon(percent, false),
                audio.muted ? "Muted" : percent + "%",
                audio.muted ? -1 : percent / 100,
                audio.muted ? Theme.red : Theme.blue
            );
        }
    }

    Connections {
        target: brightnessController

        function onChanged(percent) {
            state.showOsd("\u{f185}", percent + "%", percent / 100, Theme.yellow);
        }
    }

    // A direct window keeps niri happy when a background and a panel are
    // mapped from the same Quickshell instance.
    Background {
        screen: Quickshell.screens[0]
    }

    Variants {
        model: Quickshell.screens

        Bar {
            screen: modelData
            shellState: state
        }
    }

    Variants {
        model: Quickshell.screens

        QuickSettings {
            property var modelData

            monitor: modelData
            shellState: state
            brightness: brightnessController
        }
    }

    Variants {
        model: Quickshell.screens

        PowerDialog {
            property var modelData

            monitor: modelData
            shellState: state
        }
    }

    NotificationPopups {
        monitor: Quickshell.screens[0]
        shellState: state
        notifications: notificationServer
    }

    Osd {
        monitor: Quickshell.screens[0]
        shellState: state
    }
}
