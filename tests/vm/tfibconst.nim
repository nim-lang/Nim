discard """
  nimout: '''
Fibonacci sequence: 0, 1, 1, 2, 3
Sequence continues: 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610
'''
"""


import strformat

var fib_n {.compileTime.}: int
var fib_prev {.compileTime.}: int
var fib_prev_prev {.compileTime.}: int

proc next_fib(): int {.compileTime.} =
  let fib = if fib_n < 2:
    fib_n
  else:
    fib_prev_prev + fib_prev
  inc(fib_n)
  fib_prev_prev = fib_prev
  fib_prev = fib
  fib

const f0 = next_fib()
const f1 = next_fib()
const f2 = next_fib()
const f3 = next_fib()
const f4 = next_fib()

static:
  echo fmt"Fibonacci sequence: {f0}, {f1}, {f2}, {f3}, {f4}"

const fib_continues = block:
  var result = fmt"Sequence continues: "
  for i in 0..10:
    if i > 0:
      add(result, ", ")
    add(result, $next_fib())
  result

static:
  echo fib_continues