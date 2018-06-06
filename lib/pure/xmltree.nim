#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## A simple XML tree. More efficient and simpler than the DOM.

import macros, strtabs, strutils

type
  XmlNode* = ref XmlNodeObj ## an XML tree consists of ``XmlNode``'s.

  XmlNodeKind* = enum  ## different kinds of ``XmlNode``'s
    xnText,             ## a text element
    xnElement,          ## an element with 0 or more children
    xnCData,            ## a CDATA node
    xnEntity,           ## an entity (like ``&thing;``)
    xnComment           ## an XML comment

  XmlAttributes* = StringTableRef ## an alias for a string to string mapping

  XmlNodeObj {.acyclic.} = object
    case k: XmlNodeKind # private, use the kind() proc to read this field.
    of xnText, xnComment, xnCData, xnEntity:
      fText: string
    of xnElement:
      fTag: string
      s: seq[XmlNode]
      fAttr: XmlAttributes
    fClientData: int              ## for other clients

proc newXmlNode(kind: XmlNodeKind): XmlNode =
  ## creates a new ``XmlNode``.
  new(result)
  result.k = kind

proc newElement*(tag: string): XmlNode =
  ## creates a new ``PXmlNode`` of kind ``xnText`` with the given `tag`.
  result = newXmlNode(xnElement)
  result.fTag = tag
  result.s = @[]
  # init attributes lazily to safe memory

proc newText*(text: string): XmlNode =
  ## creates a new ``PXmlNode`` of kind ``xnText`` with the text `text`.
  result = newXmlNode(xnText)
  result.fText = text

proc newComment*(comment: string): XmlNode =
  ## creates a new ``PXmlNode`` of kind ``xnComment`` with the text `comment`.
  result = newXmlNode(xnComment)
  result.fText = comment

proc newCData*(cdata: string): XmlNode =
  ## creates a new ``PXmlNode`` of kind ``xnComment`` with the text `cdata`.
  result = newXmlNode(xnCData)
  result.fText = cdata

proc newEntity*(entity: string): XmlNode =
  ## creates a new ``PXmlNode`` of kind ``xnEntity`` with the text `entity`.
  result = newXmlNode(xnEntity)
  result.fText = entity

proc text*(n: XmlNode): string {.inline.} =
  ## gets the associated text with the node `n`. `n` can be a CDATA, Text,
  ## comment, or entity node.
  assert n.k in {xnText, xnComment, xnCData, xnEntity}
  result = n.fText

proc `text=`*(n: XmlNode, text: string){.inline.} =
  ## sets the associated text with the node `n`. `n` can be a CDATA, Text,
  ## comment, or entity node.
  assert n.k in {xnText, xnComment, xnCData, xnEntity}
  n.fText = text

proc rawText*(n: XmlNode): string {.inline.} =
  ## returns the underlying 'text' string by reference.
  ## This is only used for speed hacks.
  shallowCopy(result, n.fText)

proc rawTag*(n: XmlNode): string {.inline.} =
  ## returns the underlying 'tag' string by reference.
  ## This is only used for speed hacks.
  shallowCopy(result, n.fTag)

proc innerText*(n: XmlNode): string =
  ## gets the inner text of `n`:
  ##
  ## - If `n` is `xnText` or `xnEntity`, returns its content.
  ## - If `n` is `xnElement`, runs recursively on each child node and
  ##   concatenates the results.
  ## - Otherwise returns an empty string.
  proc worker(res: var string, n: XmlNode) =
    case n.k
    of xnText, xnEntity:
      res.add(n.fText)
    of xnElement:
      for sub in n.s:
        worker(res, sub)
    else:
      discard

  result = ""
  worker(result, n)

proc tag*(n: XmlNode): string {.inline.} =
  ## gets the tag name of `n`. `n` has to be an ``xnElement`` node.
  assert n.k == xnElement
  result = n.fTag

proc `tag=`*(n: XmlNode, tag: string) {.inline.} =
  ## sets the tag name of `n`. `n` has to be an ``xnElement`` node.
  assert n.k == xnElement
  n.fTag = tag

proc add*(father, son: XmlNode) {.inline.} =
  ## adds the child `son` to `father`.
  add(father.s, son)

proc insert*(father, son: XmlNode, index: int) {.inline.} =
  ## insert the child `son` to a given position in `father`.
  assert father.k == xnElement and son.k == xnElement
  if len(father.s) > index:
    insert(father.s, son, index)
  else:
    insert(father.s, son, len(father.s))

proc len*(n: XmlNode): int {.inline.} =
  ## returns the number `n`'s children.
  if n.k == xnElement: result = len(n.s)

proc kind*(n: XmlNode): XmlNodeKind {.inline.} =
  ## returns `n`'s kind.
  result = n.k

