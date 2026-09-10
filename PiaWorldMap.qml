import QtQuick
import QtQuick.Effects
import qs.Commons
import "Model.js" as Model

Item {
  id: root

  property var regions: []
  property string selectedId: ""
  property bool connected: false
  property string query: ""
  property color foreground: Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family

  readonly property var pins: Model.mappableRegions(regions)
  readonly property string hoverLabel: {
    for (var i = 0; i < pins.length; i++) {
      if (pins[i].id === hoveredId) return pins[i].label || pins[i].id
    }
    return ""
  }

  property string hoveredId: ""

  signal regionClicked(string id)

  implicitHeight: width * Model.mapAspect()
  height: implicitHeight
  clip: true

  Image {
    id: land
    anchors.fill: parent
    fillMode: Image.PreserveAspectFit
    source: Qt.resolvedUrl("assets/world-land.svg")
    asynchronous: true
    visible: false
    cache: true
  }

  MultiEffect {
    anchors.fill: land
    source: land
    colorization: 1.0
    colorizationColor: root.dim
    opacity: 0.55
  }

  Repeater {
    model: root.pins

    Item {
      id: pin
      required property var modelData
      required property int index

      readonly property bool selected: root.selectedId !== "" && root.selectedId === modelData.id
      readonly property bool active: pin.selected && root.connected
      readonly property bool hovered: root.hoveredId === modelData.id
      readonly property bool unmatched: {
        if (root.query === "" || pin.selected) return false
        return !Model.regionMatchesQuery(modelData, root.query)
      }
      readonly property var point: Model.projectEquirectangular(
        modelData.lat, modelData.lon, root.width, root.height)
      readonly property int dot: pin.active ? 11 : (pin.selected ? 9 : (pin.hovered ? 6 : 3))

      visible: !!(point)
      width: 16
      height: 16
      x: point ? point.x - width / 2 : 0
      y: point ? point.y - height / 2 : 0
      z: pin.selected ? 30 : (pin.hovered ? 20 : pin.index + 1)
      opacity: pin.unmatched ? 0.22 : 1

      Rectangle {
        width: pin.dot
        height: pin.dot
        radius: width / 2
        anchors.centerIn: parent
        color: pin.active
          ? Model.connectedColor()
            : (pin.selected || pin.hovered
            ? root.foreground
            : Util.alpha(root.foreground, 0.45))
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hoveredId = pin.modelData.id
        onExited: if (root.hoveredId === pin.modelData.id) root.hoveredId = ""
        onClicked: root.regionClicked(pin.modelData.id)
      }
    }
  }

  Text {
    visible: root.hoverLabel !== ""
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: Style.space(4)
    textFormat: Text.PlainText
    text: root.hoverLabel
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
    z: 40
  }
}
