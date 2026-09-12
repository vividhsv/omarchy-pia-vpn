# Contributing

This is an independent Omarchy Quattro bar plugin for Private Internet Access. The UI runs inside `omarchy-shell`; the tunnel stays in the official PIA daemon and is driven only through `piactl`. Do not ship PIA binaries, trademarks, or a custom tunnel.

Keep the independent-project disclaimer in README, NOTICE.md, About, and the installer.

## Marketplace packaging

`omarchy plugin add` clones this repository as-is. Do not commit agent-control files (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, and similar). Keep a local copy if you want them; `.gitignore` is set to leave them untracked.

Before a release:

```bash
python3 scripts/check-release-tree.py
omarchy plugin validate .
```

## Layout and commands

See [README.md](README.md) for install, update, and removal. The plugin id is `pia.omarchy`. `BarWidget.qml` is the only IPC entry; `PiaPanel.qml` must keep `manageIpc: false`.

Mutating VPN calls go through `piactl` via `runAction`, not `bash -lc`. Login must never put the password on argv, in logs, or in git. Kill switch uses unstable `piactl -u applysettings` and is best-effort.

## UI

Match Omarchy / Tailscale chrome (`qs.Ui`, `qs.Commons`). Connected green is `Model.connectedColor()` on in-panel affordances only; the bar icon stays themed. Use `PiaPowerSwitch` / `PiaToggle`, not `ToggleSwitch`. Set `textFormat: Text.PlainText`.
