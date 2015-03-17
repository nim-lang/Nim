#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple high performance `JSON`:idx:
## parser. JSON (JavaScript Object Notation) is a lightweight
## data-interchange format that is easy for humans to read and write
## (unlike XML). It is easy for machines to parse and generate.
## JSON is based on a subset of the JavaScript Programming Language,
## Standard ECMA-262 3rd Edition - December 1999.
##
## Usage example:
##
## .. code-block:: nim
##  let
##    small_json = """{"test": 1.3, "key2": true}"""
##    jobj = parseJson(small_json)
##  assert (jobj.kind == JObject)
##  echo($jobj["test"].fnum)
##  echo($jobj["key2"].bval)
##
## Results in:
##
## .. code-block:: nim
##
##   1.3000000000000000e+00
##   true
##
## This module can also be used to comfortably create JSON using the `%*`
## operator:
##
## .. code-block:: nim
##
##   var hisName = "John"
##   let herAge = 31
##   var j = %*
##     [
##       {
##         "name": hisName,
##         "age": 30
##       },
##       {
##         "name": "Susan",
##         "age": herAge
##       }
##     ]

import
  hashes, strutils, lexbase, streams, unicode, macros

type
  JsonEventKind* = enum  ## enumeration of all events that may occur when parsing
    jsonError,           ## an error occurred during parsing
    jsonEof,             ## end of file reached
    jsonString,          ## a string literal
    jsonInt,             ## an integer literal
    jsonFloat,           ## a float literal
    jsonTrue,            ## the value ``true``
    jsonFalse,           ## the value ``false``
    jsonNull,            ## the value ``null``
    jsonObjectStart,     ## start of an object: the ``{`` token
    jsonObjectEnd,       ## end of an object: the ``}`` token
    jsonArrayStart,      ## start of an array: the ``[`` token
    jsonArrayEnd         ## start of an array: the ``]`` token

  TTokKind = enum        # must be synchronized with TJsonEventKind!
    tkError,
    tkEof,
    tkString,
    tkInt,
    tkFloat,
    tkTrue,
    tkFalse,
    tkNull,
    tkCurlyLe,
    tkCurlyRi,
    tkBracketLe,
    tkBracketRi,
    tkColon,
    tkComma

  JsonError* = enum        ## enumeration that lists all errors that can occur
    errNone,               ## no error
    errInvalidToken,       ## invalid token
    errStringExpected,     ## string expected
    errColonExpected,      ## ``:`` expected
    errCommaExpected,      ## ``,`` expected
    errBracketRiExpected,  ## ``]`` expected
    errCurlyRiExpected,    ## ``}`` expected
    errQuoteExpected,      ## ``"`` or ``'`` expected
    errEOC_Expected,       ## ``*/`` expected
    errEofExpected,        ## EOF expected
    errExprExpected        ## expr expected

  ParserState = enum
    stateEof, stateStart, stateObject, stateArray, stateExpectArrayComma,
    stateExpectObjectComma, stateExpectColon, stateExpectValue

  JsonParser* = object of BaseLexer ## the parser object.
    a: string
    tok: TTokKind
    kind: JsonEventKind
    err: JsonError
    state: seq[ParserState]
    filename: string

{.deprecated: [TJsonEventKind: JsonEventKind, TJsonError: JsonError,
  TJsonParser: JsonParser].}

const
  errorMessages: array [JsonError, string] = [
    "no error",
    "invalid token",
    "string expected",
    "':' expected",
    "',' expected",
    "']' expected",
    "'}' expected",
    "'\"' or \"'\" expected",
    "'*/' expected",
    "EOF expected",
    "expression expected"
  ]
  tokToStr: array [TTokKind, string] = [
    "invalid token",
    "EOF",
    "string literal",
    "int literal",
    "float literal",
    "true",
    "false",
    "null",
    "{", "}", "[", "]", ":", ","
  ]

proc open*(my: var JsonParser, input: Stream, filename: string) =
  ## initializes the parser with an input stream. `Filename` is only used
  ## for nice error messages.
  lexbase.open(my, input)
  my.filename = filename
  my.state = @[stateStart]
  my.kind = jsonError
  my.a = ""

proc close*(my: var JsonParser) {.inline.} =
  ## closes the parser `my` and its associated input stream.
  lexbase.close(my)

proc str*(my: JsonParser): string {.inline.} =
  ## returns the character data for the events: ``jsonInt``, ``jsonFloat``,
  ## ``jsonString``
  assert(my.kind in {jsonInt, jsonFloat, jsonString})
  return my.a