proc `[]`* (n: XmlNode, i: int): XmlNode {.inline.} =
  ## returns the `i`'th child of `n`.
  assert n.k == xnElement
  result = n.s[i]

proc delete*(n: XmlNode, i: Natural) {.noSideEffect.} =
  ## delete the `i`'th child of `n`.
  assert n.k == xnElement
  n.s.delete(i)

proc `[]`* (n: var XmlNode, i: int): var XmlNode {.inline.} =
  ## returns the `i`'th child of `n` so that it can be modified
  assert n.k == xnElement
  result = n.s[i]

iterator items*(n: XmlNode): XmlNode {.inline.} =
  ## iterates over any child of `n`.
  assert n.k == xnElement
  for i in 0 .. n.len-1: yield n[i]

iterator mitems*(n: var XmlNode): var XmlNode {.inline.} =
  ## iterates over any child of `n`.
  assert n.k == xnElement
  for i in 0 .. n.len-1: yield n[i]

proc attrs*(n: XmlNode): XmlAttributes {.inline.} =
  ## gets the attributes belonging to `n`.
  ## Returns `nil` if attributes have not been initialised for this node.
  assert n.k == xnElement
  result = n.fAttr

proc `attrs=`*(n: XmlNode, attr: XmlAttributes) {.inline.} =
  ## sets the attributes belonging to `n`.
  assert n.k == xnElement
  n.fAttr = attr

proc attrsLen*(n: XmlNode): int {.inline.} =
  ## returns the number of `n`'s attributes.
  assert n.k == xnElement
  if not isNil(n.fAttr): result = len(n.fAttr)

proc clientData*(n: XmlNode): int {.inline.} =
  ## gets the client data of `n`. The client data field is used by the HTML
  ## parser and generator.
  result = n.fClientData

proc `clientData=`*(n: XmlNode, data: int) {.inline.} =
  ## sets the client data of `n`. The client data field is used by the HTML
  ## parser and generator.
  n.fClientData = data

proc addEscaped*(result: var string, s: string) =
  ## same as ``result.add(escape(s))``, but more efficient.
  for c in items(s):
    case c
    of '<': result.add("&lt;")
    of '>': result.add("&gt;")
    of '&': result.add("&amp;")
    of '"': result.add("&quot;")
    of '\'': result.add("&#x27;")
    of '/': result.add("&#x2F;")
    else: result.add(c)

proc escape*(s: string): string =
  ## escapes `s` for inclusion into an XML document.
  ## Escapes these characters:
  ##
  ## ------------    -------------------
  ## char            is converted to
  ## ------------    -------------------
  ##  ``<``          ``&lt;``
  ##  ``>``          ``&gt;``
  ##  ``&``          ``&amp;``
  ##  ``"``          ``&quot;``
  ##  ``'``          ``&#x27;``
  ##  ``/``          ``&#x2F;``
  ## ------------    -------------------
  result = newStringOfCap(s.len)
  addEscaped(result, s)

proc addIndent(result: var string, indent: int, addNewLines: bool) =
  if addNewLines:
    result.add("\n")
  for i in 1..indent: result.add(' ')

proc noWhitespace(n: XmlNode): bool =
  #for i in 1..n.len-1:
  #  if n[i].kind != n[0].kind: return true
  for i in 0..n.len-1:
    if n[i].kind in {xnText, xnEntity}: return true

proc add*(result: var string, n: XmlNode, indent = 0, indWidth = 2,
          addNewLines=true) =
  ## adds the textual representation of `n` to `result`.

  proc addEscapedAttr(result: var string, s: string) =
    # `addEscaped` alternative with less escaped characters.
    # Only to be used for escaping attribute values enclosed in double quotes!
    for c in items(s):
      case c
      of '<': result.add("&lt;")
      of '>': result.add("&gt;")
      of '&': result.add("&amp;")
      of '"': result.add("&quot;")
      else: result.add(c)

  if n == nil: return
  case n.k
  of xnElement:
    result.add('<')
    result.add(n.fTag)
    if not isNil(n.fAttr):
      for key, val in pairs(n.fAttr):
        result.add(' ')
        result.add(key)
        result.add("=\"")
        result.addEscapedAttr(val)
        result.add('"')
    if n.len > 0:
      result.add('>')
      if n.len > 1:
        if noWhitespace(n):
          # for mixed leaves, we cannot output whitespace for readability,
          # because this would be wrong. For example: ``a<b>b</b>`` is
          # different from ``a <b>b</b>``.
          for i in 0..n.len-1:
            result.add(n[i], indent+indWidth, indWidth, addNewLines)
        else:
          for i in 0..n.len-1:
            result.addIndent(indent+indWidth, addNewLines)
            result.add(n[i], indent+indWidth, indWidth, addNewLines)
          result.addIndent(indent, addNewLines)
      else:
        result.add(n[0], indent+indWidth, indWidth, addNewLines)
      result.add("</")
      result.add(n.fTag)
      result.add(">")
    else:
      result.add(" />")
  of xnText:
    result.addEscaped(n.fText)
  of xnComment:
    result.add("<!-- ")
    result.addEscaped(n.fText)
    result.add(" -->")
  of xnCData:
    result.add("<![CDATA[")
    result.add(n.fText)
    result.add("]]>")
  of xnEntity:
    result.add('&')
    result.add(n.fText)
    result.add(';')

