# Tester for nimsuggest.
# Every test file can have a #[!]# comment that is deleted from the input
# before 'nimsuggest' is invoked to ensure this token doesn't make a
# crucial difference for Nim's parser.

import os, osproc, strutils, streams, re

type
  Test = object
    cmd, dest: string
    startup: seq[string]
    script: seq[(string, string)]

const
  curDir = when defined(windows): "" else: ""
  DummyEof = "!EOF!"

template tpath(): untyped = getAppDir() / "tests"

proc parseTest(filename: string): Test =
  const cursorMarker = "#[!]#"
  let nimsug = curDir & addFileExt("nimsuggest", ExeExt)
  result.dest = getTempDir() / extractFilename(filename)
  result.cmd = nimsug & " --tester " & result.dest
  result.script = @[]
  result.startup = @[]
  var tmp = open(result.dest, fmWrite)
  var specSection = 0
  var markers = newSeq[string]()
  var i = 1
  for x in lines(filename):
    let marker = x.find(cursorMarker)+1
    if marker > 0:
      markers.add "\"" & filename & "\";\"" & result.dest & "\":" & $i & ":" & $marker
      tmp.writeLine x.replace(cursorMarker, "")
    else:
      tmp.writeLine x
    if x.contains("""""""""):
      inc specSection
    elif specSection == 1:
      if x.startsWith("$nimsuggest"):
        result.cmd = x % ["nimsuggest", nimsug, "file", filename]
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
        let x = x % ["file", filename]
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
  while true:
    setLen(a, 0)
    # eat all delimiting whitespace
    while c[i] in {' ', '\t', '\l', '\r'}: inc(i)
    case c[i]
    of '"': raise newException(ValueError, "double quotes not yet supported: " & c)
    of '\'':
      var delim = c[i]
      inc(i) # skip ' or "
      while c[i] != '\0' and c[i] != delim:
        add a, c[i]
        inc(i)
      if c[i] != '\0': inc(i)
    of '\0': break
    else:
      while c[i] > ' ':
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
    quit "unkown command: " & cmd

proc smartCompare(pattern, x: string): bool =
  if pattern.contains('*'):
    result = match(x, re(escapeRe(pattern).replace("\\x2A","(.*)"), {}))

proc runTest(filename: string): int =
  let s = parseTest filename
  for cmd in s.startup:
    if not runCmd(cmd, s.dest):
      quit "invalid command: " & cmd
  let cl = parseCmdLine(s.cmd)
  var p = startProcess(command=cl[0], args=cl[1 .. ^1],
                       options={poStdErrToStdOut, poUsePath,
                       poInteractive, poDemon})
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
        if resp != answer and not smartCompare(resp, answer):
          report.add "\nTest failed: " & filename
          report.add "\n  Expected:  " & resp
          report.add "\n  But got:   " & answer
  finally:
    inp.writeLine("quit")
    inp.flush()
    close(p)
  if report.len > 0:
    echo report
  result = report.len

proc main() =
  var failures = 0
  for x in walkFiles(getAppDir() / "tests/t*.nim"):
    echo "Test ", x
    failures += runTest(expandFilename(x))
  if failures > 0:
    quit 1

main()