proc getInt*(my: JsonParser): BiggestInt {.inline.} =
  ## returns the number for the event: ``jsonInt``
  assert(my.kind == jsonInt)
  return parseBiggestInt(my.a)

proc getFloat*(my: JsonParser): float {.inline.} =
  ## returns the number for the event: ``jsonFloat``
  assert(my.kind == jsonFloat)
  return parseFloat(my.a)

proc kind*(my: JsonParser): JsonEventKind {.inline.} =
  ## returns the current event type for the JSON parser
  return my.kind

proc getColumn*(my: JsonParser): int {.inline.} =
  ## get the current column the parser has arrived at.
  result = getColNumber(my, my.bufpos)

proc getLine*(my: JsonParser): int {.inline.} =
  ## get the current line the parser has arrived at.
  result = my.lineNumber

proc getFilename*(my: JsonParser): string {.inline.} =
  ## get the filename of the file that the parser processes.
  result = my.filename

proc errorMsg*(my: JsonParser): string =
  ## returns a helpful error message for the event ``jsonError``
  assert(my.kind == jsonError)
  result = "$1($2, $3) Error: $4" % [
    my.filename, $getLine(my), $getColumn(my), errorMessages[my.err]]

proc errorMsgExpected*(my: JsonParser, e: string): string =
  ## returns an error message "`e` expected" in the same format as the
  ## other error messages
  result = "$1($2, $3) Error: $4" % [
    my.filename, $getLine(my), $getColumn(my), e & " expected"]

proc handleHexChar(c: char, x: var int): bool =
  result = true # Success
  case c
  of '0'..'9': x = (x shl 4) or (ord(c) - ord('0'))
  of 'a'..'f': x = (x shl 4) or (ord(c) - ord('a') + 10)
  of 'A'..'F': x = (x shl 4) or (ord(c) - ord('A') + 10)
  else: result = false # error

proc parseString(my: var JsonParser): TTokKind =
  result = tkString
  var pos = my.bufpos + 1
  var buf = my.buf
  while true:
    case buf[pos]
    of '\0':
      my.err = errQuoteExpected
      result = tkError
      break
    of '"':
      inc(pos)
      break
    of '\\':
      case buf[pos+1]
      of '\\', '"', '\'', '/':
        add(my.a, buf[pos+1])
        inc(pos, 2)
      of 'b':
        add(my.a, '\b')
        inc(pos, 2)
      of 'f':
        add(my.a, '\f')
        inc(pos, 2)
      of 'n':
        add(my.a, '\L')
        inc(pos, 2)
      of 'r':
        add(my.a, '\C')
        inc(pos, 2)
      of 't':
        add(my.a, '\t')
        inc(pos, 2)
      of 'u':
        inc(pos, 2)
        var r: int
        if handleHexChar(buf[pos], r): inc(pos)
        if handleHexChar(buf[pos], r): inc(pos)
        if handleHexChar(buf[pos], r): inc(pos)
        if handleHexChar(buf[pos], r): inc(pos)
        add(my.a, toUTF8(Rune(r)))
      else:
        # don't bother with the error
        add(my.a, buf[pos])
        inc(pos)
    of '\c':
      pos = lexbase.handleCR(my, pos)
      buf = my.buf
      add(my.a, '\c')
    of '\L':
      pos = lexbase.handleLF(my, pos)
      buf = my.buf
      add(my.a, '\L')
    else:
      add(my.a, buf[pos])
      inc(pos)
  my.bufpos = pos # store back

proc skip(my: var JsonParser) =
  var pos = my.bufpos
  var buf = my.buf
  while true:
    case buf[pos]
    of '/':
      if buf[pos+1] == '/':
        # skip line comment:
        inc(pos, 2)
        while true:
          case buf[pos]
          of '\0':
            break
          of '\c':
            pos = lexbase.handleCR(my, pos)
            buf = my.buf
            break
          of '\L':
            pos = lexbase.handleLF(my, pos)
            buf = my.buf
            break
          else:
            inc(pos)
      elif buf[pos+1] == '*':
        # skip long comment:
        inc(pos, 2)
        while true:
          case buf[pos]
          of '\0':
            my.err = errEOC_Expected
            break
          of '\c':
            pos = lexbase.handleCR(my, pos)
            buf = my.buf
          of '\L':
            pos = lexbase.handleLF(my, pos)
            buf = my.buf
          of '*':
            inc(pos)
            if buf[pos] == '/':
              inc(pos)
              break
          else:
            inc(pos)
      else:
        break
    of ' ', '\t':
      inc(pos)
    of '\c':
      pos = lexbase.handleCR(my, pos)
      buf = my.buf
    of '\L':
      pos = lexbase.handleLF(my, pos)
      buf = my.buf
    else:
      break
  my.bufpos = pos

