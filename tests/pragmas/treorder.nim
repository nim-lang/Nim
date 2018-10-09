discard """
output:'''0
1
2
3'''
"""

import macros
# {.reorder: on .}
{.experimental: "codeReordering".}

echo foo(-1)
echo callWithFoo(0)
echo(CA+CD)
echo useTypes(TA(x:TB(x:1)), 2)
second(0)

template callWithFoo(arg: untyped): untyped =
  foo(arg)

proc first(i: int): void

proc second(i: int): void =
  make(first)
  first(i)

proc useTypes(a: TA, d: TD): int =
  result = a.x.x+d

type
  TDoubleCyclic = ref object
    x: TCyclicA
    y: TCyclicB

type
  TCyclicA = ref object
    x: TDoubleCyclic

type
  TCyclicB = ref object
    x: TDoubleCyclic

const
  CA = 1
  CB = CC

type
  TA = object
    x: TB
  TC = type(CC)
  TD = type(CA)

const
  CC = 1
  CD = CB

type
  TB = object
    x: TC

proc foo(x: int): int =
  result = bar(x)

proc bar(x: int): int =
  result = x+1

macro make(arg: untyped): untyped =
  ss &= arg.repr
  ss &= " "
  discard

proc first(i: int): void =
  make(second)

var ss {.compileTime.}: string = ""
