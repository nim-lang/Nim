discard """
  matrix: "; --backend:cpp; --backend:js --jsbigint64:off -d:nimStringHash2; --backend:js --jsbigint64:on"
"""


#[
Note: Macro tests are in tests/stdlib/tjsonmacro.nim
]#

import std/[json,parsejson,strutils]
import std/private/jsutils
from std/math import isNaN
when not defined(js):
  import std/streams
import stdtest/testutils
from std/fenv import epsilon
import std/[assertions, objectdollar]

proc testRoundtrip[T](t: T, expected: string) =
  # checks that `T => json => T2 => json2` is such that json2 = json
  let j = %t
  doAssert $j == expected, $j
  doAssert %(j.to(T)) == j

proc testRoundtripVal[T](t: T, expected: string) =
  # similar to testRoundtrip, but also checks that the `T => json => T2` is such that `T2 == T`
  # note that this isn't always possible, e.g. for pointer-like types or nans
  let j = %t
  doAssert $j == expected, $j
  let j2 = ($j).parseJson
  doAssert $j2 == expected, $(j2, t)
  let t2 = j2.to(T)
  doAssert t2 == t
  doAssert $(%* t2) == expected # sanity check, because -0.0 = 0.0 but their json representation differs

let testJson = parseJson"""{ "a": [1, 2, 3, 4], "b": "asd", "c": "\ud83c\udf83", "d": "\u00E6"}"""
# nil passthrough
doAssert(testJson{"doesnt_exist"}{"anything"}.isNil)
testJson{["e", "f"]} = %true
doAssert(testJson["e"]["f"].bval)

# make sure UTF-16 decoding works.
doAssert(testJson["c"].str == "🎃")
doAssert(testJson["d"].str == "æ")

# make sure no memory leek when parsing invalid string
let startMemory = getOccupiedMem()
for i in 0 .. 10000:
  try:
    discard parseJson"""{ invalid"""
  except:
    discard
# memory diff should less than 4M
doAssert(abs(getOccupiedMem() - startMemory) < 4 * 1024 * 1024)


# test `$`
let stringified = $testJson
let parsedAgain = parseJson(stringified)
doAssert(parsedAgain["b"].str == "asd")

parsedAgain["abc"] = %5
doAssert parsedAgain["abc"].num == 5

# Bounds checking
when compileOption("boundChecks"):
  try:
    let a = testJson["a"][9]
    doAssert(false, "IndexDefect not thrown")
  except IndexDefect:
    discard
  try:
    let a = testJson["a"][-1]
    doAssert(false, "IndexDefect not thrown")
  except IndexDefect:
    discard
  try:
    doAssert(testJson["a"][0].num == 1, "Index doesn't correspond to its value")
  except:
    doAssert(false, "IndexDefect thrown for valid index")

doAssert(testJson{"b"}.getStr() == "asd", "Couldn't fetch a singly nested key with {}")
doAssert(isNil(testJson{"nonexistent"}), "Non-existent keys should return nil")
doAssert(isNil(testJson{"a", "b"}), "Indexing through a list should return nil")
doAssert(isNil(testJson{"a", "b"}), "Indexing through a list should return nil")
doAssert(testJson{"a"} == parseJson"[1, 2, 3, 4]", "Didn't return a non-JObject when there was one to be found")
doAssert(isNil(parseJson("[1, 2, 3]"){"foo"}), "Indexing directly into a list should return nil")

# Generator:
var j = %* [{"name": "John", "age": 30}, {"name": "Susan", "age": 31}]
doAssert j == %[%{"name": %"John", "age": %30}, %{"name": %"Susan", "age": %31}]

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

var name = "John"
let herAge = 30
const hisAge = 31

var j3 = %*
  [ {"name": "John"
    , "age": herAge
    }
  , {"name": "Susan"
    , "age": hisAge
    }
  ]
doAssert j3 == %[%{"name": %"John", "age": %30}, %{"name": %"Susan", "age": %31}]

var j4 = %*{"test": nil}
doAssert j4 == %{"test": newJNull()}

let seqOfNodes = @[%1, %2]
let jSeqOfNodes = %seqOfNodes
doAssert(jSeqOfNodes[1].num == 2)

