#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple `XML`:idx: and `HTML`:idx: code 
## generator. Each commonly used HTML tag has a corresponding macro
## that generates a string with its HTML representation.
##
## Example:
##
## .. code-block:: nimrod
##   var nim = "Nimrod"
##   echo h1(a(href="http://force7.de/nimrod", nim))
##  
## Writes the string::
##   
##   <h1><a href="http://force7.de/nimrod">Nimrod</a></h1>
##

import
  macros, strutils

const
  coreAttr* = " id class title style "
  eventAttr* = " onclick ondblclick onmousedown onmouseup " &
    "onmouseover onmousemove onmouseout onkeypress onkeydown onkeyup "
  commonAttr* = coreAttr & eventAttr

proc getIdent(e: PNimrodNode): string {.compileTime.} = 
  case e.kind
  of nnkIdent: result = normalize($e.ident)
  of nnkAccQuoted: result = getIdent(e[0])
  else: error("cannot extract identifier from node: " & toStrLit(e).strVal)

proc delete[T](s: var seq[T], attr: T): bool = 
  var idx = find(s, attr)
  if idx >= 0:
    var L = s.len
    s[idx] = s[L-1]
    setLen(s, L-1)
    result = true

proc xmlCheckedTag*(e: PNimrodNode, tag: string,
    optAttr = "", reqAttr = "",
    isLeaf = false): PNimrodNode {.compileTime.} =
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
  result = NestList(!"&", result)


macro a*(e: expr): expr = 
  ## generates the HTML ``a`` element.
  result = xmlCheckedTag(e, "a", "href charset type hreflang rel rev " &
    "accesskey tabindex" & commonAttr)

macro acronym*(e: expr): expr = 
  ## generates the HTML ``acronym`` element.
  result = xmlCheckedTag(e, "acronym", commonAttr)

macro address*(e: expr): expr = 
  ## generates the HTML ``address`` element.
  result = xmlCheckedTag(e, "address", commonAttr)

macro area*(e: expr): expr = 
  ## generates the HTML ``area`` element.
  result = xmlCheckedTag(e, "area", "shape coords href nohref" &
    " accesskey tabindex" & commonAttr, "alt", true)

macro b*(e: expr): expr = 
  ## generates the HTML ``b`` element.
  result = xmlCheckedTag(e, "b", commonAttr)

macro base*(e: expr): expr = 
  ## generates the HTML ``base`` element.
  result = xmlCheckedTag(e, "base", "", "href", true)

macro big*(e: expr): expr = 
  ## generates the HTML ``big`` element.
  result = xmlCheckedTag(e, "big", commonAttr)

macro blockquote*(e: expr): expr = 
  ## generates the HTML ``blockquote`` element.
  result = xmlCheckedTag(e, "blockquote", " cite" & commonAttr)

macro body*(e: expr): expr = 
  ## generates the HTML ``body`` element.
  result = xmlCheckedTag(e, "body", commonAttr)

macro br*(e: expr): expr = 
  ## generates the HTML ``br`` element.
  result = xmlCheckedTag(e, "br", "", "", true)

macro button*(e: expr): expr = 
  ## generates the HTML ``button`` element.
  result = xmlCheckedTag(e, "button", "accesskey tabindex " &
    "disabled name type value" & commonAttr)

macro caption*(e: expr): expr = 
  ## generates the HTML ``caption`` element.
  result = xmlCheckedTag(e, "caption", commonAttr)

macro cite*(e: expr): expr = 
  ## generates the HTML ``cite`` element.
  result = xmlCheckedTag(e, "cite", commonAttr)

macro code*(e: expr): expr = 
  ## generates the HTML ``code`` element.
  result = xmlCheckedTag(e, "code", commonAttr)

macro col*(e: expr): expr = 
  ## generates the HTML ``col`` element.
  result = xmlCheckedTag(e, "col", "span align valign" & commonAttr, "", true)

macro colgroup*(e: expr): expr = 
  ## generates the HTML ``colgroup`` element.
  result = xmlCheckedTag(e, "colgroup", "span align valign" & commonAttr)

macro dd*(e: expr): expr = 
  ## generates the HTML ``dd`` element.
  result = xmlCheckedTag(e, "dd", commonAttr)

macro del*(e: expr): expr = 
  ## generates the HTML ``del`` element.
  result = xmlCheckedTag(e, "del", "cite datetime" & commonAttr)

macro dfn*(e: expr): expr = 
  ## generates the HTML ``dfn`` element.
  result = xmlCheckedTag(e, "dfn", commonAttr)

macro `div`*(e: expr): expr = 
  ## generates the HTML ``div`` element.
  result = xmlCheckedTag(e, "div", commonAttr)

