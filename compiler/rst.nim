#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements a *reStructuredText* parser. A large
# subset is provided.

import 
  os, msgs, strutils, platform, nhashes, ropes, options

type 
  TRstNodeKind* = enum 
    rnInner,                  # an inner node or a root
    rnHeadline,               # a headline
    rnOverline,               # an over- and underlined headline
    rnTransition,             # a transition (the ------------- <hr> thingie)
    rnParagraph,              # a paragraph
    rnBulletList,             # a bullet list
    rnBulletItem,             # a bullet item
    rnEnumList,               # an enumerated list
    rnEnumItem,               # an enumerated item
    rnDefList,                # a definition list
    rnDefItem,                # an item of a definition list consisting of ...
    rnDefName,                # ... a name part ...
    rnDefBody,                # ... and a body part ...
    rnFieldList,              # a field list
    rnField,                  # a field item
    rnFieldName,              # consisting of a field name ...
    rnFieldBody,              # ... and a field body
    rnOptionList, rnOptionListItem, rnOptionGroup, rnOption, rnOptionString, 
    rnOptionArgument, rnDescription, rnLiteralBlock, rnQuotedLiteralBlock,
    rnLineBlock,              # the | thingie
    rnLineBlockItem,          # sons of the | thing
    rnBlockQuote,             # text just indented
    rnTable, rnGridTable, rnTableRow, rnTableHeaderCell, rnTableDataCell,
    rnLabel,                  # used for footnotes and other things
    rnFootnote,               # a footnote
    rnCitation,               # similar to footnote
    rnStandaloneHyperlink, rnHyperlink, rnRef, rnDirective, # a directive
    rnDirArg, rnRaw, rnTitle, rnContents, rnImage, rnFigure, rnCodeBlock,
    rnRawHtml, rnRawLatex,
    rnContainer,              # ``container`` directive
    rnIndex,                  # index directve:
                              # .. index::
                              #   key
                              #     * `file#id <file#id>`_
                              #     * `file#id <file#id>'_
    rnSubstitutionDef,        # a definition of a substitution
    rnGeneralRole,            # Inline markup:
    rnSub, rnSup, rnIdx, rnEmphasis, # "*"
    rnStrongEmphasis,         # "**"
    rnInterpretedText,        # "`"
    rnInlineLiteral,          # "``"
    rnSubstitutionReferences, # "|"
    rnLeaf                    # a leaf; the node's text field contains the
                              # leaf val

type                          # the syntax tree of RST:
  PRSTNode* = ref TRstNode
  TRstNodeSeq* = seq[PRstNode]
  TRSTNode*{.acyclic, final.} = object 
    kind*: TRstNodeKind
    text*: string             # valid for leafs in the AST; and the title of
                              # the document or the section
    level*: int               # valid for some node kinds
    sons*: TRstNodeSeq        # the node's sons
  

proc rstParse*(text: string,  # the text to be parsed
               skipPounds: bool, filename: string, # for error messages
               line, column: int, hasToc: var bool): PRstNode
proc rsonsLen*(n: PRstNode): int
proc newRstNode*(kind: TRstNodeKind): PRstNode
proc newRstNode*(kind: TRstNodeKind, s: string): PRstNode
proc addSon*(father, son: PRstNode)
proc rstnodeToRefname*(n: PRstNode): string
proc addNodes*(n: PRstNode): string
proc getFieldValue*(n: PRstNode, fieldname: string): string
proc getArgument*(n: PRstNode): string
  # index handling:
proc setIndexPair*(index, key, val: PRstNode)
proc sortIndex*(a: PRstNode)
proc clearIndex*(index: PRstNode, filename: string)
# implementation
# ----------------------------- scanner part --------------------------------

const 
  SymChars: TCharSet = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF'}

type 
  TTokType = enum 
    tkEof, tkIndent, tkWhite, tkWord, tkAdornment, tkPunct, tkOther
  TToken{.final.} = object    # a RST token
    kind*: TTokType           # the type of the token
    ival*: int                # the indentation or parsed integer value
    symbol*: string           # the parsed symbol as string
    line*, col*: int          # line and column of the token
  
  TTokenSeq = seq[TToken]
  TLexer = object of TObject
    buf*: cstring
    bufpos*: int
    line*, col*, baseIndent*: int
    skipPounds*: bool


proc getThing(L: var TLexer, tok: var TToken, s: TCharSet) = 
  tok.kind = tkWord
  tok.line = L.line
  tok.col = L.col
  var pos = L.bufpos
  while True: 
    add(tok.symbol, L.buf[pos])
    inc(pos)
    if not (L.buf[pos] in s): break 
  inc(L.col, pos - L.bufpos)
  L.bufpos = pos

proc getAdornment(L: var TLexer, tok: var TToken) = 
  tok.kind = tkAdornment
  tok.line = L.line
  tok.col = L.col
  var pos = L.bufpos
  var c = L.buf[pos]
  while True: 
    add(tok.symbol, L.buf[pos])
    inc(pos)
    if L.buf[pos] != c: break 
  inc(L.col, pos - L.bufpos)
  L.bufpos = pos

proc getIndentAux(L: var TLexer, start: int): int = 
  var pos = start
  var buf = L.buf                 
  # skip the newline (but include it in the token!)
  if buf[pos] == '\x0D': 
    if buf[pos + 1] == '\x0A': inc(pos, 2)
    else: inc(pos)
  elif buf[pos] == '\x0A': 
    inc(pos)
  if L.skipPounds: 
    if buf[pos] == '#': inc(pos)
    if buf[pos] == '#': inc(pos)
  while True: 
    case buf[pos]
    of ' ', '\x0B', '\x0C': 
      inc(pos)
      inc(result)
    of '\x09': 
      inc(pos)
      result = result - (result mod 8) + 8
    else: 
      break                   # EndOfFile also leaves the loop
  if buf[pos] == '\0': 
    result = 0
  elif (buf[pos] == '\x0A') or (buf[pos] == '\x0D'): 
    # look at the next line for proper indentation:
    result = getIndentAux(L, pos)
  L.bufpos = pos              # no need to set back buf
  
proc getIndent(L: var TLexer, tok: var TToken) = 
  inc(L.line)
  tok.line = L.line
  tok.col = 0
  tok.kind = tkIndent         # skip the newline (but include it in the token!)
  tok.ival = getIndentAux(L, L.bufpos)
  L.col = tok.ival
  tok.ival = max(tok.ival - L.baseIndent, 0)
  tok.symbol = "\n" & repeatChar(tok.ival)

proc rawGetTok(L: var TLexer, tok: var TToken) = 
  tok.symbol = ""
  tok.ival = 0
  var c = L.buf[L.bufpos]
  case c
  of 'a'..'z', 'A'..'Z', '\x80'..'\xFF', '0'..'9': 
    getThing(L, tok, SymChars)
  of ' ', '\x09', '\x0B', '\x0C': 
    getThing(L, tok, {' ', '\x09'})
    tok.kind = tkWhite
    if L.buf[L.bufpos] in {'\x0D', '\x0A'}: 
      rawGetTok(L, tok)       # ignore spaces before \n
  of '\x0D', '\x0A': 
    getIndent(L, tok)
  of '!', '\"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',', '-', '.', 
     '/', ':', ';', '<', '=', '>', '?', '@', '[', '\\', ']', '^', '_', '`', '{',
     '|', '}', '~': 
    getAdornment(L, tok)
    if len(tok.symbol) <= 3: tok.kind = tkPunct
  else: 
    tok.line = L.line
    tok.col = L.col
    if c == '\0': 
      tok.kind = tkEof
    else: 
      tok.kind = tkOther
      add(tok.symbol, c)
      inc(L.bufpos)
      inc(L.col)
  tok.col = max(tok.col - L.baseIndent, 0)

