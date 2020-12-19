#
#
#            Nim's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The `parsecfg` module implements a high performance configuration file
## parser. The configuration file's syntax is similar to the Windows `.ini`
## format, but much more powerful, as it is not a line based parser. String
## literals, raw string literals and triple quoted string literals are supported
## as in the Nim programming language.
##
## Example of how a configuration file may look like:
##
## .. include:: ../../doc/mytest.cfg
##     :literal:
##
## Here is an example of how to use the configuration file parser:
##
## .. code-block:: nim
##
##    import os, parsecfg, strutils, streams
##
##    var f = newFileStream(paramStr(1), fmRead)
##    if f != nil:
##      var p: CfgParser
##      open(p, f, paramStr(1))
##      while true:
##        var e = next(p)
##        case e.kind
##        of cfgEof: break
##        of cfgSectionStart:   ## a ``[section]`` has been parsed
##          echo("new section: " & e.section)
##        of cfgKeyValuePair:
##          echo("key-value-pair: " & e.key & ": " & e.value)
##        of cfgOption:
##          echo("command: " & e.key & ": " & e.value)
##        of cfgError:
##          echo(e.msg)
##      close(p)
##    else:
##      echo("cannot open: " & paramStr(1))
##
##
## Examples
## ========
##
## Configuration file example
## --------------------------
##
## .. code-block:: nim
##
##     charset = "utf-8"
##     [Package]
##     name = "hello"
##     --threads:on
##     [Author]
##     name = "lihf8515"
##     qq = "10214028"
##     email = "lihaifeng@wxm.com"
##
## Creating a configuration file
## -----------------------------
## .. code-block:: nim
##
##     import parsecfg
##     var dict=newConfig()
##     dict.setSectionKey("","charset","utf-8")
##     dict.setSectionKey("Package","name","hello")
##     dict.setSectionKey("Package","--threads","on")
##     dict.setSectionKey("Author","name","lihf8515")
##     dict.setSectionKey("Author","qq","10214028")
##     dict.setSectionKey("Author","email","lihaifeng@wxm.com")
##     dict.writeConfig("config.ini")
##
## Reading a configuration file
## ----------------------------
## .. code-block:: nim
##
##     import parsecfg
##     var dict = loadConfig("config.ini")
##     var charset = dict.getSectionValue("","charset")
##     var threads = dict.getSectionValue("Package","--threads")
##     var pname = dict.getSectionValue("Package","name")
##     var name = dict.getSectionValue("Author","name")
##     var qq = dict.getSectionValue("Author","qq")
##     var email = dict.getSectionValue("Author","email")
##     echo pname & "\n" & name & "\n" & qq & "\n" & email
##
## Modifying a configuration file
## ------------------------------
## .. code-block:: nim
##
##     import parsecfg
##     var dict = loadConfig("config.ini")
##     dict.setSectionKey("Author","name","lhf")
##     dict.writeConfig("config.ini")
##
## Deleting a section key in a configuration file
## ----------------------------------------------
## .. code-block:: nim
##
##     import parsecfg
##     var dict = loadConfig("config.ini")
##     dict.delSectionKey("Author","email")
##     dict.writeConfig("config.ini")
## 
## Supported INI File structure
## ----------------------------
## The examples below are supported:
##

# taken from https://docs.python.org/3/library/configparser.html#supported-ini-file-structure
runnableExamples:
  import streams

  var dict = loadConfig(newStringStream("""[Simple Values]
    key=value
    spaces in keys=allowed
    spaces in values=allowed as well
    spaces around the delimiter = obviously
    you can also use : to delimit keys from values
    [All Values Are Strings]
    values like this: 19990429
    or this: 3.14159265359
    are they treated as numbers : no
    integers floats and booleans are held as: strings
    can use the API to get converted values directly: true
    [No Values]
    key_without_value
    # empty string value is not allowed =
    [ Seletion A   ]
    space around section name will be ignored
    [You can use comments]
    # like this
    ; or this
    # By default only in an empty line.
    # Inline comments can be harmful because they prevent users
    # from using the delimiting characters as parts of values.
    # That being said, this can be customized.
        [Sections Can Be Indented]
            can_values_be_as_well = True
            does_that_mean_anything_special = False
            purpose = formatting for readability
            # Did I mention we can indent comments, too?
    """)
  )

  let section1 = "Simple Values"
  doAssert dict.getSectionValue(section1, "key") == "value"
  doAssert dict.getSectionValue(section1, "spaces in keys") == "allowed"
  doAssert dict.getSectionValue(section1, "spaces in values") == "allowed as well"
  doAssert dict.getSectionValue(section1, "spaces around the delimiter") == "obviously"
  doAssert dict.getSectionValue(section1, "you can also use") == "to delimit keys from values"

  let section2 = "All Values Are Strings"
  doAssert dict.getSectionValue(section2, "values like this") == "19990429"
  doAssert dict.getSectionValue(section2, "or this") == "3.14159265359"
  doAssert dict.getSectionValue(section2, "are they treated as numbers") == "no"
  doAssert dict.getSectionValue(section2, "integers floats and booleans are held as") == "strings"
  doAssert dict.getSectionValue(section2, "can use the API to get converted values directly") == "true"

  let section3 = "Seletion A"
  doAssert dict.getSectionValue(section3, 
    "space around section name will be ignored", "not an empty value") == ""

  let section4 = "Sections Can Be Indented"
  doAssert dict.getSectionValue(section4, "can_values_be_as_well") == "True"
  doAssert dict.getSectionValue(section4, "does_that_mean_anything_special") == "False"
  doAssert dict.getSectionValue(section4, "purpose") == "formatting for readability"

