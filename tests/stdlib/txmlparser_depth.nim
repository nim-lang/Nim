discard """
  matrix: "--mm:arc; --mm:refc"
"""

# Deeply nested input is rejected (XML) or flattened (HTML) instead of
# exhausting the stack.

import std/[xmlparser, xmltree, strutils, streams, assertions]
import std/htmlparser {.all.}

# The parsers report failures as `XmlError`, `IOError`, `OSError` or
# `ValueError` only, so callers can list exactly those instead of `Exception`.
# Too deep nesting is one of them for XML: the `errors` variants record it.
proc xmlFromString(s: string): XmlNode {.raises: [XmlError, IOError, OSError, ValueError].} =
  parseXml(s)
proc xmlFromStream(s: Stream): XmlNode {.raises: [XmlError, IOError, OSError, ValueError].} =
  parseXml(s)
proc xmlCollecting(s: Stream, errors: var seq[string]): XmlNode {.raises: [IOError, OSError, ValueError].} =
  parseXml(s, "input", errors)
proc xmlFromFile(path: string): XmlNode {.raises: [XmlError, IOError, OSError, ValueError].} =
  loadXml(path)
proc xmlCollectingFromFile(path: string, errors: var seq[string]): XmlNode {.raises: [IOError, OSError, ValueError].} =
  loadXml(path, errors)
proc htmlFromString(s: string): XmlNode {.raises: [IOError, OSError, ValueError].} =
  parseHtml(s)
proc htmlFromStream(s: Stream): XmlNode {.raises: [IOError, OSError, ValueError].} =
  parseHtml(s)
proc htmlCollecting(s: Stream, errors: var seq[string]): XmlNode {.raises: [IOError, OSError, ValueError].} =
  parseHtml(s, "input", errors)
proc htmlFromFile(path: string): XmlNode {.raises: [IOError, OSError, ValueError].} =
  loadHtml(path)
proc htmlCollectingFromFile(path: string, errors: var seq[string]): XmlNode {.raises: [IOError, OSError, ValueError].} =
  loadHtml(path, errors)

const n = 500_000

block: # XML
  let deep = "<a>".repeat(n) & "x" & "</a>".repeat(n)
  var errors: seq[string] = @[]
  doAssert parseXml(newStringStream(deep), "deep.xml", errors) == nil
  doAssert errors.len == 1
  doAssert "nested deeper than" in errors[0]
  doAssertRaises(XmlError): discard parseXml(deep)

  # the maximum depth is still fine
  let ok = "<a>".repeat(xmlMaxDepth) & "x" & "</a>".repeat(xmlMaxDepth)
  var x = parseXml(ok)
  for i in 1 ..< xmlMaxDepth: x = x[0]
  doAssert x.innerText == "x"
  doAssertRaises(XmlError):
    discard parseXml("<a>" & ok & "</a>")

block: # HTML
  var errors: seq[string] = @[]
  let h = parseHtml(newStringStream("<div>".repeat(n) & "x"), "deep.html", errors)
  var depth = 0
  var it = h
  while it.kind == xnElement and it.len > 0:
    inc depth
    it = it[0]
  doAssert depth <= htmlMaxDepth + 1, $depth
  doAssert errors.len < 2 * htmlMaxDepth

  let ok = "<div>".repeat(100) & "x" & "</div>".repeat(100)
  errors.setLen 0
  var x = parseHtml(newStringStream(ok), "ok.html", errors)
  doAssert errors.len == 0
  for i in 1 ..< 100: x = x[0]
  doAssert x.innerText == "x"
