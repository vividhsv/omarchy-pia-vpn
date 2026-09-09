import QtQuick
import qs.Commons
import qs.Ui

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
    text: "Install the official PIA client"
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.heading
    font.bold: true
    wrapMode: Text.WordWrap
  }

  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: "This plugin wraps piactl. It does not ship a tunnel. Install the official Private Internet Access Linux client (AUR package piavpn-bin), enable the daemon, then sign in here."
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
    wrapMode: Text.WordWrap
  }

  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: "A terminal will open so you can read every command and enter your password if sudo asks."
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  Button {
    width: parent.width
    text: "Install PIA backend"
    foreground: root.foreground
    fontFamily: root.fontFamily
    bordered: true
    enabled: root.vpnState && !root.vpnState.busy
    onClicked: if (root.vpnState) root.vpnState.installBackend()
  }

  Button {
    width: parent.width
    text: "I already installed it — refresh"
    foreground: root.foreground
    fontFamily: root.fontFamily
    onClicked: if (root.vpnState) root.vpnState.refresh()
  }
}
