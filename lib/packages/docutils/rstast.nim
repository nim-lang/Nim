#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements an AST for the `reStructuredText`:idx: parser.

import strutils, json

type
  RstNodeKind* = enum        ## the possible node kinds of an PRstNode
    rnInner,                  # an inner node or a root
    rnHeadline,               # a headline
    rnOverline,               # an over- and underlined headline
    rnMarkdownHeadline,       # a Markdown headline
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
    rnLineBlockItem,          # a son of rnLineBlock - one line inside it.
                              # When `RstNode` lineIndent="\n" the line's empty
    rnBlockQuote,             # text just indented
    rnTable, rnGridTable, rnMarkdownTable, rnTableRow, rnTableHeaderCell, rnTableDataCell,
    rnFootnote,               # a footnote
    rnCitation,               # similar to footnote, so use rnFootnote instead
    rnFootnoteGroup,          # footnote group - exists for a purely stylistic
                              # reason: to display a few footnotes as 1 block
    rnStandaloneHyperlink, rnHyperlink, rnRef, rnInternalRef, rnFootnoteRef,
    rnDirective,              # a general directive
    rnDirArg,                 # a directive argument (for some directives).
                              # here are directives that are not rnDirective:
    rnRaw, rnTitle, rnContents, rnImage, rnFigure, rnCodeBlock, rnAdmonition,
    rnRawHtml, rnRawLatex,
    rnContainer,              # ``container`` directive
    rnIndex,                  # index directve:
                              # .. index::
                              #   key
                              #     * `file#id <file#id>`_
                              #     * `file#id <file#id>'_
    rnSubstitutionDef,        # a definition of a substitution
    # Inline markup:
    rnInlineCode,             # interpreted text with code in a known language
    rnCodeFragment,           # inline code for highlighting with the specified
                              # class (which cannot be inferred from context)
    rnUnknownRole,            # interpreted text with an unknown role
    rnSub, rnSup, rnIdx,
    rnEmphasis,               # "*"
    rnStrongEmphasis,         # "**"
    rnTripleEmphasis,         # "***"
    rnInterpretedText,        # "`" an auxiliary role for parsing that will
                              # be converted into other kinds like rnInlineCode
    rnInlineLiteral,          # "``"
    rnInlineTarget,           # "_`target`"
    rnSubstitutionReferences, # "|"
    rnSmiley,                 # some smiley
    rnDefaultRole,            # .. default-role:: code
    rnLeaf                    # a leaf; the node's text field contains the
                              # leaf val

  FileIndex* = distinct int32
  TLineInfo* = object
    line*: uint16
    col*: int16
    fileIndex*: FileIndex

  PRstNode* = ref RstNode    ## an RST node
  RstNodeSeq* = seq[PRstNode]
  RstNode* {.acyclic, final.} = object ## AST node (result of RST parsing)
    case kind*: RstNodeKind ## the node's kind
    of rnLeaf, rnSmiley:
      text*: string           ## string that is expected to be displayed
    of rnEnumList:
      labelFmt*: string       ## label format like "(1)"
    of rnLineBlockItem:
      lineIndent*: string     ## a few spaces or newline at the line beginning
    of rnAdmonition:
      adType*: string         ## admonition type: "note", "caution", etc. This
                              ## text will set the style and also be displayed
    of rnOverline, rnHeadline, rnMarkdownHeadline:
      level*: int             ## level of headings starting from 1 (main
                              ## chapter) to larger ones (minor sub-sections)
                              ## level=0 means it's document title or subtitle
    of rnFootnote, rnCitation, rnOptionListItem:
      order*: int             ## footnote order (for auto-symbol footnotes and
                              ## auto-numbered ones without a label)
    of rnRef, rnSubstitutionReferences,
        rnInterpretedText, rnField, rnInlineCode, rnCodeBlock, rnFootnoteRef:
      info*: TLineInfo        ## To have line/column info for warnings at
                              ## nodes that are post-processed after parsing
    else:
      discard
    anchor*: string           ## anchor, internal link target
                              ## (aka HTML id tag, aka Latex label/hypertarget)
    sons*: RstNodeSeq        ## the node's sons

proc `==`*(a, b: FileIndex): bool {.borrow.}

proc len*(n: PRstNode): int =
  result = len(n.sons)

proc newRstNode*(kind: RstNodeKind, sons: seq[PRstNode] = @[],
                 anchor = ""): PRstNode =
  result = PRstNode(kind: kind, sons: sons, anchor: anchor)

proc newRstNode*(kind: RstNodeKind, info: TLineInfo,
                 sons: seq[PRstNode] = @[]): PRstNode =
  result = PRstNode(kind: kind, sons: sons)
  result.info = info

