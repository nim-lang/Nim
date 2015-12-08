discard """
  file: "tgetimpl.nim"
  msg: '''"muhaha"
proc poo(x, y: int) =
  echo ["poo"]'''
"""

import macros

const
  foo = "muhaha"

proc poo(x, y: int) =
  echo "poo"

macro m(x: typed): untyped =
  echo repr x.symbol.getImpl
  result = x

discard m foo
discard m poo
