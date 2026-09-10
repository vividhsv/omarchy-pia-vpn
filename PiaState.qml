import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "Model.js" as Model

Item {
  id: root

  property var settings: ({})

  property bool installed: false
  property string piactlPath: ""
  property bool loggedIn: false
  property string username: ""
  property string connectionState: "Unknown"
  property string region: ""
  property string vpnIp: ""
  property string pubIp: ""
  property string protocol: ""
  property bool requestPortForward: false
  property bool allowLan: false
  property string portForward: ""
  property string killswitch: ""
  property var regions: []
  property string lastError: ""
  property string actionStatus: ""
  property bool refreshing: false
  property int _desired: -1
  property bool _stableConnected: false
  property bool _statusValid: true

  readonly property int refreshIntervalSec: intSetting("refreshIntervalSec", 8, 3, 120)
  readonly property bool connected: _desired === -1 ? _stableConnected : (_desired === 1)
  readonly property bool connecting: _desired === 1 && !_stableConnected
  readonly property bool disconnecting: _desired === 0 && _stableConnected
  readonly property bool hasVpnIp: vpnIp !== ""
  readonly property string statusIconState: {
    if (hasVpnIp && _stableConnected && _desired !== 0)
      return "connected"
    if (connecting || disconnecting || Model.isConnecting(connectionState)
        || Model.isDisconnecting(connectionState)
        || (Model.isConnected(connectionState) && !hasVpnIp)
        || (_stableConnected && !hasVpnIp))
      return "connecting"
    return "disconnected"
  }
  readonly property string statusText: {
    if (!installed) return "Not installed"
    if (!loggedIn) return "Signed out"
    if (statusIconState === "connecting")
      return disconnecting || Model.isDisconnecting(connectionState) ? "Disconnecting" : "Connecting"
    return statusIconState === "connected" ? "Connected" : "Disconnected"
  }
  readonly property bool busy: actionProcess.running || loginProcess.running || regionsProcess.running
  readonly property bool killswitchKnown: killswitch !== ""
  readonly property string regionLabel: Model.regionLabel(region)
  readonly property string protocolLabel: Model.protocolLabel(protocol)
  readonly property bool wireguard: String(protocol).toLowerCase() === "wireguard"
  readonly property bool trafficActive: wireguard && hasVpnIp && trafficWatch

  property bool trafficWatch: false
  property bool trafficIfaceUp: false
  property bool trafficReady: false
  property real trafficRxRate: 0
  property real trafficTxRate: 0
  property real trafficRxTotal: 0
  property real trafficTxTotal: 0
  property var trafficRxSamples: []
  property var trafficTxSamples: []
  property real _prevRxBytes: -1
  property real _prevTxBytes: -1
  property real _prevTrafficAt: 0
  property string _trafficOutput: ""

  property string _statusOutput: ""
  property string _actionOutput: ""
  property string _actionError: ""
  property string _loginOutput: ""
  property string _loginError: ""
  property string _loginUser: ""
  property string _loginPass: ""
  property string _regionsOutput: ""
  property bool _connectAfterAction: false

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function intSetting(name, fallback, min, max) {
    var n = parseInt(String(setting(name, fallback)), 10)
    if (!isFinite(n)) n = fallback
    if (n < min) n = min
    if (n > max) n = max
    return n
  }

  function filePath(rel) {
    var url = Qt.resolvedUrl(rel).toString()
    if (url.indexOf("file://") === 0) url = url.slice(7)
    return url
  }

  function statusScript() {
    return filePath("scripts/pia-status.sh")
  }

  function trafficScript() {
    return filePath("scripts/pia-traffic.sh")
  }

  function regionsScript() {
    return filePath("scripts/pia-regions.sh")
  }

  function loginScript() {
    return filePath("scripts/piactl-login.sh")
  }

  function installScript() {
    return filePath("scripts/install-backend.sh")
  }

  function piactl() {
    return piactlPath || "piactl"
  }

  function refresh() {
    if (statusProcess.running || actionProcess.running || loginProcess.running) return
    _statusOutput = ""
    _statusValid = true
    refreshing = true
    statusProcess.command = ["python3", statusScript()]
    statusProcess.running = true
  }

  function applyStatus(raw) {
    var parsed = Model.parseStatus(raw)
    installed = parsed.installed === true
    if (!installed) {
      resetMissing("Not installed")
      return
    }
    piactlPath = parsed.piactl || piactlPath
    if (parsed.connectionState !== "") connectionState = parsed.connectionState
    vpnIp = parsed.vpnIp === "Unknown" ? "" : parsed.vpnIp
    if (Model.isConnected(connectionState) && vpnIp !== "") _stableConnected = true
    else if (Model.isDisconnected(connectionState)) _stableConnected = false
    region = parsed.region
    pubIp = parsed.pubIp === "Unknown" ? "" : parsed.pubIp
    if (parsed.protocol !== "") protocol = parsed.protocol
    if (parsed.requestPortForward === true || parsed.requestPortForward === false)
      requestPortForward = parsed.requestPortForward
    if (parsed.allowLan === true || parsed.allowLan === false)
      allowLan = parsed.allowLan
    if (parsed.portForward !== "") portForward = parsed.portForward
    loggedIn = parsed.loggedIn === true
      || Model.isConnected(parsed.connectionState)
      || Model.isConnecting(parsed.connectionState)
      || _stableConnected
    username = parsed.username
    killswitch = parsed.killswitch
    if (!loggedIn) _desired = -1
    else if (_desired !== -1) {
      if (_desired === 1 && _stableConnected) _desired = -1
      if (_desired === 0 && !_stableConnected) _desired = -1
    }
    lastError = ""
  }

  function resetMissing(message) {
    installed = false
    piactlPath = ""
    loggedIn = false
    username = ""
    connectionState = "Unknown"
    region = ""
    vpnIp = ""
    pubIp = ""
    protocol = ""
    requestPortForward = false
    allowLan = false
    portForward = ""
    killswitch = ""
    regions = []
    _desired = -1
    _stableConnected = false
    lastError = message || ""
    clearTraffic()
  }

  function toggleConnection() {
    if (!installed || !loggedIn || actionProcess.running) return
    if (connected) disconnectVpn()
    else connectVpn()
  }

  function connectVpn() {
    if (!installed || !loggedIn || actionProcess.running) {
      if (!actionProcess.running) {
        _desired = -1
        delayedRefresh.restart()
      }
      return
    }
    _desired = 1
    runAction([piactl(), "connect"])
  }

  function disconnectVpn() {
    if (!installed || actionProcess.running) return
    _desired = 0
    runAction([piactl(), "disconnect"])
  }

  function logout() {
    if (!installed || actionProcess.running) return
    _desired = -1
    runAction([piactl(), "logout"], "Signing out…")
  }

  function enableBackground() {
    if (!installed || actionProcess.running) return
    runAction([piactl(), "background", "enable"], "Enabling background mode…")
  }

  function setRegion(id) {
    var regionId = String(id || "")
    if (!installed || regionId === "" || actionProcess.running) return
    region = regionId
    runAction([piactl(), "set", "region", regionId], "Setting region…")
  }

  function connectRegion(id) {
    var regionId = String(id || "")
    if (!installed || !loggedIn || regionId === "" || actionProcess.running) return
    region = regionId
    _desired = 1
    _connectAfterAction = true
    runAction([piactl(), "set", "region", regionId], "Connecting…")
  }

  function setProtocol(value) {
    var protocolId = String(value || "")
    if (!installed || (protocolId !== "wireguard" && protocolId !== "openvpn") || actionProcess.running)
      return
    protocol = protocolId
    runAction([piactl(), "set", "protocol", protocolId], "Setting protocol…")
  }

  function setRequestPortForward(enabled) {
    if (!installed || actionProcess.running) return
    requestPortForward = enabled === true
    runAction([piactl(), "set", "requestportforward", enabled ? "true" : "false"])
  }

  function setAllowLan(enabled) {
    if (!installed || actionProcess.running) return
    allowLan = enabled === true
    runAction([piactl(), "set", "allowlan", enabled ? "true" : "false"])
  }

  function cycleKillswitch() {
    if (!installed || !killswitchKnown || actionProcess.running) return
    var next = Model.nextKillswitch(killswitch)
    killswitch = next
    runAction([piactl(), "-u", "applysettings", '{"killswitch":"' + next + '"}'],
              "Updating kill switch…")
  }

  function refreshRegions() {
    if (!installed || regionsProcess.running) return
    _regionsOutput = ""
    regionsProcess.command = ["python3", regionsScript(), piactl()]
    regionsProcess.running = true
  }

  function login(user, pass) {
    if (!installed || loginProcess.running) return
    var name = String(user || "").trim()
    var secret = String(pass || "")
    if (name === "" || secret === "") {
      lastError = "Enter your PIA username and password"
      return
    }
    _loginOutput = ""
    _loginError = ""
    _loginUser = name
    _loginPass = secret
    actionStatus = "Signing in…"
    loginProcess.command = ["bash", loginScript(), piactl()]
    loginProcess.running = true
  }

  function installBackend() {
    Quickshell.execDetached([
      "omarchy-launch-floating-terminal-with-presentation",
      "bash",
      installScript()
    ])
    actionStatus = "Installer opened in a terminal"
    actionStatusTimer.restart()
  }

  function runAction(command, label) {
    if (actionProcess.running) return
    if (statusProcess.running) {
      _statusValid = false
      statusProcess.running = false
      refreshing = false
    }
    _actionOutput = ""
    _actionError = ""
    actionStatus = label || ""
    actionProcess.command = command
    actionProcess.running = true
  }

  function setTrafficWatch(enabled) {
    trafficWatch = enabled === true
  }

  function clearTraffic(keepSession) {
    if (trafficProcess.running) trafficProcess.running = false
    trafficIfaceUp = false
    trafficReady = false
    trafficRxRate = 0
    trafficTxRate = 0
    trafficRxSamples = []
    trafficTxSamples = []
    _prevRxBytes = -1
    _prevTxBytes = -1
    _prevTrafficAt = 0
    _trafficOutput = ""
    if (keepSession !== true) {
      trafficRxTotal = 0
      trafficTxTotal = 0
    }
  }

  function refreshTraffic() {
    if (!trafficActive || trafficProcess.running) return
    _trafficOutput = ""
    trafficProcess.command = ["python3", trafficScript()]
    trafficProcess.running = true
  }

  function applyTraffic(raw) {
    var parsed = Model.parseTraffic(raw)
    if (!parsed.ok) {
      trafficIfaceUp = false
      trafficReady = false
      trafficRxRate = 0
      trafficTxRate = 0
      trafficRxSamples = []
      trafficTxSamples = []
      _prevRxBytes = -1
      _prevTxBytes = -1
      _prevTrafficAt = 0
      return
    }
    trafficIfaceUp = true
    var now = Date.now() / 1000
    var next = Model.trafficRates(_prevRxBytes, _prevTxBytes, _prevTrafficAt, parsed.rx, parsed.tx, now)
    _prevRxBytes = parsed.rx
    _prevTxBytes = parsed.tx
    _prevTrafficAt = now
    if (!next.ready) return
    trafficReady = true
    trafficRxRate = next.rxRate
    trafficTxRate = next.txRate
    trafficRxTotal += next.rxBytes
    trafficTxTotal += next.txBytes
    trafficRxSamples = Model.appendSample(trafficRxSamples, next.rxRate, 60)
    trafficTxSamples = Model.appendSample(trafficTxSamples, next.txRate, 60)
  }

  Timer {
    id: refreshTimer
    interval: root.refreshIntervalSec * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: delayedRefresh
    interval: 700
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    id: trafficTimer
    interval: 1000
    repeat: true
    running: root.trafficActive
    triggeredOnStart: true
    onTriggered: root.refreshTraffic()
  }

  onTrafficActiveChanged: if (!trafficActive) clearTraffic(wireguard && hasVpnIp)

  Timer {
    id: actionStatusTimer
    interval: 2400
    repeat: false
    onTriggered: root.actionStatus = ""
  }

  Timer {
    id: pollWatchdog
    interval: 20000
    repeat: false
    onTriggered: {
      if (statusProcess.running) statusProcess.running = false
      if (regionsProcess.running) regionsProcess.running = false
    }
  }

  Process {
    id: statusProcess
    running: false
    command: []
    stdout: StdioCollector {
      id: statusStdout
      waitForEnd: true
      onStreamFinished: root._statusOutput = text
    }
    stderr: StdioCollector { waitForEnd: true }
    onStarted: pollWatchdog.restart()
    onExited: function(exitCode) {
      root.refreshing = false
      if (!root._statusValid) return
      var stdout = String(statusStdout.text || root._statusOutput || "")
      if (exitCode === 0) root.applyStatus(stdout)
      else if (!root.installed) {
        root.resetMissing("Could not read piactl status")
        root.lastError = Model.elide(stdout || "piactl status failed")
      }
    }
  }

  Process {
    id: regionsProcess
    running: false
    command: []
    stdout: StdioCollector {
      id: regionsStdout
      waitForEnd: true
      onStreamFinished: root._regionsOutput = text
    }
    stderr: StdioCollector { waitForEnd: true }
    onExited: function(exitCode) {
      var stdout = String(regionsStdout.text || root._regionsOutput || "")
      if (exitCode === 0) root.regions = Model.parseRegions(stdout)
    }
  }

  Process {
    id: actionProcess
    running: false
    command: []
    stdout: StdioCollector {
      id: actionStdout
      waitForEnd: true
      onStreamFinished: root._actionOutput = text
    }
    stderr: StdioCollector {
      id: actionStderr
      waitForEnd: true
      onStreamFinished: root._actionError = text
    }
    onExited: function(exitCode) {
      var stdout = String(actionStdout.text || root._actionOutput || "")
      var stderr = String(actionStderr.text || root._actionError || "")
      if (exitCode !== 0) {
        root._desired = -1
        root._connectAfterAction = false
        root.lastError = Model.elide(stderr || stdout || "PIA command failed")
        root.actionStatus = root.lastError
        actionStatusTimer.restart()
        delayedRefresh.restart()
        return
      }
      root.lastError = ""
      root.actionStatus = ""
      if (root._connectAfterAction) {
        root._connectAfterAction = false
        Qt.callLater(function() { root.connectVpn() })
        return
      }
      delayedRefresh.restart()
    }
  }

  Process {
    id: loginProcess
    running: false
    command: []
    stdinEnabled: true
    stdout: StdioCollector {
      id: loginStdout
      waitForEnd: true
      onStreamFinished: root._loginOutput = text
    }
    stderr: StdioCollector {
      id: loginStderr
      waitForEnd: true
      onStreamFinished: root._loginError = text
    }
    onStarted: {
      write(root._loginUser + "\n" + root._loginPass + "\n")
      root._loginUser = ""
      root._loginPass = ""
    }
    onExited: function(exitCode) {
      root._loginUser = ""
      root._loginPass = ""
      var stdout = String(loginStdout.text || root._loginOutput || "")
      var stderr = String(loginStderr.text || root._loginError || "")
      if (exitCode !== 0) {
        root.lastError = Model.elide(stderr || stdout || "Sign in failed")
        root.actionStatus = root.lastError
        actionStatusTimer.restart()
        delayedRefresh.restart()
      } else {
        root.loggedIn = true
        root.lastError = ""
        root.actionStatus = ""
        Qt.callLater(function() { root.enableBackground() })
      }
    }
  }

  Process {
    id: trafficProcess
    running: false
    command: []
    stdout: StdioCollector {
      id: trafficStdout
      waitForEnd: true
      onStreamFinished: root._trafficOutput = text
    }
    stderr: StdioCollector { waitForEnd: true }
    onExited: function(exitCode) {
      if (!root.trafficActive) return
      var stdout = String(trafficStdout.text || root._trafficOutput || "")
      if (exitCode === 0) root.applyTraffic(stdout)
    }
  }
}