proc parseNumber(my: var JsonParser) =
  var pos = my.bufpos
  var buf = my.buf
  if buf[pos] == '-':
    add(my.a, '-')
    inc(pos)
  if buf[pos] == '.':
    add(my.a, "0.")
    inc(pos)
  else:
    while buf[pos] in Digits:
      add(my.a, buf[pos])
      inc(pos)
    if buf[pos] == '.':
      add(my.a, '.')
      inc(pos)
  # digits after the dot:
  while buf[pos] in Digits:
    add(my.a, buf[pos])
    inc(pos)
  if buf[pos] in {'E', 'e'}:
    add(my.a, buf[pos])
    inc(pos)
    if buf[pos] in {'+', '-'}:
      add(my.a, buf[pos])
      inc(pos)
    while buf[pos] in Digits:
      add(my.a, buf[pos])
      inc(pos)
  my.bufpos = pos

proc parseName(my: var JsonParser) =
  var pos = my.bufpos
  var buf = my.buf
  if buf[pos] in IdentStartChars:
    while buf[pos] in IdentChars:
      add(my.a, buf[pos])
      inc(pos)
  my.bufpos = pos

proc getTok(my: var JsonParser): TTokKind =
  setLen(my.a, 0)
  skip(my) # skip whitespace, comments
  case my.buf[my.bufpos]
  of '-', '.', '0'..'9':
    parseNumber(my)
    if {'.', 'e', 'E'} in my.a:
      result = tkFloat
    else:
      result = tkInt
  of '"':
    result = parseString(my)
  of '[':
    inc(my.bufpos)
    result = tkBracketLe
  of '{':
    inc(my.bufpos)
    result = tkCurlyLe
  of ']':
    inc(my.bufpos)
    result = tkBracketRi
  of '}':
    inc(my.bufpos)
    result = tkCurlyRi
  of ',':
    inc(my.bufpos)
    result = tkComma
  of ':':
    inc(my.bufpos)
    result = tkColon
  of '\0':
    result = tkEof
  of 'a'..'z', 'A'..'Z', '_':
    parseName(my)
    case my.a
    of "null": result = tkNull
    of "true": result = tkTrue
    of "false": result = tkFalse
    else: result = tkError
  else:
    inc(my.bufpos)
    result = tkError
  my.tok = result

