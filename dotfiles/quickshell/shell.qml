//@ pragma ShellId tokyo-night
//@ pragma IconTheme Papirus-Dark

import Quickshell
import Quickshell.Io

ShellRoot {
    // A direct window keeps niri happy when a background and a panel are
    // mapped from the same Quickshell instance. The bar is created per screen.
    Background {
        screen: Quickshell.screens[0]
    }

    Variants {
        model: Quickshell.screens

        Bar {
            property var modelData
            screen: modelData
        }
    }
}
