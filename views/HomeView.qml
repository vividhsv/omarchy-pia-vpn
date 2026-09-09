import QtQuick
import qs.Commons
import qs.Ui
import ".."
import "../Model.js" as Model

Column {
  id: homePage

  property QtObject vpnState: null
  property color foreground: Color.foreground
  property color urgent: Color.urgent
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family

  signal locationsRequested()

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(12)

  Item {
    width: parent.width
    implicitHeight: hero.implicitHeight

    PanelHero {
      id: hero
      width: parent.width
      title: "PIA VPN"
      meta: homePage.vpnState ? homePage.vpnState.statusText : "Checking…"
      detail: homePage.vpnState && homePage.vpnState.connected ? "On" : "Off"
      foreground: homePage.foreground
      fontFamily: homePage.fontFamily
      iconOpacity: homePage.vpnState && homePage.vpnState.connected ? 1.0 : 0.55
      iconComponent: Component {
        PiaIcon {
          iconSize: Style.font.display
          statusColor: homePage.foreground
          state: homePage.vpnState ? homePage.vpnState.statusIconState : "disconnected"
        }
      }
      trailingControl: Component {
        ToggleSwitch {
          id: powerSwitch
          visible: homePage.vpnState && homePage.vpnState.installed && homePage.vpnState.loggedIn
          checked: homePage.vpnState ? homePage.vpnState.connected : false
          busy: homePage.vpnState ? homePage.vpnState.busy : false
          foreground: hero.foreground
          onToggled: if (homePage.vpnState) homePage.vpnState.toggleConnection()
        }
      }
    }
  }

  Column {
    width: parent.width
    spacing: Style.space(6)

    InfoPair { label: "Region"; value: homePage.vpnState ? (homePage.vpnState.regionLabel || "—") : "—" }
    InfoPair { label: "VPN IP"; value: homePage.vpnState && homePage.vpnState.vpnIp !== "" ? homePage.vpnState.vpnIp : "—" }
    InfoPair { label: "Public IP"; value: homePage.vpnState && homePage.vpnState.pubIp !== "" ? homePage.vpnState.pubIp : "—" }
    InfoPair { label: "Protocol"; value: homePage.vpnState ? homePage.vpnState.protocolLabel : "—" }
    InfoPair {
      visible: homePage.vpnState && homePage.vpnState.requestPortForward
      label: "Forwarded port"
      value: homePage.vpnState ? Model.portForwardLabel(homePage.vpnState.portForward) : "—"
    }
    InfoPair {
      visible: homePage.vpnState && homePage.vpnState.username !== ""
      label: "Account"
      value: homePage.vpnState ? homePage.vpnState.username : ""
    }
  }

  Button {
    width: parent.width
    text: "Choose location"
    foreground: homePage.foreground
    fontFamily: homePage.fontFamily
    bordered: true
    onClicked: homePage.locationsRequested()
  }

  Button {
    visible: homePage.vpnState && homePage.vpnState.installed
    width: parent.width
    text: "Enable background mode"
    foreground: homePage.foreground
    fontFamily: homePage.fontFamily
    onClicked: if (homePage.vpnState) homePage.vpnState.enableBackground()
  }

  component InfoPair: Column {
    property string label: ""
    property string value: ""
    width: parent.width
    spacing: Style.space(1)

    Text {
      textFormat: Text.PlainText
      text: label
      color: homePage.dim
      font.family: homePage.fontFamily
      font.pixelSize: Style.font.caption
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      text: value
      color: homePage.foreground
      font.family: homePage.fontFamily
      font.pixelSize: Style.font.body
      wrapMode: Text.WordWrap
    }
  }
}
