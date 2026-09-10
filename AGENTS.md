# Agent instructions

Independent Omarchy Quattro **bar plugin** for Private Internet Access. The UI runs inside `omarchy-shell` (Quickshell). The tunnel stays in the official PIA daemon and is driven only through `piactl`.

This is **not** affiliated with PIA or Omarchy. Do not ship PIA binaries, trademarks, or a custom tunnel. Keep that disclaimer in README, NOTICE, About, and the installer.

## Layout

```
manifest.json          plugin id pia.omarchy, barWidget entry
BarWidget.qml          bar icon, mouse buttons, IpcHandler
PiaState.qml           piactl process orchestration and UI state
Model.js               parse status/regions, labels, connectedColor()
PiaPanel.qml           Panel + KeyboardPanel (manageIpc: false)
PiaWorkspace.qml       routes, keys, Installer/Auth vs signed-in pages
views/                 Home, Locations, Settings, About, Auth, Installer
PiaIcon.qml            shield; connected / connecting / disconnected
PiaPowerSwitch.qml     green on-state switch (do not replace with ToggleSwitch)
PiaToggle.qml          labeled row using PiaPowerSwitch
scripts/pia-status.sh  python3: key=value snapshot for the UI
scripts/pia-traffic.sh python3: wgpia0 rx/tx bytes for the Home sparkline
scripts/piactl-login.sh  stdin → 0600 temp file → piactl login → shred
scripts/install-backend.sh  AUR piavpn-bin + piavpn.service + background enable
PiaSparkline.qml       WireGuard down/up sparkline on Home
```

## Commands

```bash
omarchy plugin validate .
mkdir -p ~/.config/omarchy/plugins
ln -sfn "$(pwd)" ~/.config/omarchy/plugins/pia.omarchy
omarchy-shell shell rescanPlugins
omarchy plugin enable pia.omarchy
```

QML under `~/.config/omarchy/plugins/` hot-reloads. New files or a stuck bar: `omarchy restart shell`. Do not edit `/usr/share/omarchy/` (read it). Copy Omarchy UI from `qs.Ui` / `qs.Commons` and the Tailscale panel, not from raw Qt Controls.

IPC target `pia.omarchy`: `open`, `close`, `show`, `hide`, `toggle`, `home`, `locations`, `settings`, `about`, `connect`, `disconnect`, `refresh`. Keep `IpcHandler` on `BarWidget.qml` only.

## Architecture

- **Installer** if `!installed`, **Auth** if installed but signed out, else Home / Locations / Settings / About.
- Keys (when search/auth are not focused): `t` toggle, `r` refresh, `1`–`4` routes, `Esc` close. Left click toggles the panel, right click connects/disconnects (or opens if unsigned), middle click opens Home.
- Optimistic chrome: `_desired` is `-1` (follow daemon), `1` (connecting), or `0` (disconnecting). `_stableConnected` flips only on Connected vs Disconnected so Connecting does not flicker the switch. If `connectVpn()` cannot run, clear `_desired`.
- Status polling is `python3 scripts/pia-status.sh` (`installed=…` lines). Regions are `piactl get regions`. Mutating calls go through `runAction([piactl(), …])`, not `bash -lc`.
- Home sparkline samples `/sys/class/net/wgpia0` via `python3 scripts/pia-traffic.sh` while the panel is open, WireGuard is selected, and a VPN IP is present. No extra privileges, still no custom tunnel.
- Login: write user/pass to the login process stdin. Never put the password on argv, in logs, or in git.
- Kill switch uses unstable `piactl -u applysettings`. Treat it as best-effort.

## UI

Use Omarchy tokens: `Style.space()`, `Style.font.*`, `Color.*`, `qs.Ui` (`Panel`, `PanelHero`, `Button`, `TextField`, `BorderSurface`, `PanelKeyCatcher`). Views take `vpnState`, `foreground`, `urgent`, `dim`, `fontFamily`. Set `textFormat: Text.PlainText`.

Connected green is `Model.connectedColor()` (`#3d9a5f`) on the **in-panel** shield and switches. The **bar icon stays themed** (`bar.barForeground`) — do not paint it green.

`ToggleSwitch` cannot show that green: Omarchy bakes `selected-color` to a theme hex. Use `PiaPowerSwitch` / `PiaToggle`.

## Do not

- Implement WireGuard/OpenVPN yourself, scrape the PIA website, or call undocumented HTTP APIs when `piactl` exists.
- Sample any interface other than `/sys/class/net/wgpia0`, or show a live traffic graph on OpenVPN.
- Store credentials, commit secrets, or skip shred on the login tempfile.
- Duplicate IPC on `PiaPanel` (`manageIpc: false` is required).
- Restyle the whole panel against the active Omarchy theme. Match Tailscale/Omarchy chrome; only the connected affordances are plugin-green.