const
  xmlHeader* = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
    ## header to use for complete XML output

proc `$`*(n: XmlNode): string =
  ## converts `n` into its string representation. No ``<$xml ...$>`` declaration
  ## is produced, so that the produced XML fragments are composable.
  result = ""
  result.add(n)

proc newXmlTree*(tag: string, children: openArray[XmlNode],
                 attributes: XmlAttributes = nil): XmlNode =
  ## creates a new XML tree with `tag`, `children` and `attributes`
  result = newXmlNode(xnElement)
  result.fTag = tag
  newSeq(result.s, children.len)
  for i in 0..children.len-1: result.s[i] = children[i]
  result.fAttr = attributes

proc xmlConstructor(a: NimNode): NimNode {.compileTime.} =
  if a.kind == nnkCall:
    result = newCall("newXmlTree", toStrLit(a[0]))
    var attrs = newNimNode(nnkBracket, a)
    var newStringTabCall = newCall(bindSym"newStringTable", attrs,
                                    bindSym"modeCaseSensitive")
    var elements = newNimNode(nnkBracket, a)
    for i in 1..a.len-1:
      if a[i].kind == nnkExprEqExpr:
        # In order to support attributes like `data-lang` we have to
        # replace whitespace because `toStrLit` gives `data - lang`.
        let attrName = toStrLit(a[i][0]).strVal.replace(" ", "")
        attrs.add(newStrLitNode(attrName))
        attrs.add(a[i][1])
        #echo repr(attrs)
      else:
        elements.add(a[i])
    result.add(elements)
    if attrs.len > 1:
      #echo repr(newStringTabCall)
      result.add(newStringTabCall)
  else:
    result = newCall("newXmlTree", toStrLit(a))

macro `<>`*(x: untyped): untyped =
  ## Constructor macro for XML. Example usage:
  ##
  ## .. code-block:: nim
  ##   <>a(href="http://nim-lang.org", newText("Nim rules."))
  ##
  ## Produces an XML tree for::
  ##
  ##  <a href="http://nim-lang.org">Nim rules.</a>
  ##
  result = xmlConstructor(x)

proc child*(n: XmlNode, name: string): XmlNode =
  ## Finds the first child element of `n` with a name of `name`.
  ## Returns `nil` on failure.
  assert n.kind == xnElement
  for i in items(n):
    if i.kind == xnElement:
      if i.tag == name:
        return i

proc attr*(n: XmlNode, name: string): string =
  ## Finds the first attribute of `n` with a name of `name`.
  ## Returns "" on failure.
  assert n.kind == xnElement
  if n.attrs == nil: return ""
  return n.attrs.getOrDefault(name)

proc findAll*(n: XmlNode, tag: string, result: var seq[XmlNode]) =
  ## Iterates over all the children of `n` returning those matching `tag`.
  ##
  ## Found nodes satisfying the condition will be appended to the `result`
  ## sequence, which can't be nil or the proc will crash. Usage example:
  ##
  ## .. code-block::
  ##   var
  ##     html: XmlNode
  ##     tags: seq[XmlNode] = @[]
  ##
  ##   html = buildHtml()
  ##   findAll(html, "img", tags)
  ##   for imgTag in tags:
  ##     process(imgTag)
  assert isNil(result) == false
  assert n.k == xnElement
  for child in n.items():
    if child.k != xnElement:
      continue
    if child.tag == tag:
      result.add(child)
    child.findAll(tag, result)

proc findAll*(n: XmlNode, tag: string): seq[XmlNode] =
  ## Shortcut version to assign in let blocks. Example:
  ##
  ## .. code-block::
  ##   var html: XmlNode
  ##
  ##   html = buildHtml(html)
  ##   for imgTag in html.findAll("img"):
  ##     process(imgTag)
  newSeq(result, 0)
  findAll(n, tag, result)

when isMainModule:
  assert """<a href="http://nim-lang.org">Nim rules.</a>""" ==
    $(<>a(href="http://nim-lang.org", newText("Nim rules.")))