proc getTokens(buffer: string, skipPounds: bool, tokens: var TTokenSeq) = 
  var L: TLexer
  var length = len(tokens)
  L.buf = cstring(buffer)
  L.line = 1                  # skip UTF-8 BOM
  if (L.buf[0] == '\xEF') and (L.buf[1] == '\xBB') and (L.buf[2] == '\xBF'): 
    inc(L.bufpos, 3)
  L.skipPounds = skipPounds
  if skipPounds: 
    if L.buf[L.bufpos] == '#': inc(L.bufpos)
    if L.buf[L.bufpos] == '#': inc(L.bufpos)
    L.baseIndent = 0
    while L.buf[L.bufpos] == ' ': 
      inc(L.bufpos)
      inc(L.baseIndent)
  while true: 
    inc(length)
    setlen(tokens, length)
    rawGetTok(L, tokens[length - 1])
    if tokens[length - 1].kind == tkEof: break 
  if tokens[0].kind == tkWhite: 
    # BUGFIX
    tokens[0].ival = len(tokens[0].symbol)
    tokens[0].kind = tkIndent

proc addSon(father, son: PRstNode) = 
  add(father.sons, son)

proc addSonIfNotNil(father, son: PRstNode) = 
  if son != nil: addSon(father, son)
  
proc rsonsLen(n: PRstNode): int = 
  result = len(n.sons)

proc newRstNode(kind: TRstNodeKind): PRstNode = 
  new(result)
  result.sons = @[]
  result.kind = kind

proc newRstNode(kind: TRstNodeKind, s: string): PRstNode = 
  result = newRstNode(kind)
  result.text = s

proc lastSon*(n: PRstNode): PRstNode = 
  result = n.sons[len(n.sons)-1]

type 
  TLevelMap = array[Char, int]
  TSubstitution{.final.} = object 
    key*: string
    value*: PRstNode

  TSharedState{.final.} = object 
    uLevel*, oLevel*: int        # counters for the section levels
    subs*: seq[TSubstitution]    # substitutions
    refs*: seq[TSubstitution]    # references
    underlineToLevel*: TLevelMap # Saves for each possible title adornment
                                 # character its level in the
                                 # current document. 
                                 # This is for single underline adornments.
    overlineToLevel*: TLevelMap  # Saves for each possible title adornment 
                                 # character its level in the current document. 
                                 # This is for over-underline adornments.
  
  PSharedState = ref TSharedState
  TRstParser = object of TObject
    idx*: int
    tok*: TTokenSeq
    s*: PSharedState
    indentStack*: seq[int]
    filename*: string
    line*, col*: int
    hasToc*: bool


proc newSharedState(): PSharedState = 
  new(result)
  result.subs = @[]
  result.refs = @[]

proc tokInfo(p: TRstParser, tok: TToken): TLineInfo = 
  result = newLineInfo(p.filename, p.line + tok.line, p.col + tok.col)

proc rstMessage(p: TRstParser, msgKind: TMsgKind, arg: string) = 
  GenericMessage(tokInfo(p, p.tok[p.idx]), msgKind, arg)

proc rstMessage(p: TRstParser, msgKind: TMsgKind) = 
  GenericMessage(tokInfo(p, p.tok[p.idx]), msgKind, p.tok[p.idx].symbol)

proc currInd(p: TRstParser): int = 
  result = p.indentStack[high(p.indentStack)]

proc pushInd(p: var TRstParser, ind: int) = 
  add(p.indentStack, ind)

proc popInd(p: var TRstParser) = 
  if len(p.indentStack) > 1: setlen(p.indentStack, len(p.indentStack) - 1)
  
proc initParser(p: var TRstParser, sharedState: PSharedState) = 
  p.indentStack = @[0]
  p.tok = @[]
  p.idx = 0
  p.filename = ""
  p.hasToc = false
  p.col = 0
  p.line = 1
  p.s = sharedState

proc addNodesAux(n: PRstNode, result: var string) = 
  if n.kind == rnLeaf: 
    add(result, n.text)
  else: 
    for i in countup(0, rsonsLen(n) - 1): addNodesAux(n.sons[i], result)
  
proc addNodes(n: PRstNode): string = 
  result = ""
  addNodesAux(n, result)

proc rstnodeToRefnameAux(n: PRstNode, r: var string, b: var bool) = 
  if n.kind == rnLeaf: 
    for i in countup(0, len(n.text) + 0 - 1): 
      case n.text[i]
      of '0'..'9': 
        if b: 
          add(r, '-')
          b = false
        if len(r) == 0: add(r, 'Z')
        add(r, n.text[i])
      of 'a'..'z': 
        if b: 
          add(r, '-')
          b = false
        add(r, n.text[i])
      of 'A'..'Z': 
        if b: 
          add(r, '-')
          b = false
        add(r, chr(ord(n.text[i]) - ord('A') + ord('a')))
      else: 
        if (len(r) > 0): b = true
  else: 
    for i in countup(0, rsonsLen(n) - 1): rstnodeToRefnameAux(n.sons[i], r, b)
  
proc rstnodeToRefname(n: PRstNode): string = 
  result = ""
  var b = false
  rstnodeToRefnameAux(n, result, b)

proc findSub(p: var TRstParser, n: PRstNode): int = 
  var key = addNodes(n)           
  # the spec says: if no exact match, try one without case distinction:
  for i in countup(0, high(p.s.subs)): 
    if key == p.s.subs[i].key: 
      return i
  for i in countup(0, high(p.s.subs)): 
    if cmpIgnoreStyle(key, p.s.subs[i].key) == 0: 
      return i
  result = - 1

proc setSub(p: var TRstParser, key: string, value: PRstNode) = 
  var length = len(p.s.subs)
  for i in countup(0, length - 1): 
    if key == p.s.subs[i].key: 
      p.s.subs[i].value = value
      return 
  setlen(p.s.subs, length + 1)
  p.s.subs[length].key = key
  p.s.subs[length].value = value

proc setRef(p: var TRstParser, key: string, value: PRstNode) = 
  var length = len(p.s.refs)
  for i in countup(0, length - 1): 
    if key == p.s.refs[i].key: 
      p.s.refs[i].value = value
      rstMessage(p, warnRedefinitionOfLabel, key)
      return 
  setlen(p.s.refs, length + 1)
  p.s.refs[length].key = key
  p.s.refs[length].value = value

proc findRef(p: var TRstParser, key: string): PRstNode = 
  for i in countup(0, high(p.s.refs)): 
    if key == p.s.refs[i].key: 
      return p.s.refs[i].value

proc cmpNodes(a, b: PRstNode): int = 
  assert(a.kind == rnDefItem)
  assert(b.kind == rnDefItem)
  var x = a.sons[0]
  var y = b.sons[0]
  result = cmpIgnoreStyle(addNodes(x), addNodes(y))

proc sortIndex(a: PRstNode) = 
  # we use shellsort here; fast and simple
  assert(a.kind == rnDefList)
  var N = rsonsLen(a)
  var h = 1
  while true: 
    h = 3 * h + 1
    if h > N: break 
  while true: 
    h = h div 3
    for i in countup(h, N - 1): 
      var v = a.sons[i]
      var j = i
      while cmpNodes(a.sons[j - h], v) >= 0: 
        a.sons[j] = a.sons[j - h]
        j = j - h
        if j < h: break 
      a.sons[j] = v
    if h == 1: break 
  
