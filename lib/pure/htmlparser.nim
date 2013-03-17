#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module parses an HTML document and creates its XML tree representation.
## It is supposed to handle the *wild* HTML the real world uses.
## 
## It can be used to parse a wild HTML document and output it as valid XHTML
## document (well, if you are lucky):
##
## .. code-block:: nimrod
##
##   echo loadHtml("mydirty.html")
##
##
## Every tag in the resulting tree is in lower case.
##
## **Note:** The resulting ``PXmlNode`` already uses the ``clientData`` field, 
## so it cannot be used by clients of this library.

import strutils, streams, parsexml, xmltree, unicode, strtabs

type
  THtmlTag* = enum ## list of all supported HTML tags; order will always be
                   ## alphabetically
    tagUnknown,    ## unknown HTML element
    tagA,          ## the HTML ``a`` element
    tagAbbr,       ## the deprecated HTML ``abbr`` element
    tagAcronym,    ## the HTML ``acronym`` element
    tagAddress,    ## the HTML ``address`` element
    tagApplet,     ## the deprecated HTML ``applet`` element
    tagArea,       ## the HTML ``area`` element
    tagB,          ## the HTML ``b`` element
    tagBase,       ## the HTML ``base`` element
    tagBdo,        ## the deprecated HTML ``dbo`` element
    tagBasefont,   ## the deprecated HTML ``basefont`` element
    tagBig,        ## the HTML ``big`` element
    tagBlockquote, ## the HTML ``blockquote`` element
    tagBody,       ## the HTML ``body`` element
    tagBr,         ## the HTML ``br`` element
    tagButton,     ## the HTML ``button`` element
    tagCaption,    ## the HTML ``caption`` element
    tagCenter,     ## the deprecated HTML ``center`` element
    tagCite,       ## the HTML ``cite`` element
    tagCode,       ## the HTML ``code`` element
    tagCol,        ## the HTML ``col`` element
    tagColgroup,   ## the HTML ``colgroup`` element
    tagDd,         ## the HTML ``dd`` element
    tagDel,        ## the HTML ``del`` element
    tagDfn,        ## the HTML ``dfn`` element
    tagDiv,        ## the HTML ``div`` element
    tagDir,        ## the deprecated HTLM ``dir`` element
    tagDl,         ## the HTML ``dl`` element
    tagDt,         ## the HTML ``dt`` element
    tagEm,         ## the HTML ``em`` element
    tagFieldset,   ## the HTML ``fieldset`` element
    tagFont,       ## the deprecated HTML ``font`` element
    tagForm,       ## the HTML ``form`` element
    tagFrame,      ## the HTML ``frame`` element
    tagFrameset,   ## the deprecated HTML ``frameset`` element
    tagH1,         ## the HTML ``h1`` element
    tagH2,         ## the HTML ``h2`` element
    tagH3,         ## the HTML ``h3`` element
    tagH4,         ## the HTML ``h4`` element
    tagH5,         ## the HTML ``h5`` element
    tagH6,         ## the HTML ``h6`` element
    tagHead,       ## the HTML ``head`` element
    tagHtml,       ## the HTML ``html`` element
    tagHr,         ## the HTML ``hr`` element
    tagI,          ## the HTML ``i`` element
    tagIframe,     ## the deprecated HTML ``iframe`` element
    tagImg,        ## the HTML ``img`` element
    tagInput,      ## the HTML ``input`` element
    tagIns,        ## the HTML ``ins`` element
    tagIsindex,    ## the deprecated HTML ``isindex`` element
    tagKbd,        ## the HTML ``kbd`` element
    tagLabel,      ## the HTML ``label`` element
    tagLegend,     ## the HTML ``legend`` element
    tagLi,         ## the HTML ``li`` element
    tagLink,       ## the HTML ``link`` element
    tagMap,        ## the HTML ``map`` element
    tagMenu,       ## the deprecated HTML ``menu`` element
    tagMeta,       ## the HTML ``meta`` element
    tagNobr,       ## the deprecated HTML ``nobr`` element
    tagNoframes,   ## the deprecated HTML ``noframes`` element
    tagNoscript,   ## the HTML ``noscript`` element
    tagObject,     ## the HTML ``object`` element
    tagOl,         ## the HTML ``ol`` element
    tagOptgroup,   ## the HTML ``optgroup`` element
    tagOption,     ## the HTML ``option`` element
    tagP,          ## the HTML ``p`` element
    tagParam,      ## the HTML ``param`` element
    tagPre,        ## the HTML ``pre`` element
    tagQ,          ## the HTML ``q`` element
    tagS,          ## the deprecated HTML ``s`` element
    tagSamp,       ## the HTML ``samp`` element
    tagScript,     ## the HTML ``script`` element
    tagSelect,     ## the HTML ``select`` element
    tagSmall,      ## the HTML ``small`` element
    tagSpan,       ## the HTML ``span`` element
    tagStrike,     ## the deprecated HTML ``strike`` element
    tagStrong,     ## the HTML ``strong`` element
    tagStyle,      ## the HTML ``style`` element
    tagSub,        ## the HTML ``sub`` element
    tagSup,        ## the HTML ``sup`` element
    tagTable,      ## the HTML ``table`` element
    tagTbody,      ## the HTML ``tbody`` element
    tagTd,         ## the HTML ``td`` element
    tagTextarea,   ## the HTML ``textarea`` element
    tagTfoot,      ## the HTML ``tfoot`` element
    tagTh,         ## the HTML ``th`` element
    tagThead,      ## the HTML ``thead`` element
    tagTitle,      ## the HTML ``title`` element
    tagTr,         ## the HTML ``tr`` element
    tagTt,         ## the HTML ``tt`` element
    tagU,          ## the deprecated HTML ``u`` element
    tagUl,         ## the HTML ``ul`` element
    tagVar         ## the HTML ``var`` element

