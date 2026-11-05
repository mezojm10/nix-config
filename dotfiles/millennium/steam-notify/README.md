# Steam notifications

Millennium plugin that turns Steam's own desktop toasts into freedesktop
notifications, so Noctalia shows them like any other notification.

Steam renders its toasts itself and never talks to `org.freedesktop.Notifications`.
The frontend hook drains `NotificationStore.m_rgNotificationToasts` before Steam's
`DispatchNextToast()` renders anything, then asks the Lua backend to run
`notify-send` for each entry. In-game overlay toasts and Steam sounds are left
alone.

## Files

- `steam-notify.star` (in the parent directory) is the built plugin that
  home-manager links into `~/.local/share/millennium/plugins/`.
- `frontend/index.tsx` and `backend/main.lua` are the source.
- `millennium.toml` and `package.json` are the build configuration.

## Rebuilding

The plugin is built with [starlight](https://docs.steambrew.app/developers/),
which needs Bun:

```sh
bun install --ignore-scripts
```

On NixOS, `starlight`'s bundled binary is dynamically linked and will not run
before it is patched:

```sh
patchelf --set-interpreter "$(nix eval --raw nixpkgs#glibc.outPath)/lib64/ld-linux-x86-64.so.2" \
  --set-rpath "$(nix eval --raw nixpkgs#glibc.outPath)/lib:$(nix eval --raw nixpkgs#gcc-unwrapped.lib.outPath)/lib" \
  node_modules/@steambrew/starlight/binaries/starlight-linux-x64

bun run build
```

`bun run build` writes `~/.local/share/millennium/plugins/steam-notify.star`.
Copy that file back over `dotfiles/millennium/steam-notify.star` and rebuild the
system.

## After installing

Home-manager links `steam-notify.star` into
`~/.local/share/millennium/plugins/` and adds `steam-notify` to
`~/.config/millennium/config.json`. Restart Steam so Millennium reads the new
config. If toasts still appear, check Steam → Settings → Millennium → Plugins
for **Steam notifications**.

Values written to `~/.cache/steam-notify.log` are load/error messages only,
never notification text.

This hooks Steam client internals and can break after a Steam update. If toasts
come back, check that log for `hooked NotificationStore.DispatchNextToast`.
