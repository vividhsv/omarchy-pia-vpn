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
    contentHeight: fittedContentHeight(Style.space(560), Style.space(560))

    PiaWorkspace {
      id: workspace
      anchors.fill: parent
      vpnState: root.vpnState
      onCloseRequested: root.close()
      onSwitchPanelRequested: function(direction) { root.switchPanel(direction) }
    }
  }
}
