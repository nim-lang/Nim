#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple high performance `JSON`:idx: parser. `JSON
## (JavaScript Object Notation) <http://www.json.org>`_ is a lightweight
## data-interchange format that is easy for humans to read and write (unlike
## XML). It is easy for machines to parse and generate.  JSON is based on a
## subset of the JavaScript Programming Language, `Standard ECMA-262 3rd
## Edition - December 1999
## <http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-262.pdf>`_.
##
## Parsing small values quickly can be done with the convenience `parseJson()
## <#parseJson,string>`_ proc which returns the whole JSON tree.  If you are
## parsing very big JSON inputs or want to skip most of the items in them you
## can initialize your own `TJsonParser <#TJsonParser>`_ with the `open()
## <#open>`_ proc and call `next() <#next>`_ in a loop to process the
## individual parsing events.
##
## If you need to create JSON objects from your Nimrod types you can call procs
## like `newJObject() <#newJObject>`_ (or their equivalent `%()
## <#%,openArray[tuple[string,PJsonNode]]>`_ generic constructor). For
## consistency you can provide your own ``%`` operators for custom object
## types:
##
## .. code-block:: nimrod
##   type
##     Person = object ## Generic person record.
##       age: int      ## The age of the person.
##       name: string  ## The name of the person.
##
##   proc `%`(p: Person): PJsonNode =
##     ## Converts a Person into a PJsonNode.
##     result = %[("age", %p.age), ("name", %p.name)]
##
##   proc test() =
##     # Tests making some jsons.
##     var p: Person
##     p.age = 24
##     p.name = "Minah"
##     echo(%p) # { "age": 24,  "name": "Minah"}
##
##     p.age = 33
##     p.name = "Sojin"
##     echo(%p) # { "age": 33,  "name": "Sojin"}
##
## If you don't need special logic in your Nimrod objects' serialization code
## you can also use the `marshal module <marshal.html>`_ which converts objects
## directly to JSON.

import 
  hashes, strutils, lexbase, streams, unicode

type 
  TJsonEventKind* = enum ## Events that may occur when parsing. \
    ##
    ## You compare these values agains the result of the `kind() proc <#kind>`_.
    jsonError,           ## An error ocurred during parsing.
    jsonEof,             ## End of file reached.
    jsonString,          ## A string literal.
    jsonInt,             ## An integer literal.
    jsonFloat,           ## A float literal.
    jsonTrue,            ## The value ``true``.
    jsonFalse,           ## The value ``false``.
    jsonNull,            ## The value ``null``.
    jsonObjectStart,     ## Start of an object: the ``{`` token.
    jsonObjectEnd,       ## End of an object: the ``}`` token.
    jsonArrayStart,      ## Start of an array: the ``[`` token.
    jsonArrayEnd         ## Start of an array: the ``]`` token.
    
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
    
  TJsonError* = enum       ## enumeration that lists all errors that can occur
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
    
  TParserState = enum 
    stateEof, stateStart, stateObject, stateArray, stateExpectArrayComma,
    stateExpectObjectComma, stateExpectColon, stateExpectValue

  TJsonParser* = object of TBaseLexer ## The JSON parser object. \
    ##
    ## Create a variable of this type and use `open() <#open>`_ on it.
    a: string
    tok: TTokKind
    kind: TJsonEventKind
    err: TJsonError
    state: seq[TParserState]
    filename: string
 
