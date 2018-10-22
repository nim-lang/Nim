import std/[
  os,
  osproc,
  strformat,
  nre,
  algorithm,
]

type LineMap = object
  offsets: seq[int]

proc initialize(lineMap: var LineMap, s: string) =
  lineMap.offsets.setLen 0
  for i in 0..<s.len:
    if s[i] == '\n':
      lineMap.offsets.add i

proc initLineMap(s: string): LineMap =
  initialize(result, s)

proc findLine(lineMap: LineMap, offset: int): int =
  result = upperBound(lineMap.offsets, offset)

proc testFindLine()=
  block:
    var lineMap: LineMap
    let s = "abc\ndef\n"
    lineMap.initialize(s)
    let lines = [0,0,0,1,1,1,1,2]
    for i in 0..<s.len:
      doAssert lineMap.findLine(i) == lines[i]

  block:
    let s = "\nabc\ndef"
    let lineMap = initLineMap(s)
    let lines = [1,1,1,1,2,2,2,2]
    for i in 0..<s.len:
      doAssert lineMap.findLine(i) == lines[i]

proc lintRstOK(path: string): bool=
  echo path
  let code = path.readFile
  let reg = re"(-{2,}\s+-{2,})"
  let m = code.find(reg)

  if m.isSome:
    let lineMap = initLineMap(code)
    let offset = m.get.captureBounds[0].get.a
    let line = lineMap.findLine(offset)
    const humanOffset = 1
    let msg = fmt"{path}:{line+humanOffset} potential table detected: {m.get.captures[0]}"
    echo msg
    return false
  return true

proc process(path: string, doLint = true, doPandoc = true)=
  let path2 = path.changeFileExt "md"
  if doLint:
    if not lintRstOK(path):
      return
  if doPandoc:
    let pandoc = "$HOME/Downloads/pandoc-2.3.1/bin/pandoc"
    let cmd = fmt"{pandoc} {path} -f rst -t markdown -o {path2} --columns=80 --atx-headers"
    let (output, exitCode) = osproc.execCmdEx(cmd)
    doAssert exitCode == 0
    echo output

proc convertRstToMdNim()=
  let pattern = "doc/*.rst"
  for path in walkPattern(pattern):
    process(path)

when isMainModule:
  convertRstToMdNim()