proc next*(my: var JsonParser) =
  ## retrieves the first/next event. This controls the parser.
  var tk = getTok(my)
  var i = my.state.len-1
  # the following code is a state machine. If we had proper coroutines,
  # the code could be much simpler.
  case my.state[i]
  of stateEof:
    if tk == tkEof:
      my.kind = jsonEof
    else:
      my.kind = jsonError
      my.err = errEofExpected
  of stateStart:
    # tokens allowed?
    case tk
    of tkString, tkInt, tkFloat, tkTrue, tkFalse, tkNull:
      my.state[i] = stateEof # expect EOF next!
      my.kind = JsonEventKind(ord(tk))
    of tkBracketLe:
      my.state.add(stateArray) # we expect any
      my.kind = jsonArrayStart
    of tkCurlyLe:
      my.state.add(stateObject)
      my.kind = jsonObjectStart
    of tkEof:
      my.kind = jsonEof
    else:
      my.kind = jsonError
      my.err = errEofExpected
  of stateObject:
    case tk
    of tkString, tkInt, tkFloat, tkTrue, tkFalse, tkNull:
      my.state.add(stateExpectColon)
      my.kind = JsonEventKind(ord(tk))
    of tkBracketLe:
      my.state.add(stateExpectColon)
      my.state.add(stateArray)
      my.kind = jsonArrayStart
    of tkCurlyLe:
      my.state.add(stateExpectColon)
      my.state.add(stateObject)
      my.kind = jsonObjectStart
    of tkCurlyRi:
      my.kind = jsonObjectEnd
      discard my.state.pop()
    else:
      my.kind = jsonError
      my.err = errCurlyRiExpected
  of stateArray:
    case tk
    of tkString, tkInt, tkFloat, tkTrue, tkFalse, tkNull:
      my.state.add(stateExpectArrayComma) # expect value next!
      my.kind = JsonEventKind(ord(tk))
    of tkBracketLe:
      my.state.add(stateExpectArrayComma)
      my.state.add(stateArray)
      my.kind = jsonArrayStart
    of tkCurlyLe:
      my.state.add(stateExpectArrayComma)
      my.state.add(stateObject)
      my.kind = jsonObjectStart
    of tkBracketRi:
      my.kind = jsonArrayEnd
      discard my.state.pop()
    else:
      my.kind = jsonError
      my.err = errBracketRiExpected
  of stateExpectArrayComma:
    case tk
    of tkComma:
      discard my.state.pop()
      next(my)
    of tkBracketRi:
      my.kind = jsonArrayEnd
      discard my.state.pop() # pop stateExpectArrayComma
      discard my.state.pop() # pop stateArray
    else:
      my.kind = jsonError
      my.err = errBracketRiExpected
  of stateExpectObjectComma:
    case tk
    of tkComma:
      discard my.state.pop()
      next(my)
    of tkCurlyRi:
      my.kind = jsonObjectEnd
      discard my.state.pop() # pop stateExpectObjectComma
      discard my.state.pop() # pop stateObject
    else:
      my.kind = jsonError
      my.err = errCurlyRiExpected
  of stateExpectColon:
    case tk
    of tkColon:
      my.state[i] = stateExpectValue
      next(my)
    else:
      my.kind = jsonError
      my.err = errColonExpected
  of stateExpectValue:
    case tk
    of tkString, tkInt, tkFloat, tkTrue, tkFalse, tkNull:
      my.state[i] = stateExpectObjectComma
      my.kind = JsonEventKind(ord(tk))
    of tkBracketLe:
      my.state[i] = stateExpectObjectComma
      my.state.add(stateArray)
      my.kind = jsonArrayStart
    of tkCurlyLe:
      my.state[i] = stateExpectObjectComma
      my.state.add(stateObject)
      my.kind = jsonObjectStart
    else:
      my.kind = jsonError
      my.err = errExprExpected


# ------------- higher level interface ---------------------------------------

type
  JsonNodeKind* = enum ## possible JSON node types
    JNull,
    JBool,
    JInt,
    JFloat,
    JString,
    JObject,
    JArray

  JsonNode* = ref JsonNodeObj ## JSON node
  JsonNodeObj* {.acyclic.} = object
    case kind*: JsonNodeKind
    of JString:
      str*: string
    of JInt:
      num*: BiggestInt
    of JFloat:
      fnum*: float
    of JBool:
      bval*: bool
    of JNull:
      nil
    of JObject:
      fields*: seq[tuple[key: string, val: JsonNode]]
    of JArray:
      elems*: seq[JsonNode]

  JsonParsingError* = object of ValueError ## is raised for a JSON error

{.deprecated: [EJsonParsingError: JsonParsingError, TJsonNode: JsonNodeObj,
    PJsonNode: JsonNode, TJsonNodeKind: JsonNodeKind].}

proc raiseParseErr*(p: JsonParser, msg: string) {.noinline, noreturn.} =
  ## raises an `EJsonParsingError` exception.
  raise newException(JsonParsingError, errorMsgExpected(p, msg))

proc newJString*(s: string): JsonNode =
  ## Creates a new `JString JsonNode`.
  new(result)
  result.kind = JString
  result.str = s

proc newJStringMove(s: string): JsonNode =
  new(result)
  result.kind = JString
  shallowCopy(result.str, s)

proc newJInt*(n: BiggestInt): JsonNode =
  ## Creates a new `JInt JsonNode`.
  new(result)
  result.kind = JInt
  result.num  = n

proc newJFloat*(n: float): JsonNode =
  ## Creates a new `JFloat JsonNode`.
  new(result)
  result.kind = JFloat
  result.fnum  = n

proc newJBool*(b: bool): JsonNode =
  ## Creates a new `JBool JsonNode`.
  new(result)
  result.kind = JBool
  result.bval = b

proc newJNull*(): JsonNode =
  ## Creates a new `JNull JsonNode`.
  new(result)

proc newJObject*(): JsonNode =
  ## Creates a new `JObject JsonNode`
  new(result)
  result.kind = JObject
  result.fields = @[]

proc newJArray*(): JsonNode =
  ## Creates a new `JArray JsonNode`
  new(result)
  result.kind = JArray
  result.elems = @[]