proc eqRstNodes(a, b: PRstNode): bool = 
  if a.kind != b.kind: return 
  if a.kind == rnLeaf: 
    result = a.text == b.text
  else: 
    if rsonsLen(a) != rsonsLen(b): return 
    for i in countup(0, rsonsLen(a) - 1): 
      if not eqRstNodes(a.sons[i], b.sons[i]): return 
    result = true

proc matchesHyperlink(h: PRstNode, filename: string): bool = 
  if h.kind == rnInner:       # this may happen in broken indexes!
    assert(rsonsLen(h) == 1)
    result = matchesHyperlink(h.sons[0], filename)
  elif h.kind == rnHyperlink: 
    var s = addNodes(h.sons[1])
    if startsWith(s, filename) and (s[len(filename)] == '#'): result = true
    else: result = false
  else: 
    result = false
  
proc clearIndex(index: PRstNode, filename: string) = 
  var 
    k, items, lastItem: int
    val: PRstNode
  assert(index.kind == rnDefList)
  for i in countup(0, rsonsLen(index) - 1): 
    assert(index.sons[i].sons[1].kind == rnDefBody)
    val = index.sons[i].sons[1].sons[0]
    if val.kind == rnInner: val = val.sons[0]
    if val.kind == rnBulletList: 
      items = rsonsLen(val)
      lastItem = - 1          # save the last valid item index
      for j in countup(0, rsonsLen(val) - 1): 
        if val.sons[j] == nil: 
          dec(items)
        elif matchesHyperlink(val.sons[j].sons[0], filename): 
          val.sons[j] = nil
          dec(items)
        else: 
          lastItem = j
      if items == 1: 
        index.sons[i].sons[1].sons[0] = val.sons[lastItem].sons[0]
      elif items == 0: 
        index.sons[i] = nil
    elif matchesHyperlink(val, filename): 
      index.sons[i] = nil
  k = 0
  for i in countup(0, rsonsLen(index) - 1): 
    if index.sons[i] != nil: 
      if k != i: index.sons[k] = index.sons[i]
      inc(k)
  setlen(index.sons, k)

proc setIndexPair(index, key, val: PRstNode) = 
  var e, a, b: PRstNode
  assert(index.kind == rnDefList)
  assert(key.kind != rnDefName)
  a = newRstNode(rnDefName)
  addSon(a, key)
  for i in countup(0, rsonsLen(index) - 1): 
    if eqRstNodes(index.sons[i].sons[0], a): 
      assert(index.sons[i].sons[1].kind == rnDefBody)
      e = index.sons[i].sons[1].sons[0]
      if e.kind != rnBulletList: 
        e = newRstNode(rnBulletList)
        b = newRstNode(rnBulletItem)
        addSon(b, index.sons[i].sons[1].sons[0])
        addSon(e, b)
        index.sons[i].sons[1].sons[0] = e
      b = newRstNode(rnBulletItem)
      addSon(b, val)
      addSon(e, b)
      return                  # key already exists
  e = newRstNode(rnDefItem)
  assert(val.kind != rnDefBody)
  b = newRstNode(rnDefBody)
  addSon(b, val)
  addSon(e, a)
  addSon(e, b)
  addSon(index, e)

proc newLeaf(p: var TRstParser): PRstNode = 
  result = newRstNode(rnLeaf, p.tok[p.idx].symbol)

proc getReferenceName(p: var TRstParser, endStr: string): PRstNode = 
  var res = newRstNode(rnInner)
  while true: 
    case p.tok[p.idx].kind
    of tkWord, tkOther, tkWhite: 
      addSon(res, newLeaf(p))
    of tkPunct: 
      if p.tok[p.idx].symbol == endStr: 
        inc(p.idx)
        break 
      else: 
        addSon(res, newLeaf(p))
    else: 
      rstMessage(p, errXexpected, endStr)
      break 
    inc(p.idx)
  result = res

proc untilEol(p: var TRstParser): PRstNode = 
  result = newRstNode(rnInner)
  while not (p.tok[p.idx].kind in {tkIndent, tkEof}): 
    addSon(result, newLeaf(p))
    inc(p.idx)

proc expect(p: var TRstParser, tok: string) = 
  if p.tok[p.idx].symbol == tok: inc(p.idx)
  else: rstMessage(p, errXexpected, tok)
  
proc isInlineMarkupEnd(p: TRstParser, markup: string): bool = 
  result = p.tok[p.idx].symbol == markup
  if not result: 
    return                    # Rule 3:
  result = not (p.tok[p.idx - 1].kind in {tkIndent, tkWhite})
  if not result: 
    return                    # Rule 4:
  result = (p.tok[p.idx + 1].kind in {tkIndent, tkWhite, tkEof}) or
      (p.tok[p.idx + 1].symbol[0] in
      {'\'', '\"', ')', ']', '}', '>', '-', '/', '\\', ':', '.', ',', ';', '!', 
       '?', '_'})
  if not result: 
    return                    # Rule 7:
  if p.idx > 0: 
    if (markup != "``") and (p.tok[p.idx - 1].symbol == "\\"): 
      result = false

proc isInlineMarkupStart(p: TRstParser, markup: string): bool = 
  var d: Char
  result = p.tok[p.idx].symbol == markup
  if not result: 
    return                    # Rule 1:
  result = (p.idx == 0) or (p.tok[p.idx - 1].kind in {tkIndent, tkWhite}) or
      (p.tok[p.idx - 1].symbol[0] in
      {'\'', '\"', '(', '[', '{', '<', '-', '/', ':', '_'})
  if not result: 
    return                    # Rule 2:
  result = not (p.tok[p.idx + 1].kind in {tkIndent, tkWhite, tkEof})
  if not result: 
    return                    # Rule 5 & 7:
  if p.idx > 0: 
    if p.tok[p.idx - 1].symbol == "\\": 
      result = false
    else: 
      var c = p.tok[p.idx - 1].symbol[0]
      case c
      of '\'', '\"': d = c
      of '(': d = ')'
      of '[': d = ']'
      of '{': d = '}'
      of '<': d = '>'
      else: d = '\0'
      if d != '\0': result = p.tok[p.idx + 1].symbol[0] != d
  
proc parseBackslash(p: var TRstParser, father: PRstNode) = 
  assert(p.tok[p.idx].kind == tkPunct)
  if p.tok[p.idx].symbol == "\\\\": 
    addSon(father, newRstNode(rnLeaf, "\\"))
    inc(p.idx)
  elif p.tok[p.idx].symbol == "\\": 
    # XXX: Unicode?
    inc(p.idx)
    if p.tok[p.idx].kind != tkWhite: addSon(father, newLeaf(p))
    inc(p.idx)
  else: 
    addSon(father, newLeaf(p))
    inc(p.idx)

proc match(p: TRstParser, start: int, expr: string): bool = 
  # regular expressions are:
  # special char     exact match
  # 'w'              tkWord
  # ' '              tkWhite
  # 'a'              tkAdornment
  # 'i'              tkIndent
  # 'p'              tkPunct
  # 'T'              always true
  # 'E'              whitespace, indent or eof
  # 'e'              tkWord or '#' (for enumeration lists)
  var i = 0
  var j = start
  var last = len(expr) + 0 - 1
  while i <= last: 
    case expr[i]
    of 'w': result = p.tok[j].kind == tkWord
    of ' ': result = p.tok[j].kind == tkWhite
    of 'i': result = p.tok[j].kind == tkIndent
    of 'p': result = p.tok[j].kind == tkPunct
    of 'a': result = p.tok[j].kind == tkAdornment
    of 'o': result = p.tok[j].kind == tkOther
    of 'T': result = true
    of 'E': result = p.tok[j].kind in {tkEof, tkWhite, tkIndent}
    of 'e': 
      result = (p.tok[j].kind == tkWord) or (p.tok[j].symbol == "#")
      if result: 
        case p.tok[j].symbol[0]
        of 'a'..'z', 'A'..'Z': result = len(p.tok[j].symbol) == 1
        of '0'..'9': result = allCharsInSet(p.tok[j].symbol, {'0'..'9'})
        else: nil
    else: 
      var c = expr[i]
      var length = 0
      while (i <= last) and (expr[i] == c): 
        inc(i)
        inc(length)
      dec(i)
      result = (p.tok[j].kind in {tkPunct, tkAdornment}) and
          (len(p.tok[j].symbol) == length) and (p.tok[j].symbol[0] == c)
    if not result: return 
    inc(j)
    inc(i)
  result = true

