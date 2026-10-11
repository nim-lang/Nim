discard """
  targets: "c cpp"
  output: '''
2
2
2
'''
"""

# bug #11768: typed `varargs` macro argument passed on to a proc
import std/macros

type Iter = ref object

proc at(s: seq[int], indices: varargs[Iter]) =
  echo indices.len

macro at1(s: seq, indices: varargs[Iter]): untyped =
  result = newCall(bindSym"at", s, indices)

macro at2(s: seq, indices: varargs[untyped]): untyped =
  result = newCall(bindSym"at", s, indices)

macro at3(s: seq, indices: varargs[Iter]): untyped =
  result = quote do:
    at(`s`, `indices`)

let s = @[1, 2, 3]
var i, j: Iter

s.at1(i, j)
s.at2(i, j)
s.at3(i, j)
