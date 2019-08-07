discard """
  cmd: '''nim cpp --newruntime $file'''
  output: '''(field: "value")
Indeed
0  new: 0'''
"""

import core / allocators
import system / ansi_c

import tables

type
  Node = ref object
    field: string

# bug #11807
import os
putEnv("HEAPTRASHING", "Indeed")

proc main =
  var w = newTable[string, owned Node]()
  w["key"] = Node(field: "value")
  echo w["key"][]
  echo getEnv("HEAPTRASHING")

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

let (a, d) = allocCounters()
discard cprintf("%ld  new: %ld\n", a - unpairedEnvAllocs() - d, allocs)
