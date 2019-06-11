discard """
  cmd: '''nim c --newruntime $file'''
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

let (a, d) = allocCounters()
discard cprintf("%ld %ld  new: %ld\n", a, d, allocs)
