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
## Examples
## ========
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
  coreAttr* = " accesskey class contenteditable dir hidden id lang " &
    "spellcheck style tabindex title translate "  ## HTML DOM Core Attributes
  eventAttr* = "onabort onblur oncancel oncanplay oncanplaythrough onchange " &
    "onclick oncuechange ondblclick ondurationchange onemptied onended " &
    "onerror onfocus oninput oninvalid onkeydown onkeypress onkeyup onload " &
    "onloadeddata onloadedmetadata onloadstart onmousedown onmouseenter " &
    "onmouseleave onmousemove onmouseout onmouseover onmouseup onmousewheel " &
    "onpause onplay onplaying onprogress onratechange onreset onresize " &
    "onscroll onseeked onseeking onselect onshow onstalled onsubmit " &
    "onsuspend ontimeupdate ontoggle onvolumechange onwaiting " ## HTML DOM Event Attributes
  ariaAttr* = " role "  ## HTML DOM Aria Attributes
  commonAttr* = coreAttr & eventAttr & ariaAttr  ## HTML DOM Common Attributes

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
  result = xmlCheckedTag(e, "a", "href target download rel hreflang type " &
    commonAttr)

macro abbr*(e: varargs[untyped]): untyped =
  ## generates the HTML ``abbr`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "abbr", commonAttr)

macro address*(e: varargs[untyped]): untyped =
  ## generates the HTML ``address`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "address", commonAttr)

macro area*(e: varargs[untyped]): untyped =
  ## generates the HTML ``area`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "area", "coords download href hreflang rel " &
    "shape target type" & commonAttr, "alt", true)

macro article*(e: varargs[untyped]): untyped =
  ## generates the HTML ``article`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "article", commonAttr)

macro aside*(e: varargs[untyped]): untyped =
  ## generates the HTML ``aside`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "aside", commonAttr)

macro audio*(e: varargs[untyped]): untyped =
  ## generates the HTML ``audio`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "audio", "src crossorigin preload " &
    "autoplay mediagroup loop muted controls" & commonAttr)

macro b*(e: varargs[untyped]): untyped =
  ## generates the HTML ``b`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "b", commonAttr)

macro base*(e: varargs[untyped]): untyped =
  ## generates the HTML ``base`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "base", "href target" & commonAttr, "", true)

macro bdi*(e: varargs[untyped]): untyped =
  ## generates the HTML ``bdi`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "bdi", commonAttr)

macro bdo*(e: varargs[untyped]): untyped =
  ## generates the HTML ``bdo`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "bdo", commonAttr)

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
  result = xmlCheckedTag(e, "body", "onafterprint onbeforeprint " &
    "onbeforeunload onhashchange onmessage onoffline ononline onpagehide " &
    "onpageshow onpopstate onstorage onunload" & commonAttr)

macro br*(e: varargs[untyped]): untyped =
  ## generates the HTML ``br`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "br", commonAttr, "", true)

macro button*(e: varargs[untyped]): untyped =
  ## generates the HTML ``button`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "button", "autofocus disabled form formaction " &
    "formenctype formmethod formnovalidate formtarget menu name type value" &
    commonAttr)

macro canvas*(e: varargs[untyped]): untyped =
  ## generates the HTML ``canvas`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "canvas", "width height" & commonAttr)

macro caption*(e: varargs[untyped]): untyped =
  ## generates the HTML ``caption`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "caption", commonAttr)

macro center*(e: varargs[untyped]): untyped =
  ## Generates the HTML ``center`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "center", commonAttr)

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
  result = xmlCheckedTag(e, "col", "span" & commonAttr, "", true)

macro colgroup*(e: varargs[untyped]): untyped =
  ## generates the HTML ``colgroup`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "colgroup", "span" & commonAttr)

macro data*(e: varargs[untyped]): untyped =
  ## generates the HTML ``data`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "data", "value" & commonAttr)

macro datalist*(e: varargs[untyped]): untyped =
  ## generates the HTML ``datalist`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "datalist", commonAttr)

macro dd*(e: varargs[untyped]): untyped =
  ## generates the HTML ``dd`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "dd", commonAttr)

macro del*(e: varargs[untyped]): untyped =
  ## generates the HTML ``del`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "del", "cite datetime" & commonAttr)

macro details*(e: varargs[untyped]): untyped =
  ## Generates the HTML ``details`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "details", commonAttr & "open")

macro dfn*(e: varargs[untyped]): untyped =
  ## generates the HTML ``dfn`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "dfn", commonAttr)

macro dialog*(e: varargs[untyped]): untyped =
  ## Generates the HTML ``dialog`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "dialog", commonAttr & "open")

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

macro embed*(e: varargs[untyped]): untyped =
  ## generates the HTML ``embed`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "embed", "src type height width" &
    commonAttr, "", true)

macro fieldset*(e: varargs[untyped]): untyped =
  ## generates the HTML ``fieldset`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "fieldset", "disabled form name" & commonAttr)

macro figure*(e: varargs[untyped]): untyped =
  ## generates the HTML ``figure`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "figure", commonAttr)

