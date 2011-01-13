#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import parsejson, streams, strutils

type
  TJsonNodeKind* = enum
    JString,
    JNumber,
    JBool,
    JNull,
    JObject,
    JArray
    
  PJsonNode* = ref TJsonNode 
  TJsonNode* = object
    case kind*: TJsonNodeKind
    of JString:
      str*: String
    of JNumber:
      num*: Float
    of JBool:
      bval*: Bool
    of JNull:
      nil
    of JObject:
      fields*: seq[tuple[key: string, obj: PJsonNode]]
    of JArray:
      elems*: seq[PJsonNode]

  EJsonParsingError* = object of EBase

proc raiseParseErr(parser: TJsonParser, msg: string, line = True) =
  if line:
    raise newException(EJsonParsingError, "(" & $parser.getLine & ", " &
                       $parser.getColumn & ") " & msg)
  else:
    raise newException(EJsonParsingError, msg)

proc indent(s: var string, i: int) = 
  s.add(repeatChar(i))

proc newIndent(curr, indent: int, ml: bool): Int =
  if ml: return curr + indent
  else: return indent

proc nl(s: var string, ml: bool) = 
  if ml: s.add("\n")

proc toPretty(result: var string, node: PJsonNode, indent = 2, ml = True, lstArr = False, currIndent = 0) =
  case node.kind
  of JObject:
    if currIndent != 0 and not lstArr: result.nl(ml)
    result.indent(currIndent) # Indentation
    result.add("{")
    result.nl(ml) # New line
    for i in 0..len(node.fields)-1:
      if i > 0:
        result.add(", ")
        result.nl(ml) # New Line
      var (key, item) = node.fields[i]
      result.indent(newIndent(currIndent, indent, ml)) # Need to indent more than {
      result.add("\"" & key & "\": ")
      toPretty(result, item, indent, ml, False, newIndent(currIndent, indent, ml))
    result.nl(ml)
    result.indent(currIndent) # indent the same as {
    result.add("}")
  of JString: 
    if lstArr: result.indent(currIndent)
    result.add("\"" & node.str & "\"")
  of JNumber:
    if lstArr: result.indent(currIndent)
    result.add($node.num)
  of JBool:
    if lstArr: result.indent(currIndent)
    result.add($node.bval)
  of JArray:
    if len(node.elems) != 0:
      result.add("[")
      result.nl(ml)
      for i in 0..len(node.elems)-1:
        if i > 0:
          result.add(", ")
          result.nl(ml) # New Line
        toPretty(result, node.elems[i], indent, ml,
            True, newIndent(currIndent, indent, ml))
      result.nl(ml)
      result.indent(currIndent)
      result.add("]")
    else: result.add("[]")
  of JNull:
    if lstArr: result.indent(currIndent)
    result.add("null")

proc pretty*(node: PJsonNode, indent = 2): String =
  ## Converts a `PJsonNode` to its JSON Representation, with indentation and
  ## on multiple lines.
  result = ""
  toPretty(result, node, indent)

proc `$`*(node: PJsonNode): String =
  ## Converts a `PJsonNode` to its JSON Representation on one line.
  result = ""
  toPretty(result, node, 1, False)

proc newJString*(s: String): PJsonNode =
  ## Creates a new `JString PJsonNode`
  new(result)
  result.kind = JString
  result.str = s

proc newJNumber*(n: Float): PJsonNode =
  ## Creates a new `JNumber PJsonNode`
  new(result)
  result.kind = JNumber
  result.num  = n
  
proc newJBool*(b: Bool): PJsonNode =
  ## Creates a new `JBool PJsonNode`
  new(result)
  result.kind = JBool
  result.bval = b

proc newJNull*(): PJsonNode =
  ## Creates a new `JNull PJsonNode`
  new(result)
  result.kind = JNull

proc newJObject*(f: seq[tuple[key: string, obj: PJsonNode]]): PJsonNode =
  ## Creates a new `JObject PJsonNode`
  new(result)
  result.kind = JObject
  result.fields = f

proc newJArray*(a: seq[PJsonNode]): PJsonNode =
  ## Creates a new `JArray PJsonNode`
  new(result)
  result.kind = JArray
  result.elems = a
  
