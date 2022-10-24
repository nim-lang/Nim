import parsejson, strutils, streams

import jsontypes, jsontree, jsonbuilder

export
  parsejson.JsonEventKind, parsejson.JsonError, JsonParser, JsonKindError,
  open, close, str, getInt, getFloat, kind, getColumn, getLine, getFilename,
  errorMsg, errorMsgExpected, next, JsonParsingError, raiseParseErr, nimIdentNormalize

when defined(nimPreviewSlimSystem):
  import std/[syncio, assertions]

const DepthLimit = 1000

proc parseJson(p: var JsonParser; rawIntegers, rawFloats: bool, depth = 0): JsonNode =
  ## Parses JSON from a JSON Parser `p`.
  case p.tok
  of tkString:
    # we capture 'p.a' here, so we need to give it a fresh buffer afterwards:
    when defined(gcArc) or defined(gcOrc):
      result = JsonNode(kind: JString, str: move p.a)
    else:
      result = JsonNode(kind: JString)
      shallowCopy(result.str, p.a)
      p.a = ""
    discard getTok(p)
  of tkInt:
    if rawIntegers:
      result = newJRawNumber(p.a)
    else:
      try:
        result = newJInt(parseBiggestInt(p.a))
      except ValueError:
        result = newJRawNumber(p.a)
    discard getTok(p)
  of tkFloat:
    if rawFloats:
      result = newJRawNumber(p.a)
    else:
      try:
        result = newJFloat(parseFloat(p.a))
      except ValueError:
        result = newJRawNumber(p.a)
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
    if depth > DepthLimit:
      raiseParseErr(p, "}")
    result = newJObject()
    discard getTok(p)
    while p.tok != tkCurlyRi:
      if p.tok != tkString:
        raiseParseErr(p, "string literal as key")
      var key = p.a
      discard getTok(p)
      eat(p, tkColon)
      var val = parseJson(p, rawIntegers, rawFloats, depth+1)
      result[key] = val
      if p.tok != tkComma: break
      discard getTok(p)
    eat(p, tkCurlyRi)
  of tkBracketLe:
    if depth > DepthLimit:
      raiseParseErr(p, "]")
    result = newJArray()
    discard getTok(p)
    while p.tok != tkBracketRi:
      result.add(parseJson(p, rawIntegers, rawFloats, depth+1))
      if p.tok != tkComma: break
      discard getTok(p)
    eat(p, tkBracketRi)
  of tkError, tkCurlyRi, tkBracketRi, tkColon, tkComma, tkEof:
    raiseParseErr(p, "{")

iterator parseJsonFragments*(s: Stream, filename: string = ""; rawIntegers = false, rawFloats = false): JsonNode =
  ## Parses from a stream `s` into `JsonNodes`. `filename` is only needed
  ## for nice error messages.
  ## The JSON fragments are separated by whitespace. This can be substantially
  ## faster than the comparable loop
  ## `for x in splitWhitespace(s): yield parseJson(x)`.
  ## This closes the stream `s` after it's done.
  ## If `rawIntegers` is true, integer literals will not be converted to a `JInt`
  ## field but kept as raw numbers via `JString`.
  ## If `rawFloats` is true, floating point literals will not be converted to a `JFloat`
  ## field but kept as raw numbers via `JString`.
  var p: JsonParser
  p.open(s, filename)
  try:
    discard getTok(p) # read first token
    while p.tok != tkEof:
      yield p.parseJson(rawIntegers, rawFloats)
  finally:
    p.close()

proc parseJson*(s: Stream, filename: string = ""; rawIntegers = false, rawFloats = false): JsonNode =
  ## Parses from a stream `s` into a `JsonNode`. `filename` is only needed
  ## for nice error messages.
  ## If `s` contains extra data, it will raise `JsonParsingError`.
  ## This closes the stream `s` after it's done.
  ## If `rawIntegers` is true, integer literals will not be converted to a `JInt`
  ## field but kept as raw numbers via `JString`.
  ## If `rawFloats` is true, floating point literals will not be converted to a `JFloat`
  ## field but kept as raw numbers via `JString`.
  var p: JsonParser
  p.open(s, filename)
  try:
    discard getTok(p) # read first token
    result = p.parseJson(rawIntegers, rawFloats)
    eat(p, tkEof) # check if there is no extra data
  finally:
    p.close()

when defined(js):
  from math import `mod`
  from std/jsffi import JsObject, `[]`, to
  from std/private/jsutils import getProtoName, isInteger, isSafeInteger

  proc parseNativeJson(x: cstring): JsObject {.importjs: "JSON.parse(#)".}

  proc getVarType(x: JsObject, isRawNumber: var bool): JsonNodeKind =
    result = JNull
    case $getProtoName(x) # TODO: Implicit returns fail here.
    of "[object Array]": return JArray
    of "[object Object]": return JObject
    of "[object Number]":
      if isInteger(x) and 1.0 / cast[float](x) != -Inf: # preserve -0.0 as float
        if isSafeInteger(x):
          return JInt
        else:
          isRawNumber = true
          return JString
      else:
        return JFloat
    of "[object Boolean]": return JBool
    of "[object Null]": return JNull
    of "[object String]": return JString
    else: assert false

  proc len(x: JsObject): int =
    asm """
      `result` = `x`.length;
    """

  proc convertObject(x: JsObject): JsonNode =
    var isRawNumber = false
    case getVarType(x, isRawNumber)
    of JArray:
      result = newJArray()
      for i in 0 ..< x.len:
        result.add(x[i].convertObject())
    of JObject:
      result = newJObject()
      asm """for (var property in `x`) {
        if (`x`.hasOwnProperty(property)) {
      """
      var nimProperty: cstring
      var nimValue: JsObject
      asm "`nimProperty` = property; `nimValue` = `x`[property];"
      result[$nimProperty] = nimValue.convertObject()
      asm "}}"
    of JInt:
      result = newJInt(x.to(int))
    of JFloat:
      result = newJFloat(x.to(float))
    of JString:
      # Dunno what to do with isUnquoted here
      if isRawNumber:
        var value: cstring
        {.emit: "`value` = `x`.toString();".}
        result = newJRawNumber($value)
      else:
        result = newJString($x.to(cstring))
    of JBool:
      result = newJBool(x.to(bool))
    of JNull:
      result = newJNull()

  proc parseJson*(buffer: string): JsonNode =
    when nimvm:
      return parseJson(newStringStream(buffer), "input")
    else:
      return parseNativeJson(buffer).convertObject()

else:
  proc parseJson*(buffer: string; rawIntegers = false, rawFloats = false): JsonNode =
    ## Parses JSON from `buffer`.
    ## If `buffer` contains extra data, it will raise `JsonParsingError`.
    ## If `rawIntegers` is true, integer literals will not be converted to a `JInt`
    ## field but kept as raw numbers via `JString`.
    ## If `rawFloats` is true, floating point literals will not be converted to a `JFloat`
    ## field but kept as raw numbers via `JString`.
    result = parseJson(newStringStream(buffer), "input", rawIntegers, rawFloats)

  proc parseFile*(filename: string): JsonNode =
    ## Parses `file` into a `JsonNode`.
    ## If `file` contains extra data, it will raise `JsonParsingError`.
    var stream = newFileStream(filename, fmRead)
    if stream == nil:
      raise newException(IOError, "cannot read from file: " & filename)
    result = parseJson(stream, filename, rawIntegers=false, rawFloats=false)
