#
#
#            Nim's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``parsecfg`` module implements a high performance configuration file
## parser. The configuration file's syntax is similar to the Windows ``.ini``
## format, but much more powerful, as it is not a line based parser. String
## literals, raw string literals and triple quoted string literals are supported
## as in the Nim programming language.
## The module supports annotation statements, does not delete comment
## statements and redundant blank characters, leaving the original style.
## For example, the following file is fully compatible.
##
## This is an example of how a configuration file may look like:
##
## .. include:: ../../doc/mytest.cfg
##     :literal:
##

##[ Here is an example of how to use the configuration file parser:

.. code-block:: nim

    import
      os, parsecfg, strutils, streams

    var f = newFileStream(paramStr(1), fmRead)
    if f != nil:
      var p: CfgParser
      open(p, f, filename, "#;")
      while true:
        var e = next(p)
        case e.kind
        of cfgEof: break
        of cfgSectionStart:   ## a ``[section]`` has been parsed
          echo("new section: " & e.section)
        of cfgKeyValuePair:
          echo("key-value-pair: " & e.key & ": " & e.keyVal.value)
        of cfgOption:
          echo("command: " & e.key & ": " & e.keyVal.value)
        of cfgError:
          echo(e.msg)
      close(p)
    else:
      echo("cannot open: " & paramStr(1))

]##

## Examples
## --------
##
## This is a simple example of a configuration file.
##
## ::
##
##     charset="utf-8"
##     [Package]
##     name="hello"
##     --threads:on
##     [Author]
##     name="lihf8515"
##     qq="10214028"
##     email="lihaifeng@wxm.com"
##
## Creating a configuration file.
## ==============================
## .. code-block:: nim
##
##     import parsecfg
##     var cfg=newConfig()
##     cfg.set("","charset","utf-8")
##     cfg.set("Package","name","hello")
##     cfg.set("Package","--threads","on")
##     cfg.set("Author","name","lihf8515")
##     cfg.set("Author","qq","10214028")
##     cfg.set("Author","email","lihaifeng@wxm.com")
##     cfg.write("config.ini")
##     echo cfg
##
## Reading a configuration file.
## =============================
## .. code-block:: nim
##
##     import parsecfg
##     var cfg = loadConfig("config.ini")
##     var charset = cfg.get("","charset")
##     var threads = cfg.get("Package","--threads")
##     var pname = cfg.get("Package","name")
##     var name = cfg.get("Author","name")
##     var qq = cfg.get("Author","qq")
##     var email = cfg.get("Author","email")
##     echo pname & "\n" & name & "\n" & qq & "\n" & email
##
## Modifying a configuration file.
## ===============================
## .. code-block:: nim
##
##     import parsecfg
##     var cfg = loadConfig("config.ini")
##     cfg.set("Author","name","lhf")
##     cfg.write("config.ini")
##     echo cfg
##
## Deleting a section key in a configuration file.
## ===============================================
## .. code-block:: nim
##
##     import parsecfg
##     var cfg = loadConfig("config.ini")
##     cfg.del("Author","email")
##     cfg.write("config.ini")
##     echo cfg

import
  strutils, lexbase, streams, tables

include "system/inclrtl"

type
  CfgEventKind* = enum # enumeration of all events that may occur when parsing
    cfgEof,            # end of file reached
    cfgSectionStart,   # a ``[section]`` has been parsed
    cfgKeyValuePair,   # a ``key=value`` pair has been detected
    cfgOption,         # a ``--key=value`` command line option
    cfgError           # an error occurred during parsing

  CfgEvent* = object of RootObj  # describes a parsing event
    case kind*: CfgEventKind     # the kind of the event
    of cfgEof: nil
    of cfgSectionStart:
      section*: string           # `section` contains the name of the
      sectionVal*: SectionPair   # parsed section start (syntax: ``[section]``)
                                 # 'sectionVal' is the other part of `section`
    of cfgKeyValuePair, cfgOption:
      key*: string               # contains the (key, value) pair if an option
      value*: string             # `value` field is set for compatibility with 
                                 # older versions and may be deprecated in the future.
      keyVal*: KeyValPair        # of the form ``--key: value`` or an ordinary
                                 # ``key= value`` pair has been parsed.
                                 # ``value==""`` if it was not specified in the
                                 # configuration file.
                                 
    of cfgError:                 # the parser encountered an error: `msg`
      msg*: string               # contains the error message. No exceptions
                                 # are thrown if a parse error occurs.

  SectionPair = tuple            
    tokenFrontBlank: string     # Blank in front of the `[`
    tokenLeft: string           # `[`
    sectionFrontBlank: string   # Blank in front of the `section`
    sectionRearBlank: string    # Whitespace after `section`
    tokenRight: string          # `]`
    tokenRearBlank: string      # Whitespace after `]`
    comment: string              
                          
  KeyValPair = tuple             
    keyFrontBlank: string       # Blank in front of the `key`
    keyRearBlank: string        # Whitespace after `key`
    token: string               # `=` or `:`
    valFrontBlank: string       # Blank in front of the `value`
    value: string               # value
    valRearBlank: string        # Whitespace after `value`
    comment: string              

  CfgParser* = object of BaseLexer # the parser object.
    literal: string                # the parsed (string) literal
    filename: string
    commentSeparato: string