const
  tagToStr* = [
    "a", "abbr", "acronym", "address", "applet", "area", 
    "b", "base", "basefont", "bdo", "big", "blockquote", "body", 
    "br", "button", "caption", "center", "cite", "code", 
    "col", "colgroup", "dd", "del", "dfn", "div", 
    "dir", "dl", "dt", "em", "fieldset", "font", 
    "form", "frame", "frameset", "h1", "h2", "h3", 
    "h4", "h5", "h6", "head", "html", "hr", 
    "i", "iframe", "img", "input", "ins", "isindex", 
    "kbd", "label", "legend", "li", "link", "map", 
    "menu", "meta", "nobr", "noframes", "noscript", "object", "ol", 
    "optgroup", "option", "p", "param", "pre", "q", 
    "s", "samp", "script", "select", "small", "span", 
    "strike", "strong", "style", "sub", "sup", "table", 
    "tbody", "td", "textarea", "tfoot", "th", "thead", 
    "title", "tr", "tt", "u", "ul", "var"]
  InlineTags* = {tagA, tagAbbr, tagAcronym, tagApplet, tagB, tagBasefont,
    tagBdo, tagBig, tagBr, tagButton, tagCite, tagCode, tagDel, tagDfn,
    tagEm, tagFont, tagI, tagImg, tagIns, tagInput, tagIframe, tagKbd,
    tagLabel, tagMap, tagObject, tagQ, tagSamp, tagScript, tagSelect,
    tagSmall, tagSpan, tagStrong, tagSub, tagSup, tagTextarea, tagTt,
    tagVar, tagApplet, tagBasefont, tagFont, tagIframe, tagU, tagS, 
    tagStrike}
  BlockTags* = {tagAddress, tagBlockquote, tagCenter, tagDel, tagDir, tagDiv, 
    tagDl, tagFieldset, tagForm, tagH1, tagH2, tagH3, tagH4, 
    tagH5, tagH6, tagHr, tagIns, tagIsindex, tagMenu, tagNoframes, tagNoscript, 
    tagOl, tagP, tagPre, tagTable, tagUl, tagCenter, tagDir, tagIsindex, 
    tagMenu, tagNoframes}
  SingleTags* = {tagArea, tagBase, tagBasefont, 
    tagBr, tagCol, tagFrame, tagHr, tagImg, tagIsindex,
    tagLink, tagMeta, tagParam}
  
  Entities = [
    ("nbsp", 0x00A0), ("iexcl", 0x00A1), ("cent", 0x00A2), ("pound", 0x00A3),
    ("curren", 0x00A4), ("yen", 0x00A5), ("brvbar", 0x00A6), ("sect", 0x00A7),
    ("uml", 0x00A8), ("copy", 0x00A9), ("ordf", 0x00AA), ("laquo", 0x00AB),
    ("not", 0x00AC), ("shy", 0x00AD), ("reg", 0x00AE), ("macr", 0x00AF),
    ("deg", 0x00B0), ("plusmn", 0x00B1), ("sup2", 0x00B2), ("sup3", 0x00B3),
    ("acute", 0x00B4), ("micro", 0x00B5), ("para", 0x00B6), ("middot", 0x00B7),
    ("cedil", 0x00B8), ("sup1", 0x00B9), ("ordm", 0x00BA), ("raquo", 0x00BB),
    ("frac14", 0x00BC), ("frac12", 0x00BD), ("frac34", 0x00BE), 
    ("iquest", 0x00BF), ("Agrave", 0x00C0), ("Aacute", 0x00C1),
    ("Acirc", 0x00C2), ("Atilde", 0x00C3), ("Auml", 0x00C4), ("Aring", 0x00C5),
    ("AElig", 0x00C6), ("Ccedil", 0x00C7), ("Egrave", 0x00C8),
    ("Eacute", 0x00C9), ("Ecirc", 0x00CA), ("Euml", 0x00CB), ("Igrave", 0x00CC),
    ("Iacute", 0x00CD), ("Icirc", 0x00CE), ("Iuml", 0x00CF), ("ETH", 0x00D0),
    ("Ntilde", 0x00D1), ("Ograve", 0x00D2), ("Oacute", 0x00D3), 
    ("Ocirc", 0x00D4), ("Otilde", 0x00D5), ("Ouml", 0x00D6), ("times", 0x00D7),
    ("Oslash", 0x00D8), ("Ugrave", 0x00D9), ("Uacute", 0x00DA),
    ("Ucirc", 0x00DB), ("Uuml", 0x00DC), ("Yacute", 0x00DD), ("THORN", 0x00DE),
    ("szlig", 0x00DF), ("agrave", 0x00E0), ("aacute", 0x00E1),
    ("acirc", 0x00E2), ("atilde", 0x00E3), ("auml", 0x00E4), ("aring", 0x00E5),
    ("aelig", 0x00E6), ("ccedil", 0x00E7), ("egrave", 0x00E8),
    ("eacute", 0x00E9), ("ecirc", 0x00EA), ("euml", 0x00EB), ("igrave", 0x00EC),
    ("iacute", 0x00ED), ("icirc", 0x00EE), ("iuml", 0x00EF), ("eth", 0x00F0),
    ("ntilde", 0x00F1), ("ograve", 0x00F2), ("oacute", 0x00F3),
    ("ocirc", 0x00F4), ("otilde", 0x00F5), ("ouml", 0x00F6), ("divide", 0x00F7),
    ("oslash", 0x00F8), ("ugrave", 0x00F9), ("uacute", 0x00FA),
    ("ucirc", 0x00FB), ("uuml", 0x00FC), ("yacute", 0x00FD), ("thorn", 0x00FE),
    ("yuml", 0x00FF), ("OElig", 0x0152), ("oelig", 0x0153), ("Scaron", 0x0160),
    ("scaron", 0x0161), ("Yuml", 0x0178), ("fnof", 0x0192), ("circ", 0x02C6),
    ("tilde", 0x02DC), ("Alpha", 0x0391), ("Beta", 0x0392), ("Gamma", 0x0393),
    ("Delta", 0x0394), ("Epsilon", 0x0395), ("Zeta", 0x0396), ("Eta", 0x0397),
    ("Theta", 0x0398), ("Iota", 0x0399), ("Kappa", 0x039A), ("Lambda", 0x039B),
    ("Mu", 0x039C), ("Nu", 0x039D), ("Xi", 0x039E), ("Omicron", 0x039F),
    ("Pi", 0x03A0), ("Rho", 0x03A1), ("Sigma", 0x03A3), ("Tau", 0x03A4),
    ("Upsilon", 0x03A5), ("Phi", 0x03A6), ("Chi", 0x03A7), ("Psi", 0x03A8),
    ("Omega", 0x03A9), ("alpha", 0x03B1), ("beta", 0x03B2), ("gamma", 0x03B3),
    ("delta", 0x03B4), ("epsilon", 0x03B5), ("zeta", 0x03B6), ("eta", 0x03B7),
    ("theta", 0x03B8), ("iota", 0x03B9), ("kappa", 0x03BA), ("lambda", 0x03BB),
    ("mu", 0x03BC), ("nu", 0x03BD), ("xi", 0x03BE), ("omicron", 0x03BF),
    ("pi", 0x03C0), ("rho", 0x03C1), ("sigmaf", 0x03C2), ("sigma", 0x03C3),
    ("tau", 0x03C4), ("upsilon", 0x03C5), ("phi", 0x03C6), ("chi", 0x03C7),
    ("psi", 0x03C8), ("omega", 0x03C9), ("thetasym", 0x03D1), ("upsih", 0x03D2),
    ("piv", 0x03D6), ("ensp", 0x2002), ("emsp", 0x2003), ("thinsp", 0x2009),
    ("zwnj", 0x200C), ("zwj", 0x200D), ("lrm", 0x200E), ("rlm", 0x200F),
    ("ndash", 0x2013), ("mdash", 0x2014), ("lsquo", 0x2018), ("rsquo", 0x2019),
    ("sbquo", 0x201A), ("ldquo", 0x201C), ("rdquo", 0x201D), ("bdquo", 0x201E),
    ("dagger", 0x2020), ("Dagger", 0x2021), ("bull", 0x2022), 
    ("hellip", 0x2026), ("permil", 0x2030), ("prime", 0x2032),
    ("Prime", 0x2033), ("lsaquo", 0x2039), ("rsaquo", 0x203A),
    ("oline", 0x203E), ("frasl", 0x2044), ("euro", 0x20AC),
    ("image", 0x2111), ("weierp", 0x2118), ("real", 0x211C),
    ("trade", 0x2122), ("alefsym", 0x2135), ("larr", 0x2190),
    ("uarr", 0x2191), ("rarr", 0x2192), ("darr", 0x2193),
    ("harr", 0x2194), ("crarr", 0x21B5), ("lArr", 0x21D0),
    ("uArr", 0x21D1), ("rArr", 0x21D2), ("dArr", 0x21D3),
    ("hArr", 0x21D4), ("forall", 0x2200), ("part", 0x2202),
    ("exist", 0x2203), ("empty", 0x2205), ("nabla", 0x2207),
    ("isin", 0x2208), ("notin", 0x2209), ("ni", 0x220B),
    ("prod", 0x220F), ("sum", 0x2211), ("minus", 0x2212),
    ("lowast", 0x2217), ("radic", 0x221A), ("prop", 0x221D),
    ("infin", 0x221E), ("ang", 0x2220), ("and", 0x2227),
    ("or", 0x2228), ("cap", 0x2229), ("cup", 0x222A),
    ("int", 0x222B), ("there4", 0x2234), ("sim", 0x223C),
    ("cong", 0x2245), ("asymp", 0x2248), ("ne", 0x2260),
    ("equiv", 0x2261), ("le", 0x2264), ("ge", 0x2265),
    ("sub", 0x2282), ("sup", 0x2283), ("nsub", 0x2284),
    ("sube", 0x2286), ("supe", 0x2287), ("oplus", 0x2295),
    ("otimes", 0x2297), ("perp", 0x22A5), ("sdot", 0x22C5),
    ("lceil", 0x2308), ("rceil", 0x2309), ("lfloor", 0x230A),
    ("rfloor", 0x230B), ("lang", 0x2329), ("rang", 0x232A),
    ("loz", 0x25CA), ("spades", 0x2660), ("clubs", 0x2663),
    ("hearts", 0x2665), ("diams", 0x2666)]

