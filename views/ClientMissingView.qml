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
    text: "Official PIA client required"
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.heading
    font.bold: true
    wrapMode: Text.WordWrap
  }

  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: "This plugin wraps piactl. It does not ship a tunnel and does not install the Private Internet Access client. Install that official Linux client yourself, enable its daemon, then run piactl background enable so the VPN can run without the official GUI."
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
    wrapMode: Text.WordWrap
  }

  Button {
    width: parent.width
    text: "I already have piactl — refresh"
    foreground: root.foreground
    fontFamily: root.fontFamily
    bordered: true
    onClicked: if (root.vpnState) root.vpnState.refresh()
  }
}