macro figcaption*(e: varargs[untyped]): untyped =
  ## generates the HTML ``figcaption`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "figcaption", commonAttr)

macro footer*(e: varargs[untyped]): untyped =
  ## generates the HTML ``footer`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "footer", commonAttr)

macro form*(e: varargs[untyped]): untyped =
  ## generates the HTML ``form`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "form", "accept-charset action autocomplete " &
    "enctype method name novalidate target" & commonAttr)

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
  result = xmlCheckedTag(e, "head", commonAttr)

macro header*(e: varargs[untyped]): untyped =
  ## generates the HTML ``header`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "header", commonAttr)

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

macro iframe*(e: varargs[untyped]): untyped =
  ## generates the HTML ``iframe`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "iframe", "src srcdoc name sandbox width height" &
    commonAttr)

macro img*(e: varargs[untyped]): untyped =
  ## generates the HTML ``img`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "img", "crossorigin usemap ismap height width" &
    commonAttr, "src alt", true)

macro input*(e: varargs[untyped]): untyped =
  ## generates the HTML ``input`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "input", "accept alt autocomplete autofocus " &
    "checked dirname disabled form formaction formenctype formmethod " &
    "formnovalidate formtarget height inputmode list max maxlength min " &
    "minlength multiple name pattern placeholder readonly required size " &
    "src step type value width" & commonAttr, "", true)

macro ins*(e: varargs[untyped]): untyped =
  ## generates the HTML ``ins`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "ins", "cite datetime" & commonAttr)

macro kbd*(e: varargs[untyped]): untyped =
  ## generates the HTML ``kbd`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "kbd", commonAttr)

macro keygen*(e: varargs[untyped]): untyped =
  ## generates the HTML ``keygen`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "keygen", "autofocus challenge disabled " &
    "form keytype name" & commonAttr)

macro label*(e: varargs[untyped]): untyped =
  ## generates the HTML ``label`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "label", "form for" & commonAttr)

macro legend*(e: varargs[untyped]): untyped =
  ## generates the HTML ``legend`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "legend", commonAttr)

macro li*(e: varargs[untyped]): untyped =
  ## generates the HTML ``li`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "li", "value" & commonAttr)

macro link*(e: varargs[untyped]): untyped =
  ## generates the HTML ``link`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "link", "href crossorigin rel media hreflang " &
    "type sizes" & commonAttr, "", true)

macro main*(e: varargs[untyped]): untyped =
  ## generates the HTML ``main`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "main", commonAttr)

macro map*(e: varargs[untyped]): untyped =
  ## generates the HTML ``map`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "map", "name" & commonAttr)

macro mark*(e: varargs[untyped]): untyped =
  ## generates the HTML ``mark`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "mark", commonAttr)

macro marquee*(e: varargs[untyped]): untyped =
  ## Generates the HTML ``marquee`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "marquee", coreAttr &
    "behavior bgcolor direction height hspace loop scrollamount " &
    "scrolldelay truespeed vspace width onbounce onfinish onstart")

macro meta*(e: varargs[untyped]): untyped =
  ## generates the HTML ``meta`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "meta", "name http-equiv content charset" &
    commonAttr, "", true)

macro meter*(e: varargs[untyped]): untyped =
  ## generates the HTML ``meter`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "meter", "value min max low high optimum" &
    commonAttr)

macro nav*(e: varargs[untyped]): untyped =
  ## generates the HTML ``nav`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "nav", commonAttr)

macro noscript*(e: varargs[untyped]): untyped =
  ## generates the HTML ``noscript`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "noscript", commonAttr)

macro `object`*(e: varargs[untyped]): untyped =
  ## generates the HTML ``object`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "object", "data type typemustmatch name usemap " &
    "form width height" & commonAttr)

macro ol*(e: varargs[untyped]): untyped =
  ## generates the HTML ``ol`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "ol", "reversed start type" & commonAttr)

macro optgroup*(e: varargs[untyped]): untyped =
  ## generates the HTML ``optgroup`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "optgroup", "disabled" & commonAttr, "label", false)

macro option*(e: varargs[untyped]): untyped =
  ## generates the HTML ``option`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "option", "disabled label selected value" &
    commonAttr)

macro output*(e: varargs[untyped]): untyped =
  ## generates the HTML ``output`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "output", "for form name" & commonAttr)

macro p*(e: varargs[untyped]): untyped =
  ## generates the HTML ``p`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "p", commonAttr)

macro param*(e: varargs[untyped]): untyped =
  ## generates the HTML ``param`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "param", commonAttr, "name value", true)

macro picture*(e: varargs[untyped]): untyped =
  ## Generates the HTML ``picture`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "picture", commonAttr)

macro pre*(e: varargs[untyped]): untyped =
  ## generates the HTML ``pre`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "pre", commonAttr)

macro progress*(e: varargs[untyped]): untyped =
  ## generates the HTML ``progress`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "progress", "value max" & commonAttr)

macro q*(e: varargs[untyped]): untyped =
  ## generates the HTML ``q`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "q", "cite" & commonAttr)

