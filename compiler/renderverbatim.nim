import strutils
from xmltree import addEscaped

import ast, options, msgs
import packages/docutils/highlite

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
  ## this avoids having to use a HashSet (but we could...)
  lineFirst: int
  conf: ConfigRef
  lines: seq[bool]

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

proc visitMultilineStrings(data: var LineData, n: PNode) =
  var cline = data.lineFirst

  template setLine() =
    let line2 = cline - data.lineFirst
    if data.lines.len <= line2:
      data.lines.setLen line2+1
      data.lines[line2] = true

  case n.kind
  of nkTripleStrLit:
    # same logic should be applied for any multiline token
    # we could also consider nkCommentStmt but right now we just assume doc comments,
    # unlike triple string litterals, don't de-indent from runnableExamples.
    cline = n.info.line.int
    if tripleStrLitStartsAtNextLine(data.conf, n):
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
      visitMultilineStrings(data, n[i])

proc startOfLineInsideTriple(data: LineData, line: int): bool =
  let line2 = line - data.lineFirst
  if line2 >= data.lines.len: false
  else: data.lines[line2]

proc extractRunnableExamplesSource*(conf: ConfigRef; n: PNode): string =
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
  var indent = info.col
  let numLines = numLines(conf, info.fileIndex).uint16
  var lastNonemptyPos = 0

  var data = LineData(lineFirst: first.line.int, conf: conf)
  visitMultilineStrings(data, n[^1])
  when isDebug:
    debug(n)
    for i in 0..<data.lines.len:
      echo (i+data.lineFirst, data.lines[i])

  for line in first.line..numLines: # bugfix, see `testNimDocTrailingExample`
    info.line = line
    let src = sourceLine(conf, info)
    let special = startOfLineInsideTriple(data, line.int)
    if line > last.line and not special and not isInIndentationBlock(src, indent):
      break
    if line > first.line: result.add "\n"
    if special:
      result.add src
      lastNonemptyPos = result.len
    elif src.len > indent:
      result.add src[indent..^1]
      lastNonemptyPos = result.len
  result.setLen lastNonemptyPos

proc renderNimCode*(result: var string, code: string, isLatex = false) =
  var toknizr: GeneralTokenizer
  initGeneralTokenizer(toknizr, code)
  var buf = ""
  template append(kind, val) =
    buf.setLen 0
    buf.addEscaped(val)
    let class = tokenClassToStr[kind]
    if isLatex:
      result.addf "\\span$1{$2}", [class, buf]
    else:
      result.addf  "<span class=\"$1\">$2</span>", [class, buf]
  while true:
    getNextToken(toknizr, langNim)
    case toknizr.kind
    of gtEof: break  # End Of File (or string)
    else:
      # TODO: avoid alloc; maybe toOpenArray
      append(toknizr.kind, substr(code, toknizr.start, toknizr.length + toknizr.start - 1))
