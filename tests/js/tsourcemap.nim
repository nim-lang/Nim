discard """
  action: "run"
  targets: "js"
  cmd: "nim js -r -d:nodejs $options --sourceMap:on $file"
"""
import std/[os, json, strutils, sequtils, algorithm, assertions, paths, compilesettings]

# Implements a very basic sourcemap parser and then runs it on itself.
# Allows to check for basic problems such as bad counts and lines missing (e.g. issue #21052)

type
  SourceMap = object
    version:   int
    sources:   seq[string]
    names:     seq[string]
    mappings:  string
    file:      string

  Line = object
    line, column: int
    file: string

const
  flag = 1 shl 5
  signBit = 0b1
  fourBits = 0b1111
  fiveBits = 0b11111
  mask = (1 shl 5) - 1
  alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

var b64Table: seq[int] = 0.repeat(max(alphabet.mapIt(it.ord)) + 1)
for i, b in alphabet.pairs:
  b64Table[b.ord] = i

# From https://github.com/juancarlospaco/nodejs/blob/main/src/nodejs/jsfs.nim
proc importFs*() {.importjs: "var fs = require(\"fs\");".}
proc readFileSync*(path: cstring): cstring {.importjs: "(fs.$1(#).toString())".}
importFS()
# Read in needed files
let
  jsFileName = string(querySetting(outDir).Path / "tsourcemap.js".Path)
  mapFileName = jsFileName & ".map"

  data = parseJson($mapFileName.cstring.readFileSync()).to(SourceMap)
  jsFile = $readFileSync(jsFileName.cstring)

proc decodeVLQ(inp: string): seq[int] =
  var
    shift, value: int
  for v in inp.mapIt(b64Table[it.ord]):
    value += (v and mask) shl shift
    if (v and flag) > 0:
      shift += 5
      continue
    result &= (value shr 1) * (if (value and 1) > 0: -1 else: 1)
    shift = 0
    value = 0


# Keep track of state
var
  line = 0
  source = 0
  name = 0
  column = 0
  jsLine = 1
  lines: seq[Line]

for gline in data.mappings.split(';'):
  jsLine += 1
  var jsColumn = 0
  for item in gline.strip().split(','):
    let value = item.decodeVLQ()
    doAssert value.len in [0, 1, 4, 5]
    if value.len == 0:
      continue
    jsColumn += value[0]
    if value.len >= 4:
      source += value[1]
      line += value[2]
      column += value[3]
      lines &= Line(line: line, column: column, file: data.sources[source])

let jsLines = jsFile.splitLines().len
# There needs to be a mapping for every line in the JS
# If there isn't then the JS lines wont match up with Nim lines.
# Except we don't care about the final line since that doesn't need to line up
doAssert data.mappings.count(';') == jsLines - 1

# Check we can find this file somewhere in the source map
var foundSelf = false
for line in lines:
  if "tsourcemap.nim" in line.file:
    foundSelf = true
    doAssert line.line in 0..<jsLines, "Lines is out of bounds for file"
doAssert foundSelf, "Couldn't find tsourcemap.nim in source map"