proc binaryStrSearch(x: openarray[string], y: string): int = 
  ## XXX put this into the library somewhere!
  var a = 0
  var b = len(x) - 1
  while a <= b: 
    var mid = (a + b) div 2
    var c = cmp(x[mid], y)
    if c < 0: a = mid + 1
    elif c > 0: b = mid - 1
    else: return mid
  result = - 1

proc htmlTag*(n: PXmlNode): THtmlTag = 
  ## gets `n`'s tag as a ``THtmlTag``.
  if n.clientData == 0:
    n.clientData = binaryStrSearch(tagToStr, n.tag)+1
  result = THtmlTag(n.clientData)

proc htmlTag*(s: string): THtmlTag =
  ## converts `s` to a ``THtmlTag``. If `s` is no HTML tag, ``tagUnknown`` is
  ## returned.
  result = THtmlTag(binaryStrSearch(tagToStr, s.toLower)+1)

proc entityToUtf8*(entity: string): string = 
  ## converts an HTML entity name like ``&Uuml;`` to its UTF-8 equivalent.
  ## "" is returned if the entity name is unknown. The HTML parser
  ## already converts entities to UTF-8.
  for name, val in items(entities):
    if name == entity: return toUTF8(TRune(val))
  result = ""

proc addNode(father, son: PXmlNode) = 
  if son != nil: add(father, son)

