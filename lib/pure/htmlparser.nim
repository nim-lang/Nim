#
#
#            Nim's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf
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
## .. code-block:: Nim
##
##   echo loadHtml("mydirty.html")
##
## Every tag in the resulting tree is in lower case.
##
## **Note:** The resulting ``XmlNode`` already uses the ``clientData`` field,
## so it cannot be used by clients of this library.
##
## Example: Transforming hyperlinks
## ================================
##
## This code demonstrates how you can iterate over all the tags in an HTML file
## and write back the modified version. In this case we look for hyperlinks
## ending with the extension ``.rst`` and convert them to ``.html``.
##
## .. code-block:: Nim
##
##   import htmlparser
##   import xmltree  # To use '$' for XmlNode
##   import strtabs  # To access XmlAttributes
##   import os       # To use splitFile
##   import strutils # To use cmpIgnoreCase
##
##   proc transformHyperlinks() =
##     let html = loadHTML("input.html")
##
##     for a in html.findAll("a"):
##       let href = a.attrs["href"]
##       if not href.isNil:
##         let (dir, filename, ext) = splitFile(href)
##         if cmpIgnoreCase(ext, ".rst") == 0:
##           a.attrs["href"] = dir / filename & ".html"
##
##     writeFile("output.html", $html)

import strutils, streams, parsexml, xmltree, unicode, strtabs

type
  HtmlTag* = enum ## list of all supported HTML tags; order will always be
                   ## alphabetically
    tagUnknown,    ## unknown HTML element
    tagA,          ## the HTML ``a`` element
    tagAbbr,       ## the deprecated HTML ``abbr`` element
    tagAcronym,    ## the HTML ``acronym`` element
    tagAddress,    ## the HTML ``address`` element
    tagApplet,     ## the deprecated HTML ``applet`` element
    tagArea,       ## the HTML ``area`` element
    tagArticle,    ## the HTML ``article`` element
    tagAside,      ## the HTML ``aside`` element
    tagAudio,      ## the HTML ``audio`` element
    tagB,          ## the HTML ``b`` element
    tagBase,       ## the HTML ``base`` element
    tagBdi,        ## the HTML ``bdi`` element
    tagBdo,        ## the deprecated HTML ``dbo`` element
    tagBasefont,   ## the deprecated HTML ``basefont`` element
    tagBig,        ## the HTML ``big`` element
    tagBlockquote, ## the HTML ``blockquote`` element
    tagBody,       ## the HTML ``body`` element
    tagBr,         ## the HTML ``br`` element
    tagButton,     ## the HTML ``button`` element
    tagCanvas,     ## the HTML ``canvas`` element
    tagCaption,    ## the HTML ``caption`` element
    tagCenter,     ## the deprecated HTML ``center`` element
    tagCite,       ## the HTML ``cite`` element
    tagCode,       ## the HTML ``code`` element
    tagCol,        ## the HTML ``col`` element
    tagColgroup,   ## the HTML ``colgroup`` element
    tagCommand,    ## the HTML ``command`` element
    tagDatalist,   ## the HTML ``datalist`` element
    tagDd,         ## the HTML ``dd`` element
    tagDel,        ## the HTML ``del`` element
    tagDetails,    ## the HTML ``details`` element
    tagDfn,        ## the HTML ``dfn`` element
    tagDialog,     ## the HTML ``dialog`` element
    tagDiv,        ## the HTML ``div`` element
    tagDir,        ## the deprecated HTLM ``dir`` element
    tagDl,         ## the HTML ``dl`` element
    tagDt,         ## the HTML ``dt`` element
    tagEm,         ## the HTML ``em`` element
    tagEmbed,      ## the HTML ``embed`` element
    tagFieldset,   ## the HTML ``fieldset`` element
    tagFigcaption, ## the HTML ``figcaption`` element
    tagFigure,     ## the HTML ``figure`` element
    tagFont,       ## the deprecated HTML ``font`` element
    tagFooter,     ## the HTML ``footer`` element
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
    tagHeader,     ## the HTML ``header`` element
    tagHgroup,     ## the HTML ``hgroup`` element
    tagHtml,       ## the HTML ``html`` element
    tagHr,         ## the HTML ``hr`` element
    tagI,          ## the HTML ``i`` element
    tagIframe,     ## the deprecated HTML ``iframe`` element
    tagImg,        ## the HTML ``img`` element
    tagInput,      ## the HTML ``input`` element
    tagIns,        ## the HTML ``ins`` element
    tagIsindex,    ## the deprecated HTML ``isindex`` element
    tagKbd,        ## the HTML ``kbd`` element
    tagKeygen,     ## the HTML ``keygen`` element
    tagLabel,      ## the HTML ``label`` element
    tagLegend,     ## the HTML ``legend`` element
    tagLi,         ## the HTML ``li`` element
    tagLink,       ## the HTML ``link`` element
    tagMap,        ## the HTML ``map`` element
    tagMark,       ## the HTML ``mark`` element
    tagMenu,       ## the deprecated HTML ``menu`` element
    tagMeta,       ## the HTML ``meta`` element
    tagMeter,      ## the HTML ``meter`` element
    tagNav,        ## the HTML ``nav`` element
    tagNobr,       ## the deprecated HTML ``nobr`` element
    tagNoframes,   ## the deprecated HTML ``noframes`` element
    tagNoscript,   ## the HTML ``noscript`` element
    tagObject,     ## the HTML ``object`` element
    tagOl,         ## the HTML ``ol`` element
    tagOptgroup,   ## the HTML ``optgroup`` element
    tagOption,     ## the HTML ``option`` element
    tagOutput,     ## the HTML ``output`` element
    tagP,          ## the HTML ``p`` element
    tagParam,      ## the HTML ``param`` element
    tagPre,        ## the HTML ``pre`` element
    tagProgress,   ## the HTML ``progress`` element
    tagQ,          ## the HTML ``q`` element
    tagRp,         ## the HTML ``rp`` element
    tagRt,         ## the HTML ``rt`` element
    tagRuby,       ## the HTML ``ruby`` element
    tagS,          ## the deprecated HTML ``s`` element
    tagSamp,       ## the HTML ``samp`` element
    tagScript,     ## the HTML ``script`` element
    tagSection,    ## the HTML ``section`` element
    tagSelect,     ## the HTML ``select`` element
    tagSmall,      ## the HTML ``small`` element
    tagSource,     ## the HTML ``source`` element
    tagSpan,       ## the HTML ``span`` element
    tagStrike,     ## the deprecated HTML ``strike`` element
    tagStrong,     ## the HTML ``strong`` element
    tagStyle,      ## the HTML ``style`` element
    tagSub,        ## the HTML ``sub`` element
    tagSummary,    ## the HTML ``summary`` element
    tagSup,        ## the HTML ``sup`` element
    tagTable,      ## the HTML ``table`` element
    tagTbody,      ## the HTML ``tbody`` element
    tagTd,         ## the HTML ``td`` element
    tagTextarea,   ## the HTML ``textarea`` element
    tagTfoot,      ## the HTML ``tfoot`` element
    tagTh,         ## the HTML ``th`` element
    tagThead,      ## the HTML ``thead`` element
    tagTime,       ## the HTML ``time`` element
    tagTitle,      ## the HTML ``title`` element
    tagTr,         ## the HTML ``tr`` element
    tagTrack,      ## the HTML ``track`` element
    tagTt,         ## the HTML ``tt`` element
    tagU,          ## the deprecated HTML ``u`` element
    tagUl,         ## the HTML ``ul`` element
    tagVar,        ## the HTML ``var`` element
    tagVideo,      ## the HTML ``video`` element
    tagWbr         ## the HTML ``wbr`` element

const
  tagToStr* = [
    "a", "abbr", "acronym", "address", "applet", "area", "article",
    "aside", "audio",
    "b", "base", "basefont", "bdi", "bdo", "big", "blockquote", "body",
    "br", "button", "canvas", "caption", "center", "cite", "code",
    "col", "colgroup", "command",
    "datalist", "dd", "del", "details", "dfn", "dialog", "div",
    "dir", "dl", "dt", "em", "embed", "fieldset",
    "figcaption", "figure", "font", "footer",
    "form", "frame", "frameset", "h1", "h2", "h3",
    "h4", "h5", "h6", "head", "header", "hgroup", "html", "hr",
    "i", "iframe", "img", "input", "ins", "isindex",
    "kbd", "keygen", "label", "legend", "li", "link", "map", "mark",
    "menu", "meta", "meter", "nav", "nobr", "noframes", "noscript",
    "object", "ol",
    "optgroup", "option", "output", "p", "param", "pre", "progress", "q",
    "rp", "rt", "ruby", "s", "samp", "script", "section", "select", "small",
    "source", "span", "strike", "strong", "style",
    "sub", "summary", "sup", "table",
    "tbody", "td", "textarea", "tfoot", "th", "thead", "time",
    "title", "tr", "track", "tt", "u", "ul", "var", "video", "wbr"]
  InlineTags* = {tagA, tagAbbr, tagAcronym, tagApplet, tagB, tagBasefont,
    tagBdo, tagBig, tagBr, tagButton, tagCite, tagCode, tagDel, tagDfn,
    tagEm, tagFont, tagI, tagImg, tagIns, tagInput, tagIframe, tagKbd,
    tagLabel, tagMap, tagObject, tagQ, tagSamp, tagScript, tagSelect,
    tagSmall, tagSpan, tagStrong, tagSub, tagSup, tagTextarea, tagTt,
    tagVar, tagApplet, tagBasefont, tagFont, tagIframe, tagU, tagS,
    tagStrike, tagWbr}
  BlockTags* = {tagAddress, tagBlockquote, tagCenter, tagDel, tagDir, tagDiv,
    tagDl, tagFieldset, tagForm, tagH1, tagH2, tagH3, tagH4,
    tagH5, tagH6, tagHr, tagIns, tagIsindex, tagMenu, tagNoframes, tagNoscript,
    tagOl, tagP, tagPre, tagTable, tagUl, tagCenter, tagDir, tagIsindex,
    tagMenu, tagNoframes}
  SingleTags* = {tagArea, tagBase, tagBasefont,
    tagBr, tagCol, tagFrame, tagHr, tagImg, tagIsindex,
    tagLink, tagMeta, tagParam, tagWbr}

proc allLower(s: string): bool =
  for c in s:
    if c < 'a' or c > 'z': return false
  return true

proc toHtmlTag(s: string): HtmlTag =
  case s
  of "a": tagA
  of "abbr": tagAbbr
  of "acronym": tagAcronym
  of "address": tagAddress
  of "applet": tagApplet
  of "area": tagArea
  of "article": tagArticle
  of "aside": tagAside
  of "audio": tagAudio
  of "b": tagB
  of "base": tagBase
  of "basefont": tagBasefont
  of "bdi": tagBdi
  of "bdo": tagBdo
  of "big": tagBig
  of "blockquote": tagBlockquote
  of "body": tagBody
  of "br": tagBr
  of "button": tagButton
  of "canvas": tagCanvas
  of "caption": tagCaption
  of "center": tagCenter
  of "cite": tagCite
  of "code": tagCode
  of "col": tagCol
  of "colgroup": tagColgroup
  of "command": tagCommand
  of "datalist": tagDatalist
  of "dd": tagDd
  of "del": tagDel
  of "details": tagDetails
  of "dfn": tagDfn
  of "dialog": tagDialog
  of "div": tagDiv
  of "dir": tagDir
  of "dl": tagDl
  of "dt": tagDt
  of "em": tagEm
  of "embed": tagEmbed
  of "fieldset": tagFieldset
  of "figcaption": tagFigcaption
  of "figure": tagFigure
  of "font": tagFont
  of "footer": tagFooter
  of "form": tagForm
  of "frame": tagFrame
  of "frameset": tagFrameset
  of "h1": tagH1
  of "h2": tagH2
  of "h3": tagH3
  of "h4": tagH4
  of "h5": tagH5
  of "h6": tagH6
  of "head": tagHead
  of "header": tagHeader
  of "hgroup": tagHgroup
  of "html": tagHtml
  of "hr": tagHr
  of "i": tagI
  of "iframe": tagIframe
  of "img": tagImg
  of "input": tagInput
  of "ins": tagIns
  of "isindex": tagIsindex
  of "kbd": tagKbd
  of "keygen": tagKeygen
  of "label": tagLabel
  of "legend": tagLegend
  of "li": tagLi
  of "link": tagLink
  of "map": tagMap
  of "mark": tagMark
  of "menu": tagMenu
  of "meta": tagMeta
  of "meter": tagMeter
  of "nav": tagNav
  of "nobr": tagNobr
  of "noframes": tagNoframes
  of "noscript": tagNoscript
  of "object": tagObject
  of "ol": tagOl
  of "optgroup": tagOptgroup
  of "option": tagOption
  of "output": tagOutput
  of "p": tagP
  of "param": tagParam
  of "pre": tagPre
  of "progress": tagProgress
  of "q": tagQ
  of "rp": tagRp
  of "rt": tagRt
  of "ruby": tagRuby
  of "s": tagS
  of "samp": tagSamp
  of "script": tagScript
  of "section": tagSection
  of "select": tagSelect
  of "small": tagSmall
  of "source": tagSource
  of "span": tagSpan
  of "strike": tagStrike
  of "strong": tagStrong
  of "style": tagStyle
  of "sub": tagSub
  of "summary": tagSummary
  of "sup": tagSup
  of "table": tagTable
  of "tbody": tagTbody
  of "td": tagTd
  of "textarea": tagTextarea
  of "tfoot": tagTfoot
  of "th": tagTh
  of "thead": tagThead
  of "time": tagTime
  of "title": tagTitle
  of "tr": tagTr
  of "track": tagTrack
  of "tt": tagTt
  of "u": tagU
  of "ul": tagUl
  of "var": tagVar
  of "video": tagVideo
  of "wbr": tagWbr
  else: tagUnknown


