import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "pia.omarchy"
  ipcTarget: "pia.omarchy"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property QtObject vpnState: null
  property alias route: workspace.route
  readonly property var barIdentity: hostWidget || root

  function setRoute(value) { workspace.setRoute(value) }

  function open() {
    if (vpnState) {
      vpnState.refresh()
      if (vpnState.installed && vpnState.loggedIn) vpnState.refreshRegions()
      if (typeof vpnState.setTrafficWatch === "function") vpnState.setTrafficWatch(true)
    }
    controller.show()
    Qt.callLater(workspace.focusInitial)
  }

  function close() { controller.hide() }
  function toggle() { if (opened) close(); else open() }
  function switchPanel(direction) {
    return root.bar && typeof root.bar.switchPanelFrom === "function"
      ? root.bar.switchPanelFrom(root.barIdentity, direction) : false
  }

  onOpenedChanged: {
    if (bar && "centerHoverRevealSuppressed" in bar) bar.centerHoverRevealSuppressed = opened
    if (vpnState && typeof vpnState.setTrafficWatch === "function") vpnState.setTrafficWatch(opened)
    if (opened) Qt.callLater(workspace.focusInitial)
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: workspace
    contentWidth: fittedContentWidth(Style.space(400))
    contentHeight: fittedContentHeight(Style.space(620), Style.space(620))

    PiaWorkspace {
      id: workspace
      anchors.fill: parent
      vpnState: root.vpnState
      onCloseRequested: root.close()
      onSwitchPanelRequested: function(direction) { root.switchPanel(direction) }
    }
  }
}
