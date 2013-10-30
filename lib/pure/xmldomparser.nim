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
  # Parsing errors
  EMismatchedTag* = object of EInvalidValue ## Raised when a tag is not properly closed
  EParserError* = object of EInvalidValue ## Raised when an unexpected XML Parser event occurs

  # For namespaces
  xmlnsAttr = tuple[name, value: string, ownerElement: PElement]

var nsList: seq[xmlnsAttr] = @[] # Used for storing namespaces

proc getNS(prefix: string): string =
  var defaultNS: seq[string] = @[]

  for key, value, tag in items(nsList):
    if ":" in key:
      if key.split(':')[1] == prefix:
        return value

    if key == "xmlns":
      defaultNS.add(value)

  # Don't return the default namespaces
  # in the loop, because then they would have a precedence
  # over normal namespaces
  if defaultNS.len() > 0:
    return defaultNS[0] # Return the first found default namespace
                        # if none are specified for this prefix

  return ""

proc parseText(x: var TXmlParser, doc: var PDocument): PText =
  result = doc.createTextNode(x.charData())

proc parseElement(x: var TXmlParser, doc: var PDocument): PElement =
  var n = doc.createElement("")

  while True:
    case x.kind()
    of xmlEof:
      break
    of xmlElementStart, xmlElementOpen:
      if n.tagName() != "":
        n.appendChild(parseElement(x, doc))
      else:
        n = doc.createElementNS("", x.elementName)

    of xmlElementEnd:
      if x.elementName == n.nodeName:
        # n.normalize() # Remove any whitespace etc.

        var ns: string
        if x.elementName.contains(':'):
          ns = getNS(x.elementName.split(':')[0])
        else:
          ns = getNS("")

        n.namespaceURI = ns

        # Remove any namespaces this element declared
        var count = 0 # Variable which keeps the index
                      # We need to edit it..
        for i in low(nsList)..len(nsList)-1:
          if nsList[count][2] == n:
            nsList.delete(count)
            dec(count)
          inc(count)

        return n
      else: #The wrong element is ended
        raise newException(EMismatchedTag, "Mismatched tag at line " &
          $x.getLine() & " column " & $x.getColumn)

    of xmlCharData:
      n.appendChild(parseText(x, doc))
    of xmlAttribute:
      if x.attrKey == "xmlns" or x.attrKey.startsWith("xmlns:"):
        nsList.add((x.attrKey, x.attrValue, n))

      if x.attrKey.contains(':'):
        var ns = getNS(x.attrKey)
        n.setAttributeNS(ns, x.attrKey, x.attrValue)
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

proc loadXMLStream*(stream: PStream): PDocument =
  ## Loads and parses XML from a stream specified by ``stream``, and returns
  ## a ``PDocument``

  var x: TXmlParser
  open(x, stream, nil, {reportComments})

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

  return XmlDoc

proc loadXML*(xml: string): PDocument =
  ## Loads and parses XML from a string specified by ``xml``, and returns
  ## a ``PDocument``
  var s = newStringStream(xml)
  return loadXMLStream(s)


proc loadXMLFile*(path: string): PDocument =
  ## Loads and parses XML from a file specified by ``path``, and returns
  ## a ``PDocument``

  var s = newFileStream(path, fmRead)
  if s == nil: raise newException(EIO, "Unable to read file " & path)
  return loadXMLStream(s)


when isMainModule:
  var xml = loadXMLFile(r"C:\Users\Dominik\Desktop\Code\Nimrod\xmldom\test.xml")
  #echo(xml.getElementsByTagName("m:test2")[0].namespaceURI)
  #echo(xml.getElementsByTagName("bla:test")[0].namespaceURI)
  #echo(xml.getElementsByTagName("test")[0].namespaceURI)
  for i in items(xml.getElementsByTagName("*")):
    if i.namespaceURI != nil:
      echo(i.nodeName, "=", i.namespaceURI)


  echo($xml)