proc htmlTag*(n: XmlNode): HtmlTag =
  ## Gets `n`'s tag as a ``HtmlTag``.
  if n.clientData == 0:
    n.clientData = toHtmlTag(n.tag).ord
  result = HtmlTag(n.clientData)

proc htmlTag*(s: string): HtmlTag =
  ## Converts `s` to a ``HtmlTag``. If `s` is no HTML tag, ``tagUnknown`` is
  ## returned.
  let s = if allLower(s): s else: toLowerAscii(s)
  result = toHtmlTag(s)

proc runeToEntity*(rune: Rune): string =
  ## converts a Rune to its numeric HTML entity equivalent.
  runnableExamples:
    import unicode
    doAssert runeToEntity(Rune(0)) == ""
    doAssert runeToEntity(Rune(-1)) == ""
    doAssert runeToEntity("Ü".runeAt(0)) == "#220"
    doAssert runeToEntity("∈".runeAt(0)) == "#8712"
  if rune.ord <= 0: result = ""
  else: result = '#' & $rune.ord

proc entityToRune*(entity: string): Rune =
  ## Converts an HTML entity name like ``&Uuml;`` or values like ``&#220;``
  ## or ``&#x000DC;`` to its UTF-8 equivalent.
  ## Rune(0) is returned if the entity name is unknown.
  runnableExamples:
    import unicode
    doAssert entityToRune("") == Rune(0)
    doAssert entityToRune("a") == Rune(0)
    doAssert entityToRune("gt") == ">".runeAt(0)
    doAssert entityToRune("Uuml") == "Ü".runeAt(0)
    doAssert entityToRune("quest") == "?".runeAt(0)
    doAssert entityToRune("#x0003F") == "?".runeAt(0)
  if entity.len < 2: return # smallest entity has length 2
  if entity[0] == '#':
    case entity[1]
    of '0'..'9':
      try: return Rune(parseInt(entity[1..^1]))
      except: return
    of 'x', 'X': # not case sensitive here
      try: return Rune(parseHexInt(entity[2..^1]))
      except: return
    else: return # other entities are not defined with prefix ``#``
  case entity # entity names are case sensitive
  of "Tab": result = Rune(0x00009)
  of "NewLine": result = Rune(0x0000A)
  of "excl": result = Rune(0x00021)
  of "quot", "QUOT": result = Rune(0x00022)
  of "num": result = Rune(0x00023)
  of "dollar": result = Rune(0x00024)
  of "percnt": result = Rune(0x00025)
  of "amp", "AMP": result = Rune(0x00026)
  of "apos": result = Rune(0x00027)
  of "lpar": result = Rune(0x00028)
  of "rpar": result = Rune(0x00029)
  of "ast", "midast": result = Rune(0x0002A)
  of "plus": result = Rune(0x0002B)
  of "comma": result = Rune(0x0002C)
  of "period": result = Rune(0x0002E)
  of "sol": result = Rune(0x0002F)
  of "colon": result = Rune(0x0003A)
  of "semi": result = Rune(0x0003B)
  of "lt", "LT": result = Rune(0x0003C)
  of "equals": result = Rune(0x0003D)
  of "gt", "GT": result = Rune(0x0003E)
  of "quest": result = Rune(0x0003F)
  of "commat": result = Rune(0x00040)
  of "lsqb", "lbrack": result = Rune(0x0005B)
  of "bsol": result = Rune(0x0005C)
  of "rsqb", "rbrack": result = Rune(0x0005D)
  of "Hat": result = Rune(0x0005E)
  of "lowbar": result = Rune(0x0005F)
  of "grave", "DiacriticalGrave": result = Rune(0x00060)
  of "lcub", "lbrace": result = Rune(0x0007B)
  of "verbar", "vert", "VerticalLine": result = Rune(0x0007C)
  of "rcub", "rbrace": result = Rune(0x0007D)
  of "nbsp", "NonBreakingSpace": result = Rune(0x000A0)
  of "iexcl": result = Rune(0x000A1)
  of "cent": result = Rune(0x000A2)
  of "pound": result = Rune(0x000A3)
  of "curren": result = Rune(0x000A4)
  of "yen": result = Rune(0x000A5)
  of "brvbar": result = Rune(0x000A6)
  of "sect": result = Rune(0x000A7)
  of "Dot", "die", "DoubleDot", "uml": result = Rune(0x000A8)
  of "copy", "COPY": result = Rune(0x000A9)
  of "ordf": result = Rune(0x000AA)
  of "laquo": result = Rune(0x000AB)
  of "not": result = Rune(0x000AC)
  of "shy": result = Rune(0x000AD)
  of "reg", "circledR", "REG": result = Rune(0x000AE)
  of "macr", "OverBar", "strns": result = Rune(0x000AF)
  of "deg": result = Rune(0x000B0)
  of "plusmn", "pm", "PlusMinus": result = Rune(0x000B1)
  of "sup2": result = Rune(0x000B2)
  of "sup3": result = Rune(0x000B3)
  of "acute", "DiacriticalAcute": result = Rune(0x000B4)
  of "micro": result = Rune(0x000B5)
  of "para": result = Rune(0x000B6)
  of "middot", "centerdot", "CenterDot": result = Rune(0x000B7)
  of "cedil", "Cedilla": result = Rune(0x000B8)
  of "sup1": result = Rune(0x000B9)
  of "ordm": result = Rune(0x000BA)
  of "raquo": result = Rune(0x000BB)
  of "frac14": result = Rune(0x000BC)
  of "frac12", "half": result = Rune(0x000BD)
  of "frac34": result = Rune(0x000BE)
  of "iquest": result = Rune(0x000BF)
  of "Agrave": result = Rune(0x000C0)
  of "Aacute": result = Rune(0x000C1)
  of "Acirc": result = Rune(0x000C2)
  of "Atilde": result = Rune(0x000C3)
  of "Auml": result = Rune(0x000C4)
  of "Aring": result = Rune(0x000C5)
  of "AElig": result = Rune(0x000C6)
  of "Ccedil": result = Rune(0x000C7)
  of "Egrave": result = Rune(0x000C8)
  of "Eacute": result = Rune(0x000C9)
  of "Ecirc": result = Rune(0x000CA)
  of "Euml": result = Rune(0x000CB)
  of "Igrave": result = Rune(0x000CC)
  of "Iacute": result = Rune(0x000CD)
  of "Icirc": result = Rune(0x000CE)
  of "Iuml": result = Rune(0x000CF)
  of "ETH": result = Rune(0x000D0)
  of "Ntilde": result = Rune(0x000D1)
  of "Ograve": result = Rune(0x000D2)
  of "Oacute": result = Rune(0x000D3)
  of "Ocirc": result = Rune(0x000D4)
  of "Otilde": result = Rune(0x000D5)
  of "Ouml": result = Rune(0x000D6)
  of "times": result = Rune(0x000D7)
  of "Oslash": result = Rune(0x000D8)
  of "Ugrave": result = Rune(0x000D9)
  of "Uacute": result = Rune(0x000DA)
  of "Ucirc": result = Rune(0x000DB)
  of "Uuml": result = Rune(0x000DC)
  of "Yacute": result = Rune(0x000DD)
  of "THORN": result = Rune(0x000DE)
  of "szlig": result = Rune(0x000DF)
  of "agrave": result = Rune(0x000E0)
  of "aacute": result = Rune(0x000E1)
  of "acirc": result = Rune(0x000E2)
  of "atilde": result = Rune(0x000E3)
  of "auml": result = Rune(0x000E4)
  of "aring": result = Rune(0x000E5)
  of "aelig": result = Rune(0x000E6)
  of "ccedil": result = Rune(0x000E7)
  of "egrave": result = Rune(0x000E8)
  of "eacute": result = Rune(0x000E9)
  of "ecirc": result = Rune(0x000EA)
  of "euml": result = Rune(0x000EB)
  of "igrave": result = Rune(0x000EC)
  of "iacute": result = Rune(0x000ED)
  of "icirc": result = Rune(0x000EE)
  of "iuml": result = Rune(0x000EF)
  of "eth": result = Rune(0x000F0)
  of "ntilde": result = Rune(0x000F1)
  of "ograve": result = Rune(0x000F2)
  of "oacute": result = Rune(0x000F3)
  of "ocirc": result = Rune(0x000F4)
  of "otilde": result = Rune(0x000F5)
  of "ouml": result = Rune(0x000F6)
  of "divide", "div": result = Rune(0x000F7)
  of "oslash": result = Rune(0x000F8)
  of "ugrave": result = Rune(0x000F9)
  of "uacute": result = Rune(0x000FA)
  of "ucirc": result = Rune(0x000FB)
  of "uuml": result = Rune(0x000FC)
  of "yacute": result = Rune(0x000FD)
  of "thorn": result = Rune(0x000FE)
  of "yuml": result = Rune(0x000FF)
  of "Amacr": result = Rune(0x00100)
  of "amacr": result = Rune(0x00101)
  of "Abreve": result = Rune(0x00102)
  of "abreve": result = Rune(0x00103)
  of "Aogon": result = Rune(0x00104)
  of "aogon": result = Rune(0x00105)
  of "Cacute": result = Rune(0x00106)
  of "cacute": result = Rune(0x00107)
  of "Ccirc": result = Rune(0x00108)
  of "ccirc": result = Rune(0x00109)
  of "Cdot": result = Rune(0x0010A)
  of "cdot": result = Rune(0x0010B)
  of "Ccaron": result = Rune(0x0010C)
  of "ccaron": result = Rune(0x0010D)
  of "Dcaron": result = Rune(0x0010E)
  of "dcaron": result = Rune(0x0010F)
  of "Dstrok": result = Rune(0x00110)
  of "dstrok": result = Rune(0x00111)
  of "Emacr": result = Rune(0x00112)
  of "emacr": result = Rune(0x00113)
  of "Edot": result = Rune(0x00116)
  of "edot": result = Rune(0x00117)
  of "Eogon": result = Rune(0x00118)
  of "eogon": result = Rune(0x00119)
  of "Ecaron": result = Rune(0x0011A)
  of "ecaron": result = Rune(0x0011B)
  of "Gcirc": result = Rune(0x0011C)
  of "gcirc": result = Rune(0x0011D)
  of "Gbreve": result = Rune(0x0011E)
  of "gbreve": result = Rune(0x0011F)
  of "Gdot": result = Rune(0x00120)
  of "gdot": result = Rune(0x00121)
  of "Gcedil": result = Rune(0x00122)
  of "Hcirc": result = Rune(0x00124)
  of "hcirc": result = Rune(0x00125)
  of "Hstrok": result = Rune(0x00126)
  of "hstrok": result = Rune(0x00127)
  of "Itilde": result = Rune(0x00128)
  of "itilde": result = Rune(0x00129)
  of "Imacr": result = Rune(0x0012A)
  of "imacr": result = Rune(0x0012B)
  of "Iogon": result = Rune(0x0012E)
  of "iogon": result = Rune(0x0012F)
  of "Idot": result = Rune(0x00130)
  of "imath", "inodot": result = Rune(0x00131)
  of "IJlig": result = Rune(0x00132)
  of "ijlig": result = Rune(0x00133)
  of "Jcirc": result = Rune(0x00134)
  of "jcirc": result = Rune(0x00135)
  of "Kcedil": result = Rune(0x00136)
  of "kcedil": result = Rune(0x00137)
  of "kgreen": result = Rune(0x00138)
  of "Lacute": result = Rune(0x00139)
  of "lacute": result = Rune(0x0013A)
  of "Lcedil": result = Rune(0x0013B)
  of "lcedil": result = Rune(0x0013C)
  of "Lcaron": result = Rune(0x0013D)
  of "lcaron": result = Rune(0x0013E)
  of "Lmidot": result = Rune(0x0013F)
  of "lmidot": result = Rune(0x00140)
  of "Lstrok": result = Rune(0x00141)
  of "lstrok": result = Rune(0x00142)
  of "Nacute": result = Rune(0x00143)
  of "nacute": result = Rune(0x00144)
  of "Ncedil": result = Rune(0x00145)
  of "ncedil": result = Rune(0x00146)
  of "Ncaron": result = Rune(0x00147)
  of "ncaron": result = Rune(0x00148)
  of "napos": result = Rune(0x00149)
  of "ENG": result = Rune(0x0014A)
  of "eng": result = Rune(0x0014B)
  of "Omacr": result = Rune(0x0014C)
  of "omacr": result = Rune(0x0014D)
  of "Odblac": result = Rune(0x00150)
  of "odblac": result = Rune(0x00151)
  of "OElig": result = Rune(0x00152)
  of "oelig": result = Rune(0x00153)
  of "Racute": result = Rune(0x00154)
  of "racute": result = Rune(0x00155)
  of "Rcedil": result = Rune(0x00156)
  of "rcedil": result = Rune(0x00157)
  of "Rcaron": result = Rune(0x00158)
  of "rcaron": result = Rune(0x00159)
  of "Sacute": result = Rune(0x0015A)
  of "sacute": result = Rune(0x0015B)
  of "Scirc": result = Rune(0x0015C)
  of "scirc": result = Rune(0x0015D)
  of "Scedil": result = Rune(0x0015E)
  of "scedil": result = Rune(0x0015F)
  of "Scaron": result = Rune(0x00160)
  of "scaron": result = Rune(0x00161)
  of "Tcedil": result = Rune(0x00162)
  of "tcedil": result = Rune(0x00163)
  of "Tcaron": result = Rune(0x00164)
  of "tcaron": result = Rune(0x00165)
  of "Tstrok": result = Rune(0x00166)
  of "tstrok": result = Rune(0x00167)
  of "Utilde": result = Rune(0x00168)
  of "utilde": result = Rune(0x00169)
  of "Umacr": result = Rune(0x0016A)
  of "umacr": result = Rune(0x0016B)
  of "Ubreve": result = Rune(0x0016C)
  of "ubreve": result = Rune(0x0016D)
  of "Uring": result = Rune(0x0016E)
  of "uring": result = Rune(0x0016F)
  of "Udblac": result = Rune(0x00170)
  of "udblac": result = Rune(0x00171)
  of "Uogon": result = Rune(0x00172)
  of "uogon": result = Rune(0x00173)
  of "Wcirc": result = Rune(0x00174)
  of "wcirc": result = Rune(0x00175)
  of "Ycirc": result = Rune(0x00176)
  of "ycirc": result = Rune(0x00177)
  of "Yuml": result = Rune(0x00178)
  of "Zacute": result = Rune(0x00179)
  of "zacute": result = Rune(0x0017A)
  of "Zdot": result = Rune(0x0017B)
  of "zdot": result = Rune(0x0017C)
  of "Zcaron": result = Rune(0x0017D)
  of "zcaron": result = Rune(0x0017E)
  of "fnof": result = Rune(0x00192)
  of "imped": result = Rune(0x001B5)
  of "gacute": result = Rune(0x001F5)
  of "jmath": result = Rune(0x00237)
  of "circ": result = Rune(0x002C6)
  of "caron", "Hacek": result = Rune(0x002C7)
  of "breve", "Breve": result = Rune(0x002D8)
  of "dot", "DiacriticalDot": result = Rune(0x002D9)
  of "ring": result = Rune(0x002DA)
  of "ogon": result = Rune(0x002DB)
  of "tilde", "DiacriticalTilde": result = Rune(0x002DC)
  of "dblac", "DiacriticalDoubleAcute": result = Rune(0x002DD)
  of "DownBreve": result = Rune(0x00311)
  of "UnderBar": result = Rune(0x00332)
  of "Alpha": result = Rune(0x00391)
  of "Beta": result = Rune(0x00392)
  of "Gamma": result = Rune(0x00393)
  of "Delta": result = Rune(0x00394)
  of "Epsilon": result = Rune(0x00395)
  of "Zeta": result = Rune(0x00396)
  of "Eta": result = Rune(0x00397)
  of "Theta": result = Rune(0x00398)
  of "Iota": result = Rune(0x00399)
  of "Kappa": result = Rune(0x0039A)
  of "Lambda": result = Rune(0x0039B)
  of "Mu": result = Rune(0x0039C)
  of "Nu": result = Rune(0x0039D)
  of "Xi": result = Rune(0x0039E)
  of "Omicron": result = Rune(0x0039F)
  of "Pi": result = Rune(0x003A0)
  of "Rho": result = Rune(0x003A1)
  of "Sigma": result = Rune(0x003A3)
  of "Tau": result = Rune(0x003A4)
  of "Upsilon": result = Rune(0x003A5)
  of "Phi": result = Rune(0x003A6)
  of "Chi": result = Rune(0x003A7)
  of "Psi": result = Rune(0x003A8)
  of "Omega": result = Rune(0x003A9)
  of "alpha": result = Rune(0x003B1)
  of "beta": result = Rune(0x003B2)
  of "gamma": result = Rune(0x003B3)
  of "delta": result = Rune(0x003B4)
  of "epsiv", "varepsilon", "epsilon": result = Rune(0x003B5)
  of "zeta": result = Rune(0x003B6)
  of "eta": result = Rune(0x003B7)
  of "theta": result = Rune(0x003B8)
  of "iota": result = Rune(0x003B9)
  of "kappa": result = Rune(0x003BA)
  of "lambda": result = Rune(0x003BB)
  of "mu": result = Rune(0x003BC)
  of "nu": result = Rune(0x003BD)
  of "xi": result = Rune(0x003BE)
  of "omicron": result = Rune(0x003BF)
  of "pi": result = Rune(0x003C0)
  of "rho": result = Rune(0x003C1)
  of "sigmav", "varsigma", "sigmaf": result = Rune(0x003C2)
  of "sigma": result = Rune(0x003C3)
  of "tau": result = Rune(0x003C4)
  of "upsi", "upsilon": result = Rune(0x003C5)
  of "phi", "phiv", "varphi": result = Rune(0x003C6)
  of "chi": result = Rune(0x003C7)
  of "psi": result = Rune(0x003C8)
  of "omega": result = Rune(0x003C9)
  of "thetav", "vartheta", "thetasym": result = Rune(0x003D1)
  of "Upsi", "upsih": result = Rune(0x003D2)
  of "straightphi": result = Rune(0x003D5)
  of "piv", "varpi": result = Rune(0x003D6)
  of "Gammad": result = Rune(0x003DC)
  of "gammad", "digamma": result = Rune(0x003DD)
  of "kappav", "varkappa": result = Rune(0x003F0)
  of "rhov", "varrho": result = Rune(0x003F1)
  of "epsi", "straightepsilon": result = Rune(0x003F5)
  of "bepsi", "backepsilon": result = Rune(0x003F6)
  of "IOcy": result = Rune(0x00401)
  of "DJcy": result = Rune(0x00402)
  of "GJcy": result = Rune(0x00403)
  of "Jukcy": result = Rune(0x00404)
  of "DScy": result = Rune(0x00405)
  of "Iukcy": result = Rune(0x00406)
  of "YIcy": result = Rune(0x00407)
  of "Jsercy": result = Rune(0x00408)
  of "LJcy": result = Rune(0x00409)
  of "NJcy": result = Rune(0x0040A)
  of "TSHcy": result = Rune(0x0040B)
  of "KJcy": result = Rune(0x0040C)
  of "Ubrcy": result = Rune(0x0040E)
  of "DZcy": result = Rune(0x0040F)
  of "Acy": result = Rune(0x00410)
  of "Bcy": result = Rune(0x00411)
  of "Vcy": result = Rune(0x00412)
  of "Gcy": result = Rune(0x00413)
  of "Dcy": result = Rune(0x00414)
  of "IEcy": result = Rune(0x00415)
  of "ZHcy": result = Rune(0x00416)
  of "Zcy": result = Rune(0x00417)
  of "Icy": result = Rune(0x00418)
  of "Jcy": result = Rune(0x00419)
  of "Kcy": result = Rune(0x0041A)
  of "Lcy": result = Rune(0x0041B)
  of "Mcy": result = Rune(0x0041C)
  of "Ncy": result = Rune(0x0041D)
  of "Ocy": result = Rune(0x0041E)
  of "Pcy": result = Rune(0x0041F)
  of "Rcy": result = Rune(0x00420)
  of "Scy": result = Rune(0x00421)
  of "Tcy": result = Rune(0x00422)
  of "Ucy": result = Rune(0x00423)
  of "Fcy": result = Rune(0x00424)
  of "KHcy": result = Rune(0x00425)
  of "TScy": result = Rune(0x00426)
  of "CHcy": result = Rune(0x00427)
  of "SHcy": result = Rune(0x00428)
  of "SHCHcy": result = Rune(0x00429)
  of "HARDcy": result = Rune(0x0042A)
  of "Ycy": result = Rune(0x0042B)
  of "SOFTcy": result = Rune(0x0042C)
  of "Ecy": result = Rune(0x0042D)
  of "YUcy": result = Rune(0x0042E)
  of "YAcy": result = Rune(0x0042F)
  of "acy": result = Rune(0x00430)
  of "bcy": result = Rune(0x00431)
  of "vcy": result = Rune(0x00432)
  of "gcy": result = Rune(0x00433)
  of "dcy": result = Rune(0x00434)
  of "iecy": result = Rune(0x00435)
  of "zhcy": result = Rune(0x00436)
  of "zcy": result = Rune(0x00437)
  of "icy": result = Rune(0x00438)
  of "jcy": result = Rune(0x00439)
  of "kcy": result = Rune(0x0043A)
  of "lcy": result = Rune(0x0043B)
  of "mcy": result = Rune(0x0043C)
  of "ncy": result = Rune(0x0043D)
  of "ocy": result = Rune(0x0043E)
  of "pcy": result = Rune(0x0043F)
  of "rcy": result = Rune(0x00440)
  of "scy": result = Rune(0x00441)
  of "tcy": result = Rune(0x00442)
  of "ucy": result = Rune(0x00443)
  of "fcy": result = Rune(0x00444)
  of "khcy": result = Rune(0x00445)
  of "tscy": result = Rune(0x00446)
  of "chcy": result = Rune(0x00447)
  of "shcy": result = Rune(0x00448)
  of "shchcy": result = Rune(0x00449)
  of "hardcy": result = Rune(0x0044A)
  of "ycy": result = Rune(0x0044B)
  of "softcy": result = Rune(0x0044C)
  of "ecy": result = Rune(0x0044D)
  of "yucy": result = Rune(0x0044E)
  of "yacy": result = Rune(0x0044F)
  of "iocy": result = Rune(0x00451)
  of "djcy": result = Rune(0x00452)
  of "gjcy": result = Rune(0x00453)
  of "jukcy": result = Rune(0x00454)
  of "dscy": result = Rune(0x00455)
  of "iukcy": result = Rune(0x00456)
  of "yicy": result = Rune(0x00457)
  of "jsercy": result = Rune(0x00458)
  of "ljcy": result = Rune(0x00459)
  of "njcy": result = Rune(0x0045A)
  of "tshcy": result = Rune(0x0045B)
  of "kjcy": result = Rune(0x0045C)
  of "ubrcy": result = Rune(0x0045E)
  of "dzcy": result = Rune(0x0045F)
  of "ensp": result = Rune(0x02002)
  of "emsp": result = Rune(0x02003)
  of "emsp13": result = Rune(0x02004)
  of "emsp14": result = Rune(0x02005)
  of "numsp": result = Rune(0x02007)
  of "puncsp": result = Rune(0x02008)
  of "thinsp", "ThinSpace": result = Rune(0x02009)
  of "hairsp", "VeryThinSpace": result = Rune(0x0200A)
  of "ZeroWidthSpace", "NegativeVeryThinSpace", "NegativeThinSpace",
    "NegativeMediumSpace", "NegativeThickSpace": result = Rune(0x0200B)
  of "zwnj": result = Rune(0x0200C)
  of "zwj": result = Rune(0x0200D)
  of "lrm": result = Rune(0x0200E)
  of "rlm": result = Rune(0x0200F)
  of "hyphen", "dash": result = Rune(0x02010)
  of "ndash": result = Rune(0x02013)
  of "mdash": result = Rune(0x02014)
  of "horbar": result = Rune(0x02015)
  of "Verbar", "Vert": result = Rune(0x02016)
  of "lsquo", "OpenCurlyQuote": result = Rune(0x02018)
  of "rsquo", "rsquor", "CloseCurlyQuote": result = Rune(0x02019)
  of "lsquor", "sbquo": result = Rune(0x0201A)
  of "ldquo", "OpenCurlyDoubleQuote": result = Rune(0x0201C)
  of "rdquo", "rdquor", "CloseCurlyDoubleQuote": result = Rune(0x0201D)
  of "ldquor", "bdquo": result = Rune(0x0201E)
  of "dagger": result = Rune(0x02020)
  of "Dagger", "ddagger": result = Rune(0x02021)
  of "bull", "bullet": result = Rune(0x02022)
  of "nldr": result = Rune(0x02025)
  of "hellip", "mldr": result = Rune(0x02026)
  of "permil": result = Rune(0x02030)
  of "pertenk": result = Rune(0x02031)
  of "prime": result = Rune(0x02032)
  of "Prime": result = Rune(0x02033)
  of "tprime": result = Rune(0x02034)
  of "bprime", "backprime": result = Rune(0x02035)
  of "lsaquo": result = Rune(0x02039)
  of "rsaquo": result = Rune(0x0203A)
  of "oline": result = Rune(0x0203E)
  of "caret": result = Rune(0x02041)
  of "hybull": result = Rune(0x02043)
  of "frasl": result = Rune(0x02044)
  of "bsemi": result = Rune(0x0204F)
  of "qprime": result = Rune(0x02057)
  of "MediumSpace": result = Rune(0x0205F)
  of "NoBreak": result = Rune(0x02060)
  of "ApplyFunction", "af": result = Rune(0x02061)
  of "InvisibleTimes", "it": result = Rune(0x02062)
  of "InvisibleComma", "ic": result = Rune(0x02063)
  of "euro": result = Rune(0x020AC)
  of "tdot", "TripleDot": result = Rune(0x020DB)
  of "DotDot": result = Rune(0x020DC)
  of "Copf", "complexes": result = Rune(0x02102)
  of "incare": result = Rune(0x02105)
  of "gscr": result = Rune(0x0210A)
  of "hamilt", "HilbertSpace", "Hscr": result = Rune(0x0210B)
  of "Hfr", "Poincareplane": result = Rune(0x0210C)
  of "quaternions", "Hopf": result = Rune(0x0210D)
  of "planckh": result = Rune(0x0210E)
  of "planck", "hbar", "plankv", "hslash": result = Rune(0x0210F)
  of "Iscr", "imagline": result = Rune(0x02110)
  of "image", "Im", "imagpart", "Ifr": result = Rune(0x02111)
  of "Lscr", "lagran", "Laplacetrf": result = Rune(0x02112)
  of "ell": result = Rune(0x02113)
  of "Nopf", "naturals": result = Rune(0x02115)
  of "numero": result = Rune(0x02116)
  of "copysr": result = Rune(0x02117)
  of "weierp", "wp": result = Rune(0x02118)
  of "Popf", "primes": result = Rune(0x02119)
  of "rationals", "Qopf": result = Rune(0x0211A)
  of "Rscr", "realine": result = Rune(0x0211B)
  of "real", "Re", "realpart", "Rfr": result = Rune(0x0211C)
  of "reals", "Ropf": result = Rune(0x0211D)
  of "rx": result = Rune(0x0211E)
  of "trade", "TRADE": result = Rune(0x02122)
  of "integers", "Zopf": result = Rune(0x02124)
  of "ohm": result = Rune(0x02126)
  of "mho": result = Rune(0x02127)
  of "Zfr", "zeetrf": result = Rune(0x02128)
  of "iiota": result = Rune(0x02129)
  of "angst": result = Rune(0x0212B)
  of "bernou", "Bernoullis", "Bscr": result = Rune(0x0212C)
  of "Cfr", "Cayleys": result = Rune(0x0212D)
  of "escr": result = Rune(0x0212F)
  of "Escr", "expectation": result = Rune(0x02130)
  of "Fscr", "Fouriertrf": result = Rune(0x02131)
  of "phmmat", "Mellintrf", "Mscr": result = Rune(0x02133)
  of "order", "orderof", "oscr": result = Rune(0x02134)
  of "alefsym", "aleph": result = Rune(0x02135)
  of "beth": result = Rune(0x02136)
  of "gimel": result = Rune(0x02137)
  of "daleth": result = Rune(0x02138)
  of "CapitalDifferentialD", "DD": result = Rune(0x02145)
  of "DifferentialD", "dd": result = Rune(0x02146)
  of "ExponentialE", "exponentiale", "ee": result = Rune(0x02147)
  of "ImaginaryI", "ii": result = Rune(0x02148)
  of "frac13": result = Rune(0x02153)
  of "frac23": result = Rune(0x02154)
  of "frac15": result = Rune(0x02155)
  of "frac25": result = Rune(0x02156)
  of "frac35": result = Rune(0x02157)
  of "frac45": result = Rune(0x02158)
  of "frac16": result = Rune(0x02159)
  of "frac56": result = Rune(0x0215A)
  of "frac18": result = Rune(0x0215B)
  of "frac38": result = Rune(0x0215C)
  of "frac58": result = Rune(0x0215D)
  of "frac78": result = Rune(0x0215E)
  of "larr", "leftarrow", "LeftArrow", "slarr",
    "ShortLeftArrow": result = Rune(0x02190)
  of "uarr", "uparrow", "UpArrow", "ShortUpArrow": result = Rune(0x02191)
  of "rarr", "rightarrow", "RightArrow", "srarr",
    "ShortRightArrow": result = Rune(0x02192)
  of "darr", "downarrow", "DownArrow",
    "ShortDownArrow": result = Rune(0x02193)
  of "harr", "leftrightarrow", "LeftRightArrow": result = Rune(0x02194)
  of "varr", "updownarrow", "UpDownArrow": result = Rune(0x02195)
  of "nwarr", "UpperLeftArrow", "nwarrow": result = Rune(0x02196)
  of "nearr", "UpperRightArrow", "nearrow": result = Rune(0x02197)
  of "searr", "searrow", "LowerRightArrow": result = Rune(0x02198)
  of "swarr", "swarrow", "LowerLeftArrow": result = Rune(0x02199)
  of "nlarr", "nleftarrow": result = Rune(0x0219A)
  of "nrarr", "nrightarrow": result = Rune(0x0219B)
  of "rarrw", "rightsquigarrow": result = Rune(0x0219D)
  of "Larr", "twoheadleftarrow": result = Rune(0x0219E)
  of "Uarr": result = Rune(0x0219F)
  of "Rarr", "twoheadrightarrow": result = Rune(0x021A0)
  of "Darr": result = Rune(0x021A1)
  of "larrtl", "leftarrowtail": result = Rune(0x021A2)
  of "rarrtl", "rightarrowtail": result = Rune(0x021A3)
  of "LeftTeeArrow", "mapstoleft": result = Rune(0x021A4)
  of "UpTeeArrow", "mapstoup": result = Rune(0x021A5)
  of "map", "RightTeeArrow", "mapsto": result = Rune(0x021A6)
  of "DownTeeArrow", "mapstodown": result = Rune(0x021A7)
  of "larrhk", "hookleftarrow": result = Rune(0x021A9)
  of "rarrhk", "hookrightarrow": result = Rune(0x021AA)
  of "larrlp", "looparrowleft": result = Rune(0x021AB)
  of "rarrlp", "looparrowright": result = Rune(0x021AC)
  of "harrw", "leftrightsquigarrow": result = Rune(0x021AD)
  of "nharr", "nleftrightarrow": result = Rune(0x021AE)
  of "lsh", "Lsh": result = Rune(0x021B0)
  of "rsh", "Rsh": result = Rune(0x021B1)
  of "ldsh": result = Rune(0x021B2)
  of "rdsh": result = Rune(0x021B3)
  of "crarr": result = Rune(0x021B5)
  of "cularr", "curvearrowleft": result = Rune(0x021B6)
  of "curarr", "curvearrowright": result = Rune(0x021B7)
  of "olarr", "circlearrowleft": result = Rune(0x021BA)
  of "orarr", "circlearrowright": result = Rune(0x021BB)
  of "lharu", "LeftVector", "leftharpoonup": result = Rune(0x021BC)
  of "lhard", "leftharpoondown", "DownLeftVector": result = Rune(0x021BD)
  of "uharr", "upharpoonright", "RightUpVector": result = Rune(0x021BE)
  of "uharl", "upharpoonleft", "LeftUpVector": result = Rune(0x021BF)
  of "rharu", "RightVector", "rightharpoonup": result = Rune(0x021C0)
  of "rhard", "rightharpoondown", "DownRightVector": result = Rune(0x021C1)
  of "dharr", "RightDownVector", "downharpoonright": result = Rune(0x021C2)
  of "dharl", "LeftDownVector", "downharpoonleft": result = Rune(0x021C3)
  of "rlarr", "rightleftarrows", "RightArrowLeftArrow": result = Rune(0x021C4)
  of "udarr", "UpArrowDownArrow": result = Rune(0x021C5)
  of "lrarr", "leftrightarrows", "LeftArrowRightArrow": result = Rune(0x021C6)
  of "llarr", "leftleftarrows": result = Rune(0x021C7)
  of "uuarr", "upuparrows": result = Rune(0x021C8)
  of "rrarr", "rightrightarrows": result = Rune(0x021C9)
  of "ddarr", "downdownarrows": result = Rune(0x021CA)
  of "lrhar", "ReverseEquilibrium",
    "leftrightharpoons": result = Rune(0x021CB)
  of "rlhar", "rightleftharpoons", "Equilibrium": result = Rune(0x021CC)
  of "nlArr", "nLeftarrow": result = Rune(0x021CD)
  of "nhArr", "nLeftrightarrow": result = Rune(0x021CE)
  of "nrArr", "nRightarrow": result = Rune(0x021CF)
  of "lArr", "Leftarrow", "DoubleLeftArrow": result = Rune(0x021D0)
  of "uArr", "Uparrow", "DoubleUpArrow": result = Rune(0x021D1)
  of "rArr", "Rightarrow", "Implies",
    "DoubleRightArrow": result = Rune(0x021D2)
  of "dArr", "Downarrow", "DoubleDownArrow": result = Rune(0x021D3)
  of "hArr", "Leftrightarrow", "DoubleLeftRightArrow",
    "iff": result = Rune(0x021D4)
  of "vArr", "Updownarrow", "DoubleUpDownArrow": result = Rune(0x021D5)
  of "nwArr": result = Rune(0x021D6)
  of "neArr": result = Rune(0x021D7)
  of "seArr": result = Rune(0x021D8)
  of "swArr": result = Rune(0x021D9)
  of "lAarr", "Lleftarrow": result = Rune(0x021DA)
  of "rAarr", "Rrightarrow": result = Rune(0x021DB)
  of "zigrarr": result = Rune(0x021DD)
  of "larrb", "LeftArrowBar": result = Rune(0x021E4)
  of "rarrb", "RightArrowBar": result = Rune(0x021E5)
  of "duarr", "DownArrowUpArrow": result = Rune(0x021F5)
  of "loarr": result = Rune(0x021FD)
  of "roarr": result = Rune(0x021FE)
  of "hoarr": result = Rune(0x021FF)
  of "forall", "ForAll": result = Rune(0x02200)
  of "comp", "complement": result = Rune(0x02201)
  of "part", "PartialD": result = Rune(0x02202)
  of "exist", "Exists": result = Rune(0x02203)
  of "nexist", "NotExists", "nexists": result = Rune(0x02204)
  of "empty", "emptyset", "emptyv", "varnothing": result = Rune(0x02205)
  of "nabla", "Del": result = Rune(0x02207)
  of "isin", "isinv", "Element", "in": result = Rune(0x02208)
  of "notin", "NotElement", "notinva": result = Rune(0x02209)
  of "niv", "ReverseElement", "ni", "SuchThat": result = Rune(0x0220B)
  of "notni", "notniva", "NotReverseElement": result = Rune(0x0220C)
  of "prod", "Product": result = Rune(0x0220F)
  of "coprod", "Coproduct": result = Rune(0x02210)
  of "sum", "Sum": result = Rune(0x02211)
  of "minus": result = Rune(0x02212)
  of "mnplus", "mp", "MinusPlus": result = Rune(0x02213)
  of "plusdo", "dotplus": result = Rune(0x02214)
  of "setmn", "setminus", "Backslash", "ssetmn",
    "smallsetminus": result = Rune(0x02216)
  of "lowast": result = Rune(0x02217)
  of "compfn", "SmallCircle": result = Rune(0x02218)
  of "radic", "Sqrt": result = Rune(0x0221A)
  of "prop", "propto", "Proportional", "vprop",
    "varpropto": result = Rune(0x0221D)
  of "infin": result = Rune(0x0221E)
  of "angrt": result = Rune(0x0221F)
  of "ang", "angle": result = Rune(0x02220)
  of "angmsd", "measuredangle": result = Rune(0x02221)
  of "angsph": result = Rune(0x02222)
  of "mid", "VerticalBar", "smid", "shortmid": result = Rune(0x02223)
  of "nmid", "NotVerticalBar", "nsmid", "nshortmid": result = Rune(0x02224)
  of "par", "parallel", "DoubleVerticalBar", "spar",
    "shortparallel": result = Rune(0x02225)
  of "npar", "nparallel", "NotDoubleVerticalBar", "nspar",
    "nshortparallel": result = Rune(0x02226)
  of "and", "wedge": result = Rune(0x02227)
  of "or", "vee": result = Rune(0x02228)
  of "cap": result = Rune(0x02229)
  of "cup": result = Rune(0x0222A)
  of "int", "Integral": result = Rune(0x0222B)
  of "Int": result = Rune(0x0222C)
  of "tint", "iiint": result = Rune(0x0222D)
  of "conint", "oint", "ContourIntegral": result = Rune(0x0222E)
  of "Conint", "DoubleContourIntegral": result = Rune(0x0222F)
  of "Cconint": result = Rune(0x02230)
  of "cwint": result = Rune(0x02231)
  of "cwconint", "ClockwiseContourIntegral": result = Rune(0x02232)
  of "awconint", "CounterClockwiseContourIntegral": result = Rune(0x02233)
  of "there4", "therefore", "Therefore": result = Rune(0x02234)
  of "becaus", "because", "Because": result = Rune(0x02235)
  of "ratio": result = Rune(0x02236)
  of "Colon", "Proportion": result = Rune(0x02237)
  of "minusd", "dotminus": result = Rune(0x02238)
  of "mDDot": result = Rune(0x0223A)
  of "homtht": result = Rune(0x0223B)
  of "sim", "Tilde", "thksim", "thicksim": result = Rune(0x0223C)
  of "bsim", "backsim": result = Rune(0x0223D)
  of "ac", "mstpos": result = Rune(0x0223E)
  of "acd": result = Rune(0x0223F)
  of "wreath", "VerticalTilde", "wr": result = Rune(0x02240)
  of "nsim", "NotTilde": result = Rune(0x02241)
  of "esim", "EqualTilde", "eqsim": result = Rune(0x02242)
  of "sime", "TildeEqual", "simeq": result = Rune(0x02243)
  of "nsime", "nsimeq", "NotTildeEqual": result = Rune(0x02244)
  of "cong", "TildeFullEqual": result = Rune(0x02245)
  of "simne": result = Rune(0x02246)
  of "ncong", "NotTildeFullEqual": result = Rune(0x02247)
  of "asymp", "ap", "TildeTilde", "approx", "thkap",
    "thickapprox": result = Rune(0x02248)
  of "nap", "NotTildeTilde", "napprox": result = Rune(0x02249)
  of "ape", "approxeq": result = Rune(0x0224A)
  of "apid": result = Rune(0x0224B)
  of "bcong", "backcong": result = Rune(0x0224C)
  of "asympeq", "CupCap": result = Rune(0x0224D)
  of "bump", "HumpDownHump", "Bumpeq": result = Rune(0x0224E)
  of "bumpe", "HumpEqual", "bumpeq": result = Rune(0x0224F)
  of "esdot", "DotEqual", "doteq": result = Rune(0x02250)
  of "eDot", "doteqdot": result = Rune(0x02251)
  of "efDot", "fallingdotseq": result = Rune(0x02252)
  of "erDot", "risingdotseq": result = Rune(0x02253)
  of "colone", "coloneq", "Assign": result = Rune(0x02254)
  of "ecolon", "eqcolon": result = Rune(0x02255)
  of "ecir", "eqcirc": result = Rune(0x02256)
  of "cire", "circeq": result = Rune(0x02257)
  of "wedgeq": result = Rune(0x02259)
  of "veeeq": result = Rune(0x0225A)
  of "trie", "triangleq": result = Rune(0x0225C)
  of "equest", "questeq": result = Rune(0x0225F)
  of "ne", "NotEqual": result = Rune(0x02260)
  of "equiv", "Congruent": result = Rune(0x02261)
  of "nequiv", "NotCongruent": result = Rune(0x02262)
  of "le", "leq": result = Rune(0x02264)
  of "ge", "GreaterEqual", "geq": result = Rune(0x02265)
  of "lE", "LessFullEqual", "leqq": result = Rune(0x02266)
  of "gE", "GreaterFullEqual", "geqq": result = Rune(0x02267)
  of "lnE", "lneqq": result = Rune(0x02268)
  of "gnE", "gneqq": result = Rune(0x02269)
  of "Lt", "NestedLessLess", "ll": result = Rune(0x0226A)
  of "Gt", "NestedGreaterGreater", "gg": result = Rune(0x0226B)
  of "twixt", "between": result = Rune(0x0226C)
  of "NotCupCap": result = Rune(0x0226D)
  of "nlt", "NotLess", "nless": result = Rune(0x0226E)
  of "ngt", "NotGreater", "ngtr": result = Rune(0x0226F)
  of "nle", "NotLessEqual", "nleq": result = Rune(0x02270)
  of "nge", "NotGreaterEqual", "ngeq": result = Rune(0x02271)
  of "lsim", "LessTilde", "lesssim": result = Rune(0x02272)
  of "gsim", "gtrsim", "GreaterTilde": result = Rune(0x02273)
  of "nlsim", "NotLessTilde": result = Rune(0x02274)
  of "ngsim", "NotGreaterTilde": result = Rune(0x02275)
  of "lg", "lessgtr", "LessGreater": result = Rune(0x02276)
  of "gl", "gtrless", "GreaterLess": result = Rune(0x02277)
  of "ntlg", "NotLessGreater": result = Rune(0x02278)
  of "ntgl", "NotGreaterLess": result = Rune(0x02279)
  of "pr", "Precedes", "prec": result = Rune(0x0227A)
  of "sc", "Succeeds", "succ": result = Rune(0x0227B)
  of "prcue", "PrecedesSlantEqual", "preccurlyeq": result = Rune(0x0227C)
  of "sccue", "SucceedsSlantEqual", "succcurlyeq": result = Rune(0x0227D)
  of "prsim", "precsim", "PrecedesTilde": result = Rune(0x0227E)
  of "scsim", "succsim", "SucceedsTilde": result = Rune(0x0227F)
  of "npr", "nprec", "NotPrecedes": result = Rune(0x02280)
  of "nsc", "nsucc", "NotSucceeds": result = Rune(0x02281)
  of "sub", "subset": result = Rune(0x02282)
  of "sup", "supset", "Superset": result = Rune(0x02283)
  of "nsub": result = Rune(0x02284)
  of "nsup": result = Rune(0x02285)
  of "sube", "SubsetEqual", "subseteq": result = Rune(0x02286)
  of "supe", "supseteq", "SupersetEqual": result = Rune(0x02287)
  of "nsube", "nsubseteq", "NotSubsetEqual": result = Rune(0x02288)
  of "nsupe", "nsupseteq", "NotSupersetEqual": result = Rune(0x02289)
  of "subne", "subsetneq": result = Rune(0x0228A)
  of "supne", "supsetneq": result = Rune(0x0228B)
  of "cupdot": result = Rune(0x0228D)
  of "uplus", "UnionPlus": result = Rune(0x0228E)
  of "sqsub", "SquareSubset", "sqsubset": result = Rune(0x0228F)
  of "sqsup", "SquareSuperset", "sqsupset": result = Rune(0x02290)
  of "sqsube", "SquareSubsetEqual", "sqsubseteq": result = Rune(0x02291)
  of "sqsupe", "SquareSupersetEqual", "sqsupseteq": result = Rune(0x02292)
  of "sqcap", "SquareIntersection": result = Rune(0x02293)
  of "sqcup", "SquareUnion": result = Rune(0x02294)
  of "oplus", "CirclePlus": result = Rune(0x02295)
  of "ominus", "CircleMinus": result = Rune(0x02296)
  of "otimes", "CircleTimes": result = Rune(0x02297)
  of "osol": result = Rune(0x02298)
  of "odot", "CircleDot": result = Rune(0x02299)
  of "ocir", "circledcirc": result = Rune(0x0229A)
  of "oast", "circledast": result = Rune(0x0229B)
  of "odash", "circleddash": result = Rune(0x0229D)
  of "plusb", "boxplus": result = Rune(0x0229E)
  of "minusb", "boxminus": result = Rune(0x0229F)
  of "timesb", "boxtimes": result = Rune(0x022A0)
  of "sdotb", "dotsquare": result = Rune(0x022A1)
  of "vdash", "RightTee": result = Rune(0x022A2)
  of "dashv", "LeftTee": result = Rune(0x022A3)
  of "top", "DownTee": result = Rune(0x022A4)
  of "bottom", "bot", "perp", "UpTee": result = Rune(0x022A5)
  of "models": result = Rune(0x022A7)
  of "vDash", "DoubleRightTee": result = Rune(0x022A8)
  of "Vdash": result = Rune(0x022A9)
  of "Vvdash": result = Rune(0x022AA)
  of "VDash": result = Rune(0x022AB)
  of "nvdash": result = Rune(0x022AC)
  of "nvDash": result = Rune(0x022AD)
  of "nVdash": result = Rune(0x022AE)
  of "nVDash": result = Rune(0x022AF)
  of "prurel": result = Rune(0x022B0)
  of "vltri", "vartriangleleft", "LeftTriangle": result = Rune(0x022B2)
  of "vrtri", "vartriangleright", "RightTriangle": result = Rune(0x022B3)
  of "ltrie", "trianglelefteq", "LeftTriangleEqual": result = Rune(0x022B4)
  of "rtrie", "trianglerighteq", "RightTriangleEqual": result = Rune(0x022B5)
  of "origof": result = Rune(0x022B6)
  of "imof": result = Rune(0x022B7)
  of "mumap", "multimap": result = Rune(0x022B8)
  of "hercon": result = Rune(0x022B9)
  of "intcal", "intercal": result = Rune(0x022BA)
  of "veebar": result = Rune(0x022BB)
  of "barvee": result = Rune(0x022BD)
  of "angrtvb": result = Rune(0x022BE)
  of "lrtri": result = Rune(0x022BF)
  of "xwedge", "Wedge", "bigwedge": result = Rune(0x022C0)
  of "xvee", "Vee", "bigvee": result = Rune(0x022C1)
  of "xcap", "Intersection", "bigcap": result = Rune(0x022C2)
  of "xcup", "Union", "bigcup": result = Rune(0x022C3)
  of "diam", "diamond", "Diamond": result = Rune(0x022C4)
  of "sdot": result = Rune(0x022C5)
  of "sstarf", "Star": result = Rune(0x022C6)
  of "divonx", "divideontimes": result = Rune(0x022C7)
  of "bowtie": result = Rune(0x022C8)
  of "ltimes": result = Rune(0x022C9)
  of "rtimes": result = Rune(0x022CA)
  of "lthree", "leftthreetimes": result = Rune(0x022CB)
  of "rthree", "rightthreetimes": result = Rune(0x022CC)
  of "bsime", "backsimeq": result = Rune(0x022CD)
  of "cuvee", "curlyvee": result = Rune(0x022CE)
  of "cuwed", "curlywedge": result = Rune(0x022CF)
  of "Sub", "Subset": result = Rune(0x022D0)
  of "Sup", "Supset": result = Rune(0x022D1)
  of "Cap": result = Rune(0x022D2)
  of "Cup": result = Rune(0x022D3)
  of "fork", "pitchfork": result = Rune(0x022D4)
  of "epar": result = Rune(0x022D5)
  of "ltdot", "lessdot": result = Rune(0x022D6)
  of "gtdot", "gtrdot": result = Rune(0x022D7)
  of "Ll": result = Rune(0x022D8)
  of "Gg", "ggg": result = Rune(0x022D9)
  of "leg", "LessEqualGreater", "lesseqgtr": result = Rune(0x022DA)
  of "gel", "gtreqless", "GreaterEqualLess": result = Rune(0x022DB)
  of "cuepr", "curlyeqprec": result = Rune(0x022DE)
  of "cuesc", "curlyeqsucc": result = Rune(0x022DF)
  of "nprcue", "NotPrecedesSlantEqual": result = Rune(0x022E0)
  of "nsccue", "NotSucceedsSlantEqual": result = Rune(0x022E1)
  of "nsqsube", "NotSquareSubsetEqual": result = Rune(0x022E2)
  of "nsqsupe", "NotSquareSupersetEqual": result = Rune(0x022E3)
  of "lnsim": result = Rune(0x022E6)
  of "gnsim": result = Rune(0x022E7)
  of "prnsim", "precnsim": result = Rune(0x022E8)
  of "scnsim", "succnsim": result = Rune(0x022E9)
  of "nltri", "ntriangleleft", "NotLeftTriangle": result = Rune(0x022EA)
  of "nrtri", "ntriangleright", "NotRightTriangle": result = Rune(0x022EB)
  of "nltrie", "ntrianglelefteq",
    "NotLeftTriangleEqual": result = Rune(0x022EC)
  of "nrtrie", "ntrianglerighteq",
    "NotRightTriangleEqual": result = Rune(0x022ED)
  of "vellip": result = Rune(0x022EE)
  of "ctdot": result = Rune(0x022EF)
  of "utdot": result = Rune(0x022F0)
  of "dtdot": result = Rune(0x022F1)
  of "disin": result = Rune(0x022F2)
  of "isinsv": result = Rune(0x022F3)
  of "isins": result = Rune(0x022F4)
  of "isindot": result = Rune(0x022F5)
  of "notinvc": result = Rune(0x022F6)
  of "notinvb": result = Rune(0x022F7)
  of "isinE": result = Rune(0x022F9)
  of "nisd": result = Rune(0x022FA)
  of "xnis": result = Rune(0x022FB)
  of "nis": result = Rune(0x022FC)
  of "notnivc": result = Rune(0x022FD)
  of "notnivb": result = Rune(0x022FE)
  of "barwed", "barwedge": result = Rune(0x02305)
  of "Barwed", "doublebarwedge": result = Rune(0x02306)
  of "lceil", "LeftCeiling": result = Rune(0x02308)
  of "rceil", "RightCeiling": result = Rune(0x02309)
  of "lfloor", "LeftFloor": result = Rune(0x0230A)
  of "rfloor", "RightFloor": result = Rune(0x0230B)
  of "drcrop": result = Rune(0x0230C)
  of "dlcrop": result = Rune(0x0230D)
  of "urcrop": result = Rune(0x0230E)
  of "ulcrop": result = Rune(0x0230F)
  of "bnot": result = Rune(0x02310)
  of "profline": result = Rune(0x02312)
  of "profsurf": result = Rune(0x02313)
  of "telrec": result = Rune(0x02315)
  of "target": result = Rune(0x02316)
  of "ulcorn", "ulcorner": result = Rune(0x0231C)
  of "urcorn", "urcorner": result = Rune(0x0231D)
  of "dlcorn", "llcorner": result = Rune(0x0231E)
  of "drcorn", "lrcorner": result = Rune(0x0231F)
  of "frown", "sfrown": result = Rune(0x02322)
  of "smile", "ssmile": result = Rune(0x02323)
  of "cylcty": result = Rune(0x0232D)
  of "profalar": result = Rune(0x0232E)
  of "topbot": result = Rune(0x02336)
  of "ovbar": result = Rune(0x0233D)
  of "solbar": result = Rune(0x0233F)
  of "angzarr": result = Rune(0x0237C)
  of "lmoust", "lmoustache": result = Rune(0x023B0)
  of "rmoust", "rmoustache": result = Rune(0x023B1)
  of "tbrk", "OverBracket": result = Rune(0x023B4)
  of "bbrk", "UnderBracket": result = Rune(0x023B5)
  of "bbrktbrk": result = Rune(0x023B6)
  of "OverParenthesis": result = Rune(0x023DC)
  of "UnderParenthesis": result = Rune(0x023DD)
  of "OverBrace": result = Rune(0x023DE)
  of "UnderBrace": result = Rune(0x023DF)
  of "trpezium": result = Rune(0x023E2)
  of "elinters": result = Rune(0x023E7)
  of "blank": result = Rune(0x02423)
  of "oS", "circledS": result = Rune(0x024C8)
  of "boxh", "HorizontalLine": result = Rune(0x02500)
  of "boxv": result = Rune(0x02502)
  of "boxdr": result = Rune(0x0250C)
  of "boxdl": result = Rune(0x02510)
  of "boxur": result = Rune(0x02514)
  of "boxul": result = Rune(0x02518)
  of "boxvr": result = Rune(0x0251C)
  of "boxvl": result = Rune(0x02524)
  of "boxhd": result = Rune(0x0252C)
  of "boxhu": result = Rune(0x02534)
  of "boxvh": result = Rune(0x0253C)
  of "boxH": result = Rune(0x02550)
  of "boxV": result = Rune(0x02551)
  of "boxdR": result = Rune(0x02552)
  of "boxDr": result = Rune(0x02553)
  of "boxDR": result = Rune(0x02554)
  of "boxdL": result = Rune(0x02555)
  of "boxDl": result = Rune(0x02556)
  of "boxDL": result = Rune(0x02557)
  of "boxuR": result = Rune(0x02558)
  of "boxUr": result = Rune(0x02559)
  of "boxUR": result = Rune(0x0255A)
  of "boxuL": result = Rune(0x0255B)
  of "boxUl": result = Rune(0x0255C)
  of "boxUL": result = Rune(0x0255D)
  of "boxvR": result = Rune(0x0255E)
  of "boxVr": result = Rune(0x0255F)
  of "boxVR": result = Rune(0x02560)
  of "boxvL": result = Rune(0x02561)
  of "boxVl": result = Rune(0x02562)
  of "boxVL": result = Rune(0x02563)
  of "boxHd": result = Rune(0x02564)
  of "boxhD": result = Rune(0x02565)
  of "boxHD": result = Rune(0x02566)
  of "boxHu": result = Rune(0x02567)
  of "boxhU": result = Rune(0x02568)
  of "boxHU": result = Rune(0x02569)
  of "boxvH": result = Rune(0x0256A)
  of "boxVh": result = Rune(0x0256B)
  of "boxVH": result = Rune(0x0256C)
  of "uhblk": result = Rune(0x02580)
  of "lhblk": result = Rune(0x02584)
  of "block": result = Rune(0x02588)
  of "blk14": result = Rune(0x02591)
  of "blk12": result = Rune(0x02592)
  of "blk34": result = Rune(0x02593)
  of "squ", "square", "Square": result = Rune(0x025A1)
  of "squf", "squarf", "blacksquare",
    "FilledVerySmallSquare": result = Rune(0x025AA)
  of "EmptyVerySmallSquare": result = Rune(0x025AB)
  of "rect": result = Rune(0x025AD)
  of "marker": result = Rune(0x025AE)
  of "fltns": result = Rune(0x025B1)
  of "xutri", "bigtriangleup": result = Rune(0x025B3)
  of "utrif", "blacktriangle": result = Rune(0x025B4)
  of "utri", "triangle": result = Rune(0x025B5)
  of "rtrif", "blacktriangleright": result = Rune(0x025B8)
  of "rtri", "triangleright": result = Rune(0x025B9)
  of "xdtri", "bigtriangledown": result = Rune(0x025BD)
  of "dtrif", "blacktriangledown": result = Rune(0x025BE)
  of "dtri", "triangledown": result = Rune(0x025BF)
  of "ltrif", "blacktriangleleft": result = Rune(0x025C2)
  of "ltri", "triangleleft": result = Rune(0x025C3)
  of "loz", "lozenge": result = Rune(0x025CA)
  of "cir": result = Rune(0x025CB)
  of "tridot": result = Rune(0x025EC)
  of "xcirc", "bigcirc": result = Rune(0x025EF)
  of "ultri": result = Rune(0x025F8)
  of "urtri": result = Rune(0x025F9)
  of "lltri": result = Rune(0x025FA)
  of "EmptySmallSquare": result = Rune(0x025FB)
  of "FilledSmallSquare": result = Rune(0x025FC)
  of "starf", "bigstar": result = Rune(0x02605)
  of "star": result = Rune(0x02606)
  of "phone": result = Rune(0x0260E)
  of "female": result = Rune(0x02640)
  of "male": result = Rune(0x02642)
  of "spades", "spadesuit": result = Rune(0x02660)
  of "clubs", "clubsuit": result = Rune(0x02663)
  of "hearts", "heartsuit": result = Rune(0x02665)
  of "diams", "diamondsuit": result = Rune(0x02666)
  of "sung": result = Rune(0x0266A)
  of "flat": result = Rune(0x0266D)
  of "natur", "natural": result = Rune(0x0266E)
  of "sharp": result = Rune(0x0266F)
  of "check", "checkmark": result = Rune(0x02713)
  of "cross": result = Rune(0x02717)
  of "malt", "maltese": result = Rune(0x02720)
  of "sext": result = Rune(0x02736)
  of "VerticalSeparator": result = Rune(0x02758)
  of "lbbrk": result = Rune(0x02772)
  of "rbbrk": result = Rune(0x02773)
  of "lobrk", "LeftDoubleBracket": result = Rune(0x027E6)
  of "robrk", "RightDoubleBracket": result = Rune(0x027E7)
  of "lang", "LeftAngleBracket", "langle": result = Rune(0x027E8)
  of "rang", "RightAngleBracket", "rangle": result = Rune(0x027E9)
  of "Lang": result = Rune(0x027EA)
  of "Rang": result = Rune(0x027EB)
  of "loang": result = Rune(0x027EC)
  of "roang": result = Rune(0x027ED)
  of "xlarr", "longleftarrow", "LongLeftArrow": result = Rune(0x027F5)
  of "xrarr", "longrightarrow", "LongRightArrow": result = Rune(0x027F6)
  of "xharr", "longleftrightarrow",
    "LongLeftRightArrow": result = Rune(0x027F7)
  of "xlArr", "Longleftarrow", "DoubleLongLeftArrow": result = Rune(0x027F8)
  of "xrArr", "Longrightarrow", "DoubleLongRightArrow": result = Rune(0x027F9)
  of "xhArr", "Longleftrightarrow",
    "DoubleLongLeftRightArrow": result = Rune(0x027FA)
  of "xmap", "longmapsto": result = Rune(0x027FC)
  of "dzigrarr": result = Rune(0x027FF)
  of "nvlArr": result = Rune(0x02902)
  of "nvrArr": result = Rune(0x02903)
  of "nvHarr": result = Rune(0x02904)
  of "Map": result = Rune(0x02905)
  of "lbarr": result = Rune(0x0290C)
  of "rbarr", "bkarow": result = Rune(0x0290D)
  of "lBarr": result = Rune(0x0290E)
  of "rBarr", "dbkarow": result = Rune(0x0290F)
  of "RBarr", "drbkarow": result = Rune(0x02910)
  of "DDotrahd": result = Rune(0x02911)
  of "UpArrowBar": result = Rune(0x02912)
  of "DownArrowBar": result = Rune(0x02913)
  of "Rarrtl": result = Rune(0x02916)
  of "latail": result = Rune(0x02919)
  of "ratail": result = Rune(0x0291A)
  of "lAtail": result = Rune(0x0291B)
  of "rAtail": result = Rune(0x0291C)
  of "larrfs": result = Rune(0x0291D)
  of "rarrfs": result = Rune(0x0291E)
  of "larrbfs": result = Rune(0x0291F)
  of "rarrbfs": result = Rune(0x02920)
  of "nwarhk": result = Rune(0x02923)
  of "nearhk": result = Rune(0x02924)
  of "searhk", "hksearow": result = Rune(0x02925)
  of "swarhk", "hkswarow": result = Rune(0x02926)
  of "nwnear": result = Rune(0x02927)
  of "nesear", "toea": result = Rune(0x02928)
  of "seswar", "tosa": result = Rune(0x02929)
  of "swnwar": result = Rune(0x0292A)
  of "rarrc": result = Rune(0x02933)
  of "cudarrr": result = Rune(0x02935)
  of "ldca": result = Rune(0x02936)
  of "rdca": result = Rune(0x02937)
  of "cudarrl": result = Rune(0x02938)
  of "larrpl": result = Rune(0x02939)
  of "curarrm": result = Rune(0x0293C)
  of "cularrp": result = Rune(0x0293D)
  of "rarrpl": result = Rune(0x02945)
  of "harrcir": result = Rune(0x02948)
  of "Uarrocir": result = Rune(0x02949)
  of "lurdshar": result = Rune(0x0294A)
  of "ldrushar": result = Rune(0x0294B)
  of "LeftRightVector": result = Rune(0x0294E)
  of "RightUpDownVector": result = Rune(0x0294F)
  of "DownLeftRightVector": result = Rune(0x02950)
  of "LeftUpDownVector": result = Rune(0x02951)
  of "LeftVectorBar": result = Rune(0x02952)
  of "RightVectorBar": result = Rune(0x02953)
  of "RightUpVectorBar": result = Rune(0x02954)
  of "RightDownVectorBar": result = Rune(0x02955)
  of "DownLeftVectorBar": result = Rune(0x02956)
  of "DownRightVectorBar": result = Rune(0x02957)
  of "LeftUpVectorBar": result = Rune(0x02958)
  of "LeftDownVectorBar": result = Rune(0x02959)
  of "LeftTeeVector": result = Rune(0x0295A)
  of "RightTeeVector": result = Rune(0x0295B)
  of "RightUpTeeVector": result = Rune(0x0295C)
  of "RightDownTeeVector": result = Rune(0x0295D)
  of "DownLeftTeeVector": result = Rune(0x0295E)
  of "DownRightTeeVector": result = Rune(0x0295F)
  of "LeftUpTeeVector": result = Rune(0x02960)
  of "LeftDownTeeVector": result = Rune(0x02961)
  of "lHar": result = Rune(0x02962)
  of "uHar": result = Rune(0x02963)
  of "rHar": result = Rune(0x02964)
  of "dHar": result = Rune(0x02965)
  of "luruhar": result = Rune(0x02966)
  of "ldrdhar": result = Rune(0x02967)
  of "ruluhar": result = Rune(0x02968)
  of "rdldhar": result = Rune(0x02969)
  of "lharul": result = Rune(0x0296A)
  of "llhard": result = Rune(0x0296B)
  of "rharul": result = Rune(0x0296C)
  of "lrhard": result = Rune(0x0296D)
  of "udhar", "UpEquilibrium": result = Rune(0x0296E)
  of "duhar", "ReverseUpEquilibrium": result = Rune(0x0296F)
  of "RoundImplies": result = Rune(0x02970)
  of "erarr": result = Rune(0x02971)
  of "simrarr": result = Rune(0x02972)
  of "larrsim": result = Rune(0x02973)
  of "rarrsim": result = Rune(0x02974)
  of "rarrap": result = Rune(0x02975)
  of "ltlarr": result = Rune(0x02976)
  of "gtrarr": result = Rune(0x02978)
  of "subrarr": result = Rune(0x02979)
  of "suplarr": result = Rune(0x0297B)
  of "lfisht": result = Rune(0x0297C)
  of "rfisht": result = Rune(0x0297D)
  of "ufisht": result = Rune(0x0297E)
  of "dfisht": result = Rune(0x0297F)
  of "lopar": result = Rune(0x02985)
  of "ropar": result = Rune(0x02986)
  of "lbrke": result = Rune(0x0298B)
  of "rbrke": result = Rune(0x0298C)
  of "lbrkslu": result = Rune(0x0298D)
  of "rbrksld": result = Rune(0x0298E)
  of "lbrksld": result = Rune(0x0298F)
  of "rbrkslu": result = Rune(0x02990)
  of "langd": result = Rune(0x02991)
  of "rangd": result = Rune(0x02992)
  of "lparlt": result = Rune(0x02993)
  of "rpargt": result = Rune(0x02994)
  of "gtlPar": result = Rune(0x02995)
  of "ltrPar": result = Rune(0x02996)
  of "vzigzag": result = Rune(0x0299A)
  of "vangrt": result = Rune(0x0299C)
  of "angrtvbd": result = Rune(0x0299D)
  of "ange": result = Rune(0x029A4)
  of "range": result = Rune(0x029A5)
  of "dwangle": result = Rune(0x029A6)
  of "uwangle": result = Rune(0x029A7)
  of "angmsdaa": result = Rune(0x029A8)
  of "angmsdab": result = Rune(0x029A9)
  of "angmsdac": result = Rune(0x029AA)
  of "angmsdad": result = Rune(0x029AB)
  of "angmsdae": result = Rune(0x029AC)
  of "angmsdaf": result = Rune(0x029AD)
  of "angmsdag": result = Rune(0x029AE)
  of "angmsdah": result = Rune(0x029AF)
  of "bemptyv": result = Rune(0x029B0)
  of "demptyv": result = Rune(0x029B1)
  of "cemptyv": result = Rune(0x029B2)
  of "raemptyv": result = Rune(0x029B3)
  of "laemptyv": result = Rune(0x029B4)
  of "ohbar": result = Rune(0x029B5)
  of "omid": result = Rune(0x029B6)
  of "opar": result = Rune(0x029B7)
  of "operp": result = Rune(0x029B9)
  of "olcross": result = Rune(0x029BB)
  of "odsold": result = Rune(0x029BC)
  of "olcir": result = Rune(0x029BE)
  of "ofcir": result = Rune(0x029BF)
  of "olt": result = Rune(0x029C0)
  of "ogt": result = Rune(0x029C1)
  of "cirscir": result = Rune(0x029C2)
  of "cirE": result = Rune(0x029C3)
  of "solb": result = Rune(0x029C4)
  of "bsolb": result = Rune(0x029C5)
  of "boxbox": result = Rune(0x029C9)
  of "trisb": result = Rune(0x029CD)
  of "rtriltri": result = Rune(0x029CE)
  of "LeftTriangleBar": result = Rune(0x029CF)
  of "RightTriangleBar": result = Rune(0x029D0)
  of "race": result = Rune(0x029DA)
  of "iinfin": result = Rune(0x029DC)
  of "infintie": result = Rune(0x029DD)
  of "nvinfin": result = Rune(0x029DE)
  of "eparsl": result = Rune(0x029E3)
  of "smeparsl": result = Rune(0x029E4)
  of "eqvparsl": result = Rune(0x029E5)
  of "lozf", "blacklozenge": result = Rune(0x029EB)
  of "RuleDelayed": result = Rune(0x029F4)
  of "dsol": result = Rune(0x029F6)
  of "xodot", "bigodot": result = Rune(0x02A00)
  of "xoplus", "bigoplus": result = Rune(0x02A01)
  of "xotime", "bigotimes": result = Rune(0x02A02)
  of "xuplus", "biguplus": result = Rune(0x02A04)
  of "xsqcup", "bigsqcup": result = Rune(0x02A06)
  of "qint", "iiiint": result = Rune(0x02A0C)
  of "fpartint": result = Rune(0x02A0D)
  of "cirfnint": result = Rune(0x02A10)
  of "awint": result = Rune(0x02A11)
  of "rppolint": result = Rune(0x02A12)
  of "scpolint": result = Rune(0x02A13)
  of "npolint": result = Rune(0x02A14)
  of "pointint": result = Rune(0x02A15)
  of "quatint": result = Rune(0x02A16)
  of "intlarhk": result = Rune(0x02A17)
  of "pluscir": result = Rune(0x02A22)
  of "plusacir": result = Rune(0x02A23)
  of "simplus": result = Rune(0x02A24)
  of "plusdu": result = Rune(0x02A25)
  of "plussim": result = Rune(0x02A26)
  of "plustwo": result = Rune(0x02A27)
  of "mcomma": result = Rune(0x02A29)
  of "minusdu": result = Rune(0x02A2A)
  of "loplus": result = Rune(0x02A2D)
  of "roplus": result = Rune(0x02A2E)
  of "Cross": result = Rune(0x02A2F)
  of "timesd": result = Rune(0x02A30)
  of "timesbar": result = Rune(0x02A31)
  of "smashp": result = Rune(0x02A33)
  of "lotimes": result = Rune(0x02A34)
  of "rotimes": result = Rune(0x02A35)
  of "otimesas": result = Rune(0x02A36)
  of "Otimes": result = Rune(0x02A37)
  of "odiv": result = Rune(0x02A38)
  of "triplus": result = Rune(0x02A39)
  of "triminus": result = Rune(0x02A3A)
  of "tritime": result = Rune(0x02A3B)
  of "iprod", "intprod": result = Rune(0x02A3C)
  of "amalg": result = Rune(0x02A3F)
  of "capdot": result = Rune(0x02A40)
  of "ncup": result = Rune(0x02A42)
  of "ncap": result = Rune(0x02A43)
  of "capand": result = Rune(0x02A44)
  of "cupor": result = Rune(0x02A45)
  of "cupcap": result = Rune(0x02A46)
  of "capcup": result = Rune(0x02A47)
  of "cupbrcap": result = Rune(0x02A48)
  of "capbrcup": result = Rune(0x02A49)
  of "cupcup": result = Rune(0x02A4A)
  of "capcap": result = Rune(0x02A4B)
  of "ccups": result = Rune(0x02A4C)
  of "ccaps": result = Rune(0x02A4D)
  of "ccupssm": result = Rune(0x02A50)
  of "And": result = Rune(0x02A53)
  of "Or": result = Rune(0x02A54)
  of "andand": result = Rune(0x02A55)
  of "oror": result = Rune(0x02A56)
  of "orslope": result = Rune(0x02A57)
  of "andslope": result = Rune(0x02A58)
  of "andv": result = Rune(0x02A5A)
  of "orv": result = Rune(0x02A5B)
  of "andd": result = Rune(0x02A5C)
  of "ord": result = Rune(0x02A5D)
  of "wedbar": result = Rune(0x02A5F)
  of "sdote": result = Rune(0x02A66)
  of "simdot": result = Rune(0x02A6A)
  of "congdot": result = Rune(0x02A6D)
  of "easter": result = Rune(0x02A6E)
  of "apacir": result = Rune(0x02A6F)
  of "apE": result = Rune(0x02A70)
  of "eplus": result = Rune(0x02A71)
  of "pluse": result = Rune(0x02A72)
  of "Esim": result = Rune(0x02A73)
  of "Colone": result = Rune(0x02A74)
  of "Equal": result = Rune(0x02A75)
  of "eDDot", "ddotseq": result = Rune(0x02A77)
  of "equivDD": result = Rune(0x02A78)
  of "ltcir": result = Rune(0x02A79)
  of "gtcir": result = Rune(0x02A7A)
  of "ltquest": result = Rune(0x02A7B)
  of "gtquest": result = Rune(0x02A7C)
  of "les", "LessSlantEqual", "leqslant": result = Rune(0x02A7D)
  of "ges", "GreaterSlantEqual", "geqslant": result = Rune(0x02A7E)
  of "lesdot": result = Rune(0x02A7F)
  of "gesdot": result = Rune(0x02A80)
  of "lesdoto": result = Rune(0x02A81)
  of "gesdoto": result = Rune(0x02A82)
  of "lesdotor": result = Rune(0x02A83)
  of "gesdotol": result = Rune(0x02A84)
  of "lap", "lessapprox": result = Rune(0x02A85)
  of "gap", "gtrapprox": result = Rune(0x02A86)
  of "lne", "lneq": result = Rune(0x02A87)
  of "gne", "gneq": result = Rune(0x02A88)
  of "lnap", "lnapprox": result = Rune(0x02A89)
  of "gnap", "gnapprox": result = Rune(0x02A8A)
  of "lEg", "lesseqqgtr": result = Rune(0x02A8B)
  of "gEl", "gtreqqless": result = Rune(0x02A8C)
  of "lsime": result = Rune(0x02A8D)
  of "gsime": result = Rune(0x02A8E)
  of "lsimg": result = Rune(0x02A8F)
  of "gsiml": result = Rune(0x02A90)
  of "lgE": result = Rune(0x02A91)
  of "glE": result = Rune(0x02A92)
  of "lesges": result = Rune(0x02A93)
  of "gesles": result = Rune(0x02A94)
  of "els", "eqslantless": result = Rune(0x02A95)
  of "egs", "eqslantgtr": result = Rune(0x02A96)
  of "elsdot": result = Rune(0x02A97)
  of "egsdot": result = Rune(0x02A98)
  of "el": result = Rune(0x02A99)
  of "eg": result = Rune(0x02A9A)
  of "siml": result = Rune(0x02A9D)
  of "simg": result = Rune(0x02A9E)
  of "simlE": result = Rune(0x02A9F)
  of "simgE": result = Rune(0x02AA0)
  of "LessLess": result = Rune(0x02AA1)
  of "GreaterGreater": result = Rune(0x02AA2)
  of "glj": result = Rune(0x02AA4)
  of "gla": result = Rune(0x02AA5)
  of "ltcc": result = Rune(0x02AA6)
  of "gtcc": result = Rune(0x02AA7)
  of "lescc": result = Rune(0x02AA8)
  of "gescc": result = Rune(0x02AA9)
  of "smt": result = Rune(0x02AAA)
  of "lat": result = Rune(0x02AAB)
  of "smte": result = Rune(0x02AAC)
  of "late": result = Rune(0x02AAD)
  of "bumpE": result = Rune(0x02AAE)
  of "pre", "preceq", "PrecedesEqual": result = Rune(0x02AAF)
  of "sce", "succeq", "SucceedsEqual": result = Rune(0x02AB0)
  of "prE": result = Rune(0x02AB3)
  of "scE": result = Rune(0x02AB4)
  of "prnE", "precneqq": result = Rune(0x02AB5)
  of "scnE", "succneqq": result = Rune(0x02AB6)
  of "prap", "precapprox": result = Rune(0x02AB7)
  of "scap", "succapprox": result = Rune(0x02AB8)
  of "prnap", "precnapprox": result = Rune(0x02AB9)
  of "scnap", "succnapprox": result = Rune(0x02ABA)
  of "Pr": result = Rune(0x02ABB)
  of "Sc": result = Rune(0x02ABC)
  of "subdot": result = Rune(0x02ABD)
  of "supdot": result = Rune(0x02ABE)
  of "subplus": result = Rune(0x02ABF)
  of "supplus": result = Rune(0x02AC0)
  of "submult": result = Rune(0x02AC1)
  of "supmult": result = Rune(0x02AC2)
  of "subedot": result = Rune(0x02AC3)
  of "supedot": result = Rune(0x02AC4)
  of "subE", "subseteqq": result = Rune(0x02AC5)
  of "supE", "supseteqq": result = Rune(0x02AC6)
  of "subsim": result = Rune(0x02AC7)
  of "supsim": result = Rune(0x02AC8)
  of "subnE", "subsetneqq": result = Rune(0x02ACB)
  of "supnE", "supsetneqq": result = Rune(0x02ACC)
  of "csub": result = Rune(0x02ACF)
  of "csup": result = Rune(0x02AD0)
  of "csube": result = Rune(0x02AD1)
  of "csupe": result = Rune(0x02AD2)
  of "subsup": result = Rune(0x02AD3)
  of "supsub": result = Rune(0x02AD4)
  of "subsub": result = Rune(0x02AD5)
  of "supsup": result = Rune(0x02AD6)
  of "suphsub": result = Rune(0x02AD7)
  of "supdsub": result = Rune(0x02AD8)
  of "forkv": result = Rune(0x02AD9)
  of "topfork": result = Rune(0x02ADA)
  of "mlcp": result = Rune(0x02ADB)
  of "Dashv", "DoubleLeftTee": result = Rune(0x02AE4)
  of "Vdashl": result = Rune(0x02AE6)
  of "Barv": result = Rune(0x02AE7)
  of "vBar": result = Rune(0x02AE8)
  of "vBarv": result = Rune(0x02AE9)
  of "Vbar": result = Rune(0x02AEB)
  of "Not": result = Rune(0x02AEC)
  of "bNot": result = Rune(0x02AED)
  of "rnmid": result = Rune(0x02AEE)
  of "cirmid": result = Rune(0x02AEF)
  of "midcir": result = Rune(0x02AF0)
  of "topcir": result = Rune(0x02AF1)
  of "nhpar": result = Rune(0x02AF2)
  of "parsim": result = Rune(0x02AF3)
  of "parsl": result = Rune(0x02AFD)
  of "fflig": result = Rune(0x0FB00)
  of "filig": result = Rune(0x0FB01)
  of "fllig": result = Rune(0x0FB02)
  of "ffilig": result = Rune(0x0FB03)
  of "ffllig": result = Rune(0x0FB04)
  of "Ascr": result = Rune(0x1D49C)
  of "Cscr": result = Rune(0x1D49E)
  of "Dscr": result = Rune(0x1D49F)
  of "Gscr": result = Rune(0x1D4A2)
  of "Jscr": result = Rune(0x1D4A5)
  of "Kscr": result = Rune(0x1D4A6)
  of "Nscr": result = Rune(0x1D4A9)
  of "Oscr": result = Rune(0x1D4AA)
  of "Pscr": result = Rune(0x1D4AB)
  of "Qscr": result = Rune(0x1D4AC)
  of "Sscr": result = Rune(0x1D4AE)
  of "Tscr": result = Rune(0x1D4AF)
  of "Uscr": result = Rune(0x1D4B0)
  of "Vscr": result = Rune(0x1D4B1)
  of "Wscr": result = Rune(0x1D4B2)
  of "Xscr": result = Rune(0x1D4B3)
  of "Yscr": result = Rune(0x1D4B4)
  of "Zscr": result = Rune(0x1D4B5)
  of "ascr": result = Rune(0x1D4B6)
  of "bscr": result = Rune(0x1D4B7)
  of "cscr": result = Rune(0x1D4B8)
  of "dscr": result = Rune(0x1D4B9)
  of "fscr": result = Rune(0x1D4BB)
  of "hscr": result = Rune(0x1D4BD)
  of "iscr": result = Rune(0x1D4BE)
  of "jscr": result = Rune(0x1D4BF)
  of "kscr": result = Rune(0x1D4C0)
  of "lscr": result = Rune(0x1D4C1)
  of "mscr": result = Rune(0x1D4C2)
  of "nscr": result = Rune(0x1D4C3)
  of "pscr": result = Rune(0x1D4C5)
  of "qscr": result = Rune(0x1D4C6)
  of "rscr": result = Rune(0x1D4C7)
  of "sscr": result = Rune(0x1D4C8)
  of "tscr": result = Rune(0x1D4C9)
  of "uscr": result = Rune(0x1D4CA)
  of "vscr": result = Rune(0x1D4CB)
  of "wscr": result = Rune(0x1D4CC)
  of "xscr": result = Rune(0x1D4CD)
  of "yscr": result = Rune(0x1D4CE)
  of "zscr": result = Rune(0x1D4CF)
  of "Afr": result = Rune(0x1D504)
  of "Bfr": result = Rune(0x1D505)
  of "Dfr": result = Rune(0x1D507)
  of "Efr": result = Rune(0x1D508)
  of "Ffr": result = Rune(0x1D509)
  of "Gfr": result = Rune(0x1D50A)
  of "Jfr": result = Rune(0x1D50D)
  of "Kfr": result = Rune(0x1D50E)
  of "Lfr": result = Rune(0x1D50F)
  of "Mfr": result = Rune(0x1D510)
  of "Nfr": result = Rune(0x1D511)
  of "Ofr": result = Rune(0x1D512)
  of "Pfr": result = Rune(0x1D513)
  of "Qfr": result = Rune(0x1D514)
  of "Sfr": result = Rune(0x1D516)
  of "Tfr": result = Rune(0x1D517)
  of "Ufr": result = Rune(0x1D518)
  of "Vfr": result = Rune(0x1D519)
  of "Wfr": result = Rune(0x1D51A)
  of "Xfr": result = Rune(0x1D51B)
  of "Yfr": result = Rune(0x1D51C)
  of "afr": result = Rune(0x1D51E)
  of "bfr": result = Rune(0x1D51F)
  of "cfr": result = Rune(0x1D520)
  of "dfr": result = Rune(0x1D521)
  of "efr": result = Rune(0x1D522)
  of "ffr": result = Rune(0x1D523)
  of "gfr": result = Rune(0x1D524)
  of "hfr": result = Rune(0x1D525)
  of "ifr": result = Rune(0x1D526)
  of "jfr": result = Rune(0x1D527)
  of "kfr": result = Rune(0x1D528)
  of "lfr": result = Rune(0x1D529)
  of "mfr": result = Rune(0x1D52A)
  of "nfr": result = Rune(0x1D52B)
  of "ofr": result = Rune(0x1D52C)
  of "pfr": result = Rune(0x1D52D)
  of "qfr": result = Rune(0x1D52E)
  of "rfr": result = Rune(0x1D52F)
  of "sfr": result = Rune(0x1D530)
  of "tfr": result = Rune(0x1D531)
  of "ufr": result = Rune(0x1D532)
  of "vfr": result = Rune(0x1D533)
  of "wfr": result = Rune(0x1D534)
  of "xfr": result = Rune(0x1D535)
  of "yfr": result = Rune(0x1D536)
  of "zfr": result = Rune(0x1D537)
  of "Aopf": result = Rune(0x1D538)
  of "Bopf": result = Rune(0x1D539)
  of "Dopf": result = Rune(0x1D53B)
  of "Eopf": result = Rune(0x1D53C)
  of "Fopf": result = Rune(0x1D53D)
  of "Gopf": result = Rune(0x1D53E)
  of "Iopf": result = Rune(0x1D540)
  of "Jopf": result = Rune(0x1D541)
  of "Kopf": result = Rune(0x1D542)
  of "Lopf": result = Rune(0x1D543)
  of "Mopf": result = Rune(0x1D544)
  of "Oopf": result = Rune(0x1D546)
  of "Sopf": result = Rune(0x1D54A)
  of "Topf": result = Rune(0x1D54B)
  of "Uopf": result = Rune(0x1D54C)
  of "Vopf": result = Rune(0x1D54D)
  of "Wopf": result = Rune(0x1D54E)
  of "Xopf": result = Rune(0x1D54F)
  of "Yopf": result = Rune(0x1D550)
  of "aopf": result = Rune(0x1D552)
  of "bopf": result = Rune(0x1D553)
  of "copf": result = Rune(0x1D554)
  of "dopf": result = Rune(0x1D555)
  of "eopf": result = Rune(0x1D556)
  of "fopf": result = Rune(0x1D557)
  of "gopf": result = Rune(0x1D558)
  of "hopf": result = Rune(0x1D559)
  of "iopf": result = Rune(0x1D55A)
  of "jopf": result = Rune(0x1D55B)
  of "kopf": result = Rune(0x1D55C)
  of "lopf": result = Rune(0x1D55D)
  of "mopf": result = Rune(0x1D55E)
  of "nopf": result = Rune(0x1D55F)
  of "oopf": result = Rune(0x1D560)
  of "popf": result = Rune(0x1D561)
  of "qopf": result = Rune(0x1D562)
  of "ropf": result = Rune(0x1D563)
  of "sopf": result = Rune(0x1D564)
  of "topf": result = Rune(0x1D565)
  of "uopf": result = Rune(0x1D566)
  of "vopf": result = Rune(0x1D567)
  of "wopf": result = Rune(0x1D568)
  of "xopf": result = Rune(0x1D569)
  of "yopf": result = Rune(0x1D56A)
  of "zopf": result = Rune(0x1D56B)
  else: discard

