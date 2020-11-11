

import strutils, os, osproc, streams

const
  DummyEof = "!EOF!"

proc getPosition(s: string): (int, int) =
  result = (1, 1)
  var col = 0
  for i in 0..<s.len:
    if s[i] == '\L':
      inc result[0]
      col = 0
    else:
      inc col
  result[1] = col+1

proc callNimsuggest() =
  let cl = parseCmdLine("nimsuggest --tester temp000.nim")
  var p = startProcess(command=cl[0], args=cl[1 .. ^1],
                       options={poStdErrToStdOut, poUsePath,
                       poInteractive, poDaemon})
  let outp = p.outputStream
  let inp = p.inputStream
  var report = ""
  var a = newStringOfCap(120)
  let contents = readFile("tools/nimsuggest/crashtester.nim")
  try:
    # read and ignore anything nimsuggest says at startup:
    while outp.readLine(a):
      if a == DummyEof: break

    var line = 0
    for i in 0 ..< contents.len:
      let slic = contents[0..i]
      writeFile("temp000.nim", slic)
      let (line, col) = getPosition(slic)
      inp.writeLine("sug temp000.nim:$#:$#" % [$line, $col])
      inp.flush()
      var answer = ""
      while outp.readLine(a):
        if a == DummyEof: break
        answer.add a
        answer.add '\L'
      echo answer
  finally:
    inp.writeLine("quit")
    inp.flush()
    close(p)

callNimsuggest()
