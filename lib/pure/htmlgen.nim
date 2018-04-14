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
    "onmouseover onmousemove onmouseout onkeypress onkeydown onkeyup onload "
  commonAttr* = coreAttr & eventAttr

proc getIdent(e: NimNode): string {.compileTime.} =
  case e.kind
  of nnkIdent:
    result = e.strVal.normalize
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
  var req = splitWhitespace(reqAttr)
  var opt = splitWhitespace(optAttr)
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
  when compiles(nestList(ident"&", result)):
    result = nestList(ident"&", result)
  else:
    result = nestList(!"&", result)

macro a*(e: varargs[untyped]): untyped =
  ## generates the HTML ``a`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "a", "href charset type hreflang rel rev " &
    "accesskey tabindex" & commonAttr)

macro acronym*(e: varargs[untyped]): untyped =
  ## generates the HTML ``acronym`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "acronym", commonAttr)

macro address*(e: varargs[untyped]): untyped =
  ## generates the HTML ``address`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "address", commonAttr)

macro area*(e: varargs[untyped]): untyped =
  ## generates the HTML ``area`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "area", "shape coords href nohref" &
    " accesskey tabindex" & commonAttr, "alt", true)

macro b*(e: varargs[untyped]): untyped =
  ## generates the HTML ``b`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "b", commonAttr)

macro base*(e: varargs[untyped]): untyped =
  ## generates the HTML ``base`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "base", "", "href", true)

macro big*(e: varargs[untyped]): untyped =
  ## generates the HTML ``big`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "big", commonAttr)

macro blockquote*(e: varargs[untyped]): untyped =
  ## generates the HTML ``blockquote`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "blockquote", " cite" & commonAttr)

macro body*(e: varargs[untyped]): untyped =
  ## generates the HTML ``body`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "body", commonAttr)

macro br*(e: varargs[untyped]): untyped =
  ## generates the HTML ``br`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "br", "", "", true)

macro button*(e: varargs[untyped]): untyped =
  ## generates the HTML ``button`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "button", "accesskey tabindex " &
    "disabled name type value" & commonAttr)

macro caption*(e: varargs[untyped]): untyped =
  ## generates the HTML ``caption`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "caption", commonAttr)

macro cite*(e: varargs[untyped]): untyped =
  ## generates the HTML ``cite`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "cite", commonAttr)

macro code*(e: varargs[untyped]): untyped =
  ## generates the HTML ``code`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "code", commonAttr)

macro col*(e: varargs[untyped]): untyped =
  ## generates the HTML ``col`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "col", "span align valign" & commonAttr, "", true)

macro colgroup*(e: varargs[untyped]): untyped =
  ## generates the HTML ``colgroup`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "colgroup", "span align valign" & commonAttr)

macro dd*(e: varargs[untyped]): untyped =
  ## generates the HTML ``dd`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "dd", commonAttr)

macro del*(e: varargs[untyped]): untyped =
  ## generates the HTML ``del`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "del", "cite datetime" & commonAttr)

macro dfn*(e: varargs[untyped]): untyped =
  ## generates the HTML ``dfn`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "dfn", commonAttr)

macro `div`*(e: varargs[untyped]): untyped =
  ## generates the HTML ``div`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "div", commonAttr)

macro dl*(e: varargs[untyped]): untyped =
  ## generates the HTML ``dl`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "dl", commonAttr)

macro dt*(e: varargs[untyped]): untyped =
  ## generates the HTML ``dt`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "dt", commonAttr)

macro em*(e: varargs[untyped]): untyped =
  ## generates the HTML ``em`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "em", commonAttr)

macro fieldset*(e: varargs[untyped]): untyped =
  ## generates the HTML ``fieldset`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "fieldset", commonAttr)

macro form*(e: varargs[untyped]): untyped =
  ## generates the HTML ``form`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "form", "method encype accept accept-charset" &
    commonAttr, "action")

macro h1*(e: varargs[untyped]): untyped =
  ## generates the HTML ``h1`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "h1", commonAttr)

macro h2*(e: varargs[untyped]): untyped =
  ## generates the HTML ``h2`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "h2", commonAttr)

macro h3*(e: varargs[untyped]): untyped =
  ## generates the HTML ``h3`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "h3", commonAttr)

macro h4*(e: varargs[untyped]): untyped =
  ## generates the HTML ``h4`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "h4", commonAttr)

macro h5*(e: varargs[untyped]): untyped =
  ## generates the HTML ``h5`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "h5", commonAttr)

macro h6*(e: varargs[untyped]): untyped =
  ## generates the HTML ``h6`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "h6", commonAttr)

macro head*(e: varargs[untyped]): untyped =
  ## generates the HTML ``head`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "head", "profile")

macro html*(e: varargs[untyped]): untyped =
  ## generates the HTML ``html`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "html", "xmlns", "")

macro hr*(): untyped =
  ## generates the HTML ``hr`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "hr", commonAttr, "", true)

macro i*(e: varargs[untyped]): untyped =
  ## generates the HTML ``i`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "i", commonAttr)

macro img*(e: varargs[untyped]): untyped =
  ## generates the HTML ``img`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "img", "longdesc height width", "src alt", true)

macro input*(e: varargs[untyped]): untyped =
  ## generates the HTML ``input`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "input", "name type value checked maxlength src" &
    " alt accept disabled readonly accesskey tabindex" & commonAttr, "", true)

