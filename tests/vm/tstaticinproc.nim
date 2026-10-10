discard """
  nimout: '''
@[0, 1, 2, 3, 4, 5]
@[0, 1, 2, 3, 4, 5]
BLS12_381
'''
"""

# the locals of a `static` block inside a generic proc are owned by the proc
# (serialization's static unittest2 tests)

type Stream = ref object
  data: seq[byte]

proc getOutput(s: Stream, T: type seq[byte]): seq[byte] =
  result = move s.data

template encode(Format: type, value: int): auto =
  try:
    var s = Stream()
    for i in 0..value: s.data.add byte(i)
    s.getOutput(seq[byte])
  except IOError:
    raiseAssert "no"

proc run(Format: type) =
  static:
    block:
      var bytes = Format.encode(5)
      echo bytes
      echo bytes

run int

# `$` of a `static` enum generic parameter of a macro (constantine)

import std/macros

type
  Algebra = enum A0, A1, BLS12_381
  Fp[Name: static Algebra] = object

macro algebraName[Name: static Algebra](F: type Fp[Name]): untyped =
  echo $Name
  result = newLit($Name)

doAssert algebraName(Fp[BLS12_381]) == "BLS12_381"
