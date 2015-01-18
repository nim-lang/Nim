include nre
import unittest

suite "replace":
  test "replace with 0-length strings":
    check("".replace(re"1", proc (v: RegexMatch): string = "1") == "")
    check(" ".replace(re"", proc (v: RegexMatch): string = "1") == "1 ")
    check("".replace(re"", proc (v: RegexMatch): string = "1") == "1")

  test "regular replace":
    check("123".replace(re"\d", "foo") == "foofoofoo")
    check("123".replace(re"(\d)", "$1$1") == "112233")
    check("123".replace(re"(\d)(\d)", "$1$2") == "123")
