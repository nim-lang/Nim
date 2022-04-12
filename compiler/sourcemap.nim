import os, strformat, strutils, tables, sets, ropes, json, algorithm

type
  SourceNode* = ref object
    line*:      int
    column*:    int
    source*:    string
    name*:      string
    children*:  seq[Child]

  C = enum cSourceNode, cSourceString

  Child* = ref object
    case kind*: C:
    of cSourceNode:
      node*:  SourceNode
    of cSourceString:
      s*:     string

  SourceMap* = ref object
    version*:   int
    sources*:   seq[string]
    names*:     seq[string]
    mappings*:  string
    file*:      string
    # sourceRoot*: string
    # sourcesContent*: string

  SourceMapGenerator = ref object
    file:           string
    sourceRoot:     string
    skipValidation: bool
    sources:        seq[string]
    names:          seq[string]
    mappings:       seq[Mapping]

  Mapping* = ref object
    source*:        string
    original*:      tuple[line: int, column: int]
    generated*:     tuple[line: int, column: int]
    name*:          string
    noSource*:      bool
    noName*:        bool


proc child*(s: string): Child =
  Child(kind: cSourceString, s: s)


proc child*(node: SourceNode): Child =
  Child(kind: cSourceNode, node: node)


proc newSourceNode(line: int, column: int, path: string, node: SourceNode, name: string = ""): SourceNode =
  SourceNode(line: line, column: column, source: path, name: name, children: @[child(node)])


proc newSourceNode(line: int, column: int, path: string, s: string, name: string = ""): SourceNode =
  SourceNode(line: line, column: column, source: path, name: name, children: @[child(s)])


proc newSourceNode(line: int, column: int, path: string, children: seq[Child], name: string = ""): SourceNode =
  SourceNode(line: line, column: column, source: path, name: name, children: children)




# debugging


proc text*(sourceNode: SourceNode, depth: int): string =
  let empty = "  "
  result = &"{repeat(empty, depth)}SourceNode({sourceNode.source}:{sourceNode.line}:{sourceNode.column}):\n"
  for child in sourceNode.children:
    if child.kind == cSourceString:
      result.add(&"{repeat(empty, depth + 1)}{child.s}\n")
    else:
      result.add(child.node.text(depth + 1))


proc `$`*(sourceNode: SourceNode): string = text(sourceNode, 0)


# base64_VLQ


let integers = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="


proc encode*(i: int): string =
  result = ""
  var n = i
  if n < 0:
    n = (-n shl 1) or 1
  else:
    n = n shl 1

  var z = 0
  while z == 0 or n > 0:
    var e = n and 31
    n = n shr 5
    if n > 0:
      e = e or 32

    result.add(integers[e])
    z += 1


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

proc parse*(source: string, path: string): SourceNode =
  let lines = source.splitLines()
  var lastLocation: SourceNode = nil
  result = newSourceNode(0, 0, path, @[])
    
  # we just use one single parent and add all nim lines
  # as its children, I guess in typical codegen
  # that happens recursively on ast level
  # we also don't have column info, but I doubt more one nim lines can compile to one js
  # maybe in macros?

  for i, originalLine in lines:
    let line = originalLine.strip
    if line.len == 0:
      continue
      
    # this shouldn't be a problem:
    # jsgen doesn't generate comments
    # and if you emit // line you probably know what you're doing
    if line.startsWith("// line"):
      if result.children.len > 0:
        result.children[^1].node.children.add(child(line & "\n"))
      let pos = line.find(" ", 8)
      let lineNumber = line[8 .. pos - 1].parseInt
      let linePath = line[pos + 2 .. ^2] # quotes
      
      lastLocation = newSourceNode(
        lineNumber,
        0,
        linePath,
        @[])
      result.children.add(child(lastLocation))
    else:
      var last: SourceNode
      for token in line.tokenize():
        var name = ""
        if token[0]:
          name = token[1].split('_', 1)[0]
        
        
        if result.children.len > 0:
          result.children[^1].node.children.add(
            child(
              newSourceNode(
                result.children[^1].node.line,
                0,
                result.children[^1].node.source,
                token[1],
                name)))
          last = result.children[^1].node.children[^1].node
        else:
          result.children.add(
            child(
              newSourceNode(i + 1, 0, path, token[1], name)))
          last = result.children[^1].node
      let nl = "\n"
      if not last.isNil:
        last.source.add(nl)

proc cmp(a: Mapping, b: Mapping): int =
  var c = cmp(a.generated, b.generated)
  if c != 0:
    return c

  c = cmp(a.source, b.source)
  if c != 0:
    return c

  c = cmp(a.original, b.original)
  if c != 0:
    return c

  return cmp(a.name, b.name)