proc `%`*(s: string): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JString JsonNode`.
  new(result)
  result.kind = JString
  result.str = s

proc `%`*(n: BiggestInt): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JInt JsonNode`.
  new(result)
  result.kind = JInt
  result.num  = n

proc `%`*(n: float): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JFloat JsonNode`.
  new(result)
  result.kind = JFloat
  result.fnum  = n

proc `%`*(b: bool): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JBool JsonNode`.
  new(result)
  result.kind = JBool
  result.bval = b

proc `%`*(keyVals: openArray[tuple[key: string, val: JsonNode]]): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JObject JsonNode`
  new(result)
  result.kind = JObject
  newSeq(result.fields, keyVals.len)
  for i, p in pairs(keyVals): result.fields[i] = p

proc `%`*(elements: openArray[JsonNode]): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JArray JsonNode`
  new(result)
  result.kind = JArray
  newSeq(result.elems, elements.len)
  for i, p in pairs(elements): result.elems[i] = p

proc toJson(x: NimNode): NimNode {.compiletime.} =
  case x.kind
  of nnkBracket:
    result = newNimNode(nnkBracket)
    for i in 0 .. <x.len:
      result.add(toJson(x[i]))

  of nnkTableConstr:
    result = newNimNode(nnkTableConstr)
    for i in 0 .. <x.len:
      assert x[i].kind == nnkExprColonExpr
      result.add(newNimNode(nnkExprColonExpr).add(x[i][0]).add(toJson(x[i][1])))

  else:
    result = x

  result = prefix(result, "%")

macro `%*`*(x: expr): expr =
  ## Convert an expression to a JsonNode directly, without having to specify
  ## `%` for every element.
  result = toJson(x)

proc `==`* (a,b: JsonNode): bool =
  ## Check two nodes for equality
  if a.isNil:
    if b.isNil: return true
    return false
  elif b.isNil or a.kind != b.kind:
    return false
  else:
    return case a.kind
    of JString:
      a.str == b.str
    of JInt:
      a.num == b.num
    of JFloat:
      a.fnum == b.fnum
    of JBool:
      a.bval == b.bval
    of JNull:
      true
    of JArray:
      a.elems == b.elems
    of JObject:
      a.fields == b.fields

proc hash* (n:JsonNode): THash =
  ## Compute the hash for a JSON node
  case n.kind
  of JArray:
    result = hash(n.elems)
  of JObject:
    result = hash(n.fields)
  of JInt:
    result = hash(n.num)
  of JFloat:
    result = hash(n.fnum)
  of JBool:
    result = hash(n.bval.int)
  of JString:
    result = hash(n.str)
  of JNull:
    result = hash(0)

proc len*(n: JsonNode): int =
  ## If `n` is a `JArray`, it returns the number of elements.
  ## If `n` is a `JObject`, it returns the number of pairs.
  ## Else it returns 0.
  case n.kind
  of JArray: result = n.elems.len
  of JObject: result = n.fields.len
  else: discard

proc `[]`*(node: JsonNode, name: string): JsonNode =
  ## Gets a field from a `JObject`, which must not be nil.
  ## If the value at `name` does not exist, returns nil
  assert(not isNil(node))
  assert(node.kind == JObject)
  for key, item in items(node.fields):
    if key == name:
      return item
  return nil

proc `[]`*(node: JsonNode, index: int): JsonNode =
  ## Gets the node at `index` in an Array. Result is undefined if `index`
  ## is out of bounds
  assert(not isNil(node))
  assert(node.kind == JArray)
  return node.elems[index]

proc hasKey*(node: JsonNode, key: string): bool =
  ## Checks if `key` exists in `node`.
  assert(node.kind == JObject)
  for k, item in items(node.fields):
    if k == key: return true

proc existsKey*(node: JsonNode, key: string): bool {.deprecated.} = node.hasKey(key)
  ## Deprecated for `hasKey`

proc add*(father, child: JsonNode) =
  ## Adds `child` to a JArray node `father`.
  assert father.kind == JArray
  father.elems.add(child)

proc add*(obj: JsonNode, key: string, val: JsonNode) =
  ## Adds ``(key, val)`` pair to the JObject node `obj`. For speed
  ## reasons no check for duplicate keys is performed!
  ## But ``[]=`` performs the check.
  assert obj.kind == JObject
  obj.fields.add((key, val))

proc `[]=`*(obj: JsonNode, key: string, val: JsonNode) =
  ## Sets a field from a `JObject`. Performs a check for duplicate keys.
  assert(obj.kind == JObject)
  for i in 0..obj.fields.len-1:
    if obj.fields[i].key == key:
      obj.fields[i].val = val
      return
  obj.fields.add((key, val))

proc `{}`*(node: JsonNode, key: string): JsonNode =
  ## Transverses the node and gets the given value. If any of the
  ## names does not exist, returns nil
  result = node
  if isNil(node): return nil
  result = result[key]

proc `{}=`*(node: JsonNode, names: varargs[string], value: JsonNode) =
  ## Transverses the node and tries to set the value at the given location
  ## to `value` If any of the names are missing, they are added
  var node = node
  for i in 0..(names.len-2):
    if isNil(node[names[i]]):
      node[names[i]] = newJObject()
    node = node[names[i]]
  node[names[names.len-1]] = value

proc delete*(obj: JsonNode, key: string) =
  ## Deletes ``obj[key]`` preserving the order of the other (key, value)-pairs.
  assert(obj.kind == JObject)
  for i in 0..obj.fields.len-1:
    if obj.fields[i].key == key:
      obj.fields.delete(i)
      return
  raise newException(IndexError, "key not in object")

proc copy*(p: JsonNode): JsonNode =
  ## Performs a deep copy of `a`.
  case p.kind
  of JString:
    result = newJString(p.str)
  of JInt:
    result = newJInt(p.num)
  of JFloat:
    result = newJFloat(p.fnum)
  of JBool:
    result = newJBool(p.bval)
  of JNull:
    result = newJNull()
  of JObject:
    result = newJObject()
    for key, field in items(p.fields):
      result.fields.add((key, copy(field)))
  of JArray:
    result = newJArray()
    for i in items(p.elems):
      result.elems.add(copy(i))

# ------------- pretty printing ----------------------------------------------

proc indent(s: var string, i: int) =
  s.add(spaces(i))

proc newIndent(curr, indent: int, ml: bool): int =
  if ml: return curr + indent
  else: return indent

proc nl(s: var string, ml: bool) =
  if ml: s.add("\n")

proc escapeJson*(s: string): string =
  ## Converts a string `s` to its JSON representation.
  result = newStringOfCap(s.len + s.len shr 3)
  result.add("\"")
  for x in runes(s):
    var r = int(x)
    if r >= 32 and r <= 127:
      var c = chr(r)
      case c
      of '"': result.add("\\\"")
      of '\\': result.add("\\\\")
      else: result.add(c)
    else:
      result.add("\\u")
      result.add(toHex(r, 4))
  result.add("\"")

proc toPretty(result: var string, node: JsonNode, indent = 2, ml = true,
              lstArr = false, currIndent = 0) =
  case node.kind
  of JObject:
    if currIndent != 0 and not lstArr: result.nl(ml)
    result.indent(currIndent) # Indentation
    if node.fields.len > 0:
      result.add("{")
      result.nl(ml) # New line
      for i in 0..len(node.fields)-1:
        if i > 0:
          result.add(", ")
          result.nl(ml) # New Line
        # Need to indent more than {
        result.indent(newIndent(currIndent, indent, ml))
        result.add(escapeJson(node.fields[i].key))
        result.add(": ")
        toPretty(result, node.fields[i].val, indent, ml, false,
                 newIndent(currIndent, indent, ml))
      result.nl(ml)
      result.indent(currIndent) # indent the same as {
      result.add("}")
    else:
      result.add("{}")
  of JString:
    if lstArr: result.indent(currIndent)
    result.add(escapeJson(node.str))
  of JInt:
    if lstArr: result.indent(currIndent)
    result.add($node.num)
  of JFloat:
    if lstArr: result.indent(currIndent)
    result.add($node.fnum)
  of JBool:
    if lstArr: result.indent(currIndent)
    result.add($node.bval)
  of JArray:
    if lstArr: result.indent(currIndent)
    if len(node.elems) != 0:
      result.add("[")
      result.nl(ml)
      for i in 0..len(node.elems)-1:
        if i > 0:
          result.add(", ")
          result.nl(ml) # New Line
        toPretty(result, node.elems[i], indent, ml,
            true, newIndent(currIndent, indent, ml))
      result.nl(ml)
      result.indent(currIndent)
      result.add("]")
    else: result.add("[]")
  of JNull:
    if lstArr: result.indent(currIndent)
    result.add("null")

