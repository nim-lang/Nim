discard """
  targets: "c cpp js"
  matrix: "--gc:refc; --gc:arc"
"""

import std/[strbasics, sugar]

template strip2(input: string, args: varargs[untyped]): untyped =
  var a = input
  when varargsLen(args) > 0:
    strip(a, args)
  else:
    strip(a)
  a

proc main() =
  block: # strip
    block: # bug #17173
      var a = "  vhellov   "
      strip(a)
      doAssert a == "vhellov"

    doAssert strip2("  vhellov   ") == "vhellov"
    doAssert strip2("  vhellov   ", leading = false) == "  vhellov"
    doAssert strip2("  vhellov   ", trailing = false) == "vhellov   "
    doAssert strip2("vhellov", chars = {'v'}) == "hello"
    doAssert strip2("vhellov", leading = false, chars = {'v'}) == "vhello"
    doAssert strip2("blaXbla", chars = {'b', 'a'}) == "laXbl"
    doAssert strip2("blaXbla", chars = {'b', 'a', 'l'}) == "X"
    doAssert strip2("xxxxxx", chars={'x'}) == ""
    doAssert strip2("x", chars={'x'}) == ""
    doAssert strip2("x", chars={'1'}) == "x"
    doAssert strip2("", chars={'x'}) == ""
    doAssert strip2("xxx xxx", chars={'x'}) == " "
    doAssert strip2("xxx  wind", chars={'x'}) == "  wind"
    doAssert strip2("xxx  iii", chars={'i'}) == "xxx  "

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

  block: # setSlice
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

  block: # add
    var a0 = "hi"
    var b0 = "foobar"
    when nimvm:
      discard # pending bug #15952
    else:
      a0.add b0.toOpenArray(1,3)
      doAssert a0 == "hioob"
    proc fn(c: openArray[char]): string =
      result.add c
    doAssert fn("def") == "def"
    doAssert fn(['d','\0', 'f'])[2] == 'f'

  block:
    doAssert isUpperAscii('e') == false
    doAssert isUpperAscii('E') == true
    doAssert isUpperAscii('7') == false

    doAssert isLowerAscii('e') == true
    doAssert isLowerAscii('E') == false
    doAssert isLowerAscii('7') == false

  block:
    var x = "FooBar!"
    doAssert x.dup(toLowerAscii) == "foobar!"

  block:
    var x = "FooBar!"
    doAssert x.dup(toUpperAscii) == "FOOBAR!"

  block:
    var x = "12345"
    var y = ""

    forceCopy(y, x)
    doAssert y == x

static: main()
main()

# when not defined(js):
#   block: # setLen
#     var a = "abc"
#     a.setLen 0
#     a.setLen 3, isInit = false
#     doAssert a[1] == 'b'
#     a.setLen 0
#     a.setLen 3, isInit = true
#     doAssert a[1] == '\0'

#   block: # forceCopy
#     var a: string
#     a = "foo"
#     shallow(a)
#     var b: string
#     b = a
#     doAssert b[0].addr == a[0].addr
#     var c: string
#     c.forceCopy a
#     doAssert c == a
#     doAssert c[0].addr != a[0].addr

#   block: # dataPointer
#     var a: string
#     discard a.dataPointer
#     # doAssert a.dataPointer == nil # not guaranteed
