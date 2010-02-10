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
## document (if you are lucky):
##
## .. code-block:: nimrod
##
##   echo loadHtml("mydirty.html")
##
##
## Every tag in the resulting tree is in lower case.
##
## **Note:** The resulting ``PXmlNode``s already use the ``clientData`` field, 
## so it cannot be used by clients of this library.

import streams, parsexml, xmltree

type
  THtmlTag* = enum ## list of all supported HTML tags; order will always be
                   ## alphabetically
    tagUnknown,    ## unknown HTML element
    tagA,          ## the HTML ``a`` element
    tagAcronym,    ## the HTML ``acronym`` element
    tagAddress,    ## the HTML ``address`` element
    tagArea,       ## the HTML ``area`` element
    tagB,          ## the HTML ``b`` element
    tagBase,       ## the HTML ``base`` element
    tagBig,        ## the HTML ``big`` element
    tagBlockquote, ## the HTML ``blockquote`` element
    tagBody,       ## the HTML ``body`` element
    tagBr,         ## the HTML ``br`` element
    tagButton,     ## the HTML ``button`` element
    tagCaption,    ## the HTML ``caption`` element
    tagCite,       ## the HTML ``cite`` element
    tagCode,       ## the HTML ``code`` element
    tagCol,        ## the HTML ``col`` element
    tagColgroup,   ## the HTML ``colgroup`` element
    tagDd,         ## the HTML ``dd`` element
    tagDel,        ## the HTML ``del`` element
    tagDfn,        ## the HTML ``dfn`` element
    tagDiv,        ## the HTML ``div`` element
    tagDl,         ## the HTML ``dl`` element
    tagDt,         ## the HTML ``dt`` element
    tagEm,         ## the HTML ``em`` element
    tagFieldset,   ## the HTML ``fieldset`` element
    tagForm,       ## the HTML ``form`` element
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
    tagImg,        ## the HTML ``img`` element
    tagInput,      ## the HTML ``input`` element
    tagIns,        ## the HTML ``ins`` element
    tagKbd,        ## the HTML ``kbd`` element
    tagLabel,      ## the HTML ``label`` element
    tagLegend,     ## the HTML ``legend`` element
    tagLi,         ## the HTML ``li`` element
    tagLink,       ## the HTML ``link`` element
    tagMap,        ## the HTML ``map`` element
    tagMeta,       ## the HTML ``meta`` element
    tagNoscript,   ## the HTML ``noscript`` element
    tagObject,     ## the HTML ``object`` element
    tagOl,         ## the HTML ``ol`` element
    tagOptgroup,   ## the HTML ``optgroup`` element
    tagOption,     ## the HTML ``option`` element
    tagP,          ## the HTML ``p`` element
    tagParam,      ## the HTML ``param`` element
    tagPre,        ## the HTML ``pre`` element
    tagQ,          ## the HTML ``q`` element
    tagSamp,       ## the HTML ``samp`` element
    tagScript,     ## the HTML ``script`` element
    tagSelect,     ## the HTML ``select`` element
    tagSmall,      ## the HTML ``small`` element
    tagSpan,       ## the HTML ``span`` element
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
    tagUl,         ## the HTML ``ul`` element
    tagVar         ## the HTML ``var`` element

const 
  tagStrs = [
    "a", "acronym", "address", "area", "b", "base", "big", "blockquote", 
    "body", "br", "button", "caption", "cite", "code", "col", "colgroup", 
    "dd", "del", "dfn", "div", "dl", "dt", "em", "fieldset", 
    "form", "h1", "h2", "h3", "h4", "h5", "h6", "head", "html", "hr", 
    "i", "img", "input", "ins", "kbd", "label", "legend", "li", "link", 
    "map", "meta", "noscript", "object", "ol", "optgroup", "option", 
    "p", "param", "pre", "q", "samp", "script", "select", "small", 
    "span", "strong", "style", "sub", "sup", "table", "tbody", "td", 
    "textarea", "tfoot", "th", "thead", "title", "tr", "tt", "ul", "var"
  ]

proc binaryStrSearch(x: openarray[string], y: string): int = 
  ## XXX put this into the library somewhere!
  var a = 0
  var b = len(x) - 1
  while a <= b: 
    var mid = (a + b) div 2
    var c = cmp(x[mid], y)
    if c < 0: 
      a = mid + 1
    elif c > 0: 
      b = mid - 1
    else: 
      return mid
  result = - 1

