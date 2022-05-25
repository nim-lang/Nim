import strutils

import ast, options, msgs

const isDebug = false
when isDebug:
  import renderer
  import astalgo

proc lastNodeRec(n: PNode): PNode =
  result = n
  while result.safeLen > 0: result = result[^1]

proc isInIndentationBlock(src: string, indent: int): bool =
  #[
  we stop at the first de-indentation; there's an inherent ambiguity with non
  doc comments since they can have arbitrary indentation, so we just take the
  practical route and require a runnableExamples to keep its code (including non
  doc comments) to its indentation level.
  ]#
  for j in 0..<indent:
    if src.len <= j: return true
    if src[j] != ' ': return false
  return true

type LineData = object
  ## keep track of which lines are starting inside a multiline doc comment.
  ## We purposefully avoid re-doing parsing which is already done (we get a PNode)
  ## so we don't worry about whether we're inside (nested) doc comments etc.
  ## But we sill need some logic to disambiguate different multiline styles.
  conf: ConfigRef
  lineFirst: int
  lines: seq[bool]
    ## lines[index] is true if line `lineFirst+index` starts inside a multiline string
    ## Using a HashSet (extra dependency) would simplify but not by much.

proc tripleStrLitStartsAtNextLine(conf: ConfigRef, n: PNode): bool =
  # enabling TLineInfo.offsetA,offsetB would probably make this easier
  const tripleQuote = "\"\"\""
  let src = sourceLine(conf, n.info)
  let col = n.info.col
  doAssert src.continuesWith(tripleQuote, col) # sanity check
  var i = col + 3
  var onlySpace = true
  while true:
    if src.len <= i:
      doAssert src.len == i
      return onlySpace
    elif src.continuesWith(tripleQuote, i) and (src.len == i+3 or src[i+3] != '\"'):
      return false # triple lit is in 1 line
    elif src[i] != ' ': onlySpace = false
    i.inc

proc visitMultilineStrings(ldata: var LineData, n: PNode) =
  var cline = ldata.lineFirst

  template setLine() =
    let index = cline - ldata.lineFirst
    if ldata.lines.len < index+1: ldata.lines.setLen index+1
    ldata.lines[index] = true

  case n.kind
  of nkTripleStrLit:
    # same logic should be applied for any multiline token
    # we could also consider nkCommentStmt but right now we just assume doc comments,
    # unlike triple string litterals, don't de-indent from runnableExamples.
    cline = n.info.line.int
    if tripleStrLitStartsAtNextLine(ldata.conf, n):
      cline.inc
      setLine()
    for ai in n.strVal:
      case ai
      of '\n':
        cline.inc
        setLine()
      else: discard
  else:
    for i in 0..<n.safeLen:
      visitMultilineStrings(ldata, n[i])

proc startOfLineInsideTriple(ldata: LineData, line: int): bool =
  let index = line - ldata.lineFirst
  if index >= ldata.lines.len: false
  else: ldata.lines[index]

proc extractRunnableExamplesSource*(conf: ConfigRef; n: PNode, indent = 0): string =
  ## TLineInfo.offsetA,offsetB would be cleaner but it's only enabled for nimpretty,
  ## we'd need to check performance impact to enable it for nimdoc.
  var first = n.lastSon.info
  if first.line == n[0].info.line:
    #[
    runnableExamples: assert true
    ]#
    discard
  else:
    #[
    runnableExamples:
      # non-doc comment that we want to capture even though `first` points to `assert true`
      assert true
    ]#
    first.line = n[0].info.line + 1

  let last = n.lastNodeRec.info
  var info = first
  var indent2 = info.col
  let numLines = numLines(conf, info.fileIndex).uint16
  var lastNonemptyPos = 0

  var ldata = LineData(lineFirst: first.line.int, conf: conf)
  visitMultilineStrings(ldata, n[^1])
  when isDebug:
    debug(n)
    for i in 0..<ldata.lines.len:
      echo (i+ldata.lineFirst, ldata.lines[i])

  result = ""
  for line in first.line..numLines: # bugfix, see `testNimDocTrailingExample`
    info.line = line
    let src = sourceLine(conf, info)
    let special = startOfLineInsideTriple(ldata, line.int)
    if line > last.line and not special and not isInIndentationBlock(src, indent2):
      break
    if line > first.line: result.add "\n"
    if special:
      result.add src
      lastNonemptyPos = result.len
    elif src.len > indent2:
      for i in 0..<indent: result.add ' '
      result.add src[indent2..^1]
      lastNonemptyPos = result.len
  result.setLen lastNonemptyPos