proc entityToUtf8*(entity: string): string =
  ## Converts an HTML entity name like ``&Uuml;`` or values like ``&#220;``
  ## or ``&#x000DC;`` to its UTF-8 equivalent.
  ## "" is returned if the entity name is unknown. The HTML parser
  ## already converts entities to UTF-8.
  runnableExamples:
    doAssert entityToUtf8(nil) == ""
    doAssert entityToUtf8("") == ""
    doAssert entityToUtf8("a") == ""
    doAssert entityToUtf8("gt") == ">"
    doAssert entityToUtf8("Uuml") == "Ü"
    doAssert entityToUtf8("quest") == "?"
    doAssert entityToUtf8("#63") == "?"
    doAssert entityToUtf8("Sigma") == "Σ"
    doAssert entityToUtf8("#931") == "Σ"
    doAssert entityToUtf8("#0931") == "Σ"
    doAssert entityToUtf8("#x3A3") == "Σ"
    doAssert entityToUtf8("#x03A3") == "Σ"
    doAssert entityToUtf8("#x3a3") == "Σ"
    doAssert entityToUtf8("#X3a3") == "Σ"
  let rune = entityToRune(entity)
  if rune.ord <= 0: result = ""
  else: result = toUTF8(rune)

proc addNode(father, son: XmlNode) =
  if son != nil: add(father, son)

