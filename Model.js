.pragma library

function connectedColor() {
  return "#3d9a5f"
}

function trim(value) {
  return String(value || "").replace(/^\s+|\s+$/g, "")
}

function parseStatus(raw) {
  var result = {
    ok: true,
    installed: false,
    piactl: "",
    connectionState: "",
    region: "",
    vpnIp: "",
    pubIp: "",
    protocol: "",
    requestPortForward: null,
    allowLan: null,
    portForward: "",
    loggedIn: false,
    username: "",
    killswitch: ""
  }
  var text = String(raw || "")
  if (text === "") {
    result.ok = false
    return result
  }
  var lines = text.split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i]
    var eq = line.indexOf("=")
    if (eq < 1) continue
    var key = line.substring(0, eq)
    var value = line.substring(eq + 1)
    if (key === "installed") result.installed = value === "true"
    else if (key === "piactl") result.piactl = value
    else if (key === "connectionstate") result.connectionState = value
    else if (key === "region") result.region = value
    else if (key === "vpnip") result.vpnIp = value
    else if (key === "pubip") result.pubIp = value
    else if (key === "protocol") result.protocol = value
    else if (key === "requestportforward") {
      if (value === "true") result.requestPortForward = true
      else if (value === "false") result.requestPortForward = false
    }
    else if (key === "allowlan") {
      if (value === "true") result.allowLan = true
      else if (value === "false") result.allowLan = false
    }
    else if (key === "portforward") result.portForward = value
    else if (key === "loggedin") result.loggedIn = value === "true"
    else if (key === "username") result.username = value
    else if (key === "killswitch") result.killswitch = value
  }
  return result
}

function parseRegions(raw) {
  var regions = []
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var id = trim(lines[i])
    if (id === "") continue
    regions.push({
      id: id,
      label: regionLabel(id),
      auto: id === "auto"
    })
  }
  return regions
}

function regionLabel(id) {
  var value = trim(id)
  if (value === "") return "Unknown"
  if (value === "auto") return "Auto (fastest)"
  var parts = value.split("-")
  var words = []
  for (var i = 0; i < parts.length; i++) {
    var part = parts[i]
    if (part === "") continue
    words.push(part.charAt(0).toUpperCase() + part.slice(1))
  }
  return words.length > 0 ? words.join(" ") : value
}

function isConnected(state) {
  return String(state || "") === "Connected"
}

function isConnecting(state) {
  var value = String(state || "")
  return value === "Connecting" || value === "StillConnecting"
    || value === "Reconnecting" || value === "StillReconnecting"
    || value === "DisconnectingToReconnect"
}

function isDisconnecting(state) {
  return String(state || "") === "Disconnecting"
}

function isDisconnected(state) {
  var value = String(state || "")
  return value === "Disconnected" || value === "Interrupted"
}

function displayState(state) {
  var value = String(state || "")
  if (value === "Connected") return "Connected"
  if (value === "Connecting" || value === "StillConnecting") return "Connecting"
  if (value === "Reconnecting" || value === "StillReconnecting") return "Reconnecting"
  if (value === "DisconnectingToReconnect") return "Reconnecting"
  if (value === "Disconnecting") return "Disconnecting"
  if (value === "Interrupted") return "Interrupted"
  if (value === "Disconnected") return "Disconnected"
  return value || "Unknown"
}

function protocolLabel(value) {
  var protocol = String(value || "").toLowerCase()
  if (protocol === "wireguard") return "WireGuard"
  if (protocol === "openvpn") return "OpenVPN"
  return value || "Unknown"
}

function killswitchLabel(value) {
  var mode = String(value || "").toLowerCase()
  if (mode === "on") return "On"
  if (mode === "off") return "Off"
  if (mode === "auto") return "Auto"
  return value || "Unknown"
}

function nextKillswitch(value) {
  var mode = String(value || "off").toLowerCase()
  if (mode === "off") return "on"
  if (mode === "on") return "auto"
  return "off"
}

function portForwardLabel(value) {
  var text = trim(value)
  if (text === "") return "Unknown"
  if (/^\d+$/.test(text)) return text
  return text
}

function elide(text, max) {
  var value = String(text || "").replace(/\s+/g, " ").trim()
  var limit = max || 140
  return value.length > limit ? value.substring(0, limit - 1) + "…" : value
}

function filterRegions(regions, query) {
  var needle = trim(query).toLowerCase()
  var result = []
  for (var i = 0; i < regions.length; i++) {
    var region = regions[i]
    if (!needle) {
      result.push(region)
      continue
    }
    var hay = (String(region.id || "") + " " + String(region.label || "")).toLowerCase()
    if (hay.indexOf(needle) !== -1) result.push(region)
  }
  return result
}
