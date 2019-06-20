discard """
  cmd: '''nim c --newruntime $file'''
  output: '''a b
70
2 2  alloc/dealloc pairs: 0'''
"""

import core / allocators
import system / ansi_c

proc main(): owned(proc()) =
  var a = "a"
  var b = "b"
  result = proc() =
    echo a, " ", b


proc foo(f: (iterator(): int)) =
  for i in f(): echo i

proc wrap =
  let p = main()
  p()

  let fIt = iterator(): int = yield 70
  foo fIt

wrap()
let (a, d) = allocCounters()
discard cprintf("%ld %ld  alloc/dealloc pairs: %ld\n", a, d, system.allocs)
