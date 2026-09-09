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
  property string username: ""
  property string password: ""
  readonly property bool authFocused: userField.activeFocus || passField.activeFocus

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(10)

  function focusInitial() {
    userField.forceActiveFocus()
  }

  function submit() {
    if (root.vpnState) root.vpnState.login(userField.text, passField.text)
  }

  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: "Sign in to Private Internet Access"
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.heading
    font.bold: true
    wrapMode: Text.WordWrap
  }

  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: "Credentials go to piactl through a temporary file in your runtime directory, then the file is shredded. The plugin does not store your password."
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  Text {
    textFormat: Text.PlainText
    text: "Username"
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  TextField {
    id: userField
    width: parent.width
    foreground: root.foreground
    placeholderText: "p0123456"
    onAccepted: passField.forceActiveFocus()
  }

  Text {
    textFormat: Text.PlainText
    text: "Password"
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  TextField {
    id: passField
    width: parent.width
    foreground: root.foreground
    password: true
    placeholderText: "Password"
    onAccepted: root.submit()
  }

  Button {
    width: parent.width
    text: root.vpnState && root.vpnState.busy ? "Signing in…" : "Sign in"
    foreground: root.foreground
    fontFamily: root.fontFamily
    bordered: true
    enabled: root.vpnState && !root.vpnState.busy && userField.text !== "" && passField.text !== ""
    onClicked: root.submit()
  }
}
