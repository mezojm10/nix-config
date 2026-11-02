pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n

// Niri port: layouts are read from `niri msg -j keyboard-layouts`, which only
// reports names and the active index. Selecting a layout passes its index to
// `niri msg action switch-layout`.

Item {
    id: model

    property alias visibleModel: visibleModel
    property string activeLabel: ""
    property int activeIndex: -1
    property bool _notifiedLimit: false

    function start() {
        refresh();
    }

    function refresh() {
        _notifiedLimit = false;
        getLayouts.running = true;
    }

    function switchTo(idx) {
        const count = layoutsModel.count;
        const from = activeIndex >= 0 ? activeIndex : 0;
        if (count < 2 || idx === from)
            return;

        Quickshell.execDetached(["niri", "msg", "action", "switch-layout", String(idx)]);

        activeIndex = idx;
        activeLabel = idx < count ? layoutsModel.get(idx).label : "";
        model._rebuildVisible();
        refreshTimer.restart();
    }

    function _setLayouts(names) {
        layoutsModel.clear();
        names.forEach((name, idx) => layoutsModel.append({
            layoutIndex: idx,
            token: name,
            label: name
        }));
    }

    function _rebuildVisible() {
        visibleModel.clear();

        let arr = [];
        for (let i = 0; i < layoutsModel.count; i++)
            arr.push(layoutsModel.get(i));

        arr = arr.filter(i => i.layoutIndex !== activeIndex);
        arr.forEach(i => visibleModel.append(i));

        if (!GlobalConfig.utilities.toasts.kbLimit)
            return;

        if (layoutsModel.count > 4)
            Toaster.toast(Tr.tr("Keyboard layout limit"), Tr.tr("XKB supports only 4 layouts at a time"), "warning");
    }

    visible: false

    ListModel {
        id: visibleModel
    }

    ListModel {
        id: layoutsModel
    }

    Process {
        id: getLayouts

        command: ["niri", "msg", "-j", "keyboard-layouts"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const layouts = JSON.parse(text);
                    model._setLayouts(layouts.names ?? []);
                    model.activeIndex = layouts.current_idx ?? -1;
                    model.activeLabel = model.activeIndex >= 0 && model.activeIndex < layoutsModel.count ? layoutsModel.get(model.activeIndex).label : "";
                } catch (e) {
                    model.activeIndex = -1;
                    model.activeLabel = "";
                }
                model._rebuildVisible();
            }
        }
    }

    Timer {
        id: refreshTimer

        interval: 50
        onTriggered: getLayouts.running = true
    }
}