proc newRstNode*(kind: RstNodeKind, s: string): PRstNode {.deprecated.} =
  assert kind in {rnLeaf, rnSmiley}
  result = newRstNode(kind)
  result.text = s

proc newRstLeaf*(s: string): PRstNode =
  result = newRstNode(rnLeaf)
  result.text = s

proc lastSon*(n: PRstNode): PRstNode =
  result = n.sons[len(n.sons)-1]

proc add*(father, son: PRstNode) =
  add(father.sons, son)

proc add*(father: PRstNode; s: string) =
  add(father.sons, newRstLeaf(s))

proc addIfNotNil*(father, son: PRstNode) =
  if son != nil: add(father, son)


type
  RenderContext {.pure.} = object
    indent: int
    verbatim: int

proc renderRstToRst(d: var RenderContext, n: PRstNode,
                    result: var string) {.gcsafe.}

proc renderRstSons(d: var RenderContext, n: PRstNode, result: var string) =
  for i in countup(0, len(n) - 1):
    renderRstToRst(d, n.sons[i], result)

proc renderRstToRst(d: var RenderContext, n: PRstNode, result: var string) =
  # this is needed for the index generation; it may also be useful for
  # debugging, but most code is already debugged...
  const
    lvlToChar: array[0..8, char] = ['!', '=', '-', '~', '`', '<', '*', '|', '+']
  if n == nil: return
  var ind = spaces(d.indent)
  case n.kind
  of rnInner:
    renderRstSons(d, n, result)
  of rnHeadline:
    result.add("\n")
    result.add(ind)

    let oldLen = result.len
    renderRstSons(d, n, result)
    let headlineLen = result.len - oldLen

    result.add("\n")
    result.add(ind)
    result.add repeat(lvlToChar[n.level], headlineLen)
  of rnOverline:
    result.add("\n")
    result.add(ind)

    var headline = ""
    renderRstSons(d, n, headline)

    let lvl = repeat(lvlToChar[n.level], headline.len - d.indent)
    result.add(lvl)
    result.add("\n")
    result.add(headline)

    result.add("\n")
    result.add(ind)
    result.add(lvl)
  of rnTransition:
    result.add("\n\n")
    result.add(ind)
    result.add repeat('-', 78-d.indent)
    result.add("\n\n")
  of rnParagraph:
    result.add("\n\n")
    result.add(ind)
    renderRstSons(d, n, result)
  of rnBulletItem:
    inc(d.indent, 2)
    var tmp = ""
    renderRstSons(d, n, tmp)
    if tmp.len > 0:
      result.add("\n")
      result.add(ind)
      result.add("* ")
      result.add(tmp)
    dec(d.indent, 2)
  of rnEnumItem:
    inc(d.indent, 4)
    var tmp = ""
    renderRstSons(d, n, tmp)
    if tmp.len > 0:
      result.add("\n")
      result.add(ind)
      result.add("(#) ")
      result.add(tmp)
    dec(d.indent, 4)
  of rnOptionList, rnFieldList, rnDefList, rnDefItem, rnLineBlock, rnFieldName,
     rnFieldBody, rnStandaloneHyperlink, rnBulletList, rnEnumList:
    renderRstSons(d, n, result)
  of rnDefName:
    result.add("\n\n")
    result.add(ind)
    renderRstSons(d, n, result)
  of rnDefBody:
    inc(d.indent, 2)
    if n.sons[0].kind != rnBulletList:
      result.add("\n")
      result.add(ind)
      result.add("  ")
    renderRstSons(d, n, result)
    dec(d.indent, 2)
  of rnField:
    var tmp = ""
    renderRstToRst(d, n.sons[0], tmp)

    var L = max(tmp.len + 3, 30)
    inc(d.indent, L)

    result.add "\n"
    result.add ind
    result.add ':'
    result.add tmp
    result.add ':'
    result.add spaces(L - tmp.len - 2)
    renderRstToRst(d, n.sons[1], result)

    dec(d.indent, L)
  of rnLineBlockItem:
    result.add("\n")
    result.add(ind)
    result.add("| ")
    renderRstSons(d, n, result)
  of rnBlockQuote:
    inc(d.indent, 2)
    renderRstSons(d, n, result)
    dec(d.indent, 2)
  of rnRef:
    result.add("`")
    renderRstSons(d, n, result)
    result.add("`_")
  of rnHyperlink:
    result.add('`')
    renderRstToRst(d, n.sons[0], result)
    result.add(" <")
    renderRstToRst(d, n.sons[1], result)
    result.add(">`_")
  of rnUnknownRole:
    result.add('`')
    renderRstToRst(d, n.sons[0],result)
    result.add("`:")
    renderRstToRst(d, n.sons[1],result)
    result.add(':')
  of rnSub:
    result.add('`')
    renderRstSons(d, n, result)
    result.add("`:sub:")
  of rnSup:
    result.add('`')
    renderRstSons(d, n, result)
    result.add("`:sup:")
  of rnIdx:
    result.add('`')
    renderRstSons(d, n, result)
    result.add("`:idx:")
  of rnEmphasis:
    result.add("*")
    renderRstSons(d, n, result)
    result.add("*")
  of rnStrongEmphasis:
    result.add("**")
    renderRstSons(d, n, result)
    result.add("**")
  of rnTripleEmphasis:
    result.add("***")
    renderRstSons(d, n, result)
    result.add("***")
  of rnInterpretedText:
    result.add('`')
    renderRstSons(d, n, result)
    result.add('`')
  of rnInlineLiteral:
    inc(d.verbatim)
    result.add("``")
    renderRstSons(d, n, result)
    result.add("``")
    dec(d.verbatim)
  of rnSmiley:
    result.add(n.text)
  of rnLeaf:
    if d.verbatim == 0 and n.text == "\\":
      result.add("\\\\") # XXX: escape more special characters!
    else:
      result.add(n.text)
  of rnIndex:
    result.add("\n\n")
    result.add(ind)
    result.add(".. index::\n")

    inc(d.indent, 3)
    if n.sons[2] != nil: renderRstSons(d, n.sons[2], result)
    dec(d.indent, 3)
  of rnContents:
    result.add("\n\n")
    result.add(ind)
    result.add(".. contents::")
  else:
    result.add("Error: cannot render: " & $n.kind)

