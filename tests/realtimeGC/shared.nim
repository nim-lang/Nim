import strutils

# Global state, accessing with threads, no locks. Don't do this at
# home.
var gCounter: uint64
var gTxStatus: bool
var gRxStatus: bool
var gConnectStatus: bool
var gPttStatus: bool
var gComm1Status: bool
var gComm2Status: bool

proc getTxStatus(): string =
  result = if gTxStatus: "On" else: "Off"
  gTxStatus = not gTxStatus

proc getRxStatus(): string =
  result = if gRxStatus: "On" else: "Off"
  gRxStatus = not gRxStatus

proc getConnectStatus(): string =
  result = if gConnectStatus: "Yes" else: "No"
  gConnectStatus = not gConnectStatus

proc getPttStatus(): string =
  result = if gPttStatus: "PTT: On" else: "PTT: Off"
  gPttStatus = not gPttStatus

proc getComm1Status(): string =
  result = if gComm1Status: "On" else: "Off"
  gComm1Status = not gComm1Status

proc getComm2Status(): string =
  result = if gComm2Status: "On" else: "Off"
  gComm2Status = not gComm2Status

proc status() {.exportc: "status", dynlib.} =
  var tx_status = getTxStatus()
  var rx_status = getRxStatus()
  var connected = getConnectStatus()
  var ptt_status = getPttStatus()
  var str1: string = "[PilotEdge] Connected: $1  TX: $2  RX: $3" % [connected, tx_status, rx_status]
  var a = getComm1Status()
  var b = getComm2Status()
  var str2: string = "$1  COM1: $2  COM2: $3" % [ptt_status, a, b]
  # echo(str1)
  # echo(str2)

proc count() {.exportc: "count", dynlib.} =
  var temp: uint64
  for i in 0..100_000:
    temp += 1
  gCounter += 1
  # echo("gCounter: ", gCounter)

proc checkOccupiedMem() {.exportc: "checkOccupiedMem", dynlib.} =
  if getOccupiedMem() > 10_000_000:
    quit 1
  discard
