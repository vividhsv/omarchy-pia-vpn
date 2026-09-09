import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "views"
import "Model.js" as Model

FocusScope {
  id: root

  property QtObject vpnState: null
  property color foreground: Color.popups.text
  property color urgent: Color.urgent
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family
  property string route: "home"
  property var routeStack: ["home"]

  readonly property bool installerVisible: !vpnState || !vpnState.installed
  readonly property bool authVisible: !installerVisible && vpnState && !vpnState.loggedIn
  readonly property bool inputViewVisible: installerVisible || authVisible
  readonly property var rootRoutes: ["home", "locations", "settings", "about"]
  readonly property string selectedRoot: rootRoutes.indexOf(route) >= 0 ? route : String(routeStack[0] || "home")
  readonly property var navigationDestinations: [
    { route: "home", label: "Home" },
    { route: "locations", label: "Locations" },
    { route: "settings", label: "Settings" },
    { route: "about", label: "About" }
  ]
  readonly property bool searchFocused: currentPage && currentPage.searchFocused === true
  readonly property bool authFocused: currentPage && currentPage.authFocused === true
  readonly property alias currentPage: pageLoader.item

  signal closeRequested()
  signal switchPanelRequested(int direction)

  function setRoute(value) {
    var candidate = String(value || "home")
    if (rootRoutes.indexOf(candidate) < 0) candidate = "home"
    if (candidate === route) return
    routeStack = [candidate]
    route = candidate
    if (candidate === "locations" && vpnState) vpnState.refreshRegions()
  }

  function focusInitial() {
    if (currentPage && typeof currentPage.focusInitial === "function") currentPage.focusInitial()
    else keyCatcher.forceActiveFocus()
  }

  implicitHeight: chrome.implicitHeight + Style.space(8) + pageColumn.implicitHeight
  width: parent ? parent.width : implicitWidth

  PanelKeyCatcher {
    id: keyCatcher
    anchors.fill: parent
    blocked: root.searchFocused || root.authFocused
    onCloseRequested: root.closeRequested()
    onTabRequested: function(direction) { root.switchPanelRequested(direction) }
    onTextKey: function(t) {
      if (t === "r" || t === "R") {
        if (vpnState) vpnState.refresh()
      } else if (t === "t" || t === "T") {
        if (vpnState) vpnState.toggleConnection()
      } else if (t === "1") root.setRoute("home")
      else if (t === "2") root.setRoute("locations")
      else if (t === "3") root.setRoute("settings")
      else if (t === "4") root.setRoute("about")
    }
    onActivateRequested: {
      if (root.installerVisible && vpnState) vpnState.installBackend()
    }

    Column {
      id: chrome
      width: parent.width
      spacing: Style.space(8)

      RowLayout {
        width: parent.width
        spacing: Style.space(8)

        PiaIcon {
          iconSize: Style.font.iconLarge
          statusColor: root.vpnState && root.vpnState.connected
            ? Model.connectedColor()
            : root.foreground
          state: root.vpnState ? root.vpnState.statusIconState : "disconnected"
        }

        Text {
          Layout.fillWidth: true
          textFormat: Text.PlainText
          text: "PIA VPN"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.weight: Font.DemiBold
        }

        PanelActionButton {
          iconText: "✕"
          tooltipText: "Close"
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: root.closeRequested()
        }
      }

      RowLayout {
        visible: !root.inputViewVisible
        width: parent.width
        spacing: Style.space(6)

        Repeater {
          model: root.navigationDestinations
          Button {
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            text: modelData.label
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.caption
            selected: root.selectedRoot === modelData.route
            onClicked: root.setRoute(modelData.route)
          }
        }
      }

      Text {
        visible: root.vpnState && (root.vpnState.actionStatus !== "" || root.vpnState.lastError !== "")
        width: parent.width
        textFormat: Text.PlainText
        text: root.vpnState && root.vpnState.actionStatus !== ""
          ? root.vpnState.actionStatus
          : (root.vpnState ? root.vpnState.lastError : "")
        color: root.vpnState && root.vpnState.lastError !== "" && root.vpnState.actionStatus === ""
          ? root.urgent : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }

      Flickable {
        id: viewport
        width: parent.width
        height: Math.min(pageColumn.implicitHeight, Style.space(480))
        contentWidth: width
        contentHeight: pageColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height

        Column {
          id: pageColumn
          width: viewport.width
          Loader {
            id: pageLoader
            width: parent.width
            height: item ? item.implicitHeight : 0
            sourceComponent: {
              if (root.installerVisible) return installerComponent
              if (root.authVisible) return authComponent
              switch (root.route) {
              case "locations": return locationsComponent
              case "settings": return settingsComponent
              case "about": return aboutComponent
              default: return homeComponent
              }
            }
          }
        }
      }
    }
  }

  Component {
    id: installerComponent
    InstallerView {
      vpnState: root.vpnState
      foreground: root.foreground
      urgent: root.urgent
      dim: root.dim
      fontFamily: root.fontFamily
    }
  }

  Component {
    id: authComponent
    AuthView {
      vpnState: root.vpnState
      foreground: root.foreground
      urgent: root.urgent
      dim: root.dim
      fontFamily: root.fontFamily
    }
  }

  Component {
    id: homeComponent
    HomeView {
      vpnState: root.vpnState
      foreground: root.foreground
      urgent: root.urgent
      dim: root.dim
      fontFamily: root.fontFamily
      onLocationsRequested: root.setRoute("locations")
    }
  }

  Component {
    id: locationsComponent
    LocationsView {
      vpnState: root.vpnState
      foreground: root.foreground
      urgent: root.urgent
      dim: root.dim
      fontFamily: root.fontFamily
    }
  }

  Component {
    id: settingsComponent
    SettingsView {
      vpnState: root.vpnState
      foreground: root.foreground
      urgent: root.urgent
      dim: root.dim
      fontFamily: root.fontFamily
    }
  }

  Component {
    id: aboutComponent
    AboutView {
      vpnState: root.vpnState
      foreground: root.foreground
      dim: root.dim
      fontFamily: root.fontFamily
    }
  }
}
