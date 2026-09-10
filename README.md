# PIA VPN for Omarchy

A native Omarchy Quattro bar plugin for [Private Internet Access](https://privateinternetaccess.com). The UI runs inside `omarchy-shell`; the tunnel stays in the official PIA Linux daemon and is driven through [`piactl`](https://helpdesk.privateinternetaccess.com/hc/en-us/articles/46815372532123-PIA-Desktop-Command-Line-Interface).

This is an independent community project. It is **not affiliated with, endorsed by, or supported by** Private Internet Access, Inc. or Omarchy.

## Features

- Bar icon for connected / connecting / disconnected
- Left click opens the panel, right click connects or disconnects, middle click opens Home
- Sign in without putting the password on a command line (temporary file, then shred)
- Region list from `piactl get regions`
- Protocol (WireGuard / OpenVPN), port forwarding, LAN bypass, and kill switch
- First-run installer that opens a terminal for `omarchy pkg aur add piavpn-bin`
- Live down/up sparkline on Home while WireGuard is connected (reads `/sys/class/net/wgpia0`)

## Requirements

- Arch Linux with Omarchy Quattro 4.x
- Official PIA client (`piavpn-bin` from the AUR), or install it from the plugin panel
- `piactl` and `piavpn.service`

## Install

```bash
omarchy plugin add https://github.com/vividhsv/omarchy-pia-vpn.git --enable
```

Omarchy warns before enabling third-party plugins because they run inside the shell process. Read the source first.

Open the PIA icon and choose **Install PIA backend** if `piactl` is missing. That opens a terminal that runs:

```bash
omarchy pkg aur add piavpn-bin
sudo systemctl enable --now piavpn.service
piactl background enable
```

Background mode is required so the daemon stays up without the official GUI.

### Local development

```bash
omarchy plugin validate .
mkdir -p ~/.config/omarchy/plugins
ln -sfn "$(pwd)" ~/.config/omarchy/plugins/pia.omarchy
omarchy-shell shell rescanPlugins
omarchy plugin enable pia.omarchy
```

Saving QML under `~/.config/omarchy/plugins/` reloads the plugin. If the bar does not pick it up, `omarchy restart shell`.

## Use

- `t` toggle connect (when signed in)
- `r` refresh status
- `1`–`4` Home / Locations / Settings / About
- `Esc` close

The plugin registers Quickshell IPC target `pia.omarchy` with `open`, `close`, `toggle`, `connect`, `disconnect`, and `refresh`.

## Remove

```bash
omarchy plugin remove pia.omarchy
```

That only removes the frontend. To also remove the official PIA client:

```bash
systemctl --user is-active piavpn >/dev/null 2>&1 || true
sudo systemctl disable --now piavpn.service
sudo pacman -Rns piavpn-bin
```

## License

MIT. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md). PIA’s own client remains under its upstream licenses.
