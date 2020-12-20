discard """
  targets: "c cpp js"
"""

import std/stropt


proc teststrip() =
  var a = "  vhellov   "
  strip(a)
  doAssert a == "vhellov"

  a = "  vhellov   "
  a.strip(leading = false)
  doAssert a == "  vhellov"

  a = "  vhellov   "
  a.strip(trailing = false)
  doAssert a == "vhellov   "

  a.strip()
  a.strip(chars = {'v'})
  doAssert a == "hello"

  a = "  vhellov   "
  a.strip()
  a.strip(leading = false, chars = {'v'})
  doAssert a == "vhello"

  var c = "blaXbla"
  c.strip(chars = {'b', 'a'})
  doAssert c == "laXbl"
  c = "blaXbla"
  c.strip(chars = {'b', 'a', 'l'})
  doAssert c == "X"

static: teststrip()
teststrip()