proc fixupEmbeddedRef(n, a, b: PRstNode) = 
  var sep = - 1
  for i in countdown(rsonsLen(n) - 2, 0): 
    if n.sons[i].text == "<": 
      sep = i
      break 
  var incr = if (sep > 0) and (n.sons[sep - 1].text[0] == ' '): 2 else: 1
  for i in countup(0, sep - incr): addSon(a, n.sons[i])
  for i in countup(sep + 1, rsonsLen(n) - 2): addSon(b, n.sons[i])
  
proc parsePostfix(p: var TRstParser, n: PRstNode): PRstNode = 
  result = n
  if isInlineMarkupEnd(p, "_"): 
    inc(p.idx)
    if (p.tok[p.idx - 2].symbol == "`") and (p.tok[p.idx - 3].symbol == ">"): 
      var a = newRstNode(rnInner)
      var b = newRstNode(rnInner)
      fixupEmbeddedRef(n, a, b)
      if rsonsLen(a) == 0: 
        result = newRstNode(rnStandaloneHyperlink)
        addSon(result, b)
      else: 
        result = newRstNode(rnHyperlink)
        addSon(result, a)
        addSon(result, b)
        setRef(p, rstnodeToRefname(a), b)
    elif n.kind == rnInterpretedText: 
      n.kind = rnRef
    else: 
      result = newRstNode(rnRef)
      addSon(result, n)
  elif match(p, p.idx, ":w:"): 
    # a role:
    if p.tok[p.idx + 1].symbol == "idx": 
      n.kind = rnIdx
    elif p.tok[p.idx + 1].symbol == "literal": 
      n.kind = rnInlineLiteral
    elif p.tok[p.idx + 1].symbol == "strong": 
      n.kind = rnStrongEmphasis
    elif p.tok[p.idx + 1].symbol == "emphasis": 
      n.kind = rnEmphasis
    elif (p.tok[p.idx + 1].symbol == "sub") or
        (p.tok[p.idx + 1].symbol == "subscript"): 
      n.kind = rnSub
    elif (p.tok[p.idx + 1].symbol == "sup") or
        (p.tok[p.idx + 1].symbol == "supscript"): 
      n.kind = rnSup
    else: 
      result = newRstNode(rnGeneralRole)
      n.kind = rnInner
      addSon(result, n)
      addSon(result, newRstNode(rnLeaf, p.tok[p.idx + 1].symbol))
    inc(p.idx, 3)

proc isURL(p: TRstParser, i: int): bool = 
  result = (p.tok[i + 1].symbol == ":") and (p.tok[i + 2].symbol == "//") and
      (p.tok[i + 3].kind == tkWord) and (p.tok[i + 4].symbol == ".")

proc parseURL(p: var TRstParser, father: PRstNode) = 
  #if p.tok[p.idx].symbol[strStart] = '<' then begin
  if isURL(p, p.idx): 
    var n = newRstNode(rnStandaloneHyperlink)
    while true: 
      case p.tok[p.idx].kind
      of tkWord, tkAdornment, tkOther: 
        nil
      of tkPunct: 
        if not (p.tok[p.idx + 1].kind in
            {tkWord, tkAdornment, tkOther, tkPunct}): 
          break 
      else: break 
      addSon(n, newLeaf(p))
      inc(p.idx)
    addSon(father, n)
  else: 
    var n = newLeaf(p)
    inc(p.idx)
    if p.tok[p.idx].symbol == "_": n = parsePostfix(p, n)
    addSon(father, n)

proc parseUntil(p: var TRstParser, father: PRstNode, postfix: string, 
                interpretBackslash: bool) = 
  while true: 
    case p.tok[p.idx].kind
    of tkPunct: 
      if isInlineMarkupEnd(p, postfix): 
        inc(p.idx)
        break 
      elif interpretBackslash: 
        parseBackslash(p, father)
      else: 
        addSon(father, newLeaf(p))
        inc(p.idx)
    of tkAdornment, tkWord, tkOther: 
      addSon(father, newLeaf(p))
      inc(p.idx)
    of tkIndent: 
      addSon(father, newRstNode(rnLeaf, " "))
      inc(p.idx)
      if p.tok[p.idx].kind == tkIndent: 
        rstMessage(p, errXExpected, postfix)
        break 
    of tkWhite: 
      addSon(father, newRstNode(rnLeaf, " "))
      inc(p.idx)
    else: rstMessage(p, errXExpected, postfix)
  
proc parseInline(p: var TRstParser, father: PRstNode) = 
  case p.tok[p.idx].kind
  of tkPunct: 
    if isInlineMarkupStart(p, "**"): 
      inc(p.idx)
      var n = newRstNode(rnStrongEmphasis)
      parseUntil(p, n, "**", true)
      addSon(father, n)
    elif isInlineMarkupStart(p, "*"): 
      inc(p.idx)
      var n = newRstNode(rnEmphasis)
      parseUntil(p, n, "*", true)
      addSon(father, n)
    elif isInlineMarkupStart(p, "``"): 
      inc(p.idx)
      var n = newRstNode(rnInlineLiteral)
      parseUntil(p, n, "``", false)
      addSon(father, n)
    elif isInlineMarkupStart(p, "`"): 
      inc(p.idx)
      var n = newRstNode(rnInterpretedText)
      parseUntil(p, n, "`", true)
      n = parsePostfix(p, n)
      addSon(father, n)
    elif isInlineMarkupStart(p, "|"): 
      inc(p.idx)
      var n = newRstNode(rnSubstitutionReferences)
      parseUntil(p, n, "|", false)
      addSon(father, n)
    else: 
      parseBackslash(p, father)
  of tkWord: 
    parseURL(p, father)
  of tkAdornment, tkOther, tkWhite: 
    addSon(father, newLeaf(p))
    inc(p.idx)
  else: assert(false)
  
proc getDirective(p: var TRstParser): string = 
  if (p.tok[p.idx].kind == tkWhite) and (p.tok[p.idx + 1].kind == tkWord): 
    var j = p.idx
    inc(p.idx)
    result = p.tok[p.idx].symbol
    inc(p.idx)
    while p.tok[p.idx].kind in {tkWord, tkPunct, tkAdornment, tkOther}: 
      if p.tok[p.idx].symbol == "::": break 
      add(result, p.tok[p.idx].symbol)
      inc(p.idx)
    if (p.tok[p.idx].kind == tkWhite): inc(p.idx)
    if p.tok[p.idx].symbol == "::": 
      inc(p.idx)
      if (p.tok[p.idx].kind == tkWhite): inc(p.idx)
    else: 
      p.idx = j               # set back
      result = ""             # error
  else: 
    result = ""
  