type MyObj = object
  a, b: int
  s: string
  f32: float32
  f64: float64
  next: ref MyObj
var m: MyObj
m.s = "hi"
m.a = 5
let jMyObj = %m
doAssert(jMyObj["a"].num == 5)
doAssert(jMyObj["s"].str == "hi")

# Test loading of file.
when not defined(js):
  var parsed = parseFile("tests/testdata/jsontest.json")

  try:
    discard parsed["key2"][12123]
    doAssert(false)
  except IndexDefect: doAssert(true)

  var parsed2 = parseFile("tests/testdata/jsontest2.json")
  doAssert(parsed2{"repository", "description"}.str ==
      "IRC Library for Haskell", "Couldn't fetch via multiply nested key using {}")

doAssert escapeJsonUnquoted("\10Foo🎃barÄ") == "\\nFoo🎃barÄ"
doAssert escapeJsonUnquoted("\0\7\20") == "\\u0000\\u0007\\u0014" # for #7887
doAssert escapeJson("\10Foo🎃barÄ") == "\"\\nFoo🎃barÄ\""
doAssert escapeJson("\0\7\20") == "\"\\u0000\\u0007\\u0014\"" # for #7887

# Test with extra data
when not defined(js):
  try:
    discard parseJson("123 456")
    doAssert(false)
  except JsonParsingError:
    doAssert getCurrentExceptionMsg().contains(errorMessages[errEofExpected])

  try:
    discard parseFile("tests/testdata/jsonwithextradata.json")
    doAssert(false)
  except JsonParsingError:
    doAssert getCurrentExceptionMsg().contains(errorMessages[errEofExpected])

# bug #6438
doAssert($ %*[] == "[]")
doAssert($ %*{} == "{}")

doAssert(not compiles(%{"error": "No messages"}))

# bug #9111
block:
  type
    Bar = string
    Foo = object
      a: int
      b: Bar

  let
    js = """{"a": 123, "b": "abc"}""".parseJson
    foo = js.to Foo

  doAssert(foo.b == "abc")

# Generate constructors for range[T] types
block:
  type
    Q1 = range[0'u8 .. 50'u8]
    Q2 = range[0'u16 .. 50'u16]
    Q3 = range[0'u32 .. 50'u32]
    Q4 = range[0'i8 .. 50'i8]
    Q5 = range[0'i16 .. 50'i16]
    Q6 = range[0'i32 .. 50'i32]
    Q7 = range[0'f32 .. 50'f32]
    Q8 = range[0'f64 .. 50'f64]
    Q9 = range[0 .. 50]

    X = object
      m1: Q1
      m2: Q2
      m3: Q3
      m4: Q4
      m5: Q5
      m6: Q6
      m7: Q7
      m8: Q8
      m9: Q9

  let obj = X(
    m1: Q1(42),
    m2: Q2(42),
    m3: Q3(42),
    m4: Q4(42),
    m5: Q5(42),
    m6: Q6(42),
    m7: Q7(42),
    m8: Q8(42),
    m9: Q9(42)
  )

  doAssert(obj == to(%obj, type(obj)))

  when not defined(js):
    const fragments = """[1,2,3] {"hi":3} 12 [] """
    var res = ""
    for x in parseJsonFragments(newStringStream(fragments)):
      res.add($x)
      res.add " "
    doAssert res == fragments


# test isRefSkipDistinct
type
  MyRef = ref object
  MyObject = object
  MyDistinct = distinct MyRef
  MyOtherDistinct = distinct MyRef

var x0: ref int
var x1: MyRef
var x2: MyObject
var x3: MyDistinct
var x4: MyOtherDistinct

doAssert isRefSkipDistinct(x0)
doAssert isRefSkipDistinct(x1)
doAssert not isRefSkipDistinct(x2)
doAssert isRefSkipDistinct(x3)
doAssert isRefSkipDistinct(x4)


doAssert isRefSkipDistinct(ref int)
doAssert isRefSkipDistinct(MyRef)
doAssert not isRefSkipDistinct(MyObject)
doAssert isRefSkipDistinct(MyDistinct)
doAssert isRefSkipDistinct(MyOtherDistinct)

let x = parseJson("9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999")

doAssert x.kind == JString

