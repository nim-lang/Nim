import unittest, nre, strutils, optional_nonstrict

block: # Misc tests
  block: # unicode
    check("".find(re"(*UTF8)").match == "")
    check("перевірка".replace(re"(*U)\w", "") == "")

  block: # empty or non-empty match
    check("abc".findAll(re"|.").join(":") == ":a::b::c:")
    check("abc".findAll(re".|").join(":") == "a:b:c:")

    check("abc".replace(re"|.", "x") == "xxxxxxx")
    check("abc".replace(re".|", "x") == "xxxx")

    check("abc".split(re"|.").join(":") == ":::::")
    check("abc".split(re".|").join(":") == ":::")
