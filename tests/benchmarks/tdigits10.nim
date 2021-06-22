discard """
  action: compile
"""

#[
benchmark for digits10

on OSX, `nim r -d:danger tests/benchmarks/tdigits10.nim` prints:
("digits10v1", 1718245139, 0.567017)
("digits10", 1718245139, 0.16170099999999998)

without {.noinline.} in digits10v1:
("digits10v1", 1718245139, 0.43684399999999995)
("digits10", 1718245139, 0.15965100000000004)
]#

from std/private/digitsutils import digits10

func digits10v1(num: uint64): int {.noinline.} =
# func digits10v1(num: uint64): int = # a bit faster without {.noinline.}
  if num < 10'u64:
    result = 1
  elif num < 100'u64:
    result = 2
  elif num < 1_000'u64:
    result = 3
  elif num < 10_000'u64:
    result = 4
  elif num < 100_000'u64:
    result = 5
  elif num < 1_000_000'u64:
    result = 6
  elif num < 10_000_000'u64:
    result = 7
  elif num < 100_000_000'u64:
    result = 8
  elif num < 1_000_000_000'u64:
    result = 9
  elif num < 10_000_000_000'u64:
    result = 10
  elif num < 100_000_000_000'u64:
    result = 11
  elif num < 1_000_000_000_000'u64:
    result = 12
  else:
    result = 12 + digits10v1(num div 1_000_000_000_000'u64)

proc firstPow10(n: int): uint64 {.compileTime.} =
  case n
  of 1: 1'u64
  of 2: 10'u64
  of 3: 100'u64
  of 4: 1000'u64
  of 5: 10000'u64
  of 6: 100000'u64
  of 7: 1000000'u64
  of 8: 10000000'u64
  of 9: 100000000'u64
  of 10: 1000000000'u64
  of 11: 10000000000'u64
  of 12: 100000000000'u64
  of 13: 1000000000000'u64
  of 14: 10000000000000'u64
  of 15: 100000000000000'u64
  of 16: 1000000000000000'u64
  of 17: 10000000000000000'u64
  of 18: 100000000000000000'u64
  of 19: 1000000000000000000'u64
  of 20: 10000000000000000000'u64
  else:
    doAssert false
    0'u64

func digits10v2(x: uint64): int {.inline.} =
  if x >= firstPow10(11): # 1..10, 11..20
    if x >= firstPow10(16): # 11..15, 16..20
      if x >= firstPow10(18): # 16..17, 18..20
        if x >= firstPow10(19): # 18, 19..20
          if x >= firstPow10(20): 20 # 19, 20
          else: 19
        else: 18
      elif x >= firstPow10(17): 17 # 16, 17
      else: 16
    elif x >= firstPow10(13): # 11..12, 13..15
      if x >= firstPow10(14): # 13, 14..15
        if x >= firstPow10(15): 15 # 14, 15
        else: 14
      else: 13
    elif x >= firstPow10(12): 12 # 11, 12
    else: 11
  elif x >= firstPow10(6): # 1..5, 6..10
    if x >= firstPow10(8): # 6..7, 8..10
      if x >= firstPow10(9): # 8, 9..10
        if x >= firstPow10(10): 10 # 9, 10
        else: 9
      else: 8
    elif x >= firstPow10(7): 7 # 6, 7
    else: 6
  elif x >= firstPow10(3): # 1..2, 3..5
    if x >= firstPow10(4): # 3, 4..5
      if x >= firstPow10(5): 5 # 4, 5
      else: 4
    else: 3
  elif x >= firstPow10(2): 2 # 1, 2
  else: 1

func digits10v3(x: uint64): int {.inline.} =
  if x >= firstPow10(6): # 1..5, 6..20
    if x >= firstPow10(13): # 6..12, 13..20
      if x >= firstPow10(17): # 13..16, 17..20
        if x >= firstPow10(19): # 17..18, 19..20
          if x >= firstPow10(20): 20 # 19, 20
          else: 19
        elif x >= firstPow10(18): 18 # 17, 18
        else: 17
      elif x >= firstPow10(15): # 13..14, 15..16
        if x >= firstPow10(16): 16
        else: 15
      elif x >= firstPow10(14): 14
      else: 13
    elif x >= firstPow10(9): # 6..8, 9..12
      if x >= firstPow10(11): # 9..10, 11..12
        if x >= firstPow10(12): 12 # 11, 12
        else: 11
      elif x >= firstPow10(10): 10
      else: 9
    elif x >= firstPow10(7): # 6, 7..8
      if x >= firstPow10(8): 8
      else: 7
    else: 6
  elif x >= firstPow10(3): # 1..2, 3..5
    if x >= firstPow10(4): # 3, 4..5
      if x >= firstPow10(5): 5
      else: 4
    else: 3
  elif x >= firstPow10(2): 2
  else: 1

import std/times

var c0 = 0
template main2(algo) =
  block:
    let n = 1000_000_000
    # let n = 100_000_000
    # let n = 10_000_000
    # let n = 1_000_000
    # let n = 100_000
    var c = 0
    let t = cpuTime()
    template gen(i): untyped =
      # pseudo-random but fast
      var x = cast[uint64](i)
      x + (x*x shl 5)
      # x
    for i in 1..<n:
      let x = gen(i)
      c += algo(x)
    let t2 = cpuTime()
    echo (astToStr(algo), c, t2 - t)
    # sanity check
    if c0 == 0: c0 = c
    else: doAssert c == c0

proc main =
  for i in 0..<3:
    main2(digits10v1)
    main2(digits10)
    main2(digits10v2)
    main2(digits10v3)
main()