proc parse(x: var XmlParser, errors: var seq[string]): XmlNode

proc expected(x: var XmlParser, n: XmlNode): string =
  result = errorMsg(x, "</" & n.tag & "> expected")

template elemName(x: untyped): untyped = rawData(x)

template adderr(x: untyped) =
  errors.add(x)

proc untilElementEnd(x: var XmlParser, result: XmlNode,
                     errors: var seq[string]) =
  # we parsed e.g. ``<br>`` and don't really expect a ``</br>``:
  if result.htmlTag in SingleTags:
    if x.kind != xmlElementEnd or cmpIgnoreCase(x.elemName, result.tag) != 0:
      return
  while true:
    case x.kind
    of xmlElementStart, xmlElementOpen:
      case result.htmlTag
      of tagP, tagInput, tagOption:
        # some tags are common to have no ``</end>``, like ``<li>`` but
        # allow ``<p>`` in `<dd>`, `<dt>` and ``<li>`` in next case
        if htmlTag(x.elemName) in {tagLi, tagP, tagDt, tagDd, tagInput,
                                   tagOption}:
          adderr(expected(x, result))
          break
      of tagDd, tagDt, tagLi:
        if htmlTag(x.elemName) in {tagLi, tagDt, tagDd, tagInput,
                                   tagOption}:
          adderr(expected(x, result))
          break
      of tagTd, tagTh:
        if htmlTag(x.elemName) in {tagTr, tagTd, tagTh, tagTfoot, tagThead}:
          adderr(expected(x, result))
          break
      of tagTr:
        if htmlTag(x.elemName) == tagTr:
          adderr(expected(x, result))
          break
      of tagOptgroup:
        if htmlTag(x.elemName) in {tagOption, tagOptgroup}:
          adderr(expected(x, result))
          break
      else: discard
      result.addNode(parse(x, errors))
    of xmlElementEnd:
      if cmpIgnoreCase(x.elemName, result.tag) != 0:
        #echo "5; expected: ", result.htmltag, " ", x.elemName
        adderr(expected(x, result))
        # this seems to do better match error corrections in browsers:
        while x.kind in {xmlElementEnd, xmlWhitespace}:
          if x.kind == xmlElementEnd and cmpIgnoreCase(x.elemName, result.tag) == 0:
            break
          next(x)
      next(x)
      break
    of xmlEof:
      adderr(expected(x, result))
      break
    else:
      result.addNode(parse(x, errors))

