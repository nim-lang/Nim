discard """
  output: "ok"
  targets: "c"
  matrix: "--genBif:on"
"""

import std/[compilesettings, os]
import "../../dist/nimony/src/lib/nifcore"
from "../../dist/nimony/src/lib/bif" import load

type
  Axis = enum
    x
    y
    z

  GenericArgsShape = object
    argumentCount: int
    firstKind: NifKind
    firstSymbol: string
    secondKind: NifKind
    secondSymbol: string
    firstHasRange: bool
    lowerBound: int64
    upperBound: int64

proc tagIs(cursor: Cursor, name: string): bool =
  cursor.tags.tagName(cursorTagId(cursor)) == name

proc integerLiteral(node: Cursor): int64 =
  var cursor = node
  cursor.into:
    while cursor.hasMore:
      if cursor.kind == IntLit:
        result = intVal(cursor)
      skip cursor

proc rangeBounds(node: Cursor): tuple[found: bool, lower, upper: int64] =
  var cursor = node
  var values: seq[int64]
  cursor.into:
    while cursor.hasMore:
      if cursor.kind == TagLit and tagIs(cursor, "intlit"):
        values.add integerLiteral(cursor)
      skip cursor
  if values.len >= 2:
    result = (true, values[0], values[1])

proc typeDefRange(node: Cursor): tuple[found: bool, lower, upper: int64] =
  var cursor = node
  cursor.into:
    while cursor.hasMore:
      if cursor.kind == TagLit and tagIs(cursor, "range"):
        result = rangeBounds(cursor)
      skip cursor

proc typeDefSymbol(node: Cursor): string =
  var cursor = node
  cursor.into:
    while cursor.hasMore:
      if result.len == 0 and cursor.kind == SymbolDef:
        result = symName(cursor)
      skip cursor

proc genericArgsShape(node: Cursor): GenericArgsShape =
  var cursor = node
  cursor.into:
    while cursor.hasMore:
      if cursor.kind == TagLit and tagIs(cursor, "genericargs"):
        var arguments = cursor
        arguments.into:
          while arguments.hasMore:
            case arguments.kind
            of Symbol:
              if result.argumentCount == 0:
                result.firstKind = arguments.kind
                result.firstSymbol = symName(arguments)
              elif result.argumentCount == 1:
                result.secondKind = arguments.kind
                result.secondSymbol = symName(arguments)
              inc result.argumentCount
              skip arguments
            of TagLit:
              if tagIs(arguments, "td"):
                let bounds = typeDefRange(arguments)
                let typeSymbol = typeDefSymbol(arguments)
                if result.argumentCount == 0:
                  result.firstKind = arguments.kind
                  result.firstHasRange = bounds.found
                  result.lowerBound = bounds.lower
                  result.upperBound = bounds.upper
                elif result.argumentCount == 1:
                  result.secondKind = arguments.kind
                  result.secondSymbol = typeSymbol
                inc result.argumentCount
              skip arguments
            else:
              skip arguments
        skip cursor
      else:
        skip cursor

proc collectGenericArgs(cursor: var Cursor, shapes: var seq[GenericArgsShape]) =
  if cursor.kind == TagLit:
    if tagIs(cursor, "td"):
      let shape = genericArgsShape(cursor)
      if shape.argumentCount > 0:
        shapes.add shape
    cursor.into:
      while cursor.hasMore:
        collectGenericArgs(cursor, shapes)
  else:
    skip cursor

proc hasModuleSource(node: Cursor, filename: string): bool =
  var cursor = node
  if cursor.kind != TagLit:
    skip cursor
    return
  if tagIs(cursor, "modulesrc"):
    cursor.into:
      while cursor.hasMore:
        if cursor.kind == StrLit:
          result = strVal(cursor).extractFilename == filename
        skip cursor
    return
  cursor.into:
    while cursor.hasMore:
      let found = hasModuleSource(cursor, filename)
      skip cursor
      if found:
        result = true
      if result:
        while cursor.hasMore:
          skip cursor
        break

proc fixtureBif(cache: string): string =
  for candidate in walkFiles(cache / "*.s.bif"):
    var artifact = load(candidate)
    var cursor = beginRead(artifact.buf)
    while cursor.hasMore:
      if hasModuleSource(cursor, "tgenbif.nim"):
        return candidate
      skip cursor

proc genericArgsShapes(path: string): seq[GenericArgsShape] =
  var artifact = load(path)
  var cursor = beginRead(artifact.buf)
  while cursor.hasMore:
    collectGenericArgs(cursor, result)

proc bifGenericArguments(
    values: seq[int],
    fixed: array[4, int],
    shifted: array[2 .. 5, int],
    indexed: array[Axis, int],
) =
  discard values
  discard fixed
  discard shifted
  discard indexed

let cache = querySetting(nimcacheDir)
let path = fixtureBif(cache)
doAssert path.len > 0

let shapes = genericArgsShapes(path)
var elementSymbol: string
for shape in shapes:
  if shape.argumentCount == 2 and shape.firstHasRange and shape.lowerBound == 0 and
      shape.upperBound == 3:
    elementSymbol = shape.secondSymbol
doAssert elementSymbol.len > 0

var foundSeq, foundFixed, foundShifted, foundIndexed = false
for shape in shapes:
  if shape.argumentCount == 1 and shape.firstKind == Symbol and
      shape.firstSymbol == elementSymbol:
    foundSeq = true
  elif shape.argumentCount != 2 or shape.secondSymbol != elementSymbol:
    continue
  elif shape.firstHasRange and shape.lowerBound == 0 and shape.upperBound == 3:
    foundFixed = true
  elif shape.firstHasRange and shape.lowerBound == 2 and shape.upperBound == 5:
    foundShifted = true
  elif shape.firstKind == Symbol and shape.firstSymbol != elementSymbol:
    foundIndexed = true
doAssert foundSeq
doAssert foundFixed
doAssert foundShifted
doAssert foundIndexed
echo "ok"
