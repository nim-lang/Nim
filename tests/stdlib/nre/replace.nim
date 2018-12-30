include nre
import unittest

suite "replace":
  test "replace with 0-length strings":
    check("".replace(re"1", proc (v: RegexMatch): string = "1") == "")
    check(" ".replace(re"", proc (v: RegexMatch): string = "1") == "1 1")
    check("".replace(re"", proc (v: RegexMatch): string = "1") == "1")

  test "regular replace":
    check("123".replace(re"\d", "foo") == "foofoofoo")
    check("123".replace(re"(\d)", "$1$1") == "112233")
    check("123".replace(re"(\d)(\d)", "$1$2") == "123")
    check("123".replace(re"(\d)(\d)", "$#$#") == "123")
    check("123".replace(re"(?<foo>\d)(\d)", "$foo$#$#") == "1123")
    check("123".replace(re"(?<foo>\d)(\d)", "${foo}$#$#") == "1123")

  test "replacing missing captures should throw instead of segfaulting":
    expect IndexError: discard "ab".replace(re"(a)|(b)", "$1$2")
    expect IndexError: discard "b".replace(re"(a)?(b)", "$1$2")
    expect KeyError: discard "b".replace(re"(a)?", "${foo}")
    expect KeyError: discard "b".replace(re"(?<foo>a)?", "${foo}")