import strutils, lexbase, streams, tables
import std/private/decode_helpers

include "system/inclrtl"

type
  CfgEventKind* = enum ## enumeration of all events that may occur when parsing
    cfgEof,            ## end of file reached
    cfgSectionStart,   ## a `[section]` has been parsed
    cfgKeyValuePair,   ## a `key=value` pair has been detected
    cfgOption,         ## a `--key=value` command line option
    cfgError           ## an error occurred during parsing

  CfgEvent* = object of RootObj ## describes a parsing event
    case kind*: CfgEventKind    ## the kind of the event
    of cfgEof: nil
    of cfgSectionStart:
      section*: string          ## `section` contains the name of the
                                ## parsed section start (syntax: `[section]`)
      sectionRelated*: SectionRelated
                                ## 'sectionRelated' is the other part of `section`
                                ## This field is set to keep the original
                                ## layout of the file from being ignored,
                                ## such as blank, comments, etc., 
                                ## after modification.
    of cfgKeyValuePair, cfgOption:
      key*, value*: string      ## contains the (key, value) pair if an option
                                ## of the form `--key: value` or an ordinary
                                ## `key= value` pair has been parsed.
                                ## `value==""` if it was not specified in the
                                ## configuration file.
      keyValueRelated*: KeyValueRelated
                                ## 'keyValueRelated' is the other part of `key` and
                                ## `value`. This field is set to keep the
                                ## original layout of the file from being
                                ## ignored, such as blank, comments, etc.,
                                ## after modification.

    of cfgError:                ## the parser encountered an error: `msg`
      msg*: string              ## contains the error message. No exceptions
                                ## are thrown if a parse error occurs.

  TokKind = enum
    tkInvalid, tkEof, tkSymbol, tkEquals, tkColon, tkBracketLe, tkBracketRi,
    tkDashDash, tkDash, tkBlankAndComment

  Token = object    # a token
    kind: TokKind   # the type of the token
    literal: string # the parsed (string) literal

  SectionRelated = tuple
    sectionStringKind: StringKind # The kind of the current 'section' string.
    tokenFrontBlank: string     # Blank in front of the `[`
    tokenLeft: string           # `[`
    sectionFrontBlank: string   # Blank in front of the `section`
    sectionRearBlank: string    # Blank after `section`
    tokenRight: string          # `]`
    tokenRearBlank: string      # Blank after `]`
    comment: string

  KeyValueRelated = tuple
    keyStringKind: StringKind   # The kind of the current `key` string.
    valueStringKind: StringKind # The kind of the current `value` string.
    keyFrontBlank: string       # Blank in front of the `key`
    keyRearBlank: string        # Blank after `key`
    token: string               # `=` or `:`
    valFrontBlank: string       # Blank in front of the `value`
    valRearBlank: string        # Blank after `value`
    comment: string

  StringKind = enum             # The kind of the string.
    skSymbol,                   # not enclosed in double quotes
    skString,                   # enclosed in double quotes
    skRawString,                # string of original literals
    skLongString                # long string enclosed in three quotes
 
  CfgParser* = object of BaseLexer ## the parser object.
    tok: Token
    filename: string
    commentSymbol: set[char]   # This field is set to allow the user to
                                # customize the comment symbol.
    blankAndComment: tuple[blank: string, comment: string]
                                # Blank and comments currently read
                                # by the parser

# implementation

const
  SymChars = {'a'..'z', 'A'..'Z', '0'..'9', '_', ' ', '\t', '\x80'..'\xFF',
              '.', '/', '\\', '-'}

