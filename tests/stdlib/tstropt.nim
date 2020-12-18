discard """
  targets: "c cpp js"
"""

import std/stropt


proc testStripInplace() =
  var a = "  vhellov   "
  stripInplace(a)
  doAssert a == "vhellov"

  a = "  vhellov   "
  a.stripInplace(leading = false)
  doAssert a == "  vhellov"

  a = "  vhellov   "
  a.stripInplace(trailing = false)
  doAssert a == "vhellov   "

  a.stripInplace()
  a.stripInplace(chars = {'v'})
  doAssert a == "hello"

  a = "  vhellov   "
  a.stripInplace()
  a.stripInplace(leading = false, chars = {'v'})
  doAssert a == "vhello"

  var c = "blaXbla"
  c.stripInplace(chars = {'b', 'a'})
  doAssert c == "laXbl"
  c = "blaXbla"
  c.stripInplace(chars = {'b', 'a', 'l'})
  doAssert c == "X"

static: testStripInplace()
testStripInplace()
