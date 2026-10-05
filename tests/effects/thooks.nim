discard """
  matrix: "--warningAsError:Effect"
"""

import std/isolation

# bug #23129
type
  Thing = object
    x: string

proc send(x: string) =
  let wrapper = Thing(x: x)
  discard isolate(wrapper)

send("la")

block:
  func enqueue[T](buf: var array[10, T], elem: sink T) =
    `=sink`(buf[0], elem)

  var buf: array[10, int]
  enqueue(buf, 42)
  assert buf[0] == 42