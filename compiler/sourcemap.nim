import os, strformat, strutils, tables, sets, ropes, json, strscans, std/options

type
  SourceInfo = object
    nodes: seq[Node]
    names, files: seq[string]

  Node* = object
    generated: int # Line in generated JS
    case inSource: bool # Whether the line in generated has nim equivilant
    of true:
      original: int # Line in original, we don't have column info
      file: int # Index into files list
      name: int # Index into names list (-1 for no name)
    else: discard

  SourceMap* = object
    version*:   int
    sources*:   seq[string]
    names*:     seq[string]
    mappings*:  string
    file*:      string

func addNode(info: var SourceInfo, generated: int) =
  ## Create node which doesn't appear in Nim code
  info.nodes &= Node(generated: generated, inSource: false)

func addNode*(info: var SourceInfo, generated, original: int, file: string, name = "") =
  ## Create a node which does appear in Nim code
  var node = Node(generated: generated, original: original, inSource: true)
  # Set file to file position. Add in if needed
  node.file = info.files.find(file)
  if node.file == -1:
    node.file = info.files.len
    info.files &= file
  # Do same for name if one is actually passed
  if name != "":
    node.name = info.names.find(name)
    if node.name == -1:
      node.name = info.names.len
      info.names &= name
  info.nodes &= node

# base64_VLQ
func encode*(values: seq[int]): string {.raises: [].} =
  ## Encodes a series of integers into a VLQ base64 encoded string
  # References:
  #   - https://www.lucidchart.com/techblog/2019/08/22/decode-encoding-base64-vlqs-source-maps/
  #   - https://github.com/rails/sprockets/blob/main/guides/source_maps.md#source-map-file
  const
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    shift = 5
    continueBit = 1 shl 5
    mask = continueBit - 1
  for val in values:
    # Sign is stored in first bit
    var newVal = abs(val) shl 1
    if val < 0:
      newVal = newVal or 1
    # Now comes the variable length part
    # This is how we are able to store large numbers
    while true:
      # We only encode 5 bits.
      var masked = newVal and mask
      newVal = newVal shr shift
      # If there is still something left
      # then signify with the continue bit that the
      # decoder should keep decoding
      if newVal > 0:
        masked = masked or continueBit
      result &= alphabet[masked]
      # If the value is zero then we have nothing left to encode
      if newVal == 0:
        break

type TokenState = enum Normal, String, Ident, Mangled

iterator tokenize*(line: string): (bool, string) =
  # result = @[]
  var state = Normal
  var token = ""
  var isMangled = false
  for z, ch in line:
    if ch.isAlphaAscii:
      if state == Normal:
        state = Ident
        if token.len > 0:
          yield (isMangled, token)
        token = $ch
        isMangled = false
      else:
        token.add(ch)
    elif ch == '_':
      if state == Ident:
        state = Mangled
        isMangled = true
      token.add($ch)
    elif ch != '"' and not ch.isAlphaNumeric:
      if state in {Ident, Mangled}:
        state = Normal
        if token.len > 0:
          yield (isMangled, token)
        token = $ch
        isMangled = false
      else:
        token.add($ch)
    elif ch == '"':
      if state != String:
        state = String
        if token.len > 0:
          yield (isMangled, token)
        token = $ch
        isMangled = false
      else:
        state = Normal
        token.add($ch)
        if token.len > 0:
          yield (isMangled, token)
        isMangled = false
        token = ""
    else:
      token.add($ch)
  if token.len > 0:
    yield (isMangled, token)

proc parse*(source, path: string): SourceInfo =
  let lines = source.splitLines()
  # The JS file has header information that we can't map
  var lastLocation: tuple[file: string, line: int] = ("", -1)
  # TODO: Tokenise so we get
  # Add each line as a node into the output
  for i, originalLine in lines:
    let line = originalLine.strip
    var
      lineNumber: int
      linePath: string
    if line.scanf("/* line $i \"$+\" */", lineNumber, linePath):
      # Lines are zero indexed
      lastLocation = (linePath, lineNumber - 1)
      result.addNode(i)
    elif lastLocation.line != -1:
      # TODO: Tokenisation
      result.addNode(i, lastLocation.line, lastLocation.file)
    else:
      result.addNode(i)

proc toSourceMap*(info: SourceInfo, file: string): SourceMap =
  ## Convert from high level SourceInfo into the required SourceMap object
  # Add basic info
  result.version = 3
  result.file = file
  result.sources = info.files
  result.names = info.names
  # Convert nodes into mappings.
  # Mappings are split into blocks where each block referes to a line in the outputted JS.
  # Blocks can be seperated into statements which refere to tokens on the line.
  # Since the mappings depend on previous values we need to
  # keep track of previous file, name, etc
  var
    prevFile = 0
    prevLine = 0
    prevName = 0

  for node in info.nodes:
    # We know need to encode the node info into a segment with following fields
    # All these fields are relative to their previous values
    # - 0: Column in generated code
    # - 1: Index of Nim file in source list
    # - 2: Line in Nim source
    # - 3: Column in Nim source
    # - 4: Index in names list
    if node.inSource:
      result.mappings &= encode(@[0, node.file - prevFile, node.original - prevLine, 0]) & ";"
      prevFile = node.file
      prevLine = node.original
    else:
      result.mappings &= ";"

proc genSourceMap*(source: string, outFile: string): (Rope, SourceMap) =
  let node = parse(source, outFile)
  let map = node.toSourceMap(outFile)
  ((&"{source}\n//# sourceMappingURL={outFile}.map").rope, map)

