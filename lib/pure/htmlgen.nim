#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## **Warning**: This module uses ``immediate`` macros which are known to
## cause problems. Do yourself a favor and import the module
## as ``from htmlgen import nil`` and then fully qualify the macros.
##
##
## This module implements a simple `XML`:idx: and `HTML`:idx: code
## generator. Each commonly used HTML tag has a corresponding macro
## that generates a string with its HTML representation.
##
## Example:
##
## .. code-block:: Nim
##   var nim = "Nim"
##   echo h1(a(href="http://nim-lang.org", nim))
##
## Writes the string::
##
##   <h1><a href="http://nim-lang.org">Nim</a></h1>
##

import
  macros, strutils

const
  coreAttr* = " id class title style "
  eventAttr* = " onclick ondblclick onmousedown onmouseup " &
    "onmouseover onmousemove onmouseout onkeypress onkeydown onkeyup "
  commonAttr* = coreAttr & eventAttr

proc getIdent(e: NimNode): string {.compileTime.} =
  case e.kind
  of nnkIdent: result = normalize($e.ident)
  of nnkAccQuoted:
    result = getIdent(e[0])
    for i in 1 .. e.len-1:
      result.add getIdent(e[i])
  else: error("cannot extract identifier from node: " & toStrLit(e).strVal)

proc delete[T](s: var seq[T], attr: T): bool =
  var idx = find(s, attr)
  if idx >= 0:
    var L = s.len
    s[idx] = s[L-1]
    setLen(s, L-1)
    result = true

proc xmlCheckedTag*(e: NimNode, tag: string, optAttr = "", reqAttr = "",
    isLeaf = false): NimNode {.compileTime.} =
  ## use this procedure to define a new XML tag

  # copy the attributes; when iterating over them these lists
  # will be modified, so that each attribute is only given one value
  var req = split(reqAttr)
  var opt = split(optAttr)
  result = newNimNode(nnkBracket, e)
  result.add(newStrLitNode("<"))
  result.add(newStrLitNode(tag))
  # first pass over attributes:
  for i in 1..e.len-1:
    if e[i].kind == nnkExprEqExpr:
      var name = getIdent(e[i][0])
      if delete(req, name) or delete(opt, name):
        result.add(newStrLitNode(" "))
        result.add(newStrLitNode(name))
        result.add(newStrLitNode("=\""))
        result.add(e[i][1])
        result.add(newStrLitNode("\""))
      else:
        error("invalid attribute for '" & tag & "' element: " & name)
  # check each required attribute exists:
  if req.len > 0:
    error(req[0] & " attribute for '" & tag & "' element expected")
  if isLeaf:
    for i in 1..e.len-1:
      if e[i].kind != nnkExprEqExpr:
        error("element " & tag & " cannot be nested")
    result.add(newStrLitNode(" />"))
  else:
    result.add(newStrLitNode(">"))
    # second pass over elements:
    for i in 1..e.len-1:
      if e[i].kind != nnkExprEqExpr: result.add(e[i])
    result.add(newStrLitNode("</"))
    result.add(newStrLitNode(tag))
    result.add(newStrLitNode(">"))
  result = nestList(!"&", result)


macro a*(e: expr): expr {.immediate.} =
  ## generates the HTML ``a`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "a", "href charset type hreflang rel rev " &
    "accesskey tabindex" & commonAttr)

macro acronym*(e: expr): expr {.immediate.} =
  ## generates the HTML ``acronym`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "acronym", commonAttr)

macro address*(e: expr): expr {.immediate.} =
  ## generates the HTML ``address`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "address", commonAttr)

macro area*(e: expr): expr {.immediate.} =
  ## generates the HTML ``area`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "area", "shape coords href nohref" &
    " accesskey tabindex" & commonAttr, "alt", true)

macro b*(e: expr): expr {.immediate.} =
  ## generates the HTML ``b`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "b", commonAttr)

macro base*(e: expr): expr {.immediate.} =
  ## generates the HTML ``base`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "base", "", "href", true)

macro big*(e: expr): expr {.immediate.} =
  ## generates the HTML ``big`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "big", commonAttr)

macro blockquote*(e: expr): expr {.immediate.} =
  ## generates the HTML ``blockquote`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "blockquote", " cite" & commonAttr)

macro body*(e: expr): expr {.immediate.} =
  ## generates the HTML ``body`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "body", commonAttr)

macro br*(e: expr): expr {.immediate.} =
  ## generates the HTML ``br`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "br", "", "", true)