# implementation

proc open*(c: var CfgParser, input: Stream, filename, 
           commentSeparato: string = "#;", lineOffset = 0)
          {.rtl, extern: "npc$1".} =
  ## initializes the parser with an input stream. `Filename` is only used
  ## for nice error messages. `lineOffset` can be used to influence the line
  ## number information in the generated error messages.
  lexbase.open(c, input)
  c.filename = filename
  c.literal = ""
  c.commentSeparato = commentSeparato
  inc(c.lineNumber, lineOffset)

proc close*(c: var CfgParser) {.rtl, extern: "npc$1".} =
  ## closes the parser `c` and its associated input stream.
  lexbase.close(c)

proc getColumn*(c: CfgParser): int {.rtl, extern: "npc$1".} =
  ## get the current column the parser has arrived at.
  result = getColNumber(c, c.bufpos)

proc getLine*(c: CfgParser): int {.rtl, extern: "npc$1".} =
  ## get the current line the parser has arrived at.
  result = c.lineNumber

proc getFilename*(c: CfgParser): string {.rtl, extern: "npc$1".} =
  ## get the filename of the file that the parser processes.
  result = c.filename

proc handleHexChar(c: var CfgParser, xi: var int) =
  case c.buf[c.bufpos]
  of '0'..'9':
    xi = (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('0'))
    inc(c.bufpos)
  of 'a'..'f':
    xi = (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('a') + 10)
    inc(c.bufpos)
  of 'A'..'F':
    xi = (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('A') + 10)
    inc(c.bufpos)
  else:
    discard

proc handleDecChars(c: var CfgParser, xi: var int) =
  while c.buf[c.bufpos] in {'0'..'9'}:
    xi = (xi * 10) + (ord(c.buf[c.bufpos]) - ord('0'))
    inc(c.bufpos)

proc getEscapedChar(c: var CfgParser) =
  inc(c.bufpos)               # skip '\'
  case c.buf[c.bufpos]
  of 'n', 'N':
    add(c.literal, "\n")
    inc(c.bufpos)
  of 'r', 'R', 'c', 'C':
    add(c.literal, '\c')
    inc(c.bufpos)
  of 'l', 'L':
    add(c.literal, '\L')
    inc(c.bufpos)
  of 'f', 'F':
    add(c.literal, '\f')
    inc(c.bufpos)
  of 'e', 'E':
    add(c.literal, '\e')
    inc(c.bufpos)
  of 'a', 'A':
    add(c.literal, '\a')
    inc(c.bufpos)
  of 'b', 'B':
    add(c.literal, '\b')
    inc(c.bufpos)
  of 'v', 'V':
    add(c.literal, '\v')
    inc(c.bufpos)
  of 't', 'T':
    add(c.literal, '\t')
    inc(c.bufpos)
  of '\'', '"':
    add(c.literal, c.buf[c.bufpos])
    inc(c.bufpos)
  of '\\':
    add(c.literal, '\\')
    inc(c.bufpos)
  of 'x', 'X':
    inc(c.bufpos)
    var xi = 0
    handleHexChar(c, xi)
    handleHexChar(c, xi)
    add(c.literal, chr(xi))
  of '0'..'9':
    var xi = 0
    handleDecChars(c, xi)
    if (xi <= 255): add(c.literal, chr(xi))
    else: discard
  else: discard

proc handleCRLF(c: var CfgParser, pos: int): int =
  case c.buf[pos]
  of '\c': result = lexbase.handleCR(c, pos)
  of '\L': result = lexbase.handleLF(c, pos)
  else: result = pos

