discard """
  targets: "c cpp js"
"""

import std/[strbasics, sugar]


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

  block:
    var a = "xxx  iii"
    doAssert a.dup(strip(chars = {'i'})) == "xxx  "
    doAssert a.dup(strip(chars = {' '})) == "xxx  iii"
    doAssert a.dup(strip(chars = {'x'})) == "  iii"
    doAssert a.dup(strip(chars = {'x', ' '})) == "iii"
    doAssert a.dup(strip(chars = {'x', 'i'})) == "  "
    doAssert a.dup(strip(chars = {'x', 'i', ' '})).len == 0

  block:
    var a = "x  i"
    doAssert a.dup(strip(chars = {'i'})) == "x  "
    doAssert a.dup(strip(chars = {' '})) == "x  i"
    doAssert a.dup(strip(chars = {'x'})) == "  i"
    doAssert a.dup(strip(chars = {'x', ' '})) == "i"
    doAssert a.dup(strip(chars = {'x', 'i'})) == "  "
    doAssert a.dup(strip(chars = {'x', 'i', ' '})).len == 0

  block:
    var a = ""
    doAssert a.dup(strip(chars = {'i'})).len == 0
    doAssert a.dup(strip(chars = {' '})).len == 0
    doAssert a.dup(strip(chars = {'x'})).len == 0
    doAssert a.dup(strip(chars = {'x', ' '})).len == 0
    doAssert a.dup(strip(chars = {'x', 'i'})).len == 0
    doAssert a.dup(strip(chars = {'x', 'i', ' '})).len == 0

  block:
    var a = " "
    doAssert a.dup(strip(chars = {'i'})) == " "
    doAssert a.dup(strip(chars = {' '})).len == 0
    doAssert a.dup(strip(chars = {'x'})) == " "
    doAssert a.dup(strip(chars = {'x', ' '})).len == 0
    doAssert a.dup(strip(chars = {'x', 'i'})) == " "
    doAssert a.dup(strip(chars = {'x', 'i', ' '})).len == 0


  block:
    var a = "Hello, Nim!"
    doassert a.dup(setSlice(7 .. 9)) == "Nim"
    doAssert a.dup(setSlice(0 .. 0)) == "H"
    doAssert a.dup(setSlice(0 .. 1)) == "He"
    doAssert a.dup(setSlice(0 .. 10)) == a
    doAssert a.dup(setSlice(1 .. 0)).len == 0
    doAssert a.dup(setSlice(20 .. -1)).len == 0


    doAssertRaises(AssertionDefect):
      discard a.dup(setSlice(-1 .. 1))

    doAssertRaises(AssertionDefect):
      discard a.dup(setSlice(1 .. 11))

static: teststrip()
teststrip()
