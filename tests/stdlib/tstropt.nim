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

  block:
    var a = "xxxxxx"
    a.strip(chars={'x'})
    doAssert a.len == 0

  block:
    var a = "x"
    a.strip(chars={'x'})
    doAssert a.len == 0
  
  block:
    var a = "x"
    a.strip(chars={'1'})
    doAssert a.len == 1

  block:
    var a = ""
    a.strip(chars={'x'})
    doAssert a.len == 0

  block:
    var a = "xxx xxx"
    a.strip(chars={'x'})
    doAssert a == " "

  block:
    var a = "xxx  wind"
    a.strip(chars={'x'})
    doAssert a == "  wind"

  block:
    var a = "xxx  iii"
    a.strip(chars={'i'})
    doAssert a == "xxx  "


static: teststrip()
teststrip()