proc index*[T](elements: seq[T], element: T): int =
  for z in 0 ..< elements.len:
    if elements[z] == element:
      return z
  return -1


proc serializeMappings(map: SourceMapGenerator, mappings: seq[Mapping]): string =
  var previous = Mapping(generated: (line: 1, column: 0), original: (line: 0, column: 0), name: "", source: "")
  var previousSourceId = 0
  var previousNameId = 0
  var next = ""
  var nameId = 0
  var sourceId = 0
  result = ""

  for z, mapping in mappings:
    next = ""

    if mapping.generated.line != previous.generated.line:
      previous.generated.column = 0

      while mapping.generated.line != previous.generated.line:
        next.add(";")
        previous.generated.line += 1

    else:
      if z > 0:
        if cmp(mapping, mappings[z - 1]) == 0:
          continue
        next.add(",")

    next.add(encode(mapping.generated.column - previous.generated.column))
    previous.generated.column = mapping.generated.column

    if not mapping.noSource and mapping.source.len > 0:
      sourceId = map.sources.index(mapping.source)
      next.add(encode(sourceId - previousSourceId))
      previousSourceId = sourceId
      next.add(encode(mapping.original.line - 1 - previous.original.line))
      previous.original.line = mapping.original.line - 1
      next.add(encode(mapping.original.column - previous.original.column))
      previous.original.column = mapping.original.column

      if not mapping.noName and mapping.name.len > 0:
        nameId = map.names.index(mapping.name)
        next.add(encode(nameId - previousNameId))
        previousNameId = nameId

    result.add(next)


proc gen*(map: SourceMapGenerator): SourceMap =
  var mappings = map.mappings.sorted do (a: Mapping, b: Mapping) -> int:
    cmp(a, b)
  result = SourceMap(
    file: map.file,
    version: 3,
    sources: map.sources[0..^1],
    names: map.names[0..^1],
    mappings: map.serializeMappings(mappings))



proc addMapping*(map: SourceMapGenerator, mapping: Mapping) =
  if not mapping.noSource and mapping.source notin map.sources:
    map.sources.add(mapping.source)

  if not mapping.noName and mapping.name.len > 0 and mapping.name notin map.names:
    map.names.add(mapping.name)

  # echo "map ", mapping.source, " ", mapping.original, " ", mapping.generated, " ", mapping.name
  map.mappings.add(mapping)


proc walk*(node: SourceNode, fn: proc(line: string, original: SourceNode)) =
  for child in node.children:
    if child.kind == cSourceString and child.s.len > 0:
      fn(child.s, node)
    else:
      child.node.walk(fn)


proc toSourceMap*(node: SourceNode, file: string): SourceMapGenerator =
  var map = SourceMapGenerator(file: file, sources: @[], names: @[], mappings: @[])

  var generated = (line: 1, column: 0)
  var sourceMappingActive = false
  var lastOriginal = SourceNode(source: "", line: -1, column: 0, name: "", children: @[])

  node.walk do (line: string, original: SourceNode):
    if original.source.endsWith(".js"):
      # ignore it
      discard
    else:
      if original.line != -1:
        if lastOriginal.source != original.source or
           lastOriginal.line != original.line or
           lastOriginal.column != original.column or
           lastOriginal.name != original.name:
          map.addMapping(
            Mapping(
              source: original.source,
              original: (line: original.line, column: original.column),
              generated: (line: generated.line, column: generated.column),
              name: original.name))

        lastOriginal = SourceNode(
          source: original.source,
          line: original.line,
          column: original.column,
          name: original.name,
          children: lastOriginal.children)
        sourceMappingActive = true
      elif sourceMappingActive:
        map.addMapping(
          Mapping(
            noSource: true,
            noName: true,
            generated: (line: generated.line, column: generated.column),
            original: (line: -1, column: -1)))
        lastOriginal.line = -1
        sourceMappingActive = false

    for z in 0 ..< line.len:
      if line[z] in Newlines:
        generated.line += 1
        generated.column = 0

        if z == line.len - 1:
          lastOriginal.line = -1
          sourceMappingActive = false
        elif sourceMappingActive:
          map.addMapping(
            Mapping(
              source: original.source,
              original: (line: original.line, column: original.column),
              generated: (line: generated.line, column: generated.column),
              name: original.name))
      else:
        generated.column += 1
    
  map


proc genSourceMap*(source: string, outFile: string): (Rope, SourceMap) =
  let node = parse(source, outFile)
  let map = node.toSourceMap(file = outFile)
  ((&"{source}\n//# sourceMappingURL={outFile}.map").rope, map.gen)