proc parse(x: var TXmlParser, errors: var seq[string]): PXmlNode

proc expected(x: var TXmlParser, n: PXmlNode): string =
  result = errorMsg(x, "</" & n.tag & "> expected")

proc untilElementEnd(x: var TXmlParser, result: PXmlNode, 
                     errors: var seq[string]) =
  # we parsed e.g. ``<br>`` and don't really expect a ``</br>``: 
  if result.htmlTag in singleTags:
    if x.kind != xmlElementEnd or cmpIgnoreCase(x.elementName, result.tag) != 0:
      return
  while true:
    case x.kind
    of xmlElementStart, xmlElementOpen:
      case result.htmlTag
      of tagLi, tagP, tagDt, tagDd, tagInput, tagOption:
        # some tags are common to have no ``</end>``, like ``<li>``:
        if htmlTag(x.elementName) in {tagLi, tagP, tagDt, tagDd, tagInput,
                                      tagOption}:
          errors.add(expected(x, result))
          break
        when false:
          if htmlTag(x.elementName) notin InlineTags:
            errors.add(expected(x, result))
            break
      of tagTr, tagTd, tagTh, tagTfoot, tagThead:
        if htmlTag(x.elementName) in {tagTr, tagTd, tagTh, tagTfoot, tagThead}:
          errors.add(expected(x, result))
          break
      of tagOptgroup:
        if htmlTag(x.elementName) in {tagOption, tagOptgroup}:
          errors.add(expected(x, result))
          break
      else: nil
      result.addNode(parse(x, errors))
    of xmlElementEnd: 
      if cmpIgnoreCase(x.elementName, result.tag) == 0: 
        next(x)
      else:
        errors.add(expected(x, result))
        # do not skip it here!
      break
    of xmlEof:
      errors.add(expected(x, result))
      break
    else:
      result.addNode(parse(x, errors))