proc errorStr*(c: CfgParser, msg: string): string {.rtl, extern: "npc$1".} =
  ## returns a properly formatted error message containing current line and
  ## column information.
  result = `%`("$1($2, $3) Error: $4",
               [c.filename, $getLine(c), $getColumn(c), msg])

proc warningStr*(c: CfgParser, msg: string): string {.rtl, extern: "npc$1".} =
  ## returns a properly formatted warning message containing current line and
  ## column information.
  result = `%`("$1($2, $3) Warning: $4",
               [c.filename, $getLine(c), $getColumn(c), msg])

proc ignoreMsg*(c: CfgParser, e: CfgEvent): string {.rtl, extern: "npc$1".} =
  ## returns a properly formatted warning message containing that
  ## an entry is ignored.
  case e.kind
  of cfgSectionStart: result = c.warningStr("section ignored: " & e.section)
  of cfgKeyValuePair: result = c.warningStr("key ignored: " & e.key)
  of cfgOption:
    result = c.warningStr("command ignored: " & e.key & ": " & e.keyVal.value)
  of cfgError: result = e.msg
  of cfgEof: result = ""

################################################################################

proc replace(s: string): string =
  var d = ""
  var i = 0
  while i < s.len():
    if s[i] == '\\':
      d.add(r"\\")
    elif s[i] == '\c' and s[i+1] == '\L':
      d.add(r"\n")
      inc(i)
    elif s[i] == '\c':
      d.add(r"\n")
    elif s[i] == '\L':
      d.add(r"\n")
    else:
      d.add(s[i])
    inc(i)
  result = d

proc skipCRLF(c: var CfgParser) =
  var pos = c.bufpos
  pos = handleCRLF(c, pos)
  c.bufpos = pos

proc mySplit(s: string): tuple =
  var l=len(s)-1
  var t: tuple[front: string, rear: string]
  for i in countdown(l, 0):
    if not (s[i] in {' ', '\t'}):
      t.front = s[0..i]
      t.rear = s[i+1..l]
      break
  result = t

proc readBlank(c: var CfgParser) =
  setLen(c.literal, 0)
  var pos = c.bufpos
  while true:
    if c.buf[pos] in {' ', '\t'}:
      add(c.literal, c.buf[pos])
      inc(pos)
    else:
      break
  c.bufpos = pos

proc readSection(c: var CfgParser) =
  setLen(c.literal, 0)
  var pos = c.bufpos
  while true:
    if c.buf[pos] in {']', '\c', '\L', lexbase.EndOfFile}: break
    add(c.literal, c.buf[pos])
    inc(pos)
  c.bufpos = pos

proc readComment(c: var CfgParser) =
  setLen(c.literal, 0)
  var pos = c.bufpos
  while true:
    if c.buf[pos] in {'\c', '\L', lexbase.EndOfFile}:
      break
    else:
      add(c.literal, c.buf[pos])
      inc(pos)
  c.bufpos = pos

proc readKey(c: var CfgParser) =
  setLen(c.literal, 0)
  var pos = c.bufpos
  while true:
    if c.buf[pos] in {'=', ':', '\c', '\L', lexbase.EndOfFile}: break
    add(c.literal, c.buf[pos])
    inc(pos)
  c.bufpos = pos

proc readValue(c: var CfgParser, rawMode: bool) =
  setLen(c.literal, 0)
  var pos = c.bufpos
  if (c.buf[pos] == '"') and (c.buf[pos + 1] == '"') and (c.buf[pos + 2] == '"'):
    # long string literal:
    inc(pos, 3)               # skip """
                              # skip leading newline:
    c.literal = c.literal & "\"\"\""
    pos = handleCRLF(c, pos)
    while true:
      case c.buf[pos]
      of '"':
        if (c.buf[pos + 1] == '"') and (c.buf[pos + 2] == '"'): break
        add(c.literal, '"')
        inc(pos)
      of '\c', '\L':
        pos = handleCRLF(c, pos)
        add(c.literal, "\n")
      of lexbase.EndOfFile:
        break
      else:
        add(c.literal, c.buf[pos])
        inc(pos)
    add(c.literal, "\"\"\"")
    c.bufpos = pos + 3       # skip the three """
  else:
    # ordinary string literal
    if c.buf[pos] == '"':
      c.literal = "\""
      inc(pos)
      while true:
        var ch = c.buf[pos]
        if ch == '"':
          add(c.literal, ch)
          inc(pos)
          break
        if ch in {'\c', '\L', lexbase.EndOfFile}:
          break
        if (ch == '\\') and not rawMode:
          c.bufpos = pos
          getEscapedChar(c)
          pos = c.bufpos
        else:
          add(c.literal, ch)
          inc(pos)
      c.bufpos = pos
    else:
      setLen(c.literal, 0)
      var pos = c.bufpos
      while true:
        if c.commentSeparato.contains(c.buf[pos]): break
        if c.buf[pos] in {'\c', '\L', lexbase.EndOfFile}: break
        add(c.literal, c.buf[pos])
        inc(pos)
      c.bufpos = pos