const
  errorMessages: array [TJsonError, string] = [
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

proc open*(my: var TJsonParser, input: PStream, filename: string) =
  ## Initializes the JSON parser with an `input stream <streams.html>`_.
  ##
  ## The `filename` parameter is not strictly required and is used only for
  ## nice error messages. You can pass ``nil`` as long as you never use procs
  ## like `errorMsg() <#errorMsg>`_ or `errorMsgExpected()
  ## <#errorMsgExpected>`_ but passing a dummy filename like ``<input string>``
  ## is safer and more user friendly. Example:
  ##
  ## .. code-block:: nimrod
  ##   import json, streams
  ##
  ##   var
  ##     s = newStringStream("some valid json")
  ##     p: TJsonParser
  ##   p.open(s, "<input string>")
  ##
  ## Once opened, you can process JSON parsing events with the `next()
  ## <#next>`_ proc.
  my.filename = filename
  my.state = @[stateStart]
  my.kind = jsonError
  my.a = ""
  
proc close*(my: var TJsonParser) {.inline.} =
  ## Closes the parser `my` and its associated input stream.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   var
  ##     s = newStringStream("some valid json")
  ##     p: TJsonParser
  ##   p.open(s, "<input string>")
  ##   finally: p.close
  ##   # write here parsing of input
  lexbase.close(my)

proc str*(my: TJsonParser): string {.inline.} = 
  ## Returns the character data for the `events <#TJsonEventKind>`_
  ## ``jsonInt``, ``jsonFloat`` and ``jsonString``.
  ##
  ## This proc will `assert <system.html#assert>`_ in debug builds when used
  ## with other event types. See `next() <#next>`_ for an usage example.
  assert(my.kind in {jsonInt, jsonFloat, jsonString})
  return my.a

proc getInt*(my: TJsonParser): BiggestInt {.inline.} = 
  ## Returns the number for the `jsonInt <#TJsonEventKind>`_ event.
  ##
  ## This proc will `assert <system.html#assert>`_ in debug builds when used
  ## with other event types. See `next() <#next>`_ for an usage example.
  assert(my.kind == jsonInt)
  return parseBiggestInt(my.a)

proc getFloat*(my: TJsonParser): float {.inline.} = 
  ## Returns the number for the `jsonFloat <#TJsonEventKind>`_ event.
  ##
  ## This proc will `assert <system.html#assert>`_ in debug builds when used
  ## with other event types. See `next() <#next>`_ for an usage example.
  assert(my.kind == jsonFloat)
  return parseFloat(my.a)

proc kind*(my: TJsonParser): TJsonEventKind {.inline.} = 
  ## Returns the current event type for the `JSON parser <#TJsonParser>`_.
  ##
  ## Call this proc just after `next() <#next>`_ to act on the new event.
  return my.kind
  
proc getColumn*(my: TJsonParser): int {.inline.} = 
  ## Get the current column the parser has arrived at.
  ##
  ## While this is mostly used by procs like `errorMsg() <#errorMsg>`_ you can
  ## use it as well to show user warnings if you are validating JSON values
  ## during parsing. See `next() <#next>`_ for the full example:
  ##
  ## .. code-block:: nimrod
  ##   case parser.kind
  ##   ...
  ##   of jsonString:
  ##     let inputValue = parser.str
  ##     if previousValues.contains(inputValue):
  ##       echo "$1($2, $3) Warning: repeated value '$4'" % [
  ##         parser.getFilename, $parser.getLine, $parser.getColumn,
  ##          inputValue]
  ##   ...
  result = getColNumber(my, my.bufpos)

proc getLine*(my: TJsonParser): int {.inline.} = 
  ## Get the current line the parser has arrived at.
  ##
  ## While this is mostly used by procs like `errorMsg() <#errorMsg>`_ you can
  ## use it as well to indicate user warnings if you are validating JSON values
  ## during parsing. See `next() <#next>`_ and `getColumn() <#getColumn>`_ for
  ## examples.
  result = my.lineNumber

proc getFilename*(my: TJsonParser): string {.inline.} = 
  ## Get the filename of the file that the parser is processing.
  ##
  ## This is the value you pass to the `open() <#open>`_ proc.  While this is
  ## mostly used by procs like `errorMsg() <#errorMsg>`_ you can use it as well
  ## to indicate user warnings if you are validating JSON values during
  ## parsing. See `next() <#next>`_ and `getColumn() <#getColumn>`_ for
  ## examples.
  result = my.filename
  
proc errorMsg*(my: TJsonParser): string = 
  ## Returns a helpful error message for the `jsonError <#TJsonEventKind>`_
  ## event.
  ##
  ## This proc will `assert <system.html#assert>`_ in debug builds when used
  ## with other event types. See `next() <#next>`_ for an usage example.
  assert(my.kind == jsonError)
  result = "$1($2, $3) Error: $4" % [
    my.filename, $getLine(my), $getColumn(my), errorMessages[my.err]]

proc errorMsgExpected*(my: TJsonParser, e: string): string = 
  ## Returns an error message "`e` expected".
  ##
  ## The message is in the same format as the other error messages which
  ## include the parser filename, line and column values. This is used by
  ## `raiseParseErr() <#raiseParseErr>`_ to raise  an `EJsonParsingError
  ## <#EJsonParsingError>`_.
  result = "$1($2, $3) Error: $4" % [
    my.filename, $getLine(my), $getColumn(my), e & " expected"]

proc handleHexChar(c: char, x: var int): bool = 
  result = true # Success
  case c
  of '0'..'9': x = (x shl 4) or (ord(c) - ord('0'))
  of 'a'..'f': x = (x shl 4) or (ord(c) - ord('a') + 10)
  of 'A'..'F': x = (x shl 4) or (ord(c) - ord('A') + 10)
  else: result = false # error

proc parseString(my: var TJsonParser): TTokKind =
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
        add(my.a, toUTF8(TRune(r)))
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
  
proc skip(my: var TJsonParser) = 
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

proc parseNumber(my: var TJsonParser) = 
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

proc parseName(my: var TJsonParser) = 
  var pos = my.bufpos
  var buf = my.buf
  if buf[pos] in IdentStartChars:
    while buf[pos] in IdentChars:
      add(my.a, buf[pos])
      inc(pos)
  my.bufpos = pos

proc getTok(my: var TJsonParser): TTokKind = 
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

proc next*(my: var TJsonParser) = 
  ## Retrieves the first/next event for the `JSON parser <#TJsonParser>`_.
  ##
  ## You are meant to call this method inside an infinite loop. After each
  ## call, check the result of the `kind() <#kind>`_ proc to know what has to
  ## be done next (eg. break out due to end of file). Here is a basic example
  ## which simply echoes all found elements by the parser:
  ##
  ## .. code-block:: nimrod
  ##   parser.open(stream, "<input string>")
  ##   while true:
  ##     parser.next
  ##     case parser.kind
  ##     of jsonError:
  ##       echo parser.errorMsg
  ##       break
  ##     of jsonEof: break
  ##     of jsonString: echo parser.str
  ##     of jsonInt: echo parser.getInt
  ##     of jsonFloat: echo parser.getFloat
  ##     of jsonTrue: echo "true"
  ##     of jsonFalse: echo "false"
  ##     of jsonNull: echo "null"
  ##     of jsonObjectStart: echo "{"
  ##     of jsonObjectEnd: echo "}"
  ##     of jsonArrayStart: echo "["
  ##     of jsonArrayEnd: echo "]"
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
      my.kind = TJsonEventKind(ord(tk))
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
      my.kind = TJsonEventKind(ord(tk))
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
      my.kind = TJsonEventKind(ord(tk))
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
      my.kind = TJsonEventKind(ord(tk))
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
  TJsonNodeKind* = enum ## Possible `JSON node <#TJsonNodeKind>`_ types. \
    ##
    ## To build nodes use the helper procs
    ## `newJNull() <#newJNull>`_,
    ## `newJBool() <#newJBool>`_,
    ## `newJInt() <#newJInt>`_,
    ## `newJFloat() <#newJFloat>`_,
    ## `newJString() <#newJString>`_,
    ## `newJObject() <#newJObject>`_ and
    ## `newJArray() <#newJArray>`_.
    JNull,
    JBool,
    JInt,
    JFloat,
    JString,
    JObject,
    JArray
    
  PJsonNode* = ref TJsonNode ## Reference to a `JSON node <#TJsonNode>`_.
  TJsonNode* {.final, pure, acyclic.} = object ## `Object variant \
    ## <manual.html#object-variants>`_ wrapping all possible JSON types.
    case kind*: TJsonNodeKind
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
      fields*: seq[tuple[key: string, val: PJsonNode]]
    of JArray:
      elems*: seq[PJsonNode]

  EJsonParsingError* = object of EInvalidValue ## Raised during JSON parsing. \
    ##
    ## Example:
    ##
    ## .. code-block:: nimrod
    ##   let smallJson = """{"test: 1.3, "key2": true}"""
    ##   try:
    ##     discard parseJson(smallJson)
    ##     # --> Bad JSON! input(1, 18) Error: : expected
    ##   except EJsonParsingError:
    ##     echo "Bad JSON! " & getCurrentExceptionMsg()

proc raiseParseErr*(p: TJsonParser, msg: string) {.noinline, noreturn.} =
  ## Raises an `EJsonParsingError <#EJsonParsingError>`_ exception.
  ##
  ## The message for the exception will be built passing the `msg` parameter to
  ## the `errorMsgExpected() <#errorMsgExpected>`_ proc.
  raise newException(EJsonParsingError, errorMsgExpected(p, msg))

proc newJString*(s: string): PJsonNode =
  ## Creates a new `JString PJsonNode <#TJsonNodeKind>`_.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = newJString("A string")
  ##   echo node
  ##   # --> "A string"
  ##
  ## Or you can use the shorter `%() proc <#%,string>`_.
  new(result)
  result.kind = JString
  result.str = s

proc newJStringMove(s: string): PJsonNode =
  new(result)
  result.kind = JString
  shallowCopy(result.str, s)

proc newJInt*(n: BiggestInt): PJsonNode =
  ## Creates a new `JInt PJsonNode <#TJsonNodeKind>`_.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = newJInt(900_100_200_300)
  ##   echo node
  ##   # --> 900100200300
  ##
  ## Or you can use the shorter `%() proc <#%,BiggestInt>`_.
  new(result)
  result.kind = JInt
  result.num  = n

proc newJFloat*(n: float): PJsonNode =
  ## Creates a new `JFloat PJsonNode <#TJsonNodeKind>`_.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = newJFloat(3.14)
  ##   echo node
  ##   # --> 3.14
  ##
  ## Or you can use the shorter `%() proc <#%,float>`_.
  new(result)
  result.kind = JFloat
  result.fnum  = n

proc newJBool*(b: bool): PJsonNode =
  ## Creates a new `JBool PJsonNode <#TJsonNodeKind>`_.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = newJBool(true)
  ##   echo node
  ##   # --> true
  ##
  ## Or you can use the shorter `%() proc <#%,bool>`_.
  new(result)
  result.kind = JBool
  result.bval = b

proc newJNull*(): PJsonNode =
  ## Creates a new `JNull PJsonNode <#TJsonNodeKind>`_.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = newJNull()
  ##   echo node
  ##   # --> null
  new(result)

proc newJObject*(): PJsonNode =
  ## Creates a new `JObject PJsonNode <#TJsonNodeKind>`_.
  ##
  ## The `PJsonNode <#PJsonNode>`_ will be initialized with an empty ``fields``
  ## sequence to which you can add new elements. Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = newJObject()
  ##   node.add("age", newJInt(24))
  ##   node.add("name", newJString("Minah"))
  ##   echo node
  ##   # --> { "age": 24,  "name": "Minah"}
  ##
  ## Or you can use the shorter `%() proc
  ## <#%,openArray[tuple[string,PJsonNode]]>`_.
  new(result)
  result.kind = JObject
  result.fields = @[]

proc newJArray*(): PJsonNode =
  ## Creates a new `JArray PJsonNode <#TJsonNodeKind>`_.
  ##
  ## The `PJsonNode <#PJsonNode>`_ will be initialized with an empty ``elems``
  ## sequence to which you can add new elements. Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = newJArray()
  ##   node.add(newJString("Mixing types"))
  ##   node.add(newJInt(42))
  ##   node.add(newJString("is madness"))
  ##   node.add(newJFloat(3.14))
  ##   echo node
  ##   # --> [ "Mixing types",  42,  "is madness",  3.14]
  ##
  ## Or you can use the shorter `%() proc <#%,openArray[PJsonNode]>`_.
  new(result)
  result.kind = JArray
  result.elems = @[]


proc `%`*(s: string): PJsonNode =
  ## Creates a new `JString PJsonNode <#TJsonNodeKind>`_.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = %"A string"
  ##   echo node
  ##   # --> "A string"
  ##
  ## This generic constructor is equivalent to the `newJString()
  ## <#newJString>`_ proc.
  new(result)
  result.kind = JString
  result.str = s

proc `%`*(n: BiggestInt): PJsonNode =
  ## Creates a new `JInt PJsonNode <#TJsonNodeKind>`_.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = %900_100_200_300
  ##   echo node
  ##   # --> 900100200300
  ##
  ## This generic constructor is equivalent to the `newJInt() <#newJInt>`_
  ## proc.
  new(result)
  result.kind = JInt
  result.num  = n

proc `%`*(n: float): PJsonNode =
  ## Creates a new `JFloat PJsonNode <#TJsonNodeKind>`_.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = %3.14
  ##   echo node
  ##   # --> 3.14
  ##
  ## This generic constructor is equivalent to the `newJFloat() <#newJFloat>`_
  ## proc.
  new(result)
  result.kind = JFloat
  result.fnum  = n

proc `%`*(b: bool): PJsonNode =
  ## Creates a new `JBool PJsonNode <#TJsonNodeKind>`_.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = %true
  ##   echo node
  ##   # --> true
  ##
  ## This generic constructor is equivalent to the `newJBool() <#newJBool>`_
  ## proc.
  new(result)
  result.kind = JBool
  result.bval = b

proc `%`*(keyVals: openArray[tuple[key: string, val: PJsonNode]]): PJsonNode =
  ## Creates a new `JObject PJsonNode <#TJsonNodeKind>`_.
  ##
  ## Unlike the `newJObject() <#newJObject>`_ proc, which returns an object
  ## that has to be further manipulated, you can use this generic constructor
  ## to create JSON objects with all their fields in one go. Example:
  ##
  ## .. code-block:: nimrod
  ##   let node = %[("age", %24), ("name", %"Minah")]
  ##   echo node
  ##   # --> { "age": 24,  "name": "Minah"}
  new(result)
  result.kind = JObject
  newSeq(result.fields, keyVals.len)
  for i, p in pairs(keyVals): result.fields[i] = p

proc `%`*(elements: openArray[PJsonNode]): PJsonNode =
  ## Creates a new `JArray PJsonNode <#TJsonNodeKind>`_.
  ##
  ## Unlike the `newJArray() <#newJArray>`_ proc, which returns an object
  ## that has to be further manipulated, you can use this generic constructor
  ## to create JSON arrays with all their values in one go. Example:
  ##
  ## .. code-block:: nimrod
  ##   let node = %[%"Mixing types", %42,
  ##     %"is madness", %3.14,]
  ##   echo node
  ##   # --> [ "Mixing types",  42,  "is madness",  3.14]
  new(result)
  result.kind = JArray
  newSeq(result.elems, elements.len)
  for i, p in pairs(elements): result.elems[i] = p

proc `==`* (a,b: PJsonNode): bool =
  ## Check two `PJsonNode <#PJsonNode>`_ nodes for equality.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   assert(%1 == %1)
  ##   assert(%1 != %2)
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

proc hash* (n:PJsonNode): THash =
  ## Computes the hash for a JSON node.
  ##
  ## The `THash <hashes.html#THash>`_ allows JSON nodes to be used as keys for
  ## `sets <sets.html>`_ or `tables <tables.html>`_. Example:
  ##
  ## .. code-block:: nimrod
  ##   import json, sets
  ##
  ##   var
  ##     uniqueValues = initSet[PJsonNode]()
  ##     values = %[%1, %2, %1, %2, %3]
  ##   for value in values.elems:
  ##     discard uniqueValues.containsOrIncl(value)
  ##   echo uniqueValues
  ##   # --> {1, 2, 3}
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

proc len*(n: PJsonNode): int = 
  ## Returns the number of children items for this `PJsonNode <#PJsonNode>`_.
  ##
  ## If `n` is a `JArray <#TJsonNodeKind>`_, it will return the number of
  ## elements.  If `n` is a `JObject <#TJsonNodeKind>`_, it will return the
  ## number of key-value pairs. For all other types this proc returns zero.
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   let
  ##     n1 = %[("age", %33), ("name", %"Sojin")]
  ##     n2 = %[%1, %2, %3, %4, %5, %6, %7]
  ##     n3 = %"Some odd string we have here"
  ##   echo n1.len # --> 2
  ##   echo n2.len # --> 7
  ##   echo n3.len # --> 0
  ##
  case n.kind
  of JArray: result = n.elems.len
  of JObject: result = n.fields.len
  else: discard

proc `[]`*(node: PJsonNode, name: string): PJsonNode =
  ## Gets a named field from a `JObject <#TJsonNodeKind>`_ `PJsonNode
  ## <#PJsonNode>`_.
  ##
  ## Returns the value for `name` or nil if `node` doesn't contain such a
  ## field.  This proc will `assert <system.html#assert>`_ in debug builds if
  ## `name` is ``nil`` or `node` is not a ``JObject``. On release builds it
  ## will likely crash. Example:
  ##
  ## .. code-block:: nimrod
  ##   let node = %[("age", %40), ("name", %"Britney")]
  ##   echo node["name"]
  ##   # --> "Britney"
  assert(not isNil(node))
  assert(node.kind == JObject)
  for key, item in items(node.fields):
    if key == name:
      return item
  return nil
  
proc `[]`*(node: PJsonNode, index: int): PJsonNode =
  ## Gets the `index` item from a `JArray <#TJsonNodeKind>`_ `PJsonNode
  ## <#PJsonNode>`_.
  ##
  ## Returns the specified item. Result is undefined if `index` is out of
  ## bounds.  This proc will `assert <system.html#assert>`_ in debug builds if
  ## `node` is ``nil`` or not a ``JArray``. Example:
  ##
  ## .. code-block:: nimrod
  ##   let node = %[%"Mixing types", %42,
  ##     %"is madness", %3.14,]
  ##   echo node[2]
  ##   # --> "is madness"
  assert(not isNil(node))
  assert(node.kind == JArray)
  return node.elems[index]

proc hasKey*(node: PJsonNode, key: string): bool =
  ## Returns `true` if `key` exists in a `JObject <#TJsonNodeKind>`_ `PJsonNode
  ## <#PJsonNode>`_.
  ##
  ## This proc will `assert <system.html#assert>`_ in debug builds if `node` is
  ## not a ``JObject``. On release builds it will likely crash. Example:
  ##
  ## .. code-block:: nimrod
  ##   let node = %[("age", %40), ("name", %"Britney")]
  ##   echo node.hasKey("email")
  ##   # --> false
  assert(node.kind == JObject)
  for k, item in items(node.fields):
    if k == key: return true

proc existsKey*(node: PJsonNode, key: string): bool {.deprecated.} = node.hasKey(key)
  ## Deprecated for `hasKey() <#hasKey>`_.

proc add*(father, child: PJsonNode) = 
  ## Adds `child` to a `JArray <#TJsonNodeKind>`_ `PJsonNode <#PJsonNode>`_
  ## `father` node.
  ##
  ## This proc will `assert <system.html#assert>`_ in debug builds if `node` is
  ## not a ``JArray``. On release builds it will likely crash. Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = %[%"Mixing types", %42]
  ##   node.add(%"is madness")
  ##   echo node
  ##   # --> false
  assert father.kind == JArray
  father.elems.add(child)

proc add*(obj: PJsonNode, key: string, val: PJsonNode) = 
  ## Adds ``(key, val)`` pair to a `JObject <#TJsonNodeKind>`_ `PJsonNode
  ## <#PJsonNode>`_ `obj` node.
  ##
  ## For speed reasons no check for duplicate keys is performed!  But ``[]=``
  ## performs the check.
  ##
  ## This proc will `assert <system.html#assert>`_ in debug builds if `node` is
  ## not a ``JObject``. On release builds it will likely crash. Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = newJObject()
  ##   node.add("age", newJInt(12))
  ##   # This is wrong! But we need speed…
  ##   node.add("age", newJInt(24))
  ##   echo node
  ##   # --> { "age": 12,  "age": 24}
  assert obj.kind == JObject
  obj.fields.add((key, val))

proc `[]=`*(obj: PJsonNode, key: string, val: PJsonNode) =
  ## Sets a field from a `JObject <#TJsonNodeKind>`_ `PJsonNode
  ## <#PJsonNode>`_ `obj` node.
  ##
  ## Unlike the `add() <#add,PJsonNode,string,PJsonNode>`_ proc this will
  ## perform a check for duplicate keys and replace existing values.
  ##
  ## This proc will `assert <system.html#assert>`_ in debug builds if `node` is
  ## not a ``JObject``. On release builds it will likely crash. Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = newJObject()
  ##   node["age"] = %12
  ##   # The new value replaces the previous one.
  ##   node["age"] = %24
  ##   echo node
  ##   # --> { "age": 24}
  assert(obj.kind == JObject)
  for i in 0..obj.fields.len-1:
    if obj.fields[i].key == key: 
      obj.fields[i].val = val
      return
  obj.fields.add((key, val))

proc `{}`*(node: PJsonNode, key: string): PJsonNode =
  ## Transverses the node and gets the given value. If any of the
  ## names does not exist, returns nil
  result = node
  if isNil(node): return nil
  result = result[key]

proc `{}=`*(node: PJsonNode, names: varargs[string], value: PJsonNode) =
  ## Transverses the node and tries to set the value at the given location
  ## to `value` If any of the names are missing, they are added
  var node = node
  for i in 0..(names.len-2):
    if isNil(node[names[i]]):
      node[names[i]] = newJObject()
    node = node[names[i]]
  node[names[names.len-1]] = value

proc delete*(obj: PJsonNode, key: string) =
  ## Deletes ``obj[key]`` preserving the order of the other (key, value)-pairs.
  ##
  ## If `key` doesn't exist in `obj` ``EInvalidIndex`` will be raised.  This
  ## proc will `assert <system.html#assert>`_ in debug builds if `node` is not
  ## a ``JObject``. On release builds it will likely crash. Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = %[("age", %37), ("name", %"Chris"), ("male", %false)]
  ##   echo node
  ##   # --> { "age": 37,  "name": "Chris",  "male": false}
  ##   node.delete("age")
  ##   echo node
  ##   # --> { "name": "Chris",  "male": false}
  assert(obj.kind == JObject)
  for i in 0..obj.fields.len-1:
    if obj.fields[i].key == key:
      obj.fields.delete(i)
      return
  raise newException(EInvalidIndex, "key not in object")

proc copy*(p: PJsonNode): PJsonNode =
  ## Performs a deep copy of `p`.
  ##
  ## Modifications to the copy won't affect the original.
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
  s.add(repeatChar(i))

proc newIndent(curr, indent: int, ml: bool): int =
  if ml: return curr + indent
  else: return indent

proc nl(s: var string, ml: bool) = 
  if ml: s.add("\n")

proc escapeJson*(s: string): string = 
  ## Converts a string `s` to its JSON representation.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   echo """name: "Torbjørn"""".escapeJson
  ##   # --> "name: \"Torbj\u00F8rn\""
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

proc toPretty(result: var string, node: PJsonNode, indent = 2, ml = true, 
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

proc pretty*(node: PJsonNode, indent = 2): string =
  ## Converts `node` to a pretty JSON representation.
  ##
  ## The representation will have indentation use multiple lines. Example:
  ##
  ## .. code-block:: nimrod
  ##   let node = %[("age", %33), ("name", %"Sojin")]
  ##   echo node
  ##   # --> { "age": 33,  "name": "Sojin"}
  ##   echo node.pretty
  ##   # --> {
  ##   #       "age": 33,
  ##   #       "name": "Sojin"
  ##   #     }
  result = ""
  toPretty(result, node, indent)

proc `$`*(node: PJsonNode): string =
  ## Converts `node` to its JSON representation on one line.
  result = ""
  toPretty(result, node, 1, false)

iterator items*(node: PJsonNode): PJsonNode =
  ## Iterator for the items of `node`.
  ##
  ## This proc will `assert <system.html#assert>`_ in debug builds if `node` is
  ## not a `JArray <#TJsonNodeKind>`_. On release builds it will likely crash.
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   let numbers = %[%1, %2, %3]
  ##   for n in numbers.items:
  ##     echo "Number ", n
  ##   ## --> Number 1
  ##   ##     Number 2
  ##   ##     Number 3
  assert node.kind == JArray
  for i in items(node.elems):
    yield i

iterator pairs*(node: PJsonNode): tuple[key: string, val: PJsonNode] =
  ## Iterator for the child elements of `node`.
  ##
  ## This proc will `assert <system.html#assert>`_ in debug builds if `node` is
  ## not a `JObject <#TJsonNodeKind>`_. On release builds it will likely crash.
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   var node = %[("age", %37), ("name", %"Chris")]
  ##   for key, value in node.pairs:
  ##     echo "Key: ", key, ", value: ", value
  ##   # --> Key: age, value: 37
  ##   #     Key: name, value: "Chris"
  assert node.kind == JObject
  for key, val in items(node.fields):
    yield (key, val)

proc eat(p: var TJsonParser, tok: TTokKind) = 
  if p.tok == tok: discard getTok(p)
  else: raiseParseErr(p, tokToStr[tok])

proc parseJson(p: var TJsonParser): PJsonNode = 
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
  proc parseJson*(s: PStream, filename: string): PJsonNode =
    ## Generic convenience proc to parse stream `s` into a `PJsonNode`.
    ##
    ## This wraps around `open() <#open>`_ and `next() <#next>`_ to return the
    ## full JSON DOM. Errors will be raised as exceptions, this requires the
    ## `filename` parameter to not be ``nil`` to avoid crashes.
    assert(not isNil(filename))
    var p: TJsonParser
    p.open(s, filename)
    discard getTok(p) # read first token
    result = p.parseJson()
    p.close()

  proc parseJson*(buffer: string): PJsonNode =
    ## Parses JSON from `buffer`.
    ##
    ## Specialized version around `parseJson(PStream, string)
    ## <#parseJson,PStream,string>`_. Example:
    ##
    ## .. code-block:: nimrod
    ##  let
    ##    smallJson = """{"test": 1.3, "key2": true}"""
    ##    jobj = parseJson(smallJson)
    ##  assert jobj.kind == JObject
    ##
    ##  assert jobj["test"].kind == JFloat
    ##  echo jobj["test"].fnum # --> 1.3
    ##
    ##  assert jobj["key2"].kind == JBool
    ##  echo jobj["key2"].bval # --> true
    result = parseJson(newStringStream(buffer), "input")

  proc parseFile*(filename: string): PJsonNode =
    ## Parses `file` into a `PJsonNode`.
    ##
    ## Specialized version around `parseJson(PStream, string)
    ## <#parseJson,PStream,string>`_.
    var stream = newFileStream(filename, fmRead)
    if stream == nil:
      raise newException(EIO, "cannot read from file: " & filename)
    result = parseJson(stream, filename)
else:
  from math import `mod`
  type
    TJSObject = object
  proc parseNativeJson(x: cstring): TJSObject {.importc: "JSON.parse".}

  proc getVarType(x): TJsonNodeKind =
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

  proc convertObject(x: TJSObject): PJsonNode =
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

  proc parseJson*(buffer: string): PJsonNode =
    return parseNativeJson(buffer).convertObject()

when false:
  import os
  var s = newFileStream(ParamStr(1), fmRead)
  if s == nil: quit("cannot open the file" & ParamStr(1))
  var x: TJsonParser
  open(x, s, ParamStr(1))
  while true:
    next(x)
    case x.kind
    of jsonError:
      Echo(x.errorMsg())
      break
    of jsonEof: break
    of jsonString, jsonInt, jsonFloat: echo(x.str)
    of jsonTrue: Echo("!TRUE")
    of jsonFalse: Echo("!FALSE")
    of jsonNull: Echo("!NULL")
    of jsonObjectStart: Echo("{")
    of jsonObjectEnd: Echo("}")
    of jsonArrayStart: Echo("[")
    of jsonArrayEnd: Echo("]")
    
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
    raise newException(EInvalidValue, "That line was expected to fail")
  except EInvalidIndex: echo()

  let testJson = parseJson"""{ "a": [1, 2, 3, 4], "b": "asd" }"""
  # nil passthrough
  assert(testJson{"doesnt_exist"}{"anything"}.isNil)
  testJson{["c", "d"]} = %true
  assert(testJson["c"]["d"].bval)

  # Bounds checking
  try:
    let a = testJson["a"][9]
    assert(false, "EInvalidIndex not thrown")
  except EInvalidIndex:
    discard
  try:
    let a = testJson["a"][-1]
    assert(false, "EInvalidIndex not thrown")
  except EInvalidIndex:
    discard
  try:
    assert(testJson["a"][0].num == 1, "Index doesn't correspond to its value")
  except:
    assert(false, "EInvalidIndex thrown for valid index")

  discard """
  while true:
    var json = stdin.readLine()
    var node = parse(json)
    echo(node)
    echo()
    echo()
  """
