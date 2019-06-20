discard """
  cmd: '''nim c --newruntime $file'''
  output: '''a b
0 0  alloc/dealloc pairs: 0'''
"""

import core / allocators
import system / ansi_c

proc main(): owned(proc()) =
  var a = "a"
  var b = "b"
  result = proc() =
    echo a, " ", b

proc wrap =
  let p = main()
  p()

wrap()
let (a, d) = allocCounters()
discard cprintf("%ld %ld  alloc/dealloc pairs: %ld\n", a, d, system.allocs)