proc parse(x: var XmlParser, errors: var seq[string]): XmlNode =
  case x.kind
  of xmlComment:
    result = newComment(x.rawData)
    next(x)
  of xmlCharData, xmlWhitespace:
    result = newText(x.rawData)
    next(x)
  of xmlPI, xmlSpecial:
    # we just ignore processing instructions for now
    next(x)
  of xmlError:
    adderr(errorMsg(x))
    next(x)
  of xmlElementStart:
    result = newElement(toLowerAscii(x.elemName))
    next(x)
    untilElementEnd(x, result, errors)
  of xmlElementEnd:
    adderr(errorMsg(x, "unexpected ending tag: " & x.elemName))
  of xmlElementOpen:
    result = newElement(toLowerAscii(x.elemName))
    next(x)
    result.attrs = newStringTable()
    while true:
      case x.kind
      of xmlAttribute:
        result.attrs[x.rawData] = x.rawData2
        next(x)
      of xmlElementClose:
        next(x)
        break
      of xmlError:
        adderr(errorMsg(x))
        next(x)
        break
      else:
        adderr(errorMsg(x, "'>' expected"))
        next(x)
        break
    untilElementEnd(x, result, errors)
  of xmlAttribute, xmlElementClose:
    adderr(errorMsg(x, "<some_tag> expected"))
    next(x)
  of xmlCData:
    result = newCData(x.rawData)
    next(x)
  of xmlEntity:
    var u = entityToUtf8(x.rawData)
    if u.len != 0: result = newText(u)
    next(x)
  of xmlEof: discard