proc rawGetTok(c: var CfgParser) {.gcsafe.}

proc open*(c: var CfgParser, input: Stream, filename: string,
           lineOffset = 0) {.rtl, extern: "npc$1".} =
  ## Initializes the parser with an input stream. `Filename` is only used
  ## for nice error messages. `lineOffset` can be used to influence the line
  ## number information in the generated error messages.
  lexbase.open(c, input)
  c.filename = filename
  c.tok.kind = tkInvalid
  c.tok.literal = ""
  c.commentSymbol = {'#', ';'} # Default comment symbol.
  inc(c.lineNumber, lineOffset)
  rawGetTok(c)

proc close*(c: var CfgParser) {.rtl, extern: "npc$1".} =
  ## Closes the parser `c` and its associated input stream.
  lexbase.close(c)

proc getColumn*(c: CfgParser): int {.rtl, extern: "npc$1".} =
  ## Gets the current column the parser has arrived at.
  result = getColNumber(c, c.bufpos)

proc getLine*(c: CfgParser): int {.rtl, extern: "npc$1".} =
  ## Gets the current line the parser has arrived at.
  result = c.lineNumber

proc getFilename*(c: CfgParser): string {.rtl, extern: "npc$1".} =
  ## Gets the filename of the file that the parser processes.
  result = c.filename

proc errorStr*(c: CfgParser, msg: string): string {.rtl, extern: "npc$1".} =
  ## Returns a properly formatted error message containing current line and
  ## column information.
  result = `%`("$1($2, $3) Error: $4",
                [c.filename, $getLine(c), $getColumn(c), msg])

proc warningStr*(c: CfgParser, msg: string): string {.rtl, extern: "npc$1".} =
  ## Returns a properly formatted warning message containing current line and
  ## column information.
  result = `%`("$1($2, $3) Warning: $4",
                [c.filename, $getLine(c), $getColumn(c), msg])

proc ignoreMsg*(c: CfgParser, e: CfgEvent): string {.rtl, extern: "npc$1".} =
  ## Returns a properly formatted warning message containing that
  ## an entry is ignored.
  case e.kind
  of cfgSectionStart: result = c.warningStr("section ignored: " & e.section)
  of cfgKeyValuePair: result = c.warningStr("key ignored: " & e.key)
  of cfgOption:
    result = c.warningStr("command ignored: " & e.key & ": " & e.value)
  of cfgError: result = e.msg
  of cfgEof: result = ""

proc handleDecChars(c: var CfgParser, xi: var int) =
  while c.buf[c.bufpos] in {'0'..'9'}:
    xi = (xi * 10) + (ord(c.buf[c.bufpos]) - ord('0'))
    inc(c.bufpos)

proc handleCRLF(c: var CfgParser, pos: int): int =
  case c.buf[pos]
  of '\c': result = lexbase.handleCR(c, pos)
  of '\L': result = lexbase.handleLF(c, pos)
  else: result = pos

proc getEscapedChar(c: var CfgParser) =
  inc(c.bufpos) # skip '\'
  case c.buf[c.bufpos]
  of 'n', 'N':
    add(c.tok.literal, "\n")
    inc(c.bufpos)
  of 'r', 'R', 'c', 'C':
    add(c.tok.literal, '\c')
    inc(c.bufpos)
  of 'l', 'L':
    add(c.tok.literal, '\L')
    inc(c.bufpos)
  of 'f', 'F':
    add(c.tok.literal, '\f')
    inc(c.bufpos)
  of 'e', 'E':
    add(c.tok.literal, '\e')
    inc(c.bufpos)
  of 'a', 'A':
    add(c.tok.literal, '\a')
    inc(c.bufpos)
  of 'b', 'B':
    add(c.tok.literal, '\b')
    inc(c.bufpos)
  of 'v', 'V':
    add(c.tok.literal, '\v')
    inc(c.bufpos)
  of 't', 'T':
    add(c.tok.literal, '\t')
    inc(c.bufpos)
  of '\'', '"':
    add(c.tok.literal, c.buf[c.bufpos])
    inc(c.bufpos)
  of '\\':
    add(c.tok.literal, '\\')
    inc(c.bufpos)
  of 'x', 'X':
    inc(c.bufpos)
    var xi = 0
    if handleHexChar(c.buf[c.bufpos], xi):
      inc(c.bufpos)
      if handleHexChar(c.buf[c.bufpos], xi):
        inc(c.bufpos)
    add(c.tok.literal, chr(xi))
  of '0'..'9':
    var xi = 0
    handleDecChars(c, xi)
    if (xi <= 255): add(c.tok.literal, chr(xi))
    else: c.tok.kind = tkInvalid
  else: c.tok.kind = tkInvalid

