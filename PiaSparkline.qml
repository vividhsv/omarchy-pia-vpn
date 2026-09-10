import QtQuick
import qs.Commons

Item {
  id: root

  property var rxSamples: []
  property var txSamples: []
  property int sampleLimit: 60
  property color rxColor: "#3d9a5f"
  property color txColor: Color.foreground
  property string mode: "both"
  property string kind: "bars"

  implicitHeight: Style.space(56)

  function cssRgba(c, alpha) {
    var a = isFinite(alpha) ? alpha : 1
    return "rgba(" + Math.round(c.r * 255) + ", " + Math.round(c.g * 255) + ", "
      + Math.round(c.b * 255) + ", " + a + ")"
  }

  function peak(values) {
    var list = Array.isArray(values) ? values : []
    var max = 0
    for (var i = 0; i < list.length; i++) {
      var n = Number(list[i])
      if (isFinite(n) && n > max) max = n
    }
    return max
  }

  function columnValue(values, cols, col) {
    var list = Array.isArray(values) ? values : []
    var idx = list.length - cols + col
    if (idx < 0 || idx >= list.length) return 0
    var n = Number(list[idx])
    return isFinite(n) && n > 0 ? n : 0
  }

  function stackCount(value, maxVal, rows) {
    if (maxVal <= 0 || value <= 0) return 0
    return Math.max(0, Math.min(rows, Math.round((value / maxVal) * rows)))
  }

  function paintDot(ctx, cx, cy, radius) {
    ctx.beginPath()
    ctx.arc(cx, cy, radius, 0, Math.PI * 2)
    ctx.fill()
  }

  function paintLine(ctx, samples, maxVal, limit, stroke, fill) {
    var n = samples.length
    if (n < 2) return
    var padX = 1
    var padY = 2
    var innerW = Math.max(1, width - padX * 2)
    var innerH = Math.max(1, height - padY * 2)
    function xFor(i) {
      var slot = limit - n + i
      return padX + innerW * slot / Math.max(1, limit - 1)
    }
    function yFor(v) {
      var t = maxVal > 0 ? Math.max(0, Number(v) || 0) / maxVal : 0
      return padY + innerH * (1 - t)
    }
    ctx.beginPath()
    ctx.moveTo(xFor(0), yFor(samples[0]))
    for (var i = 1; i < n; i++) ctx.lineTo(xFor(i), yFor(samples[i]))
    ctx.lineTo(xFor(n - 1), padY + innerH)
    ctx.lineTo(xFor(0), padY + innerH)
    ctx.closePath()
    ctx.fillStyle = fill
    ctx.fill()
    ctx.beginPath()
    ctx.moveTo(xFor(0), yFor(samples[0]))
    for (var j = 1; j < n; j++) ctx.lineTo(xFor(j), yFor(samples[j]))
    ctx.strokeStyle = stroke
    ctx.lineWidth = 1.5
    ctx.lineJoin = "round"
    ctx.lineCap = "round"
    ctx.stroke()
  }

  Canvas {
    id: plot
    anchors.fill: parent
    antialiasing: true

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      if (width < 4 || height < 4) return

      var rx = Array.isArray(root.rxSamples) ? root.rxSamples : []
      var tx = Array.isArray(root.txSamples) ? root.txSamples : []
      var maxVal = Math.max(root.peak(rx), root.peak(tx), 1)
      var limit = Math.max(2, root.sampleLimit)

      if (root.kind === "line") {
        if (root.mode !== "down" && tx.length > 1)
          root.paintLine(ctx, tx, maxVal, limit, root.cssRgba(root.txColor, 1), root.cssRgba(root.txColor, 0.14))
        if (root.mode !== "up" && rx.length > 1)
          root.paintLine(ctx, rx, maxVal, limit, root.cssRgba(root.rxColor, 1), root.cssRgba(root.rxColor, 0.22))
        return
      }

      var both = root.mode === "both"
      var radius = 1.35
      var minPitch = 4
      var inset = radius + 0.5
      var availW = Math.max(minPitch, width - inset * 2)
      var cols = Math.max(1, Math.floor(availW / minPitch))
      var pitch = cols > 1 ? availW / (cols - 1) : availW
      var x0 = inset
      var mid = height / 2
      var availH = both ? Math.max(minPitch, mid - inset - pitch * 0.5) : Math.max(minPitch, height - inset * 2)
      var rows = Math.max(1, Math.floor(availH / minPitch))
      var yPitch = rows > 1 ? availH / (rows - 1) : availH

      function aboveY(r) {
        return both ? (mid - inset - r * yPitch) : (height - inset - r * yPitch)
      }
      function belowY(r) {
        return both ? (mid + inset + r * yPitch) : (inset + r * yPitch)
      }

      if (both) {
        ctx.fillStyle = root.cssRgba(root.txColor, 0.22)
        ctx.fillRect(inset - radius, mid - 0.5, availW + radius * 2, 1)
      }

      for (var g = 0; g < cols; g++) {
        var gx = x0 + g * pitch
        if (both || root.mode === "down") {
          ctx.fillStyle = root.cssRgba(root.rxColor, 0.16)
          for (var gr = 0; gr < rows; gr++) root.paintDot(ctx, gx, aboveY(gr), radius)
        }
        if (both || root.mode === "up") {
          ctx.fillStyle = root.cssRgba(root.txColor, 0.16)
          for (var gd = 0; gd < rows; gd++) root.paintDot(ctx, gx, belowY(gd), radius)
        }
      }

      for (var c = 0; c < cols; c++) {
        var x = x0 + c * pitch
        if (both || root.mode === "down") {
          var downN = root.stackCount(root.columnValue(rx, cols, c), maxVal, rows)
          ctx.fillStyle = root.cssRgba(root.rxColor, 1)
          for (var d = 0; d < downN; d++) root.paintDot(ctx, x, aboveY(d), radius)
        }
        if (both || root.mode === "up") {
          var upN = root.stackCount(root.columnValue(tx, cols, c), maxVal, rows)
          ctx.fillStyle = root.cssRgba(root.txColor, 1)
          for (var u = 0; u < upN; u++) root.paintDot(ctx, x, belowY(u), radius)
        }
      }
    }
  }

  onRxSamplesChanged: plot.requestPaint()
  onTxSamplesChanged: plot.requestPaint()
  onRxColorChanged: plot.requestPaint()
  onTxColorChanged: plot.requestPaint()
  onModeChanged: plot.requestPaint()
  onKindChanged: plot.requestPaint()
  onWidthChanged: plot.requestPaint()
  onHeightChanged: plot.requestPaint()
}
