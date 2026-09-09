import QtQuick
import qs.Commons
import qs.Ui
import "../Model.js" as Model

Column {
  id: root

  property QtObject vpnState: null
  property color foreground: Color.foreground
  property color urgent: Color.urgent
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(12)

  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: "Settings"
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.heading
    font.bold: true
  }

  Column {
    width: parent.width
    spacing: Style.space(8)

    PanelSectionHeader {
      text: "PROTOCOL"
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Row {
      spacing: Style.space(6)

      Button {
        text: "WireGuard"
        foreground: root.foreground
        fontFamily: root.fontFamily
        selected: root.vpnState && String(root.vpnState.protocol).toLowerCase() === "wireguard"
        bordered: true
        enabled: root.vpnState && !root.vpnState.busy
        onClicked: if (root.vpnState) root.vpnState.setProtocol("wireguard")
      }

      Button {
        text: "OpenVPN"
        foreground: root.foreground
        fontFamily: root.fontFamily
        selected: root.vpnState && String(root.vpnState.protocol).toLowerCase() === "openvpn"
        bordered: true
        enabled: root.vpnState && !root.vpnState.busy
        onClicked: if (root.vpnState) root.vpnState.setProtocol("openvpn")
      }
    }

    Text {
      width: parent.width
      visible: root.vpnState && root.vpnState.protocol === ""
      textFormat: Text.PlainText
      text: "Protocol is unknown until piactl responds. Choose WireGuard or OpenVPN to set it."
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }
  }

  PanelSeparator { foreground: root.foreground }

  Toggle {
    width: parent.width
    label: "Request port forwarding"
    description: "Asks PIA for a forwarded port on the next connect. Unavailable in the United States."
    checked: root.vpnState ? root.vpnState.requestPortForward : false
    foreground: root.foreground
    fontFamily: root.fontFamily
    onClicked: if (root.vpnState) root.vpnState.setRequestPortForward(!root.vpnState.requestPortForward)
  }

  Text {
    visible: root.vpnState && root.vpnState.requestPortForward
    width: parent.width
    textFormat: Text.PlainText
    text: "Current port: " + Model.portForwardLabel(root.vpnState.portForward)
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  Toggle {
    width: parent.width
    label: "Allow LAN"
    description: "Let local network traffic bypass the tunnel."
    checked: root.vpnState ? root.vpnState.allowLan : false
    foreground: root.foreground
    fontFamily: root.fontFamily
    onClicked: if (root.vpnState) root.vpnState.setAllowLan(!root.vpnState.allowLan)
  }

  Column {
    visible: root.vpnState && root.vpnState.killswitchKnown
    width: parent.width
    spacing: Style.space(6)

    PanelSectionHeader {
      text: "KILL SWITCH"
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Button {
      width: parent.width
      text: "Kill switch: " + Model.killswitchLabel(root.vpnState ? root.vpnState.killswitch : "")
      foreground: root.foreground
      fontFamily: root.fontFamily
      bordered: true
      enabled: root.vpnState && !root.vpnState.busy
      onClicked: if (root.vpnState) root.vpnState.cycleKillswitch()
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      text: "Cycles off → on → auto. Uses piactl’s unstable applysettings command."
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }
  }

  PanelSeparator { foreground: root.foreground }

  Button {
    width: parent.width
    text: "Enable background mode"
    foreground: root.foreground
    fontFamily: root.fontFamily
    onClicked: if (root.vpnState) root.vpnState.enableBackground()
  }

  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: "Background mode keeps the daemon active when the official GUI is closed. Required for connect from this plugin."
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  Button {
    width: parent.width
    text: "Sign out"
    foreground: root.urgent
    fontFamily: root.fontFamily
    bordered: true
    enabled: root.vpnState && !root.vpnState.busy
    onClicked: if (root.vpnState) root.vpnState.logout()
  }
}
