discard """
  cmd: '''nim cpp --newruntime $file'''
  output: '''(field: "value")
3 3  new: 0'''
"""

import core / allocators
import system / ansi_c

import tables

type
  Node = ref object
    field: string

proc main =
  var w = newTable[string, owned Node]()
  w["key"] = Node(field: "value")
  echo w["key"][]

main()

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

let (a, d) = allocCounters()
discard cprintf("%ld %ld  new: %ld\n", a, d, allocs)
