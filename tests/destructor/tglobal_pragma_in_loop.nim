discard """
  output: '''
@[1, 1, 1]
xxx
3
'''
"""

# A `{.global.}` in a proc is initialized once, even when it's declared in a
# loop body without an initializer.
import std/tables

proc a() =
  for i in 0..2:
    var s {.global.}: seq[int]
    s.add 1
    if i == 2: echo s
a()

proc b() =
  var i = 0
  while i < 3:
    var s {.global.}: string
    s.add "x"
    if i == 2: echo s
    inc i
b()

proc c() =
  for i in 0..2:
    var t {.global.}: Table[int, int]
    t[i] = i
    if i == 2: echo t.len
c()

static:
  a()
  b()
  c()
