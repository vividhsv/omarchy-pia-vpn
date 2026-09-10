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

function parseCoord(value) {
  var n = Number(value)
  return isFinite(n) ? n : NaN
}

function regionRecord(id, lat, lon) {
  var regionId = trim(id)
  var mapped = regionId !== "" && regionId !== "auto" && isFinite(lat) && isFinite(lon)
    && lat >= mapSouthLat() && lat <= 90 && lon >= -180 && lon <= 180
  return {
    id: regionId,
    label: regionLabel(regionId),
    auto: regionId === "auto",
    lat: mapped ? lat : NaN,
    lon: mapped ? lon : NaN,
    mappable: mapped
  }
}

function parseRegions(raw) {
  var regions = []
  var current = null
  function flush() {
    if (!current || current.id === "") {
      current = null
      return
    }
    regions.push(regionRecord(current.id, current.lat, current.lon))
    current = null
  }
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = trim(lines[i])
    if (line === "") {
      flush()
      continue
    }
    var eq = line.indexOf("=")
    if (eq < 1) {
      flush()
      regions.push(regionRecord(line, NaN, NaN))
      continue
    }
    var key = line.substring(0, eq)
    var value = line.substring(eq + 1)
    if (key === "id") {
      flush()
      current = { id: trim(value), lat: NaN, lon: NaN }
    } else if (current) {
      if (key === "lat") current.lat = parseCoord(value)
      else if (key === "lon") current.lon = parseCoord(value)
    }
  }
  flush()
  return regions
}

function regionAliasMap() {
  return {
    "albania": "al",
    "algeria": "dz",
    "andorra": "ad",
    "argentina": "ar",
    "armenia": "yerevan",
    "au-adelaide": "au-adelaide",
    "au-brisbane": "au-brisbane",
    "au-melbourne": "aus-melbourne",
    "au-perth": "aus-perth",
    "au-sydney": "aus",
    "australia-streaming-optimized": "au-australia",
    "bolivia": "bo-bolivia",
    "bosnia-and-herzegovina": "ba",
    "brazil": "br",
    "bulgaria": "sofia",
    "ca-montreal": "ca",
    "chile": "santiago",
    "colombia": "bogota",
    "costa-rica": "sanjose",
    "croatia": "zagreb",
    "czech-republic": "czech",
    "dk-streaming-optimized": "denmark",
    "ecuador": "ec-ecuador",
    "es-madrid": "spain",
    "estonia": "ee",
    "fi-helsinki": "fi",
    "greece": "gr",
    "guatemala": "gt-guatemala",
    "hong-kong": "hk",
    "iceland": "is",
    "india": "in",
    "indonesia": "jakarta",
    "isle-of-man": "man",
    "israel": "israel",
    "it-milano": "italy",
    "it-streaming-optimized": "italy",
    "jp-tokyo": "japan",
    "jp-streaming-optimized": "japan",
    "latvia": "lv",
    "lithuania": "lt",
    "luxembourg": "lu",
    "malaysia": "kualalumpur",
    "moldova": "md",
    "nepal": "np-nepal",
    "netherlands": "nl-amsterdam",
    "new-zealand": "nz",
    "north-macedonia": "mk",
    "norway": "no",
    "peru": "pe-peru",
    "portugal": "pt",
    "romania": "ro",
    "saudi-arabia": "saudiarabia",
    "se-stockholm": "sweden",
    "se-streaming-optimized": "sweden",
    "serbia": "rs",
    "singapore": "sg",
    "slovakia": "sk",
    "south-africa": "za",
    "south-korea": "kr-south-korea",
    "sri-lanka": "srilanka",
    "switzerland": "swiss",
    "turkey": "tr",
    "uk-london": "uk",
    "ukraine": "ua",
    "united-arab-emirates": "ae",
    "uruguay": "uy-uruguay",
    "us-east": "us-newjersey",
    "us-east-streaming-optimized": "us-streaming",
    "us-new-york": "us-new-york-city",
    "us-texas": "us-south-west",
    "us-west": "us-california",
    "us-west-streaming-optimized": "us-california"
  }
}

function normalizeGpsKey(value) {
  var text = String(value || "").toLowerCase().replace(/_/g, "-")
  text = text.replace(/[^a-z0-9-]+/g, "-").replace(/-+/g, "-")
  text = text.replace(/^-+/, "").replace(/-+$/, "")
  var suffixes = ["-streaming-optimized", "-streaming", "-pf", "-so"]
  var changed = true
  while (changed && text !== "") {
    changed = false
    for (var i = 0; i < suffixes.length; i++) {
      var suffix = suffixes[i]
      if (text.length > suffix.length && text.substring(text.length - suffix.length) === suffix) {
        text = text.substring(0, text.length - suffix.length).replace(/-+$/, "")
        changed = true
      }
    }
    if (text.length > 2 && text.substring(text.length - 2) === "-2") {
      text = text.substring(0, text.length - 2).replace(/-+$/, "")
      changed = true
    }
  }
  return text
}

function parseCoordPair(value) {
  if (!value) return null
  var lat
  var lon
  if (Array.isArray(value) && value.length >= 2) {
    lat = Number(value[0])
    lon = Number(value[1])
  } else if (typeof value === "object") {
    lat = Number(value.lat)
    lon = Number(value.lon)
  } else {
    return null
  }
  if (!isFinite(lat) || !isFinite(lon) || lat < -90 || lat > 90 || lon < -180 || lon > 180)
    return null
  return { lat: lat, lon: lon }
}

