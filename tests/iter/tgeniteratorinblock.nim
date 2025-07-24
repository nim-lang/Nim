discard """
  output: '''30
60
90
150
180
210
240
60
180
240
[60, 180, 240]
[60, 180]'''
"""
import std/enumerate

template map[T; Y](i: iterable[T], fn: proc(x: T): Y): untyped =
  iterator internal(): Y  {.gensym.} =
    for it in i:
      yield fn(it)
  internal()

template filter[T](i: iterable[T], fn: proc(x: T): bool): untyped =
  iterator internal(): T {.gensym.} =
    for it in i:
      if fn(it):
        yield it
  internal()

template group[T](i: iterable[T], amount: static int): untyped =
  iterator internal(): array[amount, T] {.gensym.} =
    var val: array[amount, T]
    for ind, it in enumerate i:
      val[ind mod amount] = it
      if ind mod amount == amount - 1:
        yield val
  internal()

var a = [10, 20, 30, 50, 60, 70, 80]

proc mapFn(x: int): int = x * 3
proc filterFn(x: int): bool = x mod 20 == 0

for x in a.items.map(mapFn):
  echo x

for y in a.items.map(mapFn).filter(filterFn):
  echo y

for y in a.items.map(mapFn).filter(filterFn).group(3):
  echo y

for y in a.items.map(mapFn).filter(filterFn).group(2):
  echo y