macro dl*(e: expr): expr = 
  ## generates the HTML ``dl`` element.
  result = xmlCheckedTag(e, "dl", commonAttr)

macro dt*(e: expr): expr = 
  ## generates the HTML ``dt`` element.
  result = xmlCheckedTag(e, "dt", commonAttr)

macro em*(e: expr): expr = 
  ## generates the HTML ``em`` element.
  result = xmlCheckedTag(e, "em", commonAttr)

macro fieldset*(e: expr): expr = 
  ## generates the HTML ``fieldset`` element.
  result = xmlCheckedTag(e, "fieldset", commonAttr)

macro form*(e: expr): expr = 
  ## generates the HTML ``form`` element.
  result = xmlCheckedTag(e, "form", "method encype accept accept-charset" & 
    commonAttr, "action")

macro h1*(e: expr): expr = 
  ## generates the HTML ``h1`` element.
  result = xmlCheckedTag(e, "h1", commonAttr)

macro h2*(e: expr): expr = 
  ## generates the HTML ``h2`` element.
  result = xmlCheckedTag(e, "h2", commonAttr)

macro h3*(e: expr): expr = 
  ## generates the HTML ``h3`` element.
  result = xmlCheckedTag(e, "h3", commonAttr)

macro h4*(e: expr): expr = 
  ## generates the HTML ``h4`` element.
  result = xmlCheckedTag(e, "h4", commonAttr)

macro h5*(e: expr): expr = 
  ## generates the HTML ``h5`` element.
  result = xmlCheckedTag(e, "h5", commonAttr)

macro h6*(e: expr): expr = 
  ## generates the HTML ``h6`` element.
  result = xmlCheckedTag(e, "h6", commonAttr)

macro head*(e: expr): expr = 
  ## generates the HTML ``head`` element.
  result = xmlCheckedTag(e, "head", "profile")

macro html*(e: expr): expr = 
  ## generates the HTML ``html`` element.
  result = xmlCheckedTag(e, "html", "xmlns", "")

macro hr*(e: expr): expr = 
  ## generates the HTML ``hr`` element.
  result = xmlCheckedTag(e, "hr", commonAttr, "", true)

macro i*(e: expr): expr = 
  ## generates the HTML ``i`` element.
  result = xmlCheckedTag(e, "i", commonAttr)

macro img*(e: expr): expr = 
  ## generates the HTML ``img`` element.
  result = xmlCheckedTag(e, "img", "longdesc height width", "src alt", true)

macro input*(e: expr): expr = 
  ## generates the HTML ``input`` element.
  result = xmlCheckedTag(e, "input", "name type value checked maxlength src" &
    " alt accept disabled readonly accesskey tabindex" & commonAttr, "", true)

macro ins*(e: expr): expr = 
  ## generates the HTML ``ins`` element.
  result = xmlCheckedTag(e, "ins", "cite datetime" & commonAttr)

macro kbd*(e: expr): expr = 
  ## generates the HTML ``kbd`` element.
  result = xmlCheckedTag(e, "kbd", commonAttr)

macro label*(e: expr): expr = 
  ## generates the HTML ``label`` element.
  result = xmlCheckedTag(e, "label", "for accesskey" & commonAttr)

macro legend*(e: expr): expr = 
  ## generates the HTML ``legend`` element.
  result = xmlCheckedTag(e, "legend", "accesskey" & commonAttr)

macro li*(e: expr): expr = 
  ## generates the HTML ``li`` element.
  result = xmlCheckedTag(e, "li", commonAttr)

macro link*(e: expr): expr = 
  ## generates the HTML ``link`` element.
  result = xmlCheckedTag(e, "link", "href charset hreflang type rel rev media" & 
    commonAttr, "", true)

macro map*(e: expr): expr = 
  ## generates the HTML ``map`` element.
  result = xmlCheckedTag(e, "map", "class title" & eventAttr, "id", false)

macro meta*(e: expr): expr = 
  ## generates the HTML ``meta`` element.
  result = xmlCheckedTag(e, "meta", "name http-equiv scheme", "content", true)

macro noscript*(e: expr): expr = 
  ## generates the HTML ``noscript`` element.
  result = xmlCheckedTag(e, "noscript", commonAttr)

macro `object`*(e: expr): expr = 
  ## generates the HTML ``object`` element.
  result = xmlCheckedTag(e, "object", "classid data codebase declare type " &
    "codetype archive standby width height name tabindex" & commonAttr)

macro ol*(e: expr): expr = 
  ## generates the HTML ``ol`` element.
  result = xmlCheckedTag(e, "ol", commonAttr)

macro optgroup*(e: expr): expr = 
  ## generates the HTML ``optgroup`` element.
  result = xmlCheckedTag(e, "optgroup", "disabled" & commonAttr, "label", false)

macro option*(e: expr): expr = 
  ## generates the HTML ``option`` element.
  result = xmlCheckedTag(e, "option", "selected value" & commonAttr)

macro p*(e: expr): expr = 
  ## generates the HTML ``p`` element.
  result = xmlCheckedTag(e, "p", commonAttr)

macro param*(e: expr): expr = 
  ## generates the HTML ``param`` element.
  result = xmlCheckedTag(e, "param", "value id type valuetype", "name", true)

macro pre*(e: expr): expr = 
  ## generates the HTML ``pre`` element.
  result = xmlCheckedTag(e, "pre", commonAttr)

macro q*(e: expr): expr = 
  ## generates the HTML ``q`` element.
  result = xmlCheckedTag(e, "q", "cite" & commonAttr)

macro samp*(e: expr): expr = 
  ## generates the HTML ``samp`` element.
  result = xmlCheckedTag(e, "samp", commonAttr)

macro script*(e: expr): expr = 
  ## generates the HTML ``script`` element.
  result = xmlCheckedTag(e, "script", "src charset defer", "type", false)

macro select*(e: expr): expr = 
  ## generates the HTML ``select`` element.
  result = xmlCheckedTag(e, "select", "name size multiple disabled tabindex" & 
    commonAttr)

macro small*(e: expr): expr = 
  ## generates the HTML ``small`` element.
  result = xmlCheckedTag(e, "small", commonAttr)

macro span*(e: expr): expr = 
  ## generates the HTML ``span`` element.
  result = xmlCheckedTag(e, "span", commonAttr)

macro strong*(e: expr): expr = 
  ## generates the HTML ``strong`` element.
  result = xmlCheckedTag(e, "strong", commonAttr)

macro style*(e: expr): expr = 
  ## generates the HTML ``style`` element.
  result = xmlCheckedTag(e, "style", "media title", "type")

macro sub*(e: expr): expr = 
  ## generates the HTML ``sub`` element.
  result = xmlCheckedTag(e, "sub", commonAttr)

macro sup*(e: expr): expr = 
  ## generates the HTML ``sup`` element.
  result = xmlCheckedTag(e, "sup", commonAttr)

macro table*(e: expr): expr = 
  ## generates the HTML ``table`` element.
  result = xmlCheckedTag(e, "table", "summary border cellpadding cellspacing" &
    " frame rules width" & commonAttr)

macro tbody*(e: expr): expr = 
  ## generates the HTML ``tbody`` element.
  result = xmlCheckedTag(e, "tbody", "align valign" & commonAttr)

macro td*(e: expr): expr = 
  ## generates the HTML ``td`` element.
  result = xmlCheckedTag(e, "td", "colspan rowspan abbr axis headers scope" &
    " align valign" & commonAttr)

macro textarea*(e: expr): expr = 
  ## generates the HTML ``textarea`` element.
  result = xmlCheckedTag(e, "textarea", " name disabled readonly accesskey" &
    " tabindex" & commonAttr, "rows cols", false)

macro tfoot*(e: expr): expr = 
  ## generates the HTML ``tfoot`` element.
  result = xmlCheckedTag(e, "tfoot", "align valign" & commonAttr)

macro th*(e: expr): expr = 
  ## generates the HTML ``th`` element.
  result = xmlCheckedTag(e, "th", "colspan rowspan abbr axis headers scope" &
    " align valign" & commonAttr)

macro thead*(e: expr): expr = 
  ## generates the HTML ``thead`` element.
  result = xmlCheckedTag(e, "thead", "align valign" & commonAttr)

macro title*(e: expr): expr = 
  ## generates the HTML ``title`` element.
  result = xmlCheckedTag(e, "title")

macro tr*(e: expr): expr = 
  ## generates the HTML ``tr`` element.
  result = xmlCheckedTag(e, "tr", "align valign" & commonAttr)

macro tt*(e: expr): expr = 
  ## generates the HTML ``tt`` element.
  result = xmlCheckedTag(e, "tt", commonAttr)

macro ul*(e: expr): expr = 
  ## generates the HTML ``ul`` element.
  result = xmlCheckedTag(e, "ul", commonAttr)

macro `var`*(e: expr): expr = 
  ## generates the HTML ``var`` element.
  result = xmlCheckedTag(e, "var", commonAttr)

when isMainModule:
  var nim = "Nimrod"
  echo h1(a(href="http://force7.de/nimrod", nim))