proc parseComment(p: var TRstParser): PRstNode = 
  case p.tok[p.idx].kind
  of tkIndent, tkEof: 
    if p.tok[p.idx + 1].kind == tkIndent: 
      inc(p.idx)              # empty comment
    else: 
      var indent = p.tok[p.idx].ival
      while True: 
        case p.tok[p.idx].kind
        of tkEof: 
          break 
        of tkIndent: 
          if (p.tok[p.idx].ival < indent): break 
        else: 
          nil
        inc(p.idx)
  else: 
    while not (p.tok[p.idx].kind in {tkIndent, tkEof}): inc(p.idx)
  result = nil

type 
  TDirKind = enum             # must be ordered alphabetically!
    dkNone, dkAuthor, dkAuthors, dkCodeBlock, dkContainer, dkContents, dkFigure, 
    dkImage, dkInclude, dkIndex, dkRaw, dkTitle

const 
  DirIds: array[0..11, string] = ["", "author", "authors", "code-block", 
    "container", "contents", "figure", "image", "include", "index", "raw", 
    "title"]

proc getDirKind(s: string): TDirKind = 
  var i: int
  i = binaryStrSearch(DirIds, s)
  if i >= 0: result = TDirKind(i)
  else: result = dkNone
  
proc parseLine(p: var TRstParser, father: PRstNode) = 
  while True: 
    case p.tok[p.idx].kind
    of tkWhite, tkWord, tkOther, tkPunct: parseInline(p, father)
    else: break 
  
proc parseSection(p: var TRstParser, result: PRstNode)
proc parseField(p: var TRstParser): PRstNode = 
  result = newRstNode(rnField)
  var col = p.tok[p.idx].col
  inc(p.idx)                  # skip :
  var fieldname = newRstNode(rnFieldname)
  parseUntil(p, fieldname, ":", false)
  var fieldbody = newRstNode(rnFieldbody)
  if p.tok[p.idx].kind != tkIndent: parseLine(p, fieldbody)
  if p.tok[p.idx].kind == tkIndent: 
    var indent = p.tok[p.idx].ival
    if indent > col: 
      pushInd(p, indent)
      parseSection(p, fieldbody)
      popInd(p)
  addSon(result, fieldname)
  addSon(result, fieldbody)

proc parseFields(p: var TRstParser): PRstNode = 
  result = nil
  if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx + 1].symbol == ":"): 
    var col = p.tok[p.idx].ival   # BUGFIX!
    result = newRstNode(rnFieldList)
    inc(p.idx)
    while true: 
      addSon(result, parseField(p))
      if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx].ival == col) and
          (p.tok[p.idx + 1].symbol == ":"): 
        inc(p.idx)
      else: 
        break 
  
proc getFieldValue(n: PRstNode, fieldname: string): string = 
  result = ""
  if n.sons[1] == nil: return 
  if (n.sons[1].kind != rnFieldList): 
    InternalError("getFieldValue (2): " & $n.sons[1].kind)
  for i in countup(0, rsonsLen(n.sons[1]) - 1): 
    var f = n.sons[1].sons[i]
    if cmpIgnoreStyle(addNodes(f.sons[0]), fieldname) == 0: 
      result = addNodes(f.sons[1])
      if result == "": result = "\x01\x01" # indicates that the field exists
      return 

proc getArgument(n: PRstNode): string = 
  if n.sons[0] == nil: result = ""
  else: result = addNodes(n.sons[0])
  
proc parseDotDot(p: var TRstParser): PRstNode
proc parseLiteralBlock(p: var TRstParser): PRstNode = 
  result = newRstNode(rnLiteralBlock)
  var n = newRstNode(rnLeaf, "")
  if p.tok[p.idx].kind == tkIndent: 
    var indent = p.tok[p.idx].ival
    inc(p.idx)
    while True: 
      case p.tok[p.idx].kind
      of tkEof: 
        break 
      of tkIndent: 
        if (p.tok[p.idx].ival < indent): 
          break 
        else: 
          add(n.text, "\n")
          add(n.text, repeatChar(p.tok[p.idx].ival - indent))
          inc(p.idx)
      else: 
        add(n.text, p.tok[p.idx].symbol)
        inc(p.idx)
  else: 
    while not (p.tok[p.idx].kind in {tkIndent, tkEof}): 
      add(n.text, p.tok[p.idx].symbol)
      inc(p.idx)
  addSon(result, n)

proc getLevel(map: var TLevelMap, lvl: var int, c: Char): int = 
  if map[c] == 0: 
    inc(lvl)
    map[c] = lvl
  result = map[c]

proc tokenAfterNewline(p: TRstParser): int = 
  result = p.idx
  while true: 
    case p.tok[result].kind
    of tkEof: 
      break 
    of tkIndent: 
      inc(result)
      break 
    else: inc(result)
  
proc isLineBlock(p: TRstParser): bool = 
  var j = tokenAfterNewline(p)
  result = (p.tok[p.idx].col == p.tok[j].col) and (p.tok[j].symbol == "|") or
      (p.tok[j].col > p.tok[p.idx].col)

proc predNL(p: TRstParser): bool = 
  result = true
  if (p.idx > 0): 
    result = (p.tok[p.idx - 1].kind == tkIndent) and
        (p.tok[p.idx - 1].ival == currInd(p))
  
proc isDefList(p: TRstParser): bool = 
  var j = tokenAfterNewline(p)
  result = (p.tok[p.idx].col < p.tok[j].col) and
      (p.tok[j].kind in {tkWord, tkOther, tkPunct}) and
      (p.tok[j - 2].symbol != "::")

proc isOptionList(p: TRstParser): bool = 
  result = match(p, p.idx, "-w") or match(p, p.idx, "--w") or
           match(p, p.idx, "/w") or match(p, p.idx, "//w")

proc whichSection(p: TRstParser): TRstNodeKind = 
  case p.tok[p.idx].kind
  of tkAdornment: 
    if match(p, p.idx + 1, "ii"): result = rnTransition
    elif match(p, p.idx + 1, " a"): result = rnTable
    elif match(p, p.idx + 1, "i"): result = rnOverline
    else: result = rnLeaf
  of tkPunct: 
    if match(p, tokenAfterNewLine(p), "ai"): 
      result = rnHeadline
    elif p.tok[p.idx].symbol == "::": 
      result = rnLiteralBlock
    elif predNL(p) and
        ((p.tok[p.idx].symbol == "+") or (p.tok[p.idx].symbol == "*") or
        (p.tok[p.idx].symbol == "-")) and (p.tok[p.idx + 1].kind == tkWhite): 
      result = rnBulletList
    elif (p.tok[p.idx].symbol == "|") and isLineBlock(p): 
      result = rnLineBlock
    elif (p.tok[p.idx].symbol == "..") and predNL(p): 
      result = rnDirective
    elif (p.tok[p.idx].symbol == ":") and predNL(p): 
      result = rnFieldList
    elif match(p, p.idx, "(e) "): 
      result = rnEnumList
    elif match(p, p.idx, "+a+"): 
      result = rnGridTable
      rstMessage(p, errGridTableNotImplemented)
    elif isDefList(p): 
      result = rnDefList
    elif isOptionList(p): 
      result = rnOptionList
    else: 
      result = rnParagraph
  of tkWord, tkOther, tkWhite: 
    if match(p, tokenAfterNewLine(p), "ai"): result = rnHeadline
    elif isDefList(p): result = rnDefList
    elif match(p, p.idx, "e) ") or match(p, p.idx, "e. "): result = rnEnumList
    else: result = rnParagraph
  else: result = rnLeaf
  
