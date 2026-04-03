import std/[assertions, options, sequtils]
import std/nre2

block:
  let pattern = "[0-9"
  doAssertRaises(RegexError): discard re(pattern)

block: # match
  block: # upper bound must be inclusive
    doAssert "abc".match(re"abc", endpos = -1) == none(RegexMatch)
    doAssert "abc".match(re"abc", endpos = 1) == none(RegexMatch)
    doAssert "abc".match(re"abc", endpos = 2) != none(RegexMatch)

  block: # match examples
    doAssert "abc".match(re"(\w)+").get.captures[0] == "c"
    doAssert "abc".match(re"(?P<letter>\w)+").get.captures["letter"] == "c"
    doAssert "abc".match(re"(\w)\w\w").get.captures[-1] == "abc"
    doAssert "abc".match(re"(\w)+").get.captureBounds[0] == 2 .. 2
    doAssert "abc".match(re"abc").get.captureBounds[-1] == 0 .. 2
    let cap1 = "abc".match(re"(\w)(\w)+").get.captures
    doAssert cap1.len == 2
    doAssert 0 in cap1
    doAssert 1 in cap1
    doAssert cap1[0] == "a" and cap1[1] == "c"
    doAssert 0 in "abc".match(re"(\w)+").get.captureBounds

  block: # match test cases
    let mat1 = "123".match(re"123").get
    doAssert mat1.matchBounds == 0 .. 2
    doAssert mat1.match == "123"

block: # find
  block: # find text
    doAssert "3213a".find(re"[a-z]").get.match == "a"
    doAssert toSeq(findIter("1 2 3 4 5 6 7 8 ", re" ")).mapIt(
      it.match
    ) == @[" ", " ", " ", " ", " ", " ", " ", " "]

  block: # find bounds
    doAssert toSeq(findIter("1 2 3 4 5 ", re" ")).mapIt(
      it.matchBounds
    ) == @[1..1, 3..3, 5..5, 7..7, 9..9]

  block: # overlapping find
    doAssert "222".findAll(re"22") == @["22"]
    doAssert "2222".findAll(re"22") == @["22", "22"]

  block: # len 0 find
    doAssert "".findAll(re"\ ") == newSeq[string]()
    doAssert "".findAll(re"") == @[""]
    doAssert "abc".findAll(re"") == @["", "", "", ""]
    doAssert "word word".findAll(re"\b") == @["", "", "", ""]
    #doAssert "word\r\lword".findAll(re"(*ANYCRLF)(?m)$") == @["", ""]
    doAssert "word\r\lword".findAll(re"(?m)$") == @["", ""]
    #doAssert "слово слово".findAll(re"(*U)\b") == @["", "", "", ""]

block: # contains
  doAssert "abc".contains(re"bc")
  doAssert not "abc".contains(re"cd")
  doAssert not "abc".contains(re"a", start = 1)

