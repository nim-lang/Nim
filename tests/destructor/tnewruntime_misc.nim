discard """
  cmd: '''nim cpp -d:nimAllocStats --newruntime --threads:on $file'''
  output: '''(field: "value")
Indeed
axc
(v: 10)
...
destroying GenericObj[T] GenericObj[system.int]
test
(allocCount: 12, deallocCount: 10)
3'''
"""

import system / ansi_c

import tables

type
  Node = ref object
    field: string

# bug #11807
import os
putEnv("HEAPTRASHING", "Indeed")

let s1 = getAllocStats()


proc newTableOwned[A, B](initialSize = defaultInitialSize): owned(TableRef[A, B]) =
  new(result)
  result[] = initTable[A, B](initialSize)

proc main =
  var w = newTableOwned[string, owned Node]()
  w["key"] = Node(field: "value")
  echo w["key"][]
  echo getEnv("HEAPTRASHING")

  # bug #11891
  var x = "abc"
  x[1] = 'x'
  echo x

main()

# bug #11745

type
  Foo = object
    bar: seq[int]

var x = [Foo()]

# bug #11563
type
  MyTypeType = enum
    Zero, One
  MyType = object
    case kind: MyTypeType
    of Zero:
      s*: seq[MyType]
    of One:
      x*: int
var t: MyType

# bug #11254
proc test(p: owned proc()) =
  let x = (proc())p

test(proc() = discard)

# bug #10689

type
  O = object
    v: int

proc `=sink`(d: var O, s: O) =
  d.v = s.v

proc selfAssign =
  var o = O(v: 10)
  o = o
  echo o

selfAssign()

# bug #11833
type FooAt = object

proc testWrongAt() =
  var x = @[@[FooAt()]]

testWrongAt()

#-------------------------------------------------
type
  Table[A, B] = object
    x: seq[(A, B)]


proc toTable[A,B](p: sink openArray[(A, B)]): Table[A, B] =
  for zz in mitems(p):
    result.x.add move(zz)


let table = {"a": new(int)}.toTable()

# bug # #12051

type
  GenericObj[T] = object
    val: T
  Generic[T] = owned ref GenericObj[T]

proc `=destroy`[T](x: var GenericObj[T]) =
  echo "destroying GenericObj[T] ", x.typeof # to know when its being destroyed

proc main12() =
  let gnrc = Generic[int](val: 42)
  echo "..."

main12()

#####################################################################
## bug #12827
type
  MyObject = object
    x: string
    y: seq[string]
    needs_ref: ref int

proc xx(xml: string): MyObject =
  let stream = xml
  result.x  = xml
  defer: echo stream


discard xx("test")
echo getAllocStats() - s1

# bug #13457
var s = "abcde"
s.setLen(3)

echo s.cstring.len
