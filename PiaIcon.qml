import QtQuick
import QtQuick.Shapes
import qs.Commons

Item {
  id: root

  property real iconSize: Style.font.icon
  property color statusColor: Color.foreground
  property color surfaceColor: Color.background
  property string state: "disconnected"

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  readonly property real opacityForState: state === "disconnected" ? 0.55 : 1.0
  readonly property bool showSlash: state === "disconnected"

  Item {
    id: mark
    anchors.fill: parent
    opacity: root.opacityForState

    Shape {
      id: shield
      anchors.fill: parent
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        fillColor: root.statusColor
        strokeWidth: 0
        startX: shield.width * 0.50
        startY: shield.height * 0.06
        PathLine { x: shield.width * 0.88; y: shield.height * 0.22 }
        PathLine { x: shield.width * 0.88; y: shield.height * 0.52 }
        PathCubic {
          x: shield.width * 0.50; y: shield.height * 0.94
          control1X: shield.width * 0.88; control1Y: shield.height * 0.74
          control2X: shield.width * 0.70; control2Y: shield.height * 0.88
        }
        PathCubic {
          x: shield.width * 0.12; y: shield.height * 0.52
          control1X: shield.width * 0.30; control1Y: shield.height * 0.88
          control2X: shield.width * 0.12; control2Y: shield.height * 0.74
        }
        PathLine { x: shield.width * 0.12; y: shield.height * 0.22 }
        PathLine { x: shield.width * 0.50; y: shield.height * 0.06 }
      }
    }

    Rectangle {
      visible: root.state === "connecting"
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: root.height * 0.04
      width: root.width * 0.22
      height: root.width * 0.22
      radius: width / 2
      color: root.surfaceColor
      opacity: 0.9
    }

    Rectangle {
      visible: root.showSlash
      width: root.width * 0.10
      height: root.height * 0.78
      radius: width / 2
      color: root.surfaceColor
      rotation: 38
      anchors.centerIn: parent
    }
  }

  SequentialAnimation {
    running: root.state === "connecting"
    loops: Animation.Infinite
    NumberAnimation { target: mark; property: "opacity"; from: 1.0; to: 0.45; duration: 520; easing.type: Easing.InOutQuad }
    NumberAnimation { target: mark; property: "opacity"; from: 0.45; to: 1.0; duration: 520; easing.type: Easing.InOutQuad }
  }
}