macro ins*(e: varargs[untyped]): untyped =
  ## generates the HTML ``ins`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "ins", "cite datetime" & commonAttr)

macro kbd*(e: varargs[untyped]): untyped =
  ## generates the HTML ``kbd`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "kbd", commonAttr)

macro label*(e: varargs[untyped]): untyped =
  ## generates the HTML ``label`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "label", "for accesskey" & commonAttr)

macro legend*(e: varargs[untyped]): untyped =
  ## generates the HTML ``legend`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "legend", "accesskey" & commonAttr)

macro li*(e: varargs[untyped]): untyped =
  ## generates the HTML ``li`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "li", commonAttr)

macro link*(e: varargs[untyped]): untyped =
  ## generates the HTML ``link`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "link", "href charset hreflang type rel rev media" &
    commonAttr, "", true)

macro map*(e: varargs[untyped]): untyped =
  ## generates the HTML ``map`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "map", "class title" & eventAttr, "id", false)

macro meta*(e: varargs[untyped]): untyped =
  ## generates the HTML ``meta`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "meta", "name http-equiv scheme", "content", true)

macro noscript*(e: varargs[untyped]): untyped =
  ## generates the HTML ``noscript`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "noscript", commonAttr)

macro `object`*(e: varargs[untyped]): untyped =
  ## generates the HTML ``object`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "object", "classid data codebase declare type " &
    "codetype archive standby width height name tabindex" & commonAttr)

macro ol*(e: varargs[untyped]): untyped =
  ## generates the HTML ``ol`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "ol", commonAttr)

macro optgroup*(e: varargs[untyped]): untyped =
  ## generates the HTML ``optgroup`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "optgroup", "disabled" & commonAttr, "label", false)

macro option*(e: varargs[untyped]): untyped =
  ## generates the HTML ``option`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "option", "selected value" & commonAttr)

macro p*(e: varargs[untyped]): untyped =
  ## generates the HTML ``p`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "p", commonAttr)

macro param*(e: varargs[untyped]): untyped =
  ## generates the HTML ``param`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "param", "value id type valuetype", "name", true)

macro pre*(e: varargs[untyped]): untyped =
  ## generates the HTML ``pre`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "pre", commonAttr)

macro q*(e: varargs[untyped]): untyped =
  ## generates the HTML ``q`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "q", "cite" & commonAttr)

macro samp*(e: varargs[untyped]): untyped =
  ## generates the HTML ``samp`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "samp", commonAttr)

macro script*(e: varargs[untyped]): untyped =
  ## generates the HTML ``script`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "script", "src charset defer", "type", false)

macro select*(e: varargs[untyped]): untyped =
  ## generates the HTML ``select`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "select", "name size multiple disabled tabindex" &
    commonAttr)

macro small*(e: varargs[untyped]): untyped =
  ## generates the HTML ``small`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "small", commonAttr)

macro span*(e: varargs[untyped]): untyped =
  ## generates the HTML ``span`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "span", commonAttr)

macro strong*(e: varargs[untyped]): untyped =
  ## generates the HTML ``strong`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "strong", commonAttr)

macro style*(e: varargs[untyped]): untyped =
  ## generates the HTML ``style`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "style", "media title", "type")

macro sub*(e: varargs[untyped]): untyped =
  ## generates the HTML ``sub`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "sub", commonAttr)

macro sup*(e: varargs[untyped]): untyped =
  ## generates the HTML ``sup`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "sup", commonAttr)

macro table*(e: varargs[untyped]): untyped =
  ## generates the HTML ``table`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "table", "summary border cellpadding cellspacing" &
    " frame rules width" & commonAttr)

macro tbody*(e: varargs[untyped]): untyped =
  ## generates the HTML ``tbody`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "tbody", "align valign" & commonAttr)

macro td*(e: varargs[untyped]): untyped =
  ## generates the HTML ``td`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "td", "colspan rowspan abbr axis headers scope" &
    " align valign" & commonAttr)

macro textarea*(e: varargs[untyped]): untyped =
  ## generates the HTML ``textarea`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "textarea", " name disabled readonly accesskey" &
    " tabindex" & commonAttr, "rows cols", false)

macro tfoot*(e: varargs[untyped]): untyped =
  ## generates the HTML ``tfoot`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "tfoot", "align valign" & commonAttr)

macro th*(e: varargs[untyped]): untyped =
  ## generates the HTML ``th`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "th", "colspan rowspan abbr axis headers scope" &
    " align valign" & commonAttr)

macro thead*(e: varargs[untyped]): untyped =
  ## generates the HTML ``thead`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "thead", "align valign" & commonAttr)

macro title*(e: varargs[untyped]): untyped =
  ## generates the HTML ``title`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "title")

macro tr*(e: varargs[untyped]): untyped =
  ## generates the HTML ``tr`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "tr", "align valign" & commonAttr)

macro tt*(e: varargs[untyped]): untyped =
  ## generates the HTML ``tt`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "tt", commonAttr)

macro ul*(e: varargs[untyped]): untyped =
  ## generates the HTML ``ul`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "ul", commonAttr)

macro `var`*(e: varargs[untyped]): untyped =
  ## generates the HTML ``var`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "var", commonAttr)

when isMainModule:
  let nim = "Nim"
  assert h1(a(href="http://nim-lang.org", nim)) ==
    """<h1><a href="http://nim-lang.org">Nim</a></h1>"""
  assert form(action="test", `accept-charset` = "Content-Type") ==
    """<form action="test" accept-charset="Content-Type"></form>"""
