discard """
  output: "DONE: tostring.nim"
"""

doAssert "@[23, 45]" == $(@[23, 45])
doAssert "[32, 45]" == $([32, 45])
doAssert """@["", "foo", "bar"]""" == $(@["", "foo", "bar"])
doAssert """["", "foo", "bar"]""" == $(["", "foo", "bar"])
doAssert """["", "foo", "bar"]""" == $(@["", "foo", "bar"].toOpenArray(0, 2))

# bug #2395
let alphaSet: set[char] = {'a'..'c'}
doAssert "{'a', 'b', 'c'}" == $alphaSet
doAssert "2.3242" == $(2.3242)
doAssert "2.982" == $(2.982)
doAssert "123912.1" == $(123912.1)
doAssert "123912.1823" == $(123912.1823)
doAssert "5.0" == $(5.0)
doAssert "1e+100" == $(1e100)
doAssert "inf" == $(1e1000000)
doAssert "-inf" == $(-1e1000000)
doAssert "nan" == $(0.0/0.0)

# nil tests
# maybe a bit inconsistent in types
var x: seq[string]
doAssert "@[]" == $(x)

var y: string
doAssert "" == $(y)

type
  Foo = object
    a: int
    b: string

var foo1: Foo

doAssert $foo1 == "(a: 0, b: \"\")"

const
  data = @['a','b', '\0', 'c','d']
  dataStr = $data

# ensure same result when on VM or when at program execution
doAssert dataStr == $data

# array test

let arr = ['H','e','l','l','o',' ','W','o','r','l','d','!','\0']
doAssert $arr == "['H', 'e', 'l', 'l', 'o', ' ', 'W', 'o', 'r', 'l', 'd', '!', '\\x00']"
doAssert $cstring(unsafeAddr arr) == "Hello World!"

proc takes(c: cstring) =
  doAssert c == cstring""

proc testm() =
  var x: string
  # nil is mapped to "":
  takes(x)

testm()

# nil tests
var xx: seq[string]
var yy: string
doAssert xx == @[]
doAssert yy == ""

proc bar(arg: cstring) =
  doAssert arg[0] == '\0'

proc baz(arg: openarray[char]) =
  doAssert arg.len == 0

proc stringCompare() =
  var a,b,c,d,e,f,g: string
  a.add 'a'
  doAssert a == "a"
  b.add "bee"
  doAssert b == "bee"
  b.add g
  doAssert b == "bee"
  c.addFloat 123.456
  doAssert c == "123.456"
  d.addInt 123456
  doAssert d == "123456"

  doAssert e == ""
  doAssert "" == e
  doAssert f == g
  doAssert "" == ""

  g.setLen(10)
  doAssert g == "\0\0\0\0\0\0\0\0\0\0"
  doAssert "" != "\0\0\0\0\0\0\0\0\0\0"

  var nilstring: string
  #bar(nilstring)
  baz(nilstring)

stringCompare()
var nilstring: string
bar(nilstring)

static:
  stringCompare()

# bug 8847
var a2: cstring = "fo\"o2"

block:
  var s: string
  s.addQuoted a2
  doAssert s == "\"fo\\\"o2\""

type
  MyType = object
    a: int
    b: string

  MyRef = ref MyType
  MyDistinct = distinct MyType

  MyRefDistinct = ref MyDistinct
  MyDistinctRef = distinct MyRef

  MyCompoundObject = object
    field0: MyType
    field1: MyRef
    field2: MyDistinct
    field3: MyRefDistinct
    field4: MyDistinctRef