block: # bug #15835
  type
    Foo = object
      ii*: int
      data*: JsonNode

  block:
    const jt = """{"ii": 123, "data": ["some", "data"]}"""
    let js = parseJson(jt)
    discard js.to(Foo)

  block:
    const jt = """{"ii": 123}"""
    let js = parseJson(jt)
    doAssertRaises(KeyError):
      echo js.to(Foo)

type
  ContentNodeKind* = enum
    P,
    Br,
    Text,
  ContentNode* = object
    case kind*: ContentNodeKind
    of P: pChildren*: seq[ContentNode]
    of Br: nil
    of Text: textStr*: string

let mynode = ContentNode(kind: P, pChildren: @[
  ContentNode(kind: Text, textStr: "mychild"),
  ContentNode(kind: Br)
])

doAssert $mynode == """(kind: P, pChildren: @[(kind: Text, textStr: "mychild"), (kind: Br)])"""

let jsonNode = %*mynode
doAssert $jsonNode == """{"kind":"P","pChildren":[{"kind":"Text","textStr":"mychild"},{"kind":"Br"}]}"""
doAssert $jsonNode.to(ContentNode) == """(kind: P, pChildren: @[(kind: Text, textStr: "mychild"), (kind: Br)])"""

block: # bug #17383
  testRoundtrip(int32.high): "2147483647"
  testRoundtrip(uint32.high): "4294967295"
  when int.sizeof == 4:
    testRoundtrip(int.high): "2147483647"
    testRoundtrip(uint.high): "4294967295"
  else:
    testRoundtrip(int.high): "9223372036854775807"
    testRoundtrip(uint.high): "18446744073709551615"
  when hasWorkingInt64:
    testRoundtrip(int64.high): "9223372036854775807"
    testRoundtrip(uint64.high): "18446744073709551615"

block: # bug #18007
  testRoundtrip([NaN, Inf, -Inf, 0.0, -0.0, 1.0]): """["nan","inf","-inf",0.0,-0.0,1.0]"""
  # pending https://github.com/nim-lang/Nim/issues/18025 use:
  # testRoundtrip([float32(NaN), Inf, -Inf, 0.0, -0.0, 1.0])
  let inf = float32(Inf)
  testRoundtrip([float32(NaN), inf, -inf, 0.0, -0.0, 1.0]): """["nan","inf","-inf",0.0,-0.0,1.0]"""
  when not defined(js): # because of Infinity vs inf
    testRoundtripVal([inf, -inf, 0.0, -0.0, 1.0]): """["inf","-inf",0.0,-0.0,1.0]"""
  let a = parseJson($(%NaN)).to(float)
  doAssert a.isNaN

  whenRuntimeJs: discard # refs bug #18009
  do:
    testRoundtripVal(0.0): "0.0"
    testRoundtripVal(-0.0): "-0.0"

block: # bug #15397, bug #13196
  testRoundtripVal(1.0 + epsilon(float64)): "1.0000000000000002"
  testRoundtripVal(0.12345678901234567890123456789): "0.12345678901234568"

block:
  let a = "18446744073709551615"
  let b = a.parseJson
  doAssert b.kind == JString
  let c = $b
  when defined(js):
    doAssert c == "18446744073709552000"
  else:
    doAssert c == "18446744073709551615"

block:
  let a = """
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
    [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
"""

  when not defined(js):
    try:
      discard parseJson(a)
    except JsonParsingError:
      doAssert getCurrentExceptionMsg().contains("] expected")

