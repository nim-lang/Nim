discard """
  cmd: '''nim c --newruntime $file'''
  output: '''a b
70
hello
hello
hello
2 2  alloc/dealloc pairs: 0'''
"""

import system / allocators
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

# bug #11533
proc say = echo "hello"

# Error: internal error: genAssignment: tyNil
var err0: proc() = say
err0()

var ok0: proc()
ok0 = say
ok0()

var ok1 = say
ok1()

when false:
  # bug #12443
  func newStringIterator(s: string): owned(iterator(): char) =
    result = iterator(): char =
      var pos = 0
      while pos < s.len:
        yield s[pos]
        inc pos

  proc stringIter() =
    let si = newStringIterator("foo")
    for i in si():
      echo i

  stringIter()

let (a, d) = allocCounters()
discard cprintf("%ld %ld  alloc/dealloc pairs: %ld\n", a, d, system.allocs)