block:
  let tmp0 = MyType(a: 1, b: "abc")
  let tmp1 = MyRef(a: 1, b: "abc")
  let tmp2 = MyDistinct MyType(a: 1, b: "abc")
  let tmp3 = MyRefDistinct MyRef(a: 1, b: "abc")
  let tmp4 = MyDistinctRef MyRef(a: 1, b: "abc")

  let compound = MyCompoundObject(
    field0: tmp0,
    field1: tmp1,
    field2: tmp2,
    field3: tmp3,
    field4: tmp4,
  )

  doAssert $tmp0 == "(a: 1, b: \"abc\")"
  doAssert $tmp1 == "(a: 1, b: \"abc\")"
  doAssert $tmp2 == "(a: 1, b: \"abc\")"
  doAssert $tmp3 == "(a: 1, b: \"abc\")"
  doAssert $tmp4 == "(a: 1, b: \"abc\")"

  doAssert $compound == "(field0: (a: 1, b: \"abc\"), field1: (a: 1, b: \"abc\"), field2: (a: 1, b: \"abc\"), field3: (a: 1, b: \"abc\"), field4: (a: 1, b: \"abc\"))"

type
  CyclicDistinctRef = distinct CyclicDistinctRefInner
  CyclicDistinctRefInner = ref object
    name: string
    field0: CyclicDistinctRef

  # Multiple distinct stacked on top of each other. Stupid but possible.
  StupidMultiDistinctRefInner = ref object
    name: string
    field0: StupidMultiDistinctRef
  StupidMultiDistinctRefMiddle = distinct StupidMultiDistinctRefInner
  StupidMultiDistinctRef = distinct StupidMultiDistinctRefMiddle

block:
  let cyclicA: CyclicDistinctRef = CyclicDistinctRef(CyclicDistinctRefInner())
  let cyclicB: CyclicDistinctRef = CyclicDistinctRef(CyclicDistinctRefInner())
  cyclicA.CyclicDistinctRefInner.name = "A"
  cyclicA.CyclicDistinctRefInner.field0 = cyclicB
  cyclicB.CyclicDistinctRefInner.name = "B"
  cyclicB.CyclicDistinctRefInner.field0 = cyclicA

  # ensure this does not crash in an infinite loop
  doAssert $cyclicA == "(name: \"A\", field0: ...)"
  doAssert $cyclicB == "(name: \"B\", field0: ...)"

block:
  let cyclicA: StupidMultiDistinctRef = StupidMultiDistinctRef(StupidMultiDistinctRefInner())
  let cyclicB: StupidMultiDistinctRef = StupidMultiDistinctRef(StupidMultiDistinctRefInner())
  cyclicA.StupidMultiDistinctRefInner.name = "A"
  cyclicA.StupidMultiDistinctRefInner.field0 = cyclicB
  cyclicB.StupidMultiDistinctRefInner.name = "B"
  cyclicB.StupidMultiDistinctRefInner.field0 = cyclicA

  # ensure this does not crash in an infinite loop
  doAssert $cyclicA == "(name: \"A\", field0: ...)"
  doAssert $cyclicB == "(name: \"B\", field0: ...)"

type
  CyclicStuff = ref object
    name: string
    children: seq[CyclicStuff]

  TreeStuff = object
    name: string
    children: seq[TreeStuff]


  CyclicStuff2 = ref object of RootObj
    name: string
    child: ref RootObj

block:
  let cycle1 = CyclicStuff(name: "name1")
  cycle1.children.add cycle1 # very simple cycle
  doAssert $cycle1 == "(name: \"name1\", children: ...)"

  var tree = TreeStuff(name: "name1")
  var cpy = tree
  tree.children.add cpy
  cpy = tree
  tree.children.add cpy

  doAssert $tree == "(name: \"name1\", children: @[(name: \"name1\", children: @[]), (name: \"name1\", children: @[(name: \"name1\", children: @[])])])"

  let cycle2 = CyclicStuff2(name: "name3")
  cycle2.child = cycle2

type
  MyTypeWithProc = ref object
    name: string
    fun: proc(arg: int): int
    cstr: cstring
    data: UncheckedArray[byte]

block:
  let tmp = MyTypeWithProc(name: "Some Name")
  doAssert $tmp == "(name: \"Some Name\", fun: nil, cstr: nil, data: [...])"

import strutils

block:

  type Foo = object
    age: int
    s: string
    internal: seq[ptr Foo]

  var foo = Foo(age: 20, s: "bob")
  foo.internal = @[foo.addr]
  doAssert contains($foo, "(age: 20, s: \"bob\", internal: @[0x")


echo "DONE: tostring.nim"