proc htmlTag*(n: PXmlNode): THtmlTag = 
  ## gets `n`'s tag as a ``THtmlTag``. Even though results are cached, this is
  ## can be more expensive than comparing ``tag`` directly to a string.
  if n.clientData == 0:
    n.clientData = binaryStrSearch(tagStrs, n.tag)+1
  result = THtmlTag(n.clientData)

proc parseElement(x: var TXmlParser, doc: var PDocument): PElement =
  var n = doc.createElement("")

  while True:
    case x.kind()
    of xmlEof:
      break
    of xmlElementStart:
      if n.tagName() != "":
        n.appendChild(parseElement(x, doc))
      else:
        n = doc.createElement(x.elementName)
    of xmlElementOpen:
      if n.tagName() != "":
        n.appendChild(parseElement(x, doc))
      else:
        if x.elementName.contains(':'):
          #TODO: NamespaceURI
          n = doc.createElementNS("nil", x.elementName)
        else:  
          n = doc.createElement(x.elementName)
        
    of xmlElementEnd:
      if x.elementName == n.nodeName:
        # n.normalize() # Remove any whitespace etc.
        return n
      else: #The wrong element is ended
        raise newException(EMismatchedTag, "Mismatched tag at line " & 
          $x.getLine() & " column " & $x.getColumn)
      
    of xmlCharData:
      n.appendChild(parseText(x, doc))
    of xmlAttribute:
      if x.attrKey.contains(':'):
        #TODO: NamespaceURI
        n.setAttributeNS("nil", x.attrKey, x.attrValue)
      else:
        n.setAttribute(x.attrKey, x.attrValue)
    of xmlCData:
      n.appendChild(doc.createCDATASection(x.charData()))
    of xmlComment:
      n.appendChild(doc.createComment(x.charData()))
    of xmlPI:
      n.appendChild(doc.createProcessingInstruction(x.PIName(), x.PIRest()))
      
    of xmlWhitespace, xmlElementClose, xmlEntity, xmlSpecial:
      # Unused 'events'

    else:
      raise newException(EParserError, "Unexpected XML Parser event")
    x.next()

  raise newException(EMismatchedTag, 
    "Mismatched tag at line " & $x.getLine() & " column " & $x.getColumn)


proc parse*(x: var TXmlParser, father: PXmlNode) =
  

proc parseHtml*(s: PStream, filename: string, 
                errors: var seq[string]): PXmlNode = 
  ## parses the HTML from stream `s` and returns a ``PXmlNode``. Every
  ## occured parsing error is added to the `errors` sequence.
  var x: TXmlParser
  open(x, s, filename, {reportComments})
  
  result = newElement("html")
  while true:
    x.next()
    case x.kind
    of xmlWhitespace: nil # just skip it
    of xmlComment: 
      result.add(newComment(x.text))
  
  while True:
    x.next()
    case x.kind
    of xmlEof: break
    of xmlElementStart, xmlElementOpen:
      var el: PElement = parseElement(x, XmlDoc)
      XmlDoc = dom.createDocument(el)
    of xmlWhitespace, xmlElementClose, xmlEntity, xmlSpecial:
      # Unused 'events'
    else:
      raise newException(EParserError, "Unexpected XML Parser event")
  close(x)

proc parseHtml*(s: PStream): PXmlNode = 
  ## parses the HTML from stream `s` and returns a ``PXmlNode``. All parsing
  ## errors are ignored.
  var errors: seq[string] = @[]
  result = parseHtml(s, "unknown_html_doc", errors)

proc loadHtml*(path: string, reportErrors = false): PXmlNode = 
  ## Loads and parses HTML from file specified by ``path``, and returns 
  ## a ``PXmlNode``. If `reportErrors` is true, the parsing errors are
  ## ``echo``ed.
  var s = newFileStream(path, fmRead)
  if s == nil: raise newException(EIO, "Unable to read file: " & path)
  
  var errors: seq[string] = @[]
  result = parseHtml(s, path, errors)
  if reportErrors: 
    for msg in items(errors): echo(msg)

