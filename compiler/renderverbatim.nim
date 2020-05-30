import strutils
from xmltree import addEscaped

import ast, options, msgs
import packages/docutils/highlite

# import compiler/renderer
import renderer

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
    # first.col = n[0].info.col + 1 # anything with `col > n[0].col` is part of runnableExamples

  let last = n.lastNodeRec.info
  var info = first
  var indent = info.col
  let numLines = numLines(conf, info.fileIndex).uint16
  var lastNonemptyPos = 0
  for line in first.line..numLines: # bugfix, see `testNimDocTrailingExample`
    info.line = line
    let src = sourceLine(conf, info)
    if line > last.line and not isInIndentationBlock(src, indent):
      break
    if line > first.line: result.add "\n"
    if src.len > indent:
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