proc parseOther(parser: var TJsonParser): PJsonNode =
  # Parses a *single* node which is not an Array or Object.
  new(result)
  case parser.kind
  of jsonString:
    result = newJString(parser.str())
  of jsonNumber:
    result = newJNumber(parser.number())
  of jsonTrue, jsonFalse:
    result = newJBool((parser.kind == jsonTrue))
  of jsonNull:
    result = newJNull()
  of jsonError:
    parser.raiseParseErr(parser.errorMsg(), false)
  else: parser.raiseParseErr("Unexpected " & $parser.kind & " here.")

proc parseObj(parser: var TJSonParser, oStart: Bool = False): PJsonNode

proc parseArray(parser: var TJsonParser): PJsonNode =
  result = newJArray(@[])
  while True:
    parser.next()
    case parser.kind
    of jsonArrayStart:
      # Array in an array.
      var arr = parser.parseArray()
      result.elems.add(arr)
    of jsonArrayEnd:
      return
    of jsonString, jsonNumber, jsonTrue, jsonFalse, jsonNull:
      var other = parser.parseOther()
      result.elems.add(other)
    of jsonObjectStart:
      var obj = parser.parseObj(True)
      result.elems.add(obj)
    of jsonObjectEnd: parser.raiseParseErr("Unexpected }")
    of jsonEof: parser.raiseParseErr("Unexpected EOF.")
    of jsonError: parser.raiseParseErr(parser.errorMsg(), false)
    
proc parseObj(parser: var TJSonParser, oStart: Bool = False): PJsonNode =
  var key = ""
  var objStarted = oStart
  result = newJObject(@[])
  while True:
    parser.next()
    case parser.kind
    of jsonError:
      parser.raiseParseErr(parser.errorMsg(), false)
      break
    of jsonEof: break
    of jsonString, jsonNumber, jsonTrue, jsonFalse, jsonNull:
      if parser.kind == jsonString and (key == "" and objStarted):
        key = parser.str()
      elif key == "":
        parser.raiseParseErr("Expected object or array.")
      else:
        var obj = parser.parseOther()
        result.fields.add((key, obj))
        key = ""
    of jsonObjectStart:
      objStarted = True
      if key != "":
        # Make sure that parseObj knows that the object has been started
        var obj = parser.parseObj(True) 
        result.fields.add((key, obj))
        key = ""
    of jsonObjectEnd: return
    of jsonArrayStart:
      var arr = parser.parseArray()
      if key != "":
        result.fields.add((key, arr))
        key = ""
      else:
        return arr
    of jsonArrayEnd: parser.raiseParseErr("Unexpected ]")

proc parse*(json: string): PJsonNode =
  ## Parses string `json` into a `PJsonNode`.
  var stream = newStringStream(json)
  var parser: TJsonParser
  parser.open(stream, "")
  result = parser.parseObj()
    
  parser.close()

proc parseFile*(file: String): PJsonNode =
  ## Parses `file` into a `PJsonNode`.
  var stream = newFileStream(file, fmRead)
  var parser: TJsonParser
  parser.open(stream, file)
  result = parser.parseObj()
    
  parser.close()

proc `[]`*(node: PJsonNode, name: String): PJsonNode =
  ## Gets a field from a `JObject`.
  assert(node.kind == JObject)
  for key, item in items(node.fields):
    if key == name:
      return item
  return nil
  
proc `[]`*(node: PJsonNode, index: Int): PJsonNode =
  ## Gets the node at `index` in an Array.
  assert(node.kind == JArray)
  return node.elems[index]

proc existsKey*(node: PJsonNode, name: String): Bool =
  ## Checks if key `name` exists in `node`.
  assert(node.kind == JObject)
  for key, item in items(node.fields):
    if key == name:
      return True
  return False



# { "json": 5 } 
# To get that we shall use, obj["json"]

when isMainModule:
  #var node = parse("{ \"test\": null }")
  #echo(node.existsKey("test56"))
  var parsed = parseFile("test2.json")
  echo(parsed["commits"][0]["author"]["username"].str)
  echo()
  echo(pretty(parsed, 2))
  echo()
  echo(parsed)

  discard """
  while true:
    var json = stdin.readLine()
    var node = parse(json)
    echo(node)
    echo()
    echo()
  """