# =========================================================================
proc skip(c: var CfgParser) =
  ## Save the currently read blank and comment.
  var pos = c.bufpos
  var blank = ""
  var comment = ""
  while true:
    if c.buf[pos] == ' ' or c.buf[pos] == '\t':
      blank.add(c.buf[pos])
      inc(pos)
    elif c.commentSymbol.contains(c.buf[pos]):
      while not (c.buf[pos] in {'\c', '\L', lexbase.EndOfFile}):
        comment.add(c.buf[pos])
        inc(pos)
    else:
      break
  c.bufpos = pos
  c.blankAndComment = (blank, comment) 

proc rawGetTok(c: var CfgParser) =
  ## When the token is read, it stops and saves the blank and comments
  ## that are currently read for use.
  setLen(c.tok.literal, 0)
  skip(c)
  case c.buf[c.bufpos]
  of '\c', '\L':
    if c.tok.kind == tkInvalid: # Reads blank and comment lines
      c.tok.kind = tkBlankAndComment
    var pos = c.bufpos
    pos = handleCRLF(c, c.bufpos)
    c.bufpos = pos
    c.tok.literal = "\n"
  of '=':
    c.tok.kind = tkEquals
    inc(c.bufpos)
    c.tok.literal = "="
  of '-':
    inc(c.bufpos)
    if c.buf[c.bufpos] == '-':
      inc(c.bufpos)
      c.tok.kind = tkDashDash
      c.tok.literal = "--"
    else:
      c.tok.kind = tkDash
      c.tok.literal = "-"
  of ':':
    c.tok.kind = tkColon
    inc(c.bufpos)
    c.tok.literal = ":"
  of '[':
    c.tok.kind = tkBracketLe
    inc(c.bufpos)
    c.tok.literal = "["
  of ']':
    c.tok.kind = tkBracketRi
    inc(c.bufpos)
    c.tok.literal = "]"
  of '"', 'r', 'R':
    c.tok.kind = tkSymbol
  of lexbase.EndOfFile:
    c.tok.kind = tkEof
    c.tok.literal = "[EOF]"
  else:
    c.tok.kind = tkSymbol

proc getSymbol(c: var CfgParser, contentType: string) =
  ## Gets a string and discards any whitespace after a valid character.
  var pos = c.bufpos
  while true:
    case contentType
    of "value":
      if c.commentSymbol.contains(c.buf[pos]):
        break
      elif c.buf[pos] in {'\c', '\L', lexbase.EndOfFile}:
        break
      else:
        add(c.tok.literal, c.buf[pos])
        inc(pos)
    of "key":
      if c.buf[pos] == '=' or c.buf[pos] == ':':
        break
      elif c.buf[pos] in {'\c', '\L', lexbase.EndOfFile}:
        break
      else:
        add(c.tok.literal, c.buf[pos])
        inc(pos)
    of "section":
      if c.buf[pos] == ']':
        break
      elif c.buf[pos] in {'\c', '\L', lexbase.EndOfFile}:
        break
      else:
        add(c.tok.literal, c.buf[pos])
        inc(pos)

  while c.tok.literal.len > 0 and (c.tok.literal[^1] == ' ' or
                                   c.tok.literal[^1] == '\t'):
    c.tok.literal.setLen(c.tok.literal.len - 1)
    dec(pos)
  c.bufpos = pos
  c.tok.kind = tkSymbol

proc getString(c: var CfgParser, stringKind: StringKind) =
  ## Gets the contents of `section` or `key` or `value`.
  var pos = c.bufpos
  c.tok.kind = tkSymbol
  case stringKind
  of skLongString:
    # long string literal
    inc(pos, 3) # skip ""
    pos = handleCRLF(c, pos) # skip leading newline
    while true:
      case c.buf[pos]
      of '"':
        if (c.buf[pos + 1] == '"') and (c.buf[pos + 2] == '"'): break
        add(c.tok.literal, '"')
        inc(pos)
      of '\c', '\L':
        pos = handleCRLF(c, pos)
        add(c.tok.literal, "\n")
      of lexbase.EndOfFile:
        c.tok.kind = tkInvalid
        break
      else:
        add(c.tok.literal, c.buf[pos])
        inc(pos)
    c.bufpos = pos + 3 # skip the three """
  of skRawString:
    # raw string literal
    inc(pos, 2) # skip r"
    while true:
      case c.buf[pos]
      of '"':
        break
      of '\c', '\L', lexbase.EndOfFile:
        c.tok.kind = tkInvalid
        break
      else:
        add(c.tok.literal, c.buf[pos])
        inc(pos)
    c.bufpos = pos + 1 # skip the three "
  of skString:
    # enclosed in double quotes
    inc(pos, 1) # skip "
    while true:
      case c.buf[pos]
      of '"':
        break
      of '\c', '\L', lexbase.EndOfFile:
        c.tok.kind = tkInvalid
        break
      of '\\':
        c.bufpos = pos
        getEscapedChar(c)
        pos = c.bufpos
      else:
        add(c.tok.literal, c.buf[pos])
        inc(pos)
    c.bufpos = pos + 1 # skip the three "
  else: discard

