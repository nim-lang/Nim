discard """
  output: "DONE: tostring.nim"
  targets: "c cpp js"
"""
# xxx move this to tests/system/tdollars.nim

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

# nil string should be an some point in time equal to the empty string
doAssert(($foo1)[0..9] == "(a: 0, b: ")

const
  data = @['a','b', '\0', 'c','d']
  dataStr = $data

# ensure same result when on VM or when at program execution
doAssert dataStr == $data

from strutils import contains
# array test

let arr = ['H','e','l','l','o',' ','W','o','r','l','d','!','\0']
doAssert $arr == "['H', 'e', 'l', 'l', 'o', ' ', 'W', 'o', 'r', 'l', 'd', '!', '\\x00']"
when not defined js: # bug
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
  when not defined js: # bug
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
  when not defined(js): # bug
    doAssert g == "\0\0\0\0\0\0\0\0\0\0"
  doAssert "" != "\0\0\0\0\0\0\0\0\0\0"

  var nilstring: string
  #bar(nilstring)
  baz(nilstring)

stringCompare()
var nilstring: string
when not defined(js): # bug
  bar(nilstring)

static:
  stringCompare()

# bug 8847
var a2: cstring = "fo\"o2"

block:
  var s: string
  s.addQuoted a2
  doAssert s == "\"fo\\\"o2\""

block: # ptr-like types
  type
    TFoo = object
      x1: int
      x2: pointer
      x3: seq[Foo]
      x4: ptr TFoo
    Foo = ref TFoo
  
  template fun() =
    doAssert $Foo.default == "nil"
    var z = 0
    var a = Foo(x1: 1, x2: z.addr)
    let sa = $a
    a.x3 = @[nil, a, Foo()]
    a.x4 = a[].addr
    doAssert $a.x4 == sa
    doAssert $a.x3[0] == "nil"
    doAssert $a.x3[1] == sa
    doAssert $a.x3[2] != sa
    doAssert sa in $a[]

  fun()
  static: fun()

echo "DONE: tostring.nim"
