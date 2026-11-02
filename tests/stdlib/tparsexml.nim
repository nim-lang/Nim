discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/[parsexml, streams, strutils, assertions]

block: # unquoted attribute value crossing the 8 KB buffer refill point
  # The '/' in `c=</d>` is the last refill character in the first buffer, so
  # the error recovery for the unquoted value must refill instead of
  # scanning past it.
  let prefix = "<a>" & repeat('x', 8150) & "<b c=<"
  let input = prefix & "/d>" & repeat('y', 100) & "</a>"
  doAssert input.find('/') < 8192
  var x: XmlParser
  x.open(newStringStream(input), "test")
  var sawError = false
  while true:
    x.next()
    case x.kind
    of xmlError: sawError = true
    of xmlEof: break
    else: discard
  x.close()
  doAssert sawError
