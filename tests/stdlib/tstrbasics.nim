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

proc runtimeMain() =
  block: # indexOf
    block:
      const haystack: string = "0123456789ABCDEFGH"
      doAssert haystack.len == 18

      doAssert haystack.indexOf('A') == 10
      doAssert haystack.toOpenArray(5, 17).indexOf('A') == 5
      doAssert haystack.toOpenArray(5, 9).indexOf('A') == -1
      doAssert haystack.toOpenArray(5, haystack.high).indexOf("A") == 5
      doAssert haystack.toOpenArray(5, 9).indexOf("A") == -1

      doAssert haystack.indexOf({'A'..'C'}) == 10
      doAssert haystack.toOpenArray(5, haystack.high).indexOf({'A'..'C'}) == 5
      doAssert haystack.toOpenArray(5, 10).indexOf({'A'..'C'}) == 5
      doAssert haystack.toOpenArray(5, 9).indexOf({'A'..'C'}) == -1

    block:
      const haystack: string = "ABCABABABABCAB"
      doAssert len(haystack) == 14

      doAssert haystack.indexOf("ABC") == 0
      doAssert haystack.toOpenArray(0, 13).indexOf("ABC") == 0
      doAssert haystack.toOpenArray(1, 13).indexOf("ABC") == 8
      doAssert haystack.toOpenArray(9, 13).indexOf("ABC") == 0
      doAssert haystack.toOpenArray(10, 13).indexOf("ABC") == -1

      doAssert haystack.toOpenArray(0, 12).indexOf("ABC") == 0
      doAssert haystack.toOpenArray(1, 12).indexOf("ABC") == 8
      doAssert haystack.toOpenArray(1, 11).indexOf("ABC") == 8
      doAssert haystack.toOpenArray(1, 10).indexOf("ABC") == -1
      doAssert haystack.toOpenArray(1, 3).indexOf("ABC") == -1

    block:
      const haystack: seq[char] = @['a', 'b', 'c']
      doAssert haystack.indexOf("abc") == 0
      doAssert haystack.indexOf("abcd".toOpenArray(0, 3)) == -1

      const needle: seq[char] = @['a', 'b', 'c', 'd']
      doAssert haystack.indexOf(needle.toOpenArray(0, 3)) == -1
      doAssert haystack.indexOf(needle.toOpenArray(0, 2)) == 0
      doAssert haystack.indexOf(needle.toOpenArray(0, 1)) == 0
      doAssert haystack.indexOf(needle.toOpenArray(1, 2)) == 1

    # searching for empty string
    doAssert "".indexOf("") == 0
    doAssert "abc".toOpenArray(1, 2).indexOf("") == 0
    doAssert "abc".toOpenArray(2, 2).indexOf("") == 0

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

  block: # indexOf
    block:
      const haystack: string = "0123456789ABCDEFGH"
      doAssert haystack.len == 18

      doAssert haystack.indexOf("A") == 10
      doAssert haystack.indexOf({'A'..'C'}) == 10

    block:
      const haystack: string = "ABCABABABABCAB"
      doAssert len(haystack) == 14

      doAssert haystack.indexOf("ABC") == 0

    block: # using seq
      const haystack: seq[char] = @['a', 'b', 'c']
      doAssert haystack.indexOf("abc") == 0

      doAssert haystack.indexOf(@['a', 'b', 'c']) == 0
      doAssert haystack.indexOf(@['b', 'c']) == 1
      doAssert haystack.indexOf(@['a', 'b', 'c', 'd']) == -1

    doAssert "".indexOf("/") == -1
    doAssert "/".indexOf("/") == 0
    doAssert "/".indexOf("//") == -1

    # searching for empty string
    doAssert "".indexOf("") == 0
    doAssert "abc".indexOf("") == 0

static: main()
main()
runtimeMain()