macro rb*(e: varargs[untyped]): untyped =
  ## generates the HTML ``rb`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "rb", commonAttr)

macro rp*(e: varargs[untyped]): untyped =
  ## generates the HTML ``rp`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "rp", commonAttr)

macro rt*(e: varargs[untyped]): untyped =
  ## generates the HTML ``rt`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "rt", commonAttr)

macro rtc*(e: varargs[untyped]): untyped =
  ## generates the HTML ``rtc`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "rtc", commonAttr)

macro ruby*(e: varargs[untyped]): untyped =
  ## generates the HTML ``ruby`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "ruby", commonAttr)

macro s*(e: varargs[untyped]): untyped =
  ## generates the HTML ``s`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "s", commonAttr)

macro samp*(e: varargs[untyped]): untyped =
  ## generates the HTML ``samp`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "samp", commonAttr)

macro script*(e: varargs[untyped]): untyped =
  ## generates the HTML ``script`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "script", "src type charset async defer " &
    "crossorigin" & commonAttr)

macro section*(e: varargs[untyped]): untyped =
  ## generates the HTML ``section`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "section", commonAttr)

macro select*(e: varargs[untyped]): untyped =
  ## generates the HTML ``select`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "select", "autofocus disabled form multiple " &
    "name required size" & commonAttr)

macro slot*(e: varargs[untyped]): untyped =
  ## Generates the HTML ``slot`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "slot", commonAttr)

macro small*(e: varargs[untyped]): untyped =
  ## generates the HTML ``small`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "small", commonAttr)

macro source*(e: varargs[untyped]): untyped =
  ## generates the HTML ``source`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "source", "type" & commonAttr, "src", true)

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
  result = xmlCheckedTag(e, "style", "media type" & commonAttr)

macro sub*(e: varargs[untyped]): untyped =
  ## generates the HTML ``sub`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "sub", commonAttr)

macro summary*(e: varargs[untyped]): untyped =
  ## Generates the HTML ``summary`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "summary", commonAttr)

macro sup*(e: varargs[untyped]): untyped =
  ## generates the HTML ``sup`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "sup", commonAttr)

macro table*(e: varargs[untyped]): untyped =
  ## generates the HTML ``table`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "table", "border sortable" & commonAttr)

macro tbody*(e: varargs[untyped]): untyped =
  ## generates the HTML ``tbody`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "tbody", commonAttr)

macro td*(e: varargs[untyped]): untyped =
  ## generates the HTML ``td`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "td", "colspan rowspan headers" & commonAttr)

macro `template`*(e: varargs[untyped]): untyped =
  ## generates the HTML ``template`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "template", commonAttr)

macro textarea*(e: varargs[untyped]): untyped =
  ## generates the HTML ``textarea`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "textarea", "autocomplete autofocus cols " &
    "dirname disabled form inputmode maxlength minlength name placeholder " &
    "readonly required rows wrap" & commonAttr)

macro tfoot*(e: varargs[untyped]): untyped =
  ## generates the HTML ``tfoot`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "tfoot", commonAttr)

macro th*(e: varargs[untyped]): untyped =
  ## generates the HTML ``th`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "th", "colspan rowspan headers abbr scope axis" &
    " sorted" & commonAttr)

macro thead*(e: varargs[untyped]): untyped =
  ## generates the HTML ``thead`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "thead", commonAttr)

macro time*(e: varargs[untyped]): untyped =
  ## generates the HTML ``time`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "time", "datetime" & commonAttr)

macro title*(e: varargs[untyped]): untyped =
  ## generates the HTML ``title`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "title", commonAttr)

macro tr*(e: varargs[untyped]): untyped =
  ## generates the HTML ``tr`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "tr",  commonAttr)

macro track*(e: varargs[untyped]): untyped =
  ## generates the HTML ``track`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "track", "kind srclang label default" &
    commonAttr, "src", true)

macro tt*(e: varargs[untyped]): untyped =
  ## generates the HTML ``tt`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "tt", commonAttr)

macro u*(e: varargs[untyped]): untyped =
  ## generates the HTML ``u`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "u", commonAttr)

macro ul*(e: varargs[untyped]): untyped =
  ## generates the HTML ``ul`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "ul", commonAttr)

macro `var`*(e: varargs[untyped]): untyped =
  ## generates the HTML ``var`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "var", commonAttr)

macro video*(e: varargs[untyped]): untyped =
  ## generates the HTML ``video`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "video", "src crossorigin poster preload " &
    "autoplay mediagroup loop muted controls width height" & commonAttr)

macro wbr*(e: varargs[untyped]): untyped =
  ## generates the HTML ``wbr`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "wbr", commonAttr, "", true)

runnableExamples:
  let nim = "Nim"
  assert h1(a(href="http://nim-lang.org", nim)) ==
    """<h1><a href="http://nim-lang.org">Nim</a></h1>"""
  assert form(action="test", `accept-charset` = "Content-Type") ==
    """<form action="test" accept-charset="Content-Type"></form>"""
