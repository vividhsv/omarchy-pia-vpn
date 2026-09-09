import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "pia.omarchy"

  property bool panelRequested: false
  property bool pendingOpen: false
  property string pendingRoute: ""

  readonly property color statusColor: bar ? bar.barForeground : Color.foreground
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("vpnState" in target) target.vpnState = piaState
  }

  function open() {
    if (panelLoader.item) {
      panelLoader.item.open()
      return
    }
    pendingOpen = true
    panelRequested = true
  }

  function openRoute(route) {
    pendingRoute = String(route || "home")
    if (panelLoader.item) {
      panelLoader.item.setRoute(pendingRoute)
      pendingRoute = ""
      panelLoader.item.open()
      return
    }
    pendingOpen = true
    panelRequested = true
  }

  function close() {
    pendingOpen = false
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (opened) close()
    else open()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
    else close()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  PiaState {
    id: piaState
    settings: root.settings
  }

  Loader {
    id: panelLoader
    active: root.panelRequested
    source: Qt.resolvedUrl("PiaPanel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(function() {
        root.injectPanel()
        if (root.pendingOpen && panelLoader.item) {
          root.pendingOpen = false
          if (root.pendingRoute) {
            panelLoader.item.setRoute(root.pendingRoute)
            root.pendingRoute = ""
          }
          panelLoader.item.open()
        }
      })
    }
  }

  IpcHandler {
    target: "pia.omarchy"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function home(): void { root.openRoute("home") }
    function locations(): void { root.openRoute("locations") }
    function settings(): void { root.openRoute("settings") }
    function about(): void { root.openRoute("about") }
    function connect(): void {
      if (!piaState.installed || !piaState.loggedIn) root.open()
      else piaState.connectVpn()
    }
    function disconnect(): void { piaState.disconnectVpn() }
    function refresh(): string { piaState.refresh(); return "ok" }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: "PIA VPN — " + piaState.statusText
    iconComponent: Component {
      Item {
        PiaIcon {
          anchors.centerIn: parent
          iconSize: parent.width
          statusColor: root.statusColor
          surfaceColor: root.bar ? root.bar.background : Color.bar.background
          state: piaState.statusIconState
        }
      }
    }

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        if (!piaState.installed || !piaState.loggedIn) root.open()
        else piaState.toggleConnection()
      } else if (buttonCode === Qt.MiddleButton) {
        root.openRoute("home")
      } else {
        root.toggle()
      }
    }
  }
}