block: # string splitting
  block: # splitting strings
    doAssert "1 2 3 4 5 6 ".split(re" ") == @["1", "2", "3", "4", "5", "6", ""]
    doAssert "1  2  ".split(re(" ")) == @["1", "", "2", "", ""]
    doAssert "1 2".split(re(" ")) == @["1", "2"]
    doAssert "foo".split(re("foo")) == @["", ""]
    doAssert "".split(re"foo") == @[""]
    doAssert "9".split(re"\son\s") == @["9"]

  block: # captured patterns
    doAssert "12".split(re"(\d)") == @["", "1", "", "2", ""]

  #[
  block: # maxsplit
    check("123".split(re"", maxsplit = 2) == @["1", "23"])
    check("123".split(re"", maxsplit = 1) == @["123"])
    check("123".split(re"", maxsplit = -1) == @["1", "2", "3"])
  ]#

  block: # split with 0-length match
    doAssert "12345".split(re("")) == @["1", "2", "3", "4", "5"]
    doAssert "".split(re"") == newSeq[string]()
    doAssert "word word".split(re"\b") == @["word", " ", "word"]
    #doAssert "word\r\lword".split(re"(*ANYCRLF)(?m)$") == @["word", "\r\lword"]
    #doAssert "слово слово".split(re"(*U)(\b)") == @["", "слово", "", " ", "", "слово", ""]

  #[
  block: # perl split tests
    doAssert "forty-two"                    .split(re"")      .join(",") == "f,o,r,t,y,-,t,w,o"
    doAssert "forty-two"                    .split(re"", 3)   .join(",") == "f,o,rty-two"
    doAssert "split this string"            .split(re" ")     .join(",") == "split,this,string"
    doAssert "split this string"            .split(re" ", 2)  .join(",") == "split,this string"
    doAssert "try$this$string"              .split(re"\$")    .join(",") == "try,this,string"
    doAssert "try$this$string"              .split(re"\$", 2) .join(",") == "try,this$string"
    doAssert "comma, separated, values"     .split(re", ")    .join("|") == "comma|separated|values"
    doAssert "comma, separated, values"     .split(re", ", 2) .join("|") == "comma|separated, values"
    doAssert "Perl6::Camelia::Test"         .split(re"::")    .join(",") == "Perl6,Camelia,Test"
    doAssert "Perl6::Camelia::Test"         .split(re"::", 2) .join(",") == "Perl6,Camelia::Test"
    doAssert "split,me,please"              .split(re",")     .join("|") == "split|me|please"
    doAssert "split,me,please"              .split(re",", 2)  .join("|") == "split|me,please"
    doAssert "Hello World    Goodbye   Mars".split(re"\s+")   .join(",") == "Hello,World,Goodbye,Mars"
    doAssert "Hello World    Goodbye   Mars".split(re"\s+", 3).join(",") == "Hello,World,Goodbye   Mars"
    doAssert "Hello test"                   .split(re"(\s+)") .join(",") == "Hello, ,test"
    doAssert "this will be split"           .split(re" ")     .join(",") == "this,will,be,split"
    doAssert "this will be split"           .split(re" ", 3)  .join(",") == "this,will,be split"
    doAssert "a.b"                          .split(re"\.")    .join(",") == "a,b"
    doAssert ""                             .split(re"")      .len       == 0
    doAssert ":"                            .split(re"")      .len       == 1
  ]#

  block: # start position
    doAssert "abc".split(re"", start = 1) == @["b", "c"]
    doAssert "abc".split(re"", start = 2) == @["c"]
    doAssert "abc".split(re"", start = 3) == newSeq[string]()

block: # replace
  block: # replace with 0-length strings
    doAssert "".replace(re"1", proc (v: RegexMatch): string = "1") == ""
    doAssert " ".replace(re"", proc (v: RegexMatch): string = "1") == "1 1"
    doAssert "".replace(re"", proc (v: RegexMatch): string = "1") == "1"

  block: # regular replace
    doAssert "123".replace(re"\d", "foo") == "foofoofoo"
    doAssert "123".replace(re"(\d)", "$1$1") == "112233"
    doAssert "123".replace(re"(\d)(\d)", "$1$2") == "123"
    doAssert "123".replace(re"(\d)(\d)", "$#$#") == "123"
    #doAssert "123".replace(re"(?P<foo>\d)(\d)", "$foo$#$#") == "1123"
    #doAssert "123".replace(re"(?P<foo>\d)(\d)", "${foo}$#$#") == "1123"
    doAssert "abcdefghijklm".replace(re"(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)", "$12") == "l"

  block: # replacing missing captures should throw instead of segfaulting
    doAssertRaises(ValueError): discard "ab".replace(re"(a)", "$1$2")
    #[
    expect IndexDefect: discard "ab".replace(re"(a)|(b)", "$1$2")
    expect IndexDefect: discard "b".replace(re"(a)?(b)", "$1$2")
    expect KeyError: discard "b".replace(re"(a)?", "${foo}")
    expect KeyError: discard "b".replace(re"(?<foo>a)?", "${foo}")
    ]#

  #[
  block: # malformed replacement syntax should throw instead of OOB crash
    expect ValueError: discard "a".replace(re"a", "$")
    expect ValueError: discard "a".replace(re"a", "x$")
    expect ValueError: discard "a".replace(re"a", "${foo")
  ]#
