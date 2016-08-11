import json, unittest
import strutils

suite "json":

  setup:
    let smallsample = parseJson"""{ "a": [1, 2, 3, 4]}"""
    let sample = parseJson"""{ "a": [1, 2, 3, 4], "b": "asd", "c": "\ud83c\udf83", "d": "\u00E6"}"""

  test "generator1":
    var j = %* [{"name": "John", "age": 30}, {"name": "Susan", "age": 31}]
    doAssert j == %[%{"name": %"John", "age": %30}, %{"name": %"Susan", "age": %31}]

  test "generator2":
    var j2 = %*
      [
        {
          "name": "John",
          "age": 30
        },
        {
          "name": "Susan",
          "age": 31
        }
      ]
    doAssert j2 == %[%{"name": %"John", "age": %30}, %{"name": %"Susan", "age": %31}]

  test "parsing":
    let testJson = parseJson"""{ "a": [1, 2, 3, 4], "b": "asd", "c": "\ud83c\udf83", "d": "\u00E6"}"""
    # nil passthrough
    doAssert(testJson{"doesnt_exist"}{"anything"}.isNil)
    testJson{["e", "f"]} = %true
    doAssert(testJson["e"]["f"].bval)

    # make sure UTF-16 decoding works.
    when not defined(js): # TODO: The following line asserts in JS
      doAssert(testJson["c"].str == "🎃")
    doAssert(testJson["d"].str == "æ")


    # test `$`
    let stringified = $testJson
    let parsedAgain = parseJson(stringified)
    doAssert(parsedAgain["b"].str == "asd")

    parsedAgain["abc"] = %5
    doAssert parsedAgain["abc"].num == 5

  test "pretty, simple":
    let p = smallsample.pretty()
    let q = p.replace("\n", "\\n")
    doAssert q == """{\n  "a": [\n    1, \n    2, \n    3, \n    4\n  ]\n}"""
  test "pretty, indent 1":
    let p = smallsample.pretty(indent=1)
    let q = p.replace("\n", "\\n")
    doAssert q == """{\n "a": [\n  1, \n  2, \n  3, \n  4\n ]\n}"""

  test "pretty, indent 0":
    let p = smallsample.pretty(indent=0)
    let q = p.replace("\n", "\\n")
    doAssert q == """{\n"a": [\n1, \n2, \n3, \n4\n]\n}"""

  test "pretty, sorted":
    let j = parseJson"""{"d": 4, "e": 5, "a": 1, "c": 3, "b": 2, "f": 6}"""
    let p = j.pretty(sort_keys=true)
    let q = p.replace("\n", "").replace(" ", "")
    doAssert q == """{"a":1,"b":2,"c":3,"d":4,"e":5,"f":6}""", "Incorrect key order: $#" % q

  test "pretty, sorted, nested":
    let j = parseJson"""{"c": 1, "b": [{"1": 1, "0": 0, "2": 2}]}"""
    let p = j.pretty(sort_keys=true)
    let q = p.replace("\n", "").replace(" ", "")
    doAssert q == """{"b":[{"0":0,"1":1,"2":2}],"c":1}""", "Incorrect key order: $#" % q