block: # getStr, getInt, getBiggestInt, getFloat, getBool, getFields, getElems:
       # the value of a node of the matching kind, `default` for any other kind and for nil
  let nilNode: JsonNode = nil

  doAssert newJString("a").getStr("d") == "a"
  doAssert newJInt(1).getStr("d") == "d"
  doAssert nilNode.getStr("d") == "d"
  doAssert newJString("a").getStr == "a"
  doAssert nilNode.getStr == ""

  doAssert newJInt(5).getInt(7) == 5
  doAssert newJString("x").getInt(7) == 7
  doAssert newJFloat(1.5).getInt(7) == 7
  doAssert nilNode.getInt(7) == 7
  doAssert nilNode.getInt == 0

  doAssert newJInt(5).getBiggestInt(7) == 5
  doAssert newJString("x").getBiggestInt(7) == 7
  doAssert newJFloat(1.5).getBiggestInt(7) == 7
  doAssert nilNode.getBiggestInt(7) == 7
  doAssert nilNode.getBiggestInt == 0

  doAssert newJFloat(1.5).getFloat(9.5) == 1.5
  doAssert newJInt(2).getFloat(9.5) == 2.0 # a JInt is a valid float value
  doAssert newJString("x").getFloat(9.5) == 9.5
  doAssert newJBool(true).getFloat(9.5) == 9.5
  doAssert nilNode.getFloat(9.5) == 9.5
  doAssert nilNode.getFloat == 0.0

  doAssert newJBool(true).getBool(false)
  doAssert not newJBool(false).getBool(true)
  doAssert newJInt(1).getBool(true)
  doAssert not newJInt(1).getBool(false)
  doAssert nilNode.getBool(true)
  doAssert not nilNode.getBool

  let obj = %*{"a": 1, "b": 2}
  doAssert obj.getFields.len == 2
  doAssert obj.getFields["a"].getInt == 1
  doAssert newJArray().getFields.len == 0
  doAssert newJString("x").getFields(obj.fields).len == 2
  doAssert nilNode.getFields(obj.fields).len == 2
  doAssert nilNode.getFields.len == 0

  let arr = %*[1, 2, 3]
  doAssert arr.getElems.len == 3
  doAssert arr.getElems[2].getInt == 3
  doAssert newJObject().getElems.len == 0
  doAssert newJString("x").getElems(@[newJInt(9)]).len == 1
  doAssert nilNode.getElems(@[newJInt(9)]).len == 1
  doAssert nilNode.getElems.len == 0

block: # `hasKey`, `contains` on an object and on an array, `delete`
  let obj = %*{"a": 1, "b": nil}
  doAssert obj.hasKey("a")
  doAssert obj.hasKey("b")
  doAssert not obj.hasKey("c")
  doAssert "a" in obj
  doAssert "c" notin obj
  let arr = %*[1, "x", nil]
  doAssert newJInt(1) in arr
  doAssert newJString("x") in arr
  doAssert newJNull() in arr
  doAssert newJInt(2) notin arr
  doAssert newJString("1") notin arr
  obj.delete("a")
  doAssert not obj.hasKey("a")
  doAssert obj.hasKey("b")
  doAssert obj.len == 1
  doAssertRaises(KeyError): obj.delete("a")
  doAssert obj.len == 1

block: # `{}` with several indexes: out of range, a non-array in between, nil; `{}=` creates the path
  let j = %*[[1, 2], [3]]
  doAssert j{0}.len == 2
  doAssert j{0, 1}.getInt == 2
  doAssert j{1, 0}.getInt == 3
  doAssert j{2}.isNil
  doAssert j{0, 2}.isNil
  doAssert j{0, 0, 0}.isNil # `1` is not an array
  doAssert j{5, 0}.isNil
  doAssert newJObject(){0}.isNil
  doAssert newJString("x"){0}.isNil
  let nilNode: JsonNode = nil
  doAssert nilNode{0}.isNil
  let o = newJObject()
  o{"a", "b"} = newJInt(1)
  doAssert $o == """{"a":{"b":1}}"""
  o{"a", "c"} = newJInt(2)
  doAssert $o == """{"a":{"b":1,"c":2}}"""
  o{"x", "y", "z"} = newJInt(3)
  doAssert $o == """{"a":{"b":1,"c":2},"x":{"y":{"z":3}}}"""

block: # parseJson nests as deep as DepthLimit allows
  when not defined(js):
    template nested(n: int): string = "[".repeat(n) & "]".repeat(n)
    doAssert parseJson(nested(1001)).kind == JArray
    doAssertRaises(JsonParsingError): discard parseJson(nested(1002))
    template nestedObj(n: int): string = "{\"a\":".repeat(n) & "1" & "}".repeat(n)
    doAssert parseJson(nestedObj(1001)).kind == JObject
    doAssertRaises(JsonParsingError): discard parseJson(nestedObj(1002))

