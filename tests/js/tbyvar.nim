discard """
  output: '''
foo 12
bar 12
2
foo 12
bar 12
2
12.5
(nums: @[5.0, 5.0, 10.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0])
(nums: @[5.0, 5.0, 50.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0])
(nums: @[5.0, 5.0, 45.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0])
(nums: @[5.0, 5.0, 9.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0])
asd
'''
"""

# bug #1489
proc foo(x: int) = echo "foo ", x
proc bar(y: var int) = echo "bar ", y

var x = 12
foo(x)
bar(x)

# bug #1490
var y = 1
y *= 2
echo y

proc main =
  var x = 12
  foo(x)
  bar(x)

  var y = 1
  y *= 2
  echo y

main()

# Test: pass var seq to var openArray
var s = @[2, 1]
proc foo(a: var openArray[int]) = a[0] = 123

proc bar(s: var seq[int], a: int) =
  doAssert(a == 5)
  foo(s)
s.bar(5)
doAssert(s == @[123, 1])

import tables
block: # Test get addr of byvar return value
  var t = initTable[string, int]()
  t["hi"] = 5
  let a = addr t["hi"]
  a[] = 10
  doAssert(t["hi"] == 10)

block: # Test var arg inside case expression. #5244
  proc foo(a: var string) =
    a = case a
    of "a": "error"
    of "b": "error"
    else: a
  var a = "ok"
  foo(a)
  doAssert(a == "ok")


proc mainowar =
  var x = 9.0
  x += 3.5
  echo x

mainowar()


# bug #5608

type Foo = object
    nums : seq[float]

proc newFoo(len : int, default = 0.0) : Foo =
    result = Foo()
    result.nums = newSeq[float](len)
    for i in 0..(len - 1):
        result.nums[i] = default

proc `[]=`(f : var Foo, i : int, v : float) =
    f.nums[i] = v

proc `[]`(f : Foo, i : int) : float = f.nums[i]

proc `[]`(f : var Foo, i : int) : var float = f.nums[i]

var f = newFoo(10,5)

f[2] += 5
echo f
f[2] *= 5
echo f
f[2] -= 5
echo f
f[2] /= 5
echo f

# regression for #5608
import tables

type
  SomeObj = ref object
    s: cstring

var a = initTable[cstring, Table[cstring, SomeObj]]()

var b = initTable[cstring, SomeObj]()

b.add(cstring"b", SomeObj(s: cstring"asd"))

a.add(cstring"a", b)

echo a[cstring"a"][cstring"b"].s