proc getContent(c: var CfgParser, cfgEvent: var CfgEvent,
                contentType: string) =
  ## Gets the contents of `section` or `key` or `value`.
  var stringKind: StringKind
  # long string literal
  if (c.buf[c.bufpos] == '"') and (c.buf[c.bufpos + 1] == '"') and
     (c.buf[c.bufpos + 2] == '"'):
    stringKind = skLongString
    if contentType == "key":
      cfgEvent.keyValueRelated.keyStringKind = stringKind
    elif contentType == "value":
      cfgEvent.keyValueRelated.valueStringKind = stringKind
    else:
      cfgEvent.sectionRelated.sectionStringKind = stringKind
    getString(c, stringKind)
    if c.tok.kind == tkInvalid:
      cfgEvent = CfgEvent(kind: cfgError, msg:
                          errorStr(c, "\"\"\" expected, but not found"))
      return
    if contentType == "key":
      cfgEvent.key = c.tok.literal
    elif contentType == "value":
      cfgEvent.value = c.tok.literal
    else:
      cfgEvent.section = c.tok.literal
  # raw string literal
  elif (c.buf[c.bufpos] == 'r') and (c.buf[c.bufpos + 1] == '"'):
    stringKind = skRawString
    if contentType == "key":
      cfgEvent.keyValueRelated.keyStringKind = stringKind
    elif contentType == "value":
      cfgEvent.keyValueRelated.valueStringKind = stringKind
    else:
      cfgEvent.sectionRelated.sectionStringKind = stringKind
    getString(c, stringKind)
    if c.tok.kind == tkInvalid:
      cfgEvent = CfgEvent(kind: cfgError, msg:
                          errorStr(c, "r\" expected, but not found"))
      return
    if contentType == "key":
      cfgEvent.key = c.tok.literal
    elif contentType == "value":
      cfgEvent.value = c.tok.literal
    else:
      cfgEvent.section = c.tok.literal
  # enclosed in double quotes
  elif (c.buf[c.bufpos] == '"'):
    stringKind = skString
    if contentType == "key":
      cfgEvent.keyValueRelated.keyStringKind = stringKind
    elif contentType == "value":
      cfgEvent.keyValueRelated.valueStringKind = stringKind
    else:
      cfgEvent.sectionRelated.sectionStringKind = stringKind
    getString(c, stringKind)
    if c.tok.kind == tkInvalid:
      cfgEvent = CfgEvent(kind: cfgError, msg:
                          errorStr(c, "\" expected, but not found"))
      return
    if contentType == "key":
      cfgEvent.key = c.tok.literal
    elif contentType == "value":
      cfgEvent.value = c.tok.literal
    else:
      cfgEvent.section = c.tok.literal
  else: # not enclosed in double quotes
    stringKind = skSymbol
    if contentType == "key":
      cfgEvent.keyValueRelated.keyStringKind = stringKind
    elif contentType == "value":
      cfgEvent.keyValueRelated.valueStringKind = stringKind
    else:
      cfgEvent.sectionRelated.sectionStringKind = stringKind
    getSymbol(c, contentType)
    if contentType == "key":
      cfgEvent.key = c.tok.literal
    elif contentType == "value":
      cfgEvent.value = c.tok.literal
    else:
      cfgEvent.section = c.tok.literal

