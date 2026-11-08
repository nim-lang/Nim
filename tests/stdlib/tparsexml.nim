discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/[parsexml, streams, strutils, assertions, xmltree, xmlparser]

block: # '/' in a <! > declaration is part of its data
  var x: XmlParser
  x.open(newStringStream(
    """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0//EN"><a/>"""), "test")
  var special = ""
  while true:
    x.next()
    case x.kind
    of xmlSpecial: special = x.charData
    of xmlEof: break
    else: discard
  x.close()
  doAssert special == """DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0//EN"""", special

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

block: # whitespace before a '/' in a quoted attribute value
  # '/' is a refill character with its own branch, which must place the
  # pending space before the slash rather than after it.
  var x: XmlParser
  x.open(newStringStream("""<a b="1 / 2" c=" /x" d="x/ y"/>"""), "test")
  var values: seq[string]
  while true:
    x.next()
    case x.kind
    of xmlAttribute: values.add x.attrValue
    of xmlEof: break
    else: discard
  x.close()
  doAssert values == @["1 / 2", " /x", "x/ y"], $values

block: # an attribute value with " / " survives xmltree's `$` and parseXml
  let value = "1 / 2"
  let written = $(<>a(v = value))
  doAssert written == """<a v="1 / 2" />""", written
  doAssert parseXml(written).attr("v") == value
