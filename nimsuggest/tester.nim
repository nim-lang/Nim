# Tester for nimsuggest.
# Every test file can have a #[!]# comment that is deleted from the input
# before 'nimsuggest' is invoked to ensure this token doesn't make a
# crucial difference for Nim's parser.

import os, osproc, strutils, streams, re, sexp, net

type
  Test = object
    filename, cmd, dest: string
    startup: seq[string]
    script: seq[(string, string)]
    disabled: bool

const
  curDir = when defined(windows): "" else: ""
  DummyEof = "!EOF!"

template tpath(): untyped = getAppDir() / "tests"

import std/compilesettings

proc parseTest(filename: string; epcMode=false): Test =
  const cursorMarker = "#[!]#"
  let nimsug = curDir & addFileExt("nimsuggest", ExeExt)
  const libpath = querySetting(libPath)
  result.filename = filename
  result.dest = getTempDir() / extractFilename(filename)
  result.cmd = nimsug & " --tester " & result.dest
  result.script = @[]
  result.startup = @[]
  var tmp = open(result.dest, fmWrite)
  var specSection = 0
  var markers = newSeq[string]()
  var i = 1
  for x in lines(filename):
    let marker = x.find(cursorMarker)
    if marker >= 0:
      if epcMode:
        markers.add "(\"" & filename & "\" " & $i & " " & $marker & " \"" & result.dest & "\")"
      else:
        markers.add "\"" & filename & "\";\"" & result.dest & "\":" & $i & ":" & $marker
      tmp.writeLine x.replace(cursorMarker, "")
    else:
      tmp.writeLine x
    if x.contains("""""""""):
      inc specSection
    elif specSection == 1:
      if x.startsWith("disabled:"):
        if x.startsWith("disabled:true"):
          result.disabled = true
        else:
          # be strict about format
          doAssert x.startsWith("disabled:false")
          result.disabled = false
      elif x.startsWith("$nimsuggest"):
        result.cmd = x % ["nimsuggest", nimsug, "file", filename, "lib", libpath]
      elif x.startsWith("!"):
        if result.cmd.len == 0:
          result.startup.add x
        else:
          result.script.add((x, ""))
      elif x.startsWith(">"):
        # since 'markers' here are not complete yet, we do the $substitutions
        # afterwards
        result.script.add((x.substr(1).replaceWord("$path", tpath()), ""))
      elif x.len > 0:
        # expected output line:
        let x = x % ["file", filename, "lib", libpath]
        result.script[^1][1].add x.replace(";;", "\t") & '\L'
        # else: ignore empty lines for better readability of the specs
    inc i
  tmp.close()
  # now that we know the markers, substitute them:
  for a in mitems(result.script):
    a[0] = a[0] % markers

proc parseCmd(c: string): seq[string] =
  # we don't support double quotes for now so that
  # we can later support them properly with escapes and stuff.
  result = @[]
  var i = 0
  var a = ""
  while i < c.len:
    setLen(a, 0)
    # eat all delimiting whitespace
    while i < c.len and c[i] in {' ', '\t', '\l', '\r'}: inc(i)
    if i >= c.len: break
    case c[i]
    of '"': raise newException(ValueError, "double quotes not yet supported: " & c)
    of '\'':
      var delim = c[i]
      inc(i) # skip ' or "
      while i < c.len and c[i] != delim:
        add a, c[i]
        inc(i)
      if i < c.len: inc(i)
    else:
      while i < c.len and c[i] > ' ':
        add(a, c[i])
        inc(i)
    add(result, a)

proc edit(tmpfile: string; x: seq[string]) =
  if x.len != 3 and x.len != 4:
    quit "!edit takes two or three arguments"
  let f = if x.len >= 4: tpath() / x[3] else: tmpfile
  try:
    let content = readFile(f)
    let newcontent = content.replace(x[1], x[2])
    if content == newcontent:
      quit "wrong test case: edit had no effect"
    writeFile(f, newcontent)
  except IOError:
    quit "cannot edit file " & tmpfile

proc exec(x: seq[string]) =
  if x.len != 2: quit "!exec takes one argument"
  if execShellCmd(x[1]) != 0:
    quit "External program failed " & x[1]

proc copy(x: seq[string]) =
  if x.len != 3: quit "!copy takes two arguments"
  let rel = tpath()
  copyFile(rel / x[1], rel / x[2])

proc del(x: seq[string]) =
  if x.len != 2: quit "!del takes one argument"
  removeFile(tpath() / x[1])

proc runCmd(cmd, dest: string): bool =
  result = cmd[0] == '!'
  if not result: return
  let x = cmd.parseCmd()
  case x[0]
  of "!edit":
    edit(dest, x)
  of "!exec":
    exec(x)
  of "!copy":
    copy(x)
  of "!del":
    del(x)
  else:
    quit "unknown command: " & cmd

proc smartCompare(pattern, x: string): bool =
  if pattern.contains('*'):
    result = match(x, re(escapeRe(pattern).replace("\\x2A","(.*)"), {}))

proc sendEpcStr(socket: Socket; cmd: string) =
  let s = cmd.find(' ')
  doAssert s > 0
  var args = cmd.substr(s+1)
  if not args.startsWith("("): args = escapeJson(args)
  let c = "(call 567 " & cmd.substr(0, s) & args & ")"
  socket.send toHex(c.len, 6)
  socket.send c

proc recvEpc(socket: Socket): string =
  var L = newStringOfCap(6)
  if socket.recv(L, 6) != 6:
    raise newException(ValueError, "recv A failed #" & L & "#")
  let x = parseHexInt(L)
  result = newString(x)
  if socket.recv(result, x) != x:
    raise newException(ValueError, "recv B failed")

proc sexpToAnswer(s: SexpNode): string =
  result = ""
  doAssert s.kind == SList
  doAssert s.len >= 3
  let m = s[2]
  if m.kind != SList:
    echo s
  doAssert m.kind == SList
  for a in m:
    doAssert a.kind == SList
    #s.section,
    #s.symkind,
    #s.qualifiedPath.map(newSString),
    #s.filePath,
    #s.forth,
    #s.line,
    #s.column,
    #s.doc
    if a.len >= 9:
      let section = a[0].getStr
      let symk = a[1].getStr
      let qp = a[2]
      let file = a[3].getStr
      let typ = a[4].getStr
      let line = a[5].getNum
      let col = a[6].getNum
      let doc = a[7].getStr.escape
      result.add section
      result.add '\t'
      result.add symk
      result.add '\t'
      var i = 0
      if qp.kind == SList:
        for aa in qp:
          if i > 0: result.add '.'
          result.add aa.getStr
          inc i
      result.add '\t'
      result.add typ
      result.add '\t'
      result.add file
      result.add '\t'
      result.addInt line
      result.add '\t'
      result.addInt col
      result.add '\t'
      result.add doc
      result.add '\t'
      result.addInt a[8].getNum
      if a.len >= 10:
        result.add '\t'
        result.add a[9].getStr
    result.add '\L'

proc doReport(filename, answer, resp: string; report: var string) =
  if resp != answer and not smartCompare(resp, answer):
    report.add "\nTest failed: " & filename
    var hasDiff = false
    for i in 0..min(resp.len-1, answer.len-1):
      if resp[i] != answer[i]:
        report.add "\n  Expected:  " & resp.substr(i, i+200)
        report.add "\n  But got:   " & answer.substr(i, i+200)
        hasDiff = true
        break
    if not hasDiff:
      report.add "\n  Expected:  " & resp
      report.add "\n  But got:   " & answer

proc skipDisabledTest(test: Test): bool =
  if test.disabled:
    echo "disabled: " & test.filename
  result = test.disabled

proc runEpcTest(filename: string): int =
  let s = parseTest(filename, true)
  if s.skipDisabledTest: return 0
  for req, _ in items(s.script):
    if req.startsWith("highlight"):
      echo "disabled epc: " & s.filename
      return 0
  for cmd in s.startup:
    if not runCmd(cmd, s.dest):
      quit "invalid command: " & cmd
  let epccmd = s.cmd.replace("--tester", "--epc --v2 --log")
  let cl = parseCmdLine(epccmd)
  var p = startProcess(command=cl[0], args=cl[1 .. ^1],
                       options={poStdErrToStdOut, poUsePath,
                       poInteractive, poDaemon})
  let outp = p.outputStream
  let inp = p.inputStream
  var report = ""
  var socket = newSocket()
  try:
    # read the port number:
    when defined(posix):
      var a = newStringOfCap(120)
      discard outp.readLine(a)
    else:
      var i = 0
      while not osproc.hasData(p) and i < 100:
        os.sleep(50)
        inc i
      let a = outp.readAll().strip()
    let port = parseInt(a)
    socket.connect("localhost", Port(port))
    for req, resp in items(s.script):
      if not runCmd(req, s.dest):
        socket.sendEpcStr(req)
        let sx = parseSexp(socket.recvEpc())
        if not req.startsWith("mod "):
          let answer = sexpToAnswer(sx)
          doReport(filename, answer, resp, report)
  finally:
    socket.sendEpcStr "return arg"
    close(p)
  if report.len > 0:
    echo "==== EPC ========================================"
    echo report
  result = report.len

proc runTest(filename: string): int =
  let s = parseTest filename
  if s.skipDisabledTest: return 0
  for cmd in s.startup:
    if not runCmd(cmd, s.dest):
      quit "invalid command: " & cmd
  let cl = parseCmdLine(s.cmd)
  var p = startProcess(command=cl[0], args=cl[1 .. ^1],
                       options={poStdErrToStdOut, poUsePath,
                       poInteractive, poDaemon})
  let outp = p.outputStream
  let inp = p.inputStream
  var report = ""
  var a = newStringOfCap(120)
  try:
    # read and ignore anything nimsuggest says at startup:
    while outp.readLine(a):
      if a == DummyEof: break
    for req, resp in items(s.script):
      if not runCmd(req, s.dest):
        inp.writeLine(req)
        inp.flush()
        var answer = ""
        while outp.readLine(a):
          if a == DummyEof: break
          answer.add a
          answer.add '\L'
        doReport(filename, answer, resp, report)
  finally:
    inp.writeLine("quit")
    inp.flush()
    close(p)
  if report.len > 0:
    echo "==== STDIN ======================================"
    echo report
  result = report.len

proc main() =
  var failures = 0
  if os.paramCount() > 0:
    let x = os.paramStr(1)
    let xx = expandFilename x
    failures += runTest(xx)
    failures += runEpcTest(xx)
  else:
    for x in walkFiles(tpath() / "t*.nim"):
      echo "Test ", x
      let xx = expandFilename x
      when not defined(windows):
        # XXX Windows IO redirection seems bonkers:
        failures += runTest(xx)
      failures += runEpcTest(xx)
  if failures > 0:
    quit 1

main()
