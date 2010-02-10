#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module parses an XML document and creates its XML tree representation.

import streams, parsexml, xmltree


proc parse*(x: var TXmlParser, father: PXmlNode) =
  

proc parseXml*(s: PStream, filename: string, 
               errors: var seq[string]): PXmlNode = 
  ## parses the XML from stream `s` and returns a ``PXmlNode``. Every
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
  
  close(x)

proc parseXml*(s: PStream): PXmlNode = 
  ## parses the XTML from stream `s` and returns a ``PXmlNode``. All parsing
  ## errors are ignored.
  var errors: seq[string] = @[]
  result = parseXml(s, "unknown_html_doc", errors)

proc loadXml*(path: string, reportErrors = false): PXmlNode = 
  ## Loads and parses XML from file specified by ``path``, and returns 
  ## a ``PXmlNode``. If `reportErrors` is true, the parsing errors are
  ## ``echo``ed.
  var s = newFileStream(path, fmRead)
  if s == nil: raise newException(EIO, "Unable to read file: " & path)
  
  var errors: seq[string] = @[]
  result = parseXml(s, path, errors)
  if reportErrors: 
    for msg in items(errors): echo(msg)

