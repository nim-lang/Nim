#
#
#           The Nim Compiler
#        (c) Copyright 2026 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## A nimsuggest that never compiles. It takes the same arguments and speaks the
## same protocol (v4) over a socket (`--port`, `--autobind`), one command at a
## time; every command is answered by `nimsuggest2 --one-shot` (see `nsoneshot`),
## whose output it forwards. The NIFs are brought up to date at startup and on
## `changed`.

import std/[os, osproc, net, parseopt, strutils, streams]
import nsoneshot, procmonitor

proc forwardStderr(child: Stream) {.thread.} =
  var buf = newString(4096)
  while true:
    let n = child.readData(buf[0].addr, buf.len)
    if n <= 0: break
    stderr.write buf[0 ..< n]
  stderr.flushFile()

proc runOneShot(cmd: string; client: Socket) =
  var client = client
  var p: Process = nil
  var errors: Thread[Stream]
  try:
    p = startProcess(getAppFilename(),
      args = @["--one-shot"] & commandLineParams(), options = {})
    createThread(errors, forwardStderr, p.errorStream)
    p.inputStream.write(cmd & "\n")
    p.inputStream.close()
    let output = p.outputStream
    var buf = newString(4096)
    while true:
      let n = output.readData(buf[0].addr, buf.len)
      if n <= 0: break
      if client != nil:
        try:
          client.send(buf[0 ..< n])
        except OSError:
          client = nil
    joinThread(errors)
    let code = p.waitForExit()
    if code != 0:
      stderr.writeLine "nimsuggest2: `" & cmd & "` exited with code " & $code
  except OSError, IOError:
    stderr.writeLine "nimsuggest2: cannot run `" & cmd & "`: " & getCurrentExceptionMsg()
  finally:
    if p != nil:
      if p.running: p.kill()
      if errors.running: joinThread(errors)
      p.close()

proc serve(port: Port; address: string; autoBind: bool) =
  let server = newSocket()
  server.bindAddr(if autoBind: Port(0) else: port, address)
  server.listen()
  if autoBind:
    echo server.getLocalAddr()[1]
    stdout.flushFile()
  var line = ""
  while true:
    var client: Socket = nil
    try:
      server.accept(client)
      client.readLine(line)
      if line == "quit": break
      runOneShot(line, client)
      client.send("\c\L")
    except OSError, TimeoutError:
      stderr.writeLine "nimsuggest2: " & getCurrentExceptionMsg()
    finally:
      if client != nil: client.close()

proc main() =
  var port = Port(0)
  var address = "127.0.0.1"
  var autoBind = false
  var clientProcessId = 0
  for kind, key, val in getopt():
    if kind in {cmdLongOption, cmdShortOption}:
      case key.normalize
      of "one-shot", "info", "help", "h":
        oneShot()
      of "autobind": autoBind = true
      of "port": port = Port(parseInt(val))
      of "address": address = val
      of "clientprocessid": clientProcessId = parseInt(val)
      else: discard
  if not autoBind and port == Port(0):
    quit "nimsuggest2: only --port and --autobind are supported"
  if clientProcessId != 0:
    hookProcMonitor(clientProcessId)
  runOneShot("changed", nil)
  serve(port, address, autoBind)

main()
