## Code to handle communction with a repl via stdin or tcp.
## for emacs specific repl implimentation see emacs/emacs.nim
import compiler/renderer
import setup
import net, rdstdin
import communication
import consts

import compiler/[options, sigmatch, ast, lineinfos]

proc toStdout() {.gcsafe.} =
  while true:
    let res = results.recv()
    case res.section
    of ideNone: break
    of ideMsg: echo res.doc
    of ideKnown: echo res.quality == 1
    of ideProject: echo res.filePath
    else: echo res

proc toSocket(stdoutSocket: Socket) {.gcsafe.} =
  while true:
    let res = results.recv()
    case res.section
    of ideNone: break
    of ideMsg: stdoutSocket.send(res.doc & "\c\L")
    of ideKnown: stdoutSocket.send($(res.quality == 1) & "\c\L")
    of ideProject: stdoutSocket.send(res.filePath & "\c\L")
    else: stdoutSocket.send($res & "\c\L")



template setVerbosity(level: typed) =
  gVerbosity = level
  conf.notes = NotesVerbosity[gVerbosity]


proc replStdinSingleCmd(line: string) =
  requests.send line
  toStdout()
  echo ""
  flushFile(stdout)

proc replStdin*(x: ThreadParams) {.thread.} =
  if gEmitEof:
    echo DummyEof
    while true:
      let line = readLine(stdin)
      requests.send line
      if line == "quit": break
      toStdout()
      echo DummyEof
      flushFile(stdout)
  else:
    echo Help
    var line = ""
    while readLineFromStdin("> ", line):
      replStdinSingleCmd(line)
    requests.send "quit"

proc replCmdline*(x: ThreadParams) {.thread.} =
  replStdinSingleCmd(x.address)
  requests.send "quit"

proc replTcp*(x: ThreadParams) {.thread.} =
  var server = newSocket()
  if gAutoBind:
    let port = server.connectToNextFreePort(x.address)
    server.listen()
    echo port
    stdout.flushFile()
  else:
    server.bindAddr(x.port, x.address)
    server.listen()
  var inp = ""
  var stdoutSocket: Socket
  while true:
    accept(server, stdoutSocket)

    stdoutSocket.readLine(inp)
    requests.send inp
    toSocket(stdoutSocket)
    stdoutSocket.send("\c\L")
    stdoutSocket.close()