proc pretty*(node: JsonNode, indent = 2): string =
  ## Converts `node` to its JSON Representation, with indentation and
  ## on multiple lines.
  result = ""
  toPretty(result, node, indent)

proc `$`*(node: JsonNode): string =
  ## Converts `node` to its JSON Representation on one line.
  result = ""
  toPretty(result, node, 0, false)

iterator items*(node: JsonNode): JsonNode =
  ## Iterator for the items of `node`. `node` has to be a JArray.
  assert node.kind == JArray
  for i in items(node.elems):
    yield i

iterator mitems*(node: var JsonNode): var JsonNode =
  ## Iterator for the items of `node`. `node` has to be a JArray. Items can be
  ## modified.
  assert node.kind == JArray
  for i in mitems(node.elems):
    yield i

iterator pairs*(node: JsonNode): tuple[key: string, val: JsonNode] =
  ## Iterator for the child elements of `node`. `node` has to be a JObject.
  assert node.kind == JObject
  for key, val in items(node.fields):
    yield (key, val)

iterator mpairs*(node: var JsonNode): var tuple[key: string, val: JsonNode] =
  ## Iterator for the child elements of `node`. `node` has to be a JObject.
  ## Items can be modified
  assert node.kind == JObject
  for keyVal in mitems(node.fields):
    yield keyVal

proc eat(p: var JsonParser, tok: TTokKind) =
  if p.tok == tok: discard getTok(p)
  else: raiseParseErr(p, tokToStr[tok])

proc parseJson(p: var JsonParser): JsonNode =
  ## Parses JSON from a JSON Parser `p`.
  case p.tok
  of tkString:
    # we capture 'p.a' here, so we need to give it a fresh buffer afterwards:
    result = newJStringMove(p.a)
    p.a = ""
    discard getTok(p)
  of tkInt:
    result = newJInt(parseBiggestInt(p.a))
    discard getTok(p)
  of tkFloat:
    result = newJFloat(parseFloat(p.a))
    discard getTok(p)
  of tkTrue:
    result = newJBool(true)
    discard getTok(p)
  of tkFalse:
    result = newJBool(false)
    discard getTok(p)
  of tkNull:
    result = newJNull()
    discard getTok(p)
  of tkCurlyLe:
    result = newJObject()
    discard getTok(p)
    while p.tok != tkCurlyRi:
      if p.tok != tkString:
        raiseParseErr(p, "string literal as key expected")
      var key = p.a
      discard getTok(p)
      eat(p, tkColon)
      var val = parseJson(p)
      result[key] = val
      if p.tok != tkComma: break
      discard getTok(p)
    eat(p, tkCurlyRi)
  of tkBracketLe:
    result = newJArray()
    discard getTok(p)
    while p.tok != tkBracketRi:
      result.add(parseJson(p))
      if p.tok != tkComma: break
      discard getTok(p)
    eat(p, tkBracketRi)
  of tkError, tkCurlyRi, tkBracketRi, tkColon, tkComma, tkEof:
    raiseParseErr(p, "{")

when not defined(js):
  proc parseJson*(s: Stream, filename: string): JsonNode =
    ## Parses from a stream `s` into a `JsonNode`. `filename` is only needed
    ## for nice error messages.
    var p: JsonParser
    p.open(s, filename)
    discard getTok(p) # read first token
    result = p.parseJson()
    p.close()

  proc parseJson*(buffer: string): JsonNode =
    ## Parses JSON from `buffer`.
    result = parseJson(newStringStream(buffer), "input")

  proc parseFile*(filename: string): JsonNode =
    ## Parses `file` into a `JsonNode`.
    var stream = newFileStream(filename, fmRead)
    if stream == nil:
      raise newException(IOError, "cannot read from file: " & filename)
    result = parseJson(stream, filename)