function gpsIndex(gps) {
  var index = {}
  if (!gps || typeof gps !== "object") return index
  var keys = Object.keys(gps)
  for (var i = 0; i < keys.length; i++) {
    var key = keys[i]
    var pair = parseCoordPair(gps[key])
    if (!pair) continue
    var original = String(key || "").toLowerCase().replace(/_/g, "-")
    original = original.replace(/[^a-z0-9-]+/g, "-").replace(/-+/g, "-")
    original = original.replace(/^-+/, "").replace(/-+$/, "")
    if (original !== "" && !index[original]) index[original] = pair
    var normalized = normalizeGpsKey(key)
    if (normalized !== "" && !index[normalized]) index[normalized] = pair
  }
  return index
}

function regionCandidates(regionId, aliases) {
  var aliasMap = aliases && typeof aliases === "object" ? aliases : regionAliasMap()
  var rid = trim(regionId)
  if (rid === "" || rid === "auto") return []
  var names = [rid]
  if (aliasMap[rid]) names.push(aliasMap[rid])
  var normalized = normalizeGpsKey(rid)
  if (normalized !== "" && names.indexOf(normalized) === -1) names.push(normalized)
  if (normalized && aliasMap[normalized]) names.push(aliasMap[normalized])
  if (rid.indexOf("us-") === 0 && rid.substring(rid.length - 5) !== "-city") {
    names.push(rid + "-city")
    names.push(normalizeGpsKey(rid + "-city"))
  }
  var seen = []
  for (var i = 0; i < names.length; i++) {
    var key = normalizeGpsKey(names[i])
    if (key !== "" && seen.indexOf(key) === -1) seen.push(key)
    var raw = String(names[i] || "").toLowerCase().replace(/_/g, "-")
    raw = raw.replace(/[^a-z0-9-]+/g, "-").replace(/-+/g, "-")
    raw = raw.replace(/^-+/, "").replace(/-+$/, "")
    if (raw !== "" && seen.indexOf(raw) === -1) seen.push(raw)
  }
  return seen
}

function regionCoords(id, gps, aliases) {
  if (trim(id) === "auto") return null
  var index = gpsIndex(gps)
  var keys = regionCandidates(id, aliases)
  for (var i = 0; i < keys.length; i++) {
    var pair = index[keys[i]]
    if (pair) return { lat: pair.lat, lon: pair.lon }
  }
  return null
}

function mapSouthLat() {
  return -60
}

function mapAspect() {
  return (90 - mapSouthLat()) / 360
}

function projectEquirectangular(lat, lon, width, height) {
  var latN = Number(lat)
  var lonN = Number(lon)
  var w = Number(width)
  var h = Number(height)
  var south = mapSouthLat()
  var span = 90 - south
  if (!isFinite(latN) || !isFinite(lonN) || !isFinite(w) || !isFinite(h) || w <= 0 || h <= 0)
    return null
  if (latN < south || latN > 90 || lonN < -180 || lonN > 180) return null
  return {
    x: (lonN + 180) / 360 * w,
    y: (90 - latN) / span * h
  }
}

function regionMappable(region) {
  return !!(region && region.mappable === true
    && isFinite(region.lat) && isFinite(region.lon))
}

function mappableRegions(regions) {
  var list = Array.isArray(regions) ? regions : []
  var result = []
  for (var i = 0; i < list.length; i++) {
    if (regionMappable(list[i])) result.push(list[i])
  }
  return result
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

function parseTraffic(raw) {
  var result = { ok: false, rx: 0, tx: 0 }
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i]
    var eq = line.indexOf("=")
    if (eq < 1) continue
    var key = line.substring(0, eq)
    var value = line.substring(eq + 1)
    if (key === "ok") result.ok = value === "true"
    else if (key === "rx") result.rx = Number(value)
    else if (key === "tx") result.tx = Number(value)
  }
  if (!isFinite(result.rx) || result.rx < 0) result.rx = 0
  if (!isFinite(result.tx) || result.tx < 0) result.tx = 0
  return result
}

function formatBytes(bytes) {
  var n = Number(bytes)
  if (!isFinite(n) || n < 0) n = 0
  if (n < 1024) return Math.round(n) + " B"
  if (n < 1024 * 1024) return (n / 1024).toFixed(1) + " KB"
  if (n < 1024 * 1024 * 1024) return (n / (1024 * 1024)).toFixed(1) + " MB"
  return (n / (1024 * 1024 * 1024)).toFixed(2) + " GB"
}

function formatRate(bytesPerSec) {
  return formatBytes(bytesPerSec) + "/s"
}

function trafficRates(prevRx, prevTx, prevAt, rx, tx, now) {
  var dt = Number(now) - Number(prevAt)
  if (!(prevAt > 0) || dt <= 0 || dt > 5 || rx < prevRx || tx < prevTx) {
    return { ready: false, rxRate: 0, txRate: 0, rxBytes: 0, txBytes: 0 }
  }
  var rxBytes = Math.max(0, rx - prevRx)
  var txBytes = Math.max(0, tx - prevTx)
  return {
    ready: true,
    rxRate: rxBytes / dt,
    txRate: txBytes / dt,
    rxBytes: rxBytes,
    txBytes: txBytes
  }
}

function appendSample(samples, value, limit) {
  var next = Array.isArray(samples) ? samples.slice() : []
  var n = Number(value)
  next.push(isFinite(n) && n > 0 ? n : 0)
  var cap = limit || 60
  while (next.length > cap) next.shift()
  return next
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