proc handleLineComment(c: var CfgParser, frontBlank: string): CfgEvent 
                      {.rtl, extern: "npc$1".} =
  ## Handling the entire line is an annotation situation.
  result.kind = cfgKeyValuePair
  result.keyVal.keyFrontBlank = frontBlank
  result.key = ""
  result.keyVal.keyRearBlank = ""
  result.keyVal.token = ""
  result.keyVal.valFrontBlank = ""
  result.keyVal.value = ""
  result.value = ""
  result.keyVal.valRearBlank = ""
  readComment(c)
  result.keyVal.comment = c.literal
  skipCRLF(c)

proc handleSectionComment(c: var CfgParser, frontBlank, 
                          sectionFrontBlank: string): CfgEvent 
                         {.rtl, extern: "npc$1".} =
  ## Handle annotated situations in section
  result.kind = cfgKeyValuePair
  result.keyVal.keyFrontBlank = frontBlank
  result.key = ""
  result.keyVal.keyRearBlank = ""
  result.keyVal.token = ""
  result.keyVal.valFrontBlank = ""
  result.keyVal.value = ""
  result.value = ""
  result.keyVal.valRearBlank = ""
  readComment(c)
  result.keyVal.comment = '[' & sectionFrontBlank & c.literal
  skipCRLF(c)

proc next*(c: var CfgParser): CfgEvent {.rtl, extern: "npc$1".} =
  ## retrieves the first/next event. This controls the parser.
  readBlank(c) # read the blank space in the front of the line.
  var frontBlank = c.literal
  if c.commentSeparato.contains(c.buf[c.bufpos]):
    result = handleLineComment(c, frontBlank)
    return
  case c.buf[c.bufpos]
  of lexbase.EndOfFile:
    result.kind = cfgEof
  of '\c', '\L': # comment field processing as key value section.
    result = handleLineComment(c, frontBlank)
  of '[': # it could be `section`
    inc(c.bufpos) # skip `[`
    readBlank(c) # read blank in front of `section`
    var sectionFrontBlank = c.literal
    if c.commentSeparato.contains(c.buf[c.bufpos]):
      result = handleSectionComment(c, frontBlank, sectionFrontBlank)
    case c.buf[c.bufpos]
    of ']', '\c', '\L', lexbase.EndOfFile: # is not a valid `section`,
      result = handleSectionComment(c, frontBlank, sectionFrontBlank)
    else: # read valid characte.
      readSection(c)
      case c.buf[c.bufpos]
      of '\c', '\L', lexbase.EndOfFile:            # did not read `]`，
        result.kind = cfgKeyValuePair              # comment field processing
        result.keyVal.keyFrontBlank = frontBlank   # as key value section.
        result.key = ""
        result.keyVal.keyRearBlank = ""
        result.keyVal.token = ""
        result.keyVal.valFrontBlank = ""
        result.keyVal.value = ""
        result.value = ""
        result.keyVal.valRearBlank = ""
        result.keyVal.comment = '[' & sectionFrontBlank & c.literal
        skipCRLF(c)
      else: ## read `]`
        result.kind = cfgSectionStart
        result.sectionVal.tokenFrontBlank = frontBlank
        result.sectionVal.tokenLeft = "["
        result.sectionVal.sectionFrontBlank = sectionFrontBlank
        var temp = mySplit(c.literal)
        result.section = temp[0]
        result.sectionVal.sectionRearBlank = temp[1]
        result.sectionVal.tokenRight ="]"
        inc(c.bufpos) # skip `]`
        readBlank(c) # read the whitespace after `]`
        result.sectionVal.tokenRearBlank = c.literal
        readComment(c)
        result.sectionVal.comment = c.literal
        skipCRLF(c)
  else: # is the key value, does the key value processing
    result.kind = cfgKeyValuePair
    result.keyVal.keyFrontBlank = frontBlank
    readKey(c) # read key
    var temp = mySplit(c.literal)
    result.key = temp[0]
    result.keyVal.keyRearBlank = temp[1]
    case c.buf[c.bufpos]
    of '\c', '\L', lexbase.EndOfFile: # did not read `=` or `:`
      result.keyVal.token = ""
      result.keyVal.valFrontBlank = ""
      result.keyVal.value = ""
      result.value = ""
      result.keyVal.valRearBlank = ""
      result.keyVal.comment = ""
      skipCRLF(c)
    else:
      if c.buf[c.bufpos] == ':':
        result.kind = cfgOption
        result.keyVal.token = ":"
      else:
        result.kind = cfgKeyValuePair
        result.keyVal.token = "="
      inc(c.bufpos)
      readBlank(c) # read the blank front of the value
      case c.buf[c.bufpos]
      of '\c', '\L', lexbase.EndOfFile: # value not read
        result.keyVal.valFrontBlank = c.literal
        result.keyVal.value = ""
        result.value = ""
        result.keyVal.valRearBlank = ""
        result.keyVal.comment = ""
        skipCRLF(c)
      else: # read valid value
        result.keyVal.valFrontBlank = c.literal
        if c.buf[c.bufpos] == '"':
          readValue(c, false) # escape characte
        else:
          readValue(c, true) # non-escape characte
        case c.buf[c.bufpos]
        of '\c', '\L', lexbase.EndOfFile:
          result.keyVal.value = c.literal
          result.value = c.literal
          result.keyVal.valRearBlank = ""
          result.keyVal.comment = ""
          skipCRLF(c)
        else: # read to comment characte
          var temp = mySplit(c.literal)
          result.keyVal.value = temp[0]
          result.value = temp[0]
          result.keyVal.valRearBlank = temp[1]
          readComment(c)
          result.keyVal.comment = c.literal
          skipCRLF(c)
        
