#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import xmldom, os, streams, parsexml, strutils

## This module parses a XML Document into a XML DOM Document representation.

#XMLDom's Parser - Turns XML into a Document

type
  #Parsing errors
  EMismatchedTag* = object of E_Base ## Raised when a tag is not properly closed
  EParserError* = object of E_Base ## Raised when an unexpected XML Parser event occurs
    
proc parseText(x: var TXmlParser, doc: var PDocument): PText =
  result = doc.createTextNode(x.charData())

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
    
proc loadXML*(path: string): PDocument =
  ## Loads and parses XML from file specified by ``path``, and returns 
  ## a ``PDocument``
  
  var s = newFileStream(path, fmRead)
  if s == nil: raise newException(EIO, "Unable to read file " & path)

  var x: TXmlParser
  open(x, s, path, {reportComments})
  
  var XmlDoc: PDocument
  var DOM: PDOMImplementation = getDOM()
  
  while True:
    x.next()
    case x.kind()
    of xmlEof:
      break
    of xmlElementStart, xmlElementOpen:
      var el: PElement = parseElement(x, XmlDoc)
      XmlDoc = dom.createDocument(el)
    of xmlWhitespace, xmlElementClose, xmlEntity, xmlSpecial:
      # Unused 'events'
    else:
      raise newException(EParserError, "Unexpected XML Parser event")

  close(x)
  return XmlDoc


when isMainModule:
  var xml = loadXML(r"C:\Users\Dominik\Desktop\Code\Nimrod\xmldom\test.xml")
  echo($xml)
