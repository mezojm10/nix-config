# caelestia-shell (niri fork)

Vendored copy of [caelestia-dots/shell](https://github.com/caelestia-dots/shell),
patched to run on [niri](https://github.com/YaLTeR/niri) instead of Hyprland.
Upstream and niri both evolve quickly, so keep a list of local changes here to
make rebasing onto a newer upstream checkout manageable.

## Layout

- The whole upstream tree is kept, including its `flake.nix` and `nix/`
  packaging. The parent flake consumes it as the `caelestia-shell` path input.
- `nix/default.nix`: `hyprland` was replaced by `niri` in the runtime
  dependencies.

## Porting changes

| File | Change |
| --- | --- |
| `services/Hypr.qml` | Rewritten. Same API the rest of the shell uses, backed by `niri msg event-stream` and wlr-foreign-toplevel-management instead of Quickshell.Hyprland + HyprExtras. |
| `components/misc/CustomShortcut.qml` | No-op stub. Niri has no wlr-global-shortcuts; keybinds live in `dotfiles/niri/config.kdl` and call the `drawers` IPC target. |
| `components/misc/SoftFocusGrab.qml` | New stub replacing `HyprlandFocusGrab`. |
| `modules/drawers/ContentWindow.qml` | Uses `SoftFocusGrab` and `WlrKeyboardFocus.Exclusive` while a drawer is open. |
| `modules/bar/popouts/Wrapper.qml` | Uses `SoftFocusGrab`; drops the Hyprland import. |
| `modules/bar/components/workspaces/*` | Hyprland-specific types replaced by `var`; behaviour unchanged. |
| `modules/bar/popouts/kblayout/KbLayoutModel.qml` | Reads `niri msg -j keyboard-layouts`; selection cycles with `niri msg action switch-layout`. |
| `modules/areapicker/Picker.qml` | Drops `hyprctl cursorpos` (niri does not expose the pointer) and uses the shell's own border config instead of Hyprland options. |
| `modules/windowinfo/*` | Hyprland types replaced by `var`. |
| `daemons/GameMode.qml` | Stubs out Hyprland option changes; toast wording adjusted. |

## Known limitations on niri

- No special workspaces, so `toggleSpecial()` is a no-op and special-workspace
  pills stay empty.
- Window geometry is not exposed by niri IPC; window position is reported as
  0,0 and per-window previews/area-picker window snapping do not work.
- No window tags; `bar.workspaces.ignoredTags` has no effect.
- Blur behind the bar/drawers is not applied: Caelestia draws all panels on one
  full-screen layer surface, which niri would blur as a whole.
