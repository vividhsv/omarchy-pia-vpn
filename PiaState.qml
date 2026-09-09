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

  readonly property int refreshIntervalSec: intSetting("refreshIntervalSec", 8, 3, 120)
  readonly property bool connected: _desired === -1 ? Model.isConnected(connectionState) : (_desired === 1)
  readonly property bool connecting: Model.isConnecting(connectionState) || (_desired === 1 && !Model.isConnected(connectionState))
  readonly property bool disconnecting: Model.isDisconnecting(connectionState) || (_desired === 0 && Model.isConnected(connectionState))
  readonly property string statusText: {
    if (!installed) return "Not installed"
    if (actionStatus !== "") return actionStatus
    if (!loggedIn) return "Signed out"
    if (_desired === 1 && !Model.isConnected(connectionState)) return "Connecting"
    if (_desired === 0 && Model.isConnected(connectionState)) return "Disconnecting"
    return Model.displayState(connectionState)
  }
  readonly property string statusIconState: {
    if (connected) return "connected"
    if (connecting || disconnecting) return "connecting"
    return "disconnected"
  }
  readonly property bool busy: statusProcess.running
    || actionProcess.running || loginProcess.running || regionsProcess.running
  readonly property bool killswitchKnown: killswitch !== ""
  readonly property string regionLabel: Model.regionLabel(region)
  readonly property string protocolLabel: Model.protocolLabel(protocol)

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
    if (statusProcess.running) return
    _statusOutput = ""
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
    connectionState = parsed.connectionState || "Unknown"
    region = parsed.region
    vpnIp = parsed.vpnIp === "Unknown" ? "" : parsed.vpnIp
    pubIp = parsed.pubIp === "Unknown" ? "" : parsed.pubIp
    protocol = parsed.protocol
    requestPortForward = parsed.requestPortForward === true
    allowLan = parsed.allowLan === true
    portForward = parsed.portForward
    loggedIn = parsed.loggedIn === true
      || Model.isConnected(parsed.connectionState)
      || Model.isConnecting(parsed.connectionState)
    username = parsed.username
    killswitch = parsed.killswitch
    if (_desired !== -1) {
      if (_desired === 1 && Model.isConnected(connectionState)) _desired = -1
      if (_desired === 0 && !Model.isConnected(connectionState) && !Model.isDisconnecting(connectionState))
        _desired = -1
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
    lastError = message || ""
  }

  function toggleConnection() {
    if (!installed || !loggedIn || busy) return
    if (connected || connecting) disconnectVpn()
    else connectVpn()
  }

  function connectVpn() {
    if (!installed || !loggedIn || actionProcess.running) return
    _desired = 1
    runAction([piactl(), "connect"], "Connecting…")
  }

  function disconnectVpn() {
    if (!installed || actionProcess.running) return
    _desired = 0
    runAction([piactl(), "disconnect"], "Disconnecting…")
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
    runAction([piactl(), "set", "requestportforward", enabled ? "true" : "false"],
              "Updating port forwarding…")
  }

  function setAllowLan(enabled) {
    if (!installed || actionProcess.running) return
    allowLan = enabled === true
    runAction([piactl(), "set", "allowlan", enabled ? "true" : "false"], "Updating LAN policy…")
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
    regionsProcess.command = [piactl(), "get", "regions"]
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
    _actionOutput = ""
    _actionError = ""
    actionStatus = label || ""
    actionProcess.command = command
    actionProcess.running = true
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
      var stdout = String(statusStdout.text || root._statusOutput || "")
      if (exitCode === 0) root.applyStatus(stdout)
      else {
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
}