proc getSection(c: var CfgParser, kind: CfgEventKind): CfgEvent =
  ## Gets the entire contents of the current section.
  ## include blank and comment.
  result = CfgEvent(kind: cfgSectionStart)
  result.sectionRelated.sectionStringKind = skSymbol
  result.sectionRelated.tokenFrontBlank = c.blankAndComment.blank
  result.sectionRelated.tokenLeft = c.tok.literal # Get `[`
  rawGetTok(c) # Get the blank and comment in front of section
  result.sectionRelated.sectionFrontBlank = c.blankAndComment.blank
  if c.tok.kind == tkSymbol:
    getContent(c, result, "section") # Get the contents of `section`
    if result.kind == cfgError: # Error parsing, return
      return
    result.section = c.tok.literal
    rawGetTok(c) # Get the blank after section
    result.sectionRelated.sectionRearBlank = c.blankAndComment.blank
    if c.tok.kind == tkBracketRi:
      result.sectionRelated.tokenRight = c.tok.literal
      rawGetTok(c) # Gets blank and comment after `]`
      if c.tok.kind == tkEof:
        return
      if c.tok.literal == "\n":
        result.sectionRelated.tokenRearBlank = c.blankAndComment.blank
        result.sectionRelated.comment = c.blankAndComment.comment
      else:
        result = CfgEvent(kind: cfgError,
          msg: errorStr(c, "not expected character:" & c.buf[c.bufpos]))
    else:
      result = CfgEvent(kind: cfgError,
        msg: errorStr(c, "] expected, but found:" & c.tok.literal))
  else:
    result = CfgEvent(kind: cfgError,
      msg: errorStr(c, "symbol expected, but found:" & c.tok.literal))
  c.tok.kind = tkInvalid

proc getKeyValuePair(c: var CfgParser, kind: CfgEventKind): CfgEvent =
  ## Gets the entire contents of 'key' or 'value'.
  ## include blank and comment.
  if c.tok.kind == tkSymbol:
    result = CfgEvent(kind: kind)
    result.keyValueRelated.keyFrontBlank = c.blankAndComment.blank
    getContent(c, result, "key") # Gets the contents of 'key'
    if result.kind == cfgError: # Error parsing, return
      return
    rawGetTok(c) # Get the blank and comment after key
    if c.tok.kind == tkEof:
      return
    if c.tok.literal == "=" or c.tok.literal == ":": # Get token `=` or `:`
      result.keyValueRelated.keyRearBlank = c.blankAndComment.blank
      result.keyValueRelated.token = c.tok.literal
      rawGetTok(c) # Get the blank before value
      if c.tok.kind == tkEof:
        return
      if c.tok.literal != "\n":
        result.keyValueRelated.valFrontBlank = c.blankAndComment.blank
        getContent(c, result, "value") # Gets the contents of 'value'
        if result.kind == cfgError: # Error parsing, return
          return
        rawGetTok(c) # Get the blank and comment after value
      result.keyValueRelated.valRearBlank = c.blankAndComment.blank
      result.keyValueRelated.comment = c.blankAndComment.comment # End-of-line comments
    elif c.tok.literal == "\n":
      result.keyValueRelated.valRearBlank = c.blankAndComment.blank
      result.keyValueRelated.comment = c.blankAndComment.comment # End-of-line comments
    elif c.tok.literal == "":
      result = CfgEvent(kind: cfgError,
        msg: errorStr(c, "not expected character:" & c.buf[c.bufpos]))
    elif c.commentSymbol.contains(c.tok.literal[0]):
      result.keyValueRelated.valRearBlank = c.blankAndComment.blank
      result.keyValueRelated.comment = c.blankAndComment.comment # End-of-line comments
    else:
      result = CfgEvent(kind: cfgError,
        msg: errorStr(c, "not expected character:" & c.buf[c.bufpos]))
  else:
    result = CfgEvent(kind: cfgError,
      msg: errorStr(c, "symbol expected, but found:" & c.tok.literal))

proc next*(c: var CfgParser): CfgEvent {.rtl, extern: "npc$1".} =
  ## Retrieves the first/next event. This controls the parser.
  case c.tok.kind
  of tkBlankAndComment:
    result = CfgEvent(kind: cfgKeyValuePair)
    # Generates `key` for blank and comment lines.
    result.keyValueRelated.keyStringKind = skSymbol
    result.keyValueRelated.valueStringKind = skSymbol
    result.key = "BlankAndCommentLine" & $c.getLine()
    result.value = ""
    result.keyValueRelated.valRearBlank = c.blankAndComment.blank
    result.keyValueRelated.comment = c.blankAndComment.comment
    c.tok.kind = tkInvalid
    rawGetTok(c)
  of tkEof:
    result = CfgEvent(kind: cfgEof)
  of tkDash, tkDashDash:
    c.tok.kind = tkSymbol
    result = getKeyValuePair(c, cfgOption)
    c.tok.kind = tkInvalid
    rawGetTok(c)
  of tkSymbol:
    result = getKeyValuePair(c, cfgKeyValuePair)
    c.tok.kind = tkInvalid
    rawGetTok(c)
  of tkBracketLe:
    result = getSection(c, cfgSectionStart)
    c.tok.kind = tkInvalid
    rawGetTok(c)
  of tkInvalid, tkEquals, tkColon, tkBracketRi:
    result = CfgEvent(kind: cfgError,
      msg: errorStr(c, "invalid token: " & c.tok.literal))
    c.tok.kind = tkInvalid
    rawGetTok(c)