block: # parseJson rejects a non-string key and a token that cannot start a value
  when not defined(js):
    doAssertRaises(JsonParsingError): discard parseJson("{1: 2}")
    for s in ["]", "}", ",", ":", ""]:
      doAssertRaises(JsonParsingError): discard parseJson(s)

block: # `pretty`: nested containers, empty containers, the indent width
  let j = parseJson("""{"a": [1, {"b": true}], "c": {}, "d": [], "e": "x"}""")
  doAssert j.pretty == """{
  "a": [
    1,
    {
      "b": true
    }
  ],
  "c": {},
  "d": [],
  "e": "x"
}"""
  doAssert j.pretty(4) == """{
    "a": [
        1,
        {
            "b": true
        }
    ],
    "c": {},
    "d": [],
    "e": "x"
}"""
  doAssert newJArray().pretty == "[]"
  doAssert parseJson("[1, 2]").pretty == "[\n  1,\n  2\n]"
  doAssert parseJson("""[1.5, null, false, "s"]""").pretty == "[\n  1.5,\n  null,\n  false,\n  \"s\"\n]"

block: # escapeJson of the control characters, quotes and backslashes; `copy` is deep
  doAssert escapeJson("a\"b\\c") == "\"a\\\"b\\\\c\""
  doAssert escapeJson("\b\f\t\r\n") == "\"\\b\\f\\t\\r\\n\""
  doAssert escapeJson("\v") == "\"\\u000b\""
  let a = %*[[1], {"k": [2]}]
  let b = a.copy
  doAssert a == b
  b[0].add(%3)
  b[1]["k"].add(%4)
  doAssert a == %*[[1], {"k": [2]}]
  doAssert b == %*[[1, 3], {"k": [2, 4]}]

block: # `[]` with a BackwardsIndex and with a slice
  let arr = %[0, 1, 2, 3, 4, 5]
  doAssert arr[^1] == %5
  doAssert arr[^2] == %4
  doAssert arr[^6] == %0
  doAssert arr[2 .. 4] == %[2, 3, 4]
  doAssert arr[2 ..^ 2] == %[2, 3, 4]
  doAssert arr[^4 ..^ 2] == %[2, 3, 4]
  doAssert arr[0 .. 0] == %[0]
  doAssert arr[0 ..< 3] == %[0, 1, 2]
  doAssert arr[3 .. 2] == newJArray()

block: # `==`: nil, nodes of different kinds, arrays, objects
  let nilNode: JsonNode = nil
  doAssert nilNode == nilNode
  doAssert nilNode != newJNull()
  doAssert newJNull() != nilNode
  doAssert newJNull() == newJNull()
  doAssert newJInt(1) != newJString("1")
  doAssert newJInt(1) != newJFloat(1.0)
  doAssert newJString("a") == newJString("a")
  doAssert newJString("a") != newJString("b")
  doAssert newJInt(1) == newJInt(1)
  doAssert newJInt(1) != newJInt(2)
  doAssert newJFloat(1.5) == newJFloat(1.5)
  doAssert newJFloat(1.5) != newJFloat(2.5)
  doAssert newJBool(true) == newJBool(true)
  doAssert newJBool(true) != newJBool(false)
  doAssert %*[1, 2] == %*[1, 2]
  doAssert %*[1, 2] != %*[2, 1]
  doAssert %*[1, 2] != %*[1]
  doAssert %*{"a": 1, "b": 2} == %*{"b": 2, "a": 1} # the order of the keys does not matter
  doAssert %*{"a": 1, "b": 2} != %*{"a": 1, "b": 3}
  doAssert %*{"a": 1, "b": 2} != %*{"a": 1}
  doAssert %*{"a": 1, "b": 2} != %*{"a": 1, "c": 2}

block: # `%` of an unsigned integer: a JInt up to high(int), a raw number above; `%*{}`
  when not defined(js):
    doAssert (%(cast[uint](int.high))).kind == JInt
    doAssert $(%(cast[uint](int.high) + 1)) == "9223372036854775808"
    doAssert (%(cast[BiggestUInt](BiggestInt.high))).kind == JInt
    doAssert $(%(cast[BiggestUInt](BiggestInt.high) + 1)) == "9223372036854775808"
  doAssert (%*{}).kind == JObject
  doAssert $(%*{}) == "{}"