proc parseLineBlock(p: var TRstParser): PRstNode = 
  result = nil
  if p.tok[p.idx + 1].kind == tkWhite: 
    var col = p.tok[p.idx].col
    result = newRstNode(rnLineBlock)
    pushInd(p, p.tok[p.idx + 2].col)
    inc(p.idx, 2)
    while true: 
      var item = newRstNode(rnLineBlockItem)
      parseSection(p, item)
      addSon(result, item)
      if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx].ival == col) and
          (p.tok[p.idx + 1].symbol == "|") and
          (p.tok[p.idx + 2].kind == tkWhite): 
        inc(p.idx, 3)
      else: 
        break 
    popInd(p)

proc parseParagraph(p: var TRstParser, result: PRstNode) = 
  while True: 
    case p.tok[p.idx].kind
    of tkIndent: 
      if p.tok[p.idx + 1].kind == tkIndent: 
        inc(p.idx)
        break 
      elif (p.tok[p.idx].ival == currInd(p)): 
        inc(p.idx)
        case whichSection(p)
        of rnParagraph, rnLeaf, rnHeadline, rnOverline, rnDirective: 
          addSon(result, newRstNode(rnLeaf, " "))
        of rnLineBlock: 
          addSonIfNotNil(result, parseLineBlock(p))
        else: break 
      else: 
        break 
    of tkPunct: 
      if (p.tok[p.idx].symbol == "::") and
          (p.tok[p.idx + 1].kind == tkIndent) and
          (currInd(p) < p.tok[p.idx + 1].ival): 
        addSon(result, newRstNode(rnLeaf, ":"))
        inc(p.idx)            # skip '::'
        addSon(result, parseLiteralBlock(p))
        break 
      else: 
        parseInline(p, result)
    of tkWhite, tkWord, tkAdornment, tkOther: 
      parseInline(p, result)
    else: break 
  
proc parseParagraphWrapper(p: var TRstParser): PRstNode = 
  result = newRstNode(rnParagraph)
  parseParagraph(p, result)

proc parseHeadline(p: var TRstParser): PRstNode = 
  result = newRstNode(rnHeadline)
  parseLine(p, result)
  assert(p.tok[p.idx].kind == tkIndent)
  assert(p.tok[p.idx + 1].kind == tkAdornment)
  var c = p.tok[p.idx + 1].symbol[0]
  inc(p.idx, 2)
  result.level = getLevel(p.s.underlineToLevel, p.s.uLevel, c)

type 
  TIntSeq = seq[int]

proc tokEnd(p: TRstParser): int = 
  result = p.tok[p.idx].col + len(p.tok[p.idx].symbol) - 1

proc getColumns(p: var TRstParser, cols: var TIntSeq) = 
  var L = 0
  while true: 
    inc(L)
    setlen(cols, L)
    cols[L - 1] = tokEnd(p)
    assert(p.tok[p.idx].kind == tkAdornment)
    inc(p.idx)
    if p.tok[p.idx].kind != tkWhite: break 
    inc(p.idx)
    if p.tok[p.idx].kind != tkAdornment: break 
  if p.tok[p.idx].kind == tkIndent: inc(p.idx)                
  # last column has no limit:
  cols[L - 1] = 32000

proc parseDoc(p: var TRstParser): PRstNode

proc parseSimpleTable(p: var TRstParser): PRstNode = 
  var 
    cols: TIntSeq
    row: seq[string]
    i, last, line: int
    c: Char
    q: TRstParser
    a, b: PRstNode
  result = newRstNode(rnTable)
  cols = @[]
  row = @[]
  a = nil
  c = p.tok[p.idx].symbol[0]
  while true: 
    if p.tok[p.idx].kind == tkAdornment: 
      last = tokenAfterNewline(p)
      if p.tok[last].kind in {tkEof, tkIndent}: 
        # skip last adornment line:
        p.idx = last
        break 
      getColumns(p, cols)
      setlen(row, len(cols))
      if a != nil: 
        for j in countup(0, rsonsLen(a) - 1): a.sons[j].kind = rnTableHeaderCell
    if p.tok[p.idx].kind == tkEof: break 
    for j in countup(0, high(row)): row[j] = ""
    # the following while loop iterates over the lines a single cell may span:
    line = p.tok[p.idx].line
    while true: 
      i = 0
      while not (p.tok[p.idx].kind in {tkIndent, tkEof}): 
        if (tokEnd(p) <= cols[i]): 
          add(row[i], p.tok[p.idx].symbol)
          inc(p.idx)
        else: 
          if p.tok[p.idx].kind == tkWhite: inc(p.idx)
          inc(i)
      if p.tok[p.idx].kind == tkIndent: inc(p.idx)
      if tokEnd(p) <= cols[0]: break 
      if p.tok[p.idx].kind in {tkEof, tkAdornment}: break 
      for j in countup(1, high(row)): add(row[j], '\x0A')
    a = newRstNode(rnTableRow)
    for j in countup(0, high(row)): 
      initParser(q, p.s)
      q.col = cols[j]
      q.line = line - 1
      q.filename = p.filename
      getTokens(row[j], false, q.tok)
      b = newRstNode(rnTableDataCell)
      addSon(b, parseDoc(q))
      addSon(a, b)
    addSon(result, a)

proc parseTransition(p: var TRstParser): PRstNode = 
  result = newRstNode(rnTransition)
  inc(p.idx)
  if p.tok[p.idx].kind == tkIndent: inc(p.idx)
  if p.tok[p.idx].kind == tkIndent: inc(p.idx)
  
proc parseOverline(p: var TRstParser): PRstNode = 
  var c = p.tok[p.idx].symbol[0]
  inc(p.idx, 2)
  result = newRstNode(rnOverline)
  while true: 
    parseLine(p, result)
    if p.tok[p.idx].kind == tkIndent: 
      inc(p.idx)
      if p.tok[p.idx - 1].ival > currInd(p): 
        addSon(result, newRstNode(rnLeaf, " "))
      else: 
        break 
    else: 
      break 
  result.level = getLevel(p.s.overlineToLevel, p.s.oLevel, c)
  if p.tok[p.idx].kind == tkAdornment: 
    inc(p.idx)                # XXX: check?
    if p.tok[p.idx].kind == tkIndent: inc(p.idx)
  
proc parseBulletList(p: var TRstParser): PRstNode = 
  result = nil
  if p.tok[p.idx + 1].kind == tkWhite: 
    var bullet = p.tok[p.idx].symbol
    var col = p.tok[p.idx].col
    result = newRstNode(rnBulletList)
    pushInd(p, p.tok[p.idx + 2].col)
    inc(p.idx, 2)
    while true: 
      var item = newRstNode(rnBulletItem)
      parseSection(p, item)
      addSon(result, item)
      if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx].ival == col) and
          (p.tok[p.idx + 1].symbol == bullet) and
          (p.tok[p.idx + 2].kind == tkWhite): 
        inc(p.idx, 3)
      else: 
        break 
    popInd(p)

proc parseOptionList(p: var TRstParser): PRstNode = 
  result = newRstNode(rnOptionList)
  while true: 
    if isOptionList(p):
      var a = newRstNode(rnOptionGroup)
      var b = newRstNode(rnDescription)
      var c = newRstNode(rnOptionListItem)
      if match(p, p.idx, "//w"): inc(p.idx)
      while not (p.tok[p.idx].kind in {tkIndent, tkEof}): 
        if (p.tok[p.idx].kind == tkWhite) and (len(p.tok[p.idx].symbol) > 1): 
          inc(p.idx)
          break 
        addSon(a, newLeaf(p))
        inc(p.idx)
      var j = tokenAfterNewline(p)
      if (j > 0) and (p.tok[j - 1].kind == tkIndent) and
          (p.tok[j - 1].ival > currInd(p)): 
        pushInd(p, p.tok[j - 1].ival)
        parseSection(p, b)
        popInd(p)
      else: 
        parseLine(p, b)
      if (p.tok[p.idx].kind == tkIndent): inc(p.idx)
      addSon(c, a)
      addSon(c, b)
      addSon(result, c)
    else: 
      break 
  
