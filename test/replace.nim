include nre
import unittest

suite "replace":
  test "replace with 0-length strings":
    check("".replace(re"1", proc (v: RegexMatch): string = "1") == "")
    check(" ".replace(re"", proc (v: RegexMatch): string = "1") == "1 ")
    check("".replace(re"", proc (v: RegexMatch): string = "1") == "1")
