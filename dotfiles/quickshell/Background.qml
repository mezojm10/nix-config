import QtQuick
import Quickshell
import Quickshell.Wayland
import "Theme.js" as Theme

PanelWindow {
    id: background

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-background"

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            orientation: Gradient.Vertical

            GradientStop {
                position: 0.0
                color: Theme.bgDark
            }
            GradientStop {
                position: 0.42
                color: Theme.bg
            }
            GradientStop {
                position: 1.0
                color: Theme.bgDeep
            }
        }
    }

    // Soft Tokyo Night glows. Low opacity keeps them readable behind windows.
    Rectangle {
        width: parent.width * 0.55
        height: width
        radius: width / 2
        x: -width * 0.2
        y: -height * 0.35
        color: Theme.alpha(Theme.blue, 0.10)
    }

    Rectangle {
        width: parent.width * 0.45
        height: width
        radius: width / 2
        x: parent.width - width * 0.7
        y: parent.height - height * 0.55
        color: Theme.alpha(Theme.magenta, 0.08)
    }

    Rectangle {
        width: parent.width * 0.3
        height: width
        radius: width / 2
        x: parent.width * 0.55
        y: -height * 0.4
        color: Theme.alpha(Theme.cyan, 0.05)
    }

    // A quiet horizon line for a bit of structure.
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: parent.height * 0.22
        }
        height: 1
        color: Theme.alpha(Theme.surfaceAlt, 0.35)
    }
}