proc parseDefinitionList(p: var TRstParser): PRstNode = 
  result = nil
  var j = tokenAfterNewLine(p) - 1
  if (j >= 1) and (p.tok[j].kind == tkIndent) and
      (p.tok[j].ival > currInd(p)) and (p.tok[j - 1].symbol != "::"): 
    var col = p.tok[p.idx].col
    result = newRstNode(rnDefList)
    while true: 
      j = p.idx
      var a = newRstNode(rnDefName)
      parseLine(p, a)
      if (p.tok[p.idx].kind == tkIndent) and
          (p.tok[p.idx].ival > currInd(p)) and
          (p.tok[p.idx + 1].symbol != "::") and
          not (p.tok[p.idx + 1].kind in {tkIndent, tkEof}): 
        pushInd(p, p.tok[p.idx].ival)
        var b = newRstNode(rnDefBody)
        parseSection(p, b)
        var c = newRstNode(rnDefItem)
        addSon(c, a)
        addSon(c, b)
        addSon(result, c)
        popInd(p)
      else: 
        p.idx = j
        break 
      if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx].ival == col): 
        inc(p.idx)
        j = tokenAfterNewLine(p) - 1
        if (j >= 1) and (p.tok[j].kind == tkIndent) and (p.tok[j].ival > col) and
            (p.tok[j - 1].symbol != "::") and (p.tok[j + 1].kind != tkIndent): 
          nil
        else: 
          break 
    if rsonsLen(result) == 0: result = nil
  
proc parseEnumList(p: var TRstParser): PRstNode = 
  const 
    wildcards: array[0..2, string] = ["(e) ", "e) ", "e. "]
    wildpos: array[0..2, int] = [1, 0, 0]
  result = nil
  var w = 0
  while w <= 2: 
    if match(p, p.idx, wildcards[w]): break 
    inc(w)
  if w <= 2: 
    var col = p.tok[p.idx].col
    result = newRstNode(rnEnumList)
    inc(p.idx, wildpos[w] + 3)
    var j = tokenAfterNewLine(p)
    if (p.tok[j].col == p.tok[p.idx].col) or match(p, j, wildcards[w]): 
      pushInd(p, p.tok[p.idx].col)
      while true: 
        var item = newRstNode(rnEnumItem)
        parseSection(p, item)
        addSon(result, item)
        if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx].ival == col) and
            match(p, p.idx + 1, wildcards[w]): 
          inc(p.idx, wildpos[w] + 4)
        else: 
          break 
      popInd(p)
    else: 
      dec(p.idx, wildpos[w] + 3)
      result = nil

proc sonKind(father: PRstNode, i: int): TRstNodeKind = 
  result = rnLeaf
  if i < rsonsLen(father): result = father.sons[i].kind
  
proc parseSection(p: var TRstParser, result: PRstNode) = 
  while true: 
    var leave = false
    assert(p.idx >= 0)
    while p.tok[p.idx].kind == tkIndent: 
      if currInd(p) == p.tok[p.idx].ival: 
        inc(p.idx)
      elif p.tok[p.idx].ival > currInd(p): 
        pushInd(p, p.tok[p.idx].ival)
        var a = newRstNode(rnBlockQuote)
        parseSection(p, a)
        addSon(result, a)
        popInd(p)
      else: 
        leave = true
        break 
    if leave: break 
    if p.tok[p.idx].kind == tkEof: break 
    var a: PRstNode = nil
    var k = whichSection(p)
    case k
    of rnLiteralBlock: 
      inc(p.idx)              # skip '::'
      a = parseLiteralBlock(p)
    of rnBulletList: a = parseBulletList(p)
    of rnLineblock: a = parseLineBlock(p)
    of rnDirective: a = parseDotDot(p)
    of rnEnumList: a = parseEnumList(p)
    of rnLeaf: rstMessage(p, errNewSectionExpected)
    of rnParagraph: nil
    of rnDefList: a = parseDefinitionList(p)
    of rnFieldList: 
      dec(p.idx)
      a = parseFields(p)
    of rnTransition: a = parseTransition(p)
    of rnHeadline: a = parseHeadline(p)
    of rnOverline: a = parseOverline(p)
    of rnTable: a = parseSimpleTable(p)
    of rnOptionList: a = parseOptionList(p)
    else: InternalError("rst.parseSection()")
    if (a == nil) and (k != rnDirective): 
      a = newRstNode(rnParagraph)
      parseParagraph(p, a)
    addSonIfNotNil(result, a)
  if (sonKind(result, 0) == rnParagraph) and
      (sonKind(result, 1) != rnParagraph): 
    result.sons[0].kind = rnInner
  
proc parseSectionWrapper(p: var TRstParser): PRstNode = 
  result = newRstNode(rnInner)
  parseSection(p, result)
  while (result.kind == rnInner) and (rsonsLen(result) == 1): 
    result = result.sons[0]
  
proc parseDoc(p: var TRstParser): PRstNode = 
  result = parseSectionWrapper(p)
  if p.tok[p.idx].kind != tkEof: rstMessage(p, errGeneralParseError)
  
type
  TDirFlag = enum 
    hasArg, hasOptions, argIsFile, argIsWord
  TDirFlags = set[TDirFlag]
  TSectionParser = proc (p: var TRstParser): PRstNode

proc parseDirective(p: var TRstParser, flags: TDirFlags): PRstNode = 
  result = newRstNode(rnDirective)
  var args: PRstNode = nil
  var options: PRstNode = nil
  if hasArg in flags: 
    args = newRstNode(rnDirArg)
    if argIsFile in flags: 
      while True: 
        case p.tok[p.idx].kind
        of tkWord, tkOther, tkPunct, tkAdornment: 
          addSon(args, newLeaf(p))
          inc(p.idx)
        else: break 
    elif argIsWord in flags:
      while p.tok[p.idx].kind == tkWhite: inc(p.idx)
      if p.tok[p.idx].kind == tkWord: 
        addSon(args, newLeaf(p))
        inc(p.idx)
      else:
        args = nil
    else: 
      parseLine(p, args)
  addSon(result, args)
  if hasOptions in flags: 
    if (p.tok[p.idx].kind == tkIndent) and (p.tok[p.idx].ival >= 3) and
        (p.tok[p.idx + 1].symbol == ":"): 
      options = parseFields(p)
  addSon(result, options)
  
proc indFollows(p: TRstParser): bool = 
  result = p.tok[p.idx].kind == tkIndent and p.tok[p.idx].ival > currInd(p)
  
proc parseDirective(p: var TRstParser, flags: TDirFlags, 
                    contentParser: TSectionParser): PRstNode = 
  result = parseDirective(p, flags)
  if not isNil(contentParser) and indFollows(p): 
    pushInd(p, p.tok[p.idx].ival)
    var content = contentParser(p)
    popInd(p)
    addSon(result, content)
  else: 
    addSon(result, nil)

proc parseDirBody(p: var TRstParser, contentParser: TSectionParser): PRstNode = 
  if indFollows(p): 
    pushInd(p, p.tok[p.idx].ival)
    result = contentParser(p)
    popInd(p)
  