proc renderRstToRst*(n: PRstNode, result: var string) =
  ## renders `n` into its string representation and appends to `result`.
  var d: RenderContext
  renderRstToRst(d, n, result)

proc renderRstToJsonNode(node: PRstNode): JsonNode =
  result =
    %[
      (key: "kind", val: %($node.kind)),
      (key: "level", val: %BiggestInt(node.level))
     ]
  if node.kind in {rnLeaf, rnSmiley} and node.text.len > 0:
    result.add("text", %node.text)
  if len(node.sons) > 0:
    var accm = newSeq[JsonNode](len(node.sons))
    for i, son in node.sons:
      accm[i] = renderRstToJsonNode(son)
    result.add("sons", %accm)

proc renderRstToJson*(node: PRstNode): string =
  ## Writes the given RST node as JSON that is in the form
  ## ::
  ##   {
  ##     "kind":string node.kind,
  ##     "text":optional string node.text,
  ##     "level":optional int node.level,
  ##     "sons":optional node array
  ##   }
  renderRstToJsonNode(node).pretty

proc renderRstToText*(node: PRstNode): string =
  ## minimal text representation of markup node
  const code = {rnCodeFragment, rnInterpretedText, rnInlineLiteral, rnInlineCode}
  if node == nil:
    return ""
  case node.kind
  of rnLeaf, rnSmiley:
    result.add node.text
  else:
    if node.kind in code: result.add "`"
    for i in 0 ..< node.sons.len:
      if node.kind in {rnInlineCode, rnCodeBlock} and i == 0:
        continue  # omit language specifier
      result.add renderRstToText(node.sons[i])
    if node.kind in code: result.add "`"

proc renderRstToStr*(node: PRstNode, indent=0): string =
  ## Writes the parsed RST `node` into an AST tree with compact string
  ## representation in the format (one line per every sub-node):
  ## ``indent - kind - [text|level|order|adType] - anchor (if non-zero)``
  ## (suitable for debugging of RST parsing).
  if node == nil:
    result.add " ".repeat(indent) & "[nil]\n"
    return
  result.add " ".repeat(indent) & $node.kind
  case node.kind
  of rnLeaf, rnSmiley:
    result.add (if node.text == "": "" else: "  '" & node.text & "'")
  of rnEnumList:
    result.add "  labelFmt=" & node.labelFmt
  of rnLineBlockItem:
    var txt: string
    if node.lineIndent == "\n": txt = "  (blank line)"
    else: txt = "  lineIndent=" & $node.lineIndent.len
    result.add txt
  of rnAdmonition:
    result.add "  adType=" & node.adType
  of rnHeadline, rnOverline, rnMarkdownHeadline:
    result.add "  level=" & $node.level
  of rnFootnote, rnCitation, rnOptionListItem:
    result.add (if node.order == 0:   "" else: "  order=" & $node.order)
  else:
    discard
  result.add (if node.anchor == "": "" else: "  anchor='" & node.anchor & "'")
  result.add "\n"
  for son in node.sons:
    result.add renderRstToStr(son, indent=indent+2)