# ---------------- Configuration file related operations ----------------
type
  Config* = OrderedTableRef[string, SectionItem]

  SectionItem = tuple
    sectionRelated: SectionRelated
    keyValue: OrderedTableRef[string, KeyValueItem]

  KeyValueItem = tuple
    value: string
    keyValueRelated: KeyValueRelated

proc newConfig*(): Config =
  ## Creates a new configuration table.
  ## Useful when wanting to create a configuration file.
  result = newOrderedTable[string, SectionItem]()

proc loadConfig*(stream: Stream, filename: string = "[stream]",
                 commentSymbol = {'#', ';'}): Config =
  ## Loads the specified configuration from stream into a new Config instance.
  ## `filename` parameter is only used for nicer error messages.
  ## `commentSymbol` default value is `#;`
  var dict = newOrderedTable[string, SectionItem]()
  var curSection = "" ## Current section,
                      ## the default value of the current section is "",
                      ## which means that the current section is a common
  var p: CfgParser
  open(p, stream, filename)
  p.commentSymbol = commentSymbol
  while true:
    var e = next(p)
    case e.kind
    of cfgEof:
      break
    of cfgSectionStart: # Only look for the first time the Section
      var tp: SectionItem
      var t = OrderedTableRef[string, KeyValueItem]()
      curSection = e.section
      tp.sectionRelated = e.sectionRelated
      tp.keyValue = t
      dict[curSection] = tp
    of cfgKeyValuePair:
      var tp: SectionItem
      var t = OrderedTableRef[string, KeyValueItem]()
      if dict.hasKey(curSection):
        tp = dict[curSection]
        t = tp.keyValue
      t[e.key] = (e.value, e.keyValueRelated)
      tp.keyValue = t
      dict[curSection] = tp
    of cfgOption:
      var tp: SectionItem
      var t = OrderedTableRef[string, KeyValueItem]()
      if dict.hasKey(curSection):
        tp = dict[curSection]
        t = tp.keyValue
      t[e.key] = (e.value, e.keyValueRelated)
      tp.keyValue = t
      dict[curSection] = tp
    of cfgError:
      close(p)
      raise newException(Exception, e.msg)
  close(p)
  result = dict

proc loadConfig*(filename: string, commentSymbol = {'#', ';'}): Config =
  ## Loads the specified configuration file into a new Config instance.
  ## `commentSymbol` default value is `#;`
  let file = open(filename, fmRead)
  let fileStream = newFileStream(file)
  defer: fileStream.close()
  result = fileStream.loadConfig(filename, commentSymbol)

proc replace(s: string): string =
  var d = ""
  var i = 0
  while i < s.len():
    if s[i] == '\\':
      d.add(r"\\")
    elif s[i] == '\c' and s[i+1] == '\l':
      d.add(r"\c\l")
      inc(i)
    elif s[i] == '\c':
      d.add(r"\n")
    elif s[i] == '\l':
      d.add(r"\n")
    else:
      d.add(s[i])
    inc(i)
  result = d

