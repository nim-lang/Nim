discard """
  output: '''
foo
'''
"""

block: # #12672
  var a = @[1]
  let i = 1
  inc a[i-1]

  var b: seq[int]
  doAssertRaises(IndexDefect): inc b[0]
  doAssertRaises(IndexDefect): inc b[i-1]

  var x: seq[seq[int]]
  doAssertRaises(IndexDefect): # not TypeError
    inc x[0][i-1]

block: # #14087
  type Obj = object
    str: string

  var s = @[Obj(str: "abc"), Obj(str: "def")]
  s[1].str.add("ghi")
  s[s.len - 1].str.add("jkl")
  s[^1].str.add("mno")
  s[s.high].str.add("pqr")

  let slen = s.len
  s[slen - 1].str.add("stu")

  let shigh = s.high
  s[shigh].str.add("vwx")

  proc foo(): int =
    echo "foo"
    shigh
  s[foo()].str.add("yz")
  doAssert s[1].str == "defghijklmnopqrstuvwxyz"

block: # #14117
  type
    A = object
      case kind: bool
      of true:
        sons: seq[int]
      else: discard

  var a = A(kind: true)
  doAssert a.sons.len == 0
  a.sons.add(1)
  doAssert a.sons.len == 1

import tables

block: # #13966
  var t: Table[int8, array[int8, seq[tuple[]]]]

  t[0] = default(array[int8, seq[tuple[]]])
  t[0][0].add ()

block: # #11783
  proc fun(): string =
    discard

  var ret: string
  ret.add fun()
  doAssert ret == ""

block: # #12256
  var x: bool

  doAssert x == false

  reset x

  doAssert x == false
  doAssert x != true
