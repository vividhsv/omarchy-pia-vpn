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

  readonly property bool showTraffic: vpnState && vpnState.wireguard && vpnState.hasVpnIp
  readonly property string trafficDown: vpnState && vpnState.trafficReady
    ? Model.formatRate(vpnState.trafficRxRate) : "—"
  readonly property string trafficUp: vpnState && vpnState.trafficReady
    ? Model.formatRate(vpnState.trafficTxRate) : "—"
  readonly property string trafficDownTotal: vpnState
    ? Model.formatBytes(vpnState.trafficRxTotal) : "—"
  readonly property string trafficUpTotal: vpnState
    ? Model.formatBytes(vpnState.trafficTxTotal) : "—"

  signal locationsRequested()

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(12)

  Item {
    width: parent.width
    implicitHeight: hero.implicitHeight

    PanelHero {
      id: hero
      width: parent.width
      height: implicitHeight
      title: "PIA VPN"
      meta: homePage.vpnState ? homePage.vpnState.statusText : "Checking…"
      foreground: homePage.foreground
      fontFamily: homePage.fontFamily
      iconOpacity: 1.0
      iconComponent: Component {
        PiaIcon {
          iconSize: Style.font.display
          statusColor: homePage.vpnState && homePage.vpnState.connected
            ? Model.connectedColor()
            : homePage.foreground
          surfaceColor: Color.popups.background
          state: homePage.vpnState ? homePage.vpnState.statusIconState : "disconnected"
        }
      }
      trailingControl: Component {
        Row {
          id: statusRow
          readonly property bool connected: homePage.vpnState && homePage.vpnState.connected
          spacing: Style.space(8)

          BorderSurface {
            implicitWidth: detailText.implicitWidth + Style.space(10)
            implicitHeight: detailText.implicitHeight + Style.space(4)
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"
            borderSpec: statusRow.connected
              ? Border.flat(Model.connectedColor(), Style.normalBorderWidth)
              : Border.controlSpec("normal", hero.foreground, Color.accent)
            radius: Style.cornerRadius

            Text {
              id: detailText
              textFormat: Text.PlainText
              anchors.centerIn: parent
              text: statusRow.connected ? "On" : "Off"
              color: statusRow.connected
                ? Model.connectedColor()
                : Qt.darker(hero.foreground, 1.4)
              font.family: homePage.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }
          }

          PiaPowerSwitch {
            id: powerSwitch
            visible: homePage.vpnState && homePage.vpnState.installed && homePage.vpnState.loggedIn
            anchors.verticalCenter: parent.verticalCenter
            checked: homePage.vpnState ? homePage.vpnState.connected : false
            busy: homePage.vpnState ? homePage.vpnState.busy : false
            foreground: hero.foreground
            cursorRing: false
            onToggled: if (homePage.vpnState) homePage.vpnState.toggleConnection()
          }
        }
      }
    }
  }

  Column {
    width: parent.width
    spacing: Style.spacing.labelGap

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

  Row {
    visible: homePage.showTraffic
    width: parent.width
    spacing: Style.space(8)

    TrafficCard {
      width: (parent.width - parent.spacing) / 2
      label: "Down"
      value: homePage.trafficDown
      total: homePage.trafficDownTotal
      arrow: ""
      mode: "down"
      valueColor: Model.connectedColor()
      rxSamples: homePage.vpnState ? homePage.vpnState.trafficRxSamples : []
      lineColor: Model.connectedColor()
    }

    TrafficCard {
      width: (parent.width - parent.spacing) / 2
      label: "Up"
      value: homePage.trafficUp
      total: homePage.trafficUpTotal
      arrow: ""
      mode: "up"
      valueColor: homePage.foreground
      txSamples: homePage.vpnState ? homePage.vpnState.trafficTxSamples : []
      lineColor: homePage.dim
    }
  }

  PiaSparkline {
    visible: homePage.showTraffic
    width: parent.width
    height: Style.space(72)
    mode: "both"
    rxSamples: homePage.vpnState ? homePage.vpnState.trafficRxSamples : []
    txSamples: homePage.vpnState ? homePage.vpnState.trafficTxSamples : []
    rxColor: Model.connectedColor()
    txColor: homePage.dim
  }

  Button {
    width: parent.width
    text: "Choose location"
    foreground: homePage.foreground
    fontFamily: homePage.fontFamily
    bordered: true
    onClicked: homePage.locationsRequested()
  }

  component TrafficCard: BorderSurface {
    id: card
    property string label: ""
    property string value: ""
    property string total: ""
    property string arrow: ""
    property string mode: "both"
    property color valueColor: homePage.foreground
    property color lineColor: homePage.dim
    property var rxSamples: []
    property var txSamples: []

    implicitHeight: cardBody.implicitHeight + Style.spacing.controlPaddingY * 2
    color: "transparent"
    borderSpec: Border.controlSpec("normal", homePage.foreground, Color.accent)
    radius: Style.cornerRadius

    Item {
      id: cardBody
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.spacing.controlPaddingY
      anchors.leftMargin: Style.spacing.controlPaddingX
      anchors.rightMargin: Style.spacing.controlPaddingX
      implicitHeight: statsCol.implicitHeight

      Text {
        id: arrowMark
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: card.arrow
        color: card.valueColor
        font.family: homePage.fontFamily
        font.pixelSize: Style.font.title
      }

      Column {
        id: statsCol
        anchors.left: arrowMark.right
        anchors.leftMargin: Style.space(8)
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.spacing.labelGap

        Text {
          textFormat: Text.PlainText
          text: card.label
          color: homePage.dim
          font.family: homePage.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: card.value
          color: card.valueColor
          font.family: homePage.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: card.total
          color: homePage.dim
          font.family: homePage.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }

        PiaSparkline {
          width: parent.width
          height: Style.space(28)
          kind: "line"
          mode: card.mode
          rxSamples: card.rxSamples
          txSamples: card.txSamples
          rxColor: card.lineColor
          txColor: card.lineColor
        }
      }
    }
  }

  component InfoPair: Row {
    property string label: ""
    property string value: ""
    property color valueColor: homePage.foreground

    width: parent.width
    spacing: Style.space(8)

    Text {
      textFormat: Text.PlainText
      text: label
      color: homePage.dim
      font.family: homePage.fontFamily
      font.pixelSize: Style.font.bodySmall
    }

    Item {
      width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2)
      height: 1
    }

    Text {
      textFormat: Text.PlainText
      text: value
      color: valueColor
      font.family: homePage.fontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }
  }
}
