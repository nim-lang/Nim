import unittest, nre, strutils, optional_nonstrict

suite "Misc tests":
  test "unicode":
    check("".find(re"(*UTF8)").match == "")
    check("перевірка".replace(re"(*U)\w", "") == "")

  test "empty or non-empty match":
    check("abc".findall(re"|.").join(":") == ":a::b::c:")
    check("abc".findall(re".|").join(":") == "a:b:c:")

    check("abc".replace(re"|.", "x") == "xxxxxxx")
    check("abc".replace(re".|", "x") == "xxxx")

    check("abc".split(re"|.").join(":") == ":::::")
    check("abc".split(re".|").join(":") == ":::")