proc parseHtml*(s: Stream, filename: string,
                errors: var seq[string]): XmlNode =
  ## Parses the XML from stream `s` and returns a ``XmlNode``. Every
  ## occurred parsing error is added to the `errors` sequence.
  var x: XmlParser
  open(x, s, filename, {reportComments, reportWhitespace})
  next(x)
  # skip the DOCTYPE:
  if x.kind == xmlSpecial: next(x)

  result = newElement("document")
  result.addNode(parse(x, errors))
  #if x.kind != xmlEof:
  #  adderr(errorMsg(x, "EOF expected"))
  while x.kind != xmlEof:
    var oldPos = x.bufpos # little hack to see if we made any progess
    result.addNode(parse(x, errors))
    if x.bufpos == oldPos:
      # force progress!
      next(x)
  close(x)
  if result.len == 1:
    result = result[0]

proc parseHtml*(s: Stream): XmlNode =
  ## Parses the HTML from stream `s` and returns a ``XmlNode``. All parsing
  ## errors are ignored.
  var errors: seq[string] = @[]
  result = parseHtml(s, "unknown_html_doc", errors)

proc parseHtml*(html: string): XmlNode =
  ## Parses the HTML from string ``html`` and returns a ``XmlNode``. All parsing
  ## errors are ignored.
  parseHtml(newStringStream(html))

proc loadHtml*(path: string, errors: var seq[string]): XmlNode =
  ## Loads and parses HTML from file specified by ``path``, and returns
  ## a ``XmlNode``. Every occurred parsing error is added to
  ## the `errors` sequence.
  var s = newFileStream(path, fmRead)
  if s == nil: raise newException(IOError, "Unable to read file: " & path)
  result = parseHtml(s, path, errors)

proc loadHtml*(path: string): XmlNode =
  ## Loads and parses HTML from file specified by ``path``, and returns
  ## a ``XmlNode``. All parsing errors are ignored.
  var errors: seq[string] = @[]
  result = loadHtml(path, errors)

when not defined(testing) and isMainModule:
  import os

  var errors: seq[string] = @[]
  var x = loadHtml(paramStr(1), errors)
  for e in items(errors): echo e

  var f: File
  if open(f, "test.txt", fmWrite):
    f.write($x)
    f.close()
  else:
    quit("cannot write test.txt")