proc writeConfig*(dict: Config, stream: Stream) =
  ## Writes the contents of the table to the specified stream.
  for section, tp in dict.pairs():
    var sectionRelated = tp.sectionRelated
    var keyValue = tp.keyValue
    var s = ""
    if section != "": ## Not general section
      s.add(sectionRelated.tokenFrontBlank & sectionRelated.tokenLeft &
        sectionRelated.sectionFrontBlank)
      if sectionRelated.sectionStringKind == skLongString:
        s.add("\"\"\"" & section & "\"\"\"")
      elif sectionRelated.sectionStringKind == skRawString:
        s.add("r\"" & section & "\"")
      elif sectionRelated.sectionStringKind == skString:
        s.add("\"" & section & "\"")
      else:
        s.add(section)
      s.add(sectionRelated.sectionRearBlank & sectionRelated.tokenRight &
            sectionRelated.tokenRearBlank & sectionRelated.comment)
      stream.writeLine(s)
    for key, kv in keyValue.pairs():
      var newKey = ""
      s = ""
      s.add(kv.keyValueRelated.keyFrontBlank)
      if not key.startsWith("BlankAndCommentLine"): # blank and comment line
        newKey = key
      if kv.keyValueRelated.keyStringKind == skLongString:
        if newKey.startsWith("--"):
          s.add("--" & "\"\"\"" & newKey[2..^1] & "\"\"\"")
        elif newKey.startsWith("-"):
          s.add("-" & "\"\"\"" & newKey[1..^1] & "\"\"\"")
        else:
          s.add("\"\"\"" & newKey & "\"\"\"")
      elif kv.keyValueRelated.keyStringKind == skRawString:
        if newKey.startsWith("--"):
          s.add("--" & "r\"" & newKey[2..^1] & "\"")
        elif newKey.startsWith("-"):
          s.add("-" & "r\"" & newKey[1..^1] & "\"")
        else:
          s.add("r\"" & newKey & "\"")
      elif kv.keyValueRelated.keyStringKind == skString:
        if newKey.startsWith("--"):
          s.add("--" & "\"" & replace(newKey[2..^1]) & "\"")
        elif newKey.startsWith("-"):
          s.add("-" & "\"" & replace(newKey[1..^1]) & "\"")
        else:
          s.add("\"" & replace(newKey) & "\"")
      else:
        s.add(newKey)
      s.add(kv.keyValueRelated.keyRearBlank)
      s.add(kv.keyValueRelated.token)
      s.add(kv.keyValueRelated.valFrontBlank)
      if kv.keyValueRelated.valueStringKind == skLongString:
        s.add("\"\"\"" & kv.value & "\"\"\"")
      elif kv.keyValueRelated.valueStringKind == skRawString:
        s.add("r\"" & kv.value & "\"")
      elif kv.keyValueRelated.valueStringKind == skString:
        s.add("\"" & replace(kv.value) & "\"")
      else:
        s.add(kv.value)
      s.add(kv.keyValueRelated.valRearBlank)
      s.add(kv.keyValueRelated.comment)
      stream.writeLine(s)

proc `$`*(dict: Config): string =
  ## Writes the contents of the table to string.
  let stream = newStringStream()
  defer: stream.close()
  dict.writeConfig(stream)
  result = stream.data

proc writeConfig*(dict: Config, filename: string) =
  ## Writes the contents of the table to the specified configuration file.
  let file = open(filename, fmWrite)
  defer: file.close()
  let fileStream = newFileStream(file)
  dict.writeConfig(fileStream)

proc getSectionValue*(dict: Config, section, key: string, defaultVal = ""): string =
  ## Gets the key value of the specified Section.
  ## Returns the specified default value if the specified key does not exist.
  if dict.hasKey(section):
    let kv = dict[section].keyValue
    if kv.hasKey(key):
      result = kv[key].value
    else:
      result = defaultVal
  else:
    result = defaultVal

proc setSectionKey*(dict: var Config, section, key, value: string) =
  ## Sets the Key value of the specified Section.
  var tp: SectionItem
  var kv = OrderedTableRef[string, KeyValueItem]()
  var kvi: KeyValueItem
  if dict.hasKey(section): # modify section
    tp = dict[section]
    kv = tp.keyValue
    if kv.hasKey(key): # modify key
      kvi = kv[key]
      kvi.value = value
    else: # add key
      if key.startsWith("--") or key.startsWith("-"):
        kvi.keyValueRelated.token = ":"
      else:
        kvi.keyValueRelated.token = "="
      kvi.value = value
      if not allCharsInSet(value, SymChars): ## Non system character
        kvi.keyValueRelated.valueStringKind = skString
      else:
        kvi.keyValueRelated.valueStringKind = skSymbol
    kv[key] = kvi
    tp.keyValue = kv
    dict[section] = tp
  else: # add section
    if key.startsWith("--") or key.startsWith("-"):
      kvi.keyValueRelated.token = ":"
    else:
      kvi.keyValueRelated.token = "="
    if not allCharsInSet(value, SymChars): ## Non system character
      kvi.keyValueRelated.valueStringKind = skString
    else:
      kvi.keyValueRelated.valueStringKind = skSymbol
    kvi.value = value
    kv[key] = kvi
    tp.keyValue = kv
    tp.sectionRelated.tokenLeft = "["
    tp.sectionRelated.tokenRight = "]"
    dict[section] = tp

proc delSection*(dict: var Config, section: string) =
  ## Deletes the specified section and all of its sub keys.
  dict.del(section)

proc delSectionKey*(dict: var Config, section, key: string) =
  ## Deletes the key of the specified section.
  if dict.hasKey(section):
    if dict[section].keyValue.hasKey(key):
      if dict[section].keyValue.len() == 1:
        dict.del(section)
      else:
        dict[section].keyValue.del(key)