else:
  from math import `mod`
  type
    TJSObject = object
  proc parseNativeJson(x: cstring): TJSObject {.importc: "JSON.parse".}

  proc getVarType(x): JsonNodeKind =
    result = JNull
    proc getProtoName(y): cstring
      {.importc: "Object.prototype.toString.call".}
    case $getProtoName(x) # TODO: Implicit returns fail here.
    of "[object Array]": return JArray
    of "[object Object]": return JObject
    of "[object Number]":
      if cast[float](x) mod 1.0 == 0:
        return JInt
      else:
        return JFloat
    of "[object Boolean]": return JBool
    of "[object Null]": return JNull
    of "[object String]": return JString
    else: assert false

  proc len(x: TJSObject): int =
    assert x.getVarType == JArray
    asm """
      return `x`.length;
    """

  proc `[]`(x: TJSObject, y: string): TJSObject =
    assert x.getVarType == JObject
    asm """
      return `x`[`y`];
    """

  proc `[]`(x: TJSObject, y: int): TJSObject =
    assert x.getVarType == JArray
    asm """
      return `x`[`y`];
    """

  proc convertObject(x: TJSObject): JsonNode =
    case getVarType(x)
    of JArray:
      result = newJArray()
      for i in 0 .. <x.len:
        result.add(x[i].convertObject())
    of JObject:
      result = newJObject()
      asm """for (property in `x`) {
        if (`x`.hasOwnProperty(property)) {
      """
      var nimProperty: cstring
      var nimValue: TJSObject
      asm "`nimProperty` = property; `nimValue` = `x`[property];"
      result[$nimProperty] = nimValue.convertObject()
      asm "}}"
    of JInt:
      result = newJInt(cast[int](x))
    of JFloat:
      result = newJFloat(cast[float](x))
    of JString:
      result = newJString($cast[cstring](x))
    of JBool:
      result = newJBool(cast[bool](x))
    of JNull:
      result = newJNull()

  proc parseJson*(buffer: string): JsonNode =
    return parseNativeJson(buffer).convertObject()

when false:
  import os
  var s = newFileStream(paramStr(1), fmRead)
  if s == nil: quit("cannot open the file" & paramStr(1))
  var x: JsonParser
  open(x, s, paramStr(1))
  while true:
    next(x)
    case x.kind
    of jsonError:
      Echo(x.errorMsg())
      break
    of jsonEof: break
    of jsonString, jsonInt, jsonFloat: echo(x.str)
    of jsonTrue: echo("!TRUE")
    of jsonFalse: echo("!FALSE")
    of jsonNull: echo("!NULL")
    of jsonObjectStart: echo("{")
    of jsonObjectEnd: echo("}")
    of jsonArrayStart: echo("[")
    of jsonArrayEnd: echo("]")

  close(x)

# { "json": 5 }
# To get that we shall use, obj["json"]

when isMainModule:
  #var node = parse("{ \"test\": null }")
  #echo(node.existsKey("test56"))
  var parsed = parseFile("tests/testdata/jsontest.json")
  var parsed2 = parseFile("tests/testdata/jsontest2.json")
  echo(parsed)
  echo()
  echo(pretty(parsed, 2))
  echo()
  echo(parsed["keyÄÖöoßß"])
  echo()
  echo(pretty(parsed2))
  try:
    echo(parsed["key2"][12123])
    raise newException(ValueError, "That line was expected to fail")
  except IndexError: echo()

  let testJson = parseJson"""{ "a": [1, 2, 3, 4], "b": "asd" }"""
  # nil passthrough
  assert(testJson{"doesnt_exist"}{"anything"}.isNil)
  testJson{["c", "d"]} = %true
  assert(testJson["c"]["d"].bval)

  # Bounds checking
  try:
    let a = testJson["a"][9]
    assert(false, "EInvalidIndex not thrown")
  except IndexError:
    discard
  try:
    let a = testJson["a"][-1]
    assert(false, "EInvalidIndex not thrown")
  except IndexError:
    discard
  try:
    assert(testJson["a"][0].num == 1, "Index doesn't correspond to its value")
  except:
    assert(false, "EInvalidIndex thrown for valid index")

  # Generator:
  var j = %* [{"name": "John", "age": 30}, {"name": "Susan", "age": 31}]
  assert j == %[%{"name": %"John", "age": %30}, %{"name": %"Susan", "age": %31}]

  var j2 = %*
    [
      {
        "name": "John",
        "age": 30
      },
      {
        "name": "Susan",
        "age": 31
      }
    ]
  assert j2 == %[%{"name": %"John", "age": %30}, %{"name": %"Susan", "age": %31}]

  var name = "John"
  let herAge = 30
  const hisAge = 31

  var j3 = %*
    [ { "name": "John"
      , "age": herAge
      }
    , { "name": "Susan"
      , "age": hisAge
      }
    ]
  assert j3 == %[%{"name": %"John", "age": %30}, %{"name": %"Susan", "age": %31}]

  discard """
  while true:
    var json = stdin.readLine()
    var node = parse(json)
    echo(node)
    echo()
    echo()
  """