# ================= Configuration file related operations ===================
type
  Config* = OrderedTableRef[string, (SectionPair, 
                                     OrderedTableRef[string, KeyValPair])]

proc newConfig*(): Config =
  ## Create a new configuration table.
  ## Useful when wanting to create a configuration file.
  result = newOrderedTable[string, (SectionPair, 
                                    OrderedTableRef[string, KeyValPair])]()

proc loadConfig*(stream: Stream, filename: string = "[stream]",
                 commentSeparato: string = "#;"): Config =
  ## loadConfig the specified configuration from stream into a new Config
  ## instance.`filename` parameter is only used for nicer error messages.
  ## `commentSeparato` default value is `"#;"`
  var dict = newOrderedTable[string, (SectionPair, 
                                      OrderedTableRef[string, KeyValPair])]()
  var curSection = "" # Current section,
                      # the default value of the current section is "",
                      # which means that the current section is a common
  var p: CfgParser
  open(p, stream, filename, commentSeparato)
  while true:
    var e = next(p)
    case e.kind
    of cfgEof:
      break
    of cfgSectionStart: # Only look for the first time the Section
      var tp: tuple[sec: SectionPair, kv: OrderedTableRef[string, KeyValPair]]
      var t = newOrderedTable[string, KeyValPair]()
      curSection = e.section
      tp.sec = e.sectionVal
      tp.kv = t
      dict[curSection] = tp
    of cfgKeyValuePair:
      var tp: tuple[sec: SectionPair, kv: OrderedTableRef[string, KeyValPair]]
      var t = newOrderedTable[string, KeyValPair]()
      if dict.hasKey(curSection):
        tp = dict[curSection]
        t = tp.kv
      if e.key == "":
        t.add(e.key, e.keyVal)
      else:
        t[e.key] = e.keyVal
      tp.kv = t
      dict[curSection] = tp
    of cfgOption:
      var tp: tuple[sec: SectionPair, kv: OrderedTableRef[string, KeyValPair]]
      var c = newOrderedTable[string, KeyValPair]()
      if dict.hasKey(curSection):
        tp = dict[curSection]
        c = tp.kv
      c[e.key] = e.keyVal
      dict[curSection] = tp
    of cfgError:
      break
  close(p)
  result = dict

proc loadConfig*(filename: string, commentSeparato: string = "#;"): Config =
  ## loadConfig the specified configuration file into a new Config instance.
  ## `commentSeparato` default value is `"#;"`
  let file = open(filename, fmRead)
  let fileStream = newFileStream(file)
  defer: fileStream.close()
  result = fileStream.loadConfig(filename, commentSeparato)