proc parse(x: var TXmlParser, errors: var seq[string]): PXmlNode =
  case x.kind
  of xmlComment: 
    result = newComment(x.charData)
    next(x)
  of xmlCharData, xmlWhitespace:
    result = newText(x.charData)
    next(x)
  of xmlPI, xmlSpecial:
    # we just ignore processing instructions for now
    next(x)
  of xmlError:
    errors.add(errorMsg(x))
    next(x)
  of xmlElementStart:
    result = newElement(x.elementName.toLower)
    next(x)
    untilElementEnd(x, result, errors)
  of xmlElementEnd:
    errors.add(errorMsg(x, "unexpected ending tag: " & x.elementName))
  of xmlElementOpen: 
    result = newElement(x.elementName.toLower)
    next(x)
    result.attrs = newStringTable()
    while true: 
      case x.kind
      of xmlAttribute:
        result.attrs[x.attrKey] = x.attrValue
        next(x)
      of xmlElementClose:
        next(x)
        break
      of xmlError:
        errors.add(errorMsg(x))
        next(x)
        break
      else:
        errors.add(errorMsg(x, "'>' expected"))
        next(x)
        break
    untilElementEnd(x, result, errors)
  of xmlAttribute, xmlElementClose:
    errors.add(errorMsg(x, "<some_tag> expected"))
    next(x)
  of xmlCData: 
    result = newCData(x.charData)
    next(x)
  of xmlEntity:
    var u = entityToUtf8(x.entityName)
    if u.len != 0: result = newText(u)
    next(x)
  of xmlEof: nil