macro button*(e: expr): expr {.immediate.} =
  ## generates the HTML ``button`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "button", "accesskey tabindex " &
    "disabled name type value" & commonAttr)

macro caption*(e: expr): expr {.immediate.} =
  ## generates the HTML ``caption`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "caption", commonAttr)

macro cite*(e: expr): expr {.immediate.} =
  ## generates the HTML ``cite`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "cite", commonAttr)

macro code*(e: expr): expr {.immediate.} =
  ## generates the HTML ``code`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "code", commonAttr)

macro col*(e: expr): expr {.immediate.} =
  ## generates the HTML ``col`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "col", "span align valign" & commonAttr, "", true)

macro colgroup*(e: expr): expr {.immediate.} =
  ## generates the HTML ``colgroup`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "colgroup", "span align valign" & commonAttr)

macro dd*(e: expr): expr {.immediate.} =
  ## generates the HTML ``dd`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "dd", commonAttr)

macro del*(e: expr): expr {.immediate.} =
  ## generates the HTML ``del`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "del", "cite datetime" & commonAttr)

macro dfn*(e: expr): expr {.immediate.} =
  ## generates the HTML ``dfn`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "dfn", commonAttr)

macro `div`*(e: expr): expr {.immediate.} =
  ## generates the HTML ``div`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "div", commonAttr)

macro dl*(e: expr): expr {.immediate.} =
  ## generates the HTML ``dl`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "dl", commonAttr)

macro dt*(e: expr): expr {.immediate.} =
  ## generates the HTML ``dt`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "dt", commonAttr)

macro em*(e: expr): expr {.immediate.} =
  ## generates the HTML ``em`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "em", commonAttr)

macro fieldset*(e: expr): expr {.immediate.} =
  ## generates the HTML ``fieldset`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "fieldset", commonAttr)

macro form*(e: expr): expr {.immediate.} =
  ## generates the HTML ``form`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "form", "method encype accept accept-charset" &
    commonAttr, "action")

macro h1*(e: expr): expr {.immediate.} =
  ## generates the HTML ``h1`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "h1", commonAttr)

macro h2*(e: expr): expr {.immediate.} =
  ## generates the HTML ``h2`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "h2", commonAttr)

macro h3*(e: expr): expr {.immediate.} =
  ## generates the HTML ``h3`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "h3", commonAttr)

macro h4*(e: expr): expr {.immediate.} =
  ## generates the HTML ``h4`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "h4", commonAttr)

macro h5*(e: expr): expr {.immediate.} =
  ## generates the HTML ``h5`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "h5", commonAttr)

macro h6*(e: expr): expr {.immediate.} =
  ## generates the HTML ``h6`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "h6", commonAttr)

macro head*(e: expr): expr {.immediate.} =
  ## generates the HTML ``head`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "head", "profile")

macro html*(e: expr): expr {.immediate.} =
  ## generates the HTML ``html`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "html", "xmlns", "")

macro hr*(): expr {.immediate.} =
  ## generates the HTML ``hr`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "hr", commonAttr, "", true)

macro i*(e: expr): expr {.immediate.} =
  ## generates the HTML ``i`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "i", commonAttr)

macro img*(e: expr): expr {.immediate.} =
  ## generates the HTML ``img`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "img", "longdesc height width", "src alt", true)

macro input*(e: expr): expr {.immediate.} =
  ## generates the HTML ``input`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "input", "name type value checked maxlength src" &
    " alt accept disabled readonly accesskey tabindex" & commonAttr, "", true)

macro ins*(e: expr): expr {.immediate.} =
  ## generates the HTML ``ins`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "ins", "cite datetime" & commonAttr)

macro kbd*(e: expr): expr {.immediate.} =
  ## generates the HTML ``kbd`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "kbd", commonAttr)

macro label*(e: expr): expr {.immediate.} =
  ## generates the HTML ``label`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "label", "for accesskey" & commonAttr)

macro legend*(e: expr): expr {.immediate.} =
  ## generates the HTML ``legend`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "legend", "accesskey" & commonAttr)

macro li*(e: expr): expr {.immediate.} =
  ## generates the HTML ``li`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "li", commonAttr)

macro link*(e: expr): expr {.immediate.} =
  ## generates the HTML ``link`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "link", "href charset hreflang type rel rev media" &
    commonAttr, "", true)

macro map*(e: expr): expr {.immediate.} =
  ## generates the HTML ``map`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "map", "class title" & eventAttr, "id", false)

