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
  property string query: ""
  readonly property bool searchFocused: searchField.activeFocus
  readonly property var visibleRegions: Model.filterRegions(vpnState ? vpnState.regions : [], query)

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(10)

  function focusInitial() {
    searchField.forceActiveFocus()
  }

  function focusSearch() {
    searchField.forceActiveFocus()
  }

  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: "Locations"
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.heading
    font.bold: true
  }

  TextField {
    id: searchField
    width: parent.width
    foreground: root.foreground
    placeholderText: "Search regions"
    onTextChanged: root.query = text
  }

  Text {
    visible: !root.vpnState || root.vpnState.regions.length === 0
    width: parent.width
    textFormat: Text.PlainText
    text: root.vpnState && root.vpnState.busy ? "Loading regions…" : "No regions yet. Press r to refresh."
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
    wrapMode: Text.WordWrap
  }

  Column {
    visible: root.visibleRegions.length > 0
    width: parent.width
    spacing: Style.space(4)

    Repeater {
      model: root.visibleRegions

      CursorSurface {
        required property var modelData
        width: parent.width
        implicitHeight: row.implicitHeight + Style.space(10)
        foreground: root.foreground
        current: root.vpnState && root.vpnState.region === modelData.id

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (root.vpnState) root.vpnState.connectRegion(modelData.id)
          }
        }

        Row {
          id: row
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: Style.space(10)
          anchors.rightMargin: Style.space(10)
          spacing: Style.space(8)

          Text {
            width: parent.width - mark.implicitWidth - parent.spacing
            textFormat: Text.PlainText
            text: modelData.label
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            id: mark
            visible: root.vpnState && root.vpnState.region === modelData.id
            text: "●"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }
}