proc write*(dict: Config, stream: Stream) =
  ## Writes the contents of the table to the specified stream.
  for section, tp in dict.pairs():
    var secPair = tp[0]
    var kvPair = tp[1]
    if section != "": # Not general section
      stream.writeLine(secPair.tokenFrontBlank & secPair.tokenLeft &
                       secPair.sectionFrontBlank & section &
                       secPair.sectionRearBlank & secPair.tokenRight &
                       secPair.tokenRearBlank & secPair.comment)
    for key, kv in kvPair.pairs():
      var s = ""
      s.add(kv.keyFrontBlank)
      s.add(key)
      s.add(kv.keyRearBlank)
      s.add(kv.token)
      s.add(kv.valFrontBlank)
      if kv.value.startsWith("\"\"\"") and kv.value.endsWith("\"\"\""):
        s.add(kv.value)
      elif (kv.value.startsWith("r\"") or kv.value.startsWith("R\"")) and kv.value.endsWith('"'):
        s.add(kv.value)
      elif kv.value.startsWith('"') and kv.value.endsWith('"'):
        s.add(replace(kv.value))
      else:
        s.add(kv.value)
      s.add(kv.valRearBlank)
      s.add(kv.comment)
      stream.writeLine(s)

proc `$`*(dict: Config): string =
  ## Writes the contents of the table to string.
  let stream = newStringStream()
  defer: stream.close()
  dict.write(stream)
  result = stream.data

proc write*(dict: Config, filename: string) =
  ## Writes the contents of the table to the specified configuration file.
  let file = open(filename, fmWrite)
  defer: file.close()
  let fileStream = newFileStream(file)
  dict.write(fileStream)

proc get*(dict: Config, section, key: string): string =
  ## Gets the Key value of the specified Section.
  if dict.haskey(section):
    if dict[section][1].hasKey(key):
      result = dict[section][1][key].value
    elif dict[section][1].hasKey('"' & key & '"'):
      result = dict[section][1]['"' & key & '"'].value
    if result != "":
      if result.startsWith("\"\"\"") and result.endsWith("\"\"\""):
        result = result.substr(3, len(result) - 4)
      elif (result.startsWith("r\"") or result.startsWith("R\"")) and result.endsWith('"'):
        result = result.substr(2, len(result) - 2)
      elif result.startsWith('"') and result.endsWith('"'):
        result = result.substr(1, len(result) - 2)
    else:
      result = ""
  else:
    result = ""

proc set*(dict: var Config, section, key, value: string) =
  ## Sets the Key value of the specified Section.
  var tp: tuple[sec: SectionPair, kv: OrderedTableRef[string, KeyValPair]]
  var t = newOrderedTable[string, KeyValPair]()
  var kvp: KeyValPair
  if dict.hasKey(section):
    tp = dict[section]
    t = tp.kv
    var tempKey = ""
    if t.hasKey(key):
      tempKey = key
    elif t.hasKey('"' & key & '"'):
      tempKey = '"' & key & '"'
    if tempKey != "":
      if t[tempKey].value.startsWith("\"\"\"") and t[tempKey].value.endsWith("\"\"\""):
        t[tempKey].value = "\"" & value & "\""
      elif (t[tempKey].value.startsWith("r\"") or t[tempKey].value.startsWith("R\"")) and t[tempKey].value.endsWith('"'):
        t[tempKey].value = "\"" & value & "\""
      elif t[tempKey].value.startsWith('"') and t[tempKey].value.endsWith('"'):
        t[tempKey].value = "\"" & value & "\""
      else:
        t[tempKey].value = replace(value)
    else:
      kvp.token = "="
      kvp.value = "\"" & value & "\""
      t[key] = kvp
    tp.kv = t
    dict[section] = tp
  else:
    kvp.token = "="
    kvp.value = "\"" & value & "\""
    t[key] = kvp
    tp.kv = t
    tp.sec.tokenLeft = "["
    tp.sec.tokenRight = "]"
    dict[section] = tp

proc del*(dict: var Config, section: string) =
  ## Deletes the specified section and all of its sub keys.
  tables.del(dict, section)

proc del*(dict: var Config, section, key: string) =
  ## Delete the key of the specified section.
  if dict.haskey(section):
    if dict[section][1].hasKey(key):
      if dict[section][1].len() == 1:
        tables.del(dict, section)
      else:
        tables.del(dict[section][1], key)