macro meta*(e: expr): expr {.immediate.} =
  ## generates the HTML ``meta`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "meta", "name http-equiv scheme", "content", true)

macro noscript*(e: expr): expr {.immediate.} =
  ## generates the HTML ``noscript`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "noscript", commonAttr)

macro `object`*(e: expr): expr {.immediate.} =
  ## generates the HTML ``object`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "object", "classid data codebase declare type " &
    "codetype archive standby width height name tabindex" & commonAttr)

macro ol*(e: expr): expr {.immediate.} =
  ## generates the HTML ``ol`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "ol", commonAttr)

macro optgroup*(e: expr): expr {.immediate.} =
  ## generates the HTML ``optgroup`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "optgroup", "disabled" & commonAttr, "label", false)

macro option*(e: expr): expr {.immediate.} =
  ## generates the HTML ``option`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "option", "selected value" & commonAttr)

macro p*(e: expr): expr {.immediate.} =
  ## generates the HTML ``p`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "p", commonAttr)

macro param*(e: expr): expr {.immediate.} =
  ## generates the HTML ``param`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "param", "value id type valuetype", "name", true)

macro pre*(e: expr): expr {.immediate.} =
  ## generates the HTML ``pre`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "pre", commonAttr)

macro q*(e: expr): expr {.immediate.} =
  ## generates the HTML ``q`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "q", "cite" & commonAttr)

macro samp*(e: expr): expr {.immediate.} =
  ## generates the HTML ``samp`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "samp", commonAttr)

macro script*(e: expr): expr {.immediate.} =
  ## generates the HTML ``script`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "script", "src charset defer", "type", false)

macro select*(e: expr): expr {.immediate.} =
  ## generates the HTML ``select`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "select", "name size multiple disabled tabindex" &
    commonAttr)

macro small*(e: expr): expr {.immediate.} =
  ## generates the HTML ``small`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "small", commonAttr)

macro span*(e: expr): expr {.immediate.} =
  ## generates the HTML ``span`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "span", commonAttr)

macro strong*(e: expr): expr {.immediate.} =
  ## generates the HTML ``strong`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "strong", commonAttr)

macro style*(e: expr): expr {.immediate.} =
  ## generates the HTML ``style`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "style", "media title", "type")

macro sub*(e: expr): expr {.immediate.} =
  ## generates the HTML ``sub`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "sub", commonAttr)

macro sup*(e: expr): expr {.immediate.} =
  ## generates the HTML ``sup`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "sup", commonAttr)

macro table*(e: expr): expr {.immediate.} =
  ## generates the HTML ``table`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "table", "summary border cellpadding cellspacing" &
    " frame rules width" & commonAttr)

macro tbody*(e: expr): expr {.immediate.} =
  ## generates the HTML ``tbody`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "tbody", "align valign" & commonAttr)

macro td*(e: expr): expr {.immediate.} =
  ## generates the HTML ``td`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "td", "colspan rowspan abbr axis headers scope" &
    " align valign" & commonAttr)

macro textarea*(e: expr): expr {.immediate.} =
  ## generates the HTML ``textarea`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "textarea", " name disabled readonly accesskey" &
    " tabindex" & commonAttr, "rows cols", false)

macro tfoot*(e: expr): expr {.immediate.} =
  ## generates the HTML ``tfoot`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "tfoot", "align valign" & commonAttr)

macro th*(e: expr): expr {.immediate.} =
  ## generates the HTML ``th`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "th", "colspan rowspan abbr axis headers scope" &
    " align valign" & commonAttr)

macro thead*(e: expr): expr {.immediate.} =
  ## generates the HTML ``thead`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "thead", "align valign" & commonAttr)

macro title*(e: expr): expr {.immediate.} =
  ## generates the HTML ``title`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "title")

macro tr*(e: expr): expr {.immediate.} =
  ## generates the HTML ``tr`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "tr", "align valign" & commonAttr)

macro tt*(e: expr): expr {.immediate.} =
  ## generates the HTML ``tt`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "tt", commonAttr)

macro ul*(e: expr): expr {.immediate.} =
  ## generates the HTML ``ul`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "ul", commonAttr)

macro `var`*(e: expr): expr {.immediate.} =
  ## generates the HTML ``var`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "var", commonAttr)

when isMainModule:
  var nim = "Nim"
  echo h1(a(href="http://nim-lang.org", nim))
  echo form(action="test", `accept-charset` = "Content-Type")