proc parseHtml*(s: PStream, filename: string, 
                errors: var seq[string]): PXmlNode = 
  ## parses the XML from stream `s` and returns a ``PXmlNode``. Every
  ## occured parsing error is added to the `errors` sequence.
  var x: TXmlParser
  open(x, s, filename, {reportComments})
  next(x)
  # skip the DOCTYPE:
  if x.kind == xmlSpecial: next(x)
  result = parse(x, errors)
  if x.kind != xmlEof:
    errors.add(errorMsg(x, "EOF expected"))
  while x.kind != xmlEof:
    var oldPos = x.bufpos # little hack to see if we made any progess
    result.addNode(parse(x, errors))
    if x.bufpos == oldPos: 
      # force progress!
      next(x) 
  close(x)

proc parseHtml*(s: PStream): PXmlNode = 
  ## parses the XTML from stream `s` and returns a ``PXmlNode``. All parsing
  ## errors are ignored.
  var errors: seq[string] = @[]
  result = parseHtml(s, "unknown_html_doc", errors)

proc loadHtml*(path: string, errors: var seq[string]): PXmlNode = 
  ## Loads and parses HTML from file specified by ``path``, and returns 
  ## a ``PXmlNode``.  Every occured parsing error is added to
  ## the `errors` sequence.
  var s = newFileStream(path, fmRead)
  if s == nil: raise newException(EIO, "Unable to read file: " & path)
  result = parseHtml(s, path, errors)

proc loadHtml*(path: string): PXmlNode = 
  ## Loads and parses HTML from file specified by ``path``, and returns 
  ## a ``PXmlNode``. All parsing errors are ignored.
  var errors: seq[string] = @[]  
  result = loadHtml(path, errors)

when true:
  nil
else:
  proc checkHtmlAux(n: PXmlNode, errors: var seq[string]) =
    nil
  
  proc checkHtmlStructure*(n: PXmlNode, errors: var seq[string]) =
    ## checks the HTML structure after parsing for other errors like 
    ## a ``<h1>`` element within a ``<p>`` element.
    if n == nil or n.htmlTag != tagHtml: 
      errors.add("<html> tag expected")
    checkHtmlAux(n, errors)
  
when isMainModule:
  import os

  var errors: seq[string] = @[]  
  var x = loadHtml(paramStr(1), errors)
  for e in items(errors): echo e
  
  var f: TFile
  if open(f, "test.txt", fmWrite):
    f.write($x)
    f.close()
  else:
    quit("cannot write test.txt")
  
