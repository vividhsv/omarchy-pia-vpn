import QtQuick
import qs.Commons
import qs.Ui

Column {
  id: root

  property QtObject vpnState: null
  property color foreground: Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(10)

  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: "About"
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.heading
    font.bold: true
  }

  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: "PIA VPN for Omarchy is an independent community plugin. It is not affiliated with, endorsed by, or supported by Private Internet Access, Inc. or Omarchy."
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
    wrapMode: Text.WordWrap
  }

  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: "The plugin talks to the official PIA Linux daemon through piactl. Tunneling, kill switch, and protocol handling stay in that daemon. This repository only contains the Omarchy UI."
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
    wrapMode: Text.WordWrap
  }

  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: "Version 0.1.0 · MIT License"
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  Text {
    visible: root.vpnState && root.vpnState.piactlPath !== ""
    width: parent.width
    textFormat: Text.PlainText
    text: "piactl: " + (root.vpnState ? root.vpnState.piactlPath : "")
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WrapAnywhere
  }
}
