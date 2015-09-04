# Example program to show the new parsexml module
# This program reads an HTML file and writes all its used links to stdout.
# Errors and whitespace are ignored.

import os, streams, parsexml, strutils

proc `=?=` (a, b: string): bool =
  # little trick: define our own comparator that ignores case
  return cmpIgnoreCase(a, b) == 0

if paramCount() < 1:
  quit("Usage: htmlrefs filename[.html]")

var links = 0 # count the number of links
var filename = addFileExt(paramStr(1), "html")
var s = newFileStream(filename, fmRead)
if s == nil: quit("cannot open the file " & filename)
var x: XmlParser
open(x, s, filename)
next(x) # get first event
block mainLoop:
  while true:
    case x.kind
    of xmlElementOpen:
      # the <a href = "xyz"> tag we are interested in always has an attribute,
      # thus we search for ``xmlElementOpen`` and not for ``xmlElementStart``
      if x.elementName =?= "a":
        x.next()
        if x.kind == xmlAttribute:
          if x.attrKey =?= "href":
            var link = x.attrValue
            inc(links)
            # skip until we have an ``xmlElementClose`` event
            while true:
              x.next()
              case x.kind
              of xmlEof: break mainLoop
              of xmlElementClose: break
              else: discard
            x.next() # skip ``xmlElementClose``
            # now we have the description for the ``a`` element
            var desc = ""
            while x.kind == xmlCharData:
              desc.add(x.charData)
              x.next()
            echo(desc & ": " & link)
      else:
        x.next()
    of xmlEof: break # end of file reached
    of xmlError:
      echo(errorMsg(x))
      x.next()
    else: x.next() # skip other events

echo($links & " link(s) found!")
x.close()