proc dirInclude(p: var TRstParser): PRstNode = 
  #
  #The following options are recognized:
  #
  #start-after : text to find in the external data file
  #    Only the content after the first occurrence of the specified text will
  #    be included.
  #end-before : text to find in the external data file
  #    Only the content before the first occurrence of the specified text
  #    (but after any after text) will be included.
  #literal : flag (empty)
  #    The entire included text is inserted into the document as a single
  #    literal block (useful for program listings).
  #encoding : name of text encoding
  #    The text encoding of the external data file. Defaults to the document's
  #    encoding (if specified).
  #
  result = nil
  var n = parseDirective(p, {hasArg, argIsFile, hasOptions}, nil)
  var filename = strip(addNodes(n.sons[0]))
  var path = findFile(filename)
  if path == "": 
    rstMessage(p, errCannotOpenFile, filename)
  else: 
    # XXX: error handling; recursive file inclusion!
    if getFieldValue(n, "literal") != "": 
      result = newRstNode(rnLiteralBlock)
      addSon(result, newRstNode(rnLeaf, readFile(path)))
    else: 
      var q: TRstParser
      initParser(q, p.s)
      q.filename = filename
      getTokens(readFile(path), false, q.tok) # workaround a GCC bug: 
      if find(q.tok[high(q.tok)].symbol, "\0\x01\x02") > 0: 
        InternalError("Too many binary zeros in include file")
      result = parseDoc(q)

proc dirCodeBlock(p: var TRstParser): PRstNode = 
  result = parseDirective(p, {hasArg, hasOptions}, parseLiteralBlock)
  var filename = strip(getFieldValue(result, "file"))
  if filename != "": 
    var path = findFile(filename)
    if path == "": rstMessage(p, errCannotOpenFile, filename)
    var n = newRstNode(rnLiteralBlock)
    addSon(n, newRstNode(rnLeaf, readFile(path)))
    result.sons[2] = n
  result.kind = rnCodeBlock

proc dirContainer(p: var TRstParser): PRstNode = 
  result = parseDirective(p, {hasArg}, parseSectionWrapper)
  assert(result.kind == rnDirective)
  assert(rsonsLen(result) == 3)
  result.kind = rnContainer

proc dirImage(p: var TRstParser): PRstNode = 
  result = parseDirective(p, {hasOptions, hasArg, argIsFile}, nil)
  result.kind = rnImage

proc dirFigure(p: var TRstParser): PRstNode = 
  result = parseDirective(p, {hasOptions, hasArg, argIsFile}, 
                          parseSectionWrapper)
  result.kind = rnFigure

proc dirTitle(p: var TRstParser): PRstNode = 
  result = parseDirective(p, {hasArg}, nil)
  result.kind = rnTitle

proc dirContents(p: var TRstParser): PRstNode = 
  result = parseDirective(p, {hasArg}, nil)
  result.kind = rnContents

proc dirIndex(p: var TRstParser): PRstNode = 
  result = parseDirective(p, {}, parseSectionWrapper)
  result.kind = rnIndex

proc dirRawAux(p: var TRstParser, result: var PRstNode, kind: TRstNodeKind,
               contentParser: TSectionParser) = 
  var filename = getFieldValue(result, "file")
  if filename.len > 0: 
    var path = findFile(filename)
    if path.len == 0: 
      rstMessage(p, errCannotOpenFile, filename)
    else: 
      var f = readFile(path)
      result = newRstNode(kind)
      addSon(result, newRstNode(rnLeaf, f))
  else:      
    result.kind = kind
    addSon(result, parseDirBody(p, contentParser))

proc dirRaw(p: var TRstParser): PRstNode = 
  #
  #The following options are recognized:
  #
  #file : string (newlines removed)
  #    The local filesystem path of a raw data file to be included.
  #
  # html
  # latex
  result = parseDirective(p, {hasOptions, hasArg, argIsWord})
  if result.sons[0] != nil:
    if cmpIgnoreCase(result.sons[0].sons[0].text, "html") == 0:
      dirRawAux(p, result, rnRawHtml, parseLiteralBlock)
    elif cmpIgnoreCase(result.sons[0].sons[0].text, "latex") == 0: 
      dirRawAux(p, result, rnRawLatex, parseLiteralBlock)
    else:
      rstMessage(p, errInvalidDirectiveX, result.sons[0].text)
  else:
    dirRawAux(p, result, rnRaw, parseSectionWrapper)

proc parseDotDot(p: var TRstParser): PRstNode = 
  result = nil
  var col = p.tok[p.idx].col
  inc(p.idx)
  var d = getDirective(p)
  if d != "": 
    pushInd(p, col)
    case getDirKind(d)
    of dkInclude: result = dirInclude(p)
    of dkImage: result = dirImage(p)
    of dkFigure: result = dirFigure(p)
    of dkTitle: result = dirTitle(p)
    of dkContainer: result = dirContainer(p)
    of dkContents: result = dirContents(p)
    of dkRaw: result = dirRaw(p)
    of dkCodeblock: result = dirCodeBlock(p)
    of dkIndex: result = dirIndex(p)
    else: rstMessage(p, errInvalidDirectiveX, d)
    popInd(p)
  elif match(p, p.idx, " _"): 
    # hyperlink target:
    inc(p.idx, 2)
    var a = getReferenceName(p, ":")
    if p.tok[p.idx].kind == tkWhite: inc(p.idx)
    var b = untilEol(p)
    setRef(p, rstnodeToRefname(a), b)
  elif match(p, p.idx, " |"): 
    # substitution definitions:
    inc(p.idx, 2)
    var a = getReferenceName(p, "|")
    var b: PRstNode
    if p.tok[p.idx].kind == tkWhite: inc(p.idx)
    if cmpIgnoreStyle(p.tok[p.idx].symbol, "replace") == 0: 
      inc(p.idx)
      expect(p, "::")
      b = untilEol(p)
    elif cmpIgnoreStyle(p.tok[p.idx].symbol, "image") == 0: 
      inc(p.idx)
      b = dirImage(p)
    else: 
      rstMessage(p, errInvalidDirectiveX, p.tok[p.idx].symbol)
    setSub(p, addNodes(a), b)
  elif match(p, p.idx, " ["): 
    # footnotes, citations
    inc(p.idx, 2)
    var a = getReferenceName(p, "]")
    if p.tok[p.idx].kind == tkWhite: inc(p.idx)
    var b = untilEol(p)
    setRef(p, rstnodeToRefname(a), b)
  else: 
    result = parseComment(p)
  
proc resolveSubs(p: var TRstParser, n: PRstNode): PRstNode = 
  result = n
  if n == nil: return 
  case n.kind
  of rnSubstitutionReferences: 
    var x = findSub(p, n)
    if x >= 0: 
      result = p.s.subs[x].value
    else: 
      var key = addNodes(n)
      var e = getEnv(key)
      if e != "": result = newRstNode(rnLeaf, e)
      else: rstMessage(p, warnUnknownSubstitutionX, key)
  of rnRef: 
    var y = findRef(p, rstnodeToRefname(n))
    if y != nil: 
      result = newRstNode(rnHyperlink)
      n.kind = rnInner
      addSon(result, n)
      addSon(result, y)
  of rnLeaf: 
    nil
  of rnContents: 
    p.hasToc = true
  else: 
    for i in countup(0, rsonsLen(n) - 1): n.sons[i] = resolveSubs(p, n.sons[i])
  
proc rstParse(text: string,   # the text to be parsed
              skipPounds: bool, filename: string, # for error messages
              line, column: int, hasToc: var bool): PRstNode = 
  var p: TRstParser
  if isNil(text): rawMessage(errCannotOpenFile, filename)
  initParser(p, newSharedState())
  p.filename = filename
  p.line = line
  p.col = column
  getTokens(text, skipPounds, p.tok)
  result = resolveSubs(p, parseDoc(p))
  hasToc = p.hasToc